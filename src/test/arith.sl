() = evalfile ("inc.sl");

testing_feature ("Arithmetic");

static define test_value (a, b)
{
   if (a != b)
     failed ("test_value: %S != %S", a, b);
}

test_value ('\x1', 1);
test_value ('\x11', 0x11);
test_value ('\x{111}', 0x111);
test_value ('\x80', 128);
test_value ('\x81', 129);
test_value ('\xFF', 255);
test_value ('\d255', 255);
test_value ('\d8', 8);

static variable G = 11;
define check_global_local ()
{
   variable x = 1;
   if (G + 1 != 12)
     failed ("global + int");
   if (1 + G != 12)
     failed ("int + global");
   if (x + 11 != 12)
     failed ("local + int");
   if (11 + x != 12)
     failed ("int + local");
   if (x + x != 2)
     failed ("local + local");
   if (x + G != 12)
     failed ("local + global");
   if (G + x != 12)
     failed ("global + local");
   if (1 + 11 != 12)
     failed ("int + int");

   variable y = 3;
   x = 37; x = x + 3;
   if (x != 40)
     failed ("x = x + 3");
   x = 37; x = 3 + x;
   if (x != 40)
     failed ("x = 3 + x");
   x = 37; x = x + y;
   if (x != 40)
     failed ("x = x + y");
#ifexists Double_Type
   x = 37; x = x + 3.0;
   if (x != 40.0)
     failed ("x = x + 3.0");
   x = 37; x = 3.0 + x;
   if (x != 40.0)
     failed ("x = 3.0 + x");
#endif
}
check_global_local ();

define check_typeof (expr, type)
{
   if (typeof (expr) != type)
     verror ("typeof(%S) ==> %S, not %S as expected",
	     expr, typeof(expr), type);
}

define check_bool (i)
{
   check_typeof (i == i, Char_Type);
}

define check_sum_result (i, j, k)
{
   if (k != i + j)
     failed (sprintf("%S + %S != %S", typeof (i), typeof(j), typeof(k)));
}

check_typeof('a', UChar_Type);
check_typeof(1h, Short_Type);
check_typeof(1hu, UShort_Type);
check_typeof(0x20hu, UShort_Type);
check_typeof(1, Integer_Type);
check_typeof(0x20, Integer_Type);
check_typeof(1u, UInteger_Type);
check_typeof(1LU, ULong_Type);
#ifexists Double_Type
check_typeof(1f, Float_Type);
check_typeof(1e10f, Float_Type);
check_typeof(.1e10f, Float_Type);
check_typeof(.1e10, Double_Type);
#endif
check_typeof(~'a', UChar_Type);
check_typeof(~1h, Short_Type);
check_typeof(~1hu, UShort_Type);
check_typeof(~0x20hu, UShort_Type);
check_typeof(~1, Integer_Type);
check_typeof(~0x20, Integer_Type);
check_typeof(~1u, UInteger_Type);
check_typeof(~1LU, ULong_Type);

check_typeof ('a' + 'b', Integer_Type);
check_typeof (1h + 'b', Integer_Type);

if (Integer_Type == Short_Type) check_typeof (1hu + 'b', UInteger_Type);
else check_typeof (1hu + 'b', Integer_Type);

check_typeof (1u + 1, UInteger_Type);

define check_typeof_in_func ()
{
   check_typeof (1 & 1UL, ULong_Type);
   check_typeof (1 & 1, Int_Type);
   check_typeof (1 & 1uh, Int_Type);
   check_typeof (1UL & 1uh, ULong_Type);
}
check_typeof_in_func ();

if (Integer_Type == Long_Type) check_typeof (1u + 1L, ULong_Type);
else  check_typeof (1u + 1L, Long_Type);

check_typeof (1u + 1UL, ULong_Type);
#ifexists Double_Type
check_typeof (1u + 1.0f, Float_Type);
check_typeof (1u + 1.0, Double_Type);
#endif
#ifexists Complex_Type
check_typeof ('c' * 1i, Complex_Type);
check_typeof (1h * 1i, Complex_Type);
check_typeof (1.0 * 1i, Complex_Type);
check_typeof (1i * 1i, Complex_Type);
#endif

check_bool ('a');
check_bool (1h);
check_bool (1hu);
check_bool (1);
check_bool (1u);
check_bool (1L);
check_bool (1LU);
#ifexists Double_Type
check_bool (1f);
check_bool (1.0);
#endif
#ifexists Complex_Type
check_bool (1.0i);
#endif

#ifexists Complex_Type
check_typeof (Real(1), Double_Type);
check_typeof (Real('a'), Double_Type);
check_typeof (Real(1L), Double_Type);
check_typeof (Real(1f), Float_Type);
check_typeof (Real(1.0), Double_Type);
#endif

check_sum_result (1, 1, 2);
check_sum_result (1, 0x31, 50);
check_sum_result (1, '1', 50);
check_sum_result (1L, '1', 50L);
check_sum_result (1L, 1h, 2L);
check_sum_result (1, 1h, 2);
check_sum_result (1h, '1', 50);
check_sum_result (1u, 3, 4);
check_sum_result (1UL, '\x3', 4UL);

#ifexists Complex_Type
private define check_complex_real_binary (z)
{
   if ((z * 1.0) != z) failed ("complex %S*1.0", z);
   if ((z / 1.0) != z) failed ("complex %S/1.0", z);
   if ((z * 1L) != z) failed ("complex %S*1L", z);
   if ((z / 1L) != z) failed ("complex %S/1L", z);

   if ((z + 0.0) != z) failed ("complex %S+0.0", z);
   if ((z - 0.0) != z) failed ("complex %S-0.0", z);
   if ((z + 0L) != z) failed ("complex %S+0.0", z);
   if ((z - 0L) != z) failed ("complex %S-0.0", z);

   if ((1.0 * z) != z) failed ("complex 1.0*%S", z);
   if ((0.0 + z) != z) failed ("complex 1.0+%S", z);
   if ((0.0 - z) != -z) failed ("complex 1.0-%S", z);

   if ((1L * z) != z) failed ("complex 1L*%S", z);
   if ((0L + z) != z) failed ("complex 1.0+%S", z);
   if ((0L - z) != -z) failed ("complex 1.0-%S", z);

   if (((1i*z) / (1.0i)) != z) failed ("complex (1i*%S)/(1i)", z);
   if (z/(1+0i) != z) failed ("complex (1i*%S)/(1i)", z);

   if (Real(z) == 0)
     {
	ifnot (Imag (z) == -1i*z) failed ("double==complex");
	ifnot (-1i*z == Imag(z)) failed ("complex==double");

	if ((-1i*z != Imag(z)) || (Imag(z) != -1i*z))
	  failed ("imag z");
     }

   variable z2, w, z1, x, y, zz, diff;

   x = Real(z); y = Imag(z);
   z2 = z^2.0, zz = z*z;
   diff = abs (z2-zz);

   z2 = 2.0^z;
   zz = exp (z*log(2.0));
   diff = abs (z2-zz);
   if (diff > 1e-13) failed ("%S^%S", 2.0, z);
   z2 = (2+0i)^z;
   diff = abs (z2-zz);
   if (diff > 1e-13) failed ("%S^%S", 2.0, z);
   z2 = (2L)^z;
   diff = abs (z2-zz);
   if (diff > 1e-13) failed ("%S^%S", 2.0, z);

   z2 = 1i*x + y;
   if ((Imag(z2) != x) || (Real(z2) != y))
     failed ("Real/Imag %S", z);

   z2 = Conj(z);
   if ((Real(z2) != x) || (Imag(z2) != -y))
     failed ("Conj %S", z);

   % 1/z = z*/|z|^2
   z1 = 1.0/z;
   z2 = sqr(z);  % |z|^2
   diff = abs (z1 - (x/z2 - 1i*y/z2));
   if (diff > 1e-13) failed ("1/z, sqr(z)");
   z1 = 1L/z;
   diff = abs (z1 - (x/z2 - 1i*y/z2));
   if (diff > 1e-13) failed ("1/z, sqr(z)");

   z1 = z^0.5;
   z2 = sqrt(z);
   diff = abs (z1-z2);
   if (diff > 1e-13) failed ("z^0.5 vs sqrt");

   z1 = z+1;
   z2 = z; z2++;
   if (z2 != z1) failed ("z++");
   z1--;
   if (z1 != z) failed ("z--");

   if (mul2(z) != 2*z) failed ("mul2");

   if (sign(z) != sign(y))
     failed ("sign z");

   if ((z^0 != 1) || (z^0L != 1) || (z^0.0 != 1L))
     failed ("z^0");

   if (z*0 != 0L) failed ("z*0 != 0L");
   if (0L != z*0h) failed ("0L != z*0h");

#iffalse  % needs to be implemented for Complex
   if (abs(z) >= 1L)
     {
	w = z^-50;
	if (log1p (w) != w)
	  failed ("log1p(%S) ==> %S", w, log1p(w));

	if (expm1(w) != w)
	  failed ("expm1");
     }
#endif
}



check_complex_real_binary (0+0i);
check_complex_real_binary (0+1i);
check_complex_real_binary (0+2i);
check_complex_real_binary (1+0i);
check_complex_real_binary (1+1i);
check_complex_real_binary (2+1i);

static define check_complex_fun (fun, x)
{
   variable z = x + 0i;
   variable diff = abs ((@fun)(z) - (@fun)(x));
   if (diff > 1e-13)
     failed ("%S %S", fun, z);
}

check_complex_fun (&sin, 1);
check_complex_fun (&cos, 1);
check_complex_fun (&tan, 1);
check_complex_fun (&acos, 0.5);
check_complex_fun (&asin, 0.5);
check_complex_fun (&atan, 0.5);
check_complex_fun (&cosh, 1);
check_complex_fun (&sinh, 1);
check_complex_fun (&tanh, 1);
check_complex_fun (&asinh, 0.5);
check_complex_fun (&acosh, 2.0);
check_complex_fun (&atanh, 0.5);
check_complex_fun (&sqrt, 0.5);
check_complex_fun (&exp, 0.5);
#endif

define test_is_same (a, b, r)
{
   if (r != __is_same (a,b))
     failed ("__is_same (%S,%S)", a, b);
}

test_is_same (1,1,1);
test_is_same (1,'\001', 0);
#ifexists Double_Type
test_is_same (1, 1.0, 0);
test_is_same (-1.0, -(1.0), 1);
test_is_same (-PI, -(PI), 1);
test_is_same (-20.312345678, -(20.312345678), 1);
test_is_same (-20.3123f, -(20.3123f), 1);
#endif
test_is_same ("xyz", "xyz", 1);
test_is_same ([1:3],[1:3],0);
test_is_same (stdout, stderr, 0);
test_is_same (stderr, 1, 0);
#ifexists Complex_Type
test_is_same (1+2i, 1+2i, 1);
test_is_same (1.0+0.0i, 1.0, 0);
test_is_same (-20.3-2i, -(20.3+2i), 1);
#endif

#ifexists Double_Type
define another_test ()
{
   variable x = 1.0;
   variable y;

   if (18 != 1.0+1+x
       + 1.0+x+1
       + x+1.0+1
       + x+1+1.0
       + 1+1.0+x
       + 1+x+1.0)
     failed ("sum combinations");
}

another_test();
#endif

define test_typecast ()
{
   variable args = __pop_args (_NARGS-1);
   variable y = ();

   if (y != typecast (__push_args (args)))
     failed ("typecast");
}

#ifexists Double_Type
test_typecast (0.0f, 0, Float_Type);
#endif

define check_hypot (a, b, c)
{
   variable cc;
   cc = hypot (a, b);
   if (typeof (c) != typeof (cc))
     failed ("Wrong return type for hypot");
   if (0 == _eqs(c, cc))
     failed ("hypot: expected %S, got %S", c, cc);

   if (length (a) != length(b))
     return;

   cc = hypot ([a,a,a,a],[b,b,b,b]);
   if (0 == _eqs([c,c,c,c], cc))
     failed ("hypot ([a,a,a,a],[b,b,b,b])");
}

check_hypot (3.0, 4.0, 5.0);
check_hypot (3.0f, 4.0, 5.0);
check_hypot (3.0, 4.0f, 5.0);
check_hypot (3.0f, 4.0f, 5.0f);
check_hypot (3, 4, 5.0);
check_hypot (3, 4.0f, 5.0);

check_hypot ([3.0], [4.0], [5.0]);
check_hypot ([3.0f], [4.0], [5.0]);
check_hypot ([3.0], [4.0f], [5.0]);
check_hypot ([3.0f], [4.0f], [5.0f]);
check_hypot ([3], [4], [5.0]);
check_hypot ([3], [4.0f], [5.0]);

check_hypot (3.0, [4.0], [5.0]);
check_hypot (3.0f, [4.0], [5.0]);
check_hypot (3.0, [4.0f], [5.0]);
check_hypot (3.0f, [4.0f], [5.0f]);
check_hypot (3, [4], [5.0]);
check_hypot (3, [4.0f], [5.0]);

check_hypot ([3.0], 4.0, [5.0]);
check_hypot ([3.0f], 4.0, [5.0]);
check_hypot ([3.0], 4.0f, [5.0]);
check_hypot ([3.0f], 4.0f, [5.0f]);
check_hypot ([3], 4, [5.0]);
check_hypot ([3], 4.0f, [5.0]);

$1 = Double_Type[0];
$2 = Float_Type[0];
$3 = Int_Type[0];

check_hypot ($1, 4.0, $1);
check_hypot ($2, 4.0, $1);
check_hypot ($1, 4.0f, $1);
check_hypot ($2, 4.0f, $2);
check_hypot ($3, 4, $1);
check_hypot ($3, 4.0f, $1);

static define check_integer (str, val)
{
   variable val1 = integer (str);
   if ((val != val1) or (typeof (val) != typeof (val1)))
     failed ("integer($str) ==> $val1, not $val"$);
}

check_integer ("0", 0);
check_integer ("0x0", 0);
check_integer ("0x1", 1);
check_integer ("0x1h", 1);
check_integer ("0x1L", 1);
check_integer ("0x1FL", 0x1F);
check_integer ("-0x1FL", -0x1F);
check_integer ("-1L", -1);
check_integer ("-1h", -1);
try
{
   check_integer ("h", 0);
   failed ("integer(h) should have produced an exception");
}
catch SyntaxError;

static define check_atox (fun, str, val)
{
   ifnot (__is_same (val, (@fun)(str)))
     failed ("%S", fun);

   variable a = String_Type[1024];
   a[*] = str;
   variable b = (@fun) (a);
   if ((typeof (b) != Array_Type)
       || (_typeof(b) != typeof (val)))
     failed ("%S did not return array of type %S", fun, typeof(val));
   if (any(b != val))
     failed ("%S did not return the correct array of values", fun);
}

check_atox (&atoi, "7", 7);
check_atox (&atol, "7", 7L);
#ifexists atoll
check_atox (&atoll, "7", 7LL);
#endif

#ifexists Double_Type
check_atox (&atof, "7.0", 7.0);

private define check_nint (x, n)
{
   if (nint (x) != n)
     failed ("nint(%g)!=%d, found %d", x, n, nint(x));
}
check_nint (0.0, 0);
check_nint (0.4, 0);
check_nint (0.49, 0);
check_nint (0.50, 1);
check_nint (1.2, 1);
check_nint (1.49, 1);
check_nint (1.5, 2);
check_nint (-0.1, 0);
check_nint (-0.4, 0);
check_nint (-0.5, -1);
check_nint (-0.9, -1);
check_nint (-1.4, -1);
check_nint (-1.5, -2);
check_nint (-1.51, -2);

private define check_round (x, rx)
{
   if (round (x) != rx)
     failed ("round(%g)!=%g, found %g", x, rx, round(x));
}
check_round (0.0, 0);
check_round (0.4, 0);
check_round (-0.4, 0);
check_round (0.51, 1);
check_round (-0.51, -1);
check_round (0.9, 1);
check_round (-0.9, -1);
check_round (1.1, 1);
check_round (-1.1, -1);
check_round (-1.51, -2);
check_round (1.51, 2);

private define sl_feqs (a, b, relerr, abserr)
{
   if (abs(a-b) <= abserr)
     return 1;
   if (abs(a) > abs(b)) (b,a)=(a,b);

   return (abs((b-a)/b) <= relerr);
}

define test_feqs (a, b, relerr, abserr)
{
   variable c = feqs (a, b, relerr, abserr);
   variable d = array_map (Char_Type, &sl_feqs, a, b, relerr, abserr);
   if (typeof (c) != Array_Type)
     d = d[0];
   if (not _eqs(c,d))
     failed ("feqs(4 args) did not return expected result");

   c = feqs (a, b, relerr);
   d = array_map (Char_Type, &sl_feqs, a, b, relerr, 0.0);
   if (typeof (c) != Array_Type)
     d = d[0];
   if (not _eqs(c, d))
     failed ("feqs(3 args) did not return expected result");

   a = typecast (a, Double_Type);
   b = typecast (b, Float_Type);
   c = feqs (a, b, relerr);
   d = array_map (Char_Type, &sl_feqs, a, b, relerr, 0.0);
   if (typeof (c) != Array_Type)
     d = d[0];
   if (not _eqs(c, d))
     failed ("feqs(double,float) did not return expected result");

   a = typecast (a, Float_Type);
   b = typecast (b, Double_Type);
   c = feqs (a, b, relerr);
   d = array_map (Char_Type, &sl_feqs, a, b, relerr, 0.0);
   if (typeof (c) != Array_Type)
     d = d[0];
   if (not _eqs(c, d))
     failed ("feqs(float,double) did not return expected result");

   a = typecast (a, Float_Type);
   b = typecast (b, Float_Type);
   c = feqs (a, b, relerr);
   d = array_map (Char_Type, &sl_feqs, a, b, relerr, 0.0);
   if (typeof (c) != Array_Type)
     d = d[0];
   if (not _eqs(c, d))
     failed ("feqs(float,float) did not return expected result");
}

private define test_feqs1 (a, b, c, d)
{
   test_feqs (a, b, c, d);

   if ((typeof (a) == Array_Type)
       && (typeof (b) == Array_Type))
     {
	variable i, n = length (a);
	_for i (0, n-1, 1)
	  {
	     test_feqs (a, b[i], c, d);
	     test_feqs (a[i], b, c, d);
	  }
     }
}

foreach (10.0^[-12:20])
{
   $1 = ();
   $2 = $1 * 1.01;
   test_feqs1 ($1, $2, 0.001, 1e-6);

   $2 = -$1 * 1.01;
   test_feqs1 ($1, $2, 0.001, 1e-6);

   $1 = -$1;
   $2 = $1 * 1.01;
   test_feqs1 ($1, $2, 0.001, 1e-6);

   $2 = -$1 * 1.01;
   test_feqs1 ($1, $2, 0.001, 1e-6);
}

$1 = 10.0^[-12:20];
$2 = $1 * 1.01;
test_feqs1 ($1, $2, 0.001, 1e-6);

$2 = -$1 * 1.01;
test_feqs1 ($1, $2, 0.001, 1e-6);

$1 = -$1;
$2 = $1 * 1.01;
test_feqs1 ($1, $2, 0.001, 1e-6);

$2 = -$1 * 1.01;
test_feqs1 ($1, $2, 0.001, 1e-6);

if (feqs (_NaN,_NaN,0.1, 1.0))
  failed ("feqs (_NaN,_NaN)");

if (not fneqs (_NaN,_NaN,0.1, 1.0))
  failed ("fneqs (_NaN,_NaN)");

if (fgteqs (_NaN,_NaN,0.1, 1.0))
  failed ("fgteqs (_NaN,_NaN)");

if (flteqs (_NaN,_NaN,0.1, 1.0))
  failed ("flteqs (_NaN,_NaN)");

if (fgteqs (2.0, 3.0, 0.001, 0.1))
  failed ("fgteqs(2,3)");

if (flteqs (2.0, 1.0, 0.001, 0.1))
  failed ("fgteqs(2,1)");
#endif				       %  Double_Type

print ("Ok\n");
exit (0);
