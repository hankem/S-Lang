() = evalfile ("inc.sl");

testing_feature ("Multiline strings");
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
	failed ("\n1: %s --> %s", str, ml);
     }

   ml = break_string (str, "\n");
   ml = eval(```` + ml + ```;`);
   if (str != ml)
     {
	failed ("\n2: %s --> %s", str, ml);
     }

   ml = break_string (str, "\\n\\\r\n");
   ml = eval ("\"" + ml + "\"");
   if (str != ml)
     failed ("\n3: %s --> %s", str, ml);
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

private variable Test_String_Body = "\n\
{\n\
   if (str != ans)\n\
     {\n\
	failed (\"str != ans, where\\nstr=%S,\\nans=%S\\n\", str, ans);\n\
	return;\n\
     }\n\
}\n\
";

eval ("define test_string3a (str, ans)" + Test_String_Body);
eval ("define test_string3b (str, ans)" + strreplace(Test_String_Body, "\n", "\r\n"));

private define test_string3 (a, b)
{
   test_string3a (a, b);
   test_string3b (a, b);
}

test_string3 (`2 This is\na multiline\nstring\n`,
	      "2 This is\\na multiline\\nstring\\n");
test_string3 (`3 This is\\\na multiline\nstring\nX`Q,
	      "3 This is\\\na multiline\nstring\nX");
variable FOO = "multiline";
test_string3 (`4 This is\\\na ${FOO}\nstring\nX`Q$,
	      "4 This is\\\na multiline\nstring\nX");
test_string3 (`5 This is\na ${FOO}
string\n`$,
	      "5 This is\\na multiline\nstring\\n");

test_string3 (`6 This is
 a \0 binary
 string\0`BQ,
	      "6 This is\n a \0 binary\n string\0");

test_string3 (eval("`7 This is\r\n a \\0 binary\r\n string\\0`BQ"),
	      "7 This is\r\n a \0 binary\r\n string\0");

print ("Ok\n");

exit (0);

