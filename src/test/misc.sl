() = evalfile ("inc.sl");

testing_feature ("misc");

private variable Mypid_Env = sprintf ("MYPID=%d", getpid ());
putenv (Mypid_Env);
private define test_env ()
{
   variable s = getenv ("MYPID");
   if ((s == NULL) || (atoi (s) != getpid()))
     failed ("getenv/putenv");
   variable a = get_environ ();
   if (a != NULL)
     {
	if (((typeof (a) != Array_Type)) || (_typeof(a) != String_Type))
	  failed ("get_environ failed to produce an array of strings");
	ifnot (any (a == Mypid_Env))
	  failed ("get_environ failed to produce %s", Mypid_Env);
     }
#ifdef UNIX
   a = [__get_defined_symbols(), pop()];
   if (length (where(a == "UNIX")) != 1)
     failed ("expected __get_defined_symbols to produce UNIX");
#endif
}
test_env ();

private define test_datatypes ()
{
   variable type;
   foreach type (Int_Type, Long_Type, Char_Type, Short_Type, String_Type)
     {
	if (__datatype (__class_id (type)) != type)
	  failed ("__datatype/__class_id %S", type);
     }
   if ((__class_type (Int_Type) != 1)
       || (__class_type (String_Type) != 3))
     failed ("__class_type");

   variable objlist =
     {
	{"foo", String_Type, 0, 0},
	{0, Int_Type, 1, 1},
#ifexists Double_Type
	{0.0, Double_Type, 2, 2},
#endif
#ifexists Complex_Type
	{2j, Complex_Type, 3, 3},
#endif
	{[1,2], Array_Type, 1, 0},
	{{1,2}, List_Type, 0, 0},
     };
   foreach (objlist)
     {
	variable obj = ();
	if (typeof (obj[0]) != obj[1])
	  failed ("typeof %S != %S", obj[0], obj[1]);
	if (__is_numeric (obj[0]) != obj[2])
	  failed ("__is_numeric %S", obj[0]);
	if (__is_datatype_numeric (obj[1]) != obj[3])
	  failed ("__is_datatype_numeric %S", obj[1]);
     }
}
test_datatypes ();

static define test_apropos ()	       %  static for this test
{
   variable a = _apropos ("Global", "^str", 0xF);
   if (typeof (a) != Array_Type)
     failed ("Expected _apropos to return an array");
   if (length (a) == 0)
     failed ("Expected _apropos to return a non-empty array");
   if (any (strncmp (a, "str", 3)))
     failed ("_apropos did not return all string beginning with str");

   % Obsolete form
   variable n = _apropos ("^str", 0xF);
   variable b = __pop_list (n);
   b = list_to_array (b);
   b = b[array_sort(b)];
   a = a[array_sort(a)];
   ifnot (_eqs(a,b))
     failed ("_apropos obsolete form");

   a = _apropos ("", ".", 0xF);
   ifnot (any (a == _function_name()))
     failed ("_apropos failed to return static namespace");
}
test_apropos ();

print ("Ok\n");

exit (0);

