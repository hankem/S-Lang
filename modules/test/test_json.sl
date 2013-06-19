% -*- mode: slang; mode: fold -*-

() = evalfile ("./test.sl");
require ("json");

private variable json;

% test_parse %{{{

private define expect_json_object_with_key (key, expected_value, expected_type)
{
   expect_assoc_key_value (json, key, expected_value);
   expect_type (json[key], expected_type);
}

private define test_parse_empty_array () %{{{
{
   foreach json ({ "[]", "  \n\t[  \n\t \t\n ]\t\n " })
     {
	json = json_parse (json);
	expect_type (json, List_Type);
	expect_size (json, 0);
     }
}
%}}}

private define test_parse_empty_object () %{{{
{
   foreach json ({ "{}", "  \n\t{  \n\t \t\n }\t\n " })
     {
	json = json_parse (json);
	expect_type (json, Assoc_Type);
	expect_size (json, 0);
     }
}
%}}}

private define test_parse_simple_array () %{{{
{
   json = json_parse ("[1, 2 ,\t\r\n 3]");
   expect_type (json, List_Type);
   expect_value (json[0], 1);
   expect_value (json[1], 2);
   expect_value (json[2], 3);
}
%}}}

private define test_parse_simple_object () %{{{
{
   json = json_parse (`
     {
       "string" : "stringvalue",
       "long"   : 2147483647,
       "llong"  : 9223372036854775807,
       "double" : 6.022e+22,
       "true"   : true,
       "false"  : false,
       "null"   : null
     }
   `);

   expect_type (json, Assoc_Type);
   expect_size (json, 7);
   expect_json_object_with_key ("string", "stringvalue", String_Type);
   expect_json_object_with_key ("long", 2147483647, LLong_Type);
#ifeval is_defined("LLONG_MAX")
   expect_json_object_with_key ("llong", 9223372036854775807LL, LLong_Type);
#endif
   expect_json_object_with_key ("double", 6.022e+22, Double_Type);
   expect_json_object_with_key ("true", 1, UChar_Type);
   expect_json_object_with_key ("false", 0, UChar_Type);
   expect_json_object_with_key ("null", NULL, Null_Type);
}
%}}}

private define test_parse_heterogenous_array () %{{{
{
   json = json_parse (`
     [
       "stringvalue",
       42,
       6.022e+22,
       true,
       false,
       null,
       [1,2,3],
       { "i":1, "v":5, "x":10, "L":50, "C":100, "D":500, "M":1000 }
     ]
   `);

   expect_type (json, List_Type);
   expect_size (json, 8);
   expect_value (json[0], "stringvalue");
   expect_value (json[1], 42);
   expect_value (json[2], 6.022e+22);
   expect_value (json[3], 1);
   expect_value (json[4], 0);
   expect_value (json[5], NULL);
   expect_type (json[6], List_Type); %{{{
     expect_size (json[6], 3);
     expect_value (json[6][0], 1);
     expect_value (json[6][1], 2);
     expect_value (json[6][2], 3);
  %}}}
   expect_type (json[7], Assoc_Type); %{{{
     expect_size (json[7], 7);
  %}}}
}
%}}}

private define test_parse_nested_object () %{{{
{
   json = json_parse (`
     {
       "k1" : {
                "k11" : {
                          "k111" : "v111",
                          "k112" : "v112"
                        },
                "k12" : {
                          "k121" : "v121",
                          "k122" : "v122"
                        }
              },
       "k2" : {
                "k21" : {
                          "k211" : "v211",
                          "k212" : "v212"
                        },
                "k22" : {
                          "k221" : "v221",
                          "k222" : "v222"
                        }
              },
       "k3" : [ "v31", "v32" ],
       "k4" : [ 41, 42 ]
     }
   `);

   expect_type (json, Assoc_Type);
   expect_size (json, 4);
   expect_assoc_key (json, "k1"); %{{{
     expect_type (json["k1"], Assoc_Type);
     expect_assoc_key (json["k1"], "k11"); %{{{
       expect_type (json["k1"]["k11"], Assoc_Type);
       expect_assoc_key_value (json["k1"]["k11"], "k111", "v111");
       expect_assoc_key_value (json["k1"]["k11"], "k112", "v112");
    %}}}
     expect_assoc_key (json["k1"], "k12"); %{{{
       expect_type (json["k1"]["k12"], Assoc_Type);
       expect_assoc_key_value (json["k1"]["k12"], "k121", "v121");
       expect_assoc_key_value (json["k1"]["k12"], "k122", "v122");
    %}}}
  %}}}
   expect_assoc_key (json, "k2"); %{{{
     expect_type (json["k2"], Assoc_Type);
     expect_assoc_key (json["k2"], "k21"); %{{{
       expect_type (json["k2"]["k21"], Assoc_Type);
       expect_assoc_key_value (json["k2"]["k21"], "k211", "v211");
       expect_assoc_key_value (json["k2"]["k21"], "k212", "v212");
    %}}}
     expect_assoc_key (json["k2"], "k22"); %{{{
       expect_type (json["k2"]["k22"], Assoc_Type);
       expect_assoc_key_value (json["k2"]["k22"], "k221", "v221");
       expect_assoc_key_value (json["k2"]["k22"], "k222", "v222");
    %}}}
  %}}}
   expect_assoc_key (json, "k3"); %{{{
     expect_type (json["k3"], List_Type);
     expect_size (json["k3"], 2);
       expect_value (json["k3"][0], "v31");
       expect_value (json["k3"][1], "v32");
  %}}}
   expect_assoc_key (json, "k4"); %{{{
     expect_type (json["k4"], List_Type);
     expect_size (json["k4"], 2);
       expect_value (json["k4"][0], 41);
       expect_value (json["k4"][1], 42);
  %}}}
}
%}}}

% test_parse_escaped_strings %{{{

% The test below puts the strings into an object:

private define expect_string (key, expected_value)
{
   expect_json_object_with_key (key, expected_value, String_Type);
}

private define expect_bstring (key, expected_value)
{
   expect_json_object_with_key (key, expected_value, BString_Type);
}

private define test_parse_escaped_strings ()
{
   json = json_parse (`
     {
       "quotation mark"  : "\"",
       "reverse solidus" : "\\",
       "solidus"         : "\/",
       "backspace"       : "\b",
       "form feed"       : "\f",
       "line feed"       : "\n",
       "carriage return" : "\r",
       "tab"             : "\t",
       "Unicode example" : "\u0040",
       "Kaizen"          : "\u6539\u5584",
       "Schr\u00f6dinger": "\u0131\u0127 \u2202\u2044\u2202t = \u0124",
       "Unicode range"   : "\u0001 - \uFFFF = \uffff",
       "bstring with 0"  : "binary strings may even contain \u0000 characters"
     }
   `);

   expect_type (json, Assoc_Type);
   expect_string ("quotation mark"  , `"`);
   expect_string ("reverse solidus" , "\\");
   expect_string ("solidus"         , "/");
   expect_string ("backspace"       , "\b");
   expect_string ("form feed"       , "\f");
   expect_string ("line feed"       , "\n");
   expect_string ("carriage return" , "\r");
   expect_string ("tab"             , "\t");
   expect_string ("Unicode example" , "@");
   expect_string ("Kaizen"          , "改善");  % == "\u{6539}\u{5584}"
   expect_string ("Schrödinger"     , "ıħ ∂⁄∂t = Ĥ");  % == "\u{0131}\u{0127} \u{2202}\u{2044}\u{2202}t = \u{0124}"
   expect_string ("Unicode range"   , "\x01 - \u{FFFF} = \u{FFFF}");
   expect_bstring ("bstring with 0" , "binary strings may even contain \x00 characters"B);
}
%}}}

private define test_parse_too_large_numbers () %{{{
{
   json = json_parse (`[ 18446744073709551616, 1e10000 ]`);

   expect_type (json, List_Type);
   expect_size (json, 2);
   expect_value (json[0], _Inf);  % cannot be represented by LLong_Type
   expect_value (json[1], _Inf);  % cannot be represented by Double_Type
}
%}}}

% test_parse_errors %{{{

private variable describe_char_regex = "'.' = 0x[0-9A-F][0-9A-F]";

private define expect_Json_Parse_Error_while_parsing_method (obj, json_text)
{
   expect_error (Json_Parse_Error, obj.expected_error_message, &json_parse, json_text);
   return obj;  % for method chaining
}

private define expect_Json_Parse_Error (expected_error_message)
{
   return struct {  % syntactic sugar...
      expected_error_message = expected_error_message,
      while_parsing = &expect_Json_Parse_Error_while_parsing_method
   };
}

private define test_parse_errors_due_to_structure ()
{
   ()=expect_Json_Parse_Error ("empty input string")
     .while_parsing ("");

   ()=expect_Json_Parse_Error ("Unexpected character $describe_char_regex seen while parsing JSON data"$)
     .while_parsing (` "top-level string" `)
     .while_parsing (" 42 ")
     .while_parsing (" 6.022e+22 ")
     .while_parsing (" true ")
     .while_parsing (" false ")
     .while_parsing (" null ")
     .while_parsing (" ö ");

   ()=expect_Json_Parse_Error ("Unexpected character $describe_char_regex seen while parsing a JSON value"$)
     .while_parsing (` { "this is not a value" : | } `)
     .while_parsing (" [ this_is_not_a_value_either ] ");
}

private define test_parse_errors_with_strings ()
{
   ()=expect_Json_Parse_Error ("Unexpected end of input seen while parsing a JSON string")
     .while_parsing (`[ "missing quotation mark ]`);

   ()=expect_Json_Parse_Error ("Control character 0x0A in JSON string must be escaped")
     .while_parsing (`[ "literal newline \n is not allowed", "(must be \\n instead)" ]`Q);

   ()=expect_Json_Parse_Error ("Illegal escaped character 'a' = 0x61 in JSON string")
     .while_parsing (`[ "\a" ]`);

   ()=expect_Json_Parse_Error (`Illegal Unicode escape sequence in JSON string: \\u`)
     .while_parsing (`[ "\undef" ]`)
     .while_parsing (`[ "\u123`);
}

private define test_parse_errors_with_arrays ()
{
   ()=expect_Json_Parse_Error ("Expected ',' or ']' while parsing a JSON array, found $describe_char_regex"$)
     .while_parsing ("[ 1 2 ]")
     .while_parsing ("[ 1 : 2 ]");

   ()=expect_Json_Parse_Error ("Unexpected end of input seen while parsing a JSON array")
     .while_parsing ("[ 1, 2 ");

   ()=expect_Json_Parse_Error ("Expected end of input after parsing JSON array, found $describe_char_regex"$)
     .while_parsing ("[1] 2");
}

private define test_parse_errors_with_objects ()
{
   ()=expect_Json_Parse_Error ("Expected a string while parsing a JSON object, found $describe_char_regex"$)
     .while_parsing (`{ 1 }`)
     .while_parsing (`{ "one" : 1, , "two" : 2 }`);

   ()=expect_Json_Parse_Error ("Expected a ':' while parsing a JSON object, found $describe_char_regex"$)
     .while_parsing (`{ "one" = 1 }`);

   ()=expect_Json_Parse_Error ("Expected ',' or '}' while parsing a JSON object, found $describe_char_regex"$)
     .while_parsing (`{ "one" : 1 "two" : 2 }`)
     .while_parsing (`{ "one" : 1 : "two" : 2 }`);

   ()=expect_Json_Parse_Error ("Unexpected end of input seen while parsing a JSON object")
     .while_parsing (`{ "one" : 1 `);

   ()=expect_Json_Parse_Error ("Expected end of input after parsing JSON object, found $describe_char_regex"$)
     .while_parsing (`{ "one" : 1 } 2`);
}

private define test_parse_errors ()
{
   test_parse_errors_due_to_structure ();
   test_parse_errors_with_strings ();
   test_parse_errors_with_arrays ();
   test_parse_errors_with_objects ();
}
%}}}

private define test_parse ()
{
   test_parse_empty_array ();
   test_parse_empty_object ();
   test_parse_simple_array ();
   test_parse_simple_object ();
   test_parse_heterogenous_array ();
   test_parse_nested_object ();
   test_parse_escaped_strings ();
   test_parse_too_large_numbers ();
   test_parse_errors ();
}
%}}}

% test_generate %{{{

private define test_generate_empty_array () %{{{
{
   expect_value (json_generate ({}), `[]`);
}
%}}}

private define test_generate_empty_object () %{{{
{
   json = Assoc_Type[];
   expect_value (json_generate (json), `{}`);
}
%}}}

private define test_generate_simple_array () %{{{
{
   json = json_generate ({ 1L, 2L, 3L, "Hello", "World!" });
   expect_value (json, `[
  1,
  2,
  3,
  "Hello",
  "World!"
]`);
}
%}}}

private define test_generate_simple_object () %{{{
{
   variable object = Assoc_Type[];
   object["i"] = 1L;
   object["x"] = 10L;
   json = Assoc_Type[];
   json["object"] = object;
   json["array"]  = { 1, 2, 3};
   json["string"] = "stringvalue";
   json["long"]   = 2147483647;
#ifeval is_defined("LLONG_MAX")
   json["llong"]  = 9223372036854775807LL;
#endif
   json["double"] = 6.022e+22;
   json["true"]   = '\1';
   json["false"]  = '\0';
   json["null"]   = NULL;
   expect_value (json_generate (json; sort), `{
  "array": [
    1,
    2,
    3
  ],
  "double": 6.022e+22,
  "false": false,`
#ifeval is_defined("LLONG_MAX")
+`
  "llong": 9223372036854775807,`
#endif
+`
  "long": 2147483647,
  "null": null,
  "object": {
    "i": 1,
    "x": 10
  },
  "string": "stringvalue",
  "true": true
}`);
}
%}}}

private define test_generate_escaped_strings () %{{{
{
   json = {
     `" \ /`,
     "\b \f \n \r \t",
     "\u{1234}",
     "Oh, la, la\u{0300}",
     "\x00 \x01 ... \x1F \x20 \x21 ... \u{0080} \u{0081} ... \u{D7FF}"B,
     "\u{D800} ... \u{DFFF}, \u{FFFE} & \u{FFFF}",  % illegal in normal UTF-8
     "\u{D834}\u{DD1E}"  % example from ietf.org/rfc/rfc4627.txt
   };
   expect_value (json_generate (json), `[
  "\" \\ /",
  "\b \f \n \r \t",
  "\u1234",
  "Oh, la, la\u0300",
  "\u0000 \u0001 ... \u001F   ! ... \u0080 \u0081 ... \uD7FF",
  "\uD800 ... \uDFFF, \uFFFE & \uFFFF",
  "\uD834\uDD1E"
]`);
}
%}}}

private define test_generate_optional_whitespace () %{{{
{
   variable object = Assoc_Type[];
   object["three"] = 3;
   json = { 1, { 2, object, 4 } };
   variable expected_json_text =
`[
  1,
  [
    2,
    {
      "three": 3
    },
    4
  ]
]`;
  expect_value (json_generate (json),
                expected_json_text);
  expect_value (json_generate (json; pre_vsep="", post_vsep="\n  ", pre_nsep="", post_nsep=" "),
                expected_json_text);
  expect_value (json_generate (json; pre_vsep="none", post_vsep="newline\n two blanks", pre_nsep="none", post_nsep="non-whitespace ignored"),
                expected_json_text);
  expect_value (json_generate (json; pre_vsep="", post_vsep="", pre_nsep="", post_nsep=""),
                `[1,[2,{"three":3},4]]`);
  expect_value (json_generate (json; pre_vsep=" ", post_vsep="\n    ", pre_nsep="\t", post_nsep="  "),
`[
    1 ,
    [
        2 ,
        {
            "three"\t:  3
        } ,
        4
    ]
]`Q);
}
%}}}

% test_generate_object_with_sorted_keys () %{{{

private define cmp_keys_by_int_value (key1, key2)
{
   variable i1 = integer (key1),  i2 = integer (key2);
   return (i1 < i2) ? -1 : (i1 > i2);
}

private define test_generate_object_with_sorted_keys ()
{
   json = Assoc_Type[];
   json["1"]   = "I";
   json["50"]  = "L";
   json["100"] = "C";
   json["10"]  = "X";
   json["5"]   = "V";
   expect_value (json_generate (json; post_nsep="", post_vsep=" ", sort=&cmp_keys_by_int_value),
		 `{ "1":"I", "5":"V", "10":"X", "50":"L", "100":"C" }`);
}
%}}}

private define test_generate_errors () %{{{
{
   expect_error (Json_Invalid_Json_Error, `invalid boolean value '\\123'; only '\\000' and '\\001' are allowed`,
		 &json_generate, { '\123' });
   expect_error (Json_Invalid_Json_Error, "Struct_Type does not represent a JSON data structure",
		 &json_generate, struct { invalid_type });
}
%}}}

private define test_generate ()
{
   test_generate_empty_array ();
   test_generate_empty_object ();
   test_generate_simple_array ();
   test_generate_simple_object ();
   test_generate_escaped_strings ();
   test_generate_optional_whitespace ();
   test_generate_object_with_sorted_keys ();
   test_generate_errors ();
}
%}}}

define slsh_main ()
{
   testing_module ("json");
   test_parse ();
   test_generate ();
   end_test ();
}
