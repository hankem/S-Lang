\chapter{S-Lang 2 Interpreter NEWS}

\sect{What's new for \slang 2.1}

 The next section describes the features that were added to version
 2.0.  This section is devoted to what's new in version 2.1.  For a
 much more complete and detailed list of changes, see the
 \file{changes.txt} file that is distributed with the library.

\begin{itemize}
\item 
 Short circuiting boolean operators \exmp{||} and \exmp{&&}
 have been added to the languange.  The use of \exmp{orelse} and
 \exmp{andelse} constructs are nolonger necessary nor encouraged.
\item
 \em{Qualifiers} have been added to the language as a convenient
 and powerful mechanism to pass optional information to functions.
\item
 Structure definitions allow embeded assignemnts, e.g, 
#v+
    s = struct {foo = 3, bar = "hello" };
#v-
\item
  Comparison expressions such as \exmp{a<b<c} are now interpretered as
  \exmp{(a<b)and(b<c)}.
\item
  The \kw{ifnot} keyword was added as an alternative to \kw{!if}.  The
  use of \kw{!if} has been deprecated.
\item
  Looping constructs now support a "then" clause that will get
  executed if the loop runs to completion, e.g.,
#v+       
     loop (20)
       {
          if (this ())
            break;  % The then clause will NOT get executed
       }
     then do_that ();
#v-
  Note: \kw{then} is now a reserved word.
\item
  A floating point array of exactly N elements may be created
  using the form \exmp{[a:b:#N]}, where the elements are uniformly
  spaced and run from a to b, inclusive.
\item
  References to array elements and structure fields are now
  supported, e.g., \exmp{&A[3]}, \exmp{&s.foo}.
\item
  An exception may be rethrown by calling "throw" without any
  arguments:
#v+
    try { something (); }
    catch AnyError: { do_this (); throw; }
#v-
\end{itemize}

The following intrinsic function were added in version 2.1:
#d tagexmp#1 \tag{\exmp{$1}}
\begin{descrip}
\tagexmp{wherenot(x)} Equivalent to where (not(x))
\tagexmp{_$(str)}
  Evaluates strings with embedded "dollar" variables, e.g.,
  \exmp{_$("$TERM")}.
\tagexmp{__push_list/__pop_list} 
  Push list items onto the stack
\tagexmp{prod(x)}
  Computes the product of an array \exmp{a[0]*a[1]*...}
\tagexmp{minabs(x), maxabs(x)}
  Equivalent to \exmp{min(abs(x))} and \exmp{max(abs(x))}, resp.
\tagexmp{getpgrp, setgid, getpgid}
  Get and set the process group ids (Unix).
\tagexmp{setsid}
  Create a new session (Unix).
\end{descrip}

The following modules were added to version 2.1:
\begin{descrip}
  \tagexmp{iconv}
      Performs character-set conversion using the iconv library.
  \tagexmp{onig}
     A regular expression module using oniguruma RE library.
\end{descrip}

The following library files and functions were add to \slsh:
\begin{descrip}
\tagexmp{readascii} A flexible and power ascii (as opposed to binary)
  data file reader.
\tagexmp{cmdopt}  A set of functions that vastly simplify the parsing
of command line options.
\end{descrip}

Also a history and completion mechanism was added to the \slang
readline interface, and as a result, \slsh now supports history and
command/file completion.

\sect{What's new for \slang 2.0}

Here is a brief list of some of the new features and improvements in
\slang 2.0.

\begin{itemize}
\item \slsh, the generic \slang interpreter, now supports and
 interactive command-line mode with readline support.
\item Native support for Unicode via UTF-8 throughout the library.
\item A \dtype{List_Type} object has been added to the language, e.g.,
#v+
     x = {1, 2.7, "foo", [1:10]};
#v-  
  will create a (heterogeneous) list of 4 elements.
\item A much improved exception handling model.
\item Variable expansion within string literals:
#v+
    file = "$HOME/src/slang-$VERSION/"$;
#v-
\item Operator overloading for user-defined types.
 For example it is possible to define a meaning to \exmp{X+Y} where
 \exmp{X} and \exmp{Y} are defined as
#v+
    typedef struct { x, y, z } Vector;
    define vector (x,y,z) { variable v = @Vector; v.x=x; v.y=y; v.z=z;}
    X = vector (1,2,3);
    Y = vector (4,5,6);
#v-
\item Syntactic sugar for objected-oriented style method calls.
 \slang 1 code such as 
#v+

     (@s.method)(s, args);
#v-  
  may be written much more simply as
#v+
     s.method(args);
#v-
  This should make "object-oriented" code somewhat more readable.
  See also the next section if your code uses constructs such as
#v+
     @s.method(args);
#v-
  because it is not supported by \slang 2.

\item More intrinsic functions including math functions such
 as \ifun{hypot}, \ifun{atan2}, \ifun{floor}, \ifun{ceil},
 \ifun{round}, \ifun{isnan}, \ifun{isinf}, and many more.

\item Support for \exmp{long long} integers.
#v+
    X = 18446744073709551615ULL;
#v-
\item Large file support
\item Performance improvements.  The \slang 2 interpreter is about 20 percent
 faster for many operations than the previous version.
\item Better debugging support including an interactive debugger.  See
 \sectref{Using the sldb debugger} for more information.
\end{itemize}

See the relevent chapters in in the manual for more information.

\sect{Upgrading to \slang 2}

 For the most part \slang 2 is backwards-compatible with \slang 1.
 However there are a few important differences that need to be
 understood before upgrading to version 2.

\begin{descrip}
  \tag{++ and -- operators in function calls}
    Previously the \exmp{++} and {--} operators were permitted in
    a function argument list, e.g.,
#v+
    some_function (x++, x);
#v-
  Such uses are flagged as syntax errors and need to be changed to
#v+
    x++; some_function (x);
#v-

  \tag{Array indexing of strings}  Array indexing of strings uses
  byte-semantics and not character-semantics.  This distinction is
  important only if UTF-8 mode is in effect.  If you use array
  indexing with functions that use character semantics, then your code
  may not work properly in UTF-8 mode.  For example, one might have used
#v+
     i = is_substr (a, b);
     if (i) c = a[[0:i-2]];
#v-
  to extract that portion of \exmp{a} that preceeds the occurrence of
  \exmp{b} in \exmp{a}.  This may nolonger work in UTF-8 mode where
  bytes and characters are not generally the same.  The correct way to
  write the above is to use the \exmp{substr} function since it uses
  character semantics:
#v+
     i = is_substr (a, b);
     if (i) c = substr (a, 1, i-1);
#v-

  \tag{Array indexing with negative integer ranges} Previously the
    interpretation of a range array was context sensitive.  In an
    indexing situation \exmp{[0:-1]} was used to index from the first
    through the last element of an array, but outside this context,
    \exmp{[0:-1]} was an empty array.  For \slang2, the meaning of
    such arrays is always the same regardless of the context.  Since
    by itself \exmp{[0:-1]} represents an empty array, indexing with
    such an array will also produce an empty array.  The behavior of
    scalar indices has not changed: \exmp{A[-1]} still refers to the
    last element of the array.

    Range arrays with an implied endpoint make sense only in indexing
    situations.  Hence the value of the endpoint can be inferred from
    the context.  Such arrays include \exmp{[*]}, \exmp{[:-1]}, etc.

    Code that use index-ranges with negative valued indices such as
#v+
       B = A[[0:-2]];    % Get all but the last element of A
#v- 
    will have to be changed to use an array with an implied endpoint:
#v+
       B = A[[:-2]];     % Get all but the last element of A
#v-
    Similarly, code such as
#v+
       B = A[[-3:-1]];   % Get the last 3 elements of A
#v-
    must be changed to
#v+
       B = A[[-3:]];
#v-
\tag{Dereferencing function members of a structure}  Support for the
 non-parenthesized form of function member dereferencing has been
 dropped.  Code such as
#v+
     @s.foo(args);
#v-
 will need to be changed to use the parenthesized form:
#v+
     (@s.foo)(args);
#v-
 The latter form will work in both \slang 1 and \slang 2.

 If your code passes the structure as the first argument of the
 method call, e.g.,
#v+
     (@s.foo)(s, moreargs);
#v-
 then it may be changed to
#v+
     s.foo (moreargs);
#v-
 However, this \em{objected-oriented} form of method calling is not
 supported by \slang 1.

\tag{ERROR_BLOCKS}
    Exception handling via \exmp{ERROR_BLOCKS} is still supported but
    deprecated.  If your code uses \exmp{ERROR_BLOCKS} it should be
    changed to use the new exception handling model.  For example,
    code that looks like:
#v+
       ERROR_BLOCK { cleanup_after_error (); }
       do_something ();
          .
          .
#v-
   should be changed to:
#v+
       variable e;
       try (e)
         {
            do_something ();
              .
              .
         }
       catch RunTimeError: 
         {
            cleanup_after_error ();
            throw e.error, e.message;
         }
#v-

 Code that makes use of \exmp{EXECUTE_ERROR_BLOCK}
#v+
       ERROR_BLOCK { cleanup_after_error (); }
       do_something ();
          .
          .
       EXECUTE_ERROR_BLOCK;
#v-
   should be changed to make use of a \kw{finally} clause:
#v+
       variable e;
       try (e)
         {
            do_something ();
              .
              .
         }
       finally
         {
            cleanup_after_error ();
         }
#v-

 It is not possible to emulate the complete semantics of the
 \ifun{_clear_error} function.  However, those semantics are flawed
 and fixing the problems associated with the use of
 \ifun{_clear_error} was one of the primary reasons for the new
 exception handling model.  The main problem with the 
 \ifun{_clear_error} method is that it causes execution to resume at the
 byte-code following the code that triggered the error.  As such,
 \ifun{_clear_error} defines no absolute resumption point.  In
 contrast, the try-catch exception model has well-defined points of
 execution.  With the above caveats, code such as
#v+
       ERROR_BLOCK { cleanup_after_error (); _clear_error ();}
       do_something ();
          .
          .
#v-
  should be changed to:
#v+
       variable e;
       try (e)
         {
            do_something ();
              .
              .
         }
       catch RunTimeError: 
         {
            cleanup_after_error ();
         }
#v-
 And code using \ifun{_clear_error} in conjunction with
 \kw{EXECUTE_ERROR_BLOCK}:
#v+
       ERROR_BLOCK { cleanup_after_error (); _clear_error ();}
       do_something ();
          .
          .
       EXECUTE_ERROR_BLOCK;
#v-
  should be changed to:
#v+
       variable e;
       try (e)
         {
            do_something ();
              .
              .
         }
       catch RunTimeError: 
         {
            cleanup_after_error ();
         }
       finally:
         {
            cleanup_after_error ();
         }
#v-

  \tag{fread} When reading \dtype{Char_Type} and
  \dtype{UChar_Type} objects the \slang 1 version of \ifun{fread}
  returned a binary string (\dtype{BString_Type} if the number of
  characters read was greater than one, or a \exmp{U/Char_Type} if the
  number read was one.  In other words, the resulting type depended
  upon how many bytes were read with no way to predict the resulting
  type in advance. In contrast, when reading, e.g, \exmp{Int_Type}
  objects, \ifun{fread} returned an \exmp{Int_Type} when it read one
  integer, or an array of \exmp{Int_Type} if more than one was read.
  For \slang 2, the behavior of \ifun{fread} with respect to
  \dtype{UChar_Type} and \dtype{Char_Type} types was changed to
  have the same semantics as the other data types.

  The upshot is that code that used
#v+
        nread = fread (&str, Char_Type, num_wanted, fp)
#v-
  will no longer result in \exmp{str} being a \dtype{BString_Type} if
  \exmp{nread > 1}.  Instead, \exmp{str} will now become a
  \exmp{Char_Type[nread]} object.  In order to read a specified number
  of bytes from a file in the form of a string, use the
  \ifun{fread_bytes} function:
#v+
       #if (_slang_version >= 20000)
       nread = fread_bytes (&str, num_wanted, fp);
       #else
       nread = fread (&str, Char_Type, num_wanted, fp)
       #endif
#v-
  The above will work with both versions of the interpreter.

  \tag{strtrans} The \ifun{strtrans} function has been changed to
   support Unicode.  One ramification of this is that when mapping
   from one range of characters to another, the length of the ranges
   must now be equal.
   
  \tag{str_delete_chars}  This function was changed to support unicode
  character classes.  Code such as 
#v+
     y = str_delete_chars (x, "\\a");
#v-
  is now implies the deletion of all alphabetic characters from
  \exmp{x}.  Previously it meant to delete the backslashes and
  \exmp{a}s from from \exmp{x}.  Use 
#v+
     y = str_delete_chars (x, "\\\\a");
#v-
  to achieve the latter.
  
  \tag{substr, is_substr, strsub}
  These functions use character-semantics and not byte-semantics.  The
  distinction is important in UTF-8 mode.  If you use array indexing
  in conjunction with these functions, then read on.

\end{descrip}

