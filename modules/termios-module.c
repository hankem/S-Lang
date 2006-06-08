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
#include <termios.h>
#include <errno.h>

SLANG_MODULE(termios);

static int Termios_Type_Id = 0;

static int check_and_set_errno (int e)
{
#ifdef EINTR
   if (e == EINTR)
     return 0;
#endif
   (void) SLerrno_set_errno (e);
   return -1;
}

static int do_syscall_0 (int (*fun)(int), SLFile_FD_Type *f)
{
   int fd;
   int ret;

   if (-1 == SLfile_get_fd (f, &fd))
     return -1;
   
   while ((-1 == (ret = (*fun) (fd)))
	  && (0 == check_and_set_errno (errno)))
     ;
   
   return ret;
}

static int do_syscall_1 (int (*fun)(int, int), SLFile_FD_Type *f, int arg)
{
   int fd;
   int ret;

   if (-1 == SLfile_get_fd (f, &fd))
     return -1;
   
   while ((-1 == (ret = (*fun) (fd, arg)))
	  && (0 == check_and_set_errno (errno)))
     ;
   
   return ret;
}

static int do_syscall_struct_1 (int (*fun)(int, void *), SLFile_FD_Type *f, void *v)
{
   int fd;
   int ret;

   if (-1 == SLfile_get_fd (f, &fd))
     return -1;
   
   while ((-1 == (ret = (*fun) (fd, v)))
	  && (0 == check_and_set_errno (errno)))
     ;
   
   return ret;
}

static int do_syscall_struct_2 (int (*fun)(int, int, void *), SLFile_FD_Type *f, int i, void *v)
{
   int fd;
   int ret;

   if (-1 == SLfile_get_fd (f, &fd))
     return -1;
   
   while ((-1 == (ret = (*fun) (fd, i, v)))
	  && (0 == check_and_set_errno (errno)))
     ;
   
   return ret;
}

#define DO_SYSCALL_0(fun, f) do_syscall_0((int(*)(int))(fun),(f))
#define DO_SYSCALL_1(fun, f, i) do_syscall_1((int(*)(int,int))(fun),(f),(i))
#define DO_SYSCALL_STRUCT_1(fun, f, s) \
     do_syscall_struct_1((int(*)(int, void*))(fun), (f), (void*)(s))
#define DO_SYSCALL_STRUCT_2(fun, f, i, s) \
     do_syscall_struct_2((int(*)(int, int, void*))(fun), (f), (i), (void*)(s))


static int tcdrain_intrin (SLFile_FD_Type *f)
{
   return DO_SYSCALL_0 (tcdrain, f);
}

static int tcflow_intrin (SLFile_FD_Type *f, int *action)
{
   return DO_SYSCALL_1 (tcflow, f, *action);
}

static int tcflush_intrin (SLFile_FD_Type *f, int *action)
{
   return DO_SYSCALL_1 (tcflush, f, *action);
}

static int tcgetpgrp_intrin (SLFile_FD_Type *f)
{
   return DO_SYSCALL_0 (tcgetpgrp, f);
}

static int tcsetpgrp_intrin (SLFile_FD_Type *f, int *id)
{
   return DO_SYSCALL_1 (tcgetpgrp, f, *id);
}

static int tcsendbreak_intrin (SLFile_FD_Type *f, int *action)
{
   return DO_SYSCALL_1 (tcsendbreak, f, *action);
}

static void destroy_termios (SLtype type, VOID_STAR f)
{
   (void) type;
   SLfree ((char *) f);
}

static SLang_MMT_Type *allocate_termios (struct termios *s)
{
   struct termios *s1;
   SLang_MMT_Type *mmt;

   s1 = (struct termios *) SLmalloc (sizeof (struct termios));
   if (s1 == NULL)
     return NULL;
   
   memcpy (s1, s, sizeof (struct termios));
   if (NULL == (mmt = SLang_create_mmt (Termios_Type_Id, (VOID_STAR) s1)))
     SLfree ((char *) s1);
   return mmt;
}

static void tcgetattr_intrin (SLFile_FD_Type *f)
{
   struct termios s;
   SLang_MMT_Type *mmt;

   if (-1 == DO_SYSCALL_STRUCT_1(tcgetattr,f,&s))
     {
	SLang_push_null ();
	return;
     }
   
   mmt = allocate_termios (&s);	       /* NULL ok */
   if (-1 == SLang_push_mmt (mmt))
     SLang_free_mmt (mmt);
}

static int tcsetattr_intrin (SLFile_FD_Type *f, int *when, struct termios *s)
{
   return DO_SYSCALL_STRUCT_2(tcsetattr,f,*when,s);
}

static int termios_get_oflag (struct termios *s)
{
   return s->c_oflag;
}
static int termios_get_iflag (struct termios *s)
{
   return s->c_iflag;
}
static int termios_get_cflag (struct termios *s)
{
   return s->c_cflag;
}
static int termios_get_lflag (struct termios *s)
{
   return s->c_lflag;
}

static void termios_get_cc (struct termios *s)
{
   SLang_Array_Type *at;
   SLindex_Type dims = NCCS;
   int i;
   unsigned char *at_data;

   at = SLang_create_array (SLANG_UCHAR_TYPE, 0, NULL, &dims, 1);
   if (at == NULL)
     return;
   at_data = (unsigned char *) at->data;

   for (i = 0; i < NCCS; i++)
     at_data[i] = (unsigned char) s->c_cc[i];
   
   (void) SLang_push_array (at, 1);
}


static void termios_set_oflag (struct termios *s, int *flag)
{
   s->c_oflag = *flag;
}
static void termios_set_iflag (struct termios *s, int *flag)
{
   s->c_iflag = *flag;
}
static void termios_set_cflag (struct termios *s, int *flag)
{
   s->c_cflag = *flag;
}
static void termios_set_lflag (struct termios *s, int *flag)
{
   s->c_lflag = *flag;
}

static void termios_set_cc (void)
{
   SLang_Array_Type *at;
   SLang_MMT_Type *mmt;
   struct termios *s;
   unsigned char *at_data;
   int i;

   if (-1 == SLang_pop_array_of_type (&at, SLANG_UCHAR_TYPE))
     return;
   if (NULL == (mmt = SLang_pop_mmt (Termios_Type_Id)))
     goto free_and_return;

   s = (struct termios *) SLang_object_from_mmt (mmt);
   if (at->num_elements != NCCS)
     {
	SLang_verror (SL_TYPE_MISMATCH, 
		      "Expecting UChar_Type[%d]", NCCS);
	goto free_and_return;
     }

   at_data = (unsigned char *) at->data;
   for (i = 0; i < NCCS; i++)
     s->c_cc[i] = at_data[i];

   /* drop */

   free_and_return:
   SLang_free_array (at);
   SLang_free_mmt (mmt);
}

typedef struct 
{
   unsigned int bspeed;
   unsigned int speed;
}
Baudrate_Map_Type;

Baudrate_Map_Type Baudrate_Map[] = 
{
#ifdef B0
   {B0, 0},
#endif
#ifdef B50
   {B50, 50},
#endif
#ifdef B75
   {B75, 75},
#endif
#ifdef B110
   {B110, 110},
#endif
#ifdef B134
   {B134, 134},
#endif
#ifdef B150
   {B150, 150},
#endif
#ifdef B200
   {B200, 200},
#endif
#ifdef B300
   {B300, 300},
#endif
#ifdef B600
   {B600, 600},
#endif
#ifdef B1200
   {B1200, 1200},
#endif
#ifdef B1800
   {B1800, 1800},
#endif
#ifdef B2400
   {B2400, 2400},
#endif
#ifdef B4800
   {B4800, 4800},
#endif
#ifdef B9600
   {B9600, 9600},
#endif
#ifdef B19200
   {B19200, 19200},
#endif
#ifdef B38400
   {B38400, 38400},
#endif
#ifdef B57600
   {B57600, 57600},
#endif
#ifdef B115200
   {B115200, 115200},
#endif
#ifdef B230400
   {B230400, 230400},
#endif
#ifdef B460800
   {B460800, 460800},
#endif
   {0, 0}
};

static int map_speed_to_bspeed (unsigned int speed, unsigned int *bspeed)
{
   Baudrate_Map_Type *b, *bmax;

   b = Baudrate_Map;
   bmax = Baudrate_Map + (sizeof(Baudrate_Map)/sizeof(Baudrate_Map_Type)-1);
   
   while (b < bmax)
     {
	if (b->speed == speed)
	  {
	     *bspeed = b->bspeed;
	     return 0;
	  }
	b++;
     }
   SLang_verror (SL_InvalidParm_Error, "Invalid or Unsupported baudrate %u", speed);
   return -1;
}

static int map_bspeed_to_speed (unsigned int bspeed, unsigned int *speed)
{
   Baudrate_Map_Type *b, *bmax;

   b = Baudrate_Map;
   bmax = Baudrate_Map + (sizeof(Baudrate_Map)/sizeof(Baudrate_Map_Type)-1);
   
   while (b < bmax)
     {
	if (b->bspeed == bspeed)
	  {
	     *speed = b->speed;
	     return 0;
	  }
	b++;
     }
   SLang_verror (SL_InvalidParm_Error, "Invalid or Unsupported baudrate %u", bspeed);
   return -1;
}

static void cfgetispeed_intrin (struct termios *t)
{
   unsigned int speed, bspeed;

   bspeed = cfgetispeed (t);
   if (0 == map_bspeed_to_speed (bspeed, &speed))
     (void) SLang_push_uint (speed);
}

static void cfgetospeed_intrin (struct termios *t)
{
   unsigned int speed, bspeed;

   bspeed = cfgetospeed (t);
   if (0 == map_bspeed_to_speed (bspeed, &speed))
     (void) SLang_push_uint (speed);
}

static int cfsetispeed_intrin (struct termios *t, unsigned int *speed)
{   
   unsigned int bspeed;

   if (-1 == map_speed_to_bspeed (*speed, &bspeed))
     return -1;

   if (-1 == cfsetispeed (t, bspeed))
     {
	(void) SLerrno_set_errno (errno);
	return -1;
     }
   return 0;
}

static int cfsetospeed_intrin (struct termios *t, unsigned int *speed)
{   
   unsigned int bspeed;

   if (-1 == map_speed_to_bspeed (*speed, &bspeed))
     return -1;

   if (-1 == cfsetospeed (t, bspeed))
     {
	(void) SLerrno_set_errno (errno);
	return -1;
     }
   return 0;
}


static int termios_dereference (SLtype type, VOID_STAR addr)
{
   struct termios *s;
   SLang_MMT_Type *mmt;
   
   (void) type;
   mmt = *(SLang_MMT_Type **) addr;
   if (NULL == (s = (struct termios *)SLang_object_from_mmt (mmt)))
     return -1;
   
   mmt = allocate_termios (s);
   if (-1 == SLang_push_mmt (mmt))
     {
	SLang_free_mmt (mmt);
	return -1;
     }
   
   return 0;
}

   
#define DUMMY_TERMIOS_TYPE ((unsigned int)-1)
#define T DUMMY_TERMIOS_TYPE
#define F SLANG_FILE_FD_TYPE
#define I SLANG_INT_TYPE
#define V SLANG_VOID_TYPE
#define U SLANG_UINT_TYPE
static SLang_Intrin_Fun_Type Termios_Intrinsics [] =
{
   MAKE_INTRINSIC_1("tcdrain", tcdrain_intrin, I, F),
   MAKE_INTRINSIC_2("tcflow", tcflow_intrin, I, F, I),
   MAKE_INTRINSIC_2("tcflush", tcflush_intrin, I, F, I),
   MAKE_INTRINSIC_1("tcgetpgrp", tcgetpgrp_intrin, I, F),
   MAKE_INTRINSIC_2("tcsetpgrp", tcsetpgrp_intrin, I, F, I),
   MAKE_INTRINSIC_2("tcsendbreak", tcsendbreak_intrin, I, F, I),
   MAKE_INTRINSIC_1("tcgetattr", tcgetattr_intrin, V, F),
   MAKE_INTRINSIC_3("tcsetattr", tcsetattr_intrin, I, F, I, T),
   MAKE_INTRINSIC_1("cfgetispeed", cfgetispeed_intrin, V, T),
   MAKE_INTRINSIC_1("cfgetospeed", cfgetospeed_intrin, V, T),
   MAKE_INTRINSIC_2("cfsetispeed", cfsetispeed_intrin, I, T, U),
   MAKE_INTRINSIC_2("cfsetospeed", cfsetospeed_intrin, I, T, U),
   MAKE_INTRINSIC_1("termios_get_oflag", termios_get_oflag, I, T),
   MAKE_INTRINSIC_1("termios_get_iflag", termios_get_iflag, I, T),
   MAKE_INTRINSIC_1("termios_get_cflag", termios_get_cflag, I, T),
   MAKE_INTRINSIC_1("termios_get_lflag", termios_get_lflag, I, T),
   MAKE_INTRINSIC_1("termios_get_cc", termios_get_cc, V, T),
   MAKE_INTRINSIC_2("termios_set_oflag", termios_set_oflag, V, T, I),
   MAKE_INTRINSIC_2("termios_set_iflag", termios_set_iflag, V, T, I),
   MAKE_INTRINSIC_2("termios_set_cflag", termios_set_cflag, V, T, I),
   MAKE_INTRINSIC_2("termios_set_lflag", termios_set_lflag, V, T, I),
   MAKE_INTRINSIC_0("termios_set_cc", termios_set_cc, V),
   
   SLANG_END_INTRIN_FUN_TABLE
};
#undef T
#undef I
#undef F
#undef V
#undef U

static SLang_IConstant_Type Termios_Consts [] =
{
   MAKE_ICONSTANT("TCOOFF", TCOOFF),
   MAKE_ICONSTANT("TCOON", TCOON),
   MAKE_ICONSTANT("TCIOFF", TCIOFF),
   MAKE_ICONSTANT("TCION", TCION),
   MAKE_ICONSTANT("TCIFLUSH", TCIFLUSH),
   MAKE_ICONSTANT("TCOFLUSH", TCOFLUSH),
   MAKE_ICONSTANT("TCIOFLUSH", TCIOFLUSH),
   MAKE_ICONSTANT("TCSANOW", TCSANOW),
   MAKE_ICONSTANT("TCSADRAIN", TCSADRAIN),
   MAKE_ICONSTANT("TCSAFLUSH", TCSAFLUSH),		    
   MAKE_ICONSTANT("BRKINT", BRKINT),
   MAKE_ICONSTANT("IGNBRK", IGNBRK),
   MAKE_ICONSTANT("IGNPAR", IGNPAR),
   MAKE_ICONSTANT("PARMRK", PARMRK),
   MAKE_ICONSTANT("INPCK", INPCK),
   MAKE_ICONSTANT("ISTRIP", ISTRIP),
   MAKE_ICONSTANT("INLCR", INLCR),
   MAKE_ICONSTANT("IGNCR", IGNCR),
   MAKE_ICONSTANT("ICRNL", ICRNL),
   MAKE_ICONSTANT("IXON", IXON),
   MAKE_ICONSTANT("IXOFF", IXOFF),
   MAKE_ICONSTANT("CLOCAL", CLOCAL),
   MAKE_ICONSTANT("CREAD", CREAD),
   MAKE_ICONSTANT("CSIZE", CSIZE),
   MAKE_ICONSTANT("CSTOPB", CSTOPB),
   MAKE_ICONSTANT("HUPCL", HUPCL),
   MAKE_ICONSTANT("PARENB", PARENB),
   MAKE_ICONSTANT("PARODD", PARODD),
   MAKE_ICONSTANT("ECHO", ECHO),
   MAKE_ICONSTANT("ECHOE", ECHOE),
   MAKE_ICONSTANT("ECHOK", ECHOK),
   MAKE_ICONSTANT("ECHONL", ECHONL),
   MAKE_ICONSTANT("ICANON", ICANON),
   MAKE_ICONSTANT("ISIG", ISIG),
   MAKE_ICONSTANT("NOFLSH", NOFLSH),
   MAKE_ICONSTANT("TOSTOP", TOSTOP),
   MAKE_ICONSTANT("IEXTEN", IEXTEN),
   MAKE_ICONSTANT("VEOF", VEOF),
   MAKE_ICONSTANT("VEOL", VEOL),
   MAKE_ICONSTANT("VERASE", VERASE),
   MAKE_ICONSTANT("VINTR", VINTR),
   MAKE_ICONSTANT("VKILL", VKILL),
   MAKE_ICONSTANT("VQUIT", VQUIT),
   MAKE_ICONSTANT("VSUSP", VSUSP),
   MAKE_ICONSTANT("VSTART", VSTART),
   MAKE_ICONSTANT("VSTOP", VSTOP),
#ifdef ultrix   /* Ultrix gets _POSIX_VDISABLE wrong! */
# define NULL_VALUE -1
#else
# ifdef _POSIX_VDISABLE
#  define NULL_VALUE _POSIX_VDISABLE
# else
#  define NULL_VALUE 255
# endif
#endif
   MAKE_ICONSTANT("VDISABLE", NULL_VALUE),

   SLANG_END_ICONST_TABLE
};

static void patchup_intrinsic_table (SLang_Intrin_Fun_Type *table, 
				     SLtype dummy, SLtype type)
{
   while (table->name != NULL)
     {
	unsigned int i, nargs;
	SLtype *args;
	
	nargs = table->num_args;
	args = table->arg_types;
	for (i = 0; i < nargs; i++)
	  {
	     if (args[i] == dummy)
	       args[i] = type;
	  }
	
	/* For completeness */
	if (table->return_type == dummy)
	  table->return_type = type;

	table++;
     }
}


static int register_termios_type (void)
{
   SLang_Class_Type *cl;

   if (Termios_Type_Id != 0)
     return 0;

   if (NULL == (cl = SLclass_allocate_class ("Termios_Type")))
     return -1;

   if (-1 == SLclass_set_destroy_function (cl, destroy_termios))
     return -1;
   
   if (-1 == SLclass_set_deref_function (cl, termios_dereference))
     return -1;

   /* By registering as SLANG_VOID_TYPE, slang will dynamically allocate a
    * type.
    */
   if (-1 == SLclass_register_class (cl, SLANG_VOID_TYPE, sizeof (struct termios), SLANG_CLASS_TYPE_MMT))
     return -1;

   Termios_Type_Id = SLclass_get_class_id (cl);
   patchup_intrinsic_table (Termios_Intrinsics, DUMMY_TERMIOS_TYPE, Termios_Type_Id);

   return 0;
}

int init_termios_module_ns (char *ns_name)
{
   SLang_NameSpace_Type *ns;
   
   ns = SLns_create_namespace (ns_name);
   if (ns == NULL)
     return -1;

   if (-1 == register_termios_type ())
     return -1;

   if ((-1 == SLns_add_intrin_fun_table (ns, Termios_Intrinsics, "__TERMIOS__"))
       || (-1 == SLns_add_iconstant_table (ns, Termios_Consts, NULL)))
     return -1;

   return 0;
}

/* This function is optional */
void deinit_termios_module (void)
{
}
