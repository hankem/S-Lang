#include <stdlib.h>
#include <slang.h>

static int Ignore_Exit = 0;
static void c_exit (int *code)
{
   if (Ignore_Exit == 0)
     exit (*code);
}

static void failed (char *message)
{
   int status = 1;
   SLang_verror (SL_Any_Error, "Failed: %s\n", message);
   c_exit (&status);
}

static void must_succeed (char *message, int status)
{
   if (status != 0)
     failed (message);
}

static int test_api_feature (char *feature)
{
   if ((-1 == SLang_init_all ())
       || (-1 == SLadd_intrinsic_function ("exit", (FVOID_STAR) c_exit, SLANG_VOID_TYPE, 1, SLANG_INT_TYPE))
       || (-1 == SLang_load_file ("./inc.sl")))
     return -1;

   SLang_push_string (feature);
   return SLang_load_string ("() + ` (C API)`; testing_feature");
}
