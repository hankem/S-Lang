() = evalfile ("inc.sl");

testing_feature ("stdio routines");

define fdopen_tmp_file (fileptr, mode, fdp)
{
   variable file, fp, fd;

   @fileptr = NULL;

   file = util_make_tmp_file ("tmpfile", &fd);
   fp = fdopen (fd, mode);
   if (fp == NULL)
     failed ("fdopen failed: %s", errno_string());

   @fdp = fd;
   @fileptr = file;
   return fp;
}

define fopen_tmp_file (fileptr, mode)
{
   variable file, fp;

   @fileptr = NULL;

   file = util_make_tmp_file ("tmpfile", NULL);

   fp = fopen (file, mode);
   if (fp == NULL)
     failed ("Unable to open %S", file);

   @fileptr = file;
   return fp;
}

define run_tests (some_text, read_fun, write_fun, length_fun)
{
   variable file, fp, fd;
   variable new_text, nbytes, len;
   variable pos;

   fp = fdopen_tmp_file (&file, "wb", &fd);
#ifexists setvbuf
   if (-1 == setvbuf (fp, _IOFBF, 8))
     failed ("setvbuf");
#endif
   if (-1 == @write_fun (some_text, fp))
     failed (string (write_fun));

   if (-1 == fclose (fp))
     failed ("fclose");

   fp = fopen (file, "rb");
   if (fp == NULL) failed ("fopen existing");

   len = @length_fun (some_text);
   nbytes = @read_fun (&new_text, len, fp);

   if ((nbytes != len)
       or (some_text != new_text))
     failed (string (read_fun));

   if (-1 != @read_fun (&new_text, 1, fp))
     failed (string (read_fun) + " at EOF");

   if (0 == feof (fp)) failed ("feof");

   if (ferror (fp))
     failed ("expected ferror to return 0");

   clearerr (fp);
   if (feof (fp)) failed ("clearerr");

   if (0 != fseek (fp, 0, SEEK_SET)) failed ("fseek");

   nbytes = @read_fun (&new_text, len, fp);

   if ((nbytes != len)
       or (some_text != new_text))
     failed (string (read_fun) + " after fseek");

   pos = ftell (fp);
   if (pos == -1) failed ("ftell at EOF");

   if (0 != fseek (fp, 0, SEEK_SET)) failed ("fseek");
   if (0 != ftell (fp)) failed ("ftell at BOF");
   if (0 != fseek (fp, pos, SEEK_CUR)) failed ("fseek to pos");

   if (pos != ftell (fp)) failed ("ftell after fseek to pos");

   if (feof (fp) != 0) failed ("feof after fseek to EOF");

   () = fseek (fp, 0, SEEK_SET);
   nbytes = fread (&new_text, Char_Type, 0, fp);
   if (nbytes != 0)
     failed ("fread for 0 bytes");

   nbytes = fread (&new_text, Char_Type, len + 100, fp);
   if (nbytes != len)
     failed ("fread for 100 extra bytes");

   if (-1 == fclose (fp)) failed ("fclose after tests");

   fd = open (file, O_RDONLY);
   if (fd == NULL)
     failed ("open %s failed", file);

   variable ofs = (@length_fun)(some_text) - 1;
   variable ofs1 = lseek (fd, ofs, SEEK_SET);
   if (ofs != ofs1)
     failed ("lseek returned %S, expected %S: %S", ofs1, ofs, errno_string());
   if (1 != read (fd, &new_text, 1))
     failed ("read failed after lseek");
   if (new_text[0] != some_text[-1])
     failed ("read failed to read the correct byte after lseek: 0x%X vs 0x%X",
	    new_text[0], some_text[-1]);
   () = close (fd);

   () = remove (file);
   if (stat_file (file) != NULL) failed ("remove");
}

static define do_fgets (addr, nbytes, fp)
{
   variable count;
   variable dbytes, bytes;

   variable dc = fgets (&bytes, fp);
   if (dc == -1)
     return -1;

   count = dc;
   while (count < nbytes)
     {
	dc = fgets (&dbytes, fp);
	if (dc == -1)
	  break;
	count += dc;
	bytes += dbytes;
     }
   @addr = bytes;
   return count;
}

static define do_fread (addr, nbytes, fp)
{
   % return fread (addr, UChar_Type, nbytes, fp);
   return fread_bytes (addr, nbytes, fp);
}

private define do_fprintf (some_text, fp)
{
   if (fprintf (fp, "%s", some_text) != strbytelen(some_text))
     return -1;

   return 0;
}

private define do_foreach_char (addr, nbytes, fp)
{
   variable ch, str = NULL, count = 0;
   foreach ch (fp) using ("char")
     {
	if (str == NULL)
	  str = "";
	str = strcat (str, char(-1*ch));
	count++;
	if (count >= nbytes)
	  break;
     }
   if (str == NULL)
     return -1;

   @addr = str;
   return count;
}

private define do_foreach_line (addr, nbytes, fp)
{
   variable line, str = NULL, count = 0;
   foreach line (fp) using ("line")
     {
	if (str == NULL)
	  str = "";
	str = strcat (str, line);
	count += strbytelen(line);
	if (count >= nbytes)
	  break;
     }
   if (str == NULL)
     return -1;

   @addr = str;
   return count;
}

run_tests ("ABCDEFG", &do_fgets, &fputs, &strlen);
run_tests ("A\000BC\000\n\n\n", &do_fread, &fwrite, &bstrlen);
run_tests ("A\nAB\n\ABC\nABCD", &do_fgets, &do_fprintf, &strbytelen);
run_tests ("A\nAB\n\ABC\nABCD", &do_foreach_char, &fwrite, &strbytelen);
run_tests ("A\nAB\n\ABC\nABCD", &do_foreach_line, &fwrite, &strbytelen);

define test_fread_fwrite (x)
{
   variable fp, file, str, n, m, y, type, ch;

   fp = fopen_tmp_file (&file, "w+b");

   type = _typeof(x);
   n = length (x);
   if ((type == String_Type) or (type == BString_Type))
     {
	%type = UChar_Type;
	n = bstrlen (x);
     }

   if (n != fwrite (x, fp))
     failed ("test_fread_fwrite: fwrite");

   if (-1 == fseek (fp, 0, SEEK_SET))
     failed ("test_fread_fwrite: fseek");

   if (n != fread (&y, type, n, fp))
     failed ("test_fread_fwrite: fread");

   if (length (where (y != x)))
     failed ("test_fread_fwrite: fread failed to return: " + string(x));

   if (-1 == fseek (fp, 0, SEEK_SET))
     failed ("test_fread_fwrite: fseek");

   if (type == UChar_Type)
     {
	y = 0;
	foreach (fp) using ("char")
	  {
	     ch = ();
	     if (ch != x[y])
	       failed ("foreach using char: %S != %S", ch, x[y]);
	     y++;
	  }
	if (y != n)
	  failed ("foreach using char 2");
     }

   () = fclose (fp);

   if (-1 == remove (file))
     failed ("remove:" + errno_string(errno));
   if (stat_file (file) != NULL) failed ("remove");
}

test_fread_fwrite ("");
test_fread_fwrite ("hello");
test_fread_fwrite ("hel\0\0lo");
test_fread_fwrite (Integer_Type[0]);
test_fread_fwrite ([1:10]);
#ifexists Double_Type
test_fread_fwrite (3.17);
test_fread_fwrite ([1:10:0.1]);
#endif
#ifexists Complex_Type
test_fread_fwrite (Complex_Type[50] + 3 + 2i);
test_fread_fwrite (2i+3);
test_fread_fwrite ([2i+3, 7i+1]);
#endif

static define test_fgetsputslines ()
{
   variable lines = array_map (String_Type, &string, [1:1000]);
   lines += "\n";
   variable file;
   variable fp = fopen_tmp_file (&file, "w");
   if (length (lines) != fputslines (lines, fp))
     failed ("fputslines");
   if (-1 == fclose (fp))
     failed ("fputslines;fclose");
   fp = fopen (file, "r");
   if (fp == NULL)
     failed ("fputslines...fopen");
   variable lines1 = fgetslines (fp);
   if (0 == _eqs (lines1, lines))
     failed ("fgetslines");
   ()=fclose (fp);
   if (-1 == remove (file))
     failed ("remove:" + errno_string(errno));
}
test_fgetsputslines ();

define test_read_write ()
{
   variable file;
   variable fp = fopen_tmp_file (&file, "w");
   variable fd = fileno (fp);

   variable str = "helloworld";
   variable n = write (fd, str);
   if (n != strlen (str))
     failed ("write(%s) returned %d", str, n);
   () = fclose (fp);
   fd = open (file, O_RDONLY);
   variable buf;
   n = read (fd, &buf, n);
   if (n != strlen (str))
     failed ("read returned %d bytes", n);
   if (buf != str)
     failed ("read returned %s not %s", buf, str);
   () = close (fd);
   () = remove (file);
}
test_read_write();

#ifdef UNIX
private define test_write_to_stdout ()
{
   () = fflush(stdout);
   variable fd = fileno (stdout);
   variable ifd = _fileno(stdout);
   variable old_stdout = dup_fd(fd);
   if (old_stdout == NULL)
     failed ("test_write_to_stdout: dup: %S", errno_string());

   variable new_fd = open("/dev/null", O_WRONLY);

   if (-1 == dup2_fd(new_fd, ifd))
     failed ("test_write_to_stdout: dup2: %S", errno_string());

   () = close (new_fd);

   () = printf ("Write to stdout, fileno=%S", fileno(stdout));
   () = fflush(stdout);

   () = dup2_fd(old_stdout, ifd);
   () = close (old_stdout);
}
test_write_to_stdout ();
#endif

#ifdef UNIX
private define test_popen ()
{
   variable fp = popen ("ls", "r");
   if (fp == NULL)
     failed ("popen ls failed");
   variable count = 0;
   foreach (fp) using ("wsline")
     {
	variable line = ();
	count++;
     }
   if (0 != pclose (fp))
     failed ("pclose: %S", errno_string());
   if (count == 0)
     failed ("no lines read from popen ls");
}
test_popen ();
#endif

private define test_bad_fds ()
{
   variable file;
   variable fp = fopen_tmp_file (&file, "w");
   () = remove (file);

   if (NULL != fgetslines (fp, 0))
     {
	() = fclose (fp);
	failed ("fgetslines on write-only stdio file pointer");
     }

   clearerr (fp);

   if (-1 == fclose (fp))
     failed ("fclose failed");

   if (-1 != fclose (fp))
     failed ("Expected second fclose to fail");
}
test_bad_fds ();

print ("Ok\n");

exit (0);
