/* This module implements an interface to posix system calls */
/* file stdio intrinsics for S-Lang */
/*
Copyright (C) 2004, 2005, 2006 John E. Davis

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

#if defined(__unix__) || (defined (__os2__) && defined (__EMX__))
# include <sys/types.h>
#endif

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif
#ifdef HAVE_SYS_FCNTL_H
# include <sys/fcntl.h>
#endif

#ifdef __unix__
# include <sys/file.h>
#endif

#ifdef HAVE_IO_H
# include <io.h>
#endif

#if defined(__BORLANDC__)
# include <dir.h>
#endif

#if defined(__DECC) && defined(VMS)
# include <unixio.h>
# include <unixlib.h>
#endif

#ifdef VMS
# include <stat.h>
#else
# include <sys/stat.h>
#endif

#include <errno.h>

#include "slang.h"
#include "_slang.h"

struct _pSLFile_FD_Type
{
   char *name;
   unsigned int num_refs;	       /* reference counting */
   int fd;
   SLang_MMT_Type *stdio_mmt;	       /* fdopen'd stdio object */

   /* methods */
   int (*close)(int);
   int (*read) (int, char *, unsigned int *);
   int (*write)(int, char *, unsigned int *);
};


static int is_interrupt (int e)
{
#ifdef EINTR
   if (e == EINTR)
     {
	if (0 == SLang_handle_interrupt ())
	  return 1;
     }
#endif
#ifdef EAGAIN
   if (e == EAGAIN)
     {
	if (0 == SLang_handle_interrupt ())
	  return 1;
     }
#endif
   return 0;
}
	

static int close_method (int fd)
{
   return close (fd);
}

static int write_method (int fd, char *buf, unsigned int *nump)
{
   int num;

   if (-1 == (num = write (fd, buf, *nump)))
     {
	*nump = 0;
	return -1;
     }

   *nump = (unsigned int) num;
   return 0;
}

static int read_method (int fd, char *buf, unsigned int *nump)
{
   int num;

   num = read (fd, buf, *nump);
   if (num == -1)
     {
	*nump = 0;
	return -1;
     }
   *nump = (unsigned int) num;
   return 0;
}

static int check_fd (int fd)
{
   if (fd == -1)
     {
#ifdef EBADF
	_pSLerrno_errno = EBADF;
#endif
	return -1;
     }

   return 0;
}

static int posix_close (SLFile_FD_Type *f)
{
   if (-1 == check_fd (f->fd))
     return -1;

   if (f->close != NULL)
     {
	while (-1 == f->close (f->fd))
	  {
	     if (is_interrupt (errno))
	       continue;

	     _pSLerrno_errno = errno;
	     return -1;
	  }
     }

   if (f->stdio_mmt != NULL)
     {
	SLang_free_mmt (f->stdio_mmt);
	f->stdio_mmt = NULL;
     }

   f->fd = -1;
   return 0;
}

/* Usage: Uint write (f, buf); */
static void posix_write (SLFile_FD_Type *f, SLang_BString_Type *bstr)
{
   unsigned int len;
   char *p;

   if ((-1 == check_fd (f->fd))
       || (NULL == (p = (char *)SLbstring_get_pointer (bstr, &len))))
     {
	SLang_push_integer (-1);
	return;
     }

   while (-1 == f->write (f->fd, p, &len))
     {
	if (is_interrupt (errno))
	  continue;

	_pSLerrno_errno = errno;
	SLang_push_integer (-1);
	return;
     }

   (void) SLang_push_uinteger (len);
}

/* Usage: nn = read (f, &buf, n); */
static void posix_read (SLFile_FD_Type *f, SLang_Ref_Type *ref, unsigned int *nbytes)
{
   unsigned int len;
   char *b;
   SLang_BString_Type *bstr;

   b = NULL;

   len = *nbytes;
   if ((-1 == check_fd (f->fd))
       || (NULL == (b = SLmalloc (len + 1))))
     goto return_error;
   
   while (-1 == f->read (f->fd, b, &len))
     {
	if (is_interrupt (errno))
	  continue;

	_pSLerrno_errno = errno;
	goto return_error;
     }

   if (len != *nbytes)
     {
	char *b1 = SLrealloc (b, len + 1);
	if (b1 == NULL)
	  goto return_error;
	b = b1;
     }

   bstr = SLbstring_create_malloced ((unsigned char *) b, len, 0);
   if (bstr != NULL)
     {	
	if (-1 == SLang_assign_to_ref (ref, SLANG_BSTRING_TYPE, (VOID_STAR)&bstr))
	  {
	     SLbstring_free (bstr);
	     return;
	  }
	SLbstring_free (bstr);
	(void) SLang_push_uinteger (len);
	return;
     }
   
   return_error:
   if (b != NULL) SLfree ((char *)b);
   (void) SLang_assign_to_ref (ref, SLANG_NULL_TYPE, NULL);
   (void) SLang_push_integer (-1);
}

SLFile_FD_Type *SLfile_create_fd (char *name, int fd)
{
   SLFile_FD_Type *f;

   if (NULL == (f = (SLFile_FD_Type *) SLmalloc (sizeof (SLFile_FD_Type))))
     return NULL;

   memset ((char *) f, 0, sizeof (SLFile_FD_Type));
   if (NULL == (f->name = SLang_create_slstring (name)))
     {
	SLfree ((char *)f);
	return NULL;
     }

   f->fd = fd;
   f->num_refs = 1;

   f->close = close_method;
   f->read = read_method;
   f->write = write_method;

   return f;
}

SLFile_FD_Type *SLfile_dup_fd (SLFile_FD_Type *f0)
{
   SLFile_FD_Type *f;
   int fd0, fd;

   if (f0 == NULL)
     return NULL;
   fd0 = f0->fd;
   if (-1 == check_fd (fd0))
     return NULL;

   while (-1 == (fd = dup (fd0)))
     {
	if (is_interrupt (errno))
	  continue;

	_pSLerrno_errno = errno;
	return NULL;
     }
   
   if (NULL == (f = SLfile_create_fd (f0->name, fd)))
     {
	f0->close (fd);
	return NULL;
     }
   
   return f;
}

int SLfile_get_fd (SLFile_FD_Type *f, int *fd)
{
   if (f == NULL)
     return -1;
   
   *fd = f->fd;
   if (-1 == check_fd (*fd))
     return -1;

   return 0;
}

void SLfile_free_fd (SLFile_FD_Type *f)
{
   if (f == NULL)
     return;

   if (f->num_refs > 1)
     {
	f->num_refs -= 1;
	return;
     }

   if (f->fd != -1)
     {
	if (f->close != NULL)
	  {
	     while ((-1 == f->close (f->fd))
		    && is_interrupt (errno))
	       ;
	  }
	f->fd = -1;
     }

   if (f->stdio_mmt != NULL)
     SLang_free_mmt (f->stdio_mmt);

   SLfree ((char *) f);
}

static int pop_string_int (char **s, int *i)
{
   *s = NULL;
   if ((-1 == SLang_pop_integer (i))
       || (-1 == SLang_pop_slstring (s)))
     return -1;

   return 0;
}

static int pop_string_int_int (char **s, int *a, int *b)
{
   *s = NULL;
   if ((-1 == SLang_pop_integer (b))
       || (-1 == pop_string_int (s, a)))
     return -1;

   return 0;
}

static void posix_open (void)
{
   char *file;
   int mode, flags;
   SLFile_FD_Type *f;

   switch (SLang_Num_Function_Args)
     {
      case 3:
	if (-1 == pop_string_int_int (&file, &flags, &mode))
	  {
	     SLang_push_null ();
	     return;
	  }
	break;

      case 2:
      default:
	if (-1 == pop_string_int (&file, &flags))
	  return;
	mode = 0777;
	break;
     }

   f = SLfile_create_fd (file, -1);
   if (f == NULL)
     {
	SLang_free_slstring (file);
	SLang_push_null ();
	return;
     }
   SLang_free_slstring (file);

   while (-1 == (f->fd = open (f->name, flags, mode)))
     {
	if (is_interrupt (errno))
	  continue;

	_pSLerrno_errno = errno;
	SLfile_free_fd (f);
	SLang_push_null ();
	return;
     }

   if (-1 == SLfile_push_fd (f))
     SLang_push_null ();
   SLfile_free_fd (f);
}

static void posix_fileno (void)
{
   FILE *fp;
   SLang_MMT_Type *mmt;
   int fd;
   SLFile_FD_Type *f;
   char *name;

   if (-1 == SLang_pop_fileptr (&mmt, &fp))
     {
	SLang_push_null ();
	return;
     }
   name = SLang_get_name_from_fileptr (mmt);
   fd = fileno (fp);

   f = SLfile_create_fd (name, fd);
   if (f != NULL)
     f->close = NULL;		       /* prevent fd from being closed 
					* when it goes out of scope
					*/
   SLang_free_mmt (mmt);

   if (-1 == SLfile_push_fd (f))
     SLang_push_null ();
   SLfile_free_fd (f);
}

static void posix_fdopen (SLFile_FD_Type *f, char *mode)
{
   if (f->stdio_mmt == NULL)
     {
	if (-1 == _pSLstdio_fdopen (f->name, f->fd, mode))
	  return;

	if (NULL == (f->stdio_mmt = SLang_pop_mmt (SLANG_FILE_PTR_TYPE)))
	  return;
     }

   (void) SLang_push_mmt (f->stdio_mmt);
}

static _pSLc_off_t_Type posix_lseek (SLFile_FD_Type *f, _pSLc_off_t_Type *ofs, int *whence)
{
   _pSLc_off_t_Type status;
   
   while (-1 == (status = lseek (f->fd, *ofs, *whence)))
     {
	if (is_interrupt (errno))
	  continue;

	_pSLerrno_errno = errno;
	return -1;
     }

   return status;
}

static int posix_isatty (void)
{
   int ret;
   SLFile_FD_Type *f;

   if (SLang_peek_at_stack () == SLANG_FILE_PTR_TYPE)
     {
	SLang_MMT_Type *mmt;
	FILE *fp;

	if (-1 == SLang_pop_fileptr (&mmt, &fp))
	  return 0;		       /* invalid descriptor */

	ret = isatty (fileno (fp));
	SLang_free_mmt (mmt);
	return ret;
     }

   if (-1 == SLfile_pop_fd (&f))
     return 0;

   ret = isatty (f->fd);
   SLfile_free_fd (f);

   return ret;
}

static void posix_dup (SLFile_FD_Type *f)
{
   if ((NULL == (f = SLfile_dup_fd (f)))
       || (-1 == SLfile_push_fd (f)))
     SLang_push_null ();
   
   SLfile_free_fd (f);
}
	
#define I SLANG_INT_TYPE
#define V SLANG_VOID_TYPE
#define F SLANG_FILE_FD_TYPE
#define B SLANG_BSTRING_TYPE
#define R SLANG_REF_TYPE
#define U SLANG_UINT_TYPE
#define S SLANG_STRING_TYPE
#define L SLANG_LONG_TYPE
static SLang_Intrin_Fun_Type Fd_Name_Table [] =
{
   MAKE_INTRINSIC_0("fileno", posix_fileno, V),
   MAKE_INTRINSIC_0("isatty", posix_isatty, I),
   MAKE_INTRINSIC_0("open", posix_open, V),
   MAKE_INTRINSIC_3("read", posix_read, V, F, R, U),
   MAKE_INTRINSIC_3("lseek", posix_lseek, SLANG_C_OFF_T_TYPE, F, SLANG_C_OFF_T_TYPE, I),
   MAKE_INTRINSIC_2("fdopen", posix_fdopen, V, F, S),
   MAKE_INTRINSIC_2("write", posix_write, V, F, B),
   MAKE_INTRINSIC_1("dup_fd", posix_dup, V, F),
   MAKE_INTRINSIC_1("close", posix_close, I, F),
   SLANG_END_INTRIN_FUN_TABLE
};
#undef I
#undef V
#undef F
#undef B
#undef R
#undef S
#undef L
#undef U

static SLang_IConstant_Type PosixIO_Consts [] =
{
#ifdef O_RDONLY
   MAKE_ICONSTANT("O_RDONLY", O_RDONLY),
#endif
#ifdef O_WRONLY
   MAKE_ICONSTANT("O_WRONLY", O_WRONLY),
#endif
#ifdef O_RDWR
   MAKE_ICONSTANT("O_RDWR", O_RDWR),
#endif
#ifdef O_APPEND
   MAKE_ICONSTANT("O_APPEND", O_APPEND),
#endif
#ifdef O_CREAT
   MAKE_ICONSTANT("O_CREAT", O_CREAT),
#endif
#ifdef O_EXCL
   MAKE_ICONSTANT("O_EXCL", O_EXCL),
#endif
#ifdef O_NOCTTY
   MAKE_ICONSTANT("O_NOCTTY", O_NOCTTY),
#endif
#ifdef O_NONBLOCK
   MAKE_ICONSTANT("O_NONBLOCK", O_NONBLOCK),
#endif
#ifdef O_TRUNC
   MAKE_ICONSTANT("O_TRUNC", O_TRUNC),
#endif
#ifndef O_BINARY
# define O_BINARY 0
#endif
   MAKE_ICONSTANT("O_BINARY", O_BINARY),
#ifndef O_TEXT
# define O_TEXT 0
#endif
   MAKE_ICONSTANT("O_TEXT", O_TEXT),

   SLANG_END_ICONST_TABLE
};

int SLfile_push_fd (SLFile_FD_Type *f)
{
   if (f == NULL)
     return SLang_push_null ();

   f->num_refs += 1;

   if (0 == SLclass_push_ptr_obj (SLANG_FILE_FD_TYPE, (VOID_STAR) f))
     return 0;

   f->num_refs -= 1;

   return -1;
}

int SLfile_pop_fd (SLFile_FD_Type **f)
{
   return SLclass_pop_ptr_obj (SLANG_FILE_FD_TYPE, (VOID_STAR *) f);
}

static void destroy_fd_type (SLtype type, VOID_STAR ptr)
{
   (void) type;
   SLfile_free_fd (*(SLFile_FD_Type **) ptr);
}

static int fd_push (SLtype type, VOID_STAR v)
{
   (void) type;
   return SLfile_push_fd (*(SLFile_FD_Type **)v);
}

int SLang_init_posix_io (void)
{
   SLang_Class_Type *cl;

   if (NULL == (cl = SLclass_allocate_class ("FD_Type")))
     return -1;
   cl->cl_destroy = destroy_fd_type;
   (void) SLclass_set_push_function (cl, fd_push);

   if (-1 == SLclass_register_class (cl, SLANG_FILE_FD_TYPE, sizeof (SLFile_FD_Type), SLANG_CLASS_TYPE_PTR))
     return -1;

   if ((-1 == SLadd_intrin_fun_table(Fd_Name_Table, "__POSIXIO__"))
       || (-1 == SLadd_iconstant_table (PosixIO_Consts, NULL))
       || (-1 == _pSLerrno_init ()))
     return -1;

   return 0;
}

