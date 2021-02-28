/* -*- c -*- */

/* This include file is a template for defining arithmetic binary operations
 * on arithmetic types.  I realize that doing it this way is not very
 * elegant but it minimizes the number of lines of code and I believe it
 * promotes clarity.
 */

/* The following macros should be properly defined before including this file:
 *
 * For unary operations: (op a)
 *   GENERIC_UNARY_FUNCTION     Name of the unary function
 *   GENERIC_A_TYPE:            The class data type
 *   GENERIC_A_IS_UNSIGNED      Indicates that the type is unsigned
 *   GENERIC_BIT_OPERATIONS     If defined, include SLANG_BNOT
 *   ABS_FUNCTION:              Name of the abs function
 *
 * For binary operations involving arrays: (a op b)
 *   GENERIC_BINARY_FUNCTION:   The name of the binary function
 *   GENERIC_A_TYPE:            The class data type for 'a'
 *   GENERIC_B_TYPE:            The class data type for 'b
 *   GENERIC_B_TYPE_UNSIGNED:   Define it 'b' is unsigned
 *   JUST_BOOLEAN_BINARY_OPS    If defined, only "==", "!=", "or", "and" implemented
 *   GENERIC_BIT_OPERATIONS     Include bit ops: "&", "xor", "|", "<<", ">>"
 *   POW_FUNCTION               Used to compute the a^b operation
 *   POW_RESULT_TYPE            The type of the result of a^b
 *   TRAP_DIV_ZERO              required: if 1, throw SL_DIVIDE_ERROR exception
 *   MOD_FUNCTION:	        The function to use for mod
 *
 * For scalar (non-array) binary operations ( a op b)
 *   SCALAR_BINARY_FUNCTION:   The name of the scalar binary function
 *   GENERIC_A_TYPE:            The class data type for 'a'
 *   GENERIC_B_TYPE:            The class data type for 'b'
 *   GENERIC_B_TYPE_UNSIGNED    Define it 'b' is unsigned
 *   PUSH_SCALAR_OBJ_FUN        Used to push the result of (a op b)
 *   POW_FUNCTION               Used to compute the a^b operation
 *   PUSH_POW_OBJ_FUN           Function used to push the result of (a^b)
 *   TRAP_DIV_ZERO              required: If 1 throw SL_DIVIDE_ERROR exception
 *   GENERIC_BIT_OPERATIONS     Include bit op: "&", "xor", "|", "<<", ">>"
 *   MOD_FUNCTION:	        The function to use for mod
 *
 * Copy functions: Copy the an array of type A to B
 *   GENERIC_COPY_FUNCTION      Name of function
 *   GENERIC_A_TYPE             Specifies the type A
 *   GENERIC_B_TYPE             Specifies the type B
 *
 * Convert functions: Creates an array of type B initialized to values of A
 *   GENERIC_CONVERT_FUNCTION   The name of the function
 *   GENERIC_A_TYPE             Specifies the type A
 *   GENERIC_B_TYPE             Specifies the type B
 *
 * Conversion to a double: returns a single double via a typecast
 *   TO_DOUBLE_FUNCTION         Name of the function
 *   GENERIC_A_TYPE             The type of that is typecast to double
 *
 * If GENERIC_BIT_OPERATIONS is defined, the bit-level binary operators
 * will get included.  If the data type has a power operation (SLANG_POW),
 * then POW_FUNCTION should be defined to return POW_RESULT_TYPE.  The code
 * below assumes that POW_RESULT_TYPE is a floating point type,
 * with intermediate computations performed in double precision.
 *
 * If division by zero errors should be trapped, the define TRAP_DIV_ZERO to 1
 */

#define UNROLL_SOME_LOOPS 1
#if UNROLL_SOME_LOOPS
# define UNROLL_THIS_ab(_c, _a, _op, _b, _n, _na) \
   (_n) = 0; \
   while ((_n) + 4 <= (_na)) \
   { \
      (_c)[(_n)] = _a[(_n)] _op _b[(_n)]; \
      (_c)[(_n)+1] = _a[(_n)+1] _op _b[(_n)+1]; \
      (_c)[(_n)+2] = _a[(_n)+2] _op _b[(_n)+2]; \
      (_c)[(_n)+3] = _a[(_n)+3] _op _b[(_n)+3]; \
      n += 4; \
   } \
   while ((_n) < (_na)) { (_c)[(_n)] = _a[(_n)] _op _b[(_n)]; (_n)++; } (void)0

# define UNROLL_THIS_a(_c, _a, _op, _b, _n, _na) \
   (_n) = 0; \
   while ((_n) + 4 <= (_na)) \
   { \
      (_c)[(_n)] = _a[(_n)] _op _b; \
      (_c)[(_n)+1] = _a[(_n)+1] _op _b; \
      (_c)[(_n)+2] = _a[(_n)+2] _op _b; \
      (_c)[(_n)+3] = _a[(_n)+3] _op _b; \
      n += 4; \
   } \
   while ((_n) < (_na)) { (_c)[(_n)] = _a[(_n)] _op _b; (_n)++; } (void)0

# define UNROLL_THIS_b(_c, _a, _op, _b, _n, _na) \
   (_n) = 0; \
   while ((_n) + 4 <= (_na)) \
   { \
      (_c)[(_n)] = _a _op _b[(_n)]; \
      (_c)[(_n)+1] = _a _op _b[(_n)+1]; \
      (_c)[(_n)+2] = _a _op _b[(_n)+2]; \
      (_c)[(_n)+3] = _a _op _b[(_n)+3]; \
      n += 4; \
   } \
   while ((_n) < (_na)) { (_c)[(_n)] = _a _op _b[(_n)]; (_n)++; } (void)0
#endif				       /* UNROLL_SOME_LOOPS */

#ifndef TRAP_DIV_ZERO
# define TRAP_DIV_ZERO 0
#endif

#if TRAP_DIV_ZERO
# ifdef GENERIC_B_TYPE_UNSIGNED
#  define PERFORM_DIVIDE(_c, _a, _b) \
   if ((_b) == 0) \
   { \
      SLang_set_error (SL_DIVIDE_ERROR); \
      return -1; \
   } \
   else (_c) = (_a) / (_b)
#  define PERFORM_MOD(_c, _a, _b) \
   if ((_b) == 0) \
   { \
      SLang_set_error (SL_DIVIDE_ERROR); \
      return -1; \
   }\
   else (_c) = MOD_FUNCTION((_a), (_b))

# else

#  define PERFORM_DIVIDE(_c, _a, _b) \
   if ((_b) == 0) \
   { \
      SLang_set_error (SL_DIVIDE_ERROR); \
      return -1; \
   } \
   else if ((_b) == -1) (_c) = -(_a); \
   else (_c) = (_a) / (_b)

#  define PERFORM_MOD(_c, _a, _b) \
   if ((_b) == 0) \
   { \
      SLang_set_error (SL_DIVIDE_ERROR); \
      return -1; \
   }\
   else if (_b == -1) (_c) = 0; \
   else (_c) = MOD_FUNCTION((_a), (_b))

# endif				       /* GENERIC_B_TYPE_UNSIGNED */
#else
# define PERFORM_DIVIDE(_c, _a, _b) (_c) = (_a) / (_b)
# define PERFORM_MOD(_c, _a, _b) (_c) = MOD_FUNCTION((_a), (_b))
#endif				       /* TRAP_DIV_ZERO */


#ifdef GENERIC_BINARY_FUNCTION

static int GENERIC_BINARY_FUNCTION
  (int op,
   SLtype a_type, VOID_STAR ap, SLuindex_Type na,
   SLtype b_type, VOID_STAR bp, SLuindex_Type nb,
   VOID_STAR cp)
{
   GENERIC_A_TYPE *a;
   GENERIC_B_TYPE *b;

# ifndef JUST_BOOLEAN_BINARY_OPS
   GENERIC_C_TYPE *c;
# endif
# ifdef POW_FUNCTION
   POW_RESULT_TYPE *d;
# endif
   SLuindex_Type n;
# if SLANG_OPTIMIZE_FOR_SPEED < 2
   SLuindex_Type n_max, da, db;
# endif
   char *cc;

   (void) a_type;		       /* Both SLANG_INT_TYPE */
   (void) b_type;

   a = (GENERIC_A_TYPE *) ap;
   b = (GENERIC_B_TYPE *) bp;
#ifndef JUST_BOOLEAN_BINARY_OPS
   c = (GENERIC_C_TYPE *) cp;
#endif
   cc = (char *) cp;

# if SLANG_OPTIMIZE_FOR_SPEED < 2
   if (na == 1) da = 0; else da = 1;
   if (nb == 1) db = 0; else db = 1;

   if (na > nb) n_max = na; else n_max = nb;
# endif

   switch (op)
     {
      default:
	return 0;
# if !defined(JUST_BOOLEAN_BINARY_OPS)
#  ifdef POW_FUNCTION
      case SLANG_POW:
	d = (POW_RESULT_TYPE *) cp;
#   if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     d[n] = POW_FUNCTION(*a, *b);
	     a += da; b += db;
	  }
#   else
	if (na == nb)
	  {
	     for (n = 0; n < na; n++)
	       d[n] = POW_FUNCTION(a[n],b[n]);
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
	     if (xb == 2)
	       for (n = 0; n < na; n++)
		 d[n] = (double)a[n] * (double)a[n];
	     else
	       for (n = 0; n < na; n++)
		 d[n] = POW_FUNCTION(a[n], xb);
	  }
	else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
	     for (n = 0; n < nb; n++)
	       d[n] = POW_FUNCTION(xa, b[n]);
	  }
#   endif
	break;
#  endif
      case SLANG_PLUS:
#  if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     c[n] = (*a + *b); a += da; b += db;
	  }
#  else
	if (na == nb)
	  {
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_ab(c,a,+,b,n,na);
#   else
	     for (n = 0; n < na; n++) c[n] = a[n] + b[n];
#   endif
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_a(c,a,+,xb,n,na);
#   else
	     for (n = 0; n < na; n++) c[n] = a[n] + xb;
#   endif
	  }
	else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_b(c,xa,+,b,n,nb);
#   else
	     for (n = 0; n < nb; n++) c[n] = xa + b[n];
#   endif
	  }
#  endif /* SLANG_OPTIMIZE_FOR_SPEED < 2 */
	break;

      case SLANG_MINUS:
#  if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     c[n] = (*a - *b); a += da; b += db;
	  }
#  else
	if (na == nb)
	  {
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_ab(c,a,-,b,n,na);
#   else
	     for (n = 0; n < na; n++) c[n] = a[n] - b[n];
#   endif
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_a(c,a,-,xb,n,na);
#   else
	     for (n = 0; n < na; n++) c[n] = a[n] - xb;
#   endif
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_b(c,xa,-,b,n,nb);
#   else
	     for (n = 0; n < nb; n++) c[n] = xa - b[n];
#   endif
	  }
#  endif
	break;

      case SLANG_TIMES:
#  if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     c[n] = (*a * *b); a += da; b += db;
	  }
#  else
	if (na == nb)
	  {
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_ab(c,a,*,b,n,na);
#   else
	     for (n = 0; n < na; n++) c[n] = a[n] * b[n];
#   endif
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_a(c,a,*,xb,n,na);
#   else
	     for (n = 0; n < na; n++) c[n] = a[n] * xb;
#   endif
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_b(c,xa,*,b,n,nb);
#   else
	     for (n = 0; n < nb; n++)
	       c[n] = xa * b[n];
#   endif
	  }
#  endif
	break;

      case SLANG_DIVIDE:
#  if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     PERFORM_DIVIDE(c[n], *a, *b);
	     a += da;
	     b += db;
	  }
#  else
	if (na == nb)
	  {
	     for (n = 0; n < na; n++)
	       PERFORM_DIVIDE(c[n], a[n], b[n]);
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
#   if TRAP_DIV_ZERO
	     if (xb == 0)
	       {
		  SLang_set_error (SL_DIVIDE_ERROR);
		  return -1;
	       }
#    ifndef GENERIC_B_TYPE_UNSIGNED
	     else if (xb == -1)
	       for (n = 0; n < na; n++) c[n] = -a[n];
#    endif
	     else
#   endif
	       for (n = 0; n < na; n++)
		 c[n] = a[n] / xb;
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
	     for (n = 0; n < nb; n++)
	       PERFORM_DIVIDE(c[n], xa, b[n]);
	  }
#  endif
	break;

      case SLANG_MOD:
#  if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     PERFORM_MOD(c[n], *a, *b);
	     a += da; b += db;
	  }
#  else
	if (na == nb)
	  {
	     for (n = 0; n < na; n++)
	       PERFORM_MOD(c[n], a[n], b[n]);
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
	     for (n = 0; n < na; n++)
	       PERFORM_MOD(c[n], a[n], xb);
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
	     for (n = 0; n < nb; n++)
	       PERFORM_MOD(c[n], xa, b[n]);
	  }
#  endif
	break;

#  ifdef GENERIC_BIT_OPERATIONS
      case SLANG_BAND:
#   if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     c[n] = (*a & *b); a += da; b += db;
	  }
#   else
	if (na == nb)
	  {
	     for (n = 0; n < na; n++)
	       c[n] = a[n] & b[n];
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
	     for (n = 0; n < na; n++)
	       c[n] = a[n] & xb;
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
	     for (n = 0; n < nb; n++)
	       c[n] = xa & b[n];
	  }
#   endif
	break;

      case SLANG_BXOR:
#   if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     c[n] = (*a ^ *b); a += da; b += db;
	  }
#   else
	if (na == nb)
	  {
	     for (n = 0; n < na; n++)
	       c[n] = a[n] ^ b[n];
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
	     for (n = 0; n < na; n++)
	       c[n] = a[n] ^ xb;
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
	     for (n = 0; n < nb; n++)
	       c[n] = xa ^ b[n];
	  }
#   endif
	break;

      case SLANG_BOR:
#   if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     c[n] = (*a | *b); a += da; b += db;
	  }
#   else
	if (na == nb)
	  {
	     for (n = 0; n < na; n++)
	       c[n] = a[n] | b[n];
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
	     for (n = 0; n < na; n++)
	       c[n] = a[n] | xb;
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
	     for (n = 0; n < nb; n++)
	       c[n] = xa | b[n];
	  }
#   endif
	break;

      case SLANG_SHL:
#   if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     c[n] = (*a << *b); a += da; b += db;
	  }
#   else
	if (na == nb)
	  {
	     for (n = 0; n < na; n++)
	       c[n] = a[n] << b[n];
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
	     for (n = 0; n < na; n++)
	       c[n] = a[n] << xb;
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
	     for (n = 0; n < nb; n++)
	       c[n] = xa << b[n];
	  }
#   endif
	break;

      case SLANG_SHR:
#   if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     c[n] = (*a >> *b); a += da; b += db;
	  }
#   else
	if (na == nb)
	  {
	     for (n = 0; n < na; n++)
	       c[n] = a[n] >> b[n];
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
	     for (n = 0; n < na; n++)
	       c[n] = a[n] >> xb;
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
	     for (n = 0; n < nb; n++)
	       c[n] = xa >> b[n];
	  }
#   endif
	break;
#  endif 			       /* GENERIC_BIT_OPERATIONS */
      case SLANG_GT:
#  if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     cc[n] = ((GENERIC_C_TYPE)*a > (GENERIC_C_TYPE)*b); a += da; b += db;
	  }
#  else
	if (na == nb)
	  {
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_ab(cc,(GENERIC_C_TYPE)a,>,(GENERIC_C_TYPE)b,n,na);
#   else
	     for (n = 0; n < na; n++) cc[n] = ((GENERIC_C_TYPE)a[n] > (GENERIC_C_TYPE)b[n]);
#   endif
	  }
	else if (nb == 1)
	  {
	     GENERIC_C_TYPE xb = *b;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_a(cc,(GENERIC_C_TYPE)a,>,xb,n,na);
#   else
	     for (n = 0; n < na; n++) cc[n] = ((GENERIC_C_TYPE)a[n] > xb);
#   endif
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_C_TYPE xa = *a;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_b(cc,xa,>,(GENERIC_C_TYPE)b,n,nb);
#   else
	     for (n = 0; n < nb; n++) cc[n] = (xa > (GENERIC_C_TYPE)b[n]);
#   endif
	  }
#  endif
	break;

      case SLANG_GE:
#  if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     cc[n] = ((GENERIC_C_TYPE)*a >= (GENERIC_C_TYPE)*b); a += da; b += db;
	  }
#  else
	if (na == nb)
	  {
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_ab(cc,(GENERIC_C_TYPE)a,>=,(GENERIC_C_TYPE)b,n,na);
#   else
	     for (n = 0; n < na; n++) cc[n] = ((GENERIC_C_TYPE)a[n] >= (GENERIC_C_TYPE)b[n]);
#   endif
	  }
	else if (nb == 1)
	  {
	     GENERIC_C_TYPE xb = *b;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_a(cc,(GENERIC_C_TYPE)a,>=,xb,n,na);
#   else
	     for (n = 0; n < na; n++) cc[n] = ((GENERIC_C_TYPE)a[n] >= xb);
#   endif
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_C_TYPE xa = *a;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_b(cc,xa,>=,(GENERIC_C_TYPE)b,n,nb);
#   else
	     for (n = 0; n < nb; n++) cc[n] = (xa >= (GENERIC_C_TYPE)b[n]);
#   endif
	  }
#  endif
	break;

      case SLANG_LT:
#  if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     cc[n] = ((GENERIC_C_TYPE)*a < (GENERIC_C_TYPE)*b); a += da; b += db;
	  }
#  else
	if (na == nb)
	  {
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_ab(cc,(GENERIC_C_TYPE)a,<,(GENERIC_C_TYPE)b,n,na);
#   else
	     for (n = 0; n < na; n++) cc[n] = ((GENERIC_C_TYPE)a[n] < (GENERIC_C_TYPE)b[n]);
#   endif
	  }
	else if (nb == 1)
	  {
	     GENERIC_C_TYPE xb = *b;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_a(cc,(GENERIC_C_TYPE)a,<,xb,n,na);
#   else
	     for (n = 0; n < na; n++) cc[n] = ((GENERIC_C_TYPE)a[n] < xb);
#   endif
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_C_TYPE xa = *a;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_b(cc,xa,<,(GENERIC_C_TYPE)b,n,nb);
#   else
	     for (n = 0; n < nb; n++) cc[n] = (xa < (GENERIC_C_TYPE)b[n]);
#   endif
	  }
#  endif
	break;

      case SLANG_LE:
#  if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     cc[n] = ((GENERIC_C_TYPE)*a <= (GENERIC_C_TYPE)*b); a += da; b += db;
	  }
#  else
	if (na == nb)
	  {
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_ab(cc,(GENERIC_C_TYPE)a,<=,(GENERIC_C_TYPE)b,n,na);
#   else
	     for (n = 0; n < na; n++) cc[n] = ((GENERIC_C_TYPE)a[n] <= (GENERIC_C_TYPE)b[n]);
#   endif
	  }
	else if (nb == 1)
	  {
	     GENERIC_C_TYPE xb = *b;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_a(cc,(GENERIC_C_TYPE)a,<=,xb,n,na);
#   else
	     for (n = 0; n < na; n++) cc[n] = ((GENERIC_C_TYPE)a[n] <= xb);
#   endif
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_C_TYPE xa = *a;
#   if UNROLL_SOME_LOOPS
	     UNROLL_THIS_b(cc,xa,<=,(GENERIC_C_TYPE)b,n,nb);
#   else
	     for (n = 0; n < nb; n++) cc[n] = (xa <= (GENERIC_C_TYPE)b[n]);
#   endif
	  }
#  endif
	break;
# endif			       /* !defined(JUST_BOOLEAN_BINARY_OPS) */

	/* Boolean operations */
      case SLANG_EQ:
# if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     cc[n] = ((GENERIC_C_TYPE)*a == (GENERIC_C_TYPE)*b); a += da; b += db;
	  }
# else
	if (na == nb)
	  {
#  if UNROLL_SOME_LOOPS
	     UNROLL_THIS_ab(cc,(GENERIC_C_TYPE)a,==,(GENERIC_C_TYPE)b,n,na);
#  else
	     for (n = 0; n < na; n++) cc[n] = ((GENERIC_C_TYPE)a[n] == (GENERIC_C_TYPE)b[n]);
#  endif
	  }
	else if (nb == 1)
	  {
	     GENERIC_C_TYPE xb = *b;
#  if UNROLL_SOME_LOOPS
	     UNROLL_THIS_a(cc,(GENERIC_C_TYPE)a,==,xb,n,na);
#  else
	     for (n = 0; n < na; n++) cc[n] = ((GENERIC_C_TYPE)a[n] == xb);
#  endif
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_C_TYPE xa = *a;
#  if UNROLL_SOME_LOOPS
	     UNROLL_THIS_b(cc,xa,==,(GENERIC_C_TYPE)b,n,nb);
#  else
	     for (n = 0; n < nb; n++) cc[n] = (xa == (GENERIC_C_TYPE)b[n]);
#  endif
	  }
# endif
	break;

      case SLANG_NE:
# if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     cc[n] = ((GENERIC_C_TYPE)*a != (GENERIC_C_TYPE)*b); a += da; b += db;
	  }
# else
	if (na == nb)
	  {
#  if UNROLL_SOME_LOOPS
	     UNROLL_THIS_ab(cc,(GENERIC_C_TYPE)a,!=,(GENERIC_C_TYPE)b,n,na);
#  else
	     for (n = 0; n < na; n++) cc[n] = ((GENERIC_C_TYPE)a[n] != (GENERIC_C_TYPE)b[n]);
#  endif
	  }
	else if (nb == 1)
	  {
	     GENERIC_C_TYPE xb = *b;
#  if UNROLL_SOME_LOOPS
	     UNROLL_THIS_a(cc,(GENERIC_C_TYPE)a,!=,xb,n,na);
#  else
	     for (n = 0; n < na; n++) cc[n] = ((GENERIC_C_TYPE)a[n] != xb);
#  endif
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_C_TYPE xa = *a;
#  if UNROLL_SOME_LOOPS
	     UNROLL_THIS_b(cc,xa,!=,(GENERIC_C_TYPE)b,n,nb);
#  else
	     for (n = 0; n < nb; n++) cc[n] = (xa != (GENERIC_C_TYPE)b[n]);
#  endif
	  }
# endif
	break;

      case SLANG_OR:
# if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     cc[n] = (*a || *b); a += da; b += db;
	  }
# else
	if (na == nb)
	  {
#  if UNROLL_SOME_LOOPS
	     UNROLL_THIS_ab(cc,a,||,b,n,na);
#  else
	     for (n = 0; n < na; n++) cc[n] = (a[n] || b[n]);
#  endif
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
#  if UNROLL_SOME_LOOPS
	     UNROLL_THIS_a(cc,a,||,xb,n,na);
#  else
	     for (n = 0; n < na; n++) cc[n] = (a[n] || xb);
#  endif
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
#  if UNROLL_SOME_LOOPS
	     UNROLL_THIS_b(cc,xa,||,b,n,nb);
#  else
	     for (n = 0; n < nb; n++) cc[n] = (xa || b[n]);
#  endif
	  }
# endif
	break;

      case SLANG_AND:
# if SLANG_OPTIMIZE_FOR_SPEED < 2
	for (n = 0; n < n_max; n++)
	  {
	     cc[n] = (*a && *b); a += da; b += db;
	  }
# else
	if (na == nb)
	  {
#  if UNROLL_SOME_LOOPS
	     UNROLL_THIS_ab(cc,a,&&,b,n,na);
#  else
	     for (n = 0; n < na; n++) cc[n] = (a[n] && b[n]);
#  endif
	  }
	else if (nb == 1)
	  {
	     GENERIC_B_TYPE xb = *b;
#  if UNROLL_SOME_LOOPS
	     UNROLL_THIS_a(cc,a,&&,xb,n,na);
#  else
	     for (n = 0; n < na; n++) cc[n] = (a[n] && xb);
#  endif
	  }
        else /* if (na == 1) */
	  {
	     GENERIC_A_TYPE xa = *a;
#  if UNROLL_SOME_LOOPS
	     UNROLL_THIS_b(cc,xa,&&,b,n,nb);
#  else
	     for (n = 0; n < nb; n++) cc[n] = (xa && b[n]);
#  endif
	  }
# endif
	break;
     }
   return 1;
}

#endif				       /* GENERIC_BINARY_FUNCTION */

#ifdef GENERIC_UNARY_FUNCTION

static int GENERIC_UNARY_FUNCTION
  (int op,
   SLtype a_type, VOID_STAR ap, SLuindex_Type na,
   VOID_STAR bp
   )
{
   GENERIC_A_TYPE *a;
   GENERIC_B_TYPE *b;
   SLuindex_Type n;
   int *ib;
   char *cb;

   (void) a_type;

   a = (GENERIC_A_TYPE *) ap;
   b = (GENERIC_B_TYPE *) bp;

   switch (op)
     {
      default:
	return 0;

      case SLANG_PLUSPLUS:
	for (n = 0; n < na; n++) b[n] = (a[n] + 1);
	break;
      case SLANG_MINUSMINUS:
	for (n = 0; n < na; n++) b[n] = (a[n] - 1);
	break;
      case SLANG_ABS:
	for (n = 0; n < na; n++) b[n] = ABS_FUNCTION (a[n]);
	break;
      case SLANG_SIGN:
	ib = (int *) bp;
	for (n = 0; n < na; n++)
	  {
# ifdef GENERIC_A_TYPE_UNSIGNED
	     ib[n] = (a[n] != 0);
#else
	     ib[n] = ((a[n] > 0) ? 1 : ((a[n] < 0) ? -1 : 0));
#endif
	  }
	break;
      case SLANG_SQR:
	for (n = 0; n < na; n++) b[n] = (a[n] * a[n]);
	break;
      case SLANG_MUL2:
	for (n = 0; n < na; n++) b[n] = (2 * a[n]);
	break;
      case SLANG_CHS:
	for (n = 0; n < na; n++) b[n] = (GENERIC_B_TYPE) -(a[n]);
	break;

      case SLANG_NOT:
	cb = (char *) bp;
	for (n = 0; n < na; n++) cb[n] = (a[n] == 0);
	break;

# ifdef GENERIC_BIT_OPERATIONS
      case SLANG_BNOT:
	for (n = 0; n < na; n++) b[n] = ~(a[n]);
	break;
# endif
      case SLANG_ISPOS:
	cb = (char *) bp;
	for (n = 0; n < na; n++) cb[n] = (a[n] > 0);
	break;
      case SLANG_ISNEG:
	cb = (char *) bp;
# ifdef GENERIC_A_TYPE_UNSIGNED
	for (n = 0; n < na; n++) cb[n] = 0;
# else
	for (n = 0; n < na; n++) cb[n] = (a[n] < 0);
# endif
	break;
      case SLANG_ISNONNEG:
	cb = (char *) bp;
# ifdef GENERIC_A_TYPE_UNSIGNED
	for (n = 0; n < na; n++) cb[n] = 1;
# else
	for (n = 0; n < na; n++) cb[n] = (a[n] >= 0);
# endif
	break;
     }

   return 1;
}
#endif				       /* GENERIC_UNARY_FUNCTION */

#if defined(SCALAR_BINARY_FUNCTION) && SLANG_OPTIMIZE_FOR_SPEED

static int SCALAR_BINARY_FUNCTION (GENERIC_A_TYPE a, GENERIC_B_TYPE b, int op)
{
   switch (op)
     {
      default:
	return 1;
# if SLANG_HAS_FLOAT
#  ifdef POW_FUNCTION
      case SLANG_POW:
	return PUSH_POW_OBJ_FUN(POW_FUNCTION(a, b));
#  endif
# endif
      case SLANG_PLUS:
	return PUSH_SCALAR_OBJ_FUN (a + b);
      case SLANG_MINUS:
	return PUSH_SCALAR_OBJ_FUN (a - b);
      case SLANG_TIMES:
	return PUSH_SCALAR_OBJ_FUN (a * b);
      case SLANG_DIVIDE:
	  {
	     GENERIC_C_TYPE c;
	     PERFORM_DIVIDE(c, a, b);
	     return PUSH_SCALAR_OBJ_FUN (c);
	  }
      case SLANG_MOD:
	  {
	     GENERIC_A_TYPE c;
	     PERFORM_MOD(c, a, b);
	     return PUSH_SCALAR_OBJ_FUN (c);
	  }
# ifdef GENERIC_BIT_OPERATIONS
      case SLANG_BAND:
	return PUSH_SCALAR_OBJ_FUN (a & b);
      case SLANG_BXOR:
	return PUSH_SCALAR_OBJ_FUN (a ^ b);
      case SLANG_BOR:
	return PUSH_SCALAR_OBJ_FUN (a | b);
      case SLANG_SHL:
	return PUSH_SCALAR_OBJ_FUN (a << b);
      case SLANG_SHR:
	return PUSH_SCALAR_OBJ_FUN (a >> b);
# endif
      case SLANG_GT: return SLclass_push_char_obj (SLANG_CHAR_TYPE, (char)(a > b));
      case SLANG_LT: return SLclass_push_char_obj (SLANG_CHAR_TYPE, (char)(a < b));
      case SLANG_GE: return SLclass_push_char_obj (SLANG_CHAR_TYPE, (char)(a >= b));
      case SLANG_LE: return SLclass_push_char_obj (SLANG_CHAR_TYPE, (char)(a <= b));
      case SLANG_EQ: return SLclass_push_char_obj (SLANG_CHAR_TYPE, (char)(a == b));
      case SLANG_NE: return SLclass_push_char_obj (SLANG_CHAR_TYPE, (char)(a != b));
      case SLANG_OR: return SLclass_push_char_obj (SLANG_CHAR_TYPE, (char)(a || b));
      case SLANG_AND: return SLclass_push_char_obj (SLANG_CHAR_TYPE, (char)(a && b));
     }
}

#endif				       /* SCALAR_BINARY_FUNCTION */

#ifdef CMP_FUNCTION
static int CMP_FUNCTION (SLtype unused, VOID_STAR a, VOID_STAR b, int *c)
{
   GENERIC_A_TYPE x;
   GENERIC_B_TYPE y;

   (void) unused;
   x = *(GENERIC_A_TYPE *) a;
   y = *(GENERIC_B_TYPE *) b;

   if (x > y) *c = 1;
   else if (x == y) *c = 0;
   else *c = -1;

   return 0;
}
#endif

#ifdef TO_BINARY_FUNCTION
static int TO_BINARY_FUNCTION (GENERIC_A_TYPE x, char *buf, unsigned int buflen,
			       unsigned int min_num_bits)
{
   GENERIC_A_TYPE x1;
   unsigned int nbits;
   char *s;

   nbits = 1;
   x1 = x;
   while (x1 >> 8) { x1 = x1 >> 8; nbits += 8; }
   while (x1 >> 4) { x1 = x1 >> 4; nbits += 4; }
   while (x1 >> 1) { x1 = x1 >> 1; nbits += 1; }

   if (nbits >= buflen)
     return -1;			       /* calling routine must issue error */

   if (nbits < min_num_bits)
     {
	unsigned int dnbits = min_num_bits - nbits;
	if (nbits + dnbits + 1 > buflen)
	  dnbits = buflen - (nbits + 1);
	nbits += dnbits;
     }
   s = buf + nbits;
   *s = 0;
   while (x)
     {
	*(--s) = '0' + (x & 1);
	x = x >> 1;
     }
   while (s > buf)
     *(--s) = '0';

   return 0;
}
#endif

#ifdef GENERIC_COPY_FUNCTION
static void GENERIC_COPY_FUNCTION (GENERIC_B_TYPE *b, GENERIC_A_TYPE *a, SLuindex_Type n)
{
   SLuindex_Type i;
   for (i = 0; i < n; i++) b[i] = (GENERIC_B_TYPE) a[i];
}
#endif

#ifdef GENERIC_CONVERT_FUNCTION
static VOID_STAR GENERIC_CONVERT_FUNCTION (VOID_STAR ap, SLuindex_Type n)
{
   GENERIC_A_TYPE *a = (GENERIC_A_TYPE *)ap;
   GENERIC_B_TYPE *b;
   SLuindex_Type i;

   if (NULL == (b = (GENERIC_B_TYPE *)_SLcalloc (n, sizeof(GENERIC_B_TYPE))))
     return NULL;
   for (i = 0; i < n; i++) b[i] = (GENERIC_B_TYPE)a[i];
   return (VOID_STAR) b;
}
#endif

#if SLANG_HAS_FLOAT
# ifdef TO_DOUBLE_FUNCTION
static double TO_DOUBLE_FUNCTION (VOID_STAR ap)
{
   return (double) *(GENERIC_A_TYPE *)ap;
}
# endif
#endif

#ifndef CONVERT_TO_SELF_DEFINED
# define CONVERT_TO_SELF_DEFINED 1
/* This function is used  when converting between signed and unsigned versions
 * of integers of the same size.  Applicable to all datatypes
 */
static VOID_STAR convert_self_to_self (VOID_STAR ap, SLuindex_Type n)
{
   (void) n;
   return ap;
}
#endif				       /* CONVERT_TO_SELF_DEFINED */

#undef TO_DOUBLE_FUNCTION
#undef GENERIC_CONVERT_FUNCTION
#undef GENERIC_COPY_FUNCTION
#undef TO_BINARY_FUNCTION
#undef CMP_FUNCTION
#undef SCALAR_BINARY_FUNCTION
#undef PUSH_POW_OBJ_FUN
#undef PUSH_SCALAR_OBJ_FUN
#undef GENERIC_BINARY_FUNCTION
#undef GENERIC_UNARY_FUNCTION
#undef GENERIC_BIT_OPERATIONS
#undef GENERIC_A_TYPE
#undef GENERIC_B_TYPE
#undef GENERIC_C_TYPE
#undef POW_FUNCTION
#undef POW_RESULT_TYPE
#undef MOD_FUNCTION
#undef ABS_FUNCTION
#undef GENERIC_A_TYPE_UNSIGNED
#undef GENERIC_B_TYPE_UNSIGNED
#undef JUST_BOOLEAN_BINARY_OPS
#undef TRAP_DIV_ZERO
#undef UNROLL_SOME_LOOPS
#undef UNROLL_THIS_ab
#undef UNROLL_THIS_b
#undef UNROLL_THIS_a
#undef PERFORM_MOD
#undef PERFORM_DIVIDE
