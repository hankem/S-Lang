_debug_info = 1; () = evalfile ("inc.sl");

testing_feature ("lists");

static variable L = list_new ();
list_insert (L, "f0");
if ("f0" != L[0])
  failed ("L[0]");
list_append (L, "f1");
if ("f1" != L[1])
  failed ("L[1]");
list_append (L, "f2", 1);
if ("f2" != L[2])
  failed ("L[2]");
if (length (L) != 3)
  failed ("list length");
list_delete (L, 0);
if (L[0] != "f1")
  failed ("list_delete (L,0)");
list_delete (L, -1);
if (L[0] != "f1")
  failed ("list_delete (L,-1)");
list_delete (L, 0);
if (length (L))
  failed ("list_delete to empty list");

L = 0;

L = {};
L = {L, "100", [1:10]};
if (length (L) != 3)
  failed ("list with an empty list");

if (0 == _eqs(L[0], {})) failed ("list {}");

L = {"200", L, 3.14};
if ((L[0] != "200") 
    or (L[2] != 3.14)
    or (L[-1] != 3.14))
  failed ("list {with list elements}");

L = {20, 30, {40, {}, 50}};
if ((L[0] != 20) or (L[1] != 30) or (L[2][0] != 40) or (L[2][2] != 50))
  failed ("list { {} }");

static variable L1 = @L;
if (__is_same (L1, L))
  failed ("@L");
if (0 == _eqs (L1, L))
  failed ("_eqs(@L,L)");

_for (1, 10000, 1)
{
   $1 = ();
   list_append(L, $1);
}

L = {};
_for (1, 100, 1)
{
   $1 = ();
   list_append (L, {$1, "$1"$});
}
$1 = 0;
foreach $2 (L)
{
   $1++;
   if (($2[0] != $1) or ($2[1] != "$1"$))
     failed ("foreach list");
}
if (($1 != length (L)) or ($1 != 100))
  failed ("foreach length");

L = {};
_for $1 (0, 10, 1)
  L = {L,$1};

if (L[1] != 10)
  failed ("L[1]");

private define test_push_pop_list ()
{
   variable list = __pop_list (_NARGS);
   
   variable d0 = _stkdepth ();
   __push_list (list);
   variable d1 = _stkdepth ();
   if (d1 - d0 != _NARGS)
     failed ("push/pop_list");
   
   loop (_NARGS)
     {
	variable a = list_pop (list, -1);
	variable b = ();
	if (not __is_same (a, b))
	  failed ("push/pop_list failed sameness test");
     }
}

test_push_pop_list ("A", 1, 4, PI, Array_Type[3]);
test_push_pop_list ();
test_push_pop_list ("A");
test_push_pop_list ({});
test_push_pop_list ("A", {});
   

print ("Ok\n");

exit (0);

