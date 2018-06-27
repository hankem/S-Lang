() = evalfile ("inc.sl");

variable crlf = any (array_map (Int_Type, &string_match, __argv, "_crlf.sl"));

testing_feature ("Multiline strings" + (crlf ? " with CRLF line terminators" : ""));
private define break_string (str, rep)
{
   (str, ) = strreplace (str, "\n", rep, strlen (str));
   return str;
}

define test_string (str)
{
   variable ml = break_string (str, "\\n\\\n");
   ml = eval(`"` + ml + `";`);
   if (str != ml)
     {
	failed ("%s --> %s", str, ml);
     }

   ml = break_string (str, "\n");
   ml = eval(```` + ml + ```;`);
   if (str != ml)
     {
	failed ("%s --> %s", str, ml);
     }
}

test_string ("1 This is\na multiline\nstring\n");

eval(`
define test_string2 (str, ans)
{
   if (str != ans)
     {
	failed ("str != ans, where str=%s, ans=%s", str, ans);
	return;
     }
}
`);
test_string2 (`2 This is\na multiline\nstring\n`,
	      "2 This is\\na multiline\\nstring\\n");
test_string2 (`3 This is\\\na multiline\nstring\nX`Q,
	      "3 This is\\\na multiline\nstring\nX");

eval("\
define test_string3 (str, ans)\n\
{\n\
   if (str != ans)\n\
     {\n\
	failed (\"str != ans, where str=%S, ans=%S\", str, ans);\n\
	return;\n\
     }\n\
}\n\
");
test_string3 (`2 This is\na multiline\nstring\n`,
	      "2 This is\\na multiline\\nstring\\n");
test_string3 (`3 This is\\\na multiline\nstring\nX`Q,
	      "3 This is\\\na multiline\nstring\nX");
variable FOO = "multiline";
test_string3 (`4 This is\\\na ${FOO}\nstring\nX`Q$,
	      "4 This is\\\na multiline\nstring\nX");
test_string3 (`5 This is\na ${FOO}
string\n`$,
	      crlf
	      ? "5 This is\\na multiline\r\nstring\\n"
	      : "5 This is\\na multiline\nstring\\n");

test_string3 (`6 This is
 a \0 binary
 string\0`BQ,
	      crlf
	      ? "6 This is\r\n a \0 binary\r\n string\0"
	      : "6 This is\n a \0 binary\n string\0");

print ("Ok\n");

exit (0);

