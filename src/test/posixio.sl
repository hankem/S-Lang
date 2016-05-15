() = evalfile ("inc.sl");

testing_feature ("POSIX I/O routines");

define run_tests (some_text)
{
   variable file, fd, fp1, fp2;
   variable new_text, nbytes, len;
   variable pos;

   file = util_make_tmp_file ("tmpfile", &fd);

   if (-1 == write (fd, some_text))
     failed ("write");

   loop (5)
     {
	fp1 = fdopen (fd, "wb");
	fp2 = fdopen (fd, "wb");
	if ((fp1 == NULL) || (fp2 == NULL))
	  failed ("fdopen");

	if (isatty (fileno (fp1)))
	  failed ("isatty (fileno)");
     }

   if (-1 == close (fd))
     failed ("close");

   fd = open (file, O_RDONLY|O_BINARY);
   if (fd == NULL)
     failed ("open existing");

   len = bstrlen (some_text);
   nbytes = read (fd, &new_text, len);
   if (nbytes == -1)
     failed ("read");

   if ((nbytes != len)
       or (some_text != new_text))
     failed ("read");

   if (0 != read (fd, &new_text, 1))
     failed ("read at EOF");
   if (bstrlen (new_text))
     failed ("read at EOF");

   if (-1 == _close (_fileno(fd))) failed ("_close after tests");
   if (0 == close (fd))
     failed ("Expected close to fail since _close was already used");

   variable st = stat_file (file);
   () = st.st_mode;  %  see if stat_file returned the right struct
   () = remove (file);
   if (stat_file (file) != NULL) failed ("remove");
}

run_tests ("ABCDEFG");
run_tests ("A\000BC\000\n\n\n");

variable fd = open ("/dev/tty", O_RDONLY);
if (fd != NULL)
{
   if (0 == isatty (fd))
     failed ("isatty");
}
fd = 0;

if (fileno (stdin) != fileno(stdin))
{
   failed ("fileno(stdin) not equal to itself");
}

if (fileno (stdin) == fileno(stdout))
{
   failed ("fileno(stdin) is equal to fileno(stdout)");
}

private define test_misc ()
{
   variable s, fd;
   fd = fileno (stderr);
#ifexists ttyname
   if (isatty (fd))
     {
	s = ttyname ();
	if ((s != NULL) && (NULL == stat_file (s)))
	  failed ("Unable to stat tty %S", s);
     }
   if (isatty (0))
     {
	% Given no args, ttyname will use fileno(stdin)
	if (NULL == ttyname ())
	  failed ("ttyname failed with no arguments");
     }
#endif

   variable fd1 = dup_fd (fd);
   if (typeof (fd1) != FD_Type)
     failed ("dup_fd did not return an FD_Type");
   if (fd1 == fd)
     failed ("dup_fd did not return a duplicate");
   () = close (fd1);
   if (123 != dup2_fd (fd, 123))
     failed ("dup2_fd failed to return a specified descriptor: %S", errno_string());

   fd1 = @FD_Type(123);
   if (_fileno (fd1) != 123)
     failed ("@FD_Type failed");
   () = close (fd1);

   variable e = errno;
   if (NULL == stat_file (". .|<>."))
     {
	if (String_Type != typeof(errno_string (errno)))
	  failed ("expected errno_string to return a string");
     }
}

test_misc ();

print ("Ok\n");
exit (0);
