% -*- mode: slang; mode: fold -*-

() = evalfile ("./test.sl");

require ("varray");

private define test_varray ()
{
   variable file = __FILE__;
   variable fp = fopen (file, "r");
   if (fp == NULL)
     failed ("failed to open %s", file);
   variable bytes, nbytes, array, i0, i1;

   nbytes = fread (&bytes, UChar_Type, 0xFFFF, fp);
   i0 = nbytes/2;
   i1 = (3*nbytes)/4;
   array = mmap_array (file, i0, UChar_Type, [i1-i0+1]);

   if (length (array) != i1-i0+1)
     failed ("mmap_array returned wrong sized array");

   if (_typeof(array) != UChar_Type)
     failed ("mmap_array returned wrong array type [%S]", _typeof(array));

   if (not _eqs(array, bytes[[i0:i1]]))
     failed ("mmap_array produced an array with unexpected values");
}

define slsh_main ()
{
   testing_module ("varray");
   test_varray ();
   end_test ();
}
