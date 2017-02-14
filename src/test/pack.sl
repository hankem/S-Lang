() = evalfile ("inc.sl");

testing_feature ("pack and unpack functions");

static variable Is_Lil_Endian = (pack ("j", 0xFF)[0] == 0xFF);

static define test_pack ()
{
   variable str;
   variable fmt, val, args;

   args = __pop_args (_NARGS - 2);
   (fmt, val) = ();

   str = pack (fmt, __push_args (args));
   if (typeof (str) != BString_Type)
     failed ("pack did not return a bstring for format = " + fmt);
   if (str != val)
     failed ("pack returned wrong result for format = "
	     + fmt + ":" + str);
}

variable X = 0x12345678L;
variable S = "\x12\x34\x56\x78";
if (Is_Lil_Endian) S = "\x78\x56\x34\x12";

test_pack (">k", "\x12\x34\x56\x78", X);
test_pack ("<k", "\x78\x56\x34\x12", X);
test_pack ("=k", S, X);

test_pack ("c", "X", 'X');
test_pack ("cc", "XY", 'X', 'Y');
test_pack ("c4", "ABCD", 'A', ['B', 'C'], 'D', 'E');
test_pack ("xx c xx c2 x >j1", "\0\0A\0\0BC\0\xD\xE", 'A', ['B', 'C'], 0x0D0E);

test_pack ("s4", "1234", "123456");
test_pack ("z4", "123\0", "123456");
test_pack ("S4", "1234", "123456");
test_pack ("s10", "1234\0\0\0\0\0\0", "1234");
test_pack ("S10", "1234      ", "1234");

private define test_pack_unpack (x, type, fmt, size)
{
   x = typecast (x, type);
   variable p = pack (fmt, x);
   variable y = unpack (fmt, p);
   ifnot (__is_same (x, y))
     {
	failed ("packunpack format=%S, input %S --> %S", fmt, x, y);
     }
   if (size == 0)
     return;

   if (sizeof_pack (fmt) != size)
     failed ("sizeof_pack: expected %S for %S, got %S",
	     size, type, sizeof_pack(fmt));

   if (size + 1 != sizeof_pack(pad_pack_format(fmt + "c")))
     failed ("Unexpected size for pad_pack_format(%S)", fmt+"c");
}

#ifexists Double_Type
test_pack_unpack (3.14, Double_Type, "d", 0);
test_pack_unpack (3.14, Float_Type, "f", 0);
test_pack_unpack (3.14, Float32_Type, "F", 4);
test_pack_unpack (3.14, Float64_Type, "D", 8);
#endif

define test_unpack1 (fmt, str, y, type)
{
   variable xx;

   variable x = typecast (y, type);

   xx = unpack (fmt, str);

   if (length (where(xx != x)))
     failed ("unpack returned wrong result for " + fmt + ":" + string (xx));
}

test_unpack1 (">j", "\xAB\xCD"B, 0xABCD, Int16_Type);
test_unpack1 (">k", "\xAB\xCD\xEF\x12"B, 0xABCDEF12L, Int32_Type);
test_unpack1 ("<j", "\xCD\xAB"B, 0xABCD, Int16_Type);
test_unpack1 ("<k", "\x12\xEF\xCD\xAB"B, 0xABCDEF12L, Int32_Type);
test_unpack1 (">J", "\xAB\xCD"B, 0xABCDU, UInt16_Type);
test_unpack1 (">K", "\xAB\xCD\xEF\x12"B, 0xABCDEF12UL, UInt32_Type);
test_unpack1 ("<J", "\xCD\xAB"B, 0xABCDU, UInt16_Type);
test_unpack1 ("<K", "\x12\xEF\xCD\xAB"B, 0xABCDEF12UL, UInt32_Type);

#ifexists Int64_Type
test_unpack1 (">Q", "\x12\x34\x56\x78\x9A\xBC\xDE\xF0"B,
	      0x123456789ABCDEF0LL, UInt64_Type);
test_unpack1 (">q", "\x12\x34\x56\x78\x9A\xBC\xDE\xF0"B,
	      0x123456789ABCDEF0ULL, Int64_Type);
#endif

define test_unpack2 (fmt, a, type)
{
   test_unpack1 (fmt, pack (fmt, a), a, type);
}

test_unpack2 ("c5", [1,2,3,4,5], Char_Type);
test_unpack2 ("C5", [1,2,3,4,5], UChar_Type);
test_unpack2 ("h5", [1,2,3,4,5], Short_Type);
test_unpack2 ("H5", [1,2,3,4,5], UShort_Type);
test_unpack2 ("i5", [1,2,3,4,5], Int_Type);
test_unpack2 ("I5", [1,2,3,4,5], UInt_Type);
test_unpack2 ("l5", [1,2,3,4,5], Long_Type);
test_unpack2 ("L5", [1,2,3,4,5], ULong_Type);
#ifexists LLong_Type
test_unpack2 ("m5", [1,2,3,4,5], ULLong_Type);
test_unpack2 ("M5", [1,2,3,4,5], ULLong_Type);
#endif
#ifexists Double_Type
test_unpack2 ("f5", [1,2,3,4,5], Float_Type);
test_unpack2 ("d5", [1,2,3,4,5], Double_Type);
#endif

test_unpack1 ("s4", "ABCDEFGHI", "ABCD", String_Type);
test_unpack1 ("S4", "ABCDEFGHI", "ABCD", String_Type);
test_unpack1 ("z4", "ABCDFGHI", "ABCD", String_Type);
test_unpack1 ("s5", "ABCD FGHI", "ABCD ", String_Type);
test_unpack1 ("S5", "ABCD FGHI", "ABCD", String_Type);
test_unpack1 ("S5", "ABCD\0FGHI", "ABCD", BString_Type);
test_unpack1 ("z5", "ABCD\0FGHI", "ABCD", BString_Type);
test_unpack1 ("s5", "ABCD\0FGHI", "ABCD\0", BString_Type);
test_unpack1 ("S5", "          ", "", String_Type);

define test_unpack3 (fmt, a, b)
{
   variable c, d;
   variable s;

   (c, d) = unpack (fmt, pack (fmt, a, b));
   if ((a != c) or (b != d))
     failed ("%s", "unpack failed for $fmt, found ($a!=$c) or ($b!=$d)"$);
}

#ifexists Double_Type
test_unpack3 ("x x h1 x x20 d x", 31h, 41.7);
test_unpack3 ("x x S20 x x20 d x", "FF", 41.7);
test_unpack3 ("x x d0d0d0d0 S20 x x20 d x", "FF", 41.7);
test_unpack3 ("x x0 S20 x x20 d x", "FF", 41.7);
test_unpack3 ("x x0 s5 x x20 d x", "FF\0\0\0", 41.7);
test_unpack3 ("x x0 z5 x x20 f x", "FF", 41.7f);
#endif

#iffalse
% The alignment is implementation-defined.  A better way of testing
% this will me needed.
private define test_pack_format (fmt, ans, n)
{
   variable n1, ans1;
   ans1 = pad_pack_format (fmt);
   if (ans != ans1)
     failed ("pad_pack_format(%s) --> %s, expected %s",
	     fmt, ans1, ans);
   n1 = sizeof_pack (ans);
   if (n != n1)
     failed ("sizeof_pack(%s) --> %S, expected %S",
	     fmt, n1, n);
}
test_pack_format ("cjDCkcqc",
		  %0123456701234567012345670123456701234567
		  %cxj-xxxxD-------cxxxk---cxxxxxxxq-------c
		  "cx1jx4DCx3kcx7qc", 41);
#endif

private define test_byteswap (c)
{
   variable a, b, type;

   foreach type ([Util_Arith_Types,
#ifexists
		  Complex_Type,
#endif
		 ])
     {
#ifexists Complex_Type
	if (type == Complex_Type)
	  c = c + PI*1j;
#endif
	a = typecast (c, type);
	b = _array_byteswap (a, 'n', 'n');
	if (type != _typeof(b))
	  failed ("_array_byteswap %S produced wrong type: %S", a, b);
	ifnot (_eqs (a, b))
	  failed ("_array_byteswap(%S,N,N) produced %S with unexpected values", a, b);

	if (Is_Lil_Endian)
	  b = _array_byteswap (a, 'n', 'l');
	else
	  b = _array_byteswap (a, 'n', 'b');
	ifnot (_eqs (a, b))
	  failed ("_array_byteswap(%S,N,native B|L) produced %S with unexpected values", a, b);

	if (Is_Lil_Endian)
	  b = _array_byteswap (a, 'l', 'n');
	else
	  b = _array_byteswap (a, 'b', 'n');
	ifnot (_eqs (a, b))
	  failed ("_array_byteswap(%S,native B|L,N) produced %S with unexpected values", a, b);

	if (Is_Lil_Endian)
	  b = _array_byteswap (a, 'l', 'b');
	else
	  b = _array_byteswap (a, 'b', 'l');

	if (length (a) && (type != Char_Type) && (type != UChar_Type))
	  {
	     if (_eqs (a, b))
	       failed ("_array_byteswap(%S,L<->B) made no difference", a);
	  }

	if (Is_Lil_Endian)
	  b = _array_byteswap (__tmp(b), 'b', 'l');
	else
	  b = _array_byteswap (__tmp(b), 'l', 'b');
	ifnot (_eqs (a, b))
	  failed ("_array_byteswap(%S,L->B->L) produced %S with unexpected values", a, b);
     }
}
test_byteswap ([1:10]);
test_byteswap ([1:-1]);		       %  empty array
test_byteswap (0xABCDh);	       %  scalar

print ("Ok\n");
exit (0);

