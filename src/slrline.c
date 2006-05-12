/* SLang_read_line interface --- uses SLang tty stuff */
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

#include "slang.h"
#include "_slang.h"

typedef struct RL_History_Type
{
   struct RL_History_Type *prev, *next;
   char *buf;
   unsigned int len;
   unsigned int point;
} RL_History_Type;

/* Maximum size of display */
#define SLRL_DISPLAY_BUFFER_SIZE 1024

struct _pSLrline_Type
{
   RL_History_Type *root, *tail, *last;
   unsigned char *buf;		       /* edit buffer */
   unsigned int buf_len;			       /* sizeof buffer */
   unsigned int point;			       /* current editing point */
   unsigned int tab;			       /* tab width */
   unsigned int len;			       /* current line size */

   /* display variables */
   unsigned int edit_width;		       /* length of display field */
   int curs_pos;			       /* current column */
   int start_column;		       /* column offset of display */
   unsigned int hscroll;		       /* amount to use for horiz scroll */
   char *prompt;

   FVOID_STAR last_fun;		       /* last function executed by rl */

   /* These two contain an image of what is on the display */
   unsigned char upd_buf1[SLRL_DISPLAY_BUFFER_SIZE];
   unsigned char upd_buf2[SLRL_DISPLAY_BUFFER_SIZE];
   unsigned char *old_upd, *new_upd;   /* pointers to previous two buffers */
   int new_upd_len, old_upd_len;       /* length of output buffers */

   SLKeyMap_List_Type *keymap;
   int eof_char;

   /* tty variables */
   unsigned int flags;		       /*  */
   int state;
#define RLI_LINE_INVALID	0
#define RLI_LINE_SET		1
#define RLI_LINE_IN_PROGRESS	2
#define RLI_LINE_READ		3

   unsigned int (*getkey)(void);       /* getkey function -- required */
   void (*tt_goto_column)(int);
   void (*tt_insert)(char);
   void (*update_hook)(SLrline_Type *rli,
		       char *prompt, char *buf, unsigned int len, unsigned int point,
		       VOID_STAR client_data);
   VOID_STAR update_client_data;
   /* This function is only called when blinking matches */
   int (*input_pending)(int);
};

int SLang_Rline_Quit;

static unsigned char Char_Widths[256];
static void position_cursor (SLrline_Type *, int);

static void rl_beep (void)
{
   putc(7, stdout);
   fflush (stdout);
}

static int check_space (SLrline_Type *This_RLI, unsigned int dn)
{
   unsigned char *new_buf;
   unsigned int new_len;

   new_len = 1 + This_RLI->len + dn;

   if (new_len <= This_RLI->buf_len)
     return 0;

   if (NULL == (new_buf = (unsigned char *) SLrealloc ((char *)This_RLI->buf, new_len)))
     return -1;
	
   This_RLI->buf_len = new_len;
   This_RLI->buf = new_buf;
   return 0;
}


/* editing functions */
static int rl_bol (SLrline_Type *This_RLI)
{
   This_RLI->point = 0;
   return 0;
}

static int rl_eol (SLrline_Type *This_RLI)
{
   This_RLI->point = This_RLI->len;
   return 0;
}

static int rl_right (SLrline_Type *This_RLI)
{
   SLuchar_Type *s, *smax;
   int ignore_combining = 1;

   s = This_RLI->buf + This_RLI->point;
   smax = This_RLI->buf + This_RLI->len;

   if (s < smax)
     {
	if (This_RLI->flags & SL_RLINE_UTF8_MODE)
	  s = SLutf8_skip_chars (s, smax, 1, NULL, ignore_combining);
	else
	  s++;

	This_RLI->point = s - This_RLI->buf;
     }

   return 0;
}

static int rl_left (SLrline_Type *This_RLI)
{
   SLuchar_Type *s, *smin;
   int ignore_combining = 1;

   smin = This_RLI->buf;
   s = smin + This_RLI->point;

   if (s > smin)
     {
	if (This_RLI->flags & SL_RLINE_UTF8_MODE)
	  s = SLutf8_bskip_chars (smin, s, 1, NULL, ignore_combining);
	else
	  s--;

	This_RLI->point = s - This_RLI->buf;
     }

   return 0;
}

int SLrline_ins (SLrline_Type *This_RLI, char *s, unsigned int n)
{
   unsigned char *pmin;

   if (-1 == check_space (This_RLI, n + 128))
     return -1;

   pmin = This_RLI->buf + This_RLI->point;
   if (This_RLI->len)
     {
	unsigned char *p = This_RLI->buf + This_RLI->len;
	while (p >= pmin)
	  {
	     *(p + n) = *p;
	     p--;
	  }
     }
   memcpy ((char *) pmin, s, n);

   This_RLI->len += n;
   This_RLI->point += n;
   return n;
}


static int rl_self_insert (SLrline_Type *This_RLI)
{
   char buf[8];

   buf[0] = SLang_Last_Key_Char;
   buf[1] = 0;

   return SLrline_ins (This_RLI, buf, 1);
}

int SLrline_del (SLrline_Type *This_RLI, unsigned int n)
{
   SLuchar_Type *pmax, *p, *pn;
   int ignore_combining = 1;

   p = This_RLI->buf + This_RLI->point;
   pmax = This_RLI->buf + This_RLI->len;
   
   if (This_RLI->flags & SL_RLINE_UTF8_MODE)
     {
	pn = SLutf8_skip_chars (p, pmax, n, NULL, ignore_combining);
	n = pn - p;
     }
   else
     {
	if (p + n > pmax) n = (pmax - p);
	pn = p + n;
     }
   This_RLI->len -= n;

   while (pn < pmax)
     {
	*p++ = *pn++;
     }
   return 0;
}

static int rl_del (SLrline_Type *This_RLI)
{
   return SLrline_del (This_RLI, 1);
}

static int rl_quote_insert (SLrline_Type *This_RLI)
{
   /* FIXME.  We should not be messing with SLang_Error here */
   int err = _pSLang_Error;
   _pSLang_Error = 0;
   SLang_Last_Key_Char = (*This_RLI->getkey)();
   rl_self_insert (This_RLI);
   if (_pSLang_Error == SL_USER_BREAK) 
     {
	SLKeyBoard_Quit = 0;
	_pSLang_Error = 0;
     }
   else _pSLang_Error = err;
   return 0;
}

static int rl_trim (SLrline_Type *This_RLI)
{
   unsigned char *p, *pmax, *p1;

   p = This_RLI->buf + This_RLI->point;
   pmax = This_RLI->buf + This_RLI->len;

   if (p == pmax)
     {
	if (p == This_RLI->buf) return 0;
	p--;
     }

   if ((*p != ' ') && (*p != '\t')) return 0;
   p1 = p;
   while ((p1 < pmax) && ((*p1 == ' ') || (*p1 == '\t'))) p1++;
   pmax = p1;
   p1 = This_RLI->buf;

   while ((p >= p1) && ((*p == ' ') || (*p == '\t'))) p--;
   if (p == pmax) return 0;
   p++;

   This_RLI->point = (int) (p - p1);
   return SLrline_del (This_RLI, (int) (pmax - p));
}

static int rl_bdel (SLrline_Type *This_RLI)
{
   if (This_RLI->point)
     {
	rl_left (This_RLI);
	rl_del(This_RLI);
     }
   return 0;
}

static int rl_deleol (SLrline_Type *This_RLI)
{
   if (This_RLI->point == This_RLI->len) return 0;
   *(This_RLI->buf + This_RLI->point) = 0;
   This_RLI->len = This_RLI->point;
   return 1;
}

static int rl_delete_line (SLrline_Type *This_RLI)
{
   rl_bol (This_RLI);
   rl_deleol (This_RLI);
   return 0;
}

static int rl_enter (SLrline_Type *This_RLI)
{
   if (-1 == check_space (This_RLI, 1))
     return -1;

   *(This_RLI->buf + This_RLI->len) = 0;
   SLang_Rline_Quit = 1;
   return 0;
}

static SLKeyMap_List_Type *RL_Keymap;

/* This update is designed for dumb terminals.  It assumes only that the
 * terminal can backspace via ^H, and move cursor to start of line via ^M.
 * There is a hook so the user can provide a more sophisticated update if
 * necessary.
 */
static void position_cursor (SLrline_Type *This_RLI, int col)
{
   unsigned char *p, *pmax;
   int dc;

   if (col == This_RLI->curs_pos)
     {
	fflush (stdout);
	return;
     }

   if (This_RLI->tt_goto_column != NULL)
     {
	(*This_RLI->tt_goto_column)(col);
	This_RLI->curs_pos = col;
	fflush (stdout);
	return;
     }

   dc = This_RLI->curs_pos - col;
   if (dc < 0)
     {
	p = This_RLI->new_upd + This_RLI->curs_pos;
	pmax = This_RLI->new_upd + col;
	while (p < pmax) putc((char) *p++, stdout);
     }
   else
     {
	if (dc < col)
	  {
	     while (dc--) putc(8, stdout);
	  }
	else
	  {
	     putc('\r', stdout);
	     p = This_RLI->new_upd;
	     pmax = This_RLI->new_upd + col;
	     while (p < pmax) putc((char) *p++, stdout);
	  }
     }
   This_RLI->curs_pos = col;
   fflush (stdout);
}

static void erase_eol (SLrline_Type *rli)
{
   unsigned char *p, *pmax;

   p = rli->old_upd + rli->curs_pos;
   pmax = rli->old_upd + rli->old_upd_len;

   while (p++ < pmax) putc(' ', stdout);

   rli->curs_pos = rli->old_upd_len;
}

static unsigned char *spit_out(SLrline_Type *rli, unsigned char *p)
{
   unsigned char *pmax;
   position_cursor (rli, (int) (p - rli->new_upd));
   pmax = rli->new_upd + rli->new_upd_len;
   while (p < pmax) putc((char) *p++, stdout);
   rli->curs_pos = rli->new_upd_len;
   return pmax;
}

static void really_update (SLrline_Type *rli, int new_curs_position)
{
   unsigned char *b = rli->old_upd, *p = rli->new_upd, chb, chp;
   unsigned char *pmax;

   pmax = p + rli->edit_width;
   while (p < pmax)
     {
	chb = *b++; chp = *p++;
	if (chb == chp) continue;
	
	if (rli->old_upd_len <= rli->new_upd_len)
	  {
	     /* easy one */
	     (void) spit_out (rli, p - 1);
	     break;
	  }
	spit_out(rli, p - 1);
	erase_eol (rli);
	break;
     }
   position_cursor (rli, new_curs_position);

   /* update finished, so swap */

   rli->old_upd_len = rli->new_upd_len;
   p = rli->old_upd;
   rli->old_upd = rli->new_upd;
   rli->new_upd = p;
}

static void RLupdate (SLrline_Type *rli)
{
   int len, dlen, start_len, prompt_len = 0, tw = 0, count;
   int want_cursor_pos;
   unsigned char *b, chb, *b_point, *p;
   int no_echo;

   no_echo = rli->flags & SL_RLINE_NO_ECHO;
   *(rli->buf + rli->len) = 0;
   
   if (rli->update_hook != NULL)
     {
	if (no_echo)
	  (*rli->update_hook) (rli, rli->prompt, "", 0, 0, rli->update_client_data);
	else
	  (*rli->update_hook) (rli, rli->prompt, (char *)rli->buf, rli->len, rli->point, rli->update_client_data);
	return;
     }

   b_point = (unsigned char *) (rli->buf + rli->point);

   /* expand characters for output buffer --- handle prompt first.
    * Do two passes --- first to find out where to begin upon horiz
    * scroll and the second to actually fill the buffer. */
   len = 0;
   count = 2;			       /* once for prompt and once for buf */

   b = (unsigned char *) rli->prompt;
   while (count--)
     {
	if ((count == 0) && no_echo)
	  break;

	/* The prompt could be NULL */
	if (b != NULL) while ((chb = *b) != 0)
	  {
	     /* This will ensure that the screen is scrolled a third of the edit
	      * width each time */
	     if (b_point == b) break;
	     dlen = Char_Widths[chb];
	     if ((chb == '\t') && tw)
	       {
		  dlen = tw * ((len - prompt_len) / tw + 1) - (len - prompt_len);
	       }
	     len += dlen;
	     b++;
	  }
	tw = rli->tab;
	b = (unsigned char *) rli->buf;
	if (count == 1) prompt_len = len;
     }

   if (len + rli->hscroll < rli->edit_width) start_len = 0;
   else if ((rli->start_column > (int)len)
	    || (rli->start_column + (int)rli->edit_width <= len))
     {
	start_len = len - (rli->edit_width - rli->hscroll);
	if (start_len < 0) start_len = 0;
     }
   else start_len = rli->start_column;
   rli->start_column = start_len;

   want_cursor_pos = len - start_len;

   /* second pass */
   p = rli->new_upd;

   len = 0;
   count = 2;
   b = (unsigned char *) rli->prompt;
   if (b == NULL) b = (unsigned char *) "";

   while ((len < start_len) && (*b))
     {
	len += Char_Widths[*b++];
     }

   tw = 0;
   if (*b == 0)
     {
	b = (unsigned char *) rli->buf;
	while (len < start_len)
	  {
	     len += Char_Widths[*b++];
	  }
	tw = rli->tab;
	count--;
     }

   len = 0;
   while (count--)
     {
	if ((count == 0) && (no_echo))
	  break;

	while ((len < (int)rli->edit_width) && ((chb = *b++) != 0))
	  {
	     dlen = Char_Widths[chb];
	     if (dlen == 1) *p++ = chb;
	     else
	       {
		  if ((chb == '\t') && tw)
		    {
		       dlen = tw * ((len + start_len - prompt_len) / tw + 1) - (len + start_len - prompt_len);
		       len += dlen;	       /* ok since dlen comes out 0  */
		       if (len > (int)rli->edit_width) dlen = len - rli->edit_width;
		       while (dlen--) *p++ = ' ';
		       dlen = 0;
		    }
		  else
		    {
		       if (dlen == 3)
			 {
			    chb &= 0x7F;
			    *p++ = '~';
			 }

		       *p++ = '^';
		       if (chb == 127)  *p++ = '?';
		       else *p++ = chb + '@';
		    }
	       }
	     len += dlen;
	  }
	/* if (start_len > prompt_len) break; */
	tw = rli->tab;
	b = (unsigned char *) rli->buf;
     }

   rli->new_upd_len = (int) (p - rli->new_upd);
   while (p < rli->new_upd + rli->edit_width) *p++ = ' ';
   really_update (rli, want_cursor_pos);
}

void SLrline_redraw (SLrline_Type *rli)
{
   unsigned char *p;
   unsigned char *pmax;
   
   if (rli == NULL)
     return;

   p = rli->new_upd;
   pmax = p + rli->edit_width;
   while (p < pmax) *p++ = ' ';
   rli->new_upd_len = rli->edit_width;
   really_update (rli, 0);
   RLupdate (rli);
}

static int rl_eof_insert (SLrline_Type *This_RLI)
{
   return rl_enter (This_RLI);
}

/* This is very naive.  It knows very little about nesting and nothing
 * about quoting.
 */
static void blink_match (SLrline_Type *rli)
{
   unsigned char bra, ket;
   unsigned int delta_column;
   unsigned char *p, *pmin;
   int dq_level, sq_level;
   int level;

   pmin = rli->buf;
   p = pmin + rli->point;
   if (pmin == p)
     return;

   ket = SLang_Last_Key_Char;
   switch (ket)
     {
      case ')':
	bra = '(';
	break;
      case ']':
	bra = '[';
	break;
      case '}':
	bra = '{';
	break;
      default:
	return;
     }

   level = 0;
   sq_level = dq_level = 0;

   delta_column = 0;
   while (p > pmin)
     {
	char ch;

	p--;
	delta_column++;
	ch = *p;

	if (ch == ket)
	  {
	     if ((dq_level == 0) && (sq_level == 0))
	       level++;
	  }
	else if (ch == bra)
	  {
	     if ((dq_level != 0) || (sq_level != 0))
	       continue;

	     level--;
	     if (level == 0)
	       {
		  rli->point -= delta_column;
		  RLupdate (rli);
		  (*rli->input_pending)(10);
		  rli->point += delta_column;
		  RLupdate (rli);
		  break;
	       }
	     if (level < 0)
	       break;
	  }
	else if (ch == '"') dq_level = !dq_level;
	else if (ch == '\'') sq_level = !sq_level;
     }
}

char *SLrline_read_line (SLrline_Type *rli, char *prompt, unsigned int *lenp)
{
   unsigned char *p, *pmax;
   SLang_Key_Type *key;
   int last_input_char;
   unsigned int dummy_len_buf;

   if (lenp == NULL)
     lenp = &dummy_len_buf;

   *lenp = 0;

   if (rli == NULL)
     return NULL;

   if (rli->state == RLI_LINE_IN_PROGRESS)
     {
	*lenp = 0;
	return NULL;
     }

   if (prompt == NULL)
     prompt = "";

   if ((rli->prompt == NULL)
       || strcmp (rli->prompt, prompt))
     {
	if (NULL == (prompt = SLmake_string (prompt)))
	  return NULL;
	
	SLfree (rli->prompt);
	rli->prompt = prompt;
     }

   SLang_Rline_Quit = 0;
   p = rli->old_upd; pmax = p + rli->edit_width;
   while (p < pmax) *p++ = ' ';

   if (rli->state != RLI_LINE_SET)
     {
	rli->len = 0;
	rli->point = 0;
	*rli->buf = 0;
     }
   rli->state = RLI_LINE_IN_PROGRESS;

   rli->curs_pos = rli->start_column = 0;
   rli->new_upd_len = rli->old_upd_len = 0;

   rli->last_fun = NULL;
   if (rli->update_hook == NULL)
     putc ('\r', stdout);

   RLupdate (rli);

   last_input_char = 0;
   while (1)
     {
	key = SLang_do_key (RL_Keymap, (int (*)(void)) rli->getkey);

	if ((key == NULL) || (key->f.f == NULL))
	  {
	     rl_beep ();
	     continue;
	  }

	if ((*key->str != 2) || (key->str[1] != rli->eof_char))
	  last_input_char = 0;
	else
	  {
	     if ((rli->len == 0) && (last_input_char != rli->eof_char))
	       {
		  rli->buf[rli->len] = 0;
		  rli->state = RLI_LINE_READ;
		  *lenp = 0;
		  return NULL;	       /* EOF */
	       }
	     
	     last_input_char = rli->eof_char;
	  }

	if (key->type == SLKEY_F_INTRINSIC)
	  {
	     int (*func)(SLrline_Type *);
	     func = (int (*)(SLrline_Type *)) key->f.f;
	     
	     (void) (*func)(rli);

	     RLupdate (rli);
	     
	     if ((rli->flags & SL_RLINE_BLINK_MATCH)
		 && (rli->input_pending != NULL))
	       blink_match (rli);
	  }
	
	if ((SLang_Rline_Quit) || (_pSLang_Error == SL_USER_BREAK))
	  {
	     if (_pSLang_Error == SL_USER_BREAK)
	       {
		  rli->len = 0;
	       }
	     rli->buf[rli->len] = 0;
	     rli->state = RLI_LINE_READ;
	     *lenp = rli->len;

	     return SLmake_nstring ((char *)rli->buf, rli->len);
	  }
	if (key != NULL)
	  rli->last_fun = key->f.f;
     }
}

static int rl_abort (SLrline_Type *This_RLI)
{
   rl_delete_line (This_RLI);
   return rl_enter (This_RLI);
}

/* TTY interface --- ANSI */

static void ansi_goto_column (int n)
{
   putc('\r', stdout);
   if (n) fprintf(stdout, "\033[%dC", n);
}

static int rl_select_line (SLrline_Type *rli, RL_History_Type *p)
{
   unsigned int len;

   len = p->len;
   if (-1 == check_space (rli, len))
     return -1;

   rli->last = p;
   strcpy ((char *) rli->buf, p->buf);
   rli->point = p->point;
   rli->len = len;
   return 0;
}

static int rl_next_line (SLrline_Type *This_RLI);
static int rl_prev_line (SLrline_Type *This_RLI)
{
   RL_History_Type *prev;

   if (((This_RLI->last_fun != (FVOID_STAR) rl_prev_line)
	&& (This_RLI->last_fun != (FVOID_STAR) rl_next_line))
       || (This_RLI->last == NULL))
     {
	prev = This_RLI->tail;
     }
   else prev = This_RLI->last->prev;

   if (prev == NULL)
     {
	rl_beep ();
	return 0;
     }

   return rl_select_line (This_RLI, prev);
}

static int rl_redraw (SLrline_Type *This_RLI)
{
   SLrline_redraw (This_RLI);
   return 1;
}

static int rl_next_line (SLrline_Type *This_RLI)
{
   RL_History_Type *next;

   if (((This_RLI->last_fun != (FVOID_STAR) rl_prev_line)
	&& (This_RLI->last_fun != (FVOID_STAR) rl_next_line))
       || (This_RLI->last == NULL))
      {
	 rl_beep ();
	 return 0;
      }

   next = This_RLI->last->next;

   if (next == NULL)
     {
	This_RLI->len = This_RLI->point = 0;
	*This_RLI->buf = 0;
	This_RLI->last = NULL;
     }
   else rl_select_line (This_RLI, next);
   return 1;
}

#define AKEY(name,func) {name,(int (*)(void))func}

static SLKeymap_Function_Type SLReadLine_Functions[] =
{
   AKEY("up", rl_prev_line),
   AKEY("down", rl_next_line),
   AKEY("bol", rl_bol),
   AKEY("eol", rl_eol),
   AKEY("right", rl_right),
   AKEY("left", rl_left),
   AKEY("self_insert", rl_self_insert),
   AKEY("bdel", rl_bdel),
   AKEY("del", rl_del),
   AKEY("deleol", rl_deleol),
   AKEY("enter", rl_enter),
   AKEY("trim", rl_trim),
   AKEY("quoted_insert", rl_quote_insert),
   AKEY(NULL, NULL),
};

void SLrline_close (SLrline_Type *rli)
{
   if (rli == NULL)
     return;
   
   SLfree (rli->prompt);
   SLfree ((char *)rli->buf);
   SLfree ((char *)rli);
}

SLrline_Type *SLrline_open (unsigned int width, unsigned int flags)
{
   int ch;
   char simple[2];
   SLrline_Type *rli;

   if (NULL == (rli = (SLrline_Type *)SLcalloc (1, sizeof (SLrline_Type))))
     return NULL;
   
   if (width == 0)
     width = 80;

   if (width < 256) rli->buf_len = 256;
   else rli->buf_len = width;

   if (NULL == (rli->buf = (unsigned char *)SLmalloc (rli->buf_len)))
     {
	SLrline_close (rli);
	return NULL;
     }
   *rli->buf = 0;
#ifdef REAL_UNIX_SYSTEM
   rli->eof_char = 4;
#else
   rli->eof_char = 26;
#endif
   
   rli->point = 0;
   rli->flags = flags;
   rli->edit_width = width;
   rli->hscroll = width/4;
   rli->tab = 8;
   rli->getkey = SLang_getkey;
   rli->input_pending = SLang_input_pending;
   rli->state = RLI_LINE_INVALID;

   if (rli->flags & SL_RLINE_USE_ANSI)
     {
	if (rli->tt_goto_column == NULL) rli->tt_goto_column = ansi_goto_column;
     }

   if (RL_Keymap == NULL)
     {
	simple[1] = 0;
	if (NULL == (RL_Keymap = SLang_create_keymap ("ReadLine", NULL)))
	  {
	     SLrline_close (rli);
	     return NULL;
	  }

	RL_Keymap->functions = SLReadLine_Functions;

	/* This breaks under some DEC ALPHA compilers (scary!) */
#ifndef __DECC
	for (ch = ' '; ch < 256; ch++)
	  {
	     simple[0] = (char) ch;
	     SLkm_define_key (simple, (FVOID_STAR) rl_self_insert, RL_Keymap);
	  }
#else
	ch = ' ';
	while (1)
	  {
	     simple[0] = (char) ch;
	     SLkm_define_key (simple, (FVOID_STAR) rl_self_insert, RL_Keymap);
	     ch = ch + 1;
	     if (ch == 256) break;
	  }
#endif				       /* NOT __DECC */

	simple[0] = SLang_Abort_Char;
	SLkm_define_key (simple, (FVOID_STAR) rl_abort, RL_Keymap);
	simple[0] = (char) rli->eof_char;
	SLkm_define_key (simple, (FVOID_STAR) rl_eof_insert, RL_Keymap);

#ifndef IBMPC_SYSTEM
	SLkm_define_key  ("^[[A", (FVOID_STAR) rl_prev_line, RL_Keymap);
	SLkm_define_key  ("^[[B", (FVOID_STAR) rl_next_line, RL_Keymap);
	SLkm_define_key  ("^[[C", (FVOID_STAR) rl_right, RL_Keymap);
	SLkm_define_key  ("^[[D", (FVOID_STAR) rl_left, RL_Keymap);
	SLkm_define_key  ("^[OA", (FVOID_STAR) rl_prev_line, RL_Keymap);
	SLkm_define_key  ("^[OB", (FVOID_STAR) rl_next_line, RL_Keymap);
	SLkm_define_key  ("^[OC", (FVOID_STAR) rl_right, RL_Keymap);
	SLkm_define_key  ("^[OD", (FVOID_STAR) rl_left, RL_Keymap);
#else
	SLkm_define_key  ("^@H", (FVOID_STAR) rl_prev_line, RL_Keymap);
	SLkm_define_key  ("^@P", (FVOID_STAR) rl_next_line, RL_Keymap);
	SLkm_define_key  ("^@M", (FVOID_STAR) rl_right, RL_Keymap);
	SLkm_define_key  ("^@K", (FVOID_STAR) rl_left, RL_Keymap);
	SLkm_define_key  ("^@S", (FVOID_STAR) rl_del, RL_Keymap);
	SLkm_define_key  ("^@O", (FVOID_STAR) rl_eol, RL_Keymap);
	SLkm_define_key  ("^@G", (FVOID_STAR) rl_bol, RL_Keymap);

	SLkm_define_key  ("\xE0H", (FVOID_STAR) rl_prev_line, RL_Keymap);
	SLkm_define_key  ("\xE0P", (FVOID_STAR) rl_next_line, RL_Keymap);
	SLkm_define_key  ("\xE0M", (FVOID_STAR) rl_right, RL_Keymap);
	SLkm_define_key  ("\xE0K", (FVOID_STAR) rl_left, RL_Keymap);
	SLkm_define_key  ("\xE0S", (FVOID_STAR) rl_del, RL_Keymap);
	SLkm_define_key  ("\xE0O", (FVOID_STAR) rl_eol, RL_Keymap);
	SLkm_define_key  ("\xE0G", (FVOID_STAR) rl_bol, RL_Keymap);
#endif
	SLkm_define_key  ("^C", (FVOID_STAR) rl_abort, RL_Keymap);
	SLkm_define_key  ("^E", (FVOID_STAR) rl_eol, RL_Keymap);
	SLkm_define_key  ("^G", (FVOID_STAR) rl_abort, RL_Keymap);
	SLkm_define_key  ("^I", (FVOID_STAR) rl_self_insert, RL_Keymap);
	SLkm_define_key  ("^A", (FVOID_STAR) rl_bol, RL_Keymap);
	SLkm_define_key  ("\r", (FVOID_STAR) rl_enter, RL_Keymap);
	SLkm_define_key  ("\n", (FVOID_STAR) rl_enter, RL_Keymap);
	SLkm_define_key  ("^K", (FVOID_STAR) rl_deleol, RL_Keymap);
	SLkm_define_key  ("^L", (FVOID_STAR) rl_deleol, RL_Keymap);
	SLkm_define_key  ("^V", (FVOID_STAR) rl_del, RL_Keymap);
	SLkm_define_key  ("^D", (FVOID_STAR) rl_del, RL_Keymap);
	SLkm_define_key  ("^F", (FVOID_STAR) rl_right, RL_Keymap);
	SLkm_define_key  ("^B", (FVOID_STAR) rl_left, RL_Keymap);
	SLkm_define_key  ("^?", (FVOID_STAR) rl_bdel, RL_Keymap);
	SLkm_define_key  ("^H", (FVOID_STAR) rl_bdel, RL_Keymap);
	SLkm_define_key  ("^P", (FVOID_STAR) rl_prev_line, RL_Keymap);
	SLkm_define_key  ("^N", (FVOID_STAR) rl_next_line, RL_Keymap);
	SLkm_define_key  ("^R", (FVOID_STAR) rl_redraw, RL_Keymap);
	SLkm_define_key  ("`", (FVOID_STAR) rl_quote_insert, RL_Keymap);
	SLkm_define_key  ("\033\\", (FVOID_STAR) rl_trim, RL_Keymap);
	if (_pSLang_Error)
	  {
	     SLrline_close (rli);
	     return NULL;
	  }
     }

   if (rli->keymap == NULL) rli->keymap = RL_Keymap;
   rli->old_upd = rli->upd_buf1;
   rli->new_upd = rli->upd_buf2;

   if (Char_Widths[0] == 0)
     {
	/* FIXME: This does not support UTF-8 */
	for (ch = 0; ch < 32; ch++) Char_Widths[ch] = 2;
	for (ch = 32; ch < 256; ch++) Char_Widths[ch] = 1;
	Char_Widths[127] = 2;
#ifndef IBMPC_SYSTEM
	for (ch = 128; ch < 160; ch++) Char_Widths[ch] = 3;
#endif
     }

   return rli;
}

int SLrline_add_to_history (SLrline_Type *rli, char *hist)
{
   RL_History_Type *h;

   if ((rli == NULL) || (hist == NULL))
     return -1;

   if (NULL == (h = (RL_History_Type *) SLcalloc (1, sizeof (RL_History_Type)))
       || (NULL == (h->buf = SLmake_string (hist))))
     {
	SLfree ((char *)h);
	return -1;
     }

   if (rli->tail != NULL)
     rli->tail->next = h;
   
   h->prev = rli->tail;
   rli->tail = h;
   h->next = NULL;
   
   h->point = h->len = strlen (hist);
   return 0;
}
   
  
int SLrline_save_line (SLrline_Type *rli)
{
   if (rli == NULL)
     return -1;
   
   return SLrline_add_to_history (rli, (char *) rli->buf);
}

SLkeymap_Type *SLrline_get_keymap (SLrline_Type *rli)
{
   if (rli == NULL)
     return NULL;
   return rli->keymap;
}

int SLrline_set_update_hook (SLrline_Type *rli, 
			     void (*fun)(SLrline_Type *, char *, char *, unsigned int, unsigned int, VOID_STAR),
			     VOID_STAR client_data)
{
   if (rli == NULL)
     return -1;
   
   rli->update_hook = fun;
   rli->update_client_data = client_data;
   return 0;
}

char *SLrline_get_line (SLrline_Type *rli)
{
   if (rli == NULL)
     return NULL;
   return SLmake_nstring ((char *)rli->buf, rli->len);
}

int SLrline_get_point (SLrline_Type *rli, unsigned int *pointp)
{
   if (rli == NULL)
     return -1;
   *pointp = rli->point;
   return 0;
}

int SLrline_set_point (SLrline_Type *rli, unsigned int point)
{
   if (rli == NULL)
     return -1;
   
   if (rli->state == RLI_LINE_INVALID)
     return -1;

   if (rli->len > point)
     point = rli->len;
   
   rli->point = point;
   return 0;
}

int SLrline_get_tab (SLrline_Type *rli, unsigned int *p)
{
   if (rli == NULL)
     return -1;
   *p = rli->tab;
   return 0;
}

int SLrline_set_tab (SLrline_Type *rli, unsigned int tab)
{
   if (rli == NULL)
     return -1;
   
   rli->tab = tab;
   return 0;
}

int SLrline_get_hscroll (SLrline_Type *rli, unsigned int *p)
{
   if (rli == NULL)
     return -1;
   *p = rli->hscroll;
   return 0;
}

int SLrline_set_hscroll (SLrline_Type *rli, unsigned int p)
{
   if (rli == NULL)
     return -1;
   rli->hscroll = p;
   return 0;
}

int SLrline_set_line (SLrline_Type *rli, char *buf)
{
   unsigned int len;

   if (rli == NULL)
     return -1;

   if (buf == NULL)
     buf = "";
   
   len = strlen (buf);

   buf = SLmake_string (buf);
   if (buf == NULL)
     return -1;
   
   SLfree ((char *)rli->buf);
   rli->buf = (unsigned char *)buf;
   rli->buf_len = len;

   rli->point = len;
   rli->len = len;
   
   rli->state = RLI_LINE_SET;
   return 0;
}

int SLrline_set_echo (SLrline_Type *rli, int state)
{
   if (rli == NULL)
     return -1;

   if (state == 0)
     rli->flags |= SL_RLINE_NO_ECHO;
   else
     rli->flags &= ~SL_RLINE_NO_ECHO;

   return 0;
}

int SLrline_get_echo (SLrline_Type *rli, int *statep)
{
   if (rli == NULL)
     return -1;
   
   *statep = (0 == (rli->flags & SL_RLINE_NO_ECHO));
   return 0;
}

int SLrline_set_display_width (SLrline_Type *rli, unsigned int w)
{
   if (rli == NULL)
     return -1;
   
   rli->edit_width = w;
   return 0;
}
