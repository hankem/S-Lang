/* Copyright (c) 2001 John E. Davis
 * This file is part of the S-Lang library.
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Perl Artistic License.
 */

#include <stdio.h>
#include <slang.h>

#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>

SLANG_MODULE(fcntl);

static int check_and_set_errno (int e)
{
#ifdef EINTR
   if (e == EINTR)
     return 0;
#endif
   (void) SLerrno_set_errno (e);
   return -1;
}

static int do_fcntl_2 (SLFile_FD_Type *f, int cmd)
{
   int ret;
   int fd;

   if (-1 == SLfile_get_fd (f, &fd))
     return -1;
     
   while ((-1 == (ret = fcntl (fd, cmd)))
	  && (0 == check_and_set_errno (errno)))
     ;
   
   return ret;
}

static int do_fcntl_3_int (SLFile_FD_Type *f, int cmd, int flags)
{
   int ret;
   int fd;
   
      
   if (-1 == SLfile_get_fd (f, &fd))
     return -1;

   while ((-1 == (ret = fcntl (fd, cmd, flags)))
	  && (0 == check_and_set_errno (errno)))
     ;
   
   return ret;
}
   
static int fcntl_getfd (SLFile_FD_Type *f)
{
   return do_fcntl_2 (f, F_GETFD);
}

static int fcntl_setfd (SLFile_FD_Type *f, int *flags)
{
   return do_fcntl_3_int (f, F_SETFD, *flags);
}

static int fcntl_getfl (SLFile_FD_Type *f)
{   
   return do_fcntl_2 (f, F_GETFL);
}

static int fcntl_setfl (SLFile_FD_Type *f, int *flags)
{
   return do_fcntl_3_int (f, F_SETFL, *flags);
}

#define F SLANG_FILE_FD_TYPE
#define I SLANG_INT_TYPE
static SLang_Intrin_Fun_Type Fcntl_Intrinsics [] =
{
   MAKE_INTRINSIC_1("fcntl_getfd", fcntl_getfd, I, F),
   MAKE_INTRINSIC_2("fcntl_setfd", fcntl_setfd, I, F, I),
   MAKE_INTRINSIC_1("fcntl_getfl", fcntl_getfl, I, F),
   MAKE_INTRINSIC_2("fcntl_setfl", fcntl_setfl, I, F, I),

   SLANG_END_INTRIN_FUN_TABLE
};
#undef I
#undef F

static SLang_IConstant_Type Fcntl_Consts [] =
{
   MAKE_ICONSTANT("FD_CLOEXEC", FD_CLOEXEC),
   SLANG_END_ICONST_TABLE
};

int init_fcntl_module_ns (char *ns_name)
{
   SLang_NameSpace_Type *ns;
   
   ns = SLns_create_namespace (ns_name);
   if (ns == NULL)
     return -1;

   if ((-1 == SLns_add_intrin_fun_table (ns, Fcntl_Intrinsics, "__FCNTL__"))
       || (-1 == SLns_add_iconstant_table (ns, Fcntl_Consts, NULL)))
     return -1;

   return 0;
}

/* This function is optional */
void deinit_fcntl_module (void)
{
}
