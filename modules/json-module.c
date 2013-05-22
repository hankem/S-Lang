/* -*- mode: C; mode: fold -*- */

#include <stdlib.h>
#include <string.h>
#include <slang.h>

SLANG_MODULE(json);

#define JSON_MODULE_VERSION_NUMBER 200
static char* json_module_version_string = "pre-0.2.0";

// JSON grammar based upon json.org & ietf.org/rfc/rfc4627.txt /*{{{*/
/*
 * object:
 *   { }
 *   { members }
 * members:
 *   pair
 *   pair , members
 * pair:
 *   string : value
 *
 * array:
 *   [ ]
 *   [ elements ]
 * elements:
 *   value
 *   value , elements
 *
 * value:
 *   string
 *   number
 *   object
 *   array
 *   true
 *   false
 *   null
 *
 * Since a pair consists of a (arbitrary string) keyword and a value,
 * a JSON object maps onto an associatve array (Assoc_Type) in S-Lang.
 *
 * Since a JSON array is a heterogenous collection of elements,
 * these map onto a list (List_Type) in S-Lang.
 *
 * Since S-Lang has no separate boolean type,
 * true|false are represented as 1|0 of Char_Type.
 */

#define BEGIN_ARRAY	 '['
#define BEGIN_OBJECT	 '{'
#define END_ARRAY	 ']'
#define END_OBJECT	 '}'
#define VALUE_SEPARATOR	 ','
#define NAME_SEPARATOR	 ':'
#define STRING_DELIMITER '"'
#define ESCAPE_CHARACTER '\\'

/*}}}*/

static int Json_Parse_Error = -1;

#define DESCRIBE_CHAR_FMT "'%c' = 0x%02X"
#define DESCRIBE_CHAR(ch) ch, (unsigned int)(unsigned char)ch

typedef struct
{
   char *ptr;	/* points into input string */
}
Parse_Type;

static void skip_white (Parse_Type *p) /*{{{*/
{
   char *s = p->ptr;

   while ((*s == ' ') || (*s == '\t') || (*s == '\n') || (*s == '\r'))
     s++;

   p->ptr = s;
}
/*}}}*/

static int looking_at (Parse_Type *p, char ch) /*{{{*/
{
   return *p->ptr == ch;
}
/*}}}*/

static int skip_char (Parse_Type *p, char ch) /*{{{*/
{
   if (! looking_at (p, ch))
     return 0;

   p->ptr++;
   return 1;
}
/*}}}*/

static int parse_hex_digit (char ch) /*{{{*/
{
   if ('0' <= ch && ch <= '9')  return      ch - '0';
   if ('A' <= ch && ch <= 'F')  return 10 + ch - 'A';
   if ('a' <= ch && ch <= 'f')  return 10 + ch - 'a';
   else return -1;
}
/*}}}*/

static char *parse_4_hex_digits (char *s, unsigned int *new_string_len, char *new_string) /*{{{*/
{
   int d1, d2, d3, d4;
   SLwchar_Type wchar;
#define BUFLEN 6
   SLuchar_Type buf[BUFLEN], *u;

   if (   (-1 == (d1 = parse_hex_digit (s[0])))
       || (-1 == (d2 = parse_hex_digit (s[1])))
       || (-1 == (d3 = parse_hex_digit (s[2])))
       || (-1 == (d4 = parse_hex_digit (s[3]))))
     {
	SLang_verror (Json_Parse_Error, "Illegal Unicode escape sequence in JSON string: \\u%c%c%c%c", s[0], s[1], s[2], s[3]);	 // may contain '\000'
	return NULL;
     }

   wchar = (d1 << 12) + (d2 << 8) + (d3 << 4) + d4;
   u = new_string ? (SLuchar_Type*)new_string : buf;
   *new_string_len += SLutf8_encode (wchar, u, BUFLEN) - u;
#undef BUFLEN

   return s+4;
}
/*}}}*/

static int parse_string_length_and_move_ptr (Parse_Type *p) /*{{{*/
{
   unsigned int new_string_len = 0;
   char *s = p->ptr;
   char ch;

   while ((ch = *s++) != STRING_DELIMITER)
     {
	if (ch == 0)
	  {
	     SLang_verror (Json_Parse_Error, "Unexpected end of input seen while parsing a JSON string");
	     return -1;
	  }
	else if ((unsigned char)ch < 32)
	  {
	     SLang_verror (Json_Parse_Error, "Control character 0x%02X in JSON string must be escaped", (unsigned char)ch);
	     return -1;
	  }
	else if (ch == ESCAPE_CHARACTER)
	  {
	     ch = *s++;
	     switch (ch)
	       {
		case STRING_DELIMITER:
		case ESCAPE_CHARACTER:
		case '/':
		case 'b': case 'f': case 'n': case 'r': case 't':
		  new_string_len++;
		  break;
		case 'u':
		  if (NULL == (s = parse_4_hex_digits (s, &new_string_len, NULL)))
		    return -1;
		  break;
		default:
		  SLang_verror (Json_Parse_Error, "Illegal escaped character " DESCRIBE_CHAR_FMT " in JSON string", DESCRIBE_CHAR(ch));
		  return -1;
	       }
	  }
	else
	  new_string_len++;
     }
   p->ptr = s;

   return new_string_len;
}
/*}}}*/

static char *parse_string (Parse_Type *p) /*{{{*/
{
   char *s = p->ptr;
   unsigned int new_string_len = parse_string_length_and_move_ptr (p);
   char *new_string = -1 == new_string_len ? NULL : SLmalloc (new_string_len + 1);
   unsigned int new_string_pos = 0;

   if (NULL == new_string)
     return NULL;

   while (new_string_pos < new_string_len)
     {
	char ch = *s++;
	if ((ch == STRING_DELIMITER) || ((unsigned char)ch < 32))
	  goto return_appplication_error;

	if (ch != ESCAPE_CHARACTER)
	  {
	     new_string[new_string_pos++] = ch;
	     continue;
	  }

	ch = *s++;
	switch (ch)
	  {
	   case STRING_DELIMITER:
	   case ESCAPE_CHARACTER:
	   case '/':
	     new_string[new_string_pos++] = ch; break;
	   case 'b':
	     new_string[new_string_pos++] = '\b'; break;
	   case 'f':
	     new_string[new_string_pos++] = '\f'; break;
	   case 'n':
	     new_string[new_string_pos++] = '\n'; break;
	   case 'r':
	     new_string[new_string_pos++] = '\r'; break;
	   case 't':
	     new_string[new_string_pos++] = '\t'; break;
	   case 'u':
	     if (NULL != (s = parse_4_hex_digits (s, &new_string_pos, new_string + new_string_pos)))
	       break;  // else drop
	   default:
	     goto return_appplication_error;
	  }
     }
   new_string[new_string_pos] = 0;
   return new_string;

return_appplication_error:
   // Since any JSon_Parse_Error should already have been recognized
   // (by parse_string_length_and_move_ptr), something must be wrong here.
   SLang_verror (SL_Application_Error, "JSON string being parsed appears to be changing");
   SLfree (new_string);
   return NULL;
}
/*}}}*/

static int parse_and_push_string (Parse_Type *p) /*{{{*/
{
   char *s = parse_string (p);
   if ((s == NULL)
       || (-1 == SLang_push_string (s)))
     {
	SLfree (s);
	return -1;
     }
   return 0;
}
/*}}}*/

static int parse_and_push_number (Parse_Type *p) /*{{{*/
{
   char *s = p->ptr, ch;
   int is_int = 1, result;

   if (*s == '-')
     s++;
   while ('0' <= *s && *s <= '9')
     s++;
   if (*s == '.')
     {
	is_int = 0;
	s++;
	while ('0' <= *s && *s <= '9')
	  s++;
     }
   if (*s == 'e' || *s == 'E')
     {
	is_int = 0;
	s++;
	if (*s == '+' || *s == '-')
	  s++;
	while ('0' <= *s && *s <= '9')
	  s++;
     }

   ch = *s;
   *s = 0;
   result = is_int
	  ? SLang_push_long (atol (p->ptr))
	  : SLang_push_double (atof (p->ptr));
   *s = ch;
   p->ptr = s;
   return result;
}
/*}}}*/

static int parse_and_push_literal (Parse_Type *p) /*{{{*/
{
   char *s = p->ptr;

   if (*s == 't' && s[1]=='r' && s[2]=='u' && s[3]=='e')
     {
	p->ptr += 4;
	return SLang_push_char (1);  // true
     }
   else if (*s == 'f' && s[1]=='a' && s[2]=='l' && s[3]=='s' && s[4]=='e')
     {
	p->ptr += 5;
	return SLang_push_char (0);  // false
     }
   else if (*s == 'n' && s[1]=='u' && s[2]=='l' && s[3]=='l')
     {
	p->ptr += 4;
	return SLang_push_null ();
     }

   SLang_verror (Json_Parse_Error, "Unexpected character " DESCRIBE_CHAR_FMT " seen while parsing a JSON value", DESCRIBE_CHAR(*s));
   return -1;
}
/*}}}*/

static int parse_and_push_object (Parse_Type *, int);
static int parse_and_push_array (Parse_Type *, int);
static int parse_and_push_value (Parse_Type *p, int only_toplevel_values) /*{{{*/
{
   skip_white (p);

   if (! only_toplevel_values)
     {
	if (skip_char (p, STRING_DELIMITER))
	  return parse_and_push_string (p);
	switch (*p->ptr)
	  {
	   case '-':
	   case '0': case '1': case '2': case '3': case '4':
	   case '5': case '6': case '7': case '8': case '9':
	     return parse_and_push_number (p);
	   case 'f':
	   case 't':
	   case 'n':
	     return parse_and_push_literal (p);
	  }
     }
   if (skip_char (p, BEGIN_OBJECT))
     return parse_and_push_object (p, only_toplevel_values);
   if (skip_char (p, BEGIN_ARRAY))
     return parse_and_push_array (p, only_toplevel_values);

   SLang_verror (Json_Parse_Error, (only_toplevel_values
				    ? "Unexpected character " DESCRIBE_CHAR_FMT " seen while parsing JSON data (must be an object or an array)"
				    : "Unexpected character " DESCRIBE_CHAR_FMT " seen while parsing a JSON value"
				   ), DESCRIBE_CHAR(*p->ptr));
   return -1;
}
/*}}}*/

static int parse_and_push_object (Parse_Type *p, int toplevel) /*{{{*/
{
   SLang_Assoc_Array_Type *assoc = SLang_create_assoc (SLANG_ANY_TYPE, NULL);
   char *keyword;
   SLtype type;
   VOID_STAR value = assoc == NULL ? NULL : SLang_alloc_anytype ();

   if (value == NULL)
     goto return_error;

   skip_white (p);
   if (! looking_at (p, END_OBJECT))
     do
       {
	  skip_white (p);
	  if (! skip_char (p, STRING_DELIMITER))
	    {
	       SLang_verror (Json_Parse_Error, "Expected a string while parsing a JSON object, found " DESCRIBE_CHAR_FMT, DESCRIBE_CHAR(*p->ptr));
	       goto return_error;
	    }

	  keyword = SLang_create_slstring (parse_string (p));
	  if (keyword == NULL)
	    goto return_error;

	  skip_white (p);
	  if (! skip_char (p, NAME_SEPARATOR))
	    {
	       SLang_verror (Json_Parse_Error, "Expected a '%c' while parsing a JSON object, found " DESCRIBE_CHAR_FMT,
			     NAME_SEPARATOR, DESCRIBE_CHAR(*p->ptr));
	       SLang_free_slstring (keyword);
	       goto return_error;
	    }

	  if ((-1 == parse_and_push_value (p, 0))
	      || (-1 == (type = SLang_peek_at_stack ()))
	      || (-1 == SLang_pop_value (type, value))
	      || (-1 == SLang_assoc_put (assoc, keyword, type, value)))
	    {
	       SLang_free_slstring (keyword);
	       goto return_error;
	    }
	  SLang_free_slstring (keyword);

	  skip_white (p);
       }
     while (skip_char (p, VALUE_SEPARATOR));
   SLfree (value);
   value = NULL;  // prevent value from being freed a second time

   if (skip_char (p, END_OBJECT))
     {
	skip_white (p);
	if (! toplevel || looking_at (p, 0))
	  return SLang_push_assoc (assoc, 1);
	SLang_verror (Json_Parse_Error, "Expected end of input after parsing JSON object, found " DESCRIBE_CHAR_FMT, DESCRIBE_CHAR(*p->ptr));
     }
   else
     {
	if (looking_at (p, 0))
	  SLang_verror (Json_Parse_Error, "Unexpected end of input seen while parsing a JSON object");
	else
	  SLang_verror (Json_Parse_Error, "Expected '%c' or '%c' while parsing a JSON object, found " DESCRIBE_CHAR_FMT,
			VALUE_SEPARATOR, END_OBJECT, DESCRIBE_CHAR(*p->ptr));
     }

return_error:
   SLfree (value);
   SLang_free_assoc (assoc);
   return -1;
}
/*}}}*/

static int parse_and_push_array (Parse_Type *p, int toplevel) /*{{{*/
{
   SLang_List_Type *list = SLang_create_list ();
   SLtype type;
   VOID_STAR value = list == NULL ? NULL : SLang_alloc_anytype ();
   if (value == NULL)
     goto return_error;

   skip_white (p);
   if (! looking_at (p, END_ARRAY))
     do
       {
	  if ((-1 == parse_and_push_value (p, 0))
	      || (-1 == (type = SLang_peek_at_stack ()))
	      || (-1 == SLang_pop_value (type, value))
	      || (-1 == SLang_list_append (list, type, value, -1))
	     )
	    goto return_error;
	  skip_white (p);
       }
     while (skip_char (p, VALUE_SEPARATOR));
   SLfree (value);
   value = NULL;  // prevent value from being freed a second time

   if (skip_char (p, END_ARRAY))
     {
	skip_white (p);
	if (! toplevel || looking_at (p, 0))
	  return SLang_push_list (list, 1);
	SLang_verror (Json_Parse_Error, "Expected end of input after parsing JSON array, found " DESCRIBE_CHAR_FMT, DESCRIBE_CHAR(*p->ptr));
     }
   else
     {
	if (looking_at (p, 0))
	  SLang_verror (Json_Parse_Error, "Unexpected end of input seen while parsing a JSON array");
	else
	  SLang_verror (Json_Parse_Error, "Expected '%c' or '%c' while parsing a JSON array, found " DESCRIBE_CHAR_FMT,
			VALUE_SEPARATOR, END_ARRAY, DESCRIBE_CHAR(*p->ptr));
     }

return_error:
   SLfree (value);
   SLang_free_list (list);
   return -1;
}
/*}}}*/

static void parse_start (char *input_string) /*{{{*/
{
   Parse_Type pbuf, *p = &pbuf;
   memset ((char *)p, 0, sizeof (Parse_Type));
   p->ptr = input_string;

   if ((NULL == input_string)
       || (0 == *input_string))
     SLang_verror (Json_Parse_Error, "Unexpected empty input string");
   else
     parse_and_push_value (p, 1);
}
/*}}}*/

static void json_parse (void) /*{{{*/
{
   char* buffer;
   if (-1 == SLpop_string (&buffer))
     SLang_verror (SL_InvalidParm_Error, "usage: json_parse (String_Type json)");
   else
     parse_start (buffer);
}
/*}}}*/

static SLang_Intrin_Fun_Type Module_Intrinsics [] = /*{{{*/
{
   MAKE_INTRINSIC_0("json_parse", json_parse, SLANG_VOID_TYPE),
   SLANG_END_INTRIN_FUN_TABLE
};
/*}}}*/

static SLang_Intrin_Var_Type Module_Variables [] = /*{{{*/
{
   MAKE_VARIABLE("_json_module_version_string", &json_module_version_string, SLANG_STRING_TYPE, 1),
   SLANG_END_INTRIN_VAR_TABLE
};
/*}}}*/

static SLang_IConstant_Type Module_Constants [] = /*{{{*/
{
   MAKE_ICONSTANT("_json_module_version", JSON_MODULE_VERSION_NUMBER),
   SLANG_END_ICONST_TABLE
};
/*}}}*/

int init_json_module_ns (char *ns_name) /*{{{*/
{
   SLang_NameSpace_Type *ns = SLns_create_namespace (ns_name);
   if (ns == NULL)
     return -1;

   if ((Json_Parse_Error == -1)
       && (-1 == (Json_Parse_Error = SLerr_new_exception (SL_RunTime_Error, "Json_Parse_Error", "JSON Parse Error"))))
     return -1;

   if ((-1 == SLns_add_intrin_fun_table (ns, Module_Intrinsics, NULL))
       || (-1 == SLns_add_intrin_var_table (ns, Module_Variables, NULL))
       || (-1 == SLns_add_iconstant_table (ns, Module_Constants, NULL)))
     return -1;

   return 0;
}
/*}}}*/

void deinit_json_module (void) /*{{{*/
{
   /* This function is optional */
}
/*}}}*/
