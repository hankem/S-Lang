/* sin, cos, etc, for S-Lang */
/*
Copyright (C) 2004, 2005, 2006 John E. Davis

This file is part of the S-Lang Library.

The S-Lang Library is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

The S-Lang Library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
USA.  
*/

#include "slinclud.h"

#include <float.h>
#include <math.h>

#if SLANG_HAS_FLOAT

#ifdef HAVE_FLOATINGPOINT_H
# include <floatingpoint.h>
#endif

#ifdef HAVE_FENV_H
# include <fenv.h>
#endif

#ifdef HAVE_IEEEFP_H
# include <ieeefp.h>
#endif

#ifdef HAVE_NAN_H
# include <nan.h>
#endif

#include "slang.h"
#include "_slang.h"

#ifdef PI
# undef PI
#endif
#define PI 3.14159265358979323846264338327950288

/* This probably needs to be made system specific */
#define HAS_IEEE_FP	1

#if defined(__unix__)
#include <signal.h>
#include <errno.h>

static void math_floating_point_exception (int sig)
{
   sig = errno;
   (void) SLsignal (SIGFPE, math_floating_point_exception);
   errno = sig;
}
#endif

double SLmath_hypot (double x, double y)
{
   double fr, fi, ratio;

   fr = fabs(x);
   fi = fabs(y);

   if (fr > fi)
     {
	ratio = y / x;
	x = fr * sqrt (1.0 + ratio * ratio);
     }
   else if (fi == 0.0) x = 0.0;
   else
     {
	ratio = x / y;
	x = fi * sqrt (1.0 + ratio * ratio);
     }

   return x;
}

/* usage here is a1 a2 ... an n x ==> a1x^n + a2 x ^(n - 1) + ... + an */
static double math_poly (void)
{
   int n;
   double xn = 1.0, sum = 0.0;
   double an, x;

   if ((SLang_pop_double(&x))
       || (SLang_pop_integer(&n))) return(0.0);

   while (n-- > 0)
     {
	if (SLang_pop_double(&an)) break;
	sum += an * xn;
	xn = xn * x;
     }
   return (double) sum;
}

static int double_math_op_result (int op, SLtype a, SLtype *b)
{
   switch (op)
     {
      case SLMATH_ISINF:
      case SLMATH_ISNAN:
	*b = SLANG_CHAR_TYPE;
	break;

      default:
	if (a != SLANG_FLOAT_TYPE)
	  *b = SLANG_DOUBLE_TYPE;
	else
	  *b = a;
	break;
     }
   return 1;
}

#ifdef HAVE_ISNAN
# define ISNAN_FUN	isnan
#else
# define ISNAN_FUN	my_isnan
static int my_isnan (double x)
{
   return (volatile double) x != (volatile double) x;
}
#endif

int _pSLmath_isnan (double x)
{
   return ISNAN_FUN (x);
}

#ifdef HAVE_ISINF
# define ISINF_FUN	isinf
#else
# define ISINF_FUN	my_isinf
static int my_isinf (double x)
{
#ifdef HAVE_FINITE
   return (0 == finite (x)) && (0 == ISNAN_FUN (x));
#else
   double y;
   if (x == 0.0)
     return 0;
   y = x * 0.5;
   return (x == y);
#endif
}
#endif

#ifdef HAVE_ROUND
# define ROUND_FUN	round
#else
# define ROUND_FUN	my_round
static double my_round (double x)
{
   double xf, xi;
   
   xf = modf (x, &xi);		       /* x = xi + xf */
   if (xi > 0)
     {
	if (xf >= 0.5)
	  return xi + 1.0;
     }
   else 
     {
	if (xf <= -0.5)
	  return xi - 1.0;
     }
   return xi;
}
#endif

#ifdef HAVE_ASINH
# define ASINH_FUN	asinh
#else
# define ASINH_FUN	my_asinh
static double my_asinh (double x)
{
   return log (x + sqrt (x*x + 1));
}
#endif
#ifdef HAVE_ACOSH
# define ACOSH_FUN	acosh
#else
# define ACOSH_FUN	my_acosh
static double my_acosh (double x)
{
   return log (x + sqrt(x*x - 1));     /* x >= 1 */
}
#endif
#ifdef HAVE_ATANH
# define ATANH_FUN	atanh
#else
# define ATANH_FUN	my_atanh
static double my_atanh (double x)
{
   return 0.5 * log ((1.0 + x)/(1.0 - x)); /* 0 <= x^2 < 1 */
}
#endif

static int double_math_op (int op,
			   SLtype type, VOID_STAR ap, unsigned int na,
			   VOID_STAR bp)
{
   double *a, *b;
   unsigned int i;
   double (*fun) (double);
   char *c;

   (void) type;
   a = (double *) ap;
   b = (double *) bp;

   switch (op)
     {
      default:
	return 0;

      case SLMATH_SINH:
	fun = sinh;
	break;
      case SLMATH_COSH:
	fun = cosh;
	break;
      case SLMATH_TANH:
	fun = tanh;
	break;
      case SLMATH_TAN:
	fun = tan;
	break;
      case SLMATH_ASIN:
	fun = asin;
	break;
      case SLMATH_ACOS:
	fun = acos;
	break;
      case SLMATH_ATAN:
	fun = atan;
	break;
      case SLMATH_EXP:
	fun = exp;
	break;
      case SLMATH_LOG:
	fun = log;
	break;
      case SLMATH_LOG10:
	fun = log10;
	break;
      case SLMATH_SQRT:
	for (i = 0; i < na; i++)
	  b[i] = sqrt ((double) a[i]);
	return 1;
      case SLMATH_SIN:
	fun = sin;
	break;
      case SLMATH_COS:
	fun = cos;
	break;
      case SLMATH_ASINH:
	fun = ASINH_FUN;
	break;
      case SLMATH_ATANH:
	fun = ATANH_FUN;
	break;
      case SLMATH_ACOSH:
	fun = ACOSH_FUN;
	break;

      case SLMATH_CONJ:
      case SLMATH_REAL:
	for (i = 0; i < na; i++)
	  b[i] = a[i];
	return 1;
      case SLMATH_IMAG:
	for (i = 0; i < na; i++)
	  b[i] = 0.0;
	return 1;
	
      case SLMATH_ISINF:
	c = (char *) bp;
	for (i = 0; i < na; i++)
	  c[i] = (char) ISINF_FUN(a[i]);
	return 1;

      case SLMATH_ISNAN:
	c = (char *) bp;
	for (i = 0; i < na; i++)
	  c[i] = (char) ISNAN_FUN(a[i]);
	return 1;
	
      case SLMATH_FLOOR:
	fun = floor;
	break;

      case SLMATH_CEIL:
	fun = ceil;
	break;
	
      case SLMATH_ROUND:
	fun = ROUND_FUN;
	break;
     }

   for (i = 0; i < na; i++)
     b[i] = (*fun) (a[i]);

   return 1;
}

static int float_math_op (int op,
			  SLtype type, VOID_STAR ap, unsigned int na,
			  VOID_STAR bp)
{
   float *a, *b;
   unsigned int i;
   double (*fun) (double);
   char *c;

   (void) type;
   a = (float *) ap;
   b = (float *) bp;


   switch (op)
     {
      default:
	return 0;

      case SLMATH_SINH:
	fun = sinh;
	break;
      case SLMATH_COSH:
	fun = cosh;
	break;
      case SLMATH_TANH:
	fun = tanh;
	break;
      case SLMATH_TAN:
	fun = tan;
	break;
      case SLMATH_ASIN:
	fun = asin;
	break;
      case SLMATH_ACOS:
	fun = acos;
	break;
      case SLMATH_ATAN:
	fun = atan;
	break;
      case SLMATH_EXP:
	fun = exp;
	break;
      case SLMATH_LOG:
	fun = log;
	break;
      case SLMATH_LOG10:
	fun = log10;
	break;
      case SLMATH_SQRT:
	for (i = 0; i < na; i++)
	  b[i] = (float) sqrt ((double) a[i]);
	return 1;

      case SLMATH_SIN:
	fun = sin;
	break;
      case SLMATH_COS:
	fun = cos;
	break;

      case SLMATH_ASINH:
	fun = ASINH_FUN;
	break;
      case SLMATH_ATANH:
	fun = ATANH_FUN;
	break;
      case SLMATH_ACOSH:
	fun = ACOSH_FUN;
	break;

      case SLMATH_CONJ:
      case SLMATH_REAL:
	for (i = 0; i < na; i++)
	  b[i] = a[i];
	return 1;
      case SLMATH_IMAG:
	for (i = 0; i < na; i++)
	  b[i] = 0.0;
	return 1;
      case SLMATH_ISINF:
	c = (char *) bp;
	for (i = 0; i < na; i++)
	  c[i] = (char) ISINF_FUN((double) a[i]);
	return 1;

      case SLMATH_ISNAN:
	c = (char *) bp;
	for (i = 0; i < na; i++)
	  c[i] = (char) ISNAN_FUN((double) a[i]);
	return 1;

      case SLMATH_FLOOR:
	fun = floor;
	break;
      case SLMATH_CEIL:
	fun = ceil;
	break;
      case SLMATH_ROUND:
	fun = ROUND_FUN;
	break;
     }

   for (i = 0; i < na; i++)
     b[i] = (float) (*fun) ((double) a[i]);

   return 1;
}

static int generic_math_op (int op,
			    SLtype type, VOID_STAR ap, unsigned int na,
			    VOID_STAR bp)
{
   double *b;
   unsigned int i;
   SLang_To_Double_Fun_Type to_double;
   double (*fun) (double);
   unsigned int da;
   char *a, *c;

   if (NULL == (to_double = SLarith_get_to_double_fun (type, &da)))
     return 0;

   b = (double *) bp;
   a = (char *) ap;

   switch (op)
     {
      default:
	return 0;

      case SLMATH_SINH:
	fun = sinh;
	break;
      case SLMATH_COSH:
	fun = cosh;
	break;
      case SLMATH_TANH:
	fun = tanh;
	break;
      case SLMATH_TAN:
	fun = tan;
	break;
      case SLMATH_ASIN:
	fun = asin;
	break;
      case SLMATH_ACOS:
	fun = acos;
	break;
      case SLMATH_ATAN:
	fun = atan;
	break;
      case SLMATH_EXP:
	fun = exp;
	break;
      case SLMATH_LOG:
	fun = log;
	break;
      case SLMATH_LOG10:
	fun = log10;
	break;
      case SLMATH_SQRT:
	fun = sqrt;
	break;
      case SLMATH_SIN:
	fun = sin;
	break;
      case SLMATH_COS:
	fun = cos;
	break;

      case SLMATH_ASINH:
	fun = ASINH_FUN;
	break;
      case SLMATH_ATANH:
	fun = ATANH_FUN;
	break;
      case SLMATH_ACOSH:
	fun = ACOSH_FUN;
	break;


      case SLMATH_CONJ:
      case SLMATH_REAL:
	for (i = 0; i < na; i++)
	  {
	     b[i] = to_double((VOID_STAR) a);
	     a += da;
	  }
	return 1;

      case SLMATH_IMAG:
	for (i = 0; i < na; i++)
	  b[i] = 0.0;
	return 1;

      case SLMATH_ISINF:
	c = (char *) bp;
	for (i = 0; i < na; i++)
	  {
	     c[i] = (char) ISINF_FUN(to_double((VOID_STAR) a));
	     a += da;
	  }
	return 1;
      case SLMATH_ISNAN:
	c = (char *) bp;
	for (i = 0; i < na; i++)
	  {
	     c[i] = (char) ISNAN_FUN(to_double((VOID_STAR) a));
	     a += da;
	  }
	return 1;
      case SLMATH_FLOOR:
	fun = floor;
	break;
      case SLMATH_CEIL:
	fun = ceil;
	break;
      case SLMATH_ROUND:
	fun = ROUND_FUN;
	break;
     }

   for (i = 0; i < na; i++)
     {
	b[i] = (*fun) (to_double ((VOID_STAR) a));
	a += da;
     }
   
   return 1;
}

#if SLANG_HAS_COMPLEX
static int complex_math_op_result (int op, SLtype a, SLtype *b)
{
   (void) a;
   switch (op)
     {
      default:
	*b = SLANG_COMPLEX_TYPE;
	break;

      case SLMATH_ISINF:
      case SLMATH_ISNAN:
	*b = SLANG_CHAR_TYPE;
	break;

      case SLMATH_REAL:
      case SLMATH_IMAG:
	*b = SLANG_DOUBLE_TYPE;
	break;
     }
   return 1;
}

static int complex_math_op (int op,
			    SLtype type, VOID_STAR ap, unsigned int na,
			    VOID_STAR bp)
{
   double *a, *b;
   unsigned int i;
   unsigned int na2 = na * 2;
   double *(*fun) (double *, double *);
   char *c;

   (void) type;
   a = (double *) ap;
   b = (double *) bp;

   switch (op)
     {
      default:
	return 0;

      case SLMATH_REAL:
	for (i = 0; i < na; i++)
	  b[i] = a[2 * i];
	return 1;

      case SLMATH_IMAG:
	for (i = 0; i < na; i++)
	  b[i] = a[2 * i + 1];
	return 1;

      case SLMATH_CONJ:
	for (i = 0; i < na2; i += 2)
	  {
	     b[i] = a[i];
	     b[i+1] = -a[i+1];
	  }
	return 1;

      case SLMATH_ATANH:
	fun = SLcomplex_atanh;
	break;
      case SLMATH_ACOSH:
	fun = SLcomplex_acosh;
	break;
      case SLMATH_ASINH:
	fun = SLcomplex_asinh;
	break;
      case SLMATH_EXP:
	fun = SLcomplex_exp;
	break;
      case SLMATH_LOG:
	fun = SLcomplex_log;
	break;
      case SLMATH_LOG10:
	fun = SLcomplex_log10;
	break;
      case SLMATH_SQRT:
	fun = SLcomplex_sqrt;
	break;
      case SLMATH_SIN:
	fun = SLcomplex_sin;
	break;
      case SLMATH_COS:
	fun = SLcomplex_cos;
	break;
      case SLMATH_SINH:
	fun = SLcomplex_sinh;
	break;
      case SLMATH_COSH:
	fun = SLcomplex_cosh;
	break;
      case SLMATH_TANH:
	fun = SLcomplex_tanh;
	break;
      case SLMATH_TAN:
	fun = SLcomplex_tan;
	break;
      case SLMATH_ASIN:
	fun = SLcomplex_asin;
	break;
      case SLMATH_ACOS:
	fun = SLcomplex_acos;
	break;
      case SLMATH_ATAN:
	fun = SLcomplex_atan;
	break;
      case SLMATH_ISINF:
	c = (char *) bp;
	for (i = 0; i < na; i++)
	  {
	     unsigned int j = 2*i;
	     c[i] = (char) (ISINF_FUN(a[j]) || ISINF_FUN(a[j+1]));
	  }
	return 1;
      case SLMATH_ISNAN:
	c = (char *) bp;
	for (i = 0; i < na; i++)
	  {
	     unsigned int j = 2*i;
	     c[i] = (char) (ISNAN_FUN(a[j]) || ISNAN_FUN(a[j+1]));
	  }
	return 1;

      case SLMATH_FLOOR:
      case SLMATH_ROUND:
      case SLMATH_CEIL:
	return double_math_op (op, type, ap, na2, bp);
     }

   for (i = 0; i < na2; i += 2)
     (void) (*fun) (b + i, a + i);

   return 1;
}
#endif

static int do_dd_fun (double (*f)(double, double),
		      double *a, unsigned int a_inc,
		      double *b, unsigned int b_inc, 
		      double *c, unsigned int n)
{
   unsigned int i;
   for (i = 0; i < n; i++)
     {
	c[i] = (*f)(*a, *b);
	a += a_inc;
	b += b_inc;
     }
   return 0;
}

static int do_ff_fun (double (*f)(double, double),
		      float *a, unsigned int a_inc,
		      float *b, unsigned int b_inc, 
		      float *c, unsigned int n)
{
   unsigned int i;
   for (i = 0; i < n; i++)
     {
	c[i] = (float) (*f)(*a, *b);
	a += a_inc;
	b += b_inc;
     }
   return 0;
}

static int do_fd_fun (double (*f)(double, double),
		      float *a, unsigned int a_inc,
		      double *b, unsigned int b_inc, 
		      double *c, unsigned int n)
{
   unsigned int i;
   for (i = 0; i < n; i++)
     {
	c[i] = (*f)(*a, *b);
	a += a_inc;
	b += b_inc;
     }
   return 0;
}

static int do_df_fun (double (*f)(double, double),
		      double *a, unsigned int a_inc,
		      float *b, unsigned int b_inc, 
		      double *c, unsigned int n)
{
   unsigned int i;
   for (i = 0; i < n; i++)
     {
	c[i] = (*f)(*a, *b);
	a += a_inc;
	b += b_inc;
     }
   return 0;
}

static int pop_array_or_scalar (SLang_Array_Type **atp, 
				float *f, float **fp, 
				double *d, double **dp,
				int *is_floatp)
{
   SLang_Array_Type *at;

   *atp = NULL;
   switch (SLang_peek_at_stack1 ())
     {
      case -1:
	return -1;

      case SLANG_FLOAT_TYPE:
	*is_floatp = 1;
	if (SLang_peek_at_stack () == SLANG_ARRAY_TYPE)
	  {
	     if (-1 == SLang_pop_array_of_type (&at, SLANG_FLOAT_TYPE))
	       return -1;
	     *fp = (float *) at->data;
	     *atp = at;
	     return 0;
	  }

	if (-1 == SLang_pop_float (f))
	  return -1;
	*fp = f;
	return 0;

      default:
	*is_floatp = 0;
	if (SLang_peek_at_stack () == SLANG_ARRAY_TYPE)
	  {
	     if (-1 == SLang_pop_array_of_type (&at, SLANG_DOUBLE_TYPE))
	       return -1;
	     *dp = (double *) at->data;
	     *atp = at;
	     return 0;
	  }

	if (-1 == SLang_pop_double (d))
	  return -1;
	*dp = d;
	return 0;
     }
}

static SLang_Array_Type *create_from_tmp_array (SLang_Array_Type *a, SLang_Array_Type *b, SLtype type)
{
   SLang_Array_Type *c;

   if ((a != NULL) && (a->data_type == type) && (a->num_refs == 1))
     {
	a->num_refs += 1;
	return a;
     }
   if ((b != NULL) && (b->data_type == type) && (b->num_refs == 1))
     {
	b->num_refs += 1;
	return b;
     }

   if (a != NULL) 
     c = a;
   else 
     c = b;
   
   return SLang_create_array1 (type, 0, NULL, c->dims, c->num_dims, 1);
}

static int do_binary_function (double (*f)(double, double))
{
   int a_is_float, b_is_float, c_is_float;
   SLang_Array_Type *at = NULL;
   SLang_Array_Type *bt = NULL;
   SLang_Array_Type *ct;
   float *af, *bf, *cf, afbuf, bfbuf, cfbuf;
   double *ad, *bd, *cd, adbuf, bdbuf, cdbuf;
   unsigned int ainc, binc;
   unsigned int na, nb, nc;
   SLtype type;
   int is_scalar;

   if (-1 == pop_array_or_scalar (&bt, &bfbuf, &bf, &bdbuf, &bd, &b_is_float))
     return -1;

   if (-1 == pop_array_or_scalar (&at, &afbuf, &af, &adbuf, &ad, &a_is_float))
     {
	if (bt != NULL)
	  SLang_free_array (bt);
	return -1;
     }

   c_is_float = (a_is_float && b_is_float);
   if (c_is_float) 
     type = SLANG_FLOAT_TYPE;
   else
     type = SLANG_DOUBLE_TYPE;

   is_scalar = 1;
   ainc = binc = 0;
   na = nb = nc = 1;

   if (at != NULL)
     {
	ainc = 1;
	na = at->num_elements;
	is_scalar = 0;
     }

   if (bt != NULL)
     {
	binc = 1;
	nb = bt->num_elements;
	is_scalar = 0;
	if ((at != NULL) && (nb != na))
	  {
	     SLang_verror (SL_TypeMismatch_Error, "Array sizes do not match");
	     SLang_free_array (at);
	     SLang_free_array (bt);
	     return -1;
	  }
     }

   if (is_scalar == 0)
     {
	if (NULL == (ct = create_from_tmp_array (at, bt, type)))
	  {
	     SLang_free_array (at);    /* NULL ok */
	     SLang_free_array (bt);    /* NULL ok */
	     return -1;
	  }
	cf = (float *) ct->data;
	cd = (double *) ct->data;
	nc = ct->num_elements;
     }
   else
     {
	cf = (float *) &cfbuf;
	cd = (double *) &cdbuf;
	ct = NULL;
     }

   if (a_is_float)
     {
	if (b_is_float)
	  (void) do_ff_fun (f, af, ainc, bf, binc, cf, nc);
	else
	  (void) do_fd_fun (f, af, ainc, bd, binc, cd, nc);
     }
   else if (b_is_float)
     (void) do_df_fun (f, ad, ainc, bf, binc, cd, nc);
   else
     (void) do_dd_fun (f, ad, ainc, bd, binc, cd, nc);
   
   SLang_free_array (at);
   SLang_free_array (bt);
   if (ct != NULL)
     return SLang_push_array (ct, 1);

   if (c_is_float)
     return SLang_push_float (cfbuf);

   return SLang_push_double (cdbuf);
}

static void hypot_fun (void)
{
   (void) do_binary_function (SLmath_hypot);
}

static void atan2_fun (void)
{
   (void) do_binary_function (atan2);
}

static double do_min (double a, double b)
{
   if ((a >= b) || ISNAN_FUN(a))
     return b;
   return a;
}
static double do_max (double a, double b)
{
   if ((a <= b) || ISNAN_FUN(a))
     return b;
   return a;
}
static double do_diff (double a, double b)
{
   return fabs(a-b);
}
static void min_fun (void)
{
   (void) do_binary_function (do_min);
}
static void max_fun (void)
{
   (void) do_binary_function (do_max);
}
static void diff_fun (void)
{
   (void) do_binary_function (do_diff);
}

static int do_nint (double x)
{
   double xf, xi;
   
   xf = modf (x, &xi);		       /* x = xi + xf */
   if (x >= 0)
     {
	if (xf >= 0.5)
	  return xi + 1;
     }
   else 
     {
	if (xf <= -0.5)
	  return xi - 1;
     }
   return xi;
}

static int float_to_nint (SLang_Array_Type *at, SLang_Array_Type *bt)
{
   unsigned int n, i;
   int *ip;
   float *fp;
   
   fp = (float *) at->data;
   ip = (int *) bt;
   n = at->num_elements;

   for (i = 0; i < n; i++)
     ip[i] = do_nint ((double) fp[i]);

   return 0;
}

static int double_to_nint (SLang_Array_Type *at, SLang_Array_Type *bt)
{
   unsigned int n, i;
   int *ip;
   double *dp;
   
   dp = (double *) at->data;
   ip = (int *) bt;
   n = at->num_elements;

   for (i = 0; i < n; i++)
     ip[i] = do_nint (dp[i]);

   return 0;
}

static void nint_intrin (void)
{
   double x;
   SLang_Array_Type *at, *bt;
   int (*at_to_int_fun)(SLang_Array_Type *, SLang_Array_Type *);

   if (SLang_peek_at_stack () != SLANG_ARRAY_TYPE)
     {
	if (-1 == SLang_pop_double (&x))
	  return;
	(void) SLang_push_int (do_nint (x));
	return;
     }
   switch (SLang_peek_at_stack1 ())
     {
      case -1:
	return;

      case SLANG_INT_TYPE:
	return;

      case SLANG_FLOAT_TYPE:
	if (-1 == SLang_pop_array_of_type (&at, SLANG_FLOAT_TYPE))
	  return;
	at_to_int_fun = float_to_nint;
	break;

      case SLANG_DOUBLE_TYPE:
      default:
	if (-1 == SLang_pop_array_of_type (&at, SLANG_DOUBLE_TYPE))
	  return;
	at_to_int_fun = double_to_nint;
	break;
     }
   
   if (NULL == (bt = SLang_create_array1 (SLANG_INT_TYPE, 0, NULL, at->dims, at->num_dims, 1)))
     {
	SLang_free_array (at);
	return;
     }
   if (0 == (*at_to_int_fun) (at, bt))
     (void) SLang_push_array (bt, 0);
   
   SLang_free_array (bt);
   SLang_free_array (at);
}


static void fpu_clear_except_bits (void)
{
   SLfpu_clear_except_bits ();
}

static int fpu_test_except_bits (int *bits)
{
   return (int) SLfpu_test_except_bits ((unsigned int) *bits);
}

static SLang_DConstant_Type DConst_Table [] =
{
   MAKE_DCONSTANT("E", 2.718281828459045),
   MAKE_DCONSTANT("PI", PI),
   SLANG_END_DCONST_TABLE
};

static SLang_Math_Unary_Type SLmath_Table [] =
{
   MAKE_MATH_UNARY("sinh", SLMATH_SINH),
   MAKE_MATH_UNARY("asinh", SLMATH_ASINH),
   MAKE_MATH_UNARY("cosh", SLMATH_COSH),
   MAKE_MATH_UNARY("acosh", SLMATH_ACOSH),
   MAKE_MATH_UNARY("tanh", SLMATH_TANH),
   MAKE_MATH_UNARY("atanh", SLMATH_ATANH),
   MAKE_MATH_UNARY("sin", SLMATH_SIN),
   MAKE_MATH_UNARY("cos", SLMATH_COS),
   MAKE_MATH_UNARY("tan", SLMATH_TAN),
   MAKE_MATH_UNARY("atan", SLMATH_ATAN),
   MAKE_MATH_UNARY("acos", SLMATH_ACOS),
   MAKE_MATH_UNARY("asin", SLMATH_ASIN),
   MAKE_MATH_UNARY("exp", SLMATH_EXP),
   MAKE_MATH_UNARY("log", SLMATH_LOG),
   MAKE_MATH_UNARY("sqrt", SLMATH_SQRT),
   MAKE_MATH_UNARY("log10", SLMATH_LOG10),
   MAKE_MATH_UNARY("isinf", SLMATH_ISINF),
   MAKE_MATH_UNARY("isnan", SLMATH_ISNAN),
   MAKE_MATH_UNARY("floor", SLMATH_FLOOR),
   MAKE_MATH_UNARY("ceil", SLMATH_CEIL),
   MAKE_MATH_UNARY("round", SLMATH_ROUND),
   
#if SLANG_HAS_COMPLEX
   MAKE_MATH_UNARY("Real", SLMATH_REAL),
   MAKE_MATH_UNARY("Imag", SLMATH_IMAG),
   MAKE_MATH_UNARY("Conj", SLMATH_CONJ),
#endif
   SLANG_END_MATH_UNARY_TABLE
};

static SLang_Intrin_Fun_Type SLang_Math_Table [] =
{
   MAKE_INTRINSIC_0("nint", nint_intrin, SLANG_VOID_TYPE),
   MAKE_INTRINSIC_0("polynom", math_poly, SLANG_DOUBLE_TYPE),
   MAKE_INTRINSIC_0("hypot", hypot_fun, SLANG_VOID_TYPE),
   MAKE_INTRINSIC_0("atan2", atan2_fun, SLANG_VOID_TYPE),
   MAKE_INTRINSIC_0("_min", min_fun, SLANG_VOID_TYPE),
   MAKE_INTRINSIC_0("_max", max_fun, SLANG_VOID_TYPE),
   MAKE_INTRINSIC_0("_diff", diff_fun, SLANG_VOID_TYPE),
   MAKE_INTRINSIC_0("fpu_clear_except_bits", fpu_clear_except_bits, SLANG_VOID_TYPE),
   MAKE_INTRINSIC_1("fpu_test_except_bits", fpu_test_except_bits, _pSLANG_LONG_TYPE, _pSLANG_LONG_TYPE),
   SLANG_END_INTRIN_FUN_TABLE
};

static SLang_IConstant_Type IConsts [] = 
{
   MAKE_ICONSTANT("FE_DIVBYZERO", SL_FE_DIVBYZERO),
   MAKE_ICONSTANT("FE_INVALID", SL_FE_INVALID),
   MAKE_ICONSTANT("FE_OVERFLOW", SL_FE_OVERFLOW),
   MAKE_ICONSTANT("FE_UNDERFLOW", SL_FE_UNDERFLOW),
   MAKE_ICONSTANT("FE_INEXACT", SL_FE_INEXACT),
   MAKE_ICONSTANT("FE_ALL_EXCEPT", SL_FE_ALLEXCEPT),
   SLANG_END_ICONST_TABLE
};

static int add_nan_and_inf (void)
{
   volatile double nan_val, inf_val;
#ifdef HAS_IEEE_FP
   volatile double big;
   unsigned int max_loops = 256;

   big = 1e16;
   inf_val = 1.0;

   while (max_loops)
     {
	max_loops--;
	big *= 1e16;
	if (inf_val == big)
	  break;
	inf_val = big;
     }
   if (max_loops == 0)
     {
	inf_val = DBL_MAX;
	nan_val = DBL_MAX;
     }
   else nan_val = inf_val/inf_val;
#else
   inf_val = DBL_MAX;
   nan_val = DBL_MAX;
#endif
   if ((-1 == SLns_add_dconstant (NULL, "_NaN", nan_val))
       || (-1 == SLns_add_dconstant (NULL, "_Inf", inf_val)))
     return -1;
   
   SLfpu_clear_except_bits ();

   return 0;
}

int SLang_init_slmath (void)
{
   SLtype *int_types;

#if SLANG_HAS_COMPLEX
   if (-1 == _pSLinit_slcomplex ())
     return -1;
#endif
   int_types = _pSLarith_Arith_Types;

   while (*int_types != SLANG_FLOAT_TYPE)
     {
	if (-1 == SLclass_add_math_op (*int_types, generic_math_op, double_math_op_result))
	  return -1;
	int_types++;
     }

   if ((-1 == SLclass_add_math_op (SLANG_FLOAT_TYPE, float_math_op, double_math_op_result))
       || (-1 == SLclass_add_math_op (SLANG_DOUBLE_TYPE, double_math_op, double_math_op_result))
#if SLANG_HAS_COMPLEX
       || (-1 == SLclass_add_math_op (SLANG_COMPLEX_TYPE, complex_math_op, complex_math_op_result))
#endif
       )
     return -1;

   if ((-1 == SLadd_math_unary_table (SLmath_Table, "__SLMATH__"))
       || (-1 == SLadd_intrin_fun_table (SLang_Math_Table, NULL))
       || (-1 == SLadd_dconstant_table (DConst_Table, NULL))
       || (-1 == SLadd_iconstant_table (IConsts, NULL))
       || (-1 == add_nan_and_inf ()))
     return -1;

#if defined(__unix__)
   (void) SLsignal (SIGFPE, math_floating_point_exception);
#endif

   return 0;
}
#endif				       /* SLANG_HAS_FLOAT */
