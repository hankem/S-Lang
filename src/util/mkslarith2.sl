#!/usr/bin/env slsh

private variable CTypes =
  ["signed char", "unsigned char", "short", "unsigned short", "int", "unsigned int",
   "long", "unsigned long", "long long", "unsigned long long",
   "float", "double", "long double"];
private variable Is_Int_Type =
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0];

private variable Precedence =
  [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 5, 6];

private variable SLTypes =
  ["CHAR", "UCHAR", "SHORT", "USHORT", "INT", "UINT",
   "LONG", "ULONG", "LLONG", "ULLONG",
   "FLOAT", "DOUBLE", "LDOUBLE"];
private variable FNames =
  ["char", "uchar", "short", "ushort", "int", "uint",
   "long", "ulong", "llong", "ullong",
   "float", "double", "ldouble"];
% private variable Compile_If =
%   ["", "", "SHORT_IS_NOT_INT", "SHORT_IS_NOT_INT", "", "",
%    "LONG_IS_NOT_INT", "LONG_IS_NOT_INT",
%    "defined(HAVE_LONG_LONG)", "defined(HAVE_LONG_LONG)",
%    "SLANG_HAS_FLOAT", "SLANG_HAS_FLOAT", "defined(HAVE_LONG_DOUBLE)"];
private variable Compile_If =
  ["", "", "", "", "", "", "", "",
   "defined(HAVE_LONG_LONG)", "defined(HAVE_LONG_LONG)",
   "SLANG_HAS_FLOAT", "SLANG_HAS_FLOAT", "defined(HAVE_LONG_DOUBLE)"];

private variable Else_Alias =
  ["", "", "int", "uint", "", "", "int", "uint", "", "", "", "", ""];

define mkarith_copy_funs (fp)
{
   variable ntypes = length (CTypes);
   variable i, j;
   _for i (0, ntypes-1, 1)
     {
	variable ctype = CTypes[i];
	variable is_int = Is_Int_Type[i];
	variable sltype = SLTypes[i];
	variable fname = FNames[i];
	variable compile_if = Compile_If[i];
	variable prec = Precedence[i];
	variable else_alias = Else_Alias[i];
	variable s_fname = fname;
	if (s_fname[0] == 'u') s_fname = substr (s_fname, 2, -1);

	() = fprintf (fp, "/* ------------ %s ---------- */\n", ctype);

	if (compile_if != "")
	  () = fprintf (fp, "#if %s\n", compile_if);

	variable is_long = (s_fname == "long");

	_for j (0, ntypes-1, 1)
	  {
	     variable ctype1 = CTypes[j];
	     variable is_int1 = Is_Int_Type[j];
	     variable sltype1 = SLTypes[j];
	     variable fname1 = FNames[j];
	     variable compile_if1 = Compile_If[j];
	     variable else_alias1 = Else_Alias[j];
	     variable prec1 = Precedence[j];
	     variable s_fname1;

	     if (compile_if1 != "")
	       () = fprintf (fp, "#if %s\n", compile_if1);

	     s_fname1 = fname1;
	     if (s_fname1[0] == 'u') s_fname1 = substr (s_fname1, 2, -1);
	     variable is_long1 = (s_fname1 == "long");
	     variable is_conditional = is_long || is_long1;

	     variable def1 = sprintf ("copy_%s_to_%s", fname, fname1);
	     variable def2 = sprintf ("%s_to_%s", fname, fname1);

	     if ((s_fname1 == s_fname)
		 and ((s_fname1 != fname1) or (s_fname != fname)))
	       () = fprintf (fp, "#define copy_%s_to_%s\tcopy_%s_to_%s\n",
			   fname, fname1, s_fname, s_fname1);
	     else
	       {
		  if (is_conditional)
		    {
		       () = fputs ("#if LONG_IS_INT\n", fp);
		       if (is_long1)
			 () = fputs ("# define $def1 copy_${fname}_to_${else_alias1}\n"$, fp);
		       else
			 () = fputs ("# define $def1 copy_${else_alias}_to_${fname1}\n"$, fp);
		       () = fputs ("#else\n", fp);
		    }
		  () = fputs ("DEFUN_1($def1,$ctype,$ctype1)\n"$, fp);
		  if (is_conditional)
		    () = fputs ("#endif\n", fp);
	       }

	     if (prec < prec1)
	       {
		  if (is_conditional)
		    {
		       () = fputs ("#if LONG_IS_INT\n", fp);
		       if (is_long1)
			 () = fputs ("# define $def2 ${fname}_to_${else_alias1}\n"$, fp);
		       else
			 () = fputs ("# define $def2 ${else_alias}_to_${fname1}\n"$, fp);
		       () = fputs ("#else\n", fp);
		    }
		  () = fputs ("DEFUN_2($def2,$ctype,$ctype1,$def1)\n"$, fp);
		  if (is_conditional)
		    () = fputs ("#endif\n", fp);
	       }
	     else
	       {
		  () = fprintf (fp, "#define %s_to_%s\tNULL\n", fname, fname1);
	       }
#iffalse
	     if (else_alias != "")
	       {
		  () = fprintf (fp, "#else\n");
		  () = fprintf (fp, "# define copy_%s_to_%s\tcopy_%s_to_%s\n",
				fname, fname1, fname, else_alias);
		  if (prec < prec1)
		    {
		       if (fname != else_alias)
			 () = fprintf (fp, "# define %s_to_%s\t%s_to_%s\n",
				       fname, fname1, fname, else_alias);
		    }
	       }
#endif
	     if (compile_if1 != "")
	       () = fprintf (fp, "#endif /* %s */\n", compile_if1);
	  }

	() = fprintf (fp, "#if SLANG_HAS_FLOAT\n");
	() = fprintf (fp, "TO_DOUBLE_FUN(%s_to_one_double,%s)\n",
		      fname, ctype);
	() = fprintf (fp, "#endif\n");

	if (compile_if != "")
	  () = fprintf (fp, "#endif /* %s */\n", compile_if);

	() = fprintf (fp, "\n");
     }
}

define mk_to_double_table (fp)
{
   variable ntypes = length (CTypes);

   () = fprintf (fp, "#if SLANG_HAS_FLOAT\n");
   () = fprintf (fp, "static To_Double_Fun_Table_Type To_Double_Fun_Table [MAX_ARITHMETIC_TYPES] =\n{\n");

   variable i;
   _for i (0, ntypes-1, 1)
     {
	variable ctype = CTypes[i];
	variable compile_if = Compile_If[i];
	variable fname = FNames[i];

	if (compile_if != "")
	  () = fprintf (fp, "#if %s\n", compile_if);
	() = fprintf (fp, "   {sizeof(%s), %s_to_one_double},\n", ctype, fname);
	if (compile_if != "")
	  {
	     () = fprintf (fp, "#else\n");
	     () = fprintf (fp, "   {0, NULL},\n#endif\n");
	  }
     }
   () = fprintf (fp, "};\n#endif\n\n");
}

private define mk_binary_table (fp)
{
   variable ntypes = length (CTypes);
   variable i, j;

   () = fprintf (fp, "static Binary_Matrix_Type Binary_Matrix [MAX_ARITHMETIC_TYPES][MAX_ARITHMETIC_TYPES] =\n{\n");

   _for i (0, ntypes-1, 1)
     {
	variable fname = FNames[i];
	variable compile_if = Compile_If[i];

	() = fprintf (fp, "   /* %s */\n", CTypes[i]);

	if (compile_if != "")
	  () = fprintf (fp, "#if %s\n", compile_if);

	() = fprintf (fp, "   {\n");

	_for j (0, ntypes-1, 1)
	  {
	     variable fname1 = FNames[j];
	     variable compile_if1 = Compile_If[j];

	     if (compile_if1 != "")
	       () = fprintf (fp, "#if %s\n", compile_if1);

	     () = fprintf (fp, "     {(FVOID_STAR)copy_%s_to_%s, %s_to_%s},\n",
			   fname, fname1, fname, fname1);

	     if (compile_if1 == "")
	       continue;

	     () = fprintf (fp, "#else\n");
	     () = fprintf (fp, "     {NULL, NULL},\n");
	     () = fprintf (fp, "#endif\n");
	  }

	() = fprintf (fp, "   },\n");
	if (compile_if == "")
	  continue;

	() = fprintf (fp, "#else\n");

	() = fprintf (fp, "   {\n");
	loop (ntypes)
	  () = fprintf (fp, "     {NULL, NULL},\n");
	() = fprintf (fp, "   },\n");
	() = fprintf (fp, "#endif /* %s */\n\n", compile_if);
     }
   () = fprintf (fp, "};\n\n");
}

define slsh_main ()
{
   variable fp = fopen ("slarith2.inc", "w");
   () = fputs ("/* DO NOT EDIT -- this file was generated by src/util/mkslarith2.sl */\n", fp);
   mkarith_copy_funs (fp);
   mk_to_double_table (fp);
   mk_binary_table (fp);
   () = fclose (fp);
}
