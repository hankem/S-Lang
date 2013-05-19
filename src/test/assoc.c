// -*- mode: C; mode: fold -*-

#include "inc.c"

static void create_assoc_with_values_and_push_it_on_interpreter_stack () /*{{{*/
{
   SLang_Assoc_Array_Type *a = SLang_create_assoc (SLANG_ANY_TYPE, NULL);
   SLstr_Type *key;
   int i = 42;
   char *s = "Hello, World!";

   key = SLang_create_slstring ("i");
   must_succeed ("SLang_assoc_put", SLang_assoc_put (a, key, SLANG_INT_TYPE, &i));

   key = SLang_create_slstring ("s");
   must_succeed ("SLang_assoc_put", SLang_assoc_put (a, key, SLANG_STRING_TYPE, &s));

   must_succeed ("SLang_push_assoc", SLang_push_assoc (a, 1));

   SLang_load_string ("variable a = ();  \
     if (typeof (a) != Assoc_Type)         failed (`Assoc_Type on stack`); \
     ifnot (assoc_key_exists (a, `i`))     failed (`key 'i' is missing`);  \
     if (typeof (a[`i`]) != Integer_Type)  failed (`type of a['i']`);      \
     if (a[`i`] != 42)                     failed (`value of a['i']`);     \
     ifnot (assoc_key_exists (a, `s`))     failed (`key 's' is missing `); \
     if (typeof (a[`s`]) != String_Type)   failed (`type of a['s']`);      \
     if (a[`s`] != `Hello, World!`)        failed (`type of a['s']`);      \
   ");
}
/*}}}*/

static void create_assoc_with_default_value_and_push_it_on_interpreter_stack () /*{{{*/
{
   char *default_value = "default value";
   SLang_Assoc_Array_Type *a = SLang_create_assoc (SLANG_STRING_TYPE, &default_value);

   SLstr_Type *key = SLang_create_slstring ("S");
   char *s = "HELLO, WORLD!";
   must_succeed ("SLang_assoc_put", SLang_assoc_put (a, key, SLANG_STRING_TYPE, &s));

   must_succeed ("SLang_push_assoc", SLang_push_assoc ( a, 1));

   SLang_load_string ("variable a = (); \
     if (typeof (a) != Assoc_Type)        failed (`Assoc_Type on stack`); \
     if (assoc_key_exists (a, `i`))       failed (`key 'i' exists`);      \
     if (typeof (a[`i`]) != String_Type)  failed (`type of a['i']`);      \
     if (a[`i`] != `default value`)       failed (`value of a['i']`);     \
     ifnot (assoc_key_exists (a, `S`))    failed (`key 'S' is missing `); \
     if (typeof (a[`S`]) != String_Type)  failed (`type of a['S']`);      \
     if (a[`S`] != `HELLO, WORLD!`)       failed (`type of a['S']`);      \
   ;");
}
/*}}}*/

static void pop_assoc_from_interpreter_stack () /*{{{*/
{
   SLang_Assoc_Array_Type *a;
   SLstr_Type *key;
   SLtype type;
   VOID_STAR value = SLang_alloc_anytype ();

   SLang_load_string ("variable a = Assoc_Type[]; \
     a[`i`] = 42; \
     a[`s`] = `Hello, World!`; \
     a; \
   ");

   must_succeed ("SLang_pop_assoc", SLang_pop_assoc (&a));

   key = SLang_create_slstring ("i");
   must_succeed ("SLang_assoc_get", SLang_assoc_get (a, key, &type, &value));
   if (type != SLANG_INT_TYPE)  failed ("type of a['i']");
   if (*((int*)value) != 42)  failed ("value of a['i']");

   key = SLang_create_slstring ("s");
   must_succeed ("SLang_assoc_get", SLang_assoc_get (a, key, &type, &value));
   if (type != SLANG_STRING_TYPE)  failed ("type of a['s']");
   if (strcmp (*((char**)value), "Hello, World!"))  failed ("value of a['s']");
}
/*}}}*/

static void push_and_pop_assoc () /*{{{*/
{
   SLang_Assoc_Array_Type *a1 = SLang_create_assoc (SLANG_ANY_TYPE, NULL);
   SLang_Assoc_Array_Type *a2;

   must_succeed ("SLang_push_assoc", SLang_push_assoc (a1, 0));
   must_succeed ("SLang_pop_assoc", SLang_pop_assoc (&a2));
   if (a2 != a1)  failed ("pop yields pointer to previously pushed assoc");
}
/*}}}*/

static void pop_and_push_assoc () /*{{{*/
{
   SLang_Assoc_Array_Type *a;

   SLang_load_string ("variable a1 = Assoc_Type[]; \
     a1; \
   ");
   must_succeed ("SLang_pop_assoc", SLang_pop_assoc (&a));
#if 0  // test fails, since a2 points to another MMT_Type as a1, even though the underlying client data (SLang_Assoc_Array_Type *) are the same
   must_succeed ("SLang_push_assoc", SLang_push_assoc (a, 0));

   SLang_load_string ("variable a2 = (); \
     ifnot (__is_same (a1, a2))  failed (`pushing same assoc as was previously popped`); \
   ");
#endif
}
/*}}}*/

int main (int argc, char **argv)
{
   if (-1 == test_api_feature ("Associative Arrays"))
     return 1;

   create_assoc_with_values_and_push_it_on_interpreter_stack ();
   create_assoc_with_default_value_and_push_it_on_interpreter_stack ();
   pop_assoc_from_interpreter_stack ();
   push_and_pop_assoc ();
   pop_and_push_assoc ();

   SLang_load_string ("print (`Ok\n`);");

   return SLang_get_error ();
}
