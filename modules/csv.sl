import ("csv");

private define read_fp_callback (info)
{
   variable line, ch = info.comment_char;
   do
     {
	if (-1 == fgets (&line, info.fp))
	  return NULL;
     }
   while (line[0] == ch);
   return line;
}

private define read_strings_callback (str_info)
{
   variable line;

   if (str_info.output_crlf)
     {
	str_info.output_crlf = 0;
	return "\n";
     }
   variable i = str_info.i;
   if (i >= str_info.n)
     return NULL;
   line = str_info.strings[i];
   str_info.i = i+1;
   if (line[-1] != '\n')
     str_info.output_crlf = 1;

   return line;
}

private define resize_arrays (list, n)
{
   _for (0, length(list)-1, 1)
     {
	variable i = ();
	variable a = list[i];
	variable m = length(a);
	if (m > n)
	  {
	     list[i] = a[[:n-1]];
	     continue;
	  }
	variable b = _typeof(a)[n];
	b[[:m-1]] = a;
	list[i] = b;
     }
}

private define atofloat (x)
{
   typecast (atof(x), Float_Type);
}

private define read_row (csv)
{
   variable row = _csv_parse_row (csv.csv_parser);
   return row;
}

private define fixup_header_names (names)
{
   if (names == NULL) return names;
   if (typeof (names) == List_Type)
     names = list_to_array (names);
   if (_typeof(names) != String_Type)
     return names;

   names = array_map (String_Type, &strlow, names);
   names = array_map (String_Type, &strtrans, names, "\\,", "");
   names = array_map (String_Type, &strtrans, names, "^\\w", "_");
   names = array_map (String_Type, &strcompress, names, "_");
   return names;
}

private define read_cols ()
{
   if (_NARGS == 0)
     {
	usage("struct = .readcol ([columns] ; qualifiers)\n\
where columns is an optional 1-based array of column numbers,\n\
 or array of column names.\n\
Qualifiers:\n\
 header=header, fields=[array of field names],\n\
 type=value|array of 's','i','l','f','d' (string,int,long,float,double)\n\
 typeNTH=val (specifiy type for NTH column)\n\
 snan=\"\", inan=0, lnan=0L, fnan=_NaN, dnan=_NaN (defaults for empty fields),\n\
 nanNTH=val (value used for an empty field in the NTH column\n\
"
	     );
     }

   variable columns = NULL;
   if (_NARGS > 1)
     {
	% allow a mixture of arrays and scalars
	columns = __pop_list (_NARGS-1);
	columns = [__push_list(columns)];
     }
   variable csv = ();

   variable fields = qualifier ("fields");
   variable header = qualifier ("header");
   variable types = qualifier ("type");
   variable snan = qualifier ("snan", "");
   variable fnan = qualifier ("fnan", _NaN);
   variable dnan = qualifier ("dnan", typecast(_NaN,Float_Type));
   variable inan = qualifier ("inan", 0);
   variable lnan = qualifier ("lnan", 0L);

   if ((fields != NULL) && (columns != NULL)
       && (length(fields) != length(columns)))
     throw InvalidParmError, "The fields qualifier must be the same size as the number of columns";

   header = fixup_header_names (header);
   columns = fixup_header_names (columns);

   variable columns_are_string = _typeof(columns) == String_Type;

   if ((header == NULL) && columns_are_string)
     throw InvalidParmError, "No header was supplied to map column names";

   variable column_ints = columns, col, i, j;
   if (columns_are_string)
     {
	column_ints = Int_Type[length(columns)];
	_for i (0, length(columns)-1, 1)
	  {
	     col = columns[i];
	     j = wherefirst (col == columns);
	     if (j == NULL)
	       throw InvalidParmError, "Unknown (canonical) column name $col";
	     column_ints[i] = j+1;
	  }
     }

   variable row_data = csv.readrow();
   if (column_ints == NULL)
     column_ints = [1:length(row_data)];

   if (any(column_ints>length(row_data)))
     {
	throw InvalidParmError, "column number is too large for data";
     }
   variable ncols = length(column_ints);

   variable convert_funcs = Ref_Type[ncols], convert_func, val;
   variable nan_values = {}; loop(ncols) list_append(nan_values, snan);
   if (types != NULL)
     {
	if (typeof(types) == List_Type)
	  types = list_to_array (types);

	if ((typeof(types) == Array_Type) && (length(types) != ncols))
	  throw InvalidParmError, "types array must be equal to the number of columns";

	if (typeof (types) != Array_Type)
	  types = types[Int_Type[ncols]];

	variable i1;
	_for i (1, ncols, 1)
	  {
	     i1 = i-1;
	     types[i1] = qualifier ("type$i"$, types[i1]);
	  }

	i = where(types=='i');
	convert_funcs[i] = &atoi; nan_values[i] = typecast(inan, Int_Type);
	i = where(types=='l');
	convert_funcs[i] = &atol; nan_values[i] = typecast(lnan, Long_Type);
	i = where(types=='f');
	convert_funcs[i] = &atofloat; nan_values[i] = typecast (fnan, Float_Type);
	i = where(types=='d');
	convert_funcs[i] = &atof; nan_values[i] = typecast(dnan, Double_Type);

	_for i (1, ncols, 1)
	  {
	     i1 = i-1;
	     val = nan_values[i1];
	     nan_values[i1] = typecast (qualifier ("nan$i"$, val), typeof(val));
	  }
     }

   variable datastruct = NULL;
   if (fields == NULL)
     {
	if (columns_are_string)
	  fields = columns;
	else if (header != NULL)
	  fields = header[column_ints-1];
	else
	  fields = array_map(String_Type, &sprintf, "col%d", column_ints);
     }
   datastruct = @Struct_Type(fields);

   column_ints -= 1;		       %  make 0-based

   variable list_of_arrays = {}, array;
   variable init_size = 0x8000;
   variable dsize = init_size;
   variable max_allocated = init_size;
   _for i (0, ncols-1, 1)
     {
	val = row_data[column_ints[i]];
	array = typeof(nan_values[i])[max_allocated];
	ifnot (strbytelen(val))
	  val = nan_values[i];
	else
	  {
	     convert_func = convert_funcs[i];
	     if (convert_func != NULL)
	       val = (@convert_func)(val);
	  }
	array[0] = val;
	list_append (list_of_arrays, array);
     }

   variable nread = 1;
   while (row_data = csv.readrow(), row_data != NULL)
     {
	if (nread >= max_allocated)
	  {
	     max_allocated += dsize;
	     resize_arrays (list_of_arrays, max_allocated);
	  }
	_for i (0, ncols-1, 1)
	  {
	     val = row_data[column_ints[i]];
	     ifnot (strbytelen(val))
	       {
		  list_of_arrays[i][nread] = nan_values[i];
		  continue;
	       }
	     convert_func = convert_funcs[i];
	     if (convert_func == NULL)
	       {
		  list_of_arrays[i][nread] = val;
		  continue;
	       }
	     list_of_arrays[i][nread] = (@convert_func)(val);
	  }
	nread++;
     }
   resize_arrays (list_of_arrays, nread);
   set_struct_fields (datastruct, __push_list(list_of_arrays));
   return datastruct;
}

define csv_parser_new ()
{
   if (_NARGS != 1)
     usage ("\
obj = csv_parser_new (file|fp|strings ; qualifiers);\n\
Qualifiers:\n\
  quote='\"', delim=',', skiplines=0, comment=string");

   variable fp = ();
   variable type = typeof(fp);
   variable func = &read_fp_callback;
   variable func_data;

   variable skiplines = qualifier("skiplines", 0);
   variable delim = qualifier("delim", ',');
   variable quote = qualifier("quote", '"');
   variable comment = qualifier("comment", NULL);
   variable comment_char = (comment == NULL) ? 0 : comment[0];

   if ((type == Array_Type) || (type == List_Type))
     {
	func = &read_strings_callback;
	func_data = struct
	  {
	     strings = fp,
	     i = skiplines, n = length(fp),
	     output_crlf = 0,
	     comment = comment,
	     comment_char = comment_char,
	  };
     }
   else if (typeof (fp) != File_Type)
     {
	fp = fopen (fp, "r");
	if (fp == NULL)
	  throw OpenError, "Unable to open CSV file"$;
	func_data = struct
	  {
	     fp = fp,
	     comment = comment,
	     comment_char = comment_char,
	  };
	variable line;
	loop (skiplines)
	  () = fgets (&line, fp);
     }
   variable csv = struct
     {
	readrow = &read_row,
	readcol = &read_cols,
	csv_parser = _csv_parser_new (func, func_data, delim, quote),
     };

   return csv;
}
