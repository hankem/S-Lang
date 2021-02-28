private variable Type_Info_List = {};
private define add_type_info (ctype, sltype, fname,
			      isdefined, ifnot_alias, elsealias,
			      isfloat, rank)
{
   variable is_small_int = is_substr (ctype, "short") || is_substr(ctype, "char");
   variable is_unsigned = is_substr (ctype, "unsigned");
   variable pow_function = "pow((double)(a),(double)(b))";
   variable pow_result_type = "double";
   if (ctype == "float") pow_result_type = "float";
   if (ctype == "long double")
     {
	pow_function = "lpow(($ctype)(a),($ctype)(b))"$;
	pow_result_type = ctype;
     }

   variable fname_signed = fname, ctype_unsigned = ctype;
   if (is_unsigned)
     {
	fname_signed = fname_signed[[1:]];   %  uint --> int
	ctype_unsigned = strtrim (strreplace(ctype, "unsigned", ""));
     }

   % fname_signed is the signed counterpart of an unsigned name

   variable s = struct
     {
	ctype = ctype, sltype = sltype, fname = fname,
	fname_signed = fname_signed, isdefined = isdefined,
	ifnot_alias = ifnot_alias, else_alias = elsealias,
	isfloat = isfloat, is_unsigned = is_unsigned,
	rank = rank, is_small_int = is_small_int,
	pow_function = "pow((double)(a),(double)(b))",
	pow_result_type = "double",
	mod_function = "((a) % (b))",
	abs_function = (is_unsigned) ? "(a)" : "abs(a)",
	push_scalar_fun = "SLclass_push_${fname_signed}_obj(SLANG_${sltype}_TYPE, ($ctype_unsigned)(a))"$,
	push_pow_fun = "SLclass_push_double_obj(SLANG_DOUBLE_TYPE, (a))",
     };

   if (is_small_int)
     {
	s.push_scalar_fun = "SLclass_push_int_obj(SLANG_INT_TYPE, (int)(a))";
     }

   if (ctype == "long") s.abs_function = "labs(a)";
   if (ctype == "long long") s.abs_function = ("(((a) >= 0) ? (a) : -(a))");
   if (ctype == "float")
     {
	s.pow_result_type = ctype;
	s.mod_function = "(float)fmod((a),(b))";
	s.abs_function = "(float)fabs((double)(a))";
	s.push_pow_fun = "SLclass_push_float_obj(SLANG_FLOAT_TYPE,(a))";
     }
   if (ctype == "double")
     {
	s.mod_function = "fmod((a),(b))";
	s.abs_function = "fabs(a)";
     }
   if (ctype == "long double")
     {
	s.pow_function = "lpow(($ctype)(a),($ctype)(b))"$;
	s.pow_result_type = ctype;
	s.abs_function = "fabsl(a)";
	s.mod_function = "fmodl((a),(b))";
	s.push_pow_fun = "SLclass_push_ldouble_obj(SLANG_LDOUBLE_TYPE,(a))";
     }
   %print (s);
   list_append (Type_Info_List, s);
}

add_type_info ("signed char", "CHAR", "char", NULL, NULL, NULL, 0, 1);
add_type_info ("unsigned char", "UCHAR", "uchar", NULL, NULL, NULL, 0, 1);
add_type_info ("short", "SHORT", "short", NULL, "SHORT_IS_NOT_INT", "int", 0, 2);
add_type_info ("unsigned short", "USHORT", "ushort", NULL, "SHORT_IS_NOT_INT", "uint", 0, 2);
add_type_info ("int", "INT", "int", NULL, NULL, NULL, 0, 3);
add_type_info ("unsigned int", "UINT", "uint", NULL, NULL, NULL, 0, 3);
add_type_info ("long", "LONG", "long", NULL, "LONG_IS_NOT_INT", "int", 0, 4);
add_type_info ("unsigned long", "ULONG", "ulong", NULL, "LONG_IS_NOT_INT", "uint", 0, 4);
add_type_info ("long long", "LLONG", "llong", "defined(HAVE_LONG_LONG)", "LLONG_IS_NOT_LONG", "long", 0, 5);
add_type_info ("unsigned long long", "ULLONG", "ullong", "defined(HAVE_LONG_LONG)", "LLONG_IS_NOT_LONG", "ulong", 0, 5);
add_type_info ("float", "FLOAT", "float", "SLANG_HAS_FLOAT", NULL, NULL, 1, 6);
add_type_info ("double", "DOUBLE", "double", "SLANG_HAS_FLOAT", NULL, NULL, 1, 7);
add_type_info ("long double", "LDOUBLE", "ldouble", "defined(HAVE_LONG_DOUBLE)", NULL, NULL, 1, 8);

private variable Indent = 0;

private define output (s)
{
   () = fputs (s, stdout);
}

private define indent ()
{
   loop (Indent)
     output (" ");
}

private define output_if (s)
{
   if (s == NULL) return;
   indent ();
   () = fprintf (stdout, "#if %s\n", s);
   Indent++;
}

private define output_else ()
{
   Indent--;
   indent ();
   () = fprintf (stdout, "#else\n");
   Indent++;
}

private define output_endif (s)
{
   Indent--;
   indent ();
   () = fprintf (stdout, "#endif /* %S */\n", s);
}

private define output_define (a,b)
{
   indent ();
   () = fprintf (stdout, "#define %s %S\n", a, b);
}

private define output_comment (s)
{
   () = fprintf (stdout, "/* %S */\n", s);
}

private define output_newline ()
{
   () = fputs ("\n", stdout);
}

private define output_include (s)
{
   indent ();
   () = fprintf (stdout, "#include %S\n", s);
}

private define mk_to_double_table ()
{
   output_if ("SLANG_HAS_FLOAT");
   output ("static To_Double_Fun_Table_Type To_Double_Fun_Table [MAX_ARITHMETIC_TYPES] =\n{\n");

   variable ainfo;
   foreach ainfo (Type_Info_List)
     {
	variable fname = ainfo.fname, ctype = ainfo.ctype;

	output_if (ainfo.isdefined);
	output ("   {sizeof(${ctype}), ${fname}_to_one_double},\n"$);
	if (ainfo.isdefined != NULL)
	  {
	     output_else();
	     output("   {0, NULL},\n");
	     output_endif(ainfo.isdefined);
	  }
     }
   output ("};\n");
   output_endif ("SLANG_HAS_FLOAT");
   output_newline ();
}

private define mk_binary_matrix ()
{
   output ("static Binary_Matrix_Type Binary_Matrix [MAX_ARITHMETIC_TYPES][MAX_ARITHMETIC_TYPES] =\n{\n");

   variable ainfo, binfo;

   foreach ainfo (Type_Info_List)
     {
	variable actype = ainfo.ctype;
	variable afname = ainfo.fname;

	output_comment (actype);

	if (ainfo.isdefined != NULL) output_if (ainfo.isdefined);

	output ( "   {\n");
	foreach binfo (Type_Info_List)
	  {
	     variable bfname = binfo.fname;

	     output_if (binfo.isdefined);

	     variable copy_function = "(SLFvoid_Star)copy_${afname}_to_${bfname}"$;
	     variable bin_func_name = "${afname}_${bfname}_bin_op"$;
	     variable conv_function = "${afname}_to_${bfname}"$;

	     output ("     {${copy_function}, ${conv_function}, ${bin_func_name}},\n"$);
	     if (binfo.isdefined != NULL)
	       {
		  output_else ();
		  output ("     {NULL, NULL, NULL},\n");
		  output_endif (binfo.isdefined);
	       }
	  }
	output ("   },\n");

	if (ainfo.isdefined != NULL)
	  {
	     output_else ();
	     output ("   {\n");
	     loop (length (Type_Info_List))
	       {
		  output ("     {NULL, NULL, NULL},\n");
	       }
	     output ("   },\n");
	     output_endif (ainfo.isdefined);
	  }
     }
   output ("};\n\n");
}

private define mk_defines ()
{
   variable ainfo, binfo;
   foreach ainfo (Type_Info_List)
     {
	variable afname = ainfo.fname;
	variable actype = ainfo.ctype;
	variable afname_signed = ainfo.fname_signed;

	variable cmp_func_name = "${afname}_cmp_function"$;
	variable unary_func_name = "${afname}_unary_op"$;
	variable to_binary_func_name = NULL;
	if ((ainfo.isfloat == 0) && (ainfo.is_unsigned))
	  to_binary_func_name = "${afname}_to_binary"$;
	variable to_double_funct_name = "${afname}_to_one_double"$;

	output_comment (actype);
	output_if (ainfo.isdefined);
	output_if (ainfo.ifnot_alias);

	foreach binfo (Type_Info_List)
	  {
	     variable bfname = binfo.fname;
	     variable bctype = binfo.ctype;
	     variable bfname_signed = binfo.fname_signed;

	     variable bin_func_name = "${afname}_${bfname}_bin_op"$;
	     variable scalar_bin_func_name = "${afname}_${bfname}_scalar_bin_op"$;
	     variable copy_function = "copy_${afname}_to_${bfname}"$;
	     variable conv_function = "${afname}_to_${bfname}"$;

	     output_comment ("(${actype}, ${bctype})"$);
	     if (ainfo != binfo)
	       {
		  output_if (binfo.isdefined);
		  output_if (binfo.ifnot_alias);
	       }

	     % To reduce the code size, create binary functions for
	     % the diagonal terms or off-diagonal elements involving
	     % int and double
	     variable off_diagonal_types = ["int", "double"];
	     if ((ainfo == binfo)
		 || any (actype == off_diagonal_types)
		 || any (bctype == off_diagonal_types))
	       {
		  output_define ("GENERIC_BINARY_FUNCTION", bin_func_name);
	       }
	     else
	       output_define (bin_func_name, "NULL");

	     output_define ("GENERIC_A_TYPE", actype);
	     if (ainfo.is_unsigned) output_define ("GENERIC_A_TYPE_UNSIGNED", "1");

	     output_define ("GENERIC_B_TYPE", bctype);
	     if (binfo.is_unsigned) output_define ("GENERIC_B_TYPE_UNSIGNED", "1");

	     if (ainfo.is_small_int && binfo.is_small_int)
	       output_define ("GENERIC_C_TYPE", "int");
	     else if (actype == bctype)
	       output_define ("GENERIC_C_TYPE", actype);
	     else if (ainfo.rank > binfo.rank)
	       output_define ("GENERIC_C_TYPE", actype);
	     else if ((binfo.rank > ainfo.rank) || (binfo.is_unsigned))
	       output_define ("GENERIC_C_TYPE", bctype);
	     else
	       output_define ("GENERIC_C_TYPE", actype);

	     variable is_integer = not (ainfo.isfloat || binfo.isfloat);
	     if (is_integer)
	       output_define ("GENERIC_BIT_OPERATIONS", 1);
	     output_define ("TRAP_DIV_ZERO", is_integer);

	     if (ainfo.rank >= binfo.rank)
	       {
		  output_define ("POW_FUNCTION(a,b)", ainfo.pow_function);
		  output_define ("POW_RESULT_TYPE", ainfo.pow_result_type);
		  output_define ("MOD_FUNCTION(a,b)", ainfo.mod_function);
	       }
	     else
	       {
		  output_define ("POW_FUNCTION(a,b)", binfo.pow_function);
		  output_define ("POW_RESULT_TYPE", binfo.pow_result_type);
		  output_define ("MOD_FUNCTION(a,b)", binfo.mod_function);
	       }

	     if (ainfo == binfo)
	       {
		  % The scalar binary functions are currently used on
		  % the diagonal.
		  if (ainfo.is_small_int)
		    {
		       output_define (scalar_bin_func_name, "int_int_scalar_bin_op");
		    }
		  else
		    {
		       output_define ("SCALAR_BINARY_FUNCTION", scalar_bin_func_name);
		       output_define ("PUSH_SCALAR_OBJ_FUN(a)", ainfo.push_scalar_fun);
		       output_define ("PUSH_POW_OBJ_FUN(a)", ainfo.push_pow_fun);
		    }

		  output_define ("GENERIC_UNARY_FUNCTION", unary_func_name);
		  output_define ("ABS_FUNCTION(a)", ainfo.abs_function);
		  output_define ("CMP_FUNCTION", cmp_func_name);
		  if (to_binary_func_name != NULL)
		    output_define ("TO_BINARY_FUNCTION", to_binary_func_name);

		  output_define ("TO_DOUBLE_FUNCTION", to_double_funct_name);
	       }

	     if ((ainfo.rank == binfo.rank)
		 && (ainfo.is_unsigned || binfo.is_unsigned))
	       {
		  % The same function may be used to copy both the
		  % unsigned and signed integers of the same rank.
		  output_define (copy_function, "copy_${afname_signed}_to_${bfname_signed}"$);
	       }
	     else
	       {
		  output_define ("GENERIC_COPY_FUNCTION", copy_function);
	       }

	     % The convert function is only used to covert to higher ranked objects
	     if (ainfo.rank <= binfo.rank)
	       {
		  % Small ints always get converted to int
		  if (binfo.is_small_int)
		    output_define (conv_function, "${afname}_to_int"$);
		  else if (ainfo.rank == binfo.rank)
		    output_define (conv_function, "convert_self_to_self");
		  else
		    output_define ("GENERIC_CONVERT_FUNCTION", conv_function);
	       }
	     else
	       output_define (conv_function, "NULL");

	     output_include ("\"slarith.inc\"");

	     if (ainfo != binfo)
	       {
		  variable belse_alias = binfo.else_alias;
		  if (belse_alias != NULL)
		    {
		       output_else ();
		       output_define (bin_func_name, "${afname}_${belse_alias}_bin_op"$);
		       output_define (copy_function, "copy_${afname}_to_${belse_alias}"$);
		       output_define (conv_function, "${afname}_to_${belse_alias}"$);

		       %if (ainfo == binfo) output_define (scalar_bin_func_name, "${afname}_${belse_alias}_scalar_bin_op"$);

		       output_endif (binfo.ifnot_alias);
		    }
		  if (binfo.isdefined != NULL) output_endif (binfo.isdefined);
	       }
	     output_newline ();
	  }

	variable aelse_alias = ainfo.else_alias;
	if (aelse_alias != NULL)
	  {
	     output_else ();
	     foreach binfo (Type_Info_List)
	       {
		  bfname = binfo.fname;
		  variable bfname1 = bfname;
		  if (binfo == ainfo)
		    {
		       bfname1 = aelse_alias;
		    }

		  output_define ("${afname}_${bfname}_bin_op"$, "${aelse_alias}_${bfname1}_bin_op"$);
		  output_define ("${afname}_${bfname}_scalar_bin_op"$, "${aelse_alias}_${bfname1}_scalar_bin_op"$);
		  output_define ("copy_${afname}_to_${bfname}"$, "copy_${aelse_alias}_to_${bfname1}"$);
		  output_define ("${afname}_to_${bfname}"$, "${aelse_alias}_to_${bfname1}"$);
	       }

	     output_define (unary_func_name, "${aelse_alias}_unary_op"$);
	     output_define (cmp_func_name, "${aelse_alias}_cmp_function"$);
	     if (to_binary_func_name != NULL)
	       output_define (to_binary_func_name, "${aelse_alias}_to_binary"$);
	     output_define (to_double_funct_name, "${aelse_alias}_to_one_double"$);

	     output_endif (ainfo.ifnot_alias);
	  }
	if (ainfo.isdefined != NULL) output_endif (ainfo.isdefined);
	output_newline ();
     }

   output_newline ();
}

define slsh_main ()
{
   () = fputs ("/* DO NOT EDIT -- this file was generated by src/util/mkslarith2.sl */\n", stdout);

   mk_defines ();
   mk_binary_matrix ();
   mk_to_double_table ();
}
