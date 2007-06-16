private variable Pager_Rows = 22;
private variable Pager = getenv ("PAGER");
if (Pager == NULL)
  Pager = "more";

#ifexists SIGPIPE
private variable Sigpipe_Handler;
#endif

private define open_pager ()
{
#ifexists SIGPIPE
   signal (SIGPIPE, SIG_IGN, &Sigpipe_Handler);
#endif

   return popen (Pager, "w");
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

private define struct_to_string (s)
{
   if (s == NULL)
     return "NULL";

   variable names = get_struct_field_names (s);
   variable comma = "";
   variable str = "";
   foreach (names)
     {
	variable name = ();
	str = strcat (str, comma, name, "=", generic_to_string(get_struct_field (s, name)));
	comma = ", ";
     }
   return strcat ("{", str, "}");
}

private define print_list (a, ref)
{
   variable fp = stdout;
   variable i;
   variable s = "{";
   variable comma = "";
   _for i (0, length (a)-1, 1)
     {
	s = sprintf ("%s%s%s", s, comma, generic_to_string(a[i]));
	comma = ", ";
     }
   s = strcat (s, "}");
   if (ref != NULL)
     {
	@ref = s;
	return;
     }
   () = fputs (s, stdout);
   () = fputs ("\n", stdout);
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

private define print_array (a, ref)
{
   variable dims, ndims, type;

   (dims, ndims, type) = array_info (a);
   variable nelems = length (a);
   variable nrows = dims[0];
   variable use_pager = (nrows > Pager_Rows) || (prod(dims) > Pager_Rows*10);
   variable is_numeric = __is_numeric (a);
   variable fp = NULL;

   if (use_pager)
     fp = open_pager ();

   if (fp == NULL)
     fp = stdout;

   try
     {
	variable i, j;
	variable to_str;
	if (_is_struct_type (a))
	  to_str = &struct_to_string;
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
	if (fp != stdout)
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
   if (_NARGS == 0)
     {
	usage ("print (OBJ [,&str]);");
     }
   if (_NARGS == 2)
     {
	ref = ();
     }
   variable x = ();
   variable t = typeof (x);

   if (t == Array_Type)
     {
	if (ref == NULL)
	  return print_array (x, &ref);
     }

   if (is_struct_type (x))
     {
	x = struct_to_string (x);
	if (ref != NULL)
	  @ref = x;
	else
	  () = fprintf (stdout, "%s\n", x);
	return;
     }
   if (t == List_Type)
     {
	print_list (x, ref);
	return;
     }

   x = generic_to_string (x);
   if (ref != NULL)
     @ref = x;
   else
     () = fprintf (stdout, "%s\n", x);
}
