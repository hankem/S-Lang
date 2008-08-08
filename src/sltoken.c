/*
Copyright (C) 2004, 2005, 2006, 2007, 2008 John E. Davis

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

#include "slang.h"
#include "_slang.h"

#define MAX_TOKEN_LEN 254
#define MAX_FILE_LINE_LEN 256

/* int _pSLang_Compile_Line_Num_Info; */
#if SLANG_HAS_BOSEOS
int _pSLang_Compile_BOSEOS;
int _pSLang_Compile_BOFEOF;
#endif
#if SLANG_HAS_DEBUG_CODE
/* static int Default_Compile_Line_Num_Info; */
#if 0
static int Default_Compile_BOSEOS;
#endif
#endif

static char Empty_Line[1] = {0};

static char *Input_Line = Empty_Line;
static char *Input_Line_Pointer;

static SLprep_Type *This_SLpp;

static SLang_Load_Type *LLT;

static SLCONST char *map_token_to_string (_pSLang_Token_Type *tok)
{
   SLCONST char *s;
   static char numbuf [32];
   unsigned char type;
   s = NULL;

   if (tok != NULL) type = tok->type;
   else type = 0;

   switch (type)
     {
      case 0:
	s = "??";
	break;

      case CHAR_TOKEN:
      case SHORT_TOKEN:
      case INT_TOKEN:
      case LONG_TOKEN:
	sprintf (numbuf, "%ld", tok->v.long_val);
	s = numbuf;
	break;

      case UCHAR_TOKEN:
      case USHORT_TOKEN:
      case UINT_TOKEN:
      case ULONG_TOKEN:
	sprintf (numbuf, "%lu", (unsigned long)tok->v.long_val);
	s = numbuf;
	break;

#if HAVE_LONG_LONG
      case LLONG_TOKEN:
	sprintf (numbuf, "%lld", tok->v.llong_val);
	s = numbuf;
	break;
	
      case ULLONG_TOKEN:
	sprintf (numbuf, "%llu", tok->v.ullong_val);
	s = numbuf;
	break;
#endif
	
      case OBRACKET_TOKEN: s = "["; break;
      case CBRACKET_TOKEN: s = "]"; break;
      case OPAREN_TOKEN: s = "("; break;
      case CPAREN_TOKEN: s = ")"; break;
      case OBRACE_TOKEN: s = "{"; break;
      case CBRACE_TOKEN: s = "}"; break;
      case POW_TOKEN: s = "^"; break;
      case ADD_TOKEN: s = "+"; break;
      case SUB_TOKEN: s = "-"; break;
      case TIMES_TOKEN: s = "*"; break;
      case DIV_TOKEN: s = "/"; break;
      case LT_TOKEN: s = "<"; break;
      case LE_TOKEN: s = "<="; break;
      case GT_TOKEN: s = ">"; break;
      case GE_TOKEN: s = ">="; break;
      case EQ_TOKEN: s = "=="; break;
      case NE_TOKEN: s = "!="; break;
      case AND_TOKEN: s = "and"; break;
      case OR_TOKEN: s = "or"; break;
      case MOD_TOKEN: s = "mod"; break;
      case BAND_TOKEN: s = "&"; break;
      case SHL_TOKEN: s = "shl"; break;
      case SHR_TOKEN: s = "shr"; break;
      case BXOR_TOKEN: s = "xor"; break;
      case BOR_TOKEN: s = "|"; break;
      case POUND_TOKEN: s = "#"; break;
      case DEREF_TOKEN: s = "@"; break;
      case COMMA_TOKEN: s = ","; break;
      case SEMICOLON_TOKEN: s = ";"; break;
      case COLON_TOKEN: s = ":"; break;

      case ARRAY_TOKEN: s = "["; break;
      case DOT_TOKEN: s = "."; break;

#if SLANG_HAS_FLOAT
      case FLOAT_TOKEN:
      case DOUBLE_TOKEN:
      case COMPLEX_TOKEN:
#endif
      case IDENT_TOKEN:
	if ((tok->free_sval_flag == 0) || (tok->num_refs == 0))
	  break;
	/* drop */
      default:
	s = tok->v.s_val;
	break;
     }

   if (s == NULL)
     {
	sprintf (numbuf, "(0x%02X)", type);
	s = numbuf;
     }

   return s;
}

void _pSLparse_error (int errcode, SLCONST char *str, _pSLang_Token_Type *tok, int flag)
{
   int line = LLT->line_num;
   SLFUTURE_CONST char *file = (char *) LLT->name;

   if (str == NULL)
     str = "Parse Error";

#if SLANG_HAS_DEBUG_CODE
   if ((tok != NULL) && (tok->line_number != -1))
     line = tok->line_number;
#endif
   if (file == NULL) file = "??";

   if (flag || (_pSLang_Error == 0))
     _pSLang_verror (errcode, "%s:%d: %s: found '%s'",
		   file, line, str, map_token_to_string (tok));

   (void) _pSLerr_set_line_info (file, line, NULL);
}


#define ALPHA_CHAR 	1
#define DIGIT_CHAR	2
#define EXCL_CHAR 	3
#define SEP_CHAR	4
#define OP_CHAR		5
#define DOT_CHAR	6
#define BOLDOT_CHAR	7
#define DQUOTE_CHAR	8
#define QUOTE_CHAR	9
#define COMMENT_CHAR	10
#define NL_CHAR		11
#define BAD_CHAR	12
#define WHITE_CHAR	13

#define CHAR_EOF	255

#define CHAR_CLASS(c)	(Char_Type_Table[(c)][0])
#define CHAR_DATA(c)	(Char_Type_Table[(c)][1])

/* In this table, if a single character can represent an operator, e.g.,
 * '&' (BAND_TOKEN), then it must be placed before multiple-character
 * operators that begin with the same character, e.g., "&=".  See
 * get_op_token to see how this is exploited.
 *
 * The third character null terminates the operator string.  This is for
 * the token structure.
 */
static SLCONST char Operators [31][4] =
{
#define OFS_EXCL	0
     {'!',	'=',	0, NE_TOKEN},
#define OFS_POUND	1
     {'#',	0,	0, POUND_TOKEN},
#define OFS_BAND	2
     {'&',	0,	0, BAND_TOKEN},
     {'&',	'&',	0, SC_AND_TOKEN},
     {'&',	'=',	0, BANDEQS_TOKEN},
#define OFS_STAR	5
     {'*',	0,	0, TIMES_TOKEN},
     {'*',	'=',	0, TIMESEQS_TOKEN},
#define OFS_PLUS	7
     {'+',	0,	0, ADD_TOKEN},
     {'+',	'+',	0, PLUSPLUS_TOKEN},
     {'+',	'=',	0, PLUSEQS_TOKEN},
#define OFS_MINUS	10
     {'-',	0,	0, SUB_TOKEN},
     {'-',	'-',	0, MINUSMINUS_TOKEN},
     {'-',	'=',	0, MINUSEQS_TOKEN},
     {'-',	'>',	0, NAMESPACE_TOKEN},
#define OFS_DIV		14
     {'/',	0,	0, DIV_TOKEN},
     {'/',	'=',	0, DIVEQS_TOKEN},
#define OFS_LT		16
     {'<',	0,	0, LT_TOKEN},
     {'<',	'<',	0, SHL_TOKEN},
     {'<',	'=',	0, LE_TOKEN},
#define OFS_EQS		19
     {'=',	0,	0, ASSIGN_TOKEN},
     {'=',	'=',	0, EQ_TOKEN},
#define OFS_GT		21
     {'>',	0,	0, GT_TOKEN},
     {'>',	'=',	0, GE_TOKEN},
     {'>',	'>',	0, SHR_TOKEN},
#define OFS_AT		24
     {'@',	0,	0, DEREF_TOKEN},
#define OFS_POW		25
     {'^',	0,	0, POW_TOKEN},
#define OFS_BOR		26
     {'|',	0,	0, BOR_TOKEN},
     {'|',	'|',	0, SC_OR_TOKEN},
     {'|',	'=',	0, BOREQS_TOKEN},
#define OFS_BNOT	29
     {'~',	0,	0, BNOT_TOKEN},
     {	0,	0,	0, EOF_TOKEN}
};

static SLCONST unsigned char Char_Type_Table[256][2] =
{
 { NL_CHAR, 0 },	/* 0x0 */   { BAD_CHAR, 0 },	/* 0x1 */
 { BAD_CHAR, 0 },	/* 0x2 */   { BAD_CHAR, 0 },	/* 0x3 */
 { BAD_CHAR, 0 },	/* 0x4 */   { BAD_CHAR, 0 },	/* 0x5 */
 { BAD_CHAR, 0 },	/* 0x6 */   { BAD_CHAR, 0 },	/* 0x7 */
 { WHITE_CHAR, 0 },	/* 0x8 */   { WHITE_CHAR, 0 },	/* 0x9 */
 { NL_CHAR, 0 },	/* \n */   { WHITE_CHAR, 0 },	/* 0xb */
 { WHITE_CHAR, 0 },	/* 0xc */   { WHITE_CHAR, 0 },	/* \r */
 { BAD_CHAR, 0 },	/* 0xe */   { BAD_CHAR, 0 },	/* 0xf */
 { BAD_CHAR, 0 },	/* 0x10 */  { BAD_CHAR, 0 },	/* 0x11 */
 { BAD_CHAR, 0 },	/* 0x12 */  { BAD_CHAR, 0 },	/* 0x13 */
 { BAD_CHAR, 0 },	/* 0x14 */  { BAD_CHAR, 0 },	/* 0x15 */
 { BAD_CHAR, 0 },	/* 0x16 */  { BAD_CHAR, 0 },	/* 0x17 */
 { BAD_CHAR, 0 },	/* 0x18 */  { BAD_CHAR, 0 },	/* 0x19 */
 { BAD_CHAR, 0 },	/* 0x1a */  { BAD_CHAR, 0 },	/* 0x1b */
 { BAD_CHAR, 0 },	/* 0x1c */  { BAD_CHAR, 0 },	/* 0x1d */
 { BAD_CHAR, 0 },	/* 0x1e */  { BAD_CHAR, 0 },	/* 0x1f */
 { WHITE_CHAR, 0 },	/* 0x20 */  { EXCL_CHAR, OFS_EXCL },	/* ! */
 { DQUOTE_CHAR, 0 },	/* " */	    { OP_CHAR, OFS_POUND },	/* # */
 { ALPHA_CHAR, 0 },	/* $ */	    { NL_CHAR, 0 },/* % */
 { OP_CHAR, OFS_BAND },	/* & */	    { QUOTE_CHAR, 0 },	/* ' */
 { SEP_CHAR, OPAREN_TOKEN },	/* ( */	    { SEP_CHAR, CPAREN_TOKEN },	/* ) */
 { OP_CHAR, OFS_STAR },	/* * */	    { OP_CHAR, OFS_PLUS},	/* + */
 { SEP_CHAR, COMMA_TOKEN },	/* , */	    { OP_CHAR, OFS_MINUS },	/* - */
 { DOT_CHAR, 0 },	/* . */	    { OP_CHAR, OFS_DIV },	/* / */
 { DIGIT_CHAR, 0 },	/* 0 */	    { DIGIT_CHAR, 0 },	/* 1 */
 { DIGIT_CHAR, 0 },	/* 2 */	    { DIGIT_CHAR, 0 },	/* 3 */
 { DIGIT_CHAR, 0 },	/* 4 */	    { DIGIT_CHAR, 0 },	/* 5 */
 { DIGIT_CHAR, 0 },	/* 6 */	    { DIGIT_CHAR, 0 },	/* 7 */
 { DIGIT_CHAR, 0 },	/* 8 */	    { DIGIT_CHAR, 0 },	/* 9 */
 { SEP_CHAR, COLON_TOKEN },	/* : */	    { SEP_CHAR, SEMICOLON_TOKEN },	/* ; */
 { OP_CHAR, OFS_LT },	/* < */	    { OP_CHAR, OFS_EQS },	/* = */
 { OP_CHAR, OFS_GT },	/* > */	    { BAD_CHAR, 0 },	/* ? */
 { OP_CHAR, OFS_AT},	/* @ */	    { ALPHA_CHAR, 0 },	/* A */
 { ALPHA_CHAR, 0 },	/* B */	    { ALPHA_CHAR, 0 },	/* C */
 { ALPHA_CHAR, 0 },	/* D */	    { ALPHA_CHAR, 0 },	/* E */
 { ALPHA_CHAR, 0 },	/* F */	    { ALPHA_CHAR, 0 },	/* G */
 { ALPHA_CHAR, 0 },	/* H */	    { ALPHA_CHAR, 0 },	/* I */
 { ALPHA_CHAR, 0 },	/* J */	    { ALPHA_CHAR, 0 },	/* K */
 { ALPHA_CHAR, 0 },	/* L */	    { ALPHA_CHAR, 0 },	/* M */
 { ALPHA_CHAR, 0 },	/* N */	    { ALPHA_CHAR, 0 },	/* O */
 { ALPHA_CHAR, 0 },	/* P */	    { ALPHA_CHAR, 0 },	/* Q */
 { ALPHA_CHAR, 0 },	/* R */	    { ALPHA_CHAR, 0 },	/* S */
 { ALPHA_CHAR, 0 },	/* T */	    { ALPHA_CHAR, 0 },	/* U */
 { ALPHA_CHAR, 0 },	/* V */	    { ALPHA_CHAR, 0 },	/* W */
 { ALPHA_CHAR, 0 },	/* X */	    { ALPHA_CHAR, 0 },	/* Y */
 { ALPHA_CHAR, 0 },	/* Z */	    { SEP_CHAR, OBRACKET_TOKEN },	/* [ */
 { BAD_CHAR, 0 },	/* \ */	    { SEP_CHAR, CBRACKET_TOKEN },	/* ] */
 { OP_CHAR, OFS_POW },	/* ^ */	    { ALPHA_CHAR, 0 },	/* _ */
 { BAD_CHAR, 0 },	/* ` */	    { ALPHA_CHAR, 0 },	/* a */
 { ALPHA_CHAR, 0 },	/* b */	    { ALPHA_CHAR, 0 },	/* c */
 { ALPHA_CHAR, 0 },	/* d */	    { ALPHA_CHAR, 0 },	/* e */
 { ALPHA_CHAR, 0 },	/* f */	    { ALPHA_CHAR, 0 },	/* g */
 { ALPHA_CHAR, 0 },	/* h */	    { ALPHA_CHAR, 0 },	/* i */
 { ALPHA_CHAR, 0 },	/* j */	    { ALPHA_CHAR, 0 },	/* k */
 { ALPHA_CHAR, 0 },	/* l */	    { ALPHA_CHAR, 0 },	/* m */
 { ALPHA_CHAR, 0 },	/* n */	    { ALPHA_CHAR, 0 },	/* o */
 { ALPHA_CHAR, 0 },	/* p */	    { ALPHA_CHAR, 0 },	/* q */
 { ALPHA_CHAR, 0 },	/* r */	    { ALPHA_CHAR, 0 },	/* s */
 { ALPHA_CHAR, 0 },	/* t */	    { ALPHA_CHAR, 0 },	/* u */
 { ALPHA_CHAR, 0 },	/* v */	    { ALPHA_CHAR, 0 },	/* w */
 { ALPHA_CHAR, 0 },	/* x */	    { ALPHA_CHAR, 0 },	/* y */
 { ALPHA_CHAR, 0 },	/* z */	    { SEP_CHAR, OBRACE_TOKEN },	/* { */
 { OP_CHAR, OFS_BOR },	/* | */	    { SEP_CHAR, CBRACE_TOKEN },	/* } */
 { OP_CHAR, OFS_BNOT },	/* ~ */	    { BAD_CHAR, 0 },	/* 0x7f */
   
 { ALPHA_CHAR, 0 },	/* € */	    { ALPHA_CHAR, 0 },	/*  */
 { ALPHA_CHAR, 0 },	/* ‚ */	    { ALPHA_CHAR, 0 },	/* ƒ */
 { ALPHA_CHAR, 0 },	/* „ */	    { ALPHA_CHAR, 0 },	/* … */
 { ALPHA_CHAR, 0 },	/* † */	    { ALPHA_CHAR, 0 },	/* ‡ */
 { ALPHA_CHAR, 0 },	/* ˆ */	    { ALPHA_CHAR, 0 },	/* ‰ */
 { ALPHA_CHAR, 0 },	/* Š */	    { ALPHA_CHAR, 0 },	/* ‹ */
 { ALPHA_CHAR, 0 },	/* Œ */	    { ALPHA_CHAR, 0 },	/*  */
 { ALPHA_CHAR, 0 },	/* Ž */	    { ALPHA_CHAR, 0 },	/*  */
 { ALPHA_CHAR, 0 },	/*  */	    { ALPHA_CHAR, 0 },	/* ‘ */
 { ALPHA_CHAR, 0 },	/* ’ */	    { ALPHA_CHAR, 0 },	/* “ */
 { ALPHA_CHAR, 0 },	/* ” */	    { ALPHA_CHAR, 0 },	/* • */
 { ALPHA_CHAR, 0 },	/* – */	    { ALPHA_CHAR, 0 },	/* — */
 { ALPHA_CHAR, 0 },	/* ˜ */	    { ALPHA_CHAR, 0 },	/* ™ */
 { ALPHA_CHAR, 0 },	/* š */	    { ALPHA_CHAR, 0 },	/* › */
 { ALPHA_CHAR, 0 },	/* œ */	    { ALPHA_CHAR, 0 },	/*  */
 { ALPHA_CHAR, 0 },	/* ž */	    { ALPHA_CHAR, 0 },	/* Ÿ */
 { ALPHA_CHAR, 0 },	/*   */	    { ALPHA_CHAR, 0 },	/* ¡ */
 { ALPHA_CHAR, 0 },	/* ¢ */	    { ALPHA_CHAR, 0 },	/* £ */
 { ALPHA_CHAR, 0 },	/* ¤ */	    { ALPHA_CHAR, 0 },	/* ¥ */
 { ALPHA_CHAR, 0 },	/* ¦ */	    { ALPHA_CHAR, 0 },	/* § */
 { ALPHA_CHAR, 0 },	/* ¨ */	    { ALPHA_CHAR, 0 },	/* © */
 { ALPHA_CHAR, 0 },	/* ª */	    { ALPHA_CHAR, 0 },	/* « */
 { ALPHA_CHAR, 0 },	/* ¬ */	    { ALPHA_CHAR, 0 },	/* ­ */
 { ALPHA_CHAR, 0 },	/* ® */	    { ALPHA_CHAR, 0 },	/* ¯ */
 { ALPHA_CHAR, 0 },	/* ° */	    { ALPHA_CHAR, 0 },	/* ± */
 { ALPHA_CHAR, 0 },	/* ² */	    { ALPHA_CHAR, 0 },	/* ³ */
 { ALPHA_CHAR, 0 },	/* ´ */	    { ALPHA_CHAR, 0 },	/* µ */
 { ALPHA_CHAR, 0 },	/* ¶ */	    { ALPHA_CHAR, 0 },	/* · */
 { ALPHA_CHAR, 0 },	/* ¸ */	    { ALPHA_CHAR, 0 },	/* ¹ */
 { ALPHA_CHAR, 0 },	/* º */	    { ALPHA_CHAR, 0 },	/* » */
 { ALPHA_CHAR, 0 },	/* ¼ */	    { ALPHA_CHAR, 0 },	/* ½ */
 { ALPHA_CHAR, 0 },	/* ¾ */	    { ALPHA_CHAR, 0 },	/* ¿ */
 { ALPHA_CHAR, 0 },	/* À */	    { ALPHA_CHAR, 0 },	/* Á */
 { ALPHA_CHAR, 0 },	/* Â */	    { ALPHA_CHAR, 0 },	/* Ã */
 { ALPHA_CHAR, 0 },	/* Ä */	    { ALPHA_CHAR, 0 },	/* Å */
 { ALPHA_CHAR, 0 },	/* Æ */	    { ALPHA_CHAR, 0 },	/* Ç */
 { ALPHA_CHAR, 0 },	/* È */	    { ALPHA_CHAR, 0 },	/* É */
 { ALPHA_CHAR, 0 },	/* Ê */	    { ALPHA_CHAR, 0 },	/* Ë */
 { ALPHA_CHAR, 0 },	/* Ì */	    { ALPHA_CHAR, 0 },	/* Í */
 { ALPHA_CHAR, 0 },	/* Î */	    { ALPHA_CHAR, 0 },	/* Ï */
 { ALPHA_CHAR, 0 },	/* Ð */	    { ALPHA_CHAR, 0 },	/* Ñ */
 { ALPHA_CHAR, 0 },	/* Ò */	    { ALPHA_CHAR, 0 },	/* Ó */
 { ALPHA_CHAR, 0 },	/* Ô */	    { ALPHA_CHAR, 0 },	/* Õ */
 { ALPHA_CHAR, 0 },	/* Ö */	    { ALPHA_CHAR, 0 },	/* × */
 { ALPHA_CHAR, 0 },	/* Ø */	    { ALPHA_CHAR, 0 },	/* Ù */
 { ALPHA_CHAR, 0 },	/* Ú */	    { ALPHA_CHAR, 0 },	/* Û */
 { ALPHA_CHAR, 0 },	/* Ü */	    { ALPHA_CHAR, 0 },	/* Ý */
 { ALPHA_CHAR, 0 },	/* Þ */	    { ALPHA_CHAR, 0 },	/* ß */
 { ALPHA_CHAR, 0 },	/* à */	    { ALPHA_CHAR, 0 },	/* á */
 { ALPHA_CHAR, 0 },	/* â */	    { ALPHA_CHAR, 0 },	/* ã */
 { ALPHA_CHAR, 0 },	/* ä */	    { ALPHA_CHAR, 0 },	/* å */
 { ALPHA_CHAR, 0 },	/* æ */	    { ALPHA_CHAR, 0 },	/* ç */
 { ALPHA_CHAR, 0 },	/* è */	    { ALPHA_CHAR, 0 },	/* é */
 { ALPHA_CHAR, 0 },	/* ê */	    { ALPHA_CHAR, 0 },	/* ë */
 { ALPHA_CHAR, 0 },	/* ì */	    { ALPHA_CHAR, 0 },	/* í */
 { ALPHA_CHAR, 0 },	/* î */	    { ALPHA_CHAR, 0 },	/* ï */
 { ALPHA_CHAR, 0 },	/* ð */	    { ALPHA_CHAR, 0 },	/* ñ */
 { ALPHA_CHAR, 0 },	/* ò */	    { ALPHA_CHAR, 0 },	/* ó */
 { ALPHA_CHAR, 0 },	/* ô */	    { ALPHA_CHAR, 0 },	/* õ */
 { ALPHA_CHAR, 0 },	/* ö */	    { ALPHA_CHAR, 0 },	/* ÷ */
 { ALPHA_CHAR, 0 },	/* ø */	    { ALPHA_CHAR, 0 },	/* ù */
 { ALPHA_CHAR, 0 },	/* ú */	    { ALPHA_CHAR, 0 },	/* û */
 { ALPHA_CHAR, 0 },	/* ü */	    { ALPHA_CHAR, 0 },	/* ý */
 { ALPHA_CHAR, 0 },	/* þ */	    { ALPHA_CHAR, 0 },	/* ÿ */
};

int _pSLcheck_identifier_syntax (SLCONST char *name)
{
   unsigned char *p;
   
   p = (unsigned char *) name;
   if (ALPHA_CHAR == Char_Type_Table[*p][0]) while (1)
     {
	unsigned ch;
	unsigned char type;

	ch = *++p;

	type = Char_Type_Table [ch][0];
	if ((type != ALPHA_CHAR) && (type != DIGIT_CHAR))
	  {
	     if (ch == 0)
	       return 0;
	     break;
	  }
     }
   
   _pSLang_verror (SL_SYNTAX_ERROR, 
		 "Identifier or structure field name '%s' contains an illegal character", name);
   return -1;
}

static unsigned char prep_get_char (void)
{
   register unsigned char ch;

   if (0 != (ch = *Input_Line_Pointer++))
     return ch;

   Input_Line_Pointer--;
   return 0;
}

static void unget_prep_char (unsigned char ch)
{
   if ((Input_Line_Pointer != Input_Line)
       && (ch != 0))
     Input_Line_Pointer--;
   /* *Input_Line_Pointer = ch; -- Do not modify the Input_Line */
}

#include "keywhash.c"

static int get_ident_token (_pSLang_Token_Type *tok, unsigned char *s, unsigned int len)
{
   unsigned char ch;
   unsigned char type;
   Keyword_Table_Type *table;

   while (1)
     {
	ch = prep_get_char ();
	type = CHAR_CLASS (ch);
	if ((type != ALPHA_CHAR) && (type != DIGIT_CHAR))
	  {
	     unget_prep_char (ch);
	     break;
	  }
	if (len == (MAX_TOKEN_LEN - 1))
	  {
	     _pSLparse_error (SL_BUILTIN_LIMIT_EXCEEDED, "Identifier length exceeded maximum supported value", NULL, 0);
	     return tok->type = EOF_TOKEN;
	  }
	s [len++] = ch;
     }

   s[len] = 0;

   /* check if keyword */
   table = is_keyword ((char *) s, len);
   if (table != NULL)
     {
	tok->v.s_val = table->name;
	return (tok->type = table->type);
     }

   tok->v.s_val = _pSLstring_make_hashed_string ((char *)s, len, &tok->hash);
   tok->free_sval_flag = 1;
   return (tok->type = IDENT_TOKEN);
}

static int get_number_token (_pSLang_Token_Type *tok, unsigned char *s, unsigned int len)
{
   unsigned char ch;
   unsigned char type;

   /* Look for pattern  [0-9.xX]*([eE][-+]?[digits])?[ijfhul]? */
   while (1)
     {
	ch = prep_get_char ();

	type = CHAR_CLASS (ch);
	if ((type != DIGIT_CHAR) && (type != DOT_CHAR))
	  {
	     if ((ch != 'x') && (ch != 'X'))
	       break;
	     /* It must be hex */
	     do
	       {
		  if (len == (MAX_TOKEN_LEN - 1))
		    goto too_long_return_error;

		  s[len++] = ch;
		  ch = prep_get_char ();
		  type = CHAR_CLASS (ch);
	       }
	     while ((type == DIGIT_CHAR) || (type == ALPHA_CHAR));
	     break;
	  }
	if (len == (MAX_TOKEN_LEN - 1))
	  goto too_long_return_error;
	s [len++] = ch;
     }

   /* At this point, type and ch are synchronized */

   if ((ch == 'e') || (ch == 'E'))
     {
	if (len == (MAX_TOKEN_LEN - 1))
	  goto too_long_return_error;
	s[len++] = ch;
	ch = prep_get_char ();
	if ((ch == '+') || (ch == '-'))
	  {
	     if (len == (MAX_TOKEN_LEN - 1))
	       goto too_long_return_error;
	     s[len++] = ch;
	     ch = prep_get_char ();
	  }

	while (DIGIT_CHAR == (type = CHAR_CLASS(ch)))
	  {
	     if (len == (MAX_TOKEN_LEN - 1))
	       goto too_long_return_error;
	     s[len++] = ch;
	     ch = prep_get_char ();
	  }
     }

   while (ALPHA_CHAR == type)
     {
	if (len == (MAX_TOKEN_LEN - 1))
	  goto too_long_return_error;
	s[len++] = ch;
	ch = prep_get_char ();
	type = CHAR_CLASS(ch);
     }

   unget_prep_char (ch);
   s[len] = 0;

   switch (SLang_guess_type ((char *) s))
     {
      default:
	tok->v.s_val = (char *) s;
	_pSLparse_error (SL_TYPE_MISMATCH, "Not a number", tok, 0);
	return (tok->type = EOF_TOKEN);

#if SLANG_HAS_FLOAT
      case SLANG_FLOAT_TYPE:
	tok->v.s_val = _pSLstring_make_hashed_string ((char *)s, len, &tok->hash);
	tok->free_sval_flag = 1;
	return (tok->type = FLOAT_TOKEN);

      case SLANG_DOUBLE_TYPE:
	tok->v.s_val = _pSLstring_make_hashed_string ((char *)s, len, &tok->hash);
	tok->free_sval_flag = 1;
	return (tok->type = DOUBLE_TOKEN);
#endif
#if SLANG_HAS_COMPLEX
      case SLANG_COMPLEX_TYPE:
	tok->v.s_val = _pSLstring_make_hashed_string ((char *)s, len, &tok->hash);
	tok->free_sval_flag = 1;
	return (tok->type = COMPLEX_TOKEN);
#endif
      case SLANG_CHAR_TYPE:
	tok->v.long_val = (char)SLatol (s);
	return tok->type = CHAR_TOKEN;
      case SLANG_UCHAR_TYPE:
	tok->v.long_val = (unsigned char)SLatol (s);
	return tok->type = UCHAR_TOKEN;
      case SLANG_SHORT_TYPE:
	tok->v.long_val = (short)SLatol (s);
	return tok->type = SHORT_TOKEN;
      case SLANG_USHORT_TYPE:
	tok->v.long_val = (unsigned short)SLatoul (s);
	return tok->type = USHORT_TOKEN;
      case SLANG_INT_TYPE:
	tok->v.long_val = (int)SLatol (s);
	return tok->type = INT_TOKEN;
      case SLANG_UINT_TYPE:
	tok->v.long_val = (unsigned int)SLatoul (s);
	return tok->type = UINT_TOKEN;
      case SLANG_LONG_TYPE:
	tok->v.long_val = SLatol (s);
	return tok->type = LONG_TOKEN;
      case SLANG_ULONG_TYPE:
	tok->v.long_val = SLatoul (s);
	return tok->type = ULONG_TOKEN;
#ifdef HAVE_LONG_LONG
      case SLANG_LLONG_TYPE:
	tok->v.llong_val = SLatoll (s);
	return tok->type = LLONG_TOKEN;
      case SLANG_ULLONG_TYPE:
	tok->v.ullong_val = SLatoull (s);
	return tok->type = ULLONG_TOKEN;
#endif
     }

   too_long_return_error:
   _pSLparse_error (SL_BUILTIN_LIMIT_EXCEEDED, "Number too long for buffer", NULL, 0);
   return (tok->type = EOF_TOKEN);
}

static int get_op_token (_pSLang_Token_Type *tok, char ch)
{
   unsigned int offset;
   char second_char;
   unsigned char type;
   SLCONST char *name;

   /* operators are: + - / * ++ -- += -= = == != > < >= <= | etc..
    * These lex to the longest valid operator token.
    */

   offset = CHAR_DATA((unsigned char) ch);
   if (0 == Operators [offset][1])
     {
	name = Operators [offset];
	type = name [3];
     }
   else
     {
	type = EOF_TOKEN;
	name = NULL;
     }

   second_char = prep_get_char ();
   do
     {
	if (second_char == Operators[offset][1])
	  {
	     name = Operators [offset];
	     type = name [3];
	     break;
	  }
	offset++;
     }
   while (ch == Operators[offset][0]);

   tok->type = type;

   if (type == EOF_TOKEN)
     {
	_pSLparse_error (SL_NOT_IMPLEMENTED, "Operator not supported", NULL, 0);
	return type;
     }

   tok->v.s_val = (char *)name;

   if (name[1] == 0)
     unget_prep_char (second_char);

   return type;
}


/* s and t may point to the same buffer --- even for unicode.  This
 * is because a wchar is denoted by (greater than) 4 characters \x{...}, which
 * will expand to at most 6 bytes when UTF-8 encoded.  That is:
 * \x{F} expands to 1 byte
 * \x{FF} expands to 2 bytes
 * \x{FFF} expands to 3 bytes
 * \x{FFFF} expands to 3 bytes
 * \x{FFFFF} expands to 4 bytes
 * \x{FFFFFF} expands to 5 bytes
 * \x{7FFFFFF} expands to 6 bytes
 * 
 * Also, consider octal, decimal, and hex forms:
 * 
 *    \200   (0x80)
 *    \d128
 *    \x80
 * 
 * In all these cases, the escaped form uses 4 bytes.  Hence, these forms also
 * may be converted to UTF-8.
 */
/* If this returns non-zero, then it is a binary string */
static int expand_escaped_string (register char *s,
				  register char *t, register char *tmax,
				  unsigned int *lenp, int is_binary)
{
   char *s0;
   char ch;
#if 0
   int utf8_encode;

   utf8_encode = (is_binary == 0) && _pSLinterp_UTF8_Mode;
#endif
   s0 = s;
   while (t < tmax)
     {
	int isunicode;
	SLwchar_Type wch;
	char *s1;
	ch = *t++;
	
	if (ch != '\\')
	  {
	     if (ch == 0) is_binary = 1;
	     *s++ = ch;
	     continue;
	  }
	  
	if (NULL == (t = _pSLexpand_escaped_char (t, &wch, &isunicode)))
	  {
	     is_binary = -1;
	     break;
	  }
	if ((isunicode == 0)
#if 0
	    && ((wch < 127)
		|| (utf8_encode == 0))
#endif
	    )
	  {
	     if (wch == 0)
	       is_binary = 1;
	     
	     *s++ = (char) wch;
	     continue;
	  }
#if 0	
	if (isunicode && (utf8_encode == 0))
	  {
	     _pSLang_verror (SL_NOT_IMPLEMENTED, "Unicode is not supported by this application");
	     is_binary = -1;
	     break;
	  }
#endif
	/* Escaped representation is always greater than encoded form.
	 * So, 6 below is ok (although ugly).
	 */
	s1 = (char *) SLutf8_encode (wch, (SLuchar_Type *)s, 6);
	if (s1 == NULL)
	  {
	     _pSLang_verror (SL_INVALID_UTF8, "Unable to UTF-8 encode 0x%lX\n", (unsigned long)wch);
	     is_binary = -1;
	     break;
	  }
	s = s1;
     }
   *s = 0;

   *lenp = (unsigned char) (s - s0);
   return is_binary;
}
   
static int get_string_token (_pSLang_Token_Type *tok, unsigned char quote_char,
			     unsigned char *s)
{
   SLwchar_Type wch;
   unsigned char ch;
   unsigned int len = 0;
   int has_quote = 0;
#if 0
   int is_unicode = 0;
#endif
   while (1)
     {
	ch = prep_get_char ();
	if (ch == 0)
	  {
	     _pSLparse_error(SL_SYNTAX_ERROR, "Expecting quote-character", NULL, 0);
	     return (tok->type = EOF_TOKEN);
	  }
	if (ch == quote_char) break;

	s[len++] = ch;

	if (len == (MAX_TOKEN_LEN - 1))
	  {
	     _pSLparse_error (SL_BUILTIN_LIMIT_EXCEEDED, "Literal string exceeds the maximum allowable size--- use concatenation", NULL, 0);
	     return (tok->type = EOF_TOKEN);
	  }

	if (ch == '\\')
	  {
	     has_quote = 1;
	     ch = prep_get_char ();
	     s[len++] = ch;
	  }
#if 0
	else if (ch & 0x80)	       /* could be unicode */
	  is_unicode = 1;
#endif
     }

   s[len] = 0;

   if ('"' == quote_char)
     {
#define STRING_SUFFIX_B		1
#define STRING_SUFFIX_Q		2
#define STRING_SUFFIX_R		4
#define STRING_SUFFIX_S		8	
	int suffix = 0;
	int is_binary = 0;

	while (1)
	  {
	     ch = prep_get_char ();
	     if (ch == 'B')
	       {
		  is_binary = 1;
		  suffix |= STRING_SUFFIX_B;
		  continue;
	       }
	     if (ch == 'R')
	       {
		  suffix |= STRING_SUFFIX_R;
		  has_quote = 0;
		  continue;
	       }
	     if (ch == 'Q')
	       {
		  suffix |= STRING_SUFFIX_Q;
		  continue;
	       }
	     if (ch == '$')
	       {
		  suffix |= STRING_SUFFIX_S;
		  continue;
	       }
	     unget_prep_char (ch);
	     break;
	  }
	
	if ((suffix & STRING_SUFFIX_R) && (suffix & STRING_SUFFIX_Q))
	  {
	     _pSLparse_error (SL_SYNTAX_ERROR, "Conflicting suffix for string literal", NULL, 0);
	     return (tok->type = EOF_TOKEN);
	  }

	if (has_quote)
	  is_binary = expand_escaped_string ((char *) s, (char *)s, (char *)s + len, &len, is_binary);

	if (is_binary && (suffix & STRING_SUFFIX_S))
	  {
	     _pSLparse_error (SL_SYNTAX_ERROR, "A binary string cannot have the $ suffix", NULL, 0);
	     return tok->type = EOF_TOKEN;
	  }

	tok->free_sval_flag = 1;
	if (is_binary)
	  {
	     tok->v.b_val = SLbstring_create (s, len);
	     return tok->type = BSTRING_TOKEN;
	  }
	else
	  {
	     tok->v.s_val = _pSLstring_make_hashed_string ((char *)s,
							  len,
							  &tok->hash);
	     tok->free_sval_flag = 1;
	     if (suffix & STRING_SUFFIX_S)
	       return tok->type = STRING_DOLLAR_TOKEN;
	     return (tok->type = STRING_TOKEN);
	  }
     }

   /* else single character */

   if (has_quote)
     {
	if ((s[0] != '\\')
	    || (NULL == (s = (unsigned char *)_pSLexpand_escaped_char ((char *)s+1, &wch, NULL)))
	    || (*s != 0))
	  {
	     _pSLparse_error (SL_SYNTAX_ERROR, "Unable to parse character", NULL, 0);
	     return (tok->type = EOF_TOKEN);
	  }
     }
   else if (len == 1)
     wch = s[0];
   else /* Assume unicode */
     {
	unsigned char *ss = SLutf8_decode (s, s+len, &wch, NULL);
	if ((ss == NULL) || (*ss != 0))
	  {
	     _pSLparse_error(SL_SYNTAX_ERROR, "Single char expected", NULL, 0);
	     return (tok->type = EOF_TOKEN);
	  }
     }
   tok->v.long_val = wch;

   if (wch > 256)
     return tok->type = ULONG_TOKEN;

   return (tok->type = UCHAR_TOKEN);
}

static int extract_token (_pSLang_Token_Type *tok, unsigned char ch, unsigned char t)
{
   unsigned char s [MAX_TOKEN_LEN];
   unsigned int slen;

   s[0] = (char) ch;
   slen = 1;

   switch (t)
     {
      case ALPHA_CHAR:
	return get_ident_token (tok, s, slen);

      case OP_CHAR:
	return get_op_token (tok, ch);

      case DIGIT_CHAR:
	return get_number_token (tok, s, slen);

      case EXCL_CHAR:
	ch = prep_get_char ();
	s [slen++] = ch;
	t = CHAR_CLASS(ch);
	if (t == ALPHA_CHAR) return get_ident_token (tok, s, slen);
	if (t == OP_CHAR)
	  {
	     unget_prep_char (ch);
	     return get_op_token (tok, '!');
	  }
	_pSLparse_error(SL_SYNTAX_ERROR, "Misplaced !", NULL, 0);
	return -1;

      case DOT_CHAR:
	ch = prep_get_char ();
	if (DIGIT_CHAR == CHAR_CLASS(ch))
	  {
	     s [slen++] = ch;
	     return get_number_token (tok, s, slen);
	  }
	unget_prep_char (ch);
	return (tok->type = DOT_TOKEN);

      case SEP_CHAR:
	return (tok->type = CHAR_DATA(ch));

      case DQUOTE_CHAR:
      case QUOTE_CHAR:
	return get_string_token (tok, ch, s);

      default:
	_pSLparse_error(SL_SYNTAX_ERROR, "Invalid character", NULL, 0);
	return (tok->type = EOF_TOKEN);
     }
}

int _pSLget_rpn_token (_pSLang_Token_Type *tok)
{
   unsigned char ch;

   tok->v.s_val = "??";
   while ((ch = *Input_Line_Pointer) != 0)
     {
	unsigned char t;

	Input_Line_Pointer++;
	if (WHITE_CHAR == (t = CHAR_CLASS(ch)))
	  continue;

	if (NL_CHAR == t)
	  break;

	return extract_token (tok, ch, t);
     }
   Input_Line_Pointer = Empty_Line;
   return EOF_TOKEN;
}

int _pSLget_token (_pSLang_Token_Type *tok)
{
   unsigned char ch;
   unsigned char t;

   tok->num_refs = 1;
   tok->free_sval_flag = 0;
   tok->v.s_val = "??";
#if SLANG_HAS_DEBUG_CODE
   tok->line_number = LLT->line_num;
#endif
   if (_pSLang_Error || (Input_Line == NULL))
     return (tok->type = EOF_TOKEN);

   while (1)
     {
	ch = *Input_Line_Pointer++;
	if (WHITE_CHAR == (t = CHAR_CLASS (ch)))
	  continue;

	if (t != NL_CHAR)
	  return extract_token (tok, ch, t);

	do
	  {
	     LLT->line_num++;
#if SLANG_HAS_DEBUG_CODE
	     tok->line_number++;
#endif
	     Input_Line = LLT->read(LLT);
	     if ((NULL == Input_Line) || _pSLang_Error)
	       {
		  Input_Line_Pointer = Input_Line = NULL;
		  return (tok->type = EOF_TOKEN);
	       }
	  }
	while (0 == SLprep_line_ok(Input_Line, This_SLpp));

	Input_Line_Pointer = Input_Line;
	if (*Input_Line_Pointer == '.')
	  {
	     Input_Line_Pointer++;
	     return tok->type = RPN_TOKEN;
	  }
     }
}

static int prep_exists_function (SLprep_Type *pt, SLFUTURE_CONST char *line)
{
   char buf[MAX_FILE_LINE_LEN], *b, *bmax;
   unsigned char ch;
   unsigned char comment;

   (void) pt;
   bmax = buf + (sizeof (buf) - 1);
   
   comment = (unsigned char)'%';
   while (1)
     {
	/* skip whitespace */
	while ((ch = (unsigned char) *line),
	       ch && (ch != '\n') && (ch <= ' '))
	  line++;

	if ((ch <= '\n')
	    || (ch == comment)) break;

	b = buf;
	while ((ch = (unsigned char) *line) > ' ')
	  {
	     if (b < bmax) *b++ = (char) ch;
	     line++;
	  }
	*b = 0;

	if (SLang_is_defined (buf))
	  return 1;
     }

   return 0;
}

static int prep_eval_expr (SLprep_Type *pt, SLFUTURE_CONST char *expr)
{
   int ret;
   SLCONST char *end;
   void (*compile)(_pSLang_Token_Type *);
   char *expr1;

   (void) pt;
   end = strchr (expr, '\n');
   if (end == NULL)
     end = expr + strlen (expr);
   expr1 = SLmake_nstring (expr, (unsigned int) (end - expr));
   if (expr1 == NULL)
     return -1;

   compile = _pSLcompile_ptr;
   _pSLcompile_ptr = _pSLcompile;
   if ((0 != SLang_load_string (expr1))
       || (-1 == SLang_pop_integer (&ret)))
     ret = -1;
   else
     ret = (ret != 0);
   _pSLcompile_ptr = compile;

   SLfree (expr1);
   return ret;
}


int SLang_load_object (SLang_Load_Type *x)
{
   SLprep_Type *this_pp;
   SLprep_Type *save_this_pp;
   SLang_Load_Type *save_llt;
   char *save_input_line, *save_input_line_ptr;
#if SLANG_HAS_DEBUG_CODE
   /* int save_compile_line_num_info; */
#endif
#if SLANG_HAS_BOSEOS
   int save_compile_boseos;
   int save_compile_bofeof;
#endif
   int save_auto_declare_variables;

   if (NULL == (this_pp = SLprep_new ()))
     return -1;
   (void) SLprep_set_exists_hook (this_pp, prep_exists_function);
   (void) SLprep_set_eval_hook (this_pp, prep_eval_expr);

   if (-1 == _pSLcompile_push_context (x))
     {
	SLprep_delete (this_pp);
	return -1;
     }

#if SLANG_HAS_DEBUG_CODE
   /* save_compile_line_num_info = _pSLang_Compile_Line_Num_Info; */
#endif
#if SLANG_HAS_BOSEOS
   save_compile_boseos = _pSLang_Compile_BOSEOS;
   save_compile_bofeof = _pSLang_Compile_BOFEOF;
#endif
   save_this_pp = This_SLpp;
   save_input_line = Input_Line;
   save_input_line_ptr = Input_Line_Pointer;
   save_llt = LLT;
   save_auto_declare_variables = _pSLang_Auto_Declare_Globals;

   This_SLpp = this_pp;
   Input_Line_Pointer = Input_Line = Empty_Line;
   LLT = x;

   /* x->line_num = 0; */  /* already set to 0 when allocated. */
   x->parse_level = 0;
   _pSLang_Auto_Declare_Globals = x->auto_declare_globals;

#if SLANG_HAS_DEBUG_CODE
   /* _pSLang_Compile_Line_Num_Info = Default_Compile_Line_Num_Info; */
#endif
#if SLANG_HAS_BOSEOS
#if 0
   /* Instead of setting this variable to 0, let it keep its current value.
    * Suppose that the following evalfiles take place:
    *  
    *  A -> B1  --> C1  --> D1
    *    -> B2  --> C1  --> D2
    * 
    * and that B1 sets _boseos_info to 1.  Then C1 and D1 will get this value
    * but B2 will not, since it will get rest to 0 when the routine has finished
    * loading B1.
    */
     {
	char *env = getenv ("SLANG_BOSEOS");
	if (env != NULL)
	  _pSLang_Compile_BOSEOS = atoi (env);
	else
	  _pSLang_Compile_BOSEOS = 0;
     }
#endif
#endif
   _pSLparse_start (x);
   if (_pSLang_Error)
     {
       if (_pSLang_Error != SL_Usage_Error)
	  (void) _pSLerr_set_line_info (x->name, x->line_num, NULL);
	/* Doing this resets the state of the line_info object */
	(void) _pSLerr_set_line_info (x->name, x->line_num, "");
     }

   _pSLang_Auto_Declare_Globals = save_auto_declare_variables;

   (void) _pSLcompile_pop_context ();

   Input_Line = save_input_line;
   Input_Line_Pointer = save_input_line_ptr;
   LLT = save_llt;
   SLprep_delete (this_pp);
   This_SLpp = save_this_pp;

#if SLANG_HAS_DEBUG_CODE
   /* _pSLang_Compile_Line_Num_Info = save_compile_line_num_info; */
#endif
#if SLANG_HAS_BOSEOS
   _pSLang_Compile_BOSEOS = save_compile_boseos;
   _pSLang_Compile_BOFEOF = save_compile_bofeof;
#endif
   if (_pSLang_Error) return -1;
   return 0;
}

SLang_Load_Type *SLns_allocate_load_type (SLFUTURE_CONST char *name, SLFUTURE_CONST char *namespace_name)
{
   SLang_Load_Type *x;

   if (NULL == (x = (SLang_Load_Type *)SLmalloc (sizeof (SLang_Load_Type))))
     return NULL;
   memset ((char *) x, 0, sizeof (SLang_Load_Type));

   if (name == NULL) name = "";

   if (NULL == (x->name = SLang_create_slstring (name)))
     {
	SLfree ((char *) x);
	return NULL;
     }
   
   if (namespace_name != NULL)
     {
	if (NULL == (x->namespace_name = SLang_create_slstring (namespace_name)))
	  {
	     SLang_free_slstring ((char *) x->name);
	     SLfree ((char *) x);
	     return NULL;
	  }
     }

   return x;
}

SLang_Load_Type *SLallocate_load_type (SLFUTURE_CONST char *name)
{
   return SLns_allocate_load_type (name, NULL);
}

void SLdeallocate_load_type (SLang_Load_Type *x)
{
   if (x != NULL)
     {
	SLang_free_slstring ((char *) x->name);
	SLang_free_slstring ((char *) x->namespace_name);
	SLfree ((char *) x);
     }
}

typedef struct
{
   SLCONST char *string;
   SLCONST char *ptr;
}
String_Client_Data_Type;

static char *read_from_string (SLang_Load_Type *x)
{
   String_Client_Data_Type *data;
   SLCONST char *s, *s1;
   char ch;

   data = (String_Client_Data_Type *)x->client_data;
   s1 = s = data->ptr;

   if (*s == 0)
     return NULL;

   while ((ch = *s) != 0)
     {
	s++;
	if (ch == '\n')
	  break;
     }

   data->ptr = s;
   return (char *) s1;
}

int SLang_load_string (SLFUTURE_CONST char *string)
{
   return SLns_load_string (string, NULL);
}

int SLns_load_string (SLFUTURE_CONST char *string, SLFUTURE_CONST char *ns_name)
{
   SLang_Load_Type *x;
   String_Client_Data_Type data;
   int ret;

   if (string == NULL)
     return -1;

   /* Grab a private copy in case loading modifies string */
   if (NULL == (string = SLang_create_slstring (string)))
     return -1;

   /* To avoid creating a static data space for every string loaded,
    * all string objects will be regarded as identical.  So, identify
    * all of them by ***string***
    */
   if (NULL == (x = SLns_allocate_load_type ("***string***", ns_name)))
     {
	SLang_free_slstring ((char *) string);
	return -1;
     }

   x->client_data = (VOID_STAR) &data;
   x->read = read_from_string;

   data.ptr = data.string = string;
   if ((-1 == (ret = SLang_load_object (x)))
       && (SLang_Traceback & SL_TB_FULL))
     _pSLerr_traceback_msg ("Traceback: called from eval: %s\n", string);

   SLang_free_slstring ((char *)string);
   SLdeallocate_load_type (x);
   return ret;
}

typedef struct
{
   char *buf;
   FILE *fp;
}
File_Client_Data_Type;

char *SLang_User_Prompt;
static char *read_from_file (SLang_Load_Type *x)
{
   FILE *fp;
   File_Client_Data_Type *c;

   c = (File_Client_Data_Type *)x->client_data;
   fp = c->fp;

   if ((fp == stdin) && (SLang_User_Prompt != NULL))
     {
	fputs (SLang_User_Prompt, stdout);
	fflush (stdout);
     }

   return fgets (c->buf, MAX_FILE_LINE_LEN, c->fp);
}

int _pSLang_Load_File_Verbose = 0;
int SLang_load_file_verbose (int v)
{
   int v1 = _pSLang_Load_File_Verbose;
   _pSLang_Load_File_Verbose = v;
   return v1;
}

/* Note that file could be freed from Slang during run of this routine
 * so get it and store it !! (e.g., autoloading)
 */
int (*SLang_Load_File_Hook) (SLFUTURE_CONST char *);
int (*SLns_Load_File_Hook) (SLFUTURE_CONST char *, SLFUTURE_CONST char *);
int SLang_load_file (SLFUTURE_CONST char *f)
{
   return SLns_load_file (f, NULL);
}

int SLns_load_file (SLFUTURE_CONST char *f, SLFUTURE_CONST char *ns_name)
{
   File_Client_Data_Type client_data;
   SLang_Load_Type *x;
   char *name, *buf;
   FILE *fp;

   if ((ns_name == NULL) && (NULL != SLang_Load_File_Hook))
     return (*SLang_Load_File_Hook) (f);

   if (SLns_Load_File_Hook != NULL)
     return (*SLns_Load_File_Hook) (f, ns_name);

   if (f == NULL) 
     name = SLang_create_slstring ("<stdin>");
   else
     name = _pSLpath_find_file (f, 1);
	
   if (name == NULL)
     return -1;

   if (NULL == (x = SLns_allocate_load_type (name, ns_name)))
     {
	SLang_free_slstring (name);
	return -1;
     }

   buf = NULL;

   if (f != NULL)
     {
	fp = fopen (name, "r");
	if (_pSLang_Load_File_Verbose & SLANG_LOAD_FILE_VERBOSE)
	  {
	     if ((ns_name != NULL) 
		 && (*ns_name != 0) && (0 != strcmp (ns_name, "Global")))
	       SLang_vmessage ("Loading %s [ns:%s]", name, ns_name);
	     else
	       SLang_vmessage ("Loading %s", name);
	  }
     }
   else
     fp = stdin;

   if (fp == NULL)
     _pSLang_verror (SL_OBJ_NOPEN, "Unable to open %s", name);
   else if (NULL != (buf = SLmalloc (MAX_FILE_LINE_LEN + 1)))
     {
	client_data.fp = fp;
	client_data.buf = buf;
	x->client_data = (VOID_STAR) &client_data;
	x->read = read_from_file;

	(void) SLang_load_object (x);
     }

   if ((fp != NULL) && (fp != stdin))
     fclose (fp);

   SLfree (buf);
   SLang_free_slstring (name);
   SLdeallocate_load_type (x);

   if (_pSLang_Error)
     return -1;

   return 0;
}

static char *check_byte_compiled_token (char *buf)
{
   unsigned int len_lo, len_hi, len;

   len_lo = (unsigned char) *Input_Line_Pointer++;
   if ((len_lo < 32)
       || ((len_hi = (unsigned char)*Input_Line_Pointer++) < 32)
       || ((len = (len_lo - 32) | ((len_hi - 32) << 7)) >= MAX_TOKEN_LEN))
     {
	_pSLang_verror (SL_INVALID_DATA_ERROR, "Byte compiled file appears corrupt");
	return NULL;
     }

   SLMEMCPY (buf, Input_Line_Pointer, len);
   buf += len;
   Input_Line_Pointer += len;
   *buf = 0;
   return buf;
}

void _pSLcompile_byte_compiled (void)
{
   unsigned char type;
   _pSLang_Token_Type tok;
   char buf[MAX_TOKEN_LEN];
   char *ebuf;
   unsigned int len;

   memset ((char *) &tok, 0, sizeof (_pSLang_Token_Type));

   while (_pSLang_Error == 0)
     {
	top_of_switch:
	type = (unsigned char) *Input_Line_Pointer++;
	switch (type)
	  {
	   case '\n':
	   case 0:
	     if (NULL == (Input_Line = LLT->read(LLT)))
	       {
		  Input_Line_Pointer = Input_Line = NULL;
		  return;
	       }
	     Input_Line_Pointer = Input_Line;
	     goto top_of_switch;

	   case LINE_NUM_TOKEN:
	   case CHAR_TOKEN:
	   case UCHAR_TOKEN:
	   case SHORT_TOKEN:
	   case USHORT_TOKEN:
	   case INT_TOKEN:
	   case UINT_TOKEN:
	   case LONG_TOKEN:
	   case ULONG_TOKEN:
	     if (NULL == check_byte_compiled_token (buf))
	       return;
	     tok.v.long_val = atol (buf);
	     break;
#ifdef HAVE_LONG_LONG
	   case LLONG_TOKEN:
	   case ULLONG_TOKEN:
	     if (NULL == check_byte_compiled_token (buf))
	       return;
	     tok.v.llong_val = SLatoll ((unsigned char *)buf);
	     break;
#endif
	   case COMPLEX_TOKEN:
	   case FLOAT_TOKEN:
	   case DOUBLE_TOKEN:
	     if (NULL == check_byte_compiled_token (buf))
	       return;
	     tok.v.s_val = buf;
	     break;

	   case ESC_STRING_DOLLAR_TOKEN:
	     if (NULL == (ebuf = check_byte_compiled_token (buf)))
	       return;
	     tok.v.s_val = buf;
	     (void) expand_escaped_string (buf, buf, ebuf, &len, 0);
	     tok.hash = _pSLstring_hash ((unsigned char *)buf, (unsigned char *)buf + len);
	     type = STRING_DOLLAR_TOKEN;
	     break;

	   case ESC_STRING_TOKEN:
	     if (NULL == (ebuf = check_byte_compiled_token (buf)))
	       return;
	     tok.v.s_val = buf;
	     (void) expand_escaped_string (buf, buf, ebuf, &len, 0);
	     tok.hash = _pSLstring_hash ((unsigned char *)buf, (unsigned char *)buf + len);
	     type = STRING_TOKEN;
	     break;

	   case ESC_BSTRING_TOKEN:
	     if (NULL == (ebuf = check_byte_compiled_token (buf)))
	       return;
	     tok.v.s_val = buf;
	     (void) expand_escaped_string (buf, buf, ebuf, &len, 1);
	     tok.hash = len;
	     type = _BSTRING_TOKEN;
	     break;

	   case TMP_TOKEN:
	   case DEFINE_TOKEN:
	   case DEFINE_STATIC_TOKEN:
	   case DEFINE_PRIVATE_TOKEN:
	   case DEFINE_PUBLIC_TOKEN:
	   case DOT_TOKEN:
	   case DOT_METHOD_CALL_TOKEN:
	   case STRING_DOLLAR_TOKEN:
	   case STRING_TOKEN:
	   case IDENT_TOKEN:
	   case _REF_TOKEN:
	   /* case _DEREF_ASSIGN_TOKEN: */
	   case _SCALAR_ASSIGN_TOKEN:
	   case _SCALAR_PLUSEQS_TOKEN:
	   case _SCALAR_MINUSEQS_TOKEN:
	   case _SCALAR_TIMESEQS_TOKEN:
	   case _SCALAR_DIVEQS_TOKEN:
	   case _SCALAR_BOREQS_TOKEN:
	   case _SCALAR_BANDEQS_TOKEN:
	   case _SCALAR_PLUSPLUS_TOKEN:
	   case _SCALAR_POST_PLUSPLUS_TOKEN:
	   case _SCALAR_MINUSMINUS_TOKEN:
	   case _SCALAR_POST_MINUSMINUS_TOKEN:
	   case _STRUCT_ASSIGN_TOKEN:
	   case _STRUCT_PLUSEQS_TOKEN:
	   case _STRUCT_MINUSEQS_TOKEN:
	   case _STRUCT_TIMESEQS_TOKEN:
	   case _STRUCT_DIVEQS_TOKEN:
	   case _STRUCT_BOREQS_TOKEN:
	   case _STRUCT_BANDEQS_TOKEN:
	   case _STRUCT_POST_MINUSMINUS_TOKEN:
	   case _STRUCT_MINUSMINUS_TOKEN:
	   case _STRUCT_POST_PLUSPLUS_TOKEN:
	   case _STRUCT_PLUSPLUS_TOKEN:
	   case _STRUCT_FIELD_REF_TOKEN:
	     if (NULL == (ebuf = check_byte_compiled_token (buf)))
	       return;
	     tok.v.s_val = buf;
	     tok.hash = _pSLstring_hash ((unsigned char *)buf, (unsigned char *)ebuf);
	     break;

	   default:
	     break;
	  }
	tok.type = type;

	(*_pSLcompile_ptr) (&tok);
     }
}

static int escape_string (unsigned char *s, unsigned char *smax,
			  unsigned char *buf, unsigned char *buf_max,
			  int *is_escaped)
{
   unsigned char ch;

   *is_escaped = 0;
   while (buf < buf_max)
     {
	if (s == smax)
	  {
	     *buf = 0;
	     return 0;
	  }

	ch = *s++;
	switch (ch)
	  {
	   default:
	     *buf++ = ch;
	     break;

	   case 0:
	     *buf++ = '\\';
	     if (buf < buf_max) *buf++ = 'x';
	     if (buf < buf_max) *buf++ = '0';
	     if (buf < buf_max) *buf++ = '0';
	     *is_escaped = 1;
	     break; /* return 0; */

	   case '\n':
	     *buf++ = '\\';
	     if (buf < buf_max) *buf++ = 'n';
	     *is_escaped = 1;
	     break;

	   case '\r':
	     *buf++ = '\\';
	     if (buf < buf_max) *buf++ = 'r';
	     *is_escaped = 1;
	     break;

	   case 0x1A:		       /* ^Z */
	     *buf++ = '\\';
	     if (buf < buf_max) *buf++ = 'x';
	     if (buf < buf_max) *buf++ = '1';
	     if (buf < buf_max) *buf++ = 'A';
	     *is_escaped = 1;
	     break;

	   case '\\':
	     *buf++ = ch;
	     if (buf < buf_max) *buf++ = ch;
	     *is_escaped = 1;
	     break;
	  }
     }
   _pSLparse_error (SL_BUILTIN_LIMIT_EXCEEDED, "String too long to byte-compile", NULL, 0);
   return -1;
}

static FILE *Byte_Compile_Fp;
static unsigned int Byte_Compile_Line_Len;

static int bytecomp_write_data (SLCONST char *buf, unsigned int len)
{
   if ((Byte_Compile_Line_Len + len + 1) >= MAX_FILE_LINE_LEN)
     {
	if (EOF == fputs ("\n", Byte_Compile_Fp))
	  {
	     SLang_set_error (SL_IO_WRITE_ERROR);
	     return -1;
	  }
	Byte_Compile_Line_Len = 0;
     }

   if (EOF == fputs (buf, Byte_Compile_Fp))
     {
	SLang_set_error (SL_IO_WRITE_ERROR);
	return -1;
     }
   Byte_Compile_Line_Len += len;
   return 0;
}

static void byte_compile_token (_pSLang_Token_Type *tok)
{
   unsigned char buf [MAX_TOKEN_LEN + 4], *buf_max;
   unsigned int len;
   char *b3;
   int is_escaped;
   unsigned char *s;

   if (_pSLang_Error) return;

   buf [0] = (unsigned char) tok->type;
   buf [1] = 0;

   buf_max = buf + sizeof(buf);
   b3 = (char *) buf + 3;

   switch (tok->type)
     {
      case BOS_TOKEN:
      case LINE_NUM_TOKEN:
      case CHAR_TOKEN:
      case SHORT_TOKEN:
      case INT_TOKEN:
      case LONG_TOKEN:
	sprintf (b3, "%ld", tok->v.long_val);
	break;

      case UCHAR_TOKEN:
      case USHORT_TOKEN:
      case UINT_TOKEN:
      case ULONG_TOKEN:
	sprintf (b3, "%lu", tok->v.long_val);
	break;

#ifdef HAVE_LONG_LONG
      case LLONG_TOKEN:
	sprintf (b3, "%lld", tok->v.llong_val);
	break;
	
      case ULLONG_TOKEN:
	sprintf (b3, "%llu", tok->v.ullong_val);
	break;
#endif
      case _BSTRING_TOKEN:
	s = (unsigned char *) tok->v.s_val;
	len = (unsigned int) tok->hash;

	if (-1 == escape_string (s, s + len,
				 (unsigned char *)b3, buf_max,
				 &is_escaped))
	    return;

	buf[0] = ESC_BSTRING_TOKEN;
	break;

      case BSTRING_TOKEN:
	if (NULL == (s = SLbstring_get_pointer (tok->v.b_val, &len)))
	  return;

	if (-1 == escape_string (s, s + len,
				 (unsigned char *)b3, buf_max,
				 &is_escaped))
	    return;
	buf[0] = ESC_BSTRING_TOKEN;
	break;

      case STRING_DOLLAR_TOKEN:
      case STRING_TOKEN:
	s = (unsigned char *)tok->v.s_val;

	if (-1 == escape_string (s, s + strlen ((char *)s),
				 (unsigned char *)b3, buf_max,
				 &is_escaped))
	    return;

	if (is_escaped)
	  buf[0] = ((tok->type == STRING_TOKEN) 
		    ? ESC_STRING_TOKEN : ESC_STRING_DOLLAR_TOKEN);
	break;

      /* case _DEREF_ASSIGN_TOKEN: */
	/* a _SCALAR_* token is attached to an identifier. */
      case _SCALAR_ASSIGN_TOKEN:
      case _SCALAR_PLUSEQS_TOKEN:
      case _SCALAR_MINUSEQS_TOKEN:
      case _SCALAR_TIMESEQS_TOKEN:
      case _SCALAR_DIVEQS_TOKEN:
      case _SCALAR_BOREQS_TOKEN:
      case _SCALAR_BANDEQS_TOKEN:
      case _SCALAR_PLUSPLUS_TOKEN:
      case _SCALAR_POST_PLUSPLUS_TOKEN:
      case _SCALAR_MINUSMINUS_TOKEN:
      case _SCALAR_POST_MINUSMINUS_TOKEN:
      case DOT_TOKEN:
      case DOT_METHOD_CALL_TOKEN:
      case TMP_TOKEN:
      case DEFINE_TOKEN:
      case DEFINE_STATIC_TOKEN:
      case DEFINE_PRIVATE_TOKEN:
      case DEFINE_PUBLIC_TOKEN:
      case FLOAT_TOKEN:
      case DOUBLE_TOKEN:
      case COMPLEX_TOKEN:
      case IDENT_TOKEN:
      case _REF_TOKEN:
      case _STRUCT_ASSIGN_TOKEN:
      case _STRUCT_PLUSEQS_TOKEN:
      case _STRUCT_MINUSEQS_TOKEN:
      case _STRUCT_TIMESEQS_TOKEN:
      case _STRUCT_DIVEQS_TOKEN:
      case _STRUCT_BOREQS_TOKEN:
      case _STRUCT_BANDEQS_TOKEN:
      case _STRUCT_POST_MINUSMINUS_TOKEN:
      case _STRUCT_MINUSMINUS_TOKEN:
      case _STRUCT_POST_PLUSPLUS_TOKEN:
      case _STRUCT_PLUSPLUS_TOKEN:
      case _STRUCT_FIELD_REF_TOKEN:
	strcpy (b3, tok->v.s_val);
	break;

      default:
	b3 = NULL;
     }

   if (b3 != NULL)
     {
	len = strlen (b3);
	buf[1] = (unsigned char) ((len & 0x7F) + 32);
	buf[2] = (unsigned char) (((len >> 7) & 0x7F) + 32);
	len += 3;
     }
   else len = 1;

   (void) bytecomp_write_data ((char *)buf, len);
}

int SLang_byte_compile_file (SLFUTURE_CONST char *name, int method)
{
   char file [1024];

   (void) method;
   if (strlen (name) + 2 >= sizeof (file))
     {
	_pSLang_verror (SL_INVALID_PARM, "Filename too long");
	return -1;
     }
   sprintf (file, "%sc", name);
   if (NULL == (Byte_Compile_Fp = fopen (file, "w")))
     {
	_pSLang_verror(SL_OBJ_NOPEN, "%s: unable to open", file);
	return -1;
     }

   Byte_Compile_Line_Len = 0;
   if (-1 != bytecomp_write_data (".#", 2))
     {
	_pSLcompile_ptr = byte_compile_token;
	(void) SLang_load_file (name);
	_pSLcompile_ptr = _pSLcompile;

	(void) bytecomp_write_data ("\n", 1);
     }

   if (EOF == fclose (Byte_Compile_Fp))
     SLang_set_error (SL_IO_WRITE_ERROR);

   if (_pSLang_Error)
     {
	_pSLang_verror (0, "Error processing %s", name);
	return -1;
     }
   return 0;
}

int SLang_generate_debug_info (int x)
{
#if SLANG_HAS_DEBUG_CODE
   /* int y = Default_Compile_Line_Num_Info; */
   /* Default_Compile_Line_Num_Info = x; */
   int y = 0;
   (void)x;
#if 0
   if (x == 0)
     Default_Compile_BOSEOS = 0;
   else
     Default_Compile_BOSEOS = 3;
#endif
   return y;
#else
   (void) x;
   return 0;
#endif
}
