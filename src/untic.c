#define SLANG_UNTIC
char *SLang_Untic_Terminfo_File;
#include "sltermin.c"

static void usage (void)
{
   fprintf (stderr, "Usage: untic [[--terminfo filename] | [term]]\n");
   exit (1);
}

static void print_string_cap (const char *name, unsigned char *str, char *comment)
{
   fprintf (stdout, "\t%s=", name);
   while (*str)
     {
	if ((int) (*str & 0x7F) < ' ')
	  {
	     putc ('^', stdout);
	     *str += '@';
	  }
	putc (*str, stdout);
	str++;
     }
   if (comment != NULL)
     fprintf (stdout, "\t\t%s", comment);
   putc ('\n', stdout);
}

static void print_bool_cap (const char *name, char *comment)
{
   fprintf (stdout, "\t%s\t\t%s\n", name,
	    ((comment == NULL) ? "" : comment));
}

static void print_numeric_cap (const char *name, int val, char *comment)
{
   fprintf (stdout, "\t%s#%d\t\t%s\n", name, val,
	    ((comment == NULL) ? "" : comment));
}

int main (int argc, char **argv)
{
   SLterminfo_Type *t;
   Tgetstr_Map_Type *map = Tgetstr_Map;
   unsigned char *str;
   char *term;

   term = getenv ("TERM");
   if (argc > 1)
     {
	if (!strcmp ("--help", argv[1])) usage ();
	if (argc == 2)
	  term = argv[1];
	else if ((argc == 3) && !strcmp(argv[1], "--terminfo"))
	  {
	     SLang_Untic_Terminfo_File = argv[2];
	  }
	else usage ();
     }
   else if (term == NULL) return -1;

   SLtt_Try_Termcap = 0;
   t = _pSLtt_tigetent (term);
   if (t == NULL) return -1;

   puts (t->terminal_names);
   while (*map->name != 0)
     {
	str = (unsigned char *) SLtt_tigetstr ((SLFUTURE_CONST char *)map->name, (char **) &t);
	if (str == NULL)
	  {
	     map++;
	     continue;
	     /* str = (unsigned char *) "NULL"; */
	  }

	print_string_cap (map->name, str, map->comment);
	map++;
     }

   map = Tgetflag_Map;
   while (*map->name != 0)
     {
	if (_pSLtt_tigetflag (t, map->name) > 0)
	  print_bool_cap (map->name, map->comment);
	map++;
     }
   map = Tgetnum_Map;
   while (*map->name != 0)
     {
	int val;
	if ((val = SLtt_tigetnum ((SLFUTURE_CONST char *)map->name, (char **) &t)) >= 0)
	  print_numeric_cap (map->name, val, map->comment);

	map++;
     }

   if (t->ext != NULL)
     {
	Extended_Cap_Type *e = t->ext;
	int i;

	fprintf (stdout, "Local Extensions:\n");
	for (i = 0; i < e->num_string; i++)
	  {
	     str = (unsigned char *) SLtt_tigetstr ((SLFUTURE_CONST char *)e->string_caps[i], (char **) &t);
	     if (str != NULL) print_string_cap (e->string_caps[i], str, NULL);
	  }

	for (i = 0; i < e->num_bool; i++)
	  {
	     if (_pSLtt_tigetflag (t, e->bool_caps[i]) > 0)
	       print_bool_cap (e->bool_caps[i], NULL);
	  }

	for (i = 0; i < e->num_numeric; i++)
	  {
	     int val;
	     if ((val = SLtt_tigetnum ((SLFUTURE_CONST char *)e->numeric_caps[i], (char **) &t)) >= 0)
	       print_numeric_cap (e->numeric_caps[i], val, NULL);
	  }
     }

   _pSLtt_tifreeent (t);
   return 0;
}

