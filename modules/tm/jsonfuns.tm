\function{json_parse}
\synopsis{Parse JSON text into an S-Lang data structure}
\usage{json = json_parse (String_Type text)}
\description
  The \ifun{json_parse} function parses JSON data from the input string,
  and returns a corresponding S-Lang data structure. JSON values
  are represented as follows:
#v+
    JSON      S-Lang

    object    Assoc_Type
    array     List_Type
    string    String_Type or BString_Type
    number    (L)Long_Type or Double_Type
    `true'    UChar_Type ('\1')
    `false'   UChar_Type ('\0')
    `null'    Null_Type
#v-
  If the input string does not contain valid JSON data,
  a \exmp{Json_Parse_Error} is thrown.
\seealso{json_generate}
\done

\function{json_generate}
\synopsis{Generate JSON text from an S-Lang data structure}
\usage{String_Type text = json_generate (json)}
\description
  The \ifun{json_generate} function generates the JSON text
  that corresponds to the S_Lang data structure \exmp{json}.
  Valid input types -- i.e., those that generate text
  that can be parsed by \ifun{json_parse} -- are \dtype{Assoc_Type}
  (for JSON objects) and \dtype{List_Type} (for JSON arrays).

  If the order of a JSON object's key/value pairs matters,
  the \exmp{sort} qualifier can be used to order the keys:
  If given with a reference to a comparison function
#v+
  define cmp_func (key1, key2) { return key1 <=> key2; }
#v-
  the strings are sorted accordingly (see \ifun{array_sort}).
  If given with no (or another type of) value, the keys
  are ordered lexicographically. If \exmp{sort} is not given,
  the keys are unsorted as obtained by \ifun{assoc_get_keys}.

  Optional whitespace in the output text can be configured
  by the \exmp{pre_nsep}, \exmp{post_nsep}, \exmp{pre_vsep}, and \exmp{post_vsep}
  qualifiers. (Only strings built from ' ', '\\t', '\\n',
  or '\\r' are allowed. Other characters are ignored.)
  If present, all whitespace after the final "\\n"
  in \exmp{post_vsep} is considered as extra indentation,
  which accumulates for nested objects and arrays.

\qualifiers
\qualifier{sort[=&cmp_func]}{sort the keys of a JSON object}
\qualifier{pre_nsep=str}{whitespace before name separator ':'
                    in objects}{""}
\qualifier{post_nsep=str}{whitespace after name separator ':'
                     in objects}{" "}
\qualifier{pre_vsep=str}{whitespace before value separator ','
                    in objects or arrays}{""}
\qualifier{post_vsep=str}{whitespace after value separator ',',
                     after the opening, and before
                     the closing brackets in objects
                     or arrays}{"\\n  "}

\example
#v+
  % order key/value pairs in objects by integer keys:
  private define cmp_keys_by_int_value (key1, key2)
  {
    variable i1 = integer (key1),  i2 = integer (key2);
    return (i1 < i2) ? -1 : (i1 > i2);
  }
  json_generate (json; sort=&cmp_keys_by_int_value);

  % more whitespace around separators:
  json_generate (json; pre_nsep=" ", post_nsep="  ",
                       pre_vsep=" ", post_vsep="\n\t")

  % as compact as possible; no additional whitespace:
  json_generate (json; post_nsep="", post_vsep="")
#v-
\seealso{json_parse}
\done
