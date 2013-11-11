\function{slsmg_suspend_smg}
\synopsis{Suspend screen management}
\usage{slsmg_suspend_smg ()}
\description
  The \ifun{slsmg_suspend_smg} function can be used to suspend the state of the
  screen management facility during suspension of the program.  Use of
  this function will reset the display back to its default state.  The
  funtion \ifun{slsmg_resume_smg} should be called after suspension.

  This function is similar to \ifun{slsmg_reset_smg} except that the
  state of the display prior to calling \ifun{slsmg_suspend_smg} is saved.
\seealso{slsmg_resume_smg, slsmg_reset_smg}
\done

\function{slsmg_resume_smg}
\synopsis{Resume screen management}
\usage{slsmg_resume_smg ()}
\description
  The \ifun{slsmg_resume_smg} function should be called after
  \ifun{slsmg_suspend_smg} to redraw the display exactly like it was
  before \ifun{slsmg_suspend_smg} was called.
\seealso{slsmg_suspend_smg}
\done

\function{slsmg_erase_eol}
\synopsis{Erase to the end of the row}
\usage{slsmg_erase_eol ()}
\description
  The \ifun{slsmg_erase_eol} function erases all characters from the current
  position to the end of the line.  The newly created space is given
  the color of the current color.  This function has no effect on the
  position of the virtual cursor.
\seealso{slsmg_gotorc, slsmg_erase_eos, slsmg_fill_region}
\done

\function{slsmg_gotorc}
\synopsis{Move the virtual cursor}
\usage{slsmg_gotorc (Integer_Type r, c)}
\description
  The \ifun{slsmg_gotorc} function moves the virtual cursor to the row
  \var{r} and column \var{c}.  The first row and first column is
  specified by \exmp{r = 0} and \exmp{c = 0}.
\seealso{slsmg_refresh}
\done

\function{slsmg_erase_eos}
\synopsis{Erase to the end of the screen}
\usage{slsmg_erase_eos ()}
\description
  The \ifun{slsmg_erase_eos} function is like \ifun{slsmg_erase_eol}
  except that it erases all text from the current position to the
  end of the display.  The current color will be used to set the
  background of the erased area.
\seealso{slsmg_erase_eol}
\done

\function{slsmg_reverse_video}
\synopsis{Set the current color to 1}
\usage{slsmg_reverse_video ()}
\description
  This function is nothing more than \exmp{slsmg_set_color(1)}.
\seealso{slsmg_set_color}
\done

\function{slsmg_set_color}
\synopsis{Set the current color}
\usage{slsmg_set_color (Integer_Type c)}
\description
  The \ifun{slsmg_set_color} function is used to set the current
  color.  The parameter \var{c} is a color object descriptor.
  Actual foreground and background colors may be associated with a
  color descriptor via the \ifun{slsmg_define_color} function.
\example
  This example defines color \exmp{7} to be green foreground on black
  background and then displays some text in this color:
#v+
      require ("slsmg");
      variable
        ref,
        row = SLsmg_Screen_Rows / 2,
        txt = [
          "This should be displayed in green under a black background",
          "Press enter to close this window"];

      slsmg_init_smg ();
      slsmg_define_color (7, "green", "black");
      slsmg_gotorc (row, SLsmg_Screen_Cols / 2 - strlen (txt[0]) / 2);
      slsmg_set_color (7);
      slsmg_write_string (txt[0]);
      row++;
      slsmg_gotorc (row, SLsmg_Screen_Cols / 2 - strlen (txt[1]) / 2);
      slsmg_write_string (txt[1]);
      slsmg_refresh ();

      ()=fgets(&ref, stdin);
#v-
\done

\function{slsmg_normal_video}
\synopsis{Set the current color to 0}
\usage{slsmg_normal_video ()}
\description
  The \ifun{slsmg_normal_video} function sets the current color descriptor to \var{0}.
\seealso{slsmg_set_color}
\done

\function{slsmg_write_string}
\usage{slsmg_write_string (String_Type s)}
\done

\function{slsmg_cls}
\synopsis{Clear the virtual display}
\usage{slsmg_cls ()}
\description
  The \ifun{slsmg_cls} function erases the virtual display using
  the current color.  This will cause the physical display to get
  cleared the next time \ifun{slsmg_refresh} is called.
\notes
  This function is not the same as
#v+
     slsmg_gotorc (0,0); slsmg_erase_eos ();
#v-
  since these statements do not guarantee that the physical screen
  will get cleared.
\seealso{slsmg_refresh, slsmg_erase_eos}
\done

\function{slsmg_refresh}
\synopsis{Update physical screen}
\usage{slsmg_refresh ()}
\description
  The \ifun{slsmg_refresh} function updates the physical display to
  look like the virtual display.
\seealso{slsmg_suspend_smg, slsmg_init_smg, slsmg_reset_smg}
\done

\function{slsmg_reset_smg}
\synopsis{Reset the \var{SLsmg} routines}
\usage{slsmg_reset_smg ()}
\description
  The \ifun{slsmg_reset_smg} function resets the \var{SLsmg}
  screen management routines by freeing all memory allocated
  while it was active and also put the terminal's display in
  it's default state.
\seealso{slsmg_init_smg}
\done

\function{slsmg_init_smg}
\synopsis{Initialize the \var{SLsmg} routines}
\usage{slsmg_init_smg ()}
\description
  The \ifun{slsmg_init_smg} function initializes the \var{SLsmg} screen
  management routines.   Specifically, this function allocates space
  for the virtual display and puts the terminal's physical display in
  the proper state.

  This function should also be called any time the size of the
  physical display has changed so that it can reallocate a new virtual
  display to match the physical display.

\seealso{slsmg_reset_smg}
\done

\function{slsmg_write_nstring}
\synopsis{Write the first n characters of a string on the display}
\usage{slsmg_write_nstring (String_Type s, Integer_Type len)}
\description
  The \ifun{slsmg_write_nstring} function writes the first \var{n}
  characters of \var{s} to this virtual display.  If the length of
  the string \var{s} is less than \var{n}, the spaces will used until
  \var{n} characters have been written.  \var{s} can be \var{NULL}, in
  which case \var{n} spaces will be written.
\seealso{slsmg_write_string}
\done

\function{slsmg_write_wrapped_string}
\synopsis{Write a string to the display with wrapping}
\usage{slsmg_write_wrapped_string (String_Type s, Integer_Type r, c, dr, dc, fill)}
\description
  The \ifun{slsmg_write_wrapped_string} function writes the
  string \var{s} to the virtual display.  The string will be confined
  to the rectangular region whose upper right corner is at row \var{r}
  and column \var{c}, and consists of \var{nr} rows and \var{dc} columns.
  The string will be wrapped at the boundaries of the box.  If \var{fill}
  is non-zero, the last line to which characters have been written will
  get padded with spaces.
\notes
  This function does not wrap on word boundaries.  However, it will
  wrap when a newline charater is encountered.
\seealso{slsmg_write_string}
\done

\function{slsmg_char_at}
\synopsis{Get the character at the current position on the virtual display}
\usage{Integer_Type slsmg_char_at ()}
\description
  The \ifun{slsmg_char_at} function returns the character and its color
  at the current position on the virtual display.
\done

\function{slsmg_set_screen_start}
\synopsis{Set the origin of the virtual display}
\usage{slsmg_set_screen_start (Integer_Type r, c)}
\description
  The \ifun{slsmg_set_screen_start} function sets the origin of
  the virtual display to the row \var{r} and the column \var{c}.
\seealso{slsmg_init_smg}
\done

\function{slsmg_draw_hline}
\synopsis{Draw a horizontal line}
\usage{slsmg_draw_hline (Integer_Type len)}
\description
  The \ifun{slsmg_draw_hline} function draws a horizontal line of
  length \var{len} on the virtual display.  The position of the
  virtual cursor is left at the end of the line.
\seealso{slsmg_draw_vline}
\done

\function{slsmg_draw_vline}
\synopsis{Draw a vertical line}
\usage{slsmg_draw_vline (Integer_Type len)}
\description
  The \ifun{slsmg_draw_vline} function draws a vertical line of
  length \var{len} on the virtual display.  The position of the
  virtual cursor is left at the end of the line.
\done

\function{slsmg_draw_object}
\synopsis{Draw an object from the alternate character set}
\usage{slsmg_draw_object (Integer_Type r, c, obj)}
\description
  The \ifun{slsmg_draw_object} function may be used to place the object
  specified by \var{obj} at row \var{r} and column \var{c}.  The
  object is really a character from the alternate character set and
  may be specified using one of the following constants:
#v+
    SLSMG_HLINE_CHAR         Horizontal line
    SLSMG_VLINE_CHAR         Vertical line
    SLSMG_ULCORN_CHAR        Upper left corner
    SLSMG_URCORN_CHAR        Upper right corner
    SLSMG_LLCORN_CHAR        Lower left corner
    SLSMG_LRCORN_CHAR        Lower right corner
    SLSMG_CKBRD_CHAR         Checkboard character
    SLSMG_RTEE_CHAR          Right Tee
    SLSMG_LTEE_CHAR          Left Tee
    SLSMG_UTEE_CHAR          Up Tee
    SLSMG_DTEE_CHAR          Down Tee
    SLSMG_PLUS_CHAR          Plus or Cross character
#v-
\seealso{slsmg_draw_vline, slsmg_draw_hline, slsmg_draw_box}
\done

\function{slsmg_draw_box}
\synopsis{Draw a box on the virtual display}
\usage{slsmg_draw_box (Integer_Type r, c, dr, dc)}
\description
  The \ifun{slsmg_draw_box} function uses the \ifun{slsmg_draw_hline} and
  \ifun{slsmg_draw_vline} functions to draw a rectangular box on the
  virtual display.  The box's upper left corner is placed at row
  \var{r} and column \var{c}.  The length and width of the box is
  specified by \var{dr} and \var{dc}, respectively.
\seealso{slsmg_draw_vline, slsmg_draw_hline, slsmg_draw_object}
\done

\function{slsmg_get_column}
\synopsis{Get the column of the virtual cursor}
\usage{Integer_Type slsmg_get_column ()}
\description
  The \ifun{slsmg_get_column} function returns the current column of
  the virtual cursor on the virtual display.
\seealso{slsmg_get_row, slsmg_gotorc}
\done

\function{slsmg_get_row}
\synopsis{Get the row of the virtual cursor}
\usage{Integer_Type slsmg_get_row ()}
\description
  The \ifun{slsmg_get_row} function returns the current row of the
  virtual cursor on the virtual display.
\seealso{slsmg_get_column, slsmg_gotorc}
\done

\function{slsmg_forward}
\synopsis{Move the virtual cursor forward n columns}
\usage{slsmg_forward (Integer_Type n)}
\description
  The \ifun{slsmg_forward} function moves the virtual cursor forward
  \var{n} columns.
\seealso{slsmg_gotorc}
\done

\function{slsmg_set_color_in_region}
\synopsis{Change the color of a specifed region}
\usage{slsmg_set_color_in_region (Integer_Type color, r, c, dr, dc)}
\description
  The \ifun{slsmg_set_color_in_region} function may be used to
  change the color of a rectangular region whose upper left corner
  is given by (\var{r},\var{c}), and whose height and width is given
  by \var{dr} and \var{dc}, respectively.  The color of the region
  is given by the \var{color} parameter.
\seealso{slsmg_draw_box, slsmg_set_color}
\done

\function{slsmg_define_color}
\usage{slsmg_define_color (Integer_Type obj, String_Type fg, bg)}
\description
  The \ifun{slsmg_define_color} function associates the color
  descriptor \exmp{obj} with a foreground and a background color.
  The \exmp{fg} and \exmp{bg} colors can be one of the following strings:
#v+
  "color0" or "black",      "color8"  or "gray",
  "color1" or "red",        "color9"  or "brightred",
  "color2" or "green",      "color10" or "brightgreen",
  "color3" or "brown",      "color11" or "yellow",
  "color4" or "blue",       "color12" or "brightblue",
  "color5" or "magenta",    "color13" or "brightmagenta",
  "color6" or "cyan",       "color14" or "brightcyan",
  "color7" or "lightgray",  "color15" or "white"
#v-
\done

\function{slsmg_write_to_status_line}
\usage{slsmg_write_to_status_line (String_Type s)}
\done
