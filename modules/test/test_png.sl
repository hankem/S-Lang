() = evalfile ("./test.sl");
try
{
   require ("png");
}
catch ImportError:
{
   () = fprintf (stderr, "png-module not available.  Test not performed\n");
   exit (1);
}
require ("rand");

private define test_png ()
{
   variable nrows = 61, ncols = 83;
   variable img = typecast (rand (nrows*ncols), UInt32_Type);
   reshape (img, [nrows, ncols]);

   variable file = sprintf ("/tmp/testpng-%ld.png", _time() mod getpid());
   try
     {
	png_write (file, img, 1);
	variable img1 = png_read (file);
	ifnot (_eqs (img1, img))
	  {
	     failed ("png_read failed to read the ARGB image png_write created\n");
	     return;
	  }
	png_write (file, img, 0);
	img1 = png_read (file);
	ifnot (_eqs (img&0x00FFFFFFU, img1))
	  {
	     failed ("png_read failed to read the RGB image png_write created\n");
	     return;
	  }
     }
   finally
     {
	() = remove (file);
     }
}

define slsh_main ()
{
   testing_module ("png");
   test_png ();
   end_test ();
}


