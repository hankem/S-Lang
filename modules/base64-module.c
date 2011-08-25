#include <stdio.h>
#include <string.h>
#include <slang.h>

SLANG_MODULE(base64);

static int Base64_Type_Id = 0;
#define B64_MAX_ENCODED_LINE_LEN 76    /* multiple of 4 */
typedef struct _Base64_Type Base64_Type;
struct _Base64_Type
{
   SLang_Name_Type *encode_callback;
   SLang_Any_Type *callback_data;
   unsigned char *encode_buffer;		       /* malloced */
   unsigned int num_encoded;
   unsigned char buf3[3];
   unsigned int buf3_len;
#define B64_ENCODER_CLOSED	0x1
#define B64_ENCODER_INVALID	0x2
   int flags;
};

static int check_encoder (Base64_Type *b64, int err)
{
   if (b64->flags & (B64_ENCODER_INVALID|B64_ENCODER_CLOSED))
     {
	if (err)
	  SLang_verror (SL_InvalidParm_Error, "Base64 encoder is invalid or closed");
	return -1;
     }
   return 0;
}

static void b64_partial_free (Base64_Type *b64)
{
   if (b64->callback_data != NULL) SLang_free_anytype (b64->callback_data);
   b64->callback_data = NULL;
   if (b64->encode_callback != NULL) SLang_free_function (b64->encode_callback);
   b64->encode_callback = NULL;
   if (b64->encode_buffer != NULL) SLfree ((char *)b64->encode_buffer);
   b64->encode_buffer = NULL;
   b64->flags |= B64_ENCODER_INVALID;
}

static int create_b64_encode_buffer (Base64_Type *b64)
{
   b64->num_encoded = 0;
   if (NULL == (b64->encode_buffer = (unsigned char *)SLmalloc (B64_MAX_ENCODED_LINE_LEN+1)))
     return -1;
   return 0;
}

static int execute_encode_callback (Base64_Type *b64)
{
   SLang_BString_Type *b;

   if (NULL == (b = SLbstring_create_malloced (b64->encode_buffer, b64->num_encoded, 0)))
     return -1;

   if (-1 == create_b64_encode_buffer (b64))
     {
	SLbstring_free (b);
	return -1;
     }

   if ((-1 == SLang_start_arg_list ())
       || (-1 == SLang_push_anytype (b64->callback_data))
       || (-1 == SLang_push_bstring (b))
       || (-1 == SLang_end_arg_list ())
       || (-1 == SLexecute_function (b64->encode_callback)))
     {
	b64->flags |= B64_ENCODER_INVALID;
	SLbstring_free (b);
	return -1;
     }
   SLbstring_free (b);
   return 0;
}

static void free_b64_type (Base64_Type *b64)
{
   if (b64 == NULL)
     return;
   b64_partial_free (b64);
   SLfree ((char *)b64);
}

/* rfc1521:
 *
 * The encoding process represents 24-bit groups of input bits as output
 *  strings of 4 encoded characters. Proceeding from left to right, a
 *  24-bit input group is formed by concatenating 3 8-bit input groups.
 *  These 24 bits are then treated as 4 concatenated 6-bit groups, each
 *  of which is translated into a single digit in the base64 alphabet.
 *  When encoding a bit stream via the base64 encoding, the bit stream
 *  must be presumed to be ordered with the most-significant-bit first.
 */

static char Base64_Bit_Mapping[64] =
{
   'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
   'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
   'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
   'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/',
};

/*  The output stream (encoded bytes) must be represented in lines of no
 *  more than 76 characters each.  All line breaks or other characters
 *  not found in Table 1 must be ignored by decoding software.  In base64
 *  data, characters other than those in Table 1, line breaks, and other
 *  white space probably indicate a transmission error, about which a
 *  warning message or even a message rejection might be appropriate
 *  under some circumstances.
 */

static int b64_encode_triplet (Base64_Type *b64, unsigned char *str)
{
   unsigned char *encode_buf;
   unsigned char ch0, ch1, ch2;

   encode_buf = b64->encode_buffer + b64->num_encoded;

   ch0 = str[0];
   ch1 = str[1];
   ch2 = str[2];
   encode_buf[0] = Base64_Bit_Mapping[ch0>>2];
   encode_buf[1] = Base64_Bit_Mapping[((ch0&0x3)<<4) | (ch1>>4)];
   encode_buf[2] = Base64_Bit_Mapping[((ch1&0xF)<<2) | (ch2>>6)];
   encode_buf[3] = Base64_Bit_Mapping[ch2&0x3F];
   b64->num_encoded += 4;
   if (b64->num_encoded < B64_MAX_ENCODED_LINE_LEN)
     return 0;
   encode_buf[4] = 0;
   return execute_encode_callback (b64);
}

static int b64_encode_accumulate (Base64_Type *b64, unsigned char *line, unsigned int len)
{
   unsigned char *linemax;
   unsigned int i;

   linemax = line + len;

   i = b64->buf3_len;
   if (i && (i < 3))
     {
	if (line < linemax)
	  b64->buf3[i++] = *line++;
	if ((i < 3) && (line < linemax))
	  b64->buf3[i++] = *line++;

	if (i < 3)
	  {
	     b64->buf3_len = i;
	     return 0;
	  }
	if (-1 == b64_encode_triplet (b64, b64->buf3))
	  return -1;
	b64->buf3_len = 0;
     }

   while (line + 3 <= linemax)
     {
	if (-1 == b64_encode_triplet (b64, line))
	  return -1;
	line += 3;
     }

   i = 0;
   while (line < linemax)
     b64->buf3[i++] = *line++;
   b64->buf3_len = i;
   return 0;
}


static void b64_encoder_accumulate_intrin (Base64_Type *b64, SLang_BString_Type *bstr)
{
   unsigned char *data;
   unsigned int len;

   if (-1 == check_encoder (b64, 1))
     return;

   if (NULL == (data = SLbstring_get_pointer (bstr, &len)))
     return;

   (void) b64_encode_accumulate (b64, data, len);
}

static void b64_encoder_close_intrin (Base64_Type *b64)
{
   if (-1 == check_encoder (b64, 0))
     goto close_encoder;

   /* Handle the padding */
   if (b64->buf3_len)
     {
	unsigned char *encode_buf = b64->encode_buffer + b64->num_encoded;
	unsigned char ch0, ch1;

	ch0 = b64->buf3[0];
	encode_buf[0] = Base64_Bit_Mapping[ch0>>2];
	if (b64->buf3_len > 1)
	  {
	     ch1 = b64->buf3[1];
	     encode_buf[1] = Base64_Bit_Mapping[((ch0&0x3)<<4) | (ch1>>4)];
	     encode_buf[2] = Base64_Bit_Mapping[((ch1&0xF)<<2)];
	  }
	else
	  {
	     encode_buf[1] = Base64_Bit_Mapping[((ch0&0x3)<<4)];
	     encode_buf[2] = '=';
	  }
	encode_buf[3] = '=';
	b64->num_encoded += 4;
	b64->buf3_len = 0;
	if (b64->num_encoded >= B64_MAX_ENCODED_LINE_LEN)
	  (void) execute_encode_callback (b64);
     }

   if (b64->num_encoded)
     (void) execute_encode_callback (b64);

close_encoder:
   b64_partial_free (b64);
   b64->flags |= B64_ENCODER_CLOSED;
}

static void new_b64_encoder_intrin (void)
{
   Base64_Type *b64;
   SLang_MMT_Type *mmt;

   if (NULL == (b64 = (Base64_Type *)SLmalloc(sizeof(Base64_Type))))
     return;
   memset ((char *)b64, 0, sizeof(Base64_Type));

   if (-1 == create_b64_encode_buffer (b64))
     {
	SLfree ((char *)b64);
	return;
     }

   if ((-1 == SLang_pop_anytype (&b64->callback_data))
	|| (NULL == (b64->encode_callback = SLang_pop_function ()))
	|| (NULL == (mmt = SLang_create_mmt (Base64_Type_Id, (VOID_STAR)b64))))
     {
	free_b64_type (b64);
	return;
     }

   if (-1 == SLang_push_mmt (mmt))
     SLang_free_mmt (mmt);
}

#define DUMMY_B64_TYPE ((SLtype)-1)
static SLang_Intrin_Fun_Type Module_Intrinsics [] =
{
   MAKE_INTRINSIC_0("_base64_encoder_new", new_b64_encoder_intrin, SLANG_VOID_TYPE),
   MAKE_INTRINSIC_2("_base64_encoder_accumulate", b64_encoder_accumulate_intrin, SLANG_VOID_TYPE, DUMMY_B64_TYPE, SLANG_BSTRING_TYPE),
   MAKE_INTRINSIC_1("_base64_encoder_close", b64_encoder_close_intrin, SLANG_VOID_TYPE, DUMMY_B64_TYPE),
   SLANG_END_INTRIN_FUN_TABLE
};

static void destroy_b64 (SLtype type, VOID_STAR f)
{
   (void) type;
   free_b64_type ((Base64_Type *)f);
}

static int register_b64_type (void)
{
   SLang_Class_Type *cl;

   if (Base64_Type_Id != 0)
     return 0;

   if (NULL == (cl = SLclass_allocate_class ("Base64_Type")))
     return -1;

   if (-1 == SLclass_set_destroy_function (cl, destroy_b64))
     return -1;

   /* By registering as SLANG_VOID_TYPE, slang will dynamically allocate a
    * type.
    */
   if (-1 == SLclass_register_class (cl, SLANG_VOID_TYPE, sizeof (Base64_Type), SLANG_CLASS_TYPE_MMT))
     return -1;

   Base64_Type_Id = SLclass_get_class_id (cl);
   if (-1 == SLclass_patch_intrin_fun_table1 (Module_Intrinsics, DUMMY_B64_TYPE, Base64_Type_Id))
     return -1;

   return 0;
}

int init_base64_module_ns (char *ns_name)
{
   SLang_NameSpace_Type *ns = SLns_create_namespace (ns_name);
   if (ns == NULL)
     return -1;

   if (-1 == register_b64_type ())
     return -1;

   if (-1 == SLns_add_intrin_fun_table (ns, Module_Intrinsics, NULL))
     return -1;

   return 0;
}

/* This function is optional */
void deinit_base64_module (void)
{
}
