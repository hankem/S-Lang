() = evalfile ("./test.sl");
require ("chksum");

private variable Chksum_Map = Assoc_Type[];

private define add_entry (str, md5, sha1,
			  sha224, sha256, sha384, sha512)
{
   Chksum_Map[str] = struct
     {
	md5 = md5,
	sha1 = sha1,
	sha224 = sha224,
	sha256 = sha256,
	sha384 = sha384,
	sha512 = sha512,
     };
}

add_entry ("",
	   "d41d8cd98f00b204e9800998ecf8427e",
	   "da39a3ee5e6b4b0d3255bfef95601890afd80709",
	   "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f",
	   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
	   "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b",
	   "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"
	  );

add_entry ("1",
	   "c4ca4238a0b923820dcc509a6f75849b",
	   "356a192b7913b04c54574d18c28d46e6395428ab",
	   "e25388fde8290dc286a6164fa2d97e551b53498dcbf7bc378eb1f178",
	   "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b",
	   "47f05d367b0c32e438fb63e6cf4a5f35c2aa2f90dc7543f8a41a0f95ce8a40a313ab5cf36134a2068c4c969cb50db776",
	   "4dff4ea340f0a823f15d3f4f01ab62eae0e5da579ccb851f8db9dfe84c58b2b37b89903a740e1ee172da793a6e79d560e5f7f9bd058a12a280433ed6fa46510a"
	  );

add_entry ("Four score and seven years ago",
	   "8bc88284b17081c54df4daa4576251f7",
	   "0e6089220e01abfc69188c555f1a37201d2fa37f",
	   "5016349562f610749f5e34b105e48b55e2fb3aed3f81fd0572f066fd",
	   "213742bd59f1d8fe848b6ea94647dd465310b8d816234d5a952dc645fa320707",
	   "8d18c7eb4e4ccaaf18f6e7b9566d97e2a81d0838e704e8d9da1cb7461efa44165fe9ad5510f2dafa630f1de8b32d0a42",
	   "c9e9b19978e48a2d3031bfc411f60ab1d89e5ccfb9fabbc0ec135c14aa54568ca051e96ed07a5d0c7c3704f7f3189a631008734b4ce6ee1d87e97384aea21fe7"
	  );

add_entry ("Four score and seven years ago our fathers brought forth on this continent a new nation, conceived in liberty, and dedicated to the proposition that all men are created equal.",
	   "73168f4191456bc526791a83c064997b",
	   "3eabb94199e5347c55ae914ef75803ff0970d9e4",
	   "0b85933f2cf20d16c0158e46b101386b5f791a360b9590f053369a58",
	   "16b7310f53d595aa0cad0cbe8c4fe3e8ae4c71d21faae9ee0ac84530d759beea",
	   "d8f207a10e97415c2147f8702a5a1cd93239aa2dbdd8c6c23da9723929b189e65a1c9e5aae79d8161c736bbfec94b617",
	   "2a4a49becf6865588cf7fab5f3fee94a4fd2cbcc19fa6202d6be153360992ad0a8993a14a44429035cc3377dd22e1bfafb09f5e5625f3fe7654c2fdfbb3e6cfb"
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

	variable sha224 = sha224sum (key);
	if (sha224 != s.sha224)
	  failed ("sha224 failure for %s, got %s instead of %s", key, sha224, s.sha224);
	test_accumulate ("sha224", key, sha224);
	sha224 = test_chksum_file (&sha224sum_file, key);
	if (sha224 != s.sha224)
	  failed ("sha224sum_file failed: got %s, expected %s", sha224, s.sha224);

	variable sha256 = sha256sum (key);
	if (sha256 != s.sha256)
	  failed ("sha256 failure for %s, got %s instead of %s", key, sha256, s.sha256);
	test_accumulate ("sha256", key, sha256);
	sha256 = test_chksum_file (&sha256sum_file, key);
	if (sha256 != s.sha256)
	  failed ("sha256sum_file failed: got %s, expected %s", sha256, s.sha256);

	variable sha384 = sha384sum (key);
	if (sha384 != s.sha384)
	  failed ("sha384 failure for %s, got %s instead of %s", key, sha384, s.sha384);
	test_accumulate ("sha384", key, sha384);
	sha384 = test_chksum_file (&sha384sum_file, key);
	if (sha384 != s.sha384)
	  failed ("sha384sum_file failed: got %s, expected %s", sha384, s.sha384);

	variable sha512 = sha512sum (key);
	if (sha512 != s.sha512)
	  failed ("sha512 failure for %s, got %s instead of %s", key, sha512, s.sha512);
	test_accumulate ("sha512", key, sha512);
	sha512 = test_chksum_file (&sha512sum_file, key);
	if (sha512 != s.sha512)
	  failed ("sha512sum_file failed: got %s, expected %s", sha512, s.sha512);
     }

   if (md5sum_new().name != "md5") failed ("md5sum_new");
   if (sha1sum_new().name != "sha1") failed ("sha1sum_new");
   if (sha224sum_new().name != "sha224") failed ("sha224sum_new");
   if (sha256sum_new().name != "sha256") failed ("sha256sum_new");
   if (sha384sum_new().name != "sha384") failed ("sha384sum_new");
   if (sha512sum_new().name != "sha512") failed ("sha512sum_new");
}

define slsh_main ()
{
   test_module ("chksum");
   end_test ();
}

