\function{slsh_readline_init}
\synopsis{Initialize the S-Lang readline routines}
\usage{slsh_readline_init (String_Type appname)}
\description
 The \ifun{slsh_readline_init} function is used to initialize the
 \slang readline interface for use by an slsh-based application with
 name \exmp{appname}.  If defines an intrinsic variable called
 \ivar{__RL_APP__} whose value is given by \exmp{appname}.  If the
 file \exmp{$HOME/.slrlinerc} file exists, it will be loaded into the
 interpreter.  This file together with the \ivar{__RL_APP__} variable
 may be used by the user to customize the interface by, e.g., reading
 previous history files, etc.
\seealso{slsh_readline_new, rline_set_history}
\done

\function{slsh_readline_new}
\synopsis{Instantiate a readline object}
\usage{RLine_Type slsh_readline_new (String_Type name)}
\description
 This function instantiates a new readline object with the specified
 name and returns it.

 If a function called \exmp{name}_rline_open_hook exists, it will be
 called with no arguments.
\seealso{slsh_readline_init}
\done

\function{slsh_readline}
\synopsis{Get input from the user with command line editing}
\usage{String_Type slsh_readline ([RLine_Type r,] String_Type prompt)}
\description
 The \ifun{slsh_readline} function utilizes the \slang readline
 interface to read input from the terminal using the specified prompt.
 If two parameters are given, the value of the first one must be a
 \dtype{RLine_Type} object obtained previously from the
 \ifun{slsh_readline_new} function.
\seealso{slsh_readline_new, slsh_readline_init}
\done

\function{slsh_readline_noecho}
\synopsis{Get input from the user with command line editing without echo}
\usage{String_Type slsh_readline ([RLine_Type r,] String_Type prompt)}
\description
 This function is like \ifun{slsh_readline} except that the input is
 not echoed to the display.  This makes it useful for reading
 passwords, etc.
\seealso{slsh_readline, slsh_readline_new, slsh_readline_init}
\done


\function{slsh_set_readline_update_hook}
\synopsis{Specify an alternate display update function for a readline object}
\usage{slsh_set_readline_update_hook(RLine_Type rl [,&func [,funcdata]])}
\description
  This function may be used to implement an alternative update hook
  for the specified readline object.  The hook must have one of the
  following signatures, depending upon whether or not the optional
  \exmp{funcdata} was given:
#v+
   define func (rl, prompt, editbuf, editpoint) {...}
   define func (rl, prompt, editbuf, editpoint, funcdata) {...}
#v-
  The hook function is not expected to return anything.

  If \ifun{slsh_set_readline_update_hook} is called with a single
  argument, then any update hook associated with it will be set to the
  default value.
\seealso{slsh_readline_init, slsh_readline_new, slsh_readline}
\done

\function{slsh_set_update_preread_cb}
\synopsis{Specify a function to be called prior to reading via readline}
\usage{slsh_set_update_preread_cb (RLine_Type rl, Ref_Type func)}
\description
  This function may be used to specify a function to be called by
  \ifun{slsh_readline} prior to the editing loop.  It must have one of
  the following signatures:
#v+
    define func (rl) {...}
    define func (rl, funcdata);
#v-
  The second form must be used if a \exmp{funcdata} argument was
  passed to the \ifun{slsh_set_readline_update_hook} function.

  If the \exmp{func} argument is \NULL, then the callback function
  will be cleared.
\seealso{slsh_set_readline_update_hook, slsh_set_update_postread_cb}
\done

\function{slsh_set_update_postread_cb}
\synopsis{Specify a function to be called after reading via readline}
\usage{slsh_set_update_postread_cb (RLine_Type rl ,Ref_Type func)}
\description
  This function may be used to specify a function to be called by
  \ifun{slsh_readline} after to the editing loop before returning to
  the caller.  It must have one of
  the following signatures:
#v+
    define func (rl) {...}
    define func (rl, funcdata);
#v-
  The second form must be used if a \exmp{funcdata} argument was
  passed to the \ifun{slsh_set_readline_update_hook} function.

  If the \exmp{func} argument is \NULL, then the callback function
  will be cleared.
\seealso{slsh_set_readline_update_hook, slsh_set_update_postread_cb}
\done

\function{slsh_set_update_width_cb}
\synopsis{Specify a callback function to be called when the display width changes}
\usage{slsh_set_update_width_cb (RLine_Type rl, Ref_Type func)}
\description
  This function is used to set a callback function that will get
  called when the readline routines sense that the display width has
  changed.  It must have one of the following signatures:
#v+
    define func (rl, width) {...}
    define func (rl, width, funcdata);
#v-
  The second form must be used if a \exmp{funcdata} argument was
  passed to the \ifun{slsh_set_readline_update_hook} function.  The
  \exmp{width} argument to the callback function in an integer that
  specifies the new width.

  If the \exmp{func} argument is \NULL, then the callback function
  will be cleared.
\seealso{slsh_set_readline_update_hook, slsh_readline}
\done
