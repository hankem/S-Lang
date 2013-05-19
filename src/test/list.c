// -*- mode: C; mode: fold -*-

#include "inc.c"

static void create_list_with_values_and_push_it_on_interpreter_stack () /*{{{*/
{
   SLang_List_Type *l = SLang_create_list ();
   int i = 42;
   char *s = "Hello, World!";

   must_succeed ("SLang_list_append @ -1", SLang_list_append (l, SLANG_INT_TYPE, &i, -1));
   must_succeed ("SLang_list_append @  0", SLang_list_append (l, SLANG_STRING_TYPE, &s, 0));
   s = "before end";
   must_succeed ("SLang_list_insert @ -1", SLang_list_insert (l, SLANG_STRING_TYPE, &s, -1));
   s = "at beginning";
   must_succeed ("SLang_list_insert @  0", SLang_list_insert (l, SLANG_STRING_TYPE, &s, 0));

   must_succeed ("SLang_push_list", SLang_push_list (l, 1));

   SLang_load_string ("variable l = (); \
     if (typeof (l) != List_Type)        failed (`List_Type on stack`); \
     if (length (l) != 4)                failed (`length of list`);     \
     if (typeof (l[0]) != String_Type)   failed (`type of l[0]`);       \
     if (l[0] != `at beginning`)         failed (`type of l[0]`);       \
     if (typeof (l[1]) != Integer_Type)  failed (`type of l[1]`);       \
     if (l[1] != 42)                     failed (`value of l[1]`);      \
     if (typeof (l[2]) != String_Type)   failed (`type of l[2]`);       \
     if (l[2] != `before end`)           failed (`type of l[2]`);       \
     if (typeof (l[3]) != String_Type)   failed (`type of l[3]`);       \
     if (l[3] != `Hello, World!`)        failed (`type of l[3]`);       \
   ");
}
/*}}}*/

static void pop_list_from_interpreter_stack () /*{{{*/
{
   SLang_List_Type *l;

   SLang_load_string ("variable l = { 42, `Hello, World!` }; \
     l; \
   ");
   must_succeed ("SLang_pop_list", SLang_pop_list (&l));

   // We need an API to access the list's elements.
}
/*}}}*/

static void push_and_pop_list () /*{{{*/
{
   SLang_List_Type *l1 = SLang_create_list ();
   SLang_List_Type *l2;

   must_succeed ("SLang_push_list", SLang_push_list (l1, 0));
   must_succeed ("SLang_pop_list", SLang_pop_list (&l2));
   if (l2 != l1)  failed ("pop yields pointer to previously pushed list");
}
/*}}}*/

static void pop_and_push_list () /*{{{*/
{
   SLang_List_Type *l;

   SLang_load_string ("variable l1 = { 42, `Hello, World!` }; \
     l1; \
   ");
   must_succeed ("SLang_pop_list", SLang_pop_list (&l));
#if 0  // test fails, since l2 points to another MMT_Type as l1, even though the underlying client data (SLang_List_Type *) are the same
   must_succeed ("SLang_push_list", SLang_push_list (l, 0));

   SLang_load_string ("variable l2 = (); \
     ifnot (__is_same (l1, l2))  failed (`pushing same list as was previously popped`); \
   ");
#endif
}
/*}}}*/

int main (int argc, char **argv)
{
   if (-1 == test_api_feature ("lists"))
     return 1;

   create_list_with_values_and_push_it_on_interpreter_stack ();
   pop_list_from_interpreter_stack ();
   push_and_pop_list ();
   pop_and_push_list ();

   SLang_load_string ("print (`Ok\n`);");

   return SLang_get_error ();
}
