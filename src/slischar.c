#include "slinclud.h"
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

#include "slang.h"
#include "_slang.h"

#define DEFINE_PSLWC_CLASSIFICATION_TABLE
#include "slischar.h"

#define MODE_VARIABLE _pSLinterp_UTF8_Mode

int SLwchar_islower (SLwchar_Type ch)
{
   if (MODE_VARIABLE)
     return SL_CLASSIFICATION_LOOKUP(ch) & SLCHARCLASS_LOWER;
   
   if (ch < 256)
     return islower ((unsigned char) ch);
     
   return 0;
}

int SLwchar_isupper (SLwchar_Type ch)
{
   if (MODE_VARIABLE)
     return SL_CLASSIFICATION_LOOKUP(ch) & SLCHARCLASS_UPPER;
   
   if (ch < 256)
     return isupper ((unsigned char) ch);
     
   return 0;
}

int SLwchar_isalpha (SLwchar_Type ch)
{
   if (MODE_VARIABLE)
     return SL_CLASSIFICATION_LOOKUP(ch) & SLCHARCLASS_ALPHA;
   
   if (ch < 256)
     return isalpha ((unsigned char) ch);
     
   return 0;
}

int SLwchar_isxdigit (SLwchar_Type ch)
{
   if (MODE_VARIABLE)
     return SL_CLASSIFICATION_LOOKUP(ch) & SLCHARCLASS_XDIGIT;
   
   if (ch < 256)
     return isxdigit ((unsigned char) ch);

   return 0;
}

int SLwchar_isspace (SLwchar_Type ch)
{
   if (MODE_VARIABLE)
     return SL_CLASSIFICATION_LOOKUP(ch) & SLCHARCLASS_SPACE;
   
   if (ch < 256)
     return isspace ((unsigned char) ch);

   return 0;
}

int SLwchar_isblank (SLwchar_Type ch)
{
   if (MODE_VARIABLE)
     return SL_CLASSIFICATION_LOOKUP(ch) & SLCHARCLASS_BLANK;
   
   return (ch == ' ') || (ch == '\t');
}

int SLwchar_iscntrl (SLwchar_Type ch)
{
   if (MODE_VARIABLE)
     return SL_CLASSIFICATION_LOOKUP(ch) & SLCHARCLASS_CNTRL;
   
   if (ch < 256)
     return iscntrl ((unsigned char) ch);

   return 0;
}

int SLwchar_isprint (SLwchar_Type ch)
{
   if (MODE_VARIABLE)
     return SL_CLASSIFICATION_LOOKUP(ch) & SLCHARCLASS_PRINT;
   
   if (ch < 256)
     return isprint ((unsigned char) ch);

   return 0;
}

/* The following are derived quantities */
#define DIGITCLASS(x) (((x)&SLCHARCLASS_XDIGIT)&&!((x)&SLCHARCLASS_ALPHA))
#define GRAPHCLASS(x) (((x)&SLCHARCLASS_PRINT)&&!((x)&SLCHARCLASS_SPACE))
#define ALNUMCLASS(x) ((x)&(SLCHARCLASS_ALPHA|SLCHARCLASS_XDIGIT))
#define PUNCTCLASS(x) (!ALNUMCLASS(x) && GRAPHCLASS(x))

int SLwchar_isdigit (SLwchar_Type ch)
{
   if (MODE_VARIABLE)
     {
	unsigned char t = SL_CLASSIFICATION_LOOKUP(ch);
	return DIGITCLASS(t);
     }

   if ((unsigned)ch < 256)
     return isdigit ((unsigned char) ch);

   return 0;
}

int SLwchar_isgraph (SLwchar_Type ch)
{
   if (MODE_VARIABLE)
     {
	unsigned char t = SL_CLASSIFICATION_LOOKUP(ch);
	return GRAPHCLASS(t);
     }

   if ((unsigned)ch < 256)
     return isgraph ((unsigned char) ch);

   return 0;
}

int SLwchar_isalnum (SLwchar_Type ch)
{
   if (MODE_VARIABLE)
     {
	unsigned char t = SL_CLASSIFICATION_LOOKUP(ch);
	return ALNUMCLASS(t);
     }

   if ((unsigned)ch < 256)
     return isalnum ((unsigned char) ch);

   return 0;
}


int SLwchar_ispunct (SLwchar_Type ch)
{
   if (MODE_VARIABLE)
     {
	unsigned char t = SL_CLASSIFICATION_LOOKUP(ch);
	return PUNCTCLASS(t);
     }

   if ((unsigned)ch < 256)
     return ispunct ((unsigned char) ch);

   return 0;
}

