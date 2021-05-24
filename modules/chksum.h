#ifndef SL_CHKSUM_H_
#define SL_CHKSUM_H_

typedef struct SLChksum_Type
{
   int (*accumulate)(struct SLChksum_Type *, unsigned char *, unsigned int);

   /* compute the digest and delete the object.  If the last argument is
    * non-zero, just delete the object.
    */
   int (*close)(struct SLChksum_Type *, unsigned char *, int);
   unsigned int digest_len;	       /* set by open */
   unsigned int buffer_size;           /* the buffer length */
   int close_will_push;		       /* if non-zero, the close method will push the result */
#ifdef CHKSUM_TYPE_PRIVATE_FIELDS
   /* private data */
   CHKSUM_TYPE_PRIVATE_FIELDS
#endif
}
SLChksum_Type;

extern SLChksum_Type *_pSLchksum_sha1_new (char *name);
extern SLChksum_Type *_pSLchksum_md5_new (char *name);
extern SLChksum_Type *_pSLchksum_crc8_new (char *name);
extern SLChksum_Type *_pSLchksum_crc16_new (char *name);
extern SLChksum_Type *_pSLchksum_crc32_new (char *name);
extern SLChksum_Type *_pSLchksum_sha256_new (char *name);
extern SLChksum_Type *_pSLchksum_sha512_new (char *name);
#endif

