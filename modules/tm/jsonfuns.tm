\function{json_parse}
\synopsis{Parse JSON data into an S-Lang data structure}
\usage{json = json_parse (String_Type data)}
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
\done
