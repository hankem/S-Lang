#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <slang.h>
#include <math.h>

#include "../sl-feat.h"

#if SLANG_HAS_FLOAT
#if defined(__FreeBSD__) || defined(__386BSD__)
# include <floatingpoint.h>
# define HAVE_FPSETMASK 1
#endif
#endif

static int Ignore_Exit = 0;
static void c_exit (int *code)
{
   if (Ignore_Exit == 0)
     exit (*code);
}

static char test_char_return (char *x)
{
   return *x;
}
static short test_short_return (short *x)
{
   return *x;
}
static int test_int_return (int *x)
{
   return *x;
}
static long test_long_return (long *x)
{
   return *x;
}
/* static float test_float_return (float *x) */
/* { */
/*    return *x; */
/* } */
#if SLANG_HAS_FLOAT
static double test_double_return (double *x)
{
   return *x;
}
#endif
typedef struct
{
   int i;
   long l;
   short h;
   char b;
#if SLANG_HAS_FLOAT
   double d;
   double c[2];
#endif
   char *s;
   SLang_Array_Type *a;
   char *ro_str;
}
CStruct_Type;

static SLang_CStruct_Field_Type C_Struct [] =
{
   MAKE_CSTRUCT_FIELD(CStruct_Type, i, "i", SLANG_INT_TYPE, 0),
#if SLANG_HAS_FLOAT
   MAKE_CSTRUCT_FIELD(CStruct_Type, d, "d", SLANG_DOUBLE_TYPE, 0),
   MAKE_CSTRUCT_FIELD(CStruct_Type, c, "z", SLANG_COMPLEX_TYPE, 0),
#endif
   MAKE_CSTRUCT_FIELD(CStruct_Type, s, "s", SLANG_STRING_TYPE, 0),
   MAKE_CSTRUCT_FIELD(CStruct_Type, a, "a", SLANG_ARRAY_TYPE, 0),
   MAKE_CSTRUCT_FIELD(CStruct_Type, ro_str, "ro_str", SLANG_STRING_TYPE, 1),
   MAKE_CSTRUCT_INT_FIELD(CStruct_Type, l, "l", 0),
   MAKE_CSTRUCT_INT_FIELD(CStruct_Type, h, "h", 0),
   MAKE_CSTRUCT_INT_FIELD(CStruct_Type, b, "b", 0),
   SLANG_END_CSTRUCT_TABLE
};

static CStruct_Type C_Struct_Buf;
static void check_cstruct (void)
{
   static int first_time = 1;
   if (first_time)
     {
	C_Struct_Buf.ro_str = "read-only";
	first_time = 0;
     }
}

static void get_c_struct (void)
{
   check_cstruct ();
   (void) SLang_push_cstruct ((VOID_STAR) &C_Struct_Buf, C_Struct);
}

static void set_c_struct (void)
{
   SLang_Array_Type *at;

   SLang_free_cstruct ((VOID_STAR) &C_Struct_Buf, C_Struct);
   if (-1 == SLang_pop_cstruct ((VOID_STAR) &C_Struct_Buf, C_Struct))
     return;
   
   at = C_Struct_Buf.a;
   if ((at != NULL) && (at->data_type == SLANG_INT_TYPE))
     {
	/* The point of this is to look for access errors */
	SLindex_Type i, imax = (SLindex_Type)at->num_elements;
	int sum = 0;
	int *data = (int *)at->data;
	for (i = 0; i < imax; i++)
	  sum += data[i];
     }
}

static void get_c_struct_via_ref (SLang_Ref_Type *r)
{
   check_cstruct ();
   (void) SLang_assign_cstruct_to_ref (r, (VOID_STAR) &C_Struct_Buf, C_Struct);
}

static void test_pop_mmt (void)
{
   SLang_MMT_Type *mmt;
   
   if (NULL == (mmt = SLang_pop_mmt (SLang_peek_at_stack ())))
     return;
   
   if (-1 == SLang_push_mmt (mmt))
     SLang_free_mmt (mmt);
}

static void fake_import (char *);
static SLang_Intrin_Fun_Type Intrinsics [] =
{
   MAKE_INTRINSIC_S("fake_import", fake_import, VOID_TYPE),
   MAKE_INTRINSIC_I("exit", c_exit, VOID_TYPE),
   MAKE_INTRINSIC_1("test_char_return", test_char_return, SLANG_CHAR_TYPE, SLANG_CHAR_TYPE),
   MAKE_INTRINSIC_1("test_short_return", test_short_return, SLANG_SHORT_TYPE, SLANG_SHORT_TYPE),
   MAKE_INTRINSIC_1("test_int_return", test_int_return, SLANG_INT_TYPE, SLANG_INT_TYPE),
   MAKE_INTRINSIC_1("test_long_return", test_long_return, SLANG_LONG_TYPE, SLANG_LONG_TYPE),
   /* MAKE_INTRINSIC_1("test_float_return", test_float_return, SLANG_FLOAT_TYPE, SLANG_FLOAT_TYPE), */
#if SLANG_HAS_FLOAT
   MAKE_INTRINSIC_1("test_double_return", test_double_return, SLANG_DOUBLE_TYPE, SLANG_DOUBLE_TYPE),
#endif
   MAKE_INTRINSIC_0("test_pop_mmt", test_pop_mmt, SLANG_VOID_TYPE),
   MAKE_INTRINSIC_0("get_c_struct", get_c_struct, VOID_TYPE),
   MAKE_INTRINSIC_0("set_c_struct", set_c_struct, VOID_TYPE),
   MAKE_INTRINSIC_1("get_c_struct_via_ref", get_c_struct_via_ref, VOID_TYPE, SLANG_REF_TYPE),
   SLANG_END_INTRIN_FUN_TABLE
};

static void fake_import (char *ns_name)
{
   SLang_NameSpace_Type *ns = SLns_create_namespace (ns_name);
   if (ns == NULL)
     return;
   
   (void) SLns_add_intrin_fun_table (ns, Intrinsics, NULL);
}

int main (int argc, char **argv)
{
   int i;
   int utf8 = 0;

   for (i = 1; i < argc; i++)
     {
	char *arg = argv[i];
	if (*arg != '-')
	  break;

	if (0 == strcmp (arg, "-utf8"))
	  {
	     utf8 = 1;
	     continue;
	  }
	i = argc;
     }

   if (i >= argc)
     {
	fprintf (stderr, "Usage: %s [-utf8] FILE...\n", argv[0]);
	return 1;
     }
   (void) SLutf8_enable (utf8);

   if ((-1 == SLang_init_all ())
       || (-1 == SLang_init_array_extra ())
       || (-1 == SLadd_intrin_fun_table (Intrinsics, NULL)))
     return 1;
   
   SLang_Traceback = 1;

   if (-1 == SLang_set_argc_argv (argc, argv))
     return 1;

#ifdef HAVE_FPSETMASK
# ifndef FP_X_OFL
#  define FP_X_OFL 0
# endif
# ifndef FP_X_INV
#  define FP_X_INV 0
# endif
# ifndef FP_X_DZ
#  define FP_X_DZ 0
# endif
# ifndef FP_X_DNML
#  define FP_X_DNML 0
# endif
# ifndef FP_X_UFL
#  define FP_X_UFL 0
# endif
# ifndef FP_X_IMP
#  define FP_X_IMP 0
# endif
   fpsetmask (~(FP_X_OFL|FP_X_INV|FP_X_DZ|FP_X_DNML|FP_X_UFL|FP_X_IMP));
#endif

   if (i + 1 < argc)
     Ignore_Exit = 1;

   while (i < argc)
     {
	char *file = argv[i];
	if (0 == strncmp (SLpath_extname (file), ".slc", 4))
	  {
	     char *file_sl = SLmake_string (file);
	     file_sl[strlen(file_sl)-1] = 0;
	     if (-1 == SLang_byte_compile_file (file_sl, 0))
	       {
		  SLfree (file_sl);
		  return 1;
	       }
	     SLfree (file_sl);
	  }
	if (-1 == SLang_load_file (file))
	  return 1;
	i++;
     }

   return SLang_get_error ();
}

	
