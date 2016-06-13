() = evalfile ("inc.sl");

testing_feature ("Math");

#ifnexists log1p
print ("Not supported\n");
exit(0);
#stop
#endif

private define log1p_taylor (x)
{
   return polynom ([0,1,-1/2.0,1.0/3,-1.0/4,1.0/5,-1.0/6,1.0/7], x);
}

private define expm1_taylor (x)
{
   % exp(x)-1 = x+x^2/2!+...
   return polynom ([0,1,1,1,1,1,1,1,1,1,1], x, 1);
}

private define test_smallx_funct_internal (func, tfunc, x)
{
   variable y = (@tfunc)(x);
   variable y1 = (@func)(x);

   variable dy = (y1-y)/x;
   variable i = wherefirst(abs(dy)>1e-15);
   if (i != NULL)
     {
	failed ("%S(%S) ==> %S, expected %S", func, x[i], y1[i], y[i]);
     }
}

private define test_smallx_funct (f, t, x)
{
   test_smallx_funct_internal (f, t, x);
   test_smallx_funct_internal (f, t, typecast(x, Float_Type));
   test_smallx_funct_internal (f, t, [x,x,x,x]);
   test_smallx_funct_internal (f, t, typecast([x,x,x,x], Float_Type));
}

test_smallx_funct (&log1p, &log1p_taylor, 1e-9);
test_smallx_funct (&log1p, &log1p_taylor, 1e-3);
test_smallx_funct (&log1p, &log1p_taylor, 1e-15);
test_smallx_funct (&log1p, &log1p_taylor, 1e-20);

test_smallx_funct (&expm1, &expm1_taylor, 1e-3);
test_smallx_funct (&expm1, &expm1_taylor, 1e-9);
test_smallx_funct (&expm1, &expm1_taylor, 1e-15);
test_smallx_funct (&expm1, &expm1_taylor, 1e-20);

ifnot(isinf(expm1(_Inf))) failed ("expm1 _Inf");
if (expm1(-_Inf) != -1) failed ("expm1 -_Inf");
ifnot(isinf(log1p(_Inf))) failed ("log1p _Inf");
ifnot(isnan(log1p(-_Inf))) failed ("log1p -_Inf");

define check_hypot (a, b, c)
{
   variable cc;
   cc = hypot (a, b);
   if (_typeof (c) != _typeof (cc))
     failed ("Wrong return type for hypot");
   if (0 == _eqs(c, cc))
     failed ("hypot: expected %S, got %S", c, cc);

   if (length (a) != length(b))
     return;

   cc = hypot ([a,a,a,a],[b,b,b,b]);
   if (0 == _eqs([c,c,c,c], cc))
     failed ("hypot ([a,a,a,a],[b,b,b,b])");

   c = c[0];
   cc = hypot ([0,a,b]); if (0 == _eqs(cc, c)) failed ("hypot ([0,a,b])");
   cc = hypot ([a,0,b]); if (0 == _eqs(cc, c)) failed ("hypot ([a,0,b])");
   cc = hypot ([a,b,0]); if (0 == _eqs(cc, c)) failed ("hypot ([a,0,b])");
}

private define check_hypot_with_types ()
{
   variable a, b, c, s, t, u;
   foreach t (Util_Arith_Types)
     {
	a = typecast (3, t);
	foreach s (Util_Arith_Types)
	  {
	     b = typecast (4, s);
	     c = 5.0;
	     if ((t == Float_Type) && (s == Float_Type))
	       c = 5.0f;
	     u = typeof (c);

	     check_hypot (a, b, c);
	     check_hypot (a, [b], [c]);
	     check_hypot ([a], b, [c]);
	     check_hypot ([a], [b], [c]);
	     check_hypot (t[0], b, u[0]);
	     check_hypot (a, s[0], u[0]);
	  }
     }
}
check_hypot_with_types ();

private define check_nint (x, n)
{
   if (nint (x) != n)
     failed ("nint(%g)!=%d, found %d", x, n, nint(x));
   ifnot (_eqs([n,n,n], nint([x,x,x])))
     failed ("nint(%S)", [x,x,x]);
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
   ifnot (_eqs([rx,rx,rx], round([x,x,x])))
     failed ("round(%S)", [x,x,x]);
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

private define check_floor (x, rx)
{
   if (floor (x) != rx)
     failed ("floor(%g)!=%g, found %g", x, rx, round(x));
   ifnot (_eqs([rx,rx,rx], floor([x,x,x])))
     failed ("floor(%S)", [x,x,x]);
}
check_floor (1.2, 1);
check_floor (1.2f, 1);
check_floor (-1.2, -2);
check_floor (-1.2f, -2);

private define check_ceil (x, rx)
{
   if (ceil (x) != rx)
     failed ("ceil(%g)!=%g, found %g", x, rx, round(x));
   ifnot (_eqs([rx,rx,rx], ceil([x,x,x])))
     failed ("ceil(%S)", [x,x,x]);
}
check_ceil (1.2, 2);
check_ceil (1.2f, 2);
check_ceil (-1.2, -1);
check_ceil (-1.2f, -1);

private define check_with_types ()
{
   foreach (Util_Arith_Types)
     {
	variable t = ();
	variable x = typecast(31,t);
	check_nint (x, 31);
	check_round (x, 31);
	check_floor (x, 31);
	check_ceil (x, 31);
     }
}
check_with_types ();

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

private define test_misc_trig ()
{
   variable angle = [0.1:2*PI:0.1]-PI;
   variable s, c, s1, c1;
   variable type;

   foreach type ([Double_Type, Float_Type])
     {
	variable theta = typecast (angle, type);

	(s, c) = (sin(theta), cos(theta));
	(s1, c1) = sincos (theta);
	if (any (fneqs (c, c1, 1e-6, 1e-8)) || any(fneqs(s,s1,1e-6,1e-8)))
	  failed ("sincos %S failed", type);

	if (any (fneqs (theta, atan2(s1,c1), 1e-5, 1e-6)))
	  failed ("atan2 %S", type);
	(s, c) = sincos(theta[0]);
	if ((s != s1[0]) || (c != c1[0]))
	  failed ("sincos scalar %S", type);
     }

   foreach type (Util_Arith_Types)
     {
	variable one = typecast (1, type);
	variable ten = typecast (10, type);

	if (fneqs (tan(one), 1.5574077246549023, 1e-6)) failed("tan(%S)",one);
	if (fneqs (2*asin(one), PI, 1e-6)) failed ("asin(%S)", one);
	if (fneqs (2*acos(one), 0, 1e-6)) failed ("acos(%S)", one);
	if (fneqs (4*atan(one), PI, 1e-6)) failed ("atan(%S)", one);
	if (fneqs (expm1(one), 1.718281828459045, 1e-6)) failed("expm1(%S)",one);
	if (fneqs (log1p(one), 0.6931471805599453, 1e-6)) failed("log1p(%S)",one);
	if (fneqs (sinh(one), 1.1752011936438014, 1e-6)) failed("sinh(%S)",one);
	if (fneqs (cosh(one), 1.5430806348152437, 1e-6)) failed("cosh(%S)",one);
	if (fneqs (tanh(one), 0.7615941559557649, 1e-6)) failed("tanh(%S)",one);
	if (fneqs (asinh(one), 0.881373587019543, 1e-6)) failed("asinh(%S)",one);
	if (fneqs (acosh(one), 0.0, 1e-6)) failed("acosh(%S)",one);
	ifnot (isinf(atanh(one))) failed("atanh(%S)",one);
	if (fneqs (log(ten), 2.302585092994046, 1e-6)) failed("log(%S)",ten);
	if (fneqs (exp(one), E, 1e-6)) failed("exp(%S)",one);
	if (log10(ten) != 1) failed("log10(%S)", ten);

	if (Imag(one) != 0) failed ("Imag(%S)", one);
	if (Real(one) != 1) failed ("Real(%S)", one);
	if (Conj(one) != 1) failed ("Conj(%S)", one);

	one = [one, one, one];
	ten = [ten,ten,ten];
	if (any(fneqs (tan(one), 1.5574077246549023, 1e-6))) failed("tan(%S)",one);
	if (any(fneqs (2*asin(one), PI, 1e-6))) failed ("asin(%S)", one);
	if (any(fneqs (2*acos(one), 0, 1e-6))) failed ("acos(%S)", one);
	if (any(fneqs (4*atan(one), PI, 1e-6))) failed ("atan(%S)", one);
	if (any(fneqs (expm1(one), 1.718281828459045, 1e-6))) failed("expm1(%S)",one);
	if (any(fneqs (log1p(one), 0.6931471805599453, 1e-6))) failed("log1p(%S)",one);
	if (any(fneqs (sinh(one), 1.1752011936438014, 1e-6))) failed("sinh(%S)",one);
	if (any(fneqs (cosh(one), 1.5430806348152437, 1e-6))) failed("cosh(%S)",one);
	if (any(fneqs (tanh(one), 0.7615941559557649, 1e-6))) failed("tanh(%S)",one);
	if (any(fneqs (asinh(one), 0.881373587019543, 1e-6))) failed("asinh(%S)",one);
	if (any(fneqs (acosh(one), 0.0, 1e-6))) failed("acosh(%S)",one);
	ifnot (all(isinf(atanh(one)))) failed("atanh(%S)",one);
	if (any(fneqs (log(ten), 2.302585092994046, 1e-6))) failed("log(%S)",ten);
	if (any(fneqs (exp(one), E, 1e-6))) failed("exp(%S)",one);
	if (any(log10(ten) != 1)) failed("log10(%S)", ten);
	if (any(Imag(one) != 0)) failed ("Imag(%S)", one);
	if (any(Real(one) != 1)) failed ("Real(%S)", one);
	if (any(Conj(one) != 1)) failed ("Conj(%S)", one);
     }
}
test_misc_trig ();

private define test_frexp_ldexp ()
{
   foreach ([Float_Type, Double_Type])
     {
	variable type = ();
	variable x = typecast (2560, type);
	variable e, f;
	(f,e) = frexp (x);
	if ((f != 0.625) || (e != 12))
	  failed ("frexp(%S)", x);

	if (2560 != ldexp(f,e))
	  failed ("ldexp(%S,%S)", f, e);

	x = [x,x,x];
	(f,e) = frexp (x);
	if (any(f != 0.625) || any(e != 12))
	  failed ("frexp(%S)", x);

	if (any(2560 != ldexp(f,e)))
	  failed ("ldexp(%S,%S)", f, e);

	if (any(2560 != ldexp(f[0],e)))
	  failed ("ldexp(%S,%S)",f[0], e);

	if (any(2560 != ldexp(f,e[0])))
	  failed ("ldexp(%S,%S)",f,e[0]);
     }
}
test_frexp_ldexp ();

#ifexists Complex_Type
private define check_complex()
{
   if (isinf (1+2i)) failed ("isinf complex");
   ifnot (isinf (_Inf+2i)) failed ("isinf complex");
   ifnot (isinf (2i*_Inf)) failed ("isinf complex");

   if (isnan (1+2i)) failed ("isnan complex");
   ifnot (isnan (_NaN+2i)) failed ("isnan complex");
   ifnot (isnan (_NaN*2i)) failed ("isnan complex");
}
check_complex ();
#endif
print ("Ok\n");

exit (0);

