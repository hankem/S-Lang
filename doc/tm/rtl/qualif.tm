\function{qualifier}
\synopsis{Get the value of a qualifier}
\usage{value = qualifier (String_Type name [,default_value])}
\description
 This function may be used to get the value of a qualifier.  If the
 specified qualifier does not exist, \exmp{NULL} will be returned,
 unless a default value has been provided.
\example
#v+
    define echo (text)
    {
       variable fp = qualifier ("out", stdout);
       () = fputs (text, fp);
    }
    echo ("hello");              % writes hello to stdout
    echo ("hello"; out=stderr);  % writes hello to stderr
#v-
\notes
 Since \exmp{NULL} is a valid value for a qualifier, this function is
 unable to distinguish between a non-existent qualifier and one whose
 value is \exmp{NULL}.  If such a distinction is important, the
 \ifun{qualifier_exists} function can be used.  For example,
#v+
    define echo (text)
    {
       variable fp = stdout;
       if (qualifier_exists ("use_stderr"))
         fp = stderr;
       () = fputs (text, fp);
    }
    echo ("hello"; use_stderr);  % writes hello to stderr
#v-

 Prior to version 2.3.0, the \ifun{qualifier} function would always
 return \NULL for qualifiers without values.  This behavior was
 changed in version 2.3.0 such that a qualifier without a value
 assigned will be implicitely given a default value of 1 instead of
 \NULL.  That is, in versions 2.3.0 and later,
#v+
   echo ("hello"; use_stderr);
   echo ("hello"; use_stderr=1);
#v-
 are equivalent forms, whereas in versions prior to 2.3.0,
#v+
   echo ("hello"; use_stderr);
   echo ("hello"; use_stderr=NULL);
#v-
 are the same.

 The semantic change introduced in version 2.3.0 simplifies some
 common uses of the qualifier function.  For example, consider the
 following version of the \exmp{echo} function:
#v+
    define echo (text)
    {
       variable fp = stdout;
       if (qualifier ("use_stderr"))
         fp = stderr;
       () = fputs (text, fp);
    }
    echo ("hello"; use_stderr);     % write hello to stderr
    echo ("world"; use_stderr=1);   % writes world to stderr
    echo ("goodbye"; use_stderr=0); % writes goodbye to stdout
#v-
  Using versions 2.3.0 and later, both \exmp{"hello"} and
  \exmp{"world"} will be written to \exmp{stderr} since they are
  equivalent forms.  However, on versions prior to 2.3.0,
  \exmp{"hello"} would be written to \exmp{stdout} since no value was
  assigned to the \exmp{use_stderr} qualifier, resulting in \NULL being
  returned from the \ifun{qualifier} function, and \NULL evaluates to
  false in a boolean context.

  To achive the same effect with earler versions of the interpreter
  both the \ifun{qualifier} and \ifun{qualifier_exists} functions
  were required:
#v+
    define echo (text)
    {
       variable fp = stdout;
       if (qualifier_exists ("use_stderr")
           && (0 != qualifier ("use_stderr")))
         fp = stderr;
       () = fputs (text, fp);
    }
#v-
  Note that this form also works with version 2.3.0 and later.
\seealso{qualifier_exists, __qualifiers}
\done

\function{__qualifiers}
\synopsis{Get the active set of qualifiers}
\usage{Struct_Type __qualifiers ()}
\description
 This function returns the set of qualifiers associated with the
 current execution context.  If qualifiers are active, then the result
 is a structure representing the names of the qualifiers and their
 corresponding values.  Otherwise \exmp{NULL} will be returned.

 One of the main uses of this function is to pass the current set of
 qualifiers to another another function.  For example, consider a
 plotting application with a function called called \exmp{lineto} that
 sets the pen-color before drawing the line to the specified point:
#v+
    define lineto (x, y)
    {
       % The color may be specified by a qualifier, defaulting to black
       variable color = qualifier ("color", "black");
       set_pen_color (color);
           .
           .
    }
#v-
 The \exmp{lineto} function permits the color to be specified by a
 qualifier.  Now consider a function that make use of lineto to draw a
 line segment between two points:
#v+
    define line_segment (x0, y0, x1, y1)
    {
       moveto (x0, y0);
       lineto (x1, y1 ; color=qualifier("color", "black"));
    }
    line_segment (1,1, 10,10; color="blue");
#v-
 Note that in this implementation of \exmp{line_segment}, the
 \exmp{color} qualifier was explicitly passed to the \exmp{lineto}
 function.  However, this technique does not scale well.  For example, the
 \exmp{lineto} function might also take a qualifier that specifies the
 line-style, to be used as
#v+
    line_segment (1,1, 10,10; color="blue", linestyle="solid");
#v-
 But the above implementation of \exmp{line_segment} does not pass the
 \exmp{linestyle} qualifier.  In such a case, it is preferable to pass
 all the qualifiers, e.g.,
#v+
    define line_segment (x0, y0, x1, y1)
    {
       moveto (x0, y0);
       lineto (x1, y1 ;; __qualifiers());
    }
#v-
 Note the use of the double-semi colon in the \exmp{lineto}
 statement.  This tells the parser that the qualifiers are specified
 by a structure-valued argument and not a set of name-value pairs.
\seealso{qualifier, qualifier_exists}
\done

\function{qualifier_exists}
\synopsis{Check for the existence of a qualifier}
\usage{Int_Type qualifier_exists (String_Type name)}
\description
 This function will return 1 if a qualifier of the specified name
 exists, or 0 otherwise.
\seealso{qualifier, __qualifiers}
\done

