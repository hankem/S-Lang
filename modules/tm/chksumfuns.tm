\function{md5sum}
\synopsis{Compute an MD5 sum for a string}
\usage{String_Type md5sum (BString_Type bstr)}
\description
  The \ifun{md5sum} function computes the MD5 checksum for the
  specified binary string.  The function returns a string representing
  the hexadecimal representation of the checksum.
\seealso{md5sum_file, sha1sum}
\done

\function{md5sum_file}
\synopsis{Compute the MD5 sum for the contents of a file}
\usage{String_Type md5sum_file (String_Type|File_Type f)}
\description
  The \ifun{md5sum_file} computes the MD5 sum on the contents of a
  file.  The file may either be specified as a string giving the name
  of the file, or as an open stdio \dtype{File_Type} pointer.  The
  function returns a string representing the hexadecimal
  representation of the checksum.
\seealso{md5sum, sha1sum_file, sha1sum}
\done

\function{sha1sum}
\synopsis{Compute the SHA1 sum for a string}
\usage{String_Type sha1sum (BString_Type bstr)}
\description
  The \ifun{sha1sum} function computes the SHA1 checksum for the
  specified binary string.  The function returns a string representing
  the hexadecimal representation of the checksum.
\seealso{sha1sum_file, md5sum}
\done

\function{sha1sum_file}
\synopsis{Compute the SHA1 sum for the contents of a file}
\usage{String_Type sha1sum_file (String_Type|File_Type f)}
\description
  The \ifun{sha1sum_file} computes the SHA1 sum on the contents of a
  file.  The file may either be specified as a string giving the name
  of the file, or as an open stdio \dtype{File_Type} pointer.  The
  function returns a string representing the hexadecimal
  representation of the checksum.
\seealso{sha1sum, md5sum_file, md5sum}
\done
