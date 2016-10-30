\function{getegid}
\synopsis{Get the effective group id of the current process}
\usage{Int_Type getegid ()}
\description
  The \ifun{getegid} function returns the effective group ID of the
  current process.
\notes
  This function is not supported by all systems.
\seealso{getgid, geteuid, setgid}
\done

\function{geteuid}
\synopsis{Get the effective user-id of the current process}
\usage{Int_Type geteuid ()}
\description
  The \ifun{geteuid} function returns the effective user-id of the
  current process.
\notes
  This function is not supported by all systems.
\seealso{getuid, setuid, setgid}
\done

\function{getgid}
\synopsis{Get the group id of the current process}
\usage{Integer_Type getgid ()}
\description
  The \ifun{getgid} function returns the real group id of the current
  process.
\notes
  This function is not supported by all systems.
\seealso{getpid, getppid}
\done

\function{getpgid}
\synopsis{Get the process group id}
\usage{Int_Type getpgid (Int_Type pid)}
\description
  The \ifun{getpgid} function returns the process group id of the
  process whose process is \exmp{pid}.  If \exmp{pid} is 0, then the
  current process will be used.
\notes
  This function is not supported by all systems.
\seealso{getpgrp, getpid, getppid}
\done

\function{getpgrp}
\synopsis{Get the process group id of the calling process}
\usage{Int_Type getpgrp ()}
\description
  The \ifun{getpgrp} function returns the process group id of the
  current process.
\notes
  This function is not supported by all systems.
\seealso{getpgid, getpid, getppid}
\done

\function{getpid}
\synopsis{Get the current process id}
\usage{Integer_Type getpid ()}
\description
  The \ifun{getpid} function returns the current process identification
  number.
\seealso{getppid, getgid}
\done

\function{getppid}
\synopsis{Get the parent process id}
\usage{Integer_Type getppid ()}
\description
  The \ifun{getpid} function returns the process identification
  number of the parent process.
\notes
  This function is not supported by all systems.
\seealso{getpid, getgid}
\done

\function{getpriority}
\synopsis{Get a process's scheduling priority}
\usage{result = getpriority (which, who)}
\description
 The \ifun{setpriority} function may be used to obtain the kernel's
 scheduling priority for a process, process group, or a user depending
 upon the values of the \exmp{which} and \exmp{who} parameters.
 Specifically, if the value of \exmp{which} is \exmp{PRIO_PROCESS},
 then the value of \exmp{who} specifies the process id of the affected
 process. If \exmp{which} is \exmp{PRIO_PGRP}, then \exmp{who}
 specifies a process group id.  If \exmp{which} is \exmp{PRIO_USER},
 then the value of \exmp{who} is interpreted as a user id.  For the
 latter two cases, where \exmp{which} refers to a set of processes,
 the value returned corresponds to the highest priority of a process
 in the set.  A value of 0 may be used for who to denote the process
 id, process group id, or real user ID of the current process.

 Upon success, the function returns the specified priority value.  If
 an error occurs, the function will return \NULL with \ivar{errno} set
 accordingly.
\seealso{setpriority, getpid, getppid}
\done

\function{getrusage}
\synopsis{Get process resource usage}
\usage{Struct_Type getrusage ([Int_Type who])}
\description
  This function returns a structure whose fields contain information
  about the resource usage of calling process, summed over all threads
  of the process.  The optional integer argument \exmp{who} may be
  used to obtain resource usage of child processes, or of the calling
  thread itself. Specifically, the optional integer argument
  \exmp{who} may take on one of the following values:
#v+
    RUSAGE_SELF (default)
    RUSAGE_CHILDREN
#v-
  If \ivar{RUSAGE_CHILDREN} is specified, then the process information
  will be the sum of all descendents of the calling process that have
  terminated and have been waited for (via, e.g., \ifun{waitpid}).  It
  will not contain any information about child processes that have not
  terminated.

  The structure that is returned will contain the following fields:
#v+
   ru_utimesecs       user CPU time used (Double_Type secs)
   ru_stimesecs       system CPU time used (Double_Type secs)
   ru_maxrss          maximum resident_set_size
   ru_minflt          page reclaims (soft page faults)
   ru_majflt          page faults (hard page faults)
   ru_inblock         block input operations
   ru_oublock         block output operations
   ru_nvcsw           voluntary context switches
   ru_nivcsw          involuntary context switches
   ru_ixrss           integral shared memory size
   ru_idrss           integral unshared data size
   ru_isrss           integral unshared stack size
   ru_nswap           swaps
   ru_msgsnd          IPC messages sent
   ru_msgrcv          IPC messages received
   ru_nsignals        signals received
#v-
  Some of the fields may not be supported for a particular OS or
  kernel version.  For example, on Linux the 2.6.32 kernel supports
  only the following fields:
#v+
    ru_utimesecs
    ru_stimesecs
    ru_maxrss (since Linux 2.6.32)
    ru_minflt
    ru_majflt
    ru_inblock (since Linux 2.6.22)
    ru_oublock (since Linux 2.6.22)
    ru_nvcsw (since Linux 2.6)
    ru_nivcsw (since Linux 2.6)
#v-
\notes
  The underlying system call returns the CPU user and system times
  as C \exmp{struct timeval} objects.  For convenience, the interpreter
  interface represents these objects as double precision floating point
  values.
\seealso{times}
\done

\function{getsid}
\synopsis{get the session id of a process}
\usage{Int_Type getsid ([Int_Type pid])}
\description
  The \ifun{getsid} function returns the session id of the current
  process.  If the optional integer \exmp{pid} argument is given, then
  the function returns the session id of the specified process id.
\seealso{setsid, getpid, getpid}
\done

\function{getuid}
\synopsis{Get the user-id of the current process}
\usage{Int_Type getuid ()}
\description
  The \ifun{getuid} function returns the user-id of the current
  process.
\notes
  This function is not supported by all systems.
\seealso{getuid, getegid}
\done

\function{kill}
\synopsis{Send a signal to a process}
\usage{Integer_Type kill (Integer_Type pid, Integer_Type sig)}
\description
  This function may be used to send a signal given by the integer \exmp{sig}
  to the process specified by \exmp{pid}.  The function returns zero upon
  success or \exmp{-1} upon failure setting \ivar{errno} accordingly.
\example
  The \ifun{kill} function may be used to determine whether or not
  a specific process exists:
#v+
    define process_exists (pid)
    {
       if (-1 == kill (pid, 0))
         return 0;     % Process does not exist
       return 1;
    }
#v-
\notes
  This function is not supported by all systems.
\seealso{killpg, getpid}
\done

\function{killpg}
\synopsis{Send a signal to a process group}
\usage{Integer_Type killpg (Integer_Type pgrppid, Integer_Type sig)}
\description
  This function may be used to send a signal given by the integer \exmp{sig}
  to the process group specified by \exmp{pgrppid}.  The function returns zero upon
  success or \exmp{-1} upon failure setting \ivar{errno} accordingly.
\notes
  This function is not supported by all systems.
\seealso{kill, getpid}
\done

\function{mkfifo}
\synopsis{Create a named pipe}
\usage{Int_Type mkfifo (String_Type name, Int_Type mode)}
\description
  The \ifun{mkfifo} attempts to create a named pipe with the specified
  name and mode (modified by the process's umask).  The function
  returns 0 upon success, or -1 and sets \ivar{errno} upon failure.
\notes
  Not all systems support the \ifun{mkfifo} function and even on
  systems that do implement the \ifun{mkfifo} system call, the
  underlying file system may not support the concept of a named pipe,
  e.g, an NFS filesystem.
\seealso{stat_file}
\done

\function{setgid}
\synopsis{Set the group-id of the current process}
\usage{Int_Type setgid (Int_Type gid)}
\description
  The \ifun{setgid} function sets the effective group-id of the current
  process.  It returns zero upon success, or -1 upon error and sets
  \ivar{errno} appropriately.
\notes
  This function is not supported by all systems.
\seealso{getgid, setuid}
\done

\function{setpgid}
\synopsis{Set the process group-id}
\usage{Int_Type setpgid (Int_Type pid, Int_Type gid)}
\description
  The \ifun{setpgid} function sets the group-id \exmp{gid} of the
  process whose process-id is \exmp{pid}.  If \exmp{pid} is \0, then the
  current process-id will be used.  If \exmp{pgid} is \0, then the pid
  of the affected process will be used.

  If successful 0 will be returned, otherwise the function will
  return \-1 and set \ivar{errno} accordingly.
\notes
  This function is not supported by all systems.
\seealso{setgid, setuid}
\done

\function{setpriority}
\synopsis{Set the scheduling priority for a process}
\usage{Int_Type setpriority (which, who, prio)}
\description
 The \ifun{setpriority} function may be used to set the kernel's
 scheduling priority for a process, process group, or a user depending
 upon the values of the \exmp{which} and \exmp{who} parameters.
 Specifically, if the value of \exmp{which} is \exmp{PRIO_PROCESS}, then the
 value of \exmp{who} specifies the process id of the affected process.
 If \exmp{which} is \exmp{PRIO_PGRP}, then \exmp{who} specifies a process
 group id.  If \exmp{which} is \exmp{PRIO_USER},  then the value of
 \exmp{who} is interpreted as a user id.  A value of 0 may be used for
 who to denote the process id, process group id, or real user ID of
 the current process.

 Upon sucess, the \ifun{setpriority} function returns 0.  If an error occurs,
 -1 is returned and errno will be set accordingly.
\example
  The \ifun{getpriority} and \ifun{setpriority} functions may be used
  to implement a \exmp{nice} function for incrementing the priority of
  the current process as follows:
#v+
   define nice (dp)
   {
      variable p = getpriority (PRIO_PROCESS, 0);
      if (p == NULL)
        return -1;
      variable s = setpriority (PRIO_PROCESS, 0, p + dp);
      if (s == -1)
        return -1;
      return getpriority (PRIO_PROCESS, 0);
   }
#v-
\notes
 Priority values are sometimes called "nice" values.  The actual
 range of priority values is system dependent but commonly range from
 -20 to 20, with -20 being the highest scheduling priority, and +20
 the lowest.
\seealso{getpriority, getpid}
\done


\function{setsid}
\synopsis{Create a new session for the current process}
\usage{Int_Type setsid ()}
\description
  If the current process is not a session leader, the \ifun{setsid}
  function will create a new session and make the process the session
  leader for the new session.  It returns the the process group id of
  the new session.

  Upon failure, -1 will be returned and \ivar{errno} set accordingly.
\seealso{getsid, setpgid}
\done

\function{setuid}
\synopsis{Set the user-id of the current process}
\usage{Int_Type setuid (Int_Type id)}
\description
  The \ifun{setuid} function sets the effective user-id of the current
  process.  It returns zero upon success, or \-1 upon error and sets
  \ivar{errno} appropriately.
\notes
  This function is not supported by all systems.
\seealso{setgid, setpgid, getuid, geteuid}
\done

\function{sleep}
\synopsis{Pause for a specified number of seconds}
\usage{sleep (Double_Type n)}
\description
  The \ifun{sleep} function delays the current process for the
  specified number of seconds.  If it is interrupted by a signal, it
  will return prematurely.
\notes
  Not all system support sleeping for a fractional part of a second.
\done

\function{statvfs}
\synopsis{Get file system statistics}
\usage{Struct_Type statvfs (fsobj)}
\description
  This function is a wrapper around the corresponding POSIX function.
  It returns a structure whose fields provide information about the
  filesystem object \exmp{fsobj}.  This object can be either a path
  name within the file system, or an open file descriptor represented
  by an integer, \dtype{File_Type}, or \dtype{FD_Type} object.

  The fields of the structure are defined as follows:
#v+
    f_bsize  :  file system block size
    f_frsize :  fragment size
    f_blocks :  size of fs in f_frsize units
    f_bfree  :  number of free blocks
    f_bavail :  number of free blocks for unprivileged users
    f_files  :  number of inodes
    f_ffree  :  number of free inodes
    f_favail :  number of free inodes for unprivileged users
    f_fsid   :  file system ID
    f_flag   :  mount flags
    f_namemax:  maximum filename length
#v-
  The value of the \exmp{f_flag} field is a bitmapped integer composed
  of the following bits:
#v+
    ST_RDONLY : Read-only file system.
    ST_NOSUID : Set-user-ID/set-group-ID bits are ignored by the exec
                functions.
#v-

  Upon error, the function returns \NULL and sets \ivar{errno}
  accordingly.
\notes
  This function is not supported by all systems.
\seealso{stat_file}
\done

\function{system}
\synopsis{Execute a shell command}
\usage{Integer_Type system (String_Type cmd)}
\description
  The \ifun{system} function may be used to execute the string
  expression \exmp{cmd} in an inferior shell.  This function is an
  interface to the C \ifun{system} function which returns an
  implementation-defined result.   On Linux, it returns 127 if the
  inferior shell could not be invoked, -1 if there was some other
  error, otherwise it returns the return code for \exmp{cmd}.
\example
#v+
    define dir ()
    {
       () = system ("DIR");
    }
#v-
  displays a directory listing of the current directory under MSDOS or
  VMS.
\seealso{system_intr, new_process, popen}
\done

\function{system_intr}
\synopsis{Execute a shell command}
\usage{Integer_Type system_intr (String_Type cmd)}
\description
 The \ifun{system_intr} function performs the same task as the
 \ifun{system} function, except that the \var{SIGINT} signal will not
 be ignored by the calling process.  This means that if a \slang script
 calls \ifun{system_intr} function, and Ctrl-C is pressed, both the
 command invoked by the \ifun{system_intr} function and the script
 will be interrupted.  In contrast, if the command were invoked using
 the \ifun{system} function, only the command called by it would be
 interrupted, but the script would continue executing.
\seealso{system, new_process, popen}
\done

\function{umask}
\synopsis{Set the file creation mask}
\usage{Int_Type umask (Int_Type m)}
\description
  The \ifun{umask} function sets the file creation mask to the value of
  \exmp{m} and returns the previous mask.
\seealso{stat_file}
\done

\function{uname}
\synopsis{Get the system name}
\usage{Struct_Type uname ()}
\description
  The \ifun{uname} function returns a structure containing information
  about the operating system.  The structure contains the following
  fields:
#v+
       sysname  (Name of the operating system)
       nodename (Name of the node within the network)
       release  (Release level of the OS)
       version  (Current version of the release)
       machine  (Name of the hardware)
#v-
\notes
  Not all systems support this function.
\seealso{getenv}
\done

