() = evalfile ("./test.sl");
require ("chksum");

private variable Chksum_Map = Assoc_Type[];

private define add_entry (str, md5, sha1)
{
   Chksum_Map[str] = struct
     {
	md5 = md5,
	sha1 = sha1,
     };
}

add_entry ("",
	   "d41d8cd98f00b204e9800998ecf8427e",
	   "da39a3ee5e6b4b0d3255bfef95601890afd80709"
	  );

add_entry ("1",
	   "c4ca4238a0b923820dcc509a6f75849b",
	   "356a192b7913b04c54574d18c28d46e6395428ab"
	  );

add_entry ("Four score and seven years ago",
	   "8bc88284b17081c54df4daa4576251f7",
	   "0e6089220e01abfc69188c555f1a37201d2fa37f"
	  );

add_entry ("Four score and seven years ago our fathers brought forth on this continent a new nation, conceived in liberty, and dedicated to the proposition that all men are created equal.",
	   "73168f4191456bc526791a83c064997b",
	   "3eabb94199e5347c55ae914ef75803ff0970d9e4"
	  );

private define test_accumulate (name, str, chksum)
{
   str = typecast (str, BString_Type); %  test bstrings too
   variable n = bstrlen (str);
   _for (1, n, 1)
     {
	variable i0 = ();
	variable s0 = str[[0:i0-1]];
	variable s1 = str[[i0:]];
	variable m = bstrlen (s1);
	_for (1, m, 1)
	  {
	     variable i1 = ();
	     variable s10 = s1[[0:i1-1]];
	     variable s11 = s1[[i1:]];
	     variable c = chksum_new (name);
	     c.accumulate (s0);
	     c.accumulate (s10);
	     c.accumulate (s11);
	     if (chksum != c.close ())
	       failed ("Failed to compute %s for the partition '%s', '%s', '%s'", name, s0, s10, s11);
	  }
     }
}

private define test_chksum_file (func, data)
{
   variable tmpfile = sprintf ("/tmp/test_chksum_%d_%d", getpid(), _time());
   variable fp = fopen (tmpfile, "wb");
   if (fp == NULL)
     return;
   () = fwrite (data, fp);
   () = fclose (fp);
   variable s = (@func)(tmpfile);
   () = remove (tmpfile);
   return s;
}

private define test_module (module_name)
{
   testing_module (module_name);

   foreach (assoc_get_keys (Chksum_Map))
     {
	variable key = ();
	variable s = Chksum_Map[key];

	variable md5 = md5sum (key);
	if (md5 != s.md5)
	  failed ("MD5 failure for %s, got %s instead of %s", key, md5, s.md5);

	test_accumulate ("md5", key, md5);

	md5 = test_chksum_file (&md5sum_file, key);
	if (md5 != s.md5)
	  failed ("md5sum_file failed: got %s, expected %s", md5, s.md5);

	variable sha1 = sha1sum (key);
	if (sha1 != s.sha1)
	  failed ("SHA1 failure for %s, got %s instead of %s", key, sha1, s.sha1);

	test_accumulate ("sha1", key, sha1);

	sha1 = test_chksum_file (&sha1sum_file, key);
	if (sha1 != s.sha1)
	  failed ("sha1sum_file failed: got %s, expected %s", sha1, s.sha1);
     }
}

define slsh_main ()
{
   test_module ("chksum");
   end_test ();
}

