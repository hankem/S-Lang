/*
Copyright (C) 2019-2021,2022 John E. Davis

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
#include "config.h"
#include <string.h>
#include <limits.h>
#include <slang.h>
#include <stdint.h>

#define CHKSUM_TYPE_PRIVATE_FIELDS \
   void *vlookup_table; \
   int refin, refout; \
   unsigned int seed; \
   unsigned int poly; \
   unsigned int xorout;

#include "chksum.h"

#define SLang_push_uint16 SLang_push_ushort
#define SLang_push_uint32 SLang_push_uint

static unsigned char Byte_Reflect[256];
static unsigned int reflect_bits (unsigned int val, unsigned int nbits)
{
   unsigned int i;
   unsigned int r = 0, s;

   s = (1 << (nbits-1));
   for (i = 0; i < nbits; i++)
     {
        if (val & 0x00000001)
	  r |= s;
	val = val >> 1;
	s = s >> 1;
     }
   return r;
}

static void make_byte_reflect_table (void)
{
   static int inited = 0;
   unsigned int i;

   if (inited) return;

   for (i = 0; i < 256; i++)
     Byte_Reflect[i] = (unsigned char) reflect_bits (i, 8);

   inited = 1;
}

typedef struct CRC8_Table_Type_
{
   struct CRC8_Table_Type_ *next;
   unsigned int poly;
   unsigned char lookup_table[256];
}
CRC8_Table_Type;
static CRC8_Table_Type *CRC8_Table_List;

static unsigned char *get_crc8_table (unsigned char poly)
{
   CRC8_Table_Type *list;
   unsigned char *lookup_table;
   unsigned int i;

   list = CRC8_Table_List;

   while (list != NULL)
     {
	if (list->poly == poly)
	  return list->lookup_table;
	list = list->next;
     }
   list = (CRC8_Table_Type *)SLmalloc(sizeof(CRC8_Table_Type));
   if (list == NULL) return NULL;

   list->poly = poly;
   list->next = CRC8_Table_List;
   CRC8_Table_List = list;

   lookup_table = list->lookup_table;
   for (i = 0; i < 256; i++)
     {
	unsigned int j;
	unsigned char crc;

	crc = i;
	for (j = 0; j < 8; j++)
	  {
	     if (crc & 0x80)
	       crc = (crc << 1)^poly;
	     else
	       crc = crc << 1;
	  }
	lookup_table[i] = crc;
     }
   return lookup_table;
}

static int crc8_accumulate (SLChksum_Type *cs, unsigned char *buf, unsigned int buflen)
{
   unsigned char *lookup_table;
   unsigned int i;
   unsigned char crc;

   lookup_table = (unsigned char *)cs->vlookup_table;
   crc = cs->seed;

   if (cs->refin)
     {
	for (i = 0; i < buflen; i++)
	  crc = lookup_table[crc ^ Byte_Reflect[buf[i]]];
     }
   else
     {
	for (i = 0; i < buflen; i++)
	  crc = lookup_table[crc ^ buf[i]];
     }
   cs->seed = crc;
   return 0;
}

static int crc8_close (SLChksum_Type *cs, unsigned char *digest, int just_free)
{
   unsigned char crc;

   if (cs == NULL)
     return -1;

   (void) digest;

   if (just_free)
     {
	SLfree ((char *) cs);
	return 0;
     }

   crc = (unsigned char) cs->seed & 0xFF;
   if (cs->refout)
     crc = Byte_Reflect[crc];
   crc = (crc ^ cs->xorout) & 0xFF;

   SLfree ((char *)cs);
   return SLang_push_uchar (crc);
}

typedef struct CRC16_Table_Type_
{
   struct CRC16_Table_Type_ *next;
   unsigned int poly;
   uint16_t lookup_table[256];
}
CRC16_Table_Type;
static CRC16_Table_Type *CRC16_Table_List;

static uint16_t *get_crc16_table (uint16_t poly)
{
   CRC16_Table_Type *list;
   uint16_t *lookup_table;
   unsigned int i;

   list = CRC16_Table_List;
   while (list != NULL)
     {
	if (list->poly == poly)
	  return list->lookup_table;
	list = list->next;
     }
   list = (CRC16_Table_Type *)SLmalloc(sizeof(CRC16_Table_Type));
   if (list == NULL) return NULL;

   list->poly = poly;
   list->next = CRC16_Table_List;
   CRC16_Table_List = list;

   lookup_table = list->lookup_table;
   for (i = 0; i < 256; i++)
     {
	unsigned int j;
	uint16_t crc;

	crc = i << 8;
	for (j = 0; j < 8; j++)
	  {
	     if (crc & 0x8000)
	       crc = (crc << 1)^poly;
	     else
	       crc = crc << 1;
	  }
	lookup_table[i] = crc;
     }
   return lookup_table;
}

static int crc16_accumulate (SLChksum_Type *cs, unsigned char *buf, unsigned int buflen)
{
   uint16_t *lookup_table;
   unsigned int i;
   uint16_t crc;

   lookup_table = (uint16_t *)cs->vlookup_table;
   crc = (uint16_t)cs->seed;

   if (cs->refin)
     {
	for (i = 0; i < buflen; i++)
	  {
	     unsigned int j = Byte_Reflect[buf[i]] ^ (crc>>8);
	     crc = lookup_table[j] ^ (crc<<8);
	  }
     }
   else
     {
	for (i = 0; i < buflen; i++)
	  {
	     unsigned int j = buf[i] ^ (crc>>8);
	     crc = lookup_table[j] ^ (crc<<8);
	  }
     }
   cs->seed = crc;
   return 0;
}

static int crc16_close (SLChksum_Type *cs, unsigned char *digest, int just_free)
{
   uint16_t crc;

   (void) digest;
   if (cs == NULL)
     return -1;

   if (just_free)
     {
	SLfree ((char *) cs);
	return 0;
     }

   crc = cs->seed & 0xFFFF;
   if (cs->refout)
     crc = reflect_bits (crc, 16);
   crc = (crc ^ cs->xorout) & 0xFFFF;

   SLfree ((char *)cs);
   return SLang_push_uint16 (crc);
}

typedef struct CRC32_Table_Type_
{
   struct CRC32_Table_Type_ *next;
   unsigned int poly;
   uint32_t lookup_table[256];
}
CRC32_Table_Type;
static CRC32_Table_Type *CRC32_Table_List;


static uint32_t *get_crc32_table (uint32_t poly)
{
   CRC32_Table_Type *list;
   uint32_t *lookup_table;
   unsigned int i;

   list = CRC32_Table_List;
   while (list != NULL)
     {
	if (list->poly == poly)
	  return list->lookup_table;
	list = list->next;
     }
   list = (CRC32_Table_Type *)SLmalloc(sizeof(CRC32_Table_Type));
   if (list == NULL) return NULL;

   list->poly = poly;
   list->next = CRC32_Table_List;
   CRC32_Table_List = list;

   lookup_table = list->lookup_table;
   for (i = 0; i < 256; i++)
     {
	unsigned int j;
	uint32_t crc;

	crc = i << 24;
	for (j = 0; j < 8; j++)
	  {
	     if (crc & 0x80000000U)
	       crc = (crc << 1)^poly;
	     else
	       crc = crc << 1;
	  }
	lookup_table[i] = crc;
     }
   return lookup_table;
}

static int crc32_accumulate (SLChksum_Type *cs, unsigned char *buf, unsigned int buflen)
{
   uint32_t *lookup_table;
   unsigned int i;
   uint32_t crc;

   lookup_table = (uint32_t *)cs->vlookup_table;
   crc = (uint32_t)cs->seed;

   if (cs->refin)
     {
	for (i = 0; i < buflen; i++)
	  {
	     unsigned int j = Byte_Reflect[buf[i]] ^ (crc>>24);
	     crc = lookup_table[j] ^ (crc<<8);
	  }
     }
   else
     {
	for (i = 0; i < buflen; i++)
	  {
	     unsigned int j = buf[i] ^ (crc>>24);
	     crc = lookup_table[j] ^ (crc<<8);
	  }
     }
   cs->seed = crc;
   return 0;
}

static int crc32_close (SLChksum_Type *cs, unsigned char *digest, int just_free)
{
   uint32_t crc;

   (void) digest;
   if (cs == NULL)
     return -1;

   if (just_free)
     {
	SLfree ((char *) cs);
	return 0;
     }

   crc = cs->seed & 0xFFFFFFFFU;
   if (cs->refout)
     crc = reflect_bits (crc, 32);
   crc = (crc ^ cs->xorout) & 0xFFFFFFFFU;

   SLfree ((char *)cs);
   return SLang_push_uint32 (crc);
}

static SLChksum_Type *
chksum_crcxx_new (unsigned int defpoly, unsigned int mask)
{
   SLChksum_Type *cs;
   unsigned int poly, seed, xorout;
   int refin, refout;

   make_byte_reflect_table ();

   if (-1 == SLang_get_int_qualifier ("refin", &refin, 0))
     return NULL;

   if (-1 == SLang_get_int_qualifier ("refout", &refout, 0))
     return NULL;

   if (-1 == SLang_get_int_qualifier ("xorout", (int *)&xorout, 0))
     return NULL;

   if (-1 == SLang_get_int_qualifier ("seed", (int *)&seed, 0))
     return NULL;

   if (-1 == SLang_get_int_qualifier ("poly", (int *)&poly, defpoly))
     return NULL;

   cs = (SLChksum_Type *)SLmalloc (sizeof (SLChksum_Type));
   if (cs == NULL)
     return NULL;
   memset ((char *)cs, 0, sizeof (SLChksum_Type));

   cs->refin = refin;
   cs->refout = refout;
   cs->xorout = xorout & mask;
   cs->seed = seed & mask;
   cs->poly = poly & mask;
   cs->close_will_push = 1;

   return cs;
}

SLChksum_Type *_pSLchksum_crc8_new (char *name)
{
   SLChksum_Type *cs;

   (void) name;
   if (NULL == (cs = chksum_crcxx_new (0x07, 0xFF)))
     return NULL;

   cs->accumulate = crc8_accumulate;
   cs->close = crc8_close;
   cs->digest_len = 1;
   cs->buffer_size = 0;

   if (NULL == (cs->vlookup_table = get_crc8_table (cs->poly)))
     {
	SLfree ((char *)cs);
	return NULL;
     }
   return cs;
}

SLChksum_Type *_pSLchksum_crc16_new (char *name)
{
   SLChksum_Type *cs;

   (void) name;
   if (NULL == (cs = chksum_crcxx_new (0x1021, 0xFFFF)))
     return NULL;

   cs->accumulate = crc16_accumulate;
   cs->close = crc16_close;
   cs->digest_len = 2;
   cs->buffer_size = 0;

   if (NULL == (cs->vlookup_table = get_crc16_table (cs->poly)))
     {
	SLfree ((char *)cs);
	return NULL;
     }
   return cs;
}

SLChksum_Type *_pSLchksum_crc32_new (char *name)
{
   SLChksum_Type *cs;

   (void) name;
   if (NULL == (cs = chksum_crcxx_new (0x814141ABU, 0xFFFFFFFFU)))
     return NULL;

   cs->accumulate = crc32_accumulate;
   cs->close = crc32_close;
   cs->digest_len = 4;
   cs->buffer_size = 0;

   if (NULL == (cs->vlookup_table = get_crc32_table (cs->poly)))
     {
	SLfree ((char *)cs);
	return NULL;
     }
   return cs;
}

