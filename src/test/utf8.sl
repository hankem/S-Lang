() = evalfile ("inc.sl");

#ifeval (0 == _slang_utf8_ok)
%#stop
#endif

testing_feature ("utf8");

static define check_sprintf (wc)
{
   variable s1 = sprintf ("%lc", wc);
   variable s2 = eval (sprintf ("\"\\x{%X}\"", wc));
   if (s1 != s2)
     failed ("check_sprintf: %lX", wc);
}

check_sprintf (0xF);
check_sprintf (0xFF);
check_sprintf (0xFFF);
check_sprintf (0xFFFF);
check_sprintf (0xFFFFF);
check_sprintf (0xFFFFFF);
check_sprintf (0xFFFFFFF);
check_sprintf (0x7FFFFFFF);

#iffalse
vmessage ("%s", "\x{F}\n");
vmessage ("%s", "\x{FF}\n");
vmessage ("%s", "\x{FFF}\n");
vmessage ("%s", "\x{FFFF}\n");
vmessage ("%s", "\x{FFFFF}\n");
vmessage ("%s", "\x{FFFFFF}\n");
vmessage ("%s", "\x{FFFFFFF}\n");
vmessage ("%s", "\x{7FFFFFFF}\n");
#endif

if (strlen (char (173)) != 1)
  failed ("strlen (char(173))");

$1 = 0;
try
{
   $1+='­';			       %  2 bytes: 0xC2 an 0xAD
   $1+='\x{AD}';
   $1+='\xAD';
   $1+='\d173';
}
catch AnyError: failed ("To parse 'x'");
if ($1 != 4*173)
  failed ("various character forms");

if ("\u{AD}" != "\xC2\xAD")
{
   failed ("\\u{AD} != \\xC2\\xAD");
}

% If \x{...} is used with 3 or more hex digits, the result is UTF-8,
% regardless of the mode.
if ("\x{0AD}" != "\xC2\xAD")
{
   failed ("\\x{0AD} != \\xC2\\xAD");
}
if ("\x{0AD}" != "\xC2\xAD")
{
   failed ("\\x{00AD} != \\xC2\\xAD");
}

if (strbytelen ("\uAB") != 2)
{
   failed ("\\uAB expected to be 2 bytes");
}

if (_slang_utf8_ok)
{
   if (strbytelen ("\x{AB}") != 2)
     failed ("\\x{AB} expected to be 2 bytes");
}
else
{
   if (strbytelen ("\x{AB}") != 1)
     failed ("\\x{AB} expected to be 1 byte");
}

% Invalid sequences
#ifeval (_slang_utf8_ok)
private define check_illegal (wch)
{
   variable ustr = char (wch);
   variable nbytes = strbytelen (ustr);
   if (nbytes != strlen (ustr))
     failed ("%d != strlen of wide char %S", nbytes, wch);

   variable ustr_up = "A" + ustr;
   variable ustr_dn = strlow (ustr_up);
   if ((ustr_up != strup (ustr_dn)) || (ustr != ustr_dn[[1:]]))
     failed ("strlow/strup on illegal seq");

   variable p = 0;
   variable ch;
   forever
     {
	(p, ch) = strskipchar (ustr, p);
	if (ch == 0)
	  {
	     if (nbytes == 0)
	       break;
	     failed ("strskipchar on illegal sequence of wch = %S", wch);
	  }
	if (nbytes == 0)
	  {
	     failed ("strskipchar-1 on illegal sequence of wch = %S", wch);
	  }
	nbytes--;
     }

   nbytes = strbytelen (ustr);
   p = nbytes;
   forever
     {
	(p, ch) = strbskipchar (ustr, p);
	if (ch == 0)
	  {
	     if ((nbytes == 0) && (p == 0))
	       break;
	     failed ("strbskipchar on illegal sequence of wch = %S", wch);
	  }
	if (nbytes == 0)
	  {
	     failed ("strbskipchar-1 on illegal sequence of wch = %S", wch);
	  }
	nbytes--;
     }
}


check_illegal (0xD800);
check_illegal (0xDFFF);
check_illegal (0xDA12);
check_illegal (0xFFFE);
check_illegal (0xFFFF);

#endif

% The escape sequence checks are for the unbraced \xhh, \d, and \ooo forms.
% They always expand to single bytes.
private define test_escaped_chars (testid, a, b)
{
   if (a != b)
     failed ("testid=%s: test_escaped_chars (\"%s\", \"%s\")", testid, a, b);
}

test_escaped_chars ("X1", "\x20A", " A");
test_escaped_chars ("X2", "A\x20", "A ");
test_escaped_chars ("X3", "A\x20B", "A B");

test_escaped_chars ("O1", "\0406", " 6");
test_escaped_chars ("O2", "6\040", "6 ");
test_escaped_chars ("O3", "6\0407", "6 7");
test_escaped_chars ("O3", "\7A", "\x07A");
test_escaped_chars ("O3", "\10A", "\x08A");

test_escaped_chars ("D1", "\d0327", " 7");
test_escaped_chars ("D2", "6\d032", "6 ");
test_escaped_chars ("D3","6\d0327", "6 7");
test_escaped_chars ("D4","6\d1A", "6\x01A");
test_escaped_chars ("D5","6\d15A", "6\x0FA");

private define test_bad_cases ()
{
   foreach ([`\x`, `\d`, `\800`,
	     `\xZ`, `\dZ`, `\d256`])
     {
	variable s = ();
	variable bad = 0;
	try
	  {
	     ()=eval(`"` + s + `"`);
	     bad = 1;
	  }
	catch AnyError;
	if (bad) failed ("Expected parsing of %S to fail.", s);
     }
}
test_bad_cases ();

print ("Ok\n");
exit (0);

