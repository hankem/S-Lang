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
#define SLRL_DISPLAY_BUFFER_SIZE 4096  /* reasonable size for UTF-8 */

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

   /* These two contain an image of what is on the display.  They are 
    * used by the default display handling functions. (update_hook is NULL)
    */
   unsigned char upd_buf1[SLRL_DISPLAY_BUFFER_SIZE];
   unsigned char upd_buf2[SLRL_DISPLAY_BUFFER_SIZE];
   unsigned char *old_upd, *new_upd;   /* pointers to previous two buffers */
   int new_upd_len, old_upd_len;       /* length of output buffers */
   unsigned int last_nonblank_column;  /* column of last none blank char */

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
int SLrline_bol (SLrline_Type *This_RLI)
{
   This_RLI->point = 0;
   return 0;
}

int SLrline_eol (SLrline_Type *This_RLI)
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

static int rl_delbol (SLrline_Type *This_RLI)
{
   while (This_RLI->point)
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
   (void) SLrline_bol (This_RLI);
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

static SLuchar_Type *compute_char_width (SLuchar_Type *b, SLuchar_Type *bmax, int utf8_mode, unsigned int *wp, SLwchar_Type *wchp, int *illegalp)
{
   SLwchar_Type wch;

   if (illegalp != NULL) *illegalp = 0;

   if (b >= bmax)
     {
	*wp = 0;
	if (wchp != NULL) *wchp = 0;
	return b;
     }

   if (utf8_mode == 0)
     {
	*wp = Char_Widths[*b];
	if (wchp != NULL) *wchp = *b;
	return b + 1;
     }
   
   if (NULL == SLutf8_decode (b, bmax, &wch, NULL))
     {
	/* Illegal byte sequence */
	*wp = 4;   /* <XX> */
	if (wchp != NULL) *wchp = *b;
	if (illegalp != NULL) *illegalp = 1;
	return b + 1;
     }

   /* skip combining */
   if ((wch >= ' ') && (wch < 127))
     *wp = 1;
   else if (wch > 127)
     *wp = SLwchar_wcwidth (wch);
   else
     *wp = 2;			       /* ^X */
   
   if (wchp != NULL) *wchp = wch;
   /* skip combining chars too */
   return SLutf8_skip_chars (b, bmax, 1, NULL, 1);
}

/* This update is designed for dumb terminals.  It assumes only that the
 * terminal can backspace via ^H, and move cursor to start of line via ^M.
 * There is a hook so the user can provide a more sophisticated update if
 * necessary.
 */
static void position_cursor (SLrline_Type *This_RLI, int col)
{
   unsigned char *p, *pmax;
   unsigned int len, dlen;
   int curs_pos;
   int dc;
   int utf8_mode = This_RLI->flags & SL_RLINE_UTF8_MODE;

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

   curs_pos = This_RLI->curs_pos;
   dc = This_RLI->curs_pos - col;
   if (dc < 0)
     {
	p = This_RLI->new_upd;
	pmax = p + SLRL_DISPLAY_BUFFER_SIZE;

	len = 0;
	while (((int)len < curs_pos) && (p < pmax))
	  {
	     p = compute_char_width (p, pmax, utf8_mode, &dlen, NULL, NULL);
	     len += dlen;
	  }
	while (((int)len < col) && (p < pmax))
	  {
	     SLuchar_Type *p1;
	     p1 = compute_char_width (p, pmax, utf8_mode, &dlen, NULL, NULL);
	     while (p < p1)
	       putc((char) *p++, stdout);
	       
	     len += dlen;
	  }
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
	     pmax = p + SLRL_DISPLAY_BUFFER_SIZE;
	     len = 0;
	     while (((int)len < col) && (p < pmax))
	       {
		  SLuchar_Type *p1;
		  p1 = compute_char_width (p, pmax, utf8_mode, &dlen, NULL, NULL);
		  while (p < p1)
		    putc((char) *p++, stdout);
		  len += dlen;
	       }
	  }
     }
   This_RLI->curs_pos = col;
   fflush (stdout);
}

static void erase_eol (SLrline_Type *rli)
{
   int col = rli->curs_pos;
   int col_max = rli->last_nonblank_column;
   
   while (col < col_max)
     {
	putc(' ', stdout);
	col++;
     }
   rli->curs_pos = col_max;
}

static void spit_out(SLrline_Type *rli, SLuchar_Type *p, SLuchar_Type *pmax, int col)
{
   int utf8_mode = rli->flags & SL_RLINE_UTF8_MODE;
   position_cursor (rli, col);
   while (p < pmax) 
     {
	SLuchar_Type *p1;
	unsigned int dcol;
	p1 = compute_char_width (p, pmax, utf8_mode, &dcol, NULL, NULL);
	while (p < p1)
	  putc((char) *p++, stdout);
	col += dcol;
     }
   rli->curs_pos = col;
}

static void really_update (SLrline_Type *rli, int new_curs_position)
{
   SLuchar_Type *b, *bmax, *p, *pmax;
   unsigned int col, max_col;
   int utf8_mode = rli->flags & SL_RLINE_UTF8_MODE;

   col = 0;
   max_col = rli->edit_width-1;
   b = rli->old_upd;
   p = rli->new_upd;
   bmax = b + rli->old_upd_len;
   pmax = p + rli->new_upd_len;

   while (col < max_col)
     {
	SLwchar_Type pch, bch;
	SLuchar_Type *p1, *b1;
	unsigned int plen, blen;

	b1 = compute_char_width (b, bmax, utf8_mode, &blen, &bch, NULL);
	p1 = compute_char_width (p, pmax, utf8_mode, &plen, &pch, NULL);
	
	if ((p1 != p) && ((b1-b) == (p1-p))
	    && (bch == pch))
	  {
	     col += plen;
	     b = b1;
	     p = p1;
	     continue;
	  }
	
	spit_out (rli, p, pmax, col);

	col = rli->curs_pos;
	if (col < rli->last_nonblank_column)
	  erase_eol (rli);
	rli->last_nonblank_column = col;

	break;
     }

   position_cursor (rli, new_curs_position);

   /* update finished, so swap */

   rli->old_upd_len = rli->new_upd_len;
   p = rli->old_upd;
   rli->old_upd = rli->new_upd;
   rli->new_upd = p;
}

static SLuchar_Type *
  compute_tabbed_char_width (SLuchar_Type *b, SLuchar_Type *bmax, 
			     int utf8_mode, int col, int tab_width,
			     unsigned int *dlenp)
{
   if (b >= bmax)
     {
	*dlenp = 0;
	return bmax;
     }

   if ((*b == '\t') && tab_width)
     {
	*dlenp = tab_width * (col / tab_width + 1) - col;
	return b+1;
     }

   return compute_char_width (b, bmax, utf8_mode, dlenp, NULL, NULL);
}

static unsigned int compute_string_width (SLrline_Type *rli, SLuchar_Type *b, SLuchar_Type *bmax, unsigned int tab_width)
{
   int utf8_mode = rli->flags & SL_RLINE_UTF8_MODE;
   unsigned int len;

   if (b == NULL)
     return 0;
   
   len = 0;
   while (b < bmax)
     {
	unsigned int dlen;

	if ((*b == '\t') && tab_width)
	  {
	     dlen = tab_width * (len / tab_width + 1) - len;
	     b++;
	  }
	else b = compute_char_width (b, bmax, utf8_mode, &dlen, NULL, NULL);

	len += dlen;
     }
   return len;
}

static void RLupdate (SLrline_Type *rli)
{
   unsigned int len, dlen, prompt_len = 0, tw = 0, count;
   unsigned int start_len;
   int want_cursor_pos;
   unsigned char *b, *bmax, *b_point, *p, *pmax;
   int no_echo;
   int utf8_mode;
   unsigned int edit_width;

   no_echo = rli->flags & SL_RLINE_NO_ECHO;
   utf8_mode = rli->flags & SL_RLINE_UTF8_MODE;
   edit_width = rli->edit_width-1;

   *(rli->buf + rli->len) = 0;
   
   if (rli->update_hook != NULL)
     {
	if (no_echo)
	  (*rli->update_hook) (rli, rli->prompt, "", 0, 0, rli->update_client_data);
	else
	  (*rli->update_hook) (rli, rli->prompt, (char *)rli->buf, rli->len, rli->point, rli->update_client_data);
	return;
     }


   /* expand characters for output buffer --- handle prompt first.
    * Do two passes --- first to find out where to begin upon horiz
    * scroll and the second to actually fill the buffer. */
   len = 0;
   b = (unsigned char *) rli->prompt;
   if (b != NULL)
     {
	bmax = b + strlen ((char *)b);
	len += compute_string_width (rli, b, bmax, 0);
     }
   prompt_len = len;

   b = (unsigned char *) rli->buf;
   b_point = (unsigned char *) (rli->buf + rli->point);
   if (no_echo == 0)
     len += compute_string_width (rli, b, b_point, rli->tab);

   if (len + rli->hscroll < edit_width) start_len = 0;
   else if ((rli->start_column > (int)len)
	    || (rli->start_column + (int)edit_width <= (int)len))
     start_len = (len + rli->hscroll) - edit_width;
   else start_len = rli->start_column;
   rli->start_column = start_len;

   /* want_cursor_pos = len - start_len; */

   /* second pass */
   b = (unsigned char *) rli->prompt;
   if (b == NULL) b = (unsigned char *) "";
   bmax = b + strlen ((char *)b);
   len = 0;
   count = 2;
   while ((len < start_len) && (b < bmax))
     {
	b = compute_tabbed_char_width (b, bmax, utf8_mode, 0, 0, &dlen);
	len += dlen;
     }

   tw = 0;
   if (b == bmax)
     {
	b = (unsigned char *) rli->buf;
	bmax = b + strlen ((char *)b);
	tw = rli->tab;
	while ((len < start_len) && (b < bmax))
	  {
	     b = compute_tabbed_char_width (b, bmax, utf8_mode, 0, tw, &dlen);
	     len += dlen;
	  }
	count--;
     }

   len = 0;
   p = rli->new_upd;
   pmax = p + SLRL_DISPLAY_BUFFER_SIZE;
   want_cursor_pos = -1;

   while (count--)
     {
	if ((count == 0) && (no_echo))
	  break;

	while ((len < edit_width) && (b < bmax))
	  {
	     SLwchar_Type wch;
	     int is_illegal;
	     SLuchar_Type *b1;
	     
	     if (b == b_point)
	       want_cursor_pos = len;

	     if ((*b == '\t') && tw)
	       {
		  dlen = tw * ((len + start_len - prompt_len) / tw + 1) - (len + start_len - prompt_len);
		  len += dlen;	       /* ok since dlen comes out 0  */
		  if (len > edit_width) dlen = len - edit_width;
		  while (dlen-- && (p < pmax)) *p++ = ' ';
		  b++;
		  continue;
	       }

	     b1 = compute_char_width (b, bmax, utf8_mode, &dlen, &wch, &is_illegal);
	     if (len + dlen > edit_width)
	       {		       
		  /* The character is double width and a portion of it exceeds 
		   * the edit width
		   */
		  break;
	       }

	     if (is_illegal == 0)
	       {
		  if (wch < 32)
		    {
		       if (p < pmax) *p++ = '^';
		       if (p < pmax) *p++ = *b + '@';
		    }
		  else if (wch == 127)
		    {
		       if (p < pmax) *p++ = '^';
		       if (p < pmax) *p++ = '?';
		    }
		  else while (b < b1) 
		    {
		       if (p < pmax) *p++ = *b++;
		    }
	       }
	     else
	       {
		  if (p + 4 < pmax) 
		    {
		       sprintf ((char *)p, "<%02X>", *b);
		       p += 4;
		    }
	       }
	     b = b1;
	     len += dlen;
	  }
	/* if (start_len > prompt_len) break; */
	tw = rli->tab;
	b = (unsigned char *) rli->buf;
	bmax = b + strlen ((char *)b);
     }
   
   if (want_cursor_pos == -1)
     want_cursor_pos = len;

   rli->new_upd_len = (int) (p - rli->new_upd);
   while ((p < pmax) && (len < edit_width))
     {
	*p++ = ' ';
	len++;
     }
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
   AKEY("bol", SLrline_bol),
   AKEY("eol", SLrline_eol),
   AKEY("right", rl_right),
   AKEY("left", rl_left),
   AKEY("self_insert", rl_self_insert),
   AKEY("bdel", rl_bdel),
   AKEY("del", rl_del),
   AKEY("deleol", rl_deleol),
   AKEY("delbol", rl_delbol),
   AKEY("enter", rl_enter),
   AKEY("trim", rl_trim),
   AKEY("quoted_insert", rl_quote_insert),
   AKEY(NULL, NULL),
};


static void free_history (SLrline_Type *rli)
{
   RL_History_Type *h;
   
   h = rli->root;
   while (h != NULL)
     {
	RL_History_Type *next = h->next;
	if (h->buf != NULL)
	  SLfree (h->buf);
	SLfree ((char *)h);
	h = next;
     }
}
	     
void SLrline_close (SLrline_Type *rli)
{
   if (rli == NULL)
     return;
   
   free_history (rli);
   SLfree (rli->prompt);
   SLfree ((char *)rli->buf);
   SLfree ((char *)rli);
}

SLrline_Type *SLrline_open (unsigned int width, unsigned int flags)
{
   int ch;
   char simple[2];
   SLrline_Type *rli;

   if (_pSLutf8_mode)
     flags |= SL_RLINE_UTF8_MODE;

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
	SLkm_define_key  ("^@O", (FVOID_STAR) SLrline_eol, RL_Keymap);
	SLkm_define_key  ("^@G", (FVOID_STAR) SLrline_bol, RL_Keymap);

	SLkm_define_key  ("\xE0H", (FVOID_STAR) rl_prev_line, RL_Keymap);
	SLkm_define_key  ("\xE0P", (FVOID_STAR) rl_next_line, RL_Keymap);
	SLkm_define_key  ("\xE0M", (FVOID_STAR) rl_right, RL_Keymap);
	SLkm_define_key  ("\xE0K", (FVOID_STAR) rl_left, RL_Keymap);
	SLkm_define_key  ("\xE0S", (FVOID_STAR) rl_del, RL_Keymap);
	SLkm_define_key  ("\xE0O", (FVOID_STAR) SLrline_eol, RL_Keymap);
	SLkm_define_key  ("\xE0G", (FVOID_STAR) SLrline_bol, RL_Keymap);
#endif
	SLkm_define_key  ("^C", (FVOID_STAR) rl_abort, RL_Keymap);
	SLkm_define_key  ("^E", (FVOID_STAR) SLrline_eol, RL_Keymap);
	SLkm_define_key  ("^G", (FVOID_STAR) rl_abort, RL_Keymap);
	SLkm_define_key  ("^I", (FVOID_STAR) rl_self_insert, RL_Keymap);
	SLkm_define_key  ("^A", (FVOID_STAR) SLrline_bol, RL_Keymap);
	SLkm_define_key  ("\r", (FVOID_STAR) rl_enter, RL_Keymap);
	SLkm_define_key  ("\n", (FVOID_STAR) rl_enter, RL_Keymap);
	SLkm_define_key  ("^K", (FVOID_STAR) rl_deleol, RL_Keymap);
	SLkm_define_key  ("^L", (FVOID_STAR) rl_deleol, RL_Keymap);
	SLkm_define_key  ("^U", (FVOID_STAR) rl_delbol, RL_Keymap);
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

   if (rli->root == NULL)
     rli->root = h;

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
   if (w < 1)
     w = 80;
   rli->edit_width = w;
   return 0;
}
