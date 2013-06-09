/* -*-C-*-
 * json_generate_string needs to scan the input string twice:
 *   1. to determine the output string length, and
 *   2. to actually generate the output string.
 * In order to use the same algorithm, both functions
 *   1. alloc_generated_json_string, and
 *   2. fill_generated_json_string
 * are defined here at once.  Code that differs
 * is switched via #ifdef ALLOC_GENERATED_JSON_STRING.
 */

#ifdef ALLOC_GENERATED_JSON_STRING
static char *alloc_generated_json_string (char *ptr, char *end_of_input_string)
#else
static void fill_generated_json_string (char *ptr, char *end_of_input_string, char *dest_ptr)
#endif
{
#ifdef ALLOC_GENERATED_JSON_STRING
   SLstrlen_Type len = 0;
#else
   *dest_ptr++ = STRING_DELIMITER;
#endif

   while (ptr < end_of_input_string)
     {
       unsigned char ch = *ptr;
	if (ch == '"' || ch == '\\' || ch == '\b' || ch == '\f' || ch == '\n' || ch == '\r'|| ch == '\t')
	  {
#ifdef ALLOC_GENERATED_JSON_STRING
	     len += 2;
#else
	     *dest_ptr++ = ESCAPE_CHARACTER;
	     *dest_ptr++ = (ch == '"' || ch == '\\') ? ch
			 : (ch == '\b') ? 'b'
			 : (ch == '\f') ? 'f'
			 : (ch == '\n') ? 'n'
			 : (ch == '\r') ? 'r'
			 :                't';
#endif
	  }
	else if (ch < 32)
	  {
#ifdef ALLOC_GENERATED_JSON_STRING
	     len += 6;
#else
	     sprintf (dest_ptr, "\\u%04X", ch);
	     dest_ptr += 6;
#endif
	  }
	else if (ch < 0x80)
	  {
#ifdef ALLOC_GENERATED_JSON_STRING
	     len++;
#else
	     *dest_ptr++ = ch;
#endif
	  }
	else
	  {
	     /* We cannot use SLutf8_decode, since we need to handle invalid_or_overlong_utf8 or ILLEGAL_UNICODE as well. */
	     SLstrlen_Type multibyte_char_len
		= ((ch & 0xE0) == 0xC0) ? 2  /* (ch & 0b11100000) == 0b11000000 */
		: ((ch & 0xF0) == 0xE0) ? 3  /* (ch & 0b11110000) == 0b11100000 */
		: ((ch & 0xF8) == 0xF0) ? 4  /* (ch & 0b11111000) == 0b11110000 */
		: ((ch & 0xFC) == 0xF8) ? 5  /* (ch & 0b11111100) == 0b11111000 */
		:                         6;
#ifdef ALLOC_GENERATED_JSON_STRING
	     len += 6;
#else
	     {  /* stolen from slutf8.c : fast_utf8_decode */
		static unsigned char masks[7] = { 0, 0, 0x1F, 0xF, 0x7, 0x3, 0x1 };
		SLwchar_Type w = (ch & masks[multibyte_char_len]);
		SLstrlen_Type i;
		for (i = 1; i < multibyte_char_len; i++)
		  w = (w << 6) | (ptr[i] & 0x3F);

		sprintf (dest_ptr, "\\u%04X", w);
		dest_ptr += 6;
	     }
#endif
	     ptr += multibyte_char_len - 1;  /* ptr will anyways be incremented by 1 later on */
	  }
	ptr++;
     }

#ifdef ALLOC_GENERATED_JSON_STRING
   return SLmalloc (len + 3);
#else
   *dest_ptr++ = STRING_DELIMITER;
   *dest_ptr = 0;
#endif
}
