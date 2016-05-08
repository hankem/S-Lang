% -*- mode: slang; mode: fold -*-

() = evalfile ("./test.sl");

require ("iconv");

% FIXME: Add additional tests and charsets.
private define test_iconv ()
{
   variable ustr = "áéíóúüþëé", ucs = "utf-8";
   variable istr = "\xE1\xE9\xED\xF3\xFA\xFC\xFE\xEB\xE9", ics = "iso-8859-1";

   variable s = iconv_open (ics, ucs);
   variable str = iconv (s, ustr);
   iconv_close (s);
   if (str != istr)
     failed ("conversion from %s->%s failed", ucs, ics);

   % The iconv_reset functions are not necessary for simple tests.
   % They are there just to exercise the interface
   s = iconv_open (ucs, ics);
   iconv_reset (s);
   str = iconv (s, istr);
   () = iconv_reset_shift (s);
   iconv_close (s);

   if (str != ustr)
     failed ("conversion from %s->%s failed", ics, ucs);

   () = iconv_open (ucs, ics);
   %iconv_reset ();
   %iconv_reset_shift ();
}

define slsh_main ()
{
   testing_module ("iconv");
   test_iconv ();
   end_test ();
}
