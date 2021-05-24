/* -*- mode: c; mode: fold; -*- */

/* Implementation of the sha2 family: sha256, sha224, sha512, and sha384.
 * The implementation loosely follows https://datatracker.ietf.org/doc/html/rfc4634#section-5.2
 * but mapped into the structure as layed out by chksum_sha1.c
 */

#include "config.h"
#include <string.h>
#include <limits.h>
#include <slang.h>

#include "_slint.h"

#define SHA224_BUFSIZE    64
#define SHA224_DIGEST_LEN 28
#define SHA256_BUFSIZE    64
#define SHA256_DIGEST_LEN 32
#define SHA224_BITSIZE    224
#define SHA256_BITSIZE    256
#define SHA384_BUFSIZE    128
#define SHA384_DIGEST_LEN 48
#define SHA512_BUFSIZE    128
#define SHA512_DIGEST_LEN 64
#define SHA384_BITSIZE    384
#define SHA512_BITSIZE    512

#define CHKSUM_TYPE_PRIVATE_FIELDS \
   unsigned int bitsize; \
   _pSLuint32_Type *h; \
   _pSLuint32_Type num_bits[4];                /* 64 bit/128 bit representation */ \
   unsigned int num_buffered; \
   unsigned char *buf;

#include "chksum.h"

#define SHL(n, x) ((x)<<(n))
#define SHR(n, x) ((x)>>(n))
#define ROTR(n, x) (((x)>>(n)) | ((x)<<(32-(n))))
#define ROTL(n, x) (((x)<<(n)) | ((x)>>(32-(n))))

#define CH(x, y, z) (((x) & (y)) ^ ((~(x)) & (z)))
#define MAJ(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define BSIG0(x) (ROTR( 2, (x)) ^ ROTR(13, (x)) ^ ROTR(22, (x)))
#define BSIG1(x) (ROTR( 6, (x)) ^ ROTR(11, (x)) ^ ROTR(25, (x)))
#define SSIG0(x) (ROTR( 7, (x)) ^ ROTR(18, (x)) ^  SHR( 3, (x)))
#define SSIG1(x) (ROTR(17, (x)) ^ ROTR(19, (x)) ^  SHR(10, (x)))

#define MAKE_WORD(b) \
   ((((_pSLuint32_Type)((b)[0]))<<24) | (((_pSLuint32_Type)((b)[1]))<<16) \
     | (((_pSLuint32_Type)((b)[2]))<<8) | ((_pSLuint32_Type)((b)[3])))

/* We need some macros to handle 64 bit values to not have to rely on this datatype */
#if _pSLANG_UINT64_TYPE

# define ROTR_64(n, x) (((x) >> (n)) | ((x)<<(64-(n))))
# define ROTL_64(n, x) (((x) << (n)) | ((x)>>(64-(n))))

# define BSIG0_64(x) (ROTR_64(28, (x)) ^ ROTR_64(34, (x)) ^ ROTR_64(39, (x)))
# define BSIG1_64(x) (ROTR_64(14, (x)) ^ ROTR_64(18, (x)) ^ ROTR_64(41, (x)))
# define SSIG0_64(x) (ROTR_64( 1, (x)) ^ ROTR_64( 8, (x)) ^     SHR( 7, (x)))
# define SSIG1_64(x) (ROTR_64(19, (x)) ^ ROTR_64(61, (x)) ^     SHR( 6, (x)))

# define MAKE_LONG_WORD(b) \
   ( \
     (((_pSLuint64_Type)((b)[0]))<<56) | \
     (((_pSLuint64_Type)((b)[1]))<<48) | \
     (((_pSLuint64_Type)((b)[2]))<<40) | \
     (((_pSLuint64_Type)((b)[3]))<<32) | \
     (((_pSLuint64_Type)((b)[4]))<<24) | \
     (((_pSLuint64_Type)((b)[5]))<<16) | \
     (((_pSLuint64_Type)((b)[6]))<<8) | \
     (((_pSLuint64_Type)((b)[7]))) \
   )

#else /* ! _pSLANG_UINT64_TYPE */

/* 64 bit bitshift right */
# define SHR_64(n, x, r) \
   ( \
     (r)[1] = (((n) > 32) \
	       ? ((x)[0] >> ((n) - 32)) \
	       : (((n) == 32) \
		  ? (x)[0] \
		  : (((n) >= 0) \
		     ? (((x)[0] << (32 - (n))) | ((x)[1] >> (n))) \
		     : 0) \
		  ) \
	       ), \
     (r)[0] = (((n) < 32) && ((n) >= 0)) ? ((x)[0] >> (n)) : 0 \
   )

/* 64 bit bitshift left */
# define SHL_64(n, x, r) \
   ( \
     (r)[0] = (((n) > 32) \
	       ? ((x)[1] << ((n) - 32)) \
	       : (((n) == 32) \
		  ? (x)[1] \
		  : (((n) >= 0) \
		     ? (((x)[0] << (n)) | ((x)[1] >> (32 - (n)))) \
		     :  0) \
		  ) \
	       ), \
     (r)[1] = (((n) < 32) && ((n) >= 0)) ? ((x)[1] << (n)) : 0 \
   )

// 64 bit bitwise or
# define OR_64(a, b, r) \
   ( \
     (r)[0] = (a)[0] | (b)[0],  \
     (r)[1] = (a)[1] | (b)[1] \
   )

// 64 bit bitwise xor
# define XOR_64(a, b, r) \
   ( \
     (r)[0] = (a)[0] ^ (b)[0],  \
     (r)[1] = (a)[1] ^ (b)[1] \
   )

// 64 bit bitwise and
# define AND_64(a, b, r) \
   ( \
     (r)[0] = (a)[0] & (b)[0],  \
     (r)[1] = (a)[1] & (b)[1] \
   )

// 64 bit bitwise not
# define NOT_64(x, r) \
   ( \
     (r)[0] = ~(x)[0], \
     (r)[1] = ~(x)[1] \
   )

// 64 bit add
# define ADD_64(a, b, r) \
   ( \
     (r)[1] = (a)[1] + (b)[1], \
     (r)[0] = (a)[0] + (b)[0] + ((r)[1] < (a)[1]) \
   )

// 64 bit rotate right
# define ROTR_64(n, x, tmp, r) \
   ( \
     SHR_64((n), (x), (tmp)), \
     SHL_64(64-(n), (x), (r)), \
     OR_64((tmp), (r), (r))\
   )

// 64 bit BSIG0
# define BSIG0_64(x, t1, t2, t3, r) \
   ( \
     ROTR_64(28, (x), (t3), (t1)), \
     ROTR_64(34, (x), (t3), (t2)), \
     ROTR_64(39, (x), (t3), (r)), \
     XOR_64((t1), (t2), (t2)), \
     XOR_64((t2), (r), (r)) \
   )

// 64 bit BSIG1
# define BSIG1_64(x, t1, t2, t3, r) \
   ( \
     ROTR_64(14, (x), (t3), (t1)), \
     ROTR_64(18, (x), (t3), (t2)), \
     ROTR_64(41, (x), (t3), (r)), \
     XOR_64((t1), (t2), (t2)), \
     XOR_64((t2), (r), (r)) \
   )

// 64 bit SSIG0
# define SSIG0_64(x, t1, t2, t3, r) \
   ( \
     ROTR_64(1, (x), (t3), (t1)), \
     ROTR_64(8, (x), (t3), (t2)), \
     SHR_64( 7, (x), (r)), \
     XOR_64((t1), (t2), (t2)), \
     XOR_64((t2), (r), (r)) \
   )

// 64 bit SSIG1
# define SSIG1_64(x, t1, t2, t3, r) \
   ( \
     ROTR_64(19, (x), (t3), (t1)), \
     ROTR_64(61, (x), (t3), (t2)), \
     SHR_64( 6, (x), (r)), \
     XOR_64((t1), (t2), (t2)), \
     XOR_64((t2), (r), (r)) \
   )

// 64 bit CH
# define CH_64(x, y, z, r) \
   ( \
     (r)[0] = (((x)[0] & ((y)[0] ^ (z)[0])) ^ (z)[0]), \
     (r)[1] = (((x)[1] & ((y)[1] ^ (z)[1])) ^ (z)[1]) \
   )

// 64 bit MAJ
# define MAJ_64(x, y, z, r) \
   ( \
     (r)[0] = (((x)[0] & ((y)[0] | (z)[0])) | ((y)[0] & (z)[0])), \
     (r)[1] = (((x)[1] & ((y)[1] | (z)[1])) | ((y)[1] & (z)[1])) \
   )

#endif /* _pSLANG_UINT64_TYPE */

static unsigned int compute_64b_pad_length (unsigned int len) /*{{{*/
{
   unsigned int mod64 = len % 64;
   unsigned int dlen;

   if (mod64 < 56)
     dlen = 56 - mod64;
   else
     dlen = 120 - mod64;

   return dlen;
}
/*}}}*/

static unsigned int compute_128b_pad_length (unsigned int len) /*{{{*/
{
   unsigned int mod1024 = len % 128;
   unsigned int dlen;

   if (mod1024 < 112)
     dlen = 112 - mod1024;
   else
     dlen = 240 - mod1024;

   return dlen;
}
/*}}}*/

static unsigned char Pad_Bytes[128] = /*{{{*/
{
   0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};
/*}}}*/

static const _pSLuint32_Type SHA256_K[] = /*{{{*/
{
   0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
   0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
   0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
   0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
   0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
   0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
   0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
   0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
   0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
   0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
   0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
   0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
   0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
   0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
   0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
   0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};
/*}}}*/

#if _pSLANG_UINT64_TYPE
static const _pSLuint64_Type SHA512_K[] = /*{{{*/
{
   0x428a2f98d728ae22,  0x7137449123ef65cd,  0xb5c0fbcfec4d3b2f,  0xe9b5dba58189dbbc,
   0x3956c25bf348b538,  0x59f111f1b605d019,  0x923f82a4af194f9b,  0xab1c5ed5da6d8118,
   0xd807aa98a3030242,  0x12835b0145706fbe,  0x243185be4ee4b28c,  0x550c7dc3d5ffb4e2,
   0x72be5d74f27b896f,  0x80deb1fe3b1696b1,  0x9bdc06a725c71235,  0xc19bf174cf692694,
   0xe49b69c19ef14ad2,  0xefbe4786384f25e3,  0x0fc19dc68b8cd5b5,  0x240ca1cc77ac9c65,
   0x2de92c6f592b0275,  0x4a7484aa6ea6e483,  0x5cb0a9dcbd41fbd4,  0x76f988da831153b5,
   0x983e5152ee66dfab,  0xa831c66d2db43210,  0xb00327c898fb213f,  0xbf597fc7beef0ee4,
   0xc6e00bf33da88fc2,  0xd5a79147930aa725,  0x06ca6351e003826f,  0x142929670a0e6e70,
   0x27b70a8546d22ffc,  0x2e1b21385c26c926,  0x4d2c6dfc5ac42aed,  0x53380d139d95b3df,
   0x650a73548baf63de,  0x766a0abb3c77b2a8,  0x81c2c92e47edaee6,  0x92722c851482353b,
   0xa2bfe8a14cf10364,  0xa81a664bbc423001,  0xc24b8b70d0f89791,  0xc76c51a30654be30,
   0xd192e819d6ef5218,  0xd69906245565a910,  0xf40e35855771202a,  0x106aa07032bbd1b8,
   0x19a4c116b8d2d0c8,  0x1e376c085141ab53,  0x2748774cdf8eeb99,  0x34b0bcb5e19b48a8,
   0x391c0cb3c5c95a63,  0x4ed8aa4ae3418acb,  0x5b9cca4f7763e373,  0x682e6ff3d6b2b8a3,
   0x748f82ee5defb2fc,  0x78a5636f43172f60,  0x84c87814a1f0ab72,  0x8cc702081a6439ec,
   0x90befffa23631e28,  0xa4506cebde82bde9,  0xbef9a3f7b2c67915,  0xc67178f2e372532b,
   0xca273eceea26619c,  0xd186b8c721c0c207,  0xeada7dd6cde0eb1e,  0xf57d4f7fee6ed178,
   0x06f067aa72176fba,  0x0a637dc5a2c898a6,  0x113f9804bef90dae,  0x1b710b35131c471b,
   0x28db77f523047d84,  0x32caab7b40c72493,  0x3c9ebe0a15c9bebc,  0x431d67c49c100d4c,
   0x4cc5d4becb3e42b6,  0x597f299cfc657e2a,  0x5fcb6fab3ad6faec,  0x6c44198c4a475817
};
/*}}}*/
#else /* !_pSLANG_UINT64_TYPE */
static const _pSLuint32_Type SHA512_K[][2] = /*{{{*/
{
   { 0x428a2f98, 0xd728ae22 }, { 0x71374491, 0x23ef65cd }, { 0xb5c0fbcf, 0xec4d3b2f }, { 0xe9b5dba5, 0x8189dbbc },
   { 0x3956c25b, 0xf348b538 }, { 0x59f111f1, 0xb605d019 }, { 0x923f82a4, 0xaf194f9b }, { 0xab1c5ed5, 0xda6d8118 },
   { 0xd807aa98, 0xa3030242 }, { 0x12835b01, 0x45706fbe }, { 0x243185be, 0x4ee4b28c }, { 0x550c7dc3, 0xd5ffb4e2 },
   { 0x72be5d74, 0xf27b896f }, { 0x80deb1fe, 0x3b1696b1 }, { 0x9bdc06a7, 0x25c71235 }, { 0xc19bf174, 0xcf692694 },
   { 0xe49b69c1, 0x9ef14ad2 }, { 0xefbe4786, 0x384f25e3 }, { 0x0fc19dc6, 0x8b8cd5b5 }, { 0x240ca1cc, 0x77ac9c65 },
   { 0x2de92c6f, 0x592b0275 }, { 0x4a7484aa, 0x6ea6e483 }, { 0x5cb0a9dc, 0xbd41fbd4 }, { 0x76f988da, 0x831153b5 },
   { 0x983e5152, 0xee66dfab }, { 0xa831c66d, 0x2db43210 }, { 0xb00327c8, 0x98fb213f }, { 0xbf597fc7, 0xbeef0ee4 },
   { 0xc6e00bf3, 0x3da88fc2 }, { 0xd5a79147, 0x930aa725 }, { 0x06ca6351, 0xe003826f }, { 0x14292967, 0x0a0e6e70 },
   { 0x27b70a85, 0x46d22ffc }, { 0x2e1b2138, 0x5c26c926 }, { 0x4d2c6dfc, 0x5ac42aed }, { 0x53380d13, 0x9d95b3df },
   { 0x650a7354, 0x8baf63de }, { 0x766a0abb, 0x3c77b2a8 }, { 0x81c2c92e, 0x47edaee6 }, { 0x92722c85, 0x1482353b },
   { 0xa2bfe8a1, 0x4cf10364 }, { 0xa81a664b, 0xbc423001 }, { 0xc24b8b70, 0xd0f89791 }, { 0xc76c51a3, 0x0654be30 },
   { 0xd192e819, 0xd6ef5218 }, { 0xd6990624, 0x5565a910 }, { 0xf40e3585, 0x5771202a }, { 0x106aa070, 0x32bbd1b8 },
   { 0x19a4c116, 0xb8d2d0c8 }, { 0x1e376c08, 0x5141ab53 }, { 0x2748774c, 0xdf8eeb99 }, { 0x34b0bcb5, 0xe19b48a8 },
   { 0x391c0cb3, 0xc5c95a63 }, { 0x4ed8aa4a, 0xe3418acb }, { 0x5b9cca4f, 0x7763e373 }, { 0x682e6ff3, 0xd6b2b8a3 },
   { 0x748f82ee, 0x5defb2fc }, { 0x78a5636f, 0x43172f60 }, { 0x84c87814, 0xa1f0ab72 }, { 0x8cc70208, 0x1a6439ec },
   { 0x90befffa, 0x23631e28 }, { 0xa4506ceb, 0xde82bde9 }, { 0xbef9a3f7, 0xb2c67915 }, { 0xc67178f2, 0xe372532b },
   { 0xca273ece, 0xea26619c }, { 0xd186b8c7, 0x21c0c207 }, { 0xeada7dd6, 0xcde0eb1e }, { 0xf57d4f7f, 0xee6ed178 },
   { 0x06f067aa, 0x72176fba }, { 0x0a637dc5, 0xa2c898a6 }, { 0x113f9804, 0xbef90dae }, { 0x1b710b35, 0x131c471b },
   { 0x28db77f5, 0x23047d84 }, { 0x32caab7b, 0x40c72493 }, { 0x3c9ebe0a, 0x15c9bebc }, { 0x431d67c4, 0x9c100d4c },
   { 0x4cc5d4be, 0xcb3e42b6 }, { 0x597f299c, 0xfc657e2a }, { 0x5fcb6fab, 0x3ad6faec }, { 0x6c44198c, 0x4a475817 }
};
/*}}}*/
#endif /* _pSLANG_UINT64_TYPE */

static int init_sha224_object (SLChksum_Type *chksum) /*{{{*/
{
   if (NULL == (chksum->h = (_pSLuint32_Type *)SLmalloc(SHA256_BITSIZE/32*sizeof(*(chksum->h)))))
     return -1;

   if (NULL == (chksum->buf = (unsigned char *)SLmalloc(SHA224_BUFSIZE*sizeof(*(chksum->buf)))))
     return -1;

   chksum->h[0] = 0xc1059ed8;
   chksum->h[1] = 0x367cd507;
   chksum->h[2] = 0x3070dd17;
   chksum->h[3] = 0xf70e5939;
   chksum->h[4] = 0xffc00b31;
   chksum->h[5] = 0x68581511;
   chksum->h[6] = 0x64f98fa7;
   chksum->h[7] = 0xbefa4fa4;

   chksum->buffer_size = SHA224_BUFSIZE;
   chksum->bitsize = SHA224_BITSIZE;
   chksum->digest_len = SHA224_DIGEST_LEN;

   return 0;
}
/*}}}*/

static int init_sha256_object (SLChksum_Type *chksum) /*{{{*/
{
   if (NULL == (chksum->h = (_pSLuint32_Type *)SLmalloc(SHA256_BITSIZE/32*sizeof(*(chksum->h)))))
     return -1;

   if (NULL == (chksum->buf = (unsigned char *)SLmalloc(SHA256_BUFSIZE*sizeof(*(chksum->buf)))))
     return -1;

   chksum->h[0] = 0x6a09e667;
   chksum->h[1] = 0xbb67ae85;
   chksum->h[2] = 0x3c6ef372;
   chksum->h[3] = 0xa54ff53a;
   chksum->h[4] = 0x510e527f;
   chksum->h[5] = 0x9b05688c;
   chksum->h[6] = 0x1f83d9ab;
   chksum->h[7] = 0x5be0cd19;

   chksum->buffer_size = SHA256_BUFSIZE;
   chksum->bitsize = SHA256_BITSIZE;
   chksum->digest_len = SHA256_DIGEST_LEN;

   return 0;
}
/*}}}*/

static int init_sha384_object (SLChksum_Type *chksum) /*{{{*/
{
   if (NULL == (chksum->h = (_pSLuint32_Type *)SLmalloc(SHA512_BITSIZE/32*sizeof(*(chksum->h)))))
     return -1;

   if (NULL == (chksum->buf = (unsigned char *)SLmalloc(SHA384_BUFSIZE*sizeof(*(chksum->buf)))))
     return -1;

#if _pSLANG_UINT64_TYPE
   ((_pSLuint64_Type*)(chksum->h))[0] = 0xcbbb9d5dc1059ed8;
   ((_pSLuint64_Type*)(chksum->h))[1] = 0x629a292a367cd507;
   ((_pSLuint64_Type*)(chksum->h))[2] = 0x9159015a3070dd17;
   ((_pSLuint64_Type*)(chksum->h))[3] = 0x152fecd8f70e5939;
   ((_pSLuint64_Type*)(chksum->h))[4] = 0x67332667ffc00b31;
   ((_pSLuint64_Type*)(chksum->h))[5] = 0x8eb44a8768581511;
   ((_pSLuint64_Type*)(chksum->h))[6] = 0xdb0c2e0d64f98fa7;
   ((_pSLuint64_Type*)(chksum->h))[7] = 0x47b5481dbefa4fa4;
#else /* !_pSLANG_UINT64_TYPE */
   ((_pSLuint32_Type (*)[2])(chksum->h))[0][0] = 0xcbbb9d5d; ((_pSLuint32_Type (*)[2])(chksum->h))[0][1] = 0xc1059ed8;
   ((_pSLuint32_Type (*)[2])(chksum->h))[1][0] = 0x629a292a; ((_pSLuint32_Type (*)[2])(chksum->h))[1][1] = 0x367cd507;
   ((_pSLuint32_Type (*)[2])(chksum->h))[2][0] = 0x9159015a; ((_pSLuint32_Type (*)[2])(chksum->h))[2][1] = 0x3070dd17;
   ((_pSLuint32_Type (*)[2])(chksum->h))[3][0] = 0x152fecd8; ((_pSLuint32_Type (*)[2])(chksum->h))[3][1] = 0xf70e5939;
   ((_pSLuint32_Type (*)[2])(chksum->h))[4][0] = 0x67332667; ((_pSLuint32_Type (*)[2])(chksum->h))[4][1] = 0xffc00b31;
   ((_pSLuint32_Type (*)[2])(chksum->h))[5][0] = 0x8eb44a87; ((_pSLuint32_Type (*)[2])(chksum->h))[5][1] = 0x68581511;
   ((_pSLuint32_Type (*)[2])(chksum->h))[6][0] = 0xdb0c2e0d; ((_pSLuint32_Type (*)[2])(chksum->h))[6][1] = 0x64f98fa7;
   ((_pSLuint32_Type (*)[2])(chksum->h))[7][0] = 0x47b5481d; ((_pSLuint32_Type (*)[2])(chksum->h))[7][1] = 0xbefa4fa4;
#endif /* !_pSLANG_UINT64_TYPE */

   chksum->buffer_size = SHA384_BUFSIZE;
   chksum->bitsize = SHA384_BITSIZE;
   chksum->digest_len = SHA384_DIGEST_LEN;

   return 0;
}
/*}}}*/

static int init_sha512_object (SLChksum_Type *chksum) /*{{{*/
{
   if (NULL == (chksum->h = (_pSLuint32_Type *)SLmalloc(SHA512_BITSIZE/32*sizeof(*(chksum->h)))))
     return -1;

   if (NULL == (chksum->buf = (unsigned char *)SLmalloc(SHA512_BUFSIZE*sizeof(*(chksum->buf)))))
     return -1;

#if _pSLANG_UINT64_TYPE
   ((_pSLuint64_Type*)(chksum->h))[0] = 0x6a09e667f3bcc908;
   ((_pSLuint64_Type*)(chksum->h))[1] = 0xbb67ae8584caa73b;
   ((_pSLuint64_Type*)(chksum->h))[2] = 0x3c6ef372fe94f82b;
   ((_pSLuint64_Type*)(chksum->h))[3] = 0xa54ff53a5f1d36f1;
   ((_pSLuint64_Type*)(chksum->h))[4] = 0x510e527fade682d1;
   ((_pSLuint64_Type*)(chksum->h))[5] = 0x9b05688c2b3e6c1f;
   ((_pSLuint64_Type*)(chksum->h))[6] = 0x1f83d9abfb41bd6b;
   ((_pSLuint64_Type*)(chksum->h))[7] = 0x5be0cd19137e2179;
#else /* !_pSLANG_UINT64_TYPE */
   ((_pSLuint32_Type (*)[2])(chksum->h))[0][0] = 0x6a09e667; ((_pSLuint32_Type (*)[2])(chksum->h))[0][1] = 0xf3bcc908;
   ((_pSLuint32_Type (*)[2])(chksum->h))[1][0] = 0xbb67ae85; ((_pSLuint32_Type (*)[2])(chksum->h))[1][1] = 0x84caa73b;
   ((_pSLuint32_Type (*)[2])(chksum->h))[2][0] = 0x3c6ef372; ((_pSLuint32_Type (*)[2])(chksum->h))[2][1] = 0xfe94f82b;
   ((_pSLuint32_Type (*)[2])(chksum->h))[3][0] = 0xa54ff53a; ((_pSLuint32_Type (*)[2])(chksum->h))[3][1] = 0x5f1d36f1;
   ((_pSLuint32_Type (*)[2])(chksum->h))[4][0] = 0x510e527f; ((_pSLuint32_Type (*)[2])(chksum->h))[4][1] = 0xade682d1;
   ((_pSLuint32_Type (*)[2])(chksum->h))[5][0] = 0x9b05688c; ((_pSLuint32_Type (*)[2])(chksum->h))[5][1] = 0x2b3e6c1f;
   ((_pSLuint32_Type (*)[2])(chksum->h))[6][0] = 0x1f83d9ab; ((_pSLuint32_Type (*)[2])(chksum->h))[6][1] = 0xfb41bd6b;
   ((_pSLuint32_Type (*)[2])(chksum->h))[7][0] = 0x5be0cd19; ((_pSLuint32_Type (*)[2])(chksum->h))[7][1] = 0x137e2179;
#endif /* !_pSLANG_UINT64_TYPE */

   chksum->buffer_size = SHA512_BUFSIZE;
   chksum->bitsize = SHA512_BITSIZE;
   chksum->digest_len = SHA512_DIGEST_LEN;

   return 0;
}
/*}}}*/

static _pSLuint32_Type overflow_add (_pSLuint32_Type a, _pSLuint32_Type b, _pSLuint32_Type *c) /*{{{*/
{
   _pSLuint32_Type b1 = (_pSLuint32_Type)(-1) - b;
   if (a <= b1)
     {
	*c = 0;
	return a+b;
     }
   *c = 1;
   return (a - b1) - 1;
}
/*}}}*/

#if _pSLANG_UINT64_TYPE
static _pSLuint64_Type overflow_add_long (_pSLuint64_Type a, _pSLuint64_Type b, _pSLuint64_Type *c) /*{{{*/
{
   _pSLuint64_Type b1 = (_pSLuint64_Type)(-1) - b;

   if (a <= b1)
     {
	*c = 0;
	return a+b;
     }
   *c = 1;
   return (a - b1) - 1;
}
/*}}}*/
#endif

static int update_num_bits_long (SLChksum_Type *chksum, unsigned int dnum_bits) /*{{{*/
{
#if _pSLANG_UINT64_TYPE
   _pSLuint64_Type lo, hi, c;
   hi = ((_pSLuint64_Type*)(chksum->num_bits))[0];
   lo = ((_pSLuint64_Type*)(chksum->num_bits))[1];

   lo = overflow_add_long(lo, (_pSLuint64_Type)dnum_bits << 3, &c);
   if (c)
     {
	hi = overflow_add_long(hi, c, &c);
	if (c)
	  return -1;
     }
   hi = overflow_add_long(hi, dnum_bits >> 29, &c);
   if (c)
     return -1;

   ((_pSLuint64_Type*)(chksum->num_bits))[0] = hi;
   ((_pSLuint64_Type*)(chksum->num_bits))[1] = lo;
#else /* !_pSLANG_UINT64_TYPE */
   _pSLuint32_Type l1, l2, l3, l4, c;

   l1 = chksum->num_bits[0];
   l2 = chksum->num_bits[1];
   l3 = chksum->num_bits[2];
   l4 = chksum->num_bits[3];

   l4 = overflow_add(l4, (_pSLuint32_Type)dnum_bits << 3, &c);
   if (c)
     {
	l3 = overflow_add(l3, c, &c);
	if (c)
	  {
	     l2 = overflow_add(l2, c, &c);
	     if (c)
	       {
		  l1 = overflow_add(l1, c, &c);
		  if (c)
		    return -1;
	       }
	  }
     }
   l3 = overflow_add(l3, dnum_bits >> 29, &c);
   if (c)
     {
	l2 = overflow_add(l2, c, &c);
	if (c)
	  {
	     l1 = overflow_add(l1, c, &c);
	     if (c)
	       return -1;
	  }
     }

   chksum->num_bits[0] = l1;
   chksum->num_bits[1] = l2;
   chksum->num_bits[2] = l3;
   chksum->num_bits[3] = l4;
#endif /* !_pSLANG_UINT64_TYPE */

   return 0;
}
/*}}}*/

static int update_num_bits (SLChksum_Type *chksum, unsigned int dnum_bits) /*{{{*/
{
   _pSLuint32_Type l1, l2, c, d;

   d = (_pSLuint32_Type)dnum_bits << 3; // *8 bytes to bits
   l1 = chksum->num_bits[0];
   l2 = chksum->num_bits[1];

   l2 = overflow_add(l2, d, &c);
   if (c)
     {
	l1 = overflow_add(l1, c, &c);
	if (c)
	  return -1;
     }
   l1 = overflow_add(l1, dnum_bits >> 29, &c);
   if (c)
     return -1;

   chksum->num_bits[0] = l1;
   chksum->num_bits[1] = l2;

   return 0;
}
/*}}}*/

static void sha256_process_block (SLChksum_Type *sha256, unsigned char *buf) /*{{{*/
{
   _pSLuint32_Type a,b,c,d,e,f,g,h;
   _pSLuint32_Type w[64];
   unsigned int t;

   for (t=0; t<16; t++)
     {
	w[t] = MAKE_WORD(buf);
	buf += 4;
     }

   for (t=16; t<64; t++)
     w[t] = SSIG1(w[t-2]) + w[t-7] + SSIG0(w[t-15]) + w[t-16];

   a = sha256->h[0];
   b = sha256->h[1];
   c = sha256->h[2];
   d = sha256->h[3];
   e = sha256->h[4];
   f = sha256->h[5];
   g = sha256->h[6];
   h = sha256->h[7];

   for (t=0; t<64; t++)
     {
	_pSLuint32_Type t1 = h + BSIG1(e) + CH(e,f,g) + SHA256_K[t] + w[t];
	_pSLuint32_Type t2 = BSIG0(a) + MAJ(a,b,c);
	h = g;
	g = f;
	f = e;
	e = d + t1;
	d = c;
	c = b;
	b = a;
	a = t1 + t2;
     }

   sha256->h[0] += a;
   sha256->h[1] += b;
   sha256->h[2] += c;
   sha256->h[3] += d;
   sha256->h[4] += e;
   sha256->h[5] += f;
   sha256->h[6] += g;
   sha256->h[7] += h;
}
/*}}}*/

static void sha512_process_block (SLChksum_Type *sha512, unsigned char *buf) /*{{{*/
{
   unsigned int t;
#if _pSLANG_UINT64_TYPE
   _pSLuint64_Type a, b, c, d, e, f, g, h, t1, t2;
   _pSLuint64_Type w[80];

   for (t=0; t<16; t++)
     {
	w[t] = MAKE_LONG_WORD(buf);
	buf += 8;
     }

   for (t=16; t<80; t++)
     w[t] = SSIG1_64(w[t-2]) + w[t-7] + SSIG0_64(w[t-15]) + w[t-16];

   a = ((_pSLuint64_Type*)(sha512->h))[0];
   b = ((_pSLuint64_Type*)(sha512->h))[1];
   c = ((_pSLuint64_Type*)(sha512->h))[2];
   d = ((_pSLuint64_Type*)(sha512->h))[3];
   e = ((_pSLuint64_Type*)(sha512->h))[4];
   f = ((_pSLuint64_Type*)(sha512->h))[5];
   g = ((_pSLuint64_Type*)(sha512->h))[6];
   h = ((_pSLuint64_Type*)(sha512->h))[7];

   for (t=0; t<80; t++)
     {
	t1 = h + BSIG1_64(e) + CH(e, f, g) + SHA512_K[t] + w[t];
	t2 = BSIG0_64(a) + MAJ(a,b,c);
	h = g;
	g = f;
	f = e;
	e = d + t1;
	d = c;
	c = b;
	b = a;
	a = t1 + t2;
     }

   ((_pSLuint64_Type*)(sha512->h))[0] += a;
   ((_pSLuint64_Type*)(sha512->h))[1] += b;
   ((_pSLuint64_Type*)(sha512->h))[2] += c;
   ((_pSLuint64_Type*)(sha512->h))[3] += d;
   ((_pSLuint64_Type*)(sha512->h))[4] += e;
   ((_pSLuint64_Type*)(sha512->h))[5] += f;
   ((_pSLuint64_Type*)(sha512->h))[6] += g;
   ((_pSLuint64_Type*)(sha512->h))[7] += h;
#else /* !_pSLANG_UINT64_TYPE */
   _pSLuint32_Type a[2], b[2], c[2], d[2], e[2], f[2], g[2], h[2];
   _pSLuint32_Type t1[2], t2[2];
   _pSLuint32_Type w[80][2];
   _pSLuint32_Type _tmp1[2], _tmp2[2], _tmp3[2], r[2];
   _pSLuint32_Type (*ch)[2] = (_pSLuint32_Type (*)[2])(sha512->h);

   for (t=0; t<16; t++)
     {
	w[t][0] = MAKE_WORD(buf);
	w[t][1] = MAKE_WORD(buf+4);
	buf += 8;
     }

   for (t=16; t<80; t++)
     {
	SSIG1_64(w[t-2], _tmp1, _tmp2, _tmp3, r);
	w[t][0] = r[0]; w[t][1] = r[1];
	ADD_64(w[t-7], w[t], w[t]);
	SSIG0_64(w[t-15], _tmp1, _tmp2, _tmp3, r);
	ADD_64(r, w[t], w[t]);
	ADD_64(w[t-16], w[t], w[t]);
     }

   a[0] = ch[0][0]; a[1] = ch[0][1];
   b[0] = ch[1][0]; b[1] = ch[1][1];
   c[0] = ch[2][0]; c[1] = ch[2][1];
   d[0] = ch[3][0]; d[1] = ch[3][1];
   e[0] = ch[4][0]; e[1] = ch[4][1];
   f[0] = ch[5][0]; f[1] = ch[5][1];
   g[0] = ch[6][0]; g[1] = ch[6][1];
   h[0] = ch[7][0]; h[1] = ch[7][1];

   for (t=0; t<80; t++)
     {
	// t1 = h + BSIG1(e) + CH(e,f,g) + SHA512_K[t] + w[t]
	t1[0] = h[0]; t1[1] = h[1];
	BSIG1_64(e, _tmp1, _tmp2, _tmp3, r);
	ADD_64(r, t1, t1);
	CH_64(e, f, g, r);
	ADD_64(r, t1, t1);
	ADD_64(SHA512_K[t], t1, t1);
	ADD_64(w[t], t1, t1);

	// t2 = BSIG0(a) + MAJ(a,b,c)
	BSIG0_64(a, _tmp1, _tmp2, _tmp3, r);
	t2[0] = r[0]; t2[1] = r[1];
	MAJ_64(a, b, c, r);
	ADD_64(r, t2, t2);

	h[0] = g[0]; h[1] = g[1];
	g[0] = f[0]; g[1] = f[1];
	f[0] = e[0]; f[1] = e[1];
	e[0] = d[0]; e[1] = d[1];
	ADD_64(t1, e, e);
	d[0] = c[0]; d[1] = c[1];
	c[0] = b[0]; c[1] = b[1];
	b[0] = a[0]; b[1] = a[1];
	a[0] = t1[0]; a[1] = t1[1];
	ADD_64(t2, a, a);
     }

   ADD_64(a, ch[0], ch[0]);
   ADD_64(b, ch[1], ch[1]);
   ADD_64(c, ch[2], ch[2]);
   ADD_64(d, ch[3], ch[3]);
   ADD_64(e, ch[4], ch[4]);
   ADD_64(f, ch[5], ch[5]);
   ADD_64(g, ch[6], ch[6]);
   ADD_64(h, ch[7], ch[7]);
#endif /* !_pSLANG_UINT64_TYPE */
}
/*}}}*/

static int sha256_accumulate (SLChksum_Type *sha256, unsigned char *buf, unsigned int buflen) /*{{{*/
{
   unsigned int num_buffered;
   unsigned char *bufmax;

   if ((sha256 == NULL) || (buf == NULL))
     return -1;

   update_num_bits (sha256, buflen);

   num_buffered = sha256->num_buffered;

   if (num_buffered)
     {
	unsigned int dlen = sha256->buffer_size - sha256->num_buffered;

	if (buflen < dlen)
	  dlen = buflen;

	memcpy (sha256->buf+num_buffered, buf, dlen);
	num_buffered += dlen;
	buflen -= dlen;
	buf += dlen;

	if (num_buffered < sha256->buffer_size)
	  {
	     sha256->num_buffered = num_buffered;
	     return 0;
	  }

	sha256_process_block (sha256, sha256->buf);
	num_buffered = 0;
     }

   num_buffered = buflen % sha256->buffer_size;
   bufmax = buf + (buflen - num_buffered);
   while (buf < bufmax)
     {
	sha256_process_block (sha256, buf);
	buf += sha256->buffer_size;
     }

   if (num_buffered)
     memcpy (sha256->buf, bufmax, num_buffered);

   sha256->num_buffered = num_buffered;

   return 0;
}
/*}}}*/

static int sha512_accumulate (SLChksum_Type *sha512, unsigned char *buf, unsigned int buflen) /*{{{*/
{
   unsigned int num_buffered;
   unsigned char *bufmax;

   if ((sha512 == NULL) || (buf == NULL))
     return -1;

   update_num_bits_long (sha512, buflen);

   num_buffered = sha512->num_buffered;

   if (num_buffered)
     {
	unsigned int dlen = sha512->buffer_size - sha512->num_buffered;

	if (buflen < dlen)
	  dlen = buflen;

	memcpy (sha512->buf+num_buffered, buf, dlen);
	num_buffered += dlen;
	buflen -= dlen;
	buf += dlen;

	if (num_buffered < sha512->buffer_size)
	  {
	     sha512->num_buffered = num_buffered;
	     return 0;
	  }

	sha512_process_block (sha512, sha512->buf);
	num_buffered = 0;
     }

   num_buffered = buflen % sha512->buffer_size;
   bufmax = buf + (buflen - num_buffered);
   while (buf < bufmax)
     {
	sha512_process_block (sha512, buf);
	buf += sha512->buffer_size;
     }

   if (num_buffered)
     memcpy (sha512->buf, bufmax, num_buffered);

   sha512->num_buffered = num_buffered;

   return 0;
}
/*}}}*/

static void uint32_to_uchar (_pSLuint32_Type *u, unsigned int num, unsigned char *buf) /*{{{*/
{
   unsigned int i;

   for (i = 0; i < num; i++)
     {
	_pSLuint32_Type x = u[i];
	buf[3] = (unsigned char) (x & 0xFF);
	buf[2] = (unsigned char) ((x>>8) & 0xFF);
	buf[1] = (unsigned char) ((x>>16) & 0xFF);
	buf[0] = (unsigned char) ((x>>24) & 0xFF);
	buf += 4;
     }
}
/*}}}*/

static void uint64_to_uchar (_pSLuint32_Type *u, unsigned int num, unsigned char *buf) /*{{{*/
{
   unsigned int i;
#if _pSLANG_UINT64_TYPE
   _pSLuint64_Type *v = (_pSLuint64_Type*)u;

   for (i=0; i<num; i++)
     {
	_pSLuint64_Type x = v[i];
	buf[7] = (unsigned char)(x & 0xFF);
	buf[6] = (unsigned char)((x>>8) & 0xFF);
	buf[5] = (unsigned char)((x>>16) & 0xFF);
	buf[4] = (unsigned char)((x>>24) & 0xFF);

	buf[3] = (unsigned char)((x>>32) & 0xFF);
	buf[2] = (unsigned char)((x>>40) & 0xFF);
	buf[1] = (unsigned char)((x>>48) & 0xFF);
	buf[0] = (unsigned char)((x>>56) & 0xFF);

	buf += 8;
     }
#else /* !_pSLANG_UINT64_TYPE */
   _pSLuint32_Type (*v)[2] = (_pSLuint32_Type (*)[2])u;

   for (i=0; i<num; i++)
     {
	_pSLuint32_Type x[2];
	x[0] = v[i][0];
	x[1] = v[i][1];
	buf[7] = (unsigned char)(x[1] & 0xFF);
	buf[6] = (unsigned char)((x[1]>>8) & 0xFF);
	buf[5] = (unsigned char)((x[1]>>16) & 0xFF);
	buf[4] = (unsigned char)((x[1]>>24) & 0xFF);

	buf[3] = (unsigned char)(x[0] & 0xFF);
	buf[2] = (unsigned char)((x[0]>>8) & 0xFF);
	buf[1] = (unsigned char)((x[0]>>16) & 0xFF);
	buf[0] = (unsigned char)((x[0]>>24) & 0xFF);

	buf += 8;
     }
#endif /* _pSLANG_UINT64_TYPE */
}
/*}}}*/

static int sha256_close (SLChksum_Type *sha256, unsigned char *digest, int just_free) /*{{{*/
{
   unsigned char num_bits_buf[8];

   if (sha256 == NULL)
     return -1;

   if ((digest != NULL) && (just_free == 0))
     {
	/* Handle num bits before padding */
	uint32_to_uchar (sha256->num_bits, 2, num_bits_buf);

	/* Add pad and num_bits bytes */
	(void) sha256_accumulate (sha256, Pad_Bytes, compute_64b_pad_length (sha256->num_buffered));
	(void) sha256_accumulate (sha256, num_bits_buf, 8);
	uint32_to_uchar(sha256->h, sha256->bitsize/32, digest);
     }

   // clear it to not leave sensitive data long lived
   memset(sha256->buf, 0, sha256->buffer_size);

   SLfree((char*)(sha256->buf));
   SLfree((char*)(sha256->h));
   SLfree ((char *)sha256);
   return 0;
}
/*}}}*/

static int sha512_close (SLChksum_Type *sha512, unsigned char *digest, int just_free) /*{{{*/
{
   unsigned char num_bits_buf[16];

   if (sha512 == NULL)
     return -1;

   if ((digest != NULL) && (just_free == 0))
     {
	/* Handle num bits before padding */
	uint64_to_uchar (sha512->num_bits, 2, num_bits_buf);

	/* Add pad and num_bits bytes */
	(void) sha512_accumulate (sha512, Pad_Bytes, compute_128b_pad_length (sha512->num_buffered));
	(void) sha512_accumulate (sha512, num_bits_buf, 16);
	uint64_to_uchar(sha512->h, sha512->bitsize/64, digest);
     }

   /* clear it to not leave sensitive data long lived */
   memset(sha512->buf, 0, sha512->buffer_size);

   SLfree((char*)(sha512->buf));
   SLfree((char*)(sha512->h));
   SLfree ((char *)sha512);
   return 0;
}
/*}}}*/

SLChksum_Type *_pSLchksum_sha256_new (char *name) /*{{{*/
{
   SLChksum_Type *sha256;

   if (NULL == (sha256 = (SLChksum_Type *)SLmalloc (sizeof (SLChksum_Type))))
     return NULL;

   memset ((char *)sha256, 0, sizeof (SLChksum_Type));

   sha256->accumulate = sha256_accumulate;
   sha256->close = sha256_close;

   if (0 == strcmp(name, "sha256"))
     {
	if (init_sha256_object(sha256))
	  goto error_return;
     }
   else if (0 == strcmp(name, "sha224"))
     {
	if (init_sha224_object(sha256))
	  goto error_return;
     }
   else
     goto error_return;

   return sha256;

error_return:
   SLfree((char*)(sha256->h));
   SLfree((char*)(sha256->buf));
   SLfree((char*)sha256);

   return NULL;
}
/*}}}*/

SLChksum_Type *_pSLchksum_sha512_new (char *name) /*{{{*/
{
   SLChksum_Type *sha512;

   if (NULL == (sha512 = (SLChksum_Type *)SLmalloc (sizeof (SLChksum_Type))))
     return NULL;

   memset ((char *)sha512, 0, sizeof (SLChksum_Type));

   sha512->accumulate = sha512_accumulate;
   sha512->close = sha512_close;

   if (0 == strcmp(name, "sha512"))
     {
	if (init_sha512_object(sha512))
	  goto error_return;
     }
   else if (0 == strcmp(name, "sha384"))
     {
	if (init_sha384_object(sha512))
	  goto error_return;
     }
   else
     goto error_return;

   return sha512;

error_return:
   SLfree((char*)(sha512->h));
   SLfree((char*)(sha512->buf));
   SLfree((char*)sha512);

   return NULL;
}
/*}}}*/
