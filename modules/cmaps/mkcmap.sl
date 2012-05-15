
define rgb_to_cmap (r, g, b, file)
{
   variable rgb = (r << 16)|(g<<8)|b;
   variable name = path_basename_sans_extname (file);
   if (NULL != stat_file (file))
     throw IOError, sprintf ("File %s exists-- delete it if you want to overwrite", file);

   variable fp = fopen (file, "w");
   () = fputs (`% -*- slang -*-
%

$1 =
[`,
	       fp);
   _for (0, length(rgb)-1, 1)
     {
	variable i = ();
	if ((i mod 8) == 0)
	  () = fputs ("\n  ", fp);
	() = fprintf (fp, "0x%06X,", rgb[i]);
     }
   () = fprintf (fp, `
];

png_add_colormap ("%s", __tmp($1));
`,
		 name);
   () = fclose (fp);
}

#ifnfalse
require ("gslinterp");
require ("readascii");
private define convert_normalized_color (c, n)
{
   variable cx = [0:1:#length(c)];
   variable x = [0:1:#n];
   variable y = interp_linear (x, cx, c);
   return int (y*255.999);
}

define slsh_main ()
{
   variable r, g, b;
   variable file = __argv[1];
   () = readascii (file, &r, &g, &b);
   r = convert_normalized_color (r, 256);
   g = convert_normalized_color (g, 256);
   b = convert_normalized_color (b, 256);
   rgb_to_cmap (r, g, b, path_basename_sans_extname (file) + ".map");
}
#endif
