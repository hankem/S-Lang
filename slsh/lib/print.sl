private variable Pager_Rows = 22;
private variable Pager = getenv ("PAGER");
if (Pager == NULL)
  Pager = "more";

#ifexists SIGPIPE
private variable Sigpipe_Handler;
#endif

private define open_pager (pager)
{
#ifexists SIGPIPE
   signal (SIGPIPE, SIG_IGN, &Sigpipe_Handler);
#endif
   variable fp = popen (pager, "w");
   if (fp == NULL)
     throw OpenError, "Unable to open the pager ($pager)"$;
   
   return fp;
}

private define close_pager (fp)
{
   if (fp != NULL)
     () = pclose (fp);
#ifexists SIGPIPE
   signal (SIGPIPE, Sigpipe_Handler);
#endif
}

private define generic_to_string (x)
{
   variable t = typeof (x);

   if ((t == String_Type) or (t == BString_Type))
     return make_printable_string (x);

   return string (x);
}

private define struct_to_string (s, single_line)
{
   if (s == NULL)
     return "NULL";

   variable names = get_struct_field_names (s);
   variable comma = "";
   variable str = "{";
   variable comma_str = ", ";
   if (single_line == 0)
     comma_str = ",\n ";
   foreach (names)
     {
	variable name = ();
	str = strcat (str, comma, name, "=", generic_to_string(get_struct_field (s, name)));
	comma = comma_str;
     }
   return strcat (str, "}");
}

private define struct_to_single_line_string (s)
{
   return struct_to_string (s, 1);
}
  
private define print_list (a, ref, fp, use_pager, pager_pgm)
{
   variable i;
   variable s = "{";
   variable comma = "";
   if (ref != NULL)
     {
	_for i (0, length (a)-1, 1)
	  {
	     s = sprintf ("%s%s%s", s, comma, generic_to_string(a[i]));
	     comma = ", ";
	  }
	s = strcat (s, "}");
	@ref = s;
	return;
     }
   
   if (use_pager == -1)
     use_pager = length (a) > Pager_Rows;
   
   variable pager_open = 0;
   if (use_pager && (fp == NULL))
     {
	fp = open_pager (pager_pgm);
	pager_open = 1;
     }

   if (fp == NULL)
     fp = stdout;

   if (-1 != fprintf (fp, "{\n"))
     {
	foreach s (a)
	  {
	     if (-1 == fprintf (fp, "%s\n", generic_to_string (s)))
	       break;
	  }
	then
	  () = fprintf (fp, "}\n");
     }

   if (pager_open)
     close_pager (fp);
}

private define write_2d_array (fp, a, to_str)
{
   variable dims = array_shape (a);
   variable nrows = dims[0];
   variable ncols = dims[1];

   _for (0, nrows-1, 1)
     {
	variable i = ();
	_for (0, ncols-1, 1)
	  {
	     variable j = ();
	     if (-1 == fprintf (fp, "%s ", (@to_str)(a[i,j])))
	       return -1;
	  }
	if (-1 == fputs ("\n", fp))
	  return -1;
     }
   return 0;
}

private define print_array (a, ref, fp, use_pager, pager_pgm)
{
   variable dims, ndims, type;

   (dims, ndims, type) = array_info (a);
   variable nelems = length (a);
   variable nrows = dims[0];
   variable is_numeric = __is_numeric (a);
   variable pager_open = 0;
   if (use_pager == -1)
     use_pager = (nrows > Pager_Rows) || (prod(dims) > Pager_Rows*10);

   if (use_pager && (fp == NULL))
     {
	fp = open_pager (pager_pgm);
	pager_open = 1;
     }

   if (fp == NULL)
     fp = stdout;

   try
     {
	variable i, j;
	variable to_str;
	if (_is_struct_type (a))
	  to_str = &struct_to_single_line_string;
	else if (__is_numeric (a))
	  to_str = &string;
	else
	  to_str = &generic_to_string;

	if (ndims == 1)
	  {
	     _for i (0, nrows-1, 1)
	       {
		  if (-1 == fprintf (fp, "%s\n", (@to_str)(a[i])))
		    return;
	       }
	     return;
	  }

	if (ndims == 2)
	  {
	     () = write_2d_array (fp, a, to_str);
	     return;
	  }

	nrows = nint(prod(dims[[0:ndims-3]]));
	variable new_dims = [nrows, dims[ndims-2], dims[ndims-1]];
	reshape (a, new_dims);
	_for i (0, nrows-1, 1)
	  {
	     if ((-1 == write_2d_array (fp, a[i,*,*], to_str))
		 || (-1 == fputs ("\n", fp)))
	       return;
	  }
     }
   finally
     {
	if (pager_open)
	  close_pager (fp);
	reshape (a, dims);
     }
}

define print_set_pager (pager)
{
   Pager = pager;
}

define print_set_pager_lines (n)
{
   Pager_Rows = n;
}

define print ()
{
   variable ref = NULL;
   variable fp = NULL;

   if (_NARGS == 0)
     {
	usage ("print (OBJ [,&str|File_Type]);\n"
	       + "Qualifiers: pager[=pgm], nopager\n");
     }
   variable pager_pgm = Pager;
   variable use_pager = -1;	       %  auto
   if (qualifier_exists("nopager"))
     use_pager = 0;
   else if (qualifier_exists ("pager"))
     {
	use_pager = 1;
	pager_pgm = qualifier ("pager");
	if (pager_pgm == NULL)
	  pager_pgm = Pager;
     }

   if (_NARGS == 2)
     {
	ref = ();
	if (typeof (ref) == File_Type)
	  {
	     fp = ref;
	     ref = NULL;
	  }
	use_pager = 0;
     }

   variable x = ();
   variable t = typeof (x);

   % Note: print_array may use the pager if fp is NULL.
   if (t == Array_Type)
     {
	if (ref == NULL)
	  return print_array (x, &ref, fp, use_pager, pager_pgm);
     }

   if (t == List_Type)
     {
	print_list (x, ref, fp, use_pager, pager_pgm);
	return;
     }

   if (is_struct_type (x))
     x = struct_to_string (x, 0);
   else
     x = generic_to_string (x);
   
   if (ref != NULL)
     {
	@ref = x;
	return;
     }

   if (use_pager == -1)
     use_pager = (count_byte_occurances (x, '\n') > Pager_Rows);

   if (use_pager)
     {
	fp = open_pager (pager_pgm);
	if (fp == NULL)
	  use_pager = 0;
     }
   
   if (fp == NULL)
     fp = stdout;
   
   if (-1 != fputs (x, fp))
     {
	() = fputs ("\n", fp);
     }

   if (use_pager)
     close_pager (fp);
}
