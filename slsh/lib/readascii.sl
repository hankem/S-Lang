% Simple ascii file reader
% Copyright (C) 2007 John E. Davis
%
% This file is part of the S-Lang Library and may be distributed under the
% terms of the GNU General Public License.  See the file COPYING for
% more information.

private define allocate_array_list (list, num)
{
   variable n = length (list);
   variable array_list = Array_Type[n];
   _for (0, n-1, 1)
     {
	variable j = ();
	array_list[j] = typeof(list[j])[num];
     }
   return array_list;
}

define readascii ()
{
   if (_NARGS < 2)
     {
	usage ("nrows = %s (file, &a1,...; qualifiers);\nQualifiers:\n" 
	       + "nrows=int, ncols=int, format=string, skip=int, maxlines=int, delim=string\n"
	       + "size=int, dsize=int, stop_on_mismatch, lastline=&var lastlinenum=&var\n",
	       + "comment=string\n",
	       _function_name);
     }

   variable nrows = qualifier ("nrows", NULL);
   variable ncols = qualifier ("ncols", NULL);
   variable fmt = qualifier ("format", NULL);
   variable skip = qualifier ("skip", 0);
   variable maxlines = qualifier ("maxlines", NULL);
   variable delim = qualifier ("delim", " ");
   variable init_size = qualifier("size", NULL);
   variable dsize = qualifier ("dsize", NULL);
   variable stop_on_mismatch = qualifier_exists ("stop_on_mismatch");
   variable linep = qualifier ("lastread", NULL);
   variable linenump = qualifier ("lastlinenum", NULL);
   variable comment = qualifier ("comment", NULL);
   if (comment != NULL)
     variable comment_len = strbytelen (comment);

   if (skip < 0)
     skip = 0;

   variable has_ncols_qualifier = 0;
   variable arg_refs;

   if (ncols != NULL)
     {
	has_ncols_qualifier = 1;
	if (_NARGS != 2)
	  throw UsageError, "The ncols qualifier is incompatible with more than one reference arg";
	arg_refs = ();
     }
   else 
     {
	arg_refs = __pop_list (_NARGS-1);
	ncols = length (arg_refs);
     }

   variable fp = ();

   if (fmt == NULL)
     {
	fmt = String_Type[ncols];
	fmt[*] = "%lf";
	fmt = strjoin (fmt, delim);
     }

   variable fp_is_array = 0;

   if (typeof (fp) != File_Type)
     {
	if (typeof (fp) == Array_Type)
	  {
	     if ((maxlines == NULL) || (maxlines > length (fp)))
	       maxlines = length (fp);
	     fp_is_array = 1;
	  }
	else
	  {
	     variable file = fp;
	     fp = fopen (file, "r");
	     if (fp == NULL)
	       throw IOError, "Unable to open $file"$;
	  }
     }

   if (nrows == NULL)
     nrows = -1;
   else if (nrows < 0)
     nrows = 0;
   
   if (init_size == NULL)
     {
	if ((nrows != NULL) && (nrows > 0))
	  init_size = nrows;
	else if (fp_is_array) 
	  init_size = maxlines;
	else
	  init_size = 0x8000;
     }

   if (dsize == NULL)
     dsize = init_size;

   variable array_list = NULL;
   variable max_allocated = 0;
   variable i, k, nitems = 0;

   % Create a list of references that can be passed to sscanf
   variable ref_list = {}, ref_buf = {};
   _for i (0, ncols-1, 1)
     {
	list_append (ref_buf, 1);
	list_append (ref_list, &ref_buf[i]);
     }

   variable nlines = 0;
   variable line = NULL;
   while ((nitems != nrows) && (nlines != maxlines))
     {
	if (fp_is_array)
	  line = fp[nlines];
	else if (-1 == fgets (&line, fp))
	  break;

	nlines++;

	if (skip)
	  {
	     skip--;
	     continue;
	  }

	if (ncols != sscanf (line, fmt, __push_list(ref_list)))
	  {
	     if (stop_on_mismatch
		 && ((comment == NULL) || strnbytecmp (comment, line, comment_len)))
	       break;
	     continue;
	  }
	
	ifnot (max_allocated)
	  {
	     max_allocated = init_size;
	     array_list = allocate_array_list (ref_buf, max_allocated);
	  }

	if (nitems == max_allocated)
	  {
	     max_allocated += dsize;
	     variable new_array_list = allocate_array_list (ref_buf, max_allocated);
	     k = [0:nitems-1];
	     _for i (0, ncols-1, 1)
	       new_array_list[i][k] = array_list[i];
	     array_list = new_array_list;
	  }
	
	_for i (0, ncols-1, 1)
	  array_list[i][nitems] = ref_buf[i];

	nitems++;
     }

   if (nitems) 
     {
	if (max_allocated != nitems)
	  {
	     k = [0:nitems-1];
	     _for i (0, ncols-1, 1)
	       array_list[i] = array_list[i][k];
	  }
	if (has_ncols_qualifier)
	  @arg_refs = array_list;
	else _for i (0, ncols-1, 1)
	  @arg_refs[i] = array_list[i];
     }
   
   if (linep != NULL) 
     @linep = line;
   if (linenump != NULL)
     @linenump = nlines;

   return nitems;
}