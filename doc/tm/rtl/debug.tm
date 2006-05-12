\variable{_boseos_info}
\synopsis{Control the generation of BOS/EOS callback code}
\usage{Int_Type _boseos_info}
\description
 This value of this variable dictates whether or not the \slang
 interpeter will generate code to call the beginning and end of
 statement callback handlers.  The value of this variable is local to
 the compilation unit, but is inherited by other units loaded by the
 current unit.

 The value of \ivar{_boseos_info} controls the generation of code for
 callbacks as follows:
#v+
   Value      Description
   -----------------------------------------------------------------
     0        No code for making callbacks will be produced.
     1        Callback generation will take place for all non-branching
              statements.
     2        Same as for 1 with the addition that code will also be
              generated for branching statements.
#v-
 A non-branching statement is one that does not effect chain of
 execution.  Branching statements include all looping statements,
 conditional statement, \exmp{break}, \exmp{continue}, and \exmp{return}.
\example
 Consider the following:
#v+
   _boseos_info = 1;
   define foo ()
   {
      if (some_expression)
        some_statement;
   }
   _boseos_info = 2;
   define bar ()
   {
      if (some_expression)
        some_statement;
   }
#v-
 The function \exmp{foo} will be compiled with code generated to call the
 BOS and EOS handlers when \exmp{some_statement} is executed.  The
 function \exmp{bar} will be compiled with code to call the handlers
 for both \exmp{some_expression} and \exmp{some_statement}.
\notes
 The \sldb debugger and \slsh's \exmp{stkcheck.sl} make use of this
 facility.
\seealso{_set_bos_handler, _set_eos_handler, _debug_info}
\done

\function{_clear_error}
\synopsis{Clear an error condition (deprecated)}
\usage{_clear_error ()}
\description
  This function has been deprecated.  New code should make use of
  try-catch exception handling.

  This function may be used in error-blocks to clear the error that
  triggered execution of the error block.  Execution resumes following
  the statement, in the scope of the error-block, that triggered the
  error.
\example
  Consider the following wrapper around the \ifun{putenv} function:
#v+
    define try_putenv (name, value)
    {
       variable status;
       ERROR_BLOCK
        {
          _clear_error ();
          status = -1;
        }
       status = 0;
       putenv (sprintf ("%s=%s", name, value);
       return status;
    }
#v-
  If \ifun{putenv} fails, it generates an error condition, which the
  \exmp{try_putenv} function catches and clears.  Thus \exmp{try_putenv}
  is a function that returns -1 upon failure and 0 upon
  success.
\seealso{_trace_function, _slangtrace, _traceback}
\done

\variable{_debug_info}
\synopsis{Configure debugging information}
\usage{Integer_Type _debug_info}
\description
  The \ivar{_debug_info} variable controls whether or not extra code
  should be generated for additional debugging and traceback
  information.  Currently, if \ivar{_debug_info} is zero, no extra code
  will be generated; otherwise extra code will be inserted into the
  compiled bytecode for additional debugging data.

  The value of this variable is local to each compilation unit and
  setting its value in one unit has no effect upon its value in other
  units.
\example
#v+
    _debug_info = 1;   % Enable debugging information
#v-
\notes
  Setting this variable to a non-zero value may slow down the
  interpreter somewhat.
  
  The value of this variable is not currently used.
\seealso{_traceback, _slangtrace}
\done

\function{_set_bos_handler}
\synopsis{Set the beginning of statement callback handler}
\usage{_set_bos_handler (Ref_Type func)}
\description
 This function is used to set the function to be called prior to the
 beginning of a statement.  The function will be passed two
 parameters: the name of the file and the line number of the statement
 to be executed.  It should return nothing.
\example
#v+
    static define bos_handler (file, line)
    {
      () = fputs ("About to execute $file:$line\n"$, stdout);
    }
    _set_bos_handler (&bos_handler);
#v-
\notes
 The beginning and end of statement handlers will be called for
 statements in a file only if that file was compiled with the variable
 \ivar{_boseos_info} set to a non-zero value.
\seealso{_set_eos_handler, _boseos_info}
\done

\function{_set_eos_handler}
\synopsis{Set the beginning of statement callback handler}
\usage{_set_eos_handler (Ref_Type func)}
\description
 This function is used to set the function to be called at the end of
 a statement.  The function will be passed no parameters and it should
 return nothing.
\example
#v+
   static define eos_handler ()
   {
     () = fputs ("Done executing the statement\n", stdout);
   }
   _set_eos_handler (&bos_handler);
#v-
\notes
 The beginning and end of statement handlers will be called for
 statements in a file only if that file was compiled with the variable
 \ivar{_boseos_info} set to a non-zero value.
\seealso{_set_eos_handler, _boseos_info}
\done

\variable{_slangtrace}
\synopsis{Turn function tracing on or off}
\usage{Integer_Type _slangtrace}
\description
  The \ivar{_slangtrace} variable is a debugging aid that when set to a
  non-zero value enables tracing when function declared by
  \ifun{_trace_function} is entered.  If the value is greater than
  zero, both intrinsic and user defined functions will get traced.
  However, if set to a value less than zero, intrinsic functions will
  not get traced.
\seealso{_trace_function, _traceback, _print_stack}
\done

\variable{_traceback}
\synopsis{Generate a traceback upon error}
\usage{Integer_Type _traceback}
\description
  \ivar{_traceback} is an intrinsic integer variable whose value
  controls whether or not a traceback of the call stack is to be
  generated upon error.  If \ivar{_traceback} is greater than zero, a
  full traceback will be generated, which includes the values of local
  variables.  If the value is less than zero, a traceback will be
  generated without local variable information, and if
  \ivar{_traceback} is zero the traceback will not be generated.
  
  Running \slsh with the \exmp{-g} option causes this variable to be
  set to 1.
\seealso{_boseos_info}
\done

\function{_trace_function}
\synopsis{Set the function to trace}
\usage{_trace_function (String_Type f)}
\description
  \ifun{_trace_function} declares that the \slang function with name
  \exmp{f} is to be traced when it is called.  Calling
  \ifun{_trace_function} does not in itself turn tracing on.  Tracing
  is turned on only when the variable \ivar{_slangtrace} is non-zero.
\seealso{_slangtrace, _traceback}
\done

