_debug_info = 1; () = evalfile ("inc.sl");

testing_feature ("Binary Strings");

variable a = "\000A\000B\000C\000D";

if (typeof (a) != BString_Type) failed ("typeof");

if (bstrlen (a) != 8) failed ("bstrlen");

if ((a[[0:7:2]] != "\000\000\000\000")
    or (a[[1:7:2]] != "ABCD")) failed ("array indexing");

if (strlen (a) != 0) failed ("typecast");

a += "XYZ";

if (a[[8:]] != "XYZ") failed ("+= op");

a = "XYZ" + a;
if (a == "XYZ") failed ("== op");

if (strcmp (a, "XYZ")) failed ("failed strcmp");

loop (1000)
{
   a = "\000A\000B\000C\000D";
   a = "A\000B\000C\000";
}

print ("Ok\n");
exit (0);
