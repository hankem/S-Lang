\function{csv_parser_new}
\synopsis{Instantiate a parser for CSV data}
\usage{obj = cvs_parser_new (filename|File_Type|Strings[])}
\description
  This function instantiates an object that may be used to parse and
  read so-called comma-separated-value (CSV) data.  It requires a
  single argument, which may be the name of a file, an open file
  pointer, or an array of strings.
\qualifiers
\qualifier{delim}{character used for the delimiter}{','}
\qualifier{quote}{character used for the quoting fields}{'"'}
\qualifier{skiplines}{number of lines to skip before parsing}{0}
\qualifier{comment}{lines beginning with this string will be skipped}
\qualifier{blankrows}{default for how blank rows should be handled}{"skip"}
\methods
  readrow: Read and parse a row from the CSV object
  readcol: Read one or more columns from the CVS object
\example
  See the documentation for the \sfun{cvs.readcol} and
  \sfun{cvs.readrow} methods for examples.
\notes
 The current implementation assumes the CSV format specified according
 to RFC 4180.

 It is important to understand the difference between a ROW and a LINE
 in a CSV formatted file: a row may span more than one line in a file.  The
 \exmp{skiplines} qualifier specifies the number of LINES to be
 skipped, not ROWS.

 CSV files have no notion of data-types: all field values are strings.
 For this reason, the \exmp{type} qualifier introduces an extra layer
 that is not part CSV format.
\seealso{csv.readcol, csv.readrow}
\done

\function{csv.readcol}
\synopsis{Read one or more columns from a CSV file}
\usage{datastruct = csv.readcol([columns])}
\description
 This function method may be used to read one or more columns from a
 comma-separated-value file.  If passed with no arguments, all columns
 of the file will be returned.  Otherwise, only those columns
 specified by the columns argument will be returned.

 The return value is a structure with fields that correspond to the
 desired columns.  The default is for the structure to have field
 names \exmp{col1}, \exmp{col2}, etc., where the integer suffix
 specifies the column number.  The \exmp{fields} and \exmp{header}
 qualifiers may be used to specify a different set of names.
\qualifiers
  \qualifier{fields}{An array of field names to use for the returned structure}
  \qualifier{header}{Array of strings that correspond to the header row}
  \qualifier{type}{An scalar or array type-specifier, see below}
  \qualifier{typeN}{Type-specifier for column N}
  \qualifier{snan}{String value to use for an empty string element}{""}
  \qualifier{inan}{Integer value to use for an empty integer element}{0}
  \qualifier{lnan}{Long int value to use for an empty long int element}{0L}
  \qualifier{fnan}{Float value to use for an empty float element}{_NaN}
  \qualifier{dnan}{Double value to use for an empty double element}{_NaN}
  \qualifier{nanN}{Value used for an empty element in the column N}
  \qualifier{blankrows}{How a blank row should be handled}{"skip"}

  The type-specifier is used to specifiy the type of a field.  It must
  be one of the following characters:
#v+
     's' (String_Type)
     'i' (Int_Type)
     'l' (Long_Type)
     'f' (Float_Type)
     'd' (Double_Type)
#v-
  If the value of the \exmp{type} qualifier is scalar, then all
  columns will default to use the corresponding type.  If different
  types are desired, then an array of type-specifiers may be used.
  The length of the array must be the same as the number of columns to
  be returned.  The \exmp{typeN} qualifier may be used to give the
  type of column N.

  If the \exmp{columns} argument is string-valued, then the
  \exmp{header} qualifier must be supplied to provide a mapping
  from column names to column numbers.  If it is present, it will also
  be used to give normalized field names to the returned structure.
  For normalization, the column name is first lower-cased, then all
  non-alphanumeric values are converted to "_",  and excess underscore
  characters removed.

  See the documentation for the \sfun{csv.readrow} for more
  information about how blank rows should be handled.
\example
 Suppose that \file{data.csv} is a file that contains
#v+
    # The data below are from runs 6 and 7
    x,y,errx,erry,Notes - or - Comments
    10.2,0.5,,0.1,
    13.4,0.9,0.1,0.16,
    20.7,18.2,,0.3,Vacuum leak in beam line
    29.6,1.3,,0.31,
    31.2,1.2,0.11,0.33,"This data point
    taken from run 7"
#v-
 This file consists of 8 lines and forms a CSV file with 6 rows.  The
 first row consists of a single column, and the subsequent rows of
 consist of 5 columns. columns.  Note that the last row is split
 across two lines.  The row with the single column will be regarded as
 a comment in what follows.

 The first step is to instantiate a parser object using:
#v+
    csv = csv_parser_new ("data.csv" ;comment="#");
#v-
 The use of the \exmp{comment} qualifier will cause all lines
 beginning with \exmp{"#"} to be skipped.  Alternatively, the first
 line could have been skipped using
#v+
    csv = csv_parser_new ("data.csv" ;skiplines=1);
#v-
 The second row (also second line) in the file is the header line: it
 gives the names of the columns.  It may be read using
#v+
    header = csv.readrow ();
#v-
 The rest of the file consists of the data values.  We want to read
 the first 4 columns as single precision (\dtype{Float_Type}) values,
 and the 5th as a string.  One way to do this is
#v+
    table = csv.readcol (;type=['f','f','f','f','s']);
#v-
 This will result in \exmp{table} set to a structure of the form
#v+
   struct { col1 = Float_Type[5],
            col2 = Float_Type[5],
            col3 = Float_Type[5],
            col4 = Float_Type[5],
            col5 = String_Type[5]
          }
#v-
 The same result could also have been achieved using
#v+
    table = csv.readcol (;type='f', type5='s');
#v-
 If the \exmp{header} qualifier is used, then
#v+
    table = csv.readcol (;type='f', type5='s', header=header);
#v-
 would produce the structure
#v+
   struct {x=Float_Type[5],
           y=Float_Type[5],
           errx=Float_Type[5],
           erry=Float_Type[5],
           notes_or_comments=String_Type[5]
          }
#v-
 Note how the "Notes -or- Comments" value was normalized.

 To read just the \exmp{x} and \exmp{y} columns, either of the
 following may be used:
#v+
    table = csv.readcol ([1,2] ;type='f');
    table = csv.readcol (["x","y"] ;type='f', header=header);
#v-
 The \exmp{header} qualifier was required in the last form to map the
 column names to numbers.
\seealso{cvs_parser_new, csv_readcol, readascii}
\done


\function{csv.readrow}
\synopsis{Read a row from a CSV file}
\usage{row = csv.readrow ()}
\description
  The \exmp{csv.readrow} function method may be used to read the next
  row from the underlying CSV (comma-separated-value) parser object.  The
  object must have already been instantiated using the
  \sfun{cvs_parser_new} function.  It returns the row data in the form
  of an array of strings.  If the end of input it reached, \NULL will
  be returned.
\qualifiers
\qualifier{blankrows}{How a blank row should be handled}{"skip"}

  The \exmp{blankrows} qualifier is used to specify how a blank row
  should be handled.  A blankrow is defined as a row made up of no
  characters except for the newline or carriage-return sequance.  For
  example, the following 9 lines has one blank row that occurs on
  line 8:
#v+
     "12.3"
     "4

     5"
     "5.1"
     ""
     "7.2"
     
     "6.2"
#v-
  If the value of \exmp{"blankrow"} is \exmp{"skip"}, then blank rows
  will be ignored by the parser.  If the value is \exmp{"stop"}, then the row
  will be returned as an empty array of strings (length equal to 0).
  Otherwise the row will be treated as if it contained the empty
  string and returned as an array of length 1 with a value of "".  The
  default behavior is to skip such rows.
\seealso{csv_parser_new, csv.readcol, csv_readcol}
\done

\function{csv_readcol}
\synopsis{Read one or more columns from a CSV file}
\usage{Struct_Type csv_readcol (file|fp [,columns] ;qualifiers)}
\description
 This function may be used to read one or more of the columns in the specified
 CSV file.  If the \exmp{columns} argument is present, then only those
 columns will be read; otherwise all columns in the file will be read.
 The columns will be returned in the form of a structure.
\qualifiers
 This function supports all of the qualifiers supported by the
 \sfun{csv_decoder_new} function and the \sfun{csv.readcol} method.  In
 addition, if the \exmp{has_header} qualifier is present, the first
 line processed (after skipping any lines implied by the
 \exmp{skiplines} and \exmp{comment} qualifiers) will be regarded as
 the header.
\example
#v+
   data = csv_readcol ("mirror.csv" ;comment="#", has_header, delim='|');
#v-
\seealso{csv_decoder_new, csv.readcol, csv.readrow, csv.writecol, csv_encoder_new}
\done

\function{csv_encoder_new}
\synopsis{Create an object for writing CSV files}
\usage{csv = csv_encoder_new ()}
\description
  The \sfun{csv_encoder_new} function returns an object that may
  be used for creating a CSV file.
\qualifiers
\qualifier{delim}{Character used for the field delimiter}{','}
\qualifier{quote}{Character used for quoting fields}{'"'}
\qualifier{quoteall}{Quote all field values}
\qualifier{quotesome}{Quote only those fields where quoting is necessary}
\methods
  writecol: write one or more colums to a file.  For more information
  about this method, see the documentation for \sfun{csv.writecol}.
\example
    x = [0:2*PI:#100];
    csv = csv_encoder_new (;delim='|');
    csv.writecol ("sinx.csv", x, sin(x) ; names=["x", "sin of x"]);
\notes
  The \ifun{set_float_format} function may be used to specify the
  format used where writing floating point numbers to the CSV file.
\seealso{csv_writecol, csv_encoder_new, csv_readcol}
\done
