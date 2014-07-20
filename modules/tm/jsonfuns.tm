\function{json_decode}
\synopsis{Parse JSON text into an S-Lang data structure}
\usage{json = json_decode (String_Type text)}
\description
  The \ifun{json_decode} function parses JSON data from the input
  string, and returns a corresponding S-Lang data structure.
  JSON values are represented as follows:
#v+
    JSON   -> S-Lang

    object    Struct_Type
    array     List_Type
    string    String_Type or BString_Type
    number    (L)Long_Type or Double_Type
    `true'    UChar_Type ('\1')
    `false'   UChar_Type ('\0')
    `null'    Null_Type
#v-
  The S-Lang structure corresponding to a JSON object
  with duplicate keys has no duplicate field names,
  but the field value is given by the last JSON value.

  If the input string does not contain valid JSON data,
  or if numeric values cannot be represented within \slang,
  or if JSON objects and/or arrays are too deeply nested,
  a \exmp{Json_Parse_Error} is thrown.
\seealso{json_encode}
\done

\function{json_encode}
\synopsis{Generate JSON text from an S-Lang data structure}
\usage{String_Type text = json_encode (json)}
\description
  The \ifun{json_encode} function generates the JSON text
  that corresponds to the S_Lang data structure \exmp{json}.
  Valid input types -- i.e., those that generate text
  that can be parsed by \ifun{json_decode} -- are \dtype{Struct_Type}
  (for JSON objects) and \dtype{List_Type} or \dtype{Array_Type} (for
  JSON arrays), provided that these containers contain
  only the following types:
#v+
    S-Lang                         -> JSON

    Struct_Type                       object
    List_Type or Array_Type           array
    String_Type or BString_Type       string
    UChar_Type ('\1')                 `true'
    UChar_Type ('\0')                 `false'
    other non-complex numeric types   number
    Null_Type                         `null'
#v-
  Invalid input causes a \exmp{Json_Invalid_Json_Error}.

  Optional whitespace in the output text can be configured
  by the \exmp{pre_nsep}, \exmp{post_nsep}, \exmp{pre_vsep}, and \exmp{post_vsep}
  qualifiers. (Only strings built from ' ', '\\t', '\\n',
  or '\\r' are allowed. Other characters are ignored.)
  If present, all whitespace after the final "\\n"
  in \exmp{post_vsep} is considered as extra indentation,
  which accumulates for nested objects and arrays.

\qualifiers
\qualifier{pre_nsep=str}{whitespace before name separator ':'
                    in objects}{""}
\qualifier{post_nsep=str}{whitespace after name separator ':'
                     in objects}{""}
\qualifier{pre_vsep=str}{whitespace before value separator ','
                    in objects or arrays}{""}
\qualifier{post_vsep=str}{whitespace after value separator ',',
                     after the opening, and before
                     the closing brackets in objects
                     or arrays}{""}

\example
#v+
  % some whitespace and indentation after separators:
  json_encode (json; pre_nsep="", post_nsep=" ",
                     pre_vsep="", post_vsep="\n  ")

  % yet more whitespace around separators:
  json_encode (json; pre_nsep=" ", post_nsep="  ",
                     pre_vsep=" ", post_vsep="\n\t")
#v-
\seealso{json_decode}
\done
