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

private define test_colormaps ()
{
   variable cmap_names = png_get_colormap_names();

   if (length (cmap_names) == 0)
     failed ("png_get_colormap_names: no color maps found");

   variable cmap_name, cmap;

   foreach cmap_name (cmap_names)
     {
	try
	  {
	     cmap = png_get_colormap (cmap_name);
	     if (cmap == NULL) throw DataError;
	  }
	catch AnyError: failed ("png_get_colormap %s failed", cmap_name);
     }

   variable rgb = 0x80A0B0C0;
   if (png_rgb_get_r (rgb) != 0xA0) failed ("png_get_r failed");
   if (png_rgb_get_g (rgb) != 0xB0) failed ("png_get_g failed");
   if (png_rgb_get_b (rgb) != 0xC0) failed ("png_get_b failed");

   % A single value or array of identical values map to 127
   rgb = png_gray_to_rgb (0x80);
   if (rgb != 0x7F7F7F) failed ("png_gray_to_rgb: %X vs %X", rgb, 0x808080);

   variable img = typecast ([64, 128], UChar_Type);
   rgb = png_gray_to_rgb (img);
   % This should map to 0,255
   ifnot (_eqs(rgb, [0,0xFFFFFF]))
     failed ("png_gray_to_rgb([64,128])");

   variable gray = png_rgb_to_gray (0x808080);
   if (gray != 0x80) failed ("png_rgb_to_gray 1");

   gray = png_rgb_to_gray (0x200000; wghts=[1.0,0,0]);
   if (gray != 0x20) failed ("png_rgb_to_gray 2");

   variable r = UChar_Type[256], g = @r, b = @r;
   r[[0:127]] = 0x20; r[[128:]] = 0xAA;
   g[[0:127]] = 0x40; g[[128:]] = 0xBB;
   b[[0:127]] = 0x60; b[[128:]] = 0xCC;
   rgb = (r<<16)|(g<<8)|b;
   png_add_colormap ("testmap", rgb);
   variable badvalue = rgb[0];

   gray = [0:255]*1.0;
   gray[0x80] = _NaN;		       %  bad pixel
   rgb = png_gray_to_rgb (gray, "testmap");
   if ((rgb[64] != 0x204060)
       || (rgb[200] != 0xAABBCC)
       || (rgb[0x80] != badvalue))
     failed ("png_gray_to_rgb with testmap");
}

define slsh_main ()
{
   testing_module ("png");
   test_png ();
   test_colormaps ();
   end_test ();
}


