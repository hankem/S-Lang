() = evalfile ("inc.sl");

testing_feature ("Binary Strings");

private define test_printable_bstring ()
{
   variable db = "a\000"B, b = ""B;
   loop (20)
     b += db;

   set_printable_bstring_size (16);
   if (16 != get_printable_bstring_size ())
     failed ("get/set_printable_bstring_size");
   % for 16, we expect
   variable expect = "a\\000a\\000a...";
   if (expect != "$b"$)
     failed ("expected expected bstring representation to be: %s, got %s",
	     expect, "$b"$);

   set_printable_bstring_size (256);
   b = "abc";
   if ("abc" != "$b"$)
     failed ("representation of small binary string");
}
test_printable_bstring ();

define test ()
{
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

   a = "XYZ"B;
   if (typeof (a) != BString_Type)
     failed ("B suffix on a binary string");

   loop (10)
     {
	variable aa = a + ""B;
	variable b = __tmp(a) + "X";
	if (b != aa + "X")
	  failed ("__tmp op");
	a = __tmp(b);
     }

   a = BString_Type[10]; a[*] = "XYZ"B;

   if (bstrjoin (a) != strjoin (a))
     failed ("bstrjoin 1");
   if (bstrjoin (a, "\n") != strjoin (a,"\n"))
     failed ("bstrjoin 2");

   b = "XYZ";
   loop (10)
     {
	a += "XYZ"B;
	b += "XYZ";
	if (any (a != b))
	  failed ("Adding array of bstrings");
     }

   loop (20)
     {
	a = "\000A\000B\000C\000D";
	a = "A\000B\000C\000";
     }

   if ("XYZ\000XYZ\000XYZ\000" != bstrcat ("XY","Z\000", "XYZ\000", "XYZ", "\000"))
     failed ("bstrcat");
   if ("XYZ" == bstrcat ("XY","Z\000", "XYZ\000", "XYZ", "\000"))
     failed ("bstrcat 2");
}
test ();

define test_is_substrbytes (a, b, ans)
{
   variable x = is_substrbytes (a, b);
   if (ans != x)
     failed ("%d != (%d = is_substrbytes (%S, %S))", ans, x, a, b);
   if (ans > 1)
     {
	x = is_substrbytes (a, b, ans-1);
	if (ans != x)
	  failed ("%d != (%d = is_substrbytes (%S, %S, %S))", ans, x, a, b, ans-1);
     }
}
test_is_substrbytes ("hello", "o", 5);
test_is_substrbytes ("hello", "x", 0);
test_is_substrbytes ("hello", "h", 1);
test_is_substrbytes ("hello", "hello", 1);
test_is_substrbytes ("hello", "hellox", 0);
test_is_substrbytes ("hell\0", "\0", 5);
test_is_substrbytes ("hell\0w", "l\0w", 4);
test_is_substrbytes ("hell\0w", "", 0);
test_is_substrbytes ("", "", 0);
test_is_substrbytes ("\0hello", "h", 2);
test_is_substrbytes ("\0", "h", 0);
test_is_substrbytes ("\0", "", 0);
test_is_substrbytes ("\0", "\0", 1);
test_is_substrbytes ("\0x", "\0", 1);
test_is_substrbytes ("\0x", "\0x", 1);
test_is_substrbytes ("\0x", "\0xy", 0);
test_is_substrbytes ("", "\0xy", 0);
test_is_substrbytes ("", "\0x", 0);
test_is_substrbytes ("", "\0", 0);
test_is_substrbytes ("eefdefg", "efg", 5);

private define test_ops (a1, a2)
{
   variable b1, b2;
   b1 = typecast (a1, BString_Type);
   b2 = typecast (a2, BString_Type);

   if ((a1 == a2) != (b1 == b2))
     failed ("operator %S == %S", b1, b2);
   if ((a1 >= a2) != (b1 >= b2))
     failed ("operator %S >= %S", b1, b2);
   if ((a1 <= a2) != (b1 <= b2))
     failed ("operator %S <= %S", b1, b2);
   if ((a1 > a2) != (b1 > b2))
     failed ("operator %S > %S", b1, b2);
   if ((a1 < a2) != (b1 < b2))
     failed ("operator %S < %S", b1, b2);

   variable c1 = BString_Type[5]; c1[*] = b1;
   variable c2 = BString_Type[5]; c2[*] = b2;
   a1 = typecast (c1, String_Type);
   a2 = typecast (c2, String_Type);

   if (any ((a1 == a2) != (c1 == c2)))
     failed ("operator[] %S == %S", b1, b2);
   if (any ((a1 >= a2) != (c1 >= c2)))
     failed ("operator[] %S >= %S", b1, b2);
   if (any ((a1 <= a2) != (c1 <= c2)))
     failed ("operator[] %S <= %S", b1, b2);
   if (any ((a1 > a2) != (c1 > c2)))
     failed ("operator[] %S > %S", b1, b2);
   if (any ((a1 < a2) != (c1 < c2)))
     failed ("operator[] %S < %S", b1, b2);
}

test_ops ("hello", "world");
test_ops ("hello", "hello");
test_ops ("hell", "hello");
test_ops ("hello", "hell");
test_ops ("", "hell");
test_ops ("hell", "");
test_ops ("", "");

print ("Ok\n");
exit (0);
