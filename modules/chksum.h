#ifndef SL_CHKSUM_H_
#define SL_CHKSUM_H_

#if SIZEOF_INT == 4
typedef unsigned int uint32;
#else
# if SIZEOF_SHORT == 4
typedef unsigned short uint32;
# else
#  if SIZEOF_LONG == 4
typedef unsigned long uint32;
#  else
#   error "Unable to find a 32bit integer type"
#  endif
# endif
#endif

typedef struct SLChksum_Type
{
   int (*accumulate)(struct SLChksum_Type *, unsigned char *, unsigned int);

   /* compute the digest and delete the object.  If the digest parameter is
    * NULL, just delete the object
    */
   int (*close)(struct SLChksum_Type *, unsigned char *);
   unsigned int digest_len;	       /* set by open */
#ifdef CHKSUM_TYPE_PRIVATE_FIELDS
   /* private data */
   CHKSUM_TYPE_PRIVATE_FIELDS
#endif
}
SLChksum_Type;

extern SLChksum_Type *_pSLchksum_sha1_new (char *name);
extern SLChksum_Type *_pSLchksum_md5_new (char *name);
#endif

