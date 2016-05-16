() = evalfile ("inc.sl");

testing_feature ("regexp");

% Tests go here....

private define test_regexp (pat, str, val, ans)
{
   variable val1 = string_match (str, pat);   %  form 1
   if (val != val1)
     failed ("string_match(%S,%S) ==> %S, not %S", str, pat, val1, val);

   if (val == 0)
     return;

   variable pos, len;
   (pos, len) = string_match_nth (0);
   variable ans1 = str[[pos:pos+len-1]];
   if (ans1 != ans)
     failed ("string_match(%S,%S) ==> %S, not %S", str, pat, ans1, ans);
}

test_regexp (`.d`, "ffdoodfoo fob", 2, "fd");
test_regexp (`.*d`, "ffdoodfoo fob", 1, "ffdood");
test_regexp (`.?d`, "ffdoodfoo fob", 2, "fd");
test_regexp (`.+d`, "ffdoodfoo fob", 1, "ffdood");
test_regexp (`.\{1,3\}d`, "ffdoodfoo fob", 1, "ffd");
test_regexp (`.\{1,\}d`, "ffdoodfoo fob", 1, "ffdood");
test_regexp (`.\{4,\}d`, "ffdoodfoo fob", 1, "ffdood");
test_regexp (`.\{3,4\}d`, "ffdoodfoo fob", 2, "fdood");
test_regexp (`.\{3\}d`, "ffdoodfoo fob", 3, "dood");

test_regexp (`\c[A-Z]+`, "fooFOO4", 4, "FOO");
test_regexp (`\C[A-Z]+`, "fooFOO4", 1, "fooFOO");
test_regexp (`\<fo+`, "ffoodfoo fob", 10, "fo");
test_regexp (`\<fo+\>`, "ffoodfoo fob", 0, NULL);
test_regexp (`fo+\>`, "ffoodfoo fob", 6, "foo");
test_regexp (`fo?\>`, "ffoodfoo fob", 0, NULL);
test_regexp (`fo?.\>`, "ffoodfoo fob", 6, "foo");
test_regexp (`\<fo?.*`, "ffoodfoo fob", 1, "ffoodfoo fob");
test_regexp (`\<fo+.*`, "ffoodfoo fob", 10, "fob");
test_regexp (`fo?.`, "ffoodfoo fob", 1, "ff");

test_regexp (`o\{0,3\}d`, "ffdoodfoo fob", 3, "d");
test_regexp (`o\{,3\}d`, "ffdoodfoo fob", 3, "d");
test_regexp (`o\{1,3\}d`, "ffdoodfoo fob", 4, "ood");
test_regexp (`o\{1,\}d`, "ffdoodfoo fob", 4, "ood");
test_regexp (`o\{,\}d`, "ffdoodfoo fob", 3, "d");
test_regexp (`o\{2\}d`, "ffdoodfoo fob", 4, "ood");

test_regexp (`[k-s]\{0,3\}d`, "ffdoodfoo fob", 3, "d");
test_regexp (`[k-s]\{,3\}d`, "ffdoodfoo fob", 3, "d");
test_regexp (`[k-s]\{1,3\}d`, "ffdoodfoo fob", 4, "ood");
test_regexp (`[k-s]\{1,\}d`, "ffdoodfoo fob", 4, "ood");
test_regexp (`[k-s]\{,\}d`, "ffdoodfoo fob", 3, "d");
test_regexp (`[k-s]\{2\}d`, "ffdoodfoo fob", 4, "ood");

test_regexp (`[k-s]d`, "ffdoodfoo fob", 5, "od");
test_regexp (`[k-s]?d`, "ffdoodfoo fob", 3, "d");
test_regexp (`[k-s]*d`, "ffdoodfoo fob", 3, "d");
test_regexp (`[k-s]+d`, "ffdoodfoo fob", 4, "ood");

test_regexp (`.\{0,3\}d`, "ffdoodfoo fob", 1, "ffd");
test_regexp (`.\{,3\}d`, "ffdoodfoo fob", 1, "ffd");
test_regexp (`.\{1,3\}d`, "ffdoodfoo fob", 1, "ffd");
test_regexp (`.\{1,\}d`, "ffdoodfoo fob", 1, "ffdood");
test_regexp (`.\{4,\}d`, "ffdoodfoo fob", 1, "ffdood");
test_regexp (`.\{3,4\}d`, "ffdoodfoo fob", 2, "fdood");
test_regexp (`.\{3\}d`, "ffdoodfoo fob", 3, "dood");

test_regexp (`\d\{0,3\}d`, "ffd00df00 f0b", 3, "d");
test_regexp (`\d\{,3\}d`, "ffd00df00 f0b", 3, "d");
test_regexp (`\d\{1,3\}d`, "ffd00df00 f0b", 4, "00d");
test_regexp (`\d\{1,\}d`, "ffd00df00 f0b", 4, "00d");
test_regexp (`\d\{,\}d`, "ffd00df00 f0b", 3, "d");
test_regexp (`\d\{2\}d`, "ffd00df00 f0b", 4, "00d");

test_regexp (`\([a-z]+\)\1?`, "foodoododd", 1, "foodoododd");
test_regexp (`\([a-z]+\)\1*`, "foodoododd", 1, "foodoododd");
test_regexp (`\([a-z]+\)\1+`, "foodoododd", 2, "oodood");
test_regexp (`^\([a-z]+\)\1+`, "foodoododd", 0, NULL);
test_regexp (`\([a-z]+\)\1+$`, "foodoodood", 2, "oodoodood");
test_regexp (`\([a-z]+\).\1+`, "foodjoododd", 2, "oodjood");

test_regexp (`\([^j]+\)j\1\{2,3\}`, "foodjfoodfoodfoodfood", 1, "foodjfoodfoodfood");
test_regexp (`\([^\t]+\)\t\e\n\1\{2,3\}`, "food\t\e\nfoodfoodfoodfood", 1, "food\t\e\nfoodfoodfood");
test_regexp (`\([^j]+\)\1\{2,3\}`, "foodjfoodfoodfoodfoodxood", 6, "foodfoodfoodfood");
test_regexp (`\([^]j]+\)\1\{2,3\}`, "foodjfoodfoodfoodfoodxood", 6, "foodfoodfoodfood");
test_regexp (`\([^[j]+\)\1\{2,3\}`, "foodjfoodfoodfoodfoodxood", 6, "foodfoodfoodfood");
test_regexp (`\([^[j\n]+\)\1\{2,3\}`, "food\nfoodfoodfoodfoodxood", 6, "foodfoodfoodfood");

test_regexp (`\(\c[a-z]+\t\C[a-z]+\)`, "CATcat\tCATcat", 4, "cat\tCATcat");
test_regexp (`\<.*$`, "foo bar\nbazb\n", 9, "bazb");
test_regexp (`\<.*$`, "foo bar\nbazb\n\n", 0, NULL);
test_regexp (`\<[a-z\n]+$`, "foo bar\nbazb\n\n", 5, "bar\nbazb\n\n");
test_regexp (`\<[a-z]+\n+$`, "foo bar.bazb\n\n", 9, "bazb\n\n");

static define test_regexp_match (pat, str, val, ans)
{
   variable val1 = string_match (str, pat);   %  form 1
   if (val != val1)
     failed ("string_match(%S,%S) ==> %S, not %S", str, pat, val1, val);

   if (val == 0)
     return;

   variable ofs = 1+strbytelen (str);
   str = strcat (str, str);

   val1 = string_match (str, pat, ofs);%  form 2
   if (val1)
     val += ofs-1;

   if (val1 != val)
     failed ("string_match($str,$pat,$ofs) ==> $val1, not $val"$);

   if (ans == NULL)
     return;

   variable matches = string_matches (str, pat);
   if ((length (matches) < 2) || (ans != matches[1]))
     failed ("string_matches (%s, %s)", str, pat);
}

test_regexp_match ("B.*[1-5]", "0xAB123G", 4, NULL);
test_regexp_match ("\([1-5]+\)G\1"R, "0xAB123G12F", 0, NULL);
test_regexp_match ("\([1-5]+\)G\1"R, "0xAB123G123F", 5, "123");
test_regexp_match ("[1-5]", "0xAB123G", 5, NULL);
test_regexp_match ("\([1-5]2\)"R, "0xAB123G", 5, "12");
test_regexp_match ("G", "0xAB123G", 8, NULL);
test_regexp_match ("\(G\)"R, "0xAB123G", 8, "G");

test_regexp_match (`=\(\d\)`, "L=1X", 2, "1");
test_regexp_match (`=\(\d?\)`, "L=1X", 2, "1");
test_regexp_match (`=\(\d?\)`, "L=12X", 2, "1");
test_regexp_match (`=\(\d+\)`, "L=1X", 2, "1");
test_regexp_match (`=\(\d+\)`, "L=12X", 2, "12");
test_regexp_match (`=\(\d*\)`, "L=1X", 2, "1");
test_regexp_match (`=\(\d*\)`, "L=X", 2, "");

static define test_globbing (glob, re)
{
   variable pat = glob_to_regexp (glob);
   if (re != pat)
     failed ("glob_to_regexp (%s) produced %s, expected %s",
	     glob, pat, re);
}

#iffalse
test_globbing ("*.c", "^[^.].*\\.c$");
#else
test_globbing ("*.c", "^.*\\.c$");
#endif
test_globbing ("[*].c", "^[*]\\.c$");
test_globbing ("x+??$.$", "^x\\+..\\$\\.\\$$");
test_globbing ("x+[file$", "^x\\+\\[file\\$$");
test_globbing ("x+[^$", "^x\\+\\[^\\$$");
test_globbing ("x+[^]$", "^x\\+\\[^]\\$$");
test_globbing ("x+[^]]$", "^x\\+[^]]\\$$");
test_globbing ("[", "^\\[$");
test_globbing ("x[", "^x\\[$");
test_globbing ("x[]", "^x\\[]$");
test_globbing ("x[]]", "^x[]]$");
test_globbing ("x\\[]]", "^x\\\\[]]$");

print ("Ok\n");

exit (0);

