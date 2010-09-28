#include <stdio.h>
#include <string.h>
#include <slang.h>

SLANG_MODULE(csv);

static int CSV_Parser_Type_Id = 0;

typedef struct _CSV_Parser_Type CSV_Parser_Type;
struct _CSV_Parser_Type
{
   char delimchar;
   char quotechar;
   SLang_Name_Type *read_callback;
   SLang_Any_Type *callback_data;
};

static int execute_read_callback (CSV_Parser_Type *csv, char **sptr)
{
   char *s;

   *sptr = NULL;

   if ((-1 == SLang_start_arg_list ())
       || (-1 == SLang_push_anytype (csv->callback_data))
       || (-1 == SLang_end_arg_list ())
       || (-1 == SLexecute_function (csv->read_callback)))
     return -1;

   if (SLang_peek_at_stack () == SLANG_NULL_TYPE)
     {
	(void) SLang_pop_null ();
	return 0;
     }

   if (-1 == SLang_pop_slstring (&s))
     return -1;
   
   *sptr = s;
   return 1;
}

typedef struct
{
   char **values;
   SLindex_Type num_allocated;
   SLindex_Type num;
}
Values_Array_Type;

static int push_values_array (Values_Array_Type *av)
{
   SLang_Array_Type *at;
   char **new_values;

   if (av->num == 0)
     {
	return SLang_push_null ();
     }

   if (NULL == (new_values = (char **)SLrealloc ((char *)av->values, av->num*sizeof(char *))))
     return -1;
   av->values = new_values;
   av->num_allocated = av->num;
   at = SLang_create_array (SLANG_STRING_TYPE, 0, av->values, &av->num, 1);
   if (at == NULL)
     return -1;

   av->num_allocated = 0;
   av->num = 0;
   av->values = NULL;

   return SLang_push_array (at, 1);
}

static int init_values_array_type (Values_Array_Type *av)
{
   memset ((char *)av, 0, sizeof(Values_Array_Type));
   return 0;
}

static void free_values_array (Values_Array_Type *av)
{
   SLindex_Type i, num;
   char **values;

   if (NULL == (values = av->values))
     return;
   num = av->num;
   for (i = 0; i < num; i++)
     SLang_free_slstring (values[i]);
   SLfree ((char *)values);
}

static int store_value (Values_Array_Type *va, char *value)
{
   SLindex_Type num_allocated;

   num_allocated = va->num_allocated;
   if (num_allocated == va->num)
     {
	char **values;
	num_allocated += 256;
	values = (char **)SLrealloc ((char *)va->values, num_allocated*sizeof(char *));
	if (values == NULL)
	  return -1;
	va->values = values;
     }
   if (NULL == (va->values[va->num] = SLang_create_slstring (value)))
     return -1;

   va->num++;
   return 0;
}

#define NEXT_CHAR(ch) \
   if (do_read) \
   { \
      if (line != NULL) \
	{ \
	   SLang_free_slstring (line); \
	   line = NULL; \
	} \
      status = execute_read_callback (csv, &line); \
      do_read = 0; \
      if (status == -1) \
	goto return_error; \
      line_ofs = 0; \
      if (status == 0) \
	{ \
	   if ((av.num == 0) && (value_ofs == 0)) break; \
	   ch = 0; \
	} \
      else \
	ch = line[line_ofs++]; \
   } \
   else \
     ch = line[line_ofs++]

static int parse_csv_row (CSV_Parser_Type *csv)
{
   char *line;
   size_t line_ofs;
   char *value;
   size_t value_size, value_ofs;
   char delimchar, quotechar;
   int return_status;
   Values_Array_Type av;
   int do_read, in_quote;

   if (-1 == init_values_array_type (&av))
     return -1;

   delimchar = csv->delimchar;
   quotechar = csv->quotechar;

   value_ofs = line_ofs = 0;
   value_size = 0;
   value = NULL;
   line = NULL;
   do_read = 1;

   in_quote = 0;
   return_status = -1;
   while (1)
     {
	int status;
	char ch;

	if (value_ofs == value_size)
	  {
	     char *new_value;

	     if (value_size < 64)
	       value_size += 32;
	     else if (value_size < 8192)
	       value_size *= 2;
	     else value_size += 8192;

	     new_value = SLrealloc (value, value_size);
	     if (new_value == NULL)
	       goto return_error;
	     value = new_value;
	  }

	NEXT_CHAR(ch);

	if ((ch == quotechar) && quotechar)
	  {
	     if (in_quote)
	       {
		  NEXT_CHAR(ch);
		  if (ch == quotechar)
		    {
		       value[value_ofs++] = ch;
		       continue;
		    }

		  if ((ch != ',') && (ch != 0) && (ch != '\n'))
		    {
		       SLang_verror (SL_Data_Error, "Expecting a delimiter after an end-quote character");
		       goto return_error;
		    }
		  in_quote = 0;
		  /* drop */
	       }
	     else if (value_ofs != 0)
	       {
		  SLang_verror (SL_Data_Error, "Misplaced quote character inside a csv field");
		  goto return_error;
	       }
	     else 
	       {
		  in_quote = 1;
		  continue;
	       }
	  }

	if (ch == delimchar)
	  {
	     if (in_quote)
	       {
		  value[value_ofs++] = ch;
		  continue;
	       }
	     value[value_ofs] = 0;
	     if (-1 == store_value (&av, value))
	       goto return_error;
	     value_ofs = 0;
	     continue;
	  }
	if ((ch == 0) || (ch == '\n'))
	  {
	     if (in_quote)
	       {
		  if (ch == '\n')
		    {
		       value[value_ofs++] = ch;
		       do_read = 1;
		       continue;
		    }
		  SLang_verror (SL_Data_Error, "No closing quote seen parsing CSV data");
		  goto return_error;
	       }

	     value[value_ofs] = 0;
	     if (-1 == store_value (&av, value))
	       goto return_error;

	     break;		       /* done */
	  }

	value[value_ofs++] = ch;
     }

   /* Get here if at end of line or file */
   return_status = push_values_array (&av);
   /* drop */

return_error:
   SLfree (value);
   free_values_array(&av);
   if (line != NULL)
     SLang_free_slstring (line);
   return return_status;
}

static void free_csv_parser (CSV_Parser_Type *csv)
{
   if (csv == NULL)
     return;
   if (csv->callback_data != NULL) SLang_free_anytype (csv->callback_data);
   if (csv->read_callback != NULL) SLang_free_function (csv->read_callback);
   SLfree ((char *)csv);
}

/* Usage: obj = cvs_parser_new (&read_callback, callback_data, delim, quote) */
static void new_csv_parser_intrin (void)
{
   CSV_Parser_Type *csv;
   SLang_MMT_Type *mmt;

   if (NULL == (csv = (CSV_Parser_Type *)SLmalloc(sizeof(CSV_Parser_Type))))
     return;
   memset ((char *)csv, 0, sizeof(CSV_Parser_Type));

   if ((-1 == SLang_pop_char (&csv->quotechar))
       || (-1 == SLang_pop_char (&csv->delimchar))
       || (-1 == SLang_pop_anytype (&csv->callback_data))
       || (NULL == (csv->read_callback = SLang_pop_function ()))
       || (NULL == (mmt = SLang_create_mmt (CSV_Parser_Type_Id, (VOID_STAR)csv))))
     {
	free_csv_parser (csv);
	return;
     }

   if (-1 == SLang_push_mmt (mmt))
     SLang_free_mmt (mmt);
}

static void parse_csv_row_intrin (CSV_Parser_Type *csv)
{
   (void) parse_csv_row (csv);
}

#define DUMMY_CSV_PARSER_TYPE ((SLtype)-1)
static SLang_Intrin_Fun_Type Module_Intrinsics [] =
{
   MAKE_INTRINSIC_0("_csv_parser_new", new_csv_parser_intrin, SLANG_VOID_TYPE),
   MAKE_INTRINSIC_1("_csv_parse_row", parse_csv_row_intrin, SLANG_VOID_TYPE, DUMMY_CSV_PARSER_TYPE),
   SLANG_END_INTRIN_FUN_TABLE
};

static void destroy_csv (SLtype type, VOID_STAR f)
{
   (void) type;
   free_csv_parser ((CSV_Parser_Type *)f);
}

static int register_csv_type (void)
{
   SLang_Class_Type *cl;

   if (CSV_Parser_Type_Id != 0)
     return 0;

   if (NULL == (cl = SLclass_allocate_class ("CSV_Parser_Type")))
     return -1;

   if (-1 == SLclass_set_destroy_function (cl, destroy_csv))
     return -1;

   /* By registering as SLANG_VOID_TYPE, slang will dynamically allocate a
    * type.
    */
   if (-1 == SLclass_register_class (cl, SLANG_VOID_TYPE, sizeof (CSV_Parser_Type), SLANG_CLASS_TYPE_MMT))
     return -1;

   CSV_Parser_Type_Id = SLclass_get_class_id (cl);
   if (-1 == SLclass_patch_intrin_fun_table1 (Module_Intrinsics, DUMMY_CSV_PARSER_TYPE, CSV_Parser_Type_Id))
     return -1;

   return 0;
}

   
int init_csv_module_ns (char *ns_name)
{
   SLang_NameSpace_Type *ns = SLns_create_namespace (ns_name);
   if (ns == NULL)
     return -1;

   if (-1 == register_csv_type ())
     return -1;

   if (-1 == SLns_add_intrin_fun_table (ns, Module_Intrinsics, NULL))
     return -1;

   return 0;
}

/* This function is optional */
void deinit_csv_module (void)
{
}
