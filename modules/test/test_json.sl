% -*- mode: slang; mode: fold -*-

() = evalfile ("./test.sl");
require ("json");

private variable json;

% test_decode %{{{

private define expect_json_object_with_key (key, expected_value, expected_type)
{
   expect_struct_key_value (json, key, expected_value);
   variable v = get_struct_field (json, key);
   expect_type (v, expected_type);
}

private define test_decode_empty_array () %{{{
{
   foreach json ({ "[]", "  \n\t[  \n\t \t\n ]\t\n " })
     {
	json = json_decode (json);
	expect_type (json, List_Type);
	expect_size (json, 0);
     }
}
%}}}

private define test_decode_empty_object () %{{{
{
   foreach json ({ "{}", "  \n\t{  \n\t \t\n }\t\n " })
     {
	json = json_decode (json);
	expect_type (json, Struct_Type);
	expect_size (json, 0);
     }
}
%}}}

private define test_decode_simple_array () %{{{
{
   json = json_decode ("[1, 2 ,\t\r\n 3]");
   expect_type (json, List_Type);
   expect_value (json[0], 1);
   expect_value (json[1], 2);
   expect_value (json[2], 3);
}
%}}}

private define test_decode_simple_object () %{{{
{
   json = json_decode (`
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

   expect_struct_field_names (json,
			      [
				"string",
				"long",
#ifeval is_defined("LLONG_MAX")
				"llong",
#endif
				"double",
				"true",
				"false",
				"null"
			      ]);

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

private define test_decode_heterogenous_array () %{{{
{
   json = json_decode (`
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
   expect_type (json[7], Struct_Type); %{{{
     expect_size (json[7], 7);
  %}}}
}
%}}}

private define test_decode_nested_object () %{{{
{
   json = json_decode (`
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

   expect_type (json, Struct_Type);
   expect_size (json, 4);
   expect_struct_key (json, "k1"); %{{{
     expect_type (json."k1", Struct_Type);
     expect_struct_key (json."k1", "k11"); %{{{
       expect_type (json."k1"."k11", Struct_Type);
       expect_struct_key_value (json."k1"."k11", "k111", "v111");
       expect_struct_key_value (json."k1"."k11", "k112", "v112");
    %}}}
     expect_struct_key (json."k1", "k12"); %{{{
       expect_type (json."k1"."k12", Struct_Type);
       expect_struct_key_value (json."k1"."k12", "k121", "v121");
       expect_struct_key_value (json."k1"."k12", "k122", "v122");
    %}}}
  %}}}
   expect_struct_key (json, "k2"); %{{{
     expect_type (json."k2", Struct_Type);
     expect_struct_key (json."k2", "k21"); %{{{
       expect_type (json."k2"."k21", Struct_Type);
       expect_struct_key_value (json."k2"."k21", "k211", "v211");
       expect_struct_key_value (json."k2"."k21", "k212", "v212");
    %}}}
     expect_struct_key (json."k2", "k22"); %{{{
       expect_type (json."k2"."k22", Struct_Type);
       expect_struct_key_value (json."k2"."k22", "k221", "v221");
       expect_struct_key_value (json."k2"."k22", "k222", "v222");
    %}}}
  %}}}
   expect_struct_key (json, "k3"); %{{{
     expect_type (json."k3", List_Type);
     expect_size (json."k3", 2);
       expect_value (json."k3"[0], "v31");
       expect_value (json."k3"[1], "v32");
  %}}}
   expect_struct_key (json, "k4"); %{{{
     expect_type (json."k4", List_Type);
     expect_size (json."k4", 2);
       expect_value (json."k4"[0], 41);
       expect_value (json."k4"[1], 42);
  %}}}
}
%}}}

private variable maximally_nested_array = `[
[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
"(depth = 100 below the toplevel array)"
]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]
]`;

private define test_decode_maximally_nested_array () %{{{
{
   json = json_decode (maximally_nested_array);
   loop (1+100)
     {
	expect_type (json, List_Type);
	json = json[0];
     }
   expect_type (json, String_Type);
}
%}}}

private define test_decode_object_with_duplicate_key () %{{{
{
   json = json_decode (`{"a":null, "b":"B", "a":"A"}`);
   expect_type (json, Struct_Type);
   expect_struct_field_names (json, ["a", "b"]);
   expect_json_object_with_key ("a", "A", String_Type);
   expect_json_object_with_key ("b", "B", String_Type);
}
%}}}

% test_decode_escaped_strings %{{{

% The test below puts the strings into an object:

private define expect_string (key, expected_value)
{
   expect_json_object_with_key (key, expected_value, String_Type);
}

private define expect_bstring (key, expected_value)
{
   expect_json_object_with_key (key, expected_value, BString_Type);
}

private define test_decode_escaped_strings ()
{
   json = json_decode (`
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

   expect_type (json, Struct_Type);
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

% test_decode_errors %{{{

private variable describe_char_regex = "'.' = 0x[0-9A-F][0-9A-F]";

private define expect_Json_Parse_Error_while_decoding_method (obj, json_text)
{
   expect_error (Json_Parse_Error, obj.expected_error_message, &json_decode, json_text);
   return obj;  % for method chaining
}

private define expect_Json_Parse_Error (expected_error_message)
{
   return struct {  % syntactic sugar...
      expected_error_message = expected_error_message,
      while_decoding = &expect_Json_Parse_Error_while_decoding_method
   };
}

private define test_parse_errors_due_to_structure () %{{{
{
   ()=expect_Json_Parse_Error ("empty input string")
     .while_decoding ("");

   ()=expect_Json_Parse_Error ("Unexpected character $describe_char_regex seen while parsing JSON data"$)
     .while_decoding (` "top-level string" `)
     .while_decoding (" 42 ")
     .while_decoding (" 6.022e+22 ")
     .while_decoding (" true ")
     .while_decoding (" false ")
     .while_decoding (" null ")
     .while_decoding (" ö ");

   ()=expect_Json_Parse_Error ("Unexpected character $describe_char_regex seen while parsing a JSON value"$)
     .while_decoding (` { "this is not a value" : | } `)
     .while_decoding (" [ this_is_not_a_value_either ] ");
}
%}}}

private define test_parse_errors_with_strings () %{{{
{
   ()=expect_Json_Parse_Error ("Unexpected end of input seen while parsing a JSON string")
     .while_decoding (`[ "missing quotation mark ]`);

   ()=expect_Json_Parse_Error ("Control character 0x0A in JSON string must be escaped")
     .while_decoding (`[ "literal newline \n is not allowed", "(must be \\n instead)" ]`Q);

   ()=expect_Json_Parse_Error ("Illegal escaped character 'a' = 0x61 in JSON string")
     .while_decoding (`[ "\a" ]`);

   ()=expect_Json_Parse_Error (`Illegal Unicode escape sequence in JSON string: \\u`)
     .while_decoding (`[ "\undef" ]`)
     .while_decoding (`[ "\u123`);
}
%}}}

private define test_parse_errors_with_arrays () %{{{
{
   ()=expect_Json_Parse_Error ("Expected ',' or ']' while parsing a JSON array, found $describe_char_regex"$)
     .while_decoding ("[ 1 2 ]")
     .while_decoding ("[ 1 : 2 ]");

   ()=expect_Json_Parse_Error ("Unexpected end of input seen while parsing a JSON array")
     .while_decoding ("[ 1, 2 ");

   ()=expect_Json_Parse_Error ("Expected end of input after parsing JSON array, found $describe_char_regex"$)
     .while_decoding ("[1] 2");
}
%}}}

private define test_parse_errors_with_objects () %{{{
{
   ()=expect_Json_Parse_Error ("Expected a string while parsing a JSON object, found $describe_char_regex"$)
     .while_decoding (`{ 1 }`)
     .while_decoding (`{ "one" : 1, , "two" : 2 }`);

   ()=expect_Json_Parse_Error ("Expected a ':' while parsing a JSON object, found $describe_char_regex"$)
     .while_decoding (`{ "one" = 1 }`);

   ()=expect_Json_Parse_Error ("Expected ',' or '}' while parsing a JSON object, found $describe_char_regex"$)
     .while_decoding (`{ "one" : 1 "two" : 2 }`)
     .while_decoding (`{ "one" : 1 : "two" : 2 }`);

   ()=expect_Json_Parse_Error ("Unexpected end of input seen while parsing a JSON object")
     .while_decoding (`{ "one" : 1 `);

   ()=expect_Json_Parse_Error ("Expected end of input after parsing JSON object, found $describe_char_regex"$)
     .while_decoding (`{ "one" : 1 } 2`);
}
%}}}

private define test_parse_errors_due_to_too_large_numbers () %{{{
{
   variable large_int = "18446744073709551616";  % cannot even be represented by (U)Int64_Type
   ()=expect_Json_Parse_Error ("Integer value is too large ($large_int)"$)
     .while_decoding ("[ $large_int ]"$);

   variable large_num = "2e4932";  % cannot even be represented by binary128/quadruple-precision floating-point format
   ()=expect_Json_Parse_Error ("Numeric value is too large ($large_num)"$)
     .while_decoding ("[ $large_num ]"$);
}
%}}}

private define test_parse_error_due_to_recursion_depth () %{{{
{
  ()=expect_Json_Parse_Error ("json text exceeds maximum nesting level")
    .while_decoding ("[ $maximally_nested_array ]"$);
}

private define test_decode_errors ()
{
   test_parse_errors_due_to_structure ();
   test_parse_errors_with_strings ();
   test_parse_errors_with_arrays ();
   test_parse_errors_with_objects ();
   test_parse_errors_due_to_too_large_numbers ();
   test_parse_error_due_to_recursion_depth ();
}
%}}}

private define test_decode ()
{
   test_decode_empty_array ();
   test_decode_empty_object ();
   test_decode_simple_array ();
   test_decode_simple_object ();
   test_decode_heterogenous_array ();
   test_decode_nested_object ();
   test_decode_maximally_nested_array ();
   test_decode_object_with_duplicate_key ();
   test_decode_escaped_strings ();
   test_decode_errors ();
}
%}}}

%}}}

% test_encode %{{{

% explicit whitespace-qualifiers:
variable no_whitespaces = struct { pre_nsep="", post_nsep="", pre_vsep="", post_vsep="" };
variable some_whitespaces = struct { @no_whitespaces, post_nsep=" ", post_vsep="\n  " };

private define test_encode_empty_array () %{{{
{
   expect_value (json_encode ({}), `[]`);
   expect_value (json_encode (String_Type[0]), `[]`);
   expect_value (json_encode (Integer_Type[0]), `[]`);
}
%}}}

private define test_encode_empty_object () %{{{
{
   json = @Struct_Type (String_Type[0]);
   expect_value (json_encode (json), `{}`);
}
%}}}

private define test_encode_simple_array_from_list () %{{{
{
   json = json_encode ({ 1L, 2L, 3L, "Hello", "World!" };; no_whitespaces);
   expect_value (json, `[1,2,3,"Hello","World!"]`);
}
%}}}

private define test_encode_simple_array_from_string_array () %{{{
{
   json = json_encode ([ "Hello", "World!" ];; no_whitespaces);
   expect_value (json, `["Hello","World!"]`);

   json = json_encode ([ "Hello", "World!", NULL ];; no_whitespaces);
   expect_value (json, `["Hello","World!",null]`);
}
%}}}

private define test_encode_simple_array_from_int_array () %{{{
{
   json = json_encode ([ 1, 2, 3 ];; no_whitespaces);
   expect_value (json, `[1,2,3]`);
}
%}}}

private define test_encode_simple_object () %{{{
{
   json = struct
     {
	"object" = struct { "i" = 1L, "x" = 10L },
	"array"  = [ 1, 2, 3 ],
	"string" = "stringvalue",
	"long"   = 2147483647,
#ifeval is_defined("LLONG_MAX")
	"llong"  = 9223372036854775807LL,
#endif
	"double" = 6.022e+22,
	"true"   = '\1',
	"false"  = '\0',
	"null"   = NULL,
     };

   expect_value (json_encode (json;; some_whitespaces), `{
  "object": {
    "i": 1,
    "x": 10
  },
  "array": [
    1,
    2,
    3
  ],
  "string": "stringvalue",
  "long": 2147483647,`
#ifeval is_defined("LLONG_MAX")
+`
  "llong": 9223372036854775807,`
#endif
+`
  "double": 6.022e+22,
  "true": true,
  "false": false,
  "null": null
}`);
}
%}}}

private define test_encode_escaped_strings () %{{{
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
   expect_value (json_encode (json;; some_whitespaces), `[
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

private define test_encode_optional_whitespace () %{{{
{
   json = { 1, { 2, struct { three = 3 }, 4 } };

   variable expected_json_text = `[1,[2,{"three":3},4]]`;
   expect_value (json_encode (json), expected_json_text);
   expect_value (json_encode (json;; no_whitespaces), expected_json_text);

   expected_json_text =
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
  expect_value (json_encode (json; pre_vsep="", post_vsep="\n  ", pre_nsep="", post_nsep=" "),
		expected_json_text);
  % non-whitespace is ignored:
  expect_value (json_encode (json; pre_vsep="none", post_vsep="newline\n two blanks", pre_nsep="none", post_nsep="non-whitespace ignored"),
		expected_json_text);

  expect_value (json_encode (json; pre_vsep=" ", post_vsep="\n\n    ", pre_nsep="\t", post_nsep="  "),
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

private define test_encode_errors () %{{{
{
   expect_error (Json_Invalid_Json_Error, `invalid boolean value '\\123'; only '\\000' and '\\001' are allowed`,
		 &json_encode, { '\123' });
   expect_error (Json_Invalid_Json_Error, "DataType_Type does not represent a JSON data structure",
		 &json_encode, typeof(Int_Type));
}
%}}}

private define test_encode ()
{
   test_encode_empty_array ();
   test_encode_empty_object ();
   test_encode_simple_array_from_list ();
   test_encode_simple_array_from_string_array ();
   test_encode_simple_array_from_int_array ();
   test_encode_simple_object ();
   test_encode_escaped_strings ();
   test_encode_optional_whitespace ();
   test_encode_errors ();
}
%}}}

define slsh_main ()
{
   testing_module ("json");
   test_decode ();
   test_encode ();
   end_test ();
}
