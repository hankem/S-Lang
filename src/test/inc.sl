#ifexists _slsyswrap_set_syscall_failure
% Every file loads this-- do not subject it to syscall failures everytime
private variable Inc_Syscall = _slsyswrap_set_syscall_failure (0);
#endif

define slsyswrap_set_syscall_failure (n)
{
#ifexists _slsyswrap_set_syscall_failure
   return _slsyswrap_set_syscall_failure (n);
#else
   return -1;
#endif
}


define print (x)
{
   x = string (x);
   () = fputs (x, stdout);
   () = fflush (stdout);
}

define testing_feature (f)
{
   variable u = "", nl = "";
   if (_slang_utf8_ok) u = " [UTF-8 mode]";
   if (f[-1] == '\n')
     {
	f = strtrim (f);
	nl = "\n";
     }
   () = fprintf (stdout, "Testing %s%s ...%s", f, u, nl);
   () = fflush (stdout);
}

new_exception ("TestError", AnyError, "Test Error");

define failed ()
{
   () = slsyswrap_set_syscall_failure (0);
   variable s = __pop_args (_NARGS);
   s = sprintf (__push_args(s));
   %() = fprintf (stderr, "Failed: %s\n", s);
   throw TestError, sprintf ("Failed: %s [utf8=%d]\n", s, _slang_utf8_ok);
   exit (1);
}

private variable _Random_Seed = 123456789UL * _time ();
$1 = getenv ("SLSYSWRAP_RANDSEED");
if ($1 != NULL) _Random_Seed = typecast (atol($1), ULong_Type);

define random ()
{
   _Random_Seed = (_Random_Seed * 69069UL + 1013904243UL)&0xFFFFFFFFUL;
   return _Random_Seed/4294967296.0;
}

define random_integer (maxn)
{
   _Random_Seed = (_Random_Seed * 69069UL + 1013904243UL)&0xFFFFFFFFUL;
   return int(_Random_Seed mod maxn);
}

define urand ()
{
   variable scf = slsyswrap_set_syscall_failure (0);
   EXIT_BLOCK
     {
	() = slsyswrap_set_syscall_failure (scf);
     }

   if (_NARGS == 0)
     return random ();
   variable n = ();
   variable x = Double_Type [n];
   _for (0, n-1, 1)
     {
	variable i = ();
	x[i] = random ();
     }
   return x;
}

define util_make_tmp_file (prefix, fdp)
{
   variable scf = slsyswrap_set_syscall_failure (0);
   EXIT_BLOCK
     {
	() = slsyswrap_set_syscall_failure (scf);
     }

   variable fmt = prefix + "%08X.tmp";
   variable flags = O_WRONLY|O_EXCL|O_CREAT|O_BINARY;

   loop (10000)
     {
	variable file = sprintf (fmt, random_integer (0xFFFFFFFFUL));
	forever
	  {
	     variable fd = open (file, flags, 0600);
	     if (fd != NULL)
	       {
		  if (fdp != NULL) @fdp = fd;
		  return file;
	       }
	     if (errno == EEXIST)
	       break;
	     failed ("Could not open tmp file %s: %s", file, errno_string());
	  }
     }
   failed ("Could not create a tmp file with prefix %s", prefix);
}

define util_make_tmp_dir (prefix)
{
   variable scf = slsyswrap_set_syscall_failure (0);
   EXIT_BLOCK
     {
	() = slsyswrap_set_syscall_failure (scf);
     }

   variable fmt = prefix + "%08X.dir";
   variable flags = O_WRONLY|O_EXCL|O_CREAT|O_BINARY;
   variable mode = 0700;

   loop (10000)
     {
	variable file = sprintf (fmt, random_integer (0xFFFFFFFFUL));
	forever
	  {
	     if (0 == mkdir (file, mode))
	       return file;
	     if (errno == EEXIST)
	       break;
	     failed ("Could not create tmp directory %s: %s", file, errno_string());
	  }
     }
   failed ("Could not create a tmp directory with prefix %s", prefix);
}

variable Util_Arith_Types
  = [Char_Type, UChar_Type, Short_Type, UShort_Type,
     Int_Type, UInt_Type, Long_Type, ULong_Type,
#ifexists Double_Type
     Float_Type, Double_Type,
#endif
#ifexists LLong_Type
     LLong_Type, ULLong_Type,
#endif
    ];

variable Util_Signed_Arith_Types
  = [Char_Type, Short_Type, Int_Type, Long_Type,
#ifexists Double_Type
     Float_Type, Double_Type,
#endif
#ifexists LLong_Type
     LLong_Type,
#endif
    ];

#ifexists _slsyswrap_set_syscall_failure
() = slsyswrap_set_syscall_failure (Inc_Syscall);
#endif
