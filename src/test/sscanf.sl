() = evalfile ("inc.sl");

testing_feature ("sscanf");

#ifexists Double_Type
static variable eps = 1.0;
while (1 + eps/2.0 != 1)
  eps /= 2.0;

static define feqs (x, y)
{
   if (x == y)
     return 1;

   % (delta_diff)^2 = (delta_y)^ + (delta_x)^2
   % delta_y = eps * y
   % (delta_diff)^2 = eps*eps (y^2 + x^2)
   % |delta_diff| = eps * sqrt (y^2 + x^2) ~= eps * x *sqrt(2)
   variable diff = y - x;
   if (x < 0) x = -x;
   if (y < 0) y = -y;
   if (diff < 0) diff = -diff;
   variable tol = ((x + y) * eps);

   if (diff <= tol)
     return 1;
   vmessage ("diff = %e, abs(x)*eps = %e, error=%e",
	     diff, tol, diff/(x+y));
   return 1;
}

static variable Inf = 1e1000;
static define test_atof (x)
{
   variable y;
   variable str = sprintf ("%.64e", x);
   variable tstr;

   tstr = strup (strtrim (str));

   if (tstr == "INF")
     y = Inf;
   else if (tstr == "-INF")
     y = -Inf;
   else
     y = atof (str);

   !if (feqs (x,y))
     failed ("%e = atof(%e [%s]): diff = %e\n", y, x, tstr, y-x);
}

static define test_atof_main (n)
{

   loop (n)
     {
	variable a,b,c;
	a = 500 - random () * 1000;
	b = 400 - 800 * random ();
	ERROR_BLOCK
	  {
	     _clear_error ();
	     () = fprintf (stderr, "Floating point exception occured for %g * 10^%g\n",
			   a, b);
	  }
	if (1)
	  {
	     c = a * 10.0^b;
	     test_atof (c);
	  }
     }

   test_atof (random ());
}
test_atof_main (1000);

# ifexists EINVAL
if ((0.0 != atof ("FOO")) || (errno != EINVAL)) failed ("atof FOO");
# endif

#endif				       %  Double_Type


define test_scanf (buf, format, xp, yp, n)
{
   variable nn, x, y;
   nn = sscanf (buf, format, &x, &y);
   if (n != nn)
     failed ("sscanf (%s, %s, &x, &y) ==> returned %d",
	     buf, format, nn);
   if (n >= 1)
     {
	if (x != xp)
	  {
#ifexists Double_Type
	     if ((typeof (x) == Double_Type)
		 or (typeof (x) == Float_Type))
	       {
		  if (1)
		    failed ("sscanf (%s, %s, &x, &y) ==> x = %e, diff=%e",
			    buf, format, x, x - xp);
	       }
	     else
#endif
	       failed ("sscanf (%s, %s, &x, &y) ==> x = %S",
		       buf, format, x);
	  }
     }

   if (n >= 2)
     {
	if (y != yp)
	  {
#ifexists Double_Type
	     if ((typeof (y) == Double_Type)
		 or (typeof (y) == Float_Type))
	       failed ("sscanf (%s, %s, &x, &y) ==> y = %e, diff=%e",
		       buf, format, y, y - yp);
	     else
#endif
	       failed ("sscanf (%s, %s, &x, &y) ==> y = %S",
		       buf, format, y);
	  }
     }
}

test_scanf (" -30,,XX ,,2,3", "%2hd%4s", -3, "0,,X", 2);
test_scanf ("1,2,3", "%d,%2s", 1, "2,", 2);
test_scanf ("1,2 ,3", "%d,%2s", 1, "2", 2);
test_scanf ("1,2 ,3", "%d,%20s", 1, "2", 2);
test_scanf ("1,,,,2,3", "%d,%20s", 1, ",,,2,3", 2);
test_scanf ("1,    ,,,2,3", "%d,%20s", 1, ",,,2,3", 2);
test_scanf ("-30.1,,,,2,3", "%d,%2s", -30, "", 1);
test_scanf (" -30,,XX ,,2,3", "%d%4s", -30, ",,XX", 2);
test_scanf (" -30,,XX ,,2,3", "%hd%4s", -30, ",,XX", 2);
test_scanf (" -30,,XX ,,2,3", "%1hd%4s", -3, "0,,X", 0);
#ifexists Double_Type
test_scanf (" +30.173e-2,,XX ,,2,3", "%lf,,%4s", 30.173e-2, "XX", 2);
test_scanf (" -30.1,,XX ,,2,3", "%lf,,%4s", -30.1, "XX", 2);
test_scanf (" +30.1,,XX ,,2,3", "%lf,,%4s", 30.1, "XX", 2);
test_scanf (" +30.,,XX ,,2,3", "%lf,,%4s", 30.0, "XX", 2);
test_scanf (" +30.173,,XX ,,2,3", "%lf,,%4s", 30.173, "XX", 2);
test_scanf (" +30.173e+2,,XX ,,2,3", "%lf,,%4s", 30.173e2, "XX", 2);
test_scanf (" +30.173e-03,,XX ,,2,3", "%lf,,%4s", 30.173e-3, "XX", 2);
test_scanf (" +30.173E-03,,XX ,,2,3", "%lf,,%4s", 30.173e-3, "XX", 2);
test_scanf ("+.E", "%lf%lf", 0, 0, 0);
test_scanf ("+0.E", "%lf%s", 0, "E", 2);
test_scanf ("-0.E", "%lf%s", 0, "E", 2);
test_scanf ("-0.E-", "%lf%s", 0, "E-", 2);
test_scanf ("-0.E+", "%lf%s", 0, "E+", 2);
test_scanf ("-0.E+X", "%lf%s", 0, "E+X", 2);
test_scanf ("-1.E+0X", "%lf%s", -1, "X", 2);
test_scanf (".000", "%lf", 0.0, "", 1);
test_scanf ("-.000", "%lf", -0.0, "", 1);
test_scanf ("-0+X", "%lf%s", 0, "+X", 2);
test_scanf ("0+X", "%lf%s", 0, "+X", 2);
test_scanf ("0.000000000000E00+X", "%lf%s", 0, "+X", 2);
test_scanf ("1.000000000000E000000001+X", "%lf%s", 10, "+X", 2);
#endif

test_scanf (" hello world", "%s%s", "hello", "world", 2);
test_scanf (" hello world", "%s%c", "hello", ' ', 2);
test_scanf (" hello world", "%s%2c", "hello", " w", 2);
test_scanf (" hello world", "%s%5c", "hello", " worl", 2);
test_scanf (" hello world", "%s%6c", "hello", " world", 2);
test_scanf (" hello world", "%s%7c", "hello", " world", 2);
test_scanf (" hello world", "%s%1000c", "hello", " world", 2);

test_scanf (" hello world", "%*s%c%1000c", ' ', "world", 2);

test_scanf ("abcdefghijk", "%[a-c]%s", "abc", "defghijk", 2);
test_scanf ("abcdefghijk", "%4[a-z]%s", "abcd", "efghijk", 2);
test_scanf ("ab[-]cdefghijk", "%4[]ab]%s", "ab", "[-]cdefghijk", 2);
test_scanf ("ab[-]cdefghijk", "%40[][ab-]%s", "ab[-]", "cdefghijk", 2);
test_scanf ("ab12345cdefghijk", "ab%[^1-9]%s", "", "12345cdefghijk", 2);
test_scanf ("ab12345cdefghijk", "ab%3[^4-5]%s", "123", "45cdefghijk", 2);

% tests " " matching 0 or more whitespace chars
test_scanf ("hel7o world19", " h el %do wor l d%d", 7, 19, 2);

test_scanf ("\t\n", "%s %s", "", "", 0);
test_scanf ("", "%s", "", "", 0);

define test_default_format ()
{
   loop (1000)
     {
	variable x = (2.0 * (random ()-0.5))
	  * 10^(40*(random()-0.5));
	if (x != eval(string(x)))
	  {
	     () = fprintf (stderr, "double %%S format failed for %.17g ==> %S\n", x, x);
	  }
	x = typecast (x, Float_Type);

	if (x != eval(string(x)+"f"))
	  {
	     () = fprintf (stderr, "float %%S format failed for %.17g ==> %S\n", x, x);
	  }
     }
}
test_default_format ();

private define test_bad_formats (str, fmt, varp)
{
   try
     {
	if (0 == sscanf (str, fmt, varp))
	  throw AnyError, "sscanf returned 0-- this is ok";
     }
   catch AnyError: return;

   failed ("expected sscanf(%S,%S,%S) to fail, produced %S", str, fmt, varp, @varp);
}
test_bad_formats ("7", "%d", 14);
test_bad_formats ("7", "%)", &$1);
test_bad_formats ("7", "%", &$1);
test_bad_formats ("7", "%d", &errno);
test_bad_formats ("7", "%d", &sin);
test_bad_formats ("range", "%[a-d", &$1);
test_bad_formats ("range", "%]", &$1);

private define test_other_formats (str, fmt, val)
{
   variable x;
   if (1 != sscanf (str, fmt, &x))
     failed ("scanf (%S. %S. %S) did not return 1", str, fmt, &x);

   if (typeof (x) != typeof (val))
     failed ("sscanf (%S. %S. %S) produced %S, expected %S",
	     str, fmt, &x, typeof(x), typeof(val));

   if (x != val)
     {
	failed ("sscanf (%S, %S, %S) produced %S, expected %S",
		str, fmt, &x, x, val);
     }
}

#ifexists Double_Type
test_other_formats ("2.0", "%e", 2.0f);
test_other_formats ("2.0", "%f", 2.0f);
test_other_formats ("2.0", "%g", 2.0f);
test_other_formats ("2.0", "%E", 2.0);
test_other_formats ("2.0", "%F", 2.0);
#endif
test_other_formats ("255", "%i", 255);
test_other_formats ("0xFF", "%i", 255);
test_other_formats ("0377", "%i", 255);

test_other_formats ("255", "%hi", 255h);
test_other_formats ("0xFF", "%hi", 255h);
test_other_formats ("0377", "%hi", 255h);

test_other_formats ("255", "%li", 255L);
test_other_formats ("0xFF", "%li", 255L);
test_other_formats ("0377", "%li", 255L);

test_other_formats ("255", "%I", 255L);
test_other_formats ("0xFF", "%I", 255L);
test_other_formats ("0XFF", "%I", 255L);
test_other_formats ("0377", "%I", 255L);

test_other_formats ("FF", "%x", 255u);
test_other_formats ("FF", "%hx", 255uh);
test_other_formats ("FF", "%lx", 255UL);
test_other_formats ("FF", "%X", 255UL);

test_other_formats ("377", "%o", 255U);
test_other_formats ("377", "%ho", 255uh);
test_other_formats ("377", "%lo", 255UL);
test_other_formats ("377", "%O", 255UL);

test_other_formats ("1234", "%u", 1234U);
test_other_formats ("1234", "%hu", 1234UH);
test_other_formats ("1234", "%lu", 1234UL);
test_other_formats ("1234", "%U", 1234UL);

private define is_equal (x, y)
{
   if (x == y) return 1;
#ifexists isnan
   if (isnan (x) && isnan (y))
     return 1;
#endif
   return 0;
}

private define test_2weird (str, fmt, x, y)
{
   variable a, b;
   if ((2 != sscanf (str, fmt, &a, &b))
       || (0 == is_equal(a, x))
       || (0 == is_equal(b, y)))
     failed ("sscanf (%S, %S): expected %S, %S", str, fmt, x, y);
}

#ifexists Double_Type
test_2weird ("-nan:4", "%f:%d", _NaN, 4);
test_2weird ("-nan():4", "%f:%d", _NaN, 4);
test_2weird ("-nan(here):4", "%f:%d", _NaN, 4);
test_2weird ("Inf:4", "%f:%d", _Inf, 4);
test_2weird ("Infinity:4", "%f:%d", _Inf, 4);
test_2weird ("-Inf:4", "%f:%d", -_Inf, 4);
test_2weird ("-Infinity:4", "%f:%d", -_Inf, 4);
#endif

print ("Ok\n");

exit (0);

