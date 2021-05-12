() = evalfile ("./common.sl");

require ("structfuns");

private define test_struct_filter ()
{
   variable s, s1, i;

   s = struct
     {
	str = "foo",
	a1 = ["bar", "foo"],
	a2 = {1,2,3},
     };

   i = 0;
   s1 = struct_filter (s, i; copy);
   if ((s1.str != s.str)
       || (s1.a1 != "bar")
       || not _eqs (s1.a2, s.a2))
     failed ("filtering with i=0");

   s = struct
     {
	str = "foo",
	a1 = [1:3],
	a2 = _reshape ([1:3*4*5], [3,4*5]),
	a3 = _reshape ([1:3*4*5], [3,4,5]),
     };

   i = [1,2];
   s1 = struct_filter (s, i; dim=0, copy);
   if ((s1.str != s.str)
       || not _eqs (s1.a1, s.a1[i])
       || not _eqs (s1.a2, s.a2[i,*])
       || not _eqs (s1.a3, s.a3[i,*,*]))
     failed ("filtering on dim=0 failed");

   i = [1,2];
   s1 = struct_filter (s, i; dim=1, copy);
   if ((s1.str != s.str)
       || not _eqs (s1.a1, s.a1)
       || not _eqs (s1.a2, s.a2[*,i])
       || not _eqs (s1.a3, s.a3[*,i,*]))
     failed ("filtering on dim=1 failed");

   i = [1,2];
   s1 = struct_filter (s, i; dim=2, copy);
   if ((s1.str != s.str)
       || not _eqs (s1.a1, s.a1)
       || not _eqs (s1.a2, s.a2)
       || not _eqs (s1.a3, s.a3[*,*,i]))
     failed ("filtering on dim=1 failed");
}

private define test_struct_combine ()
{
   variable s1 = struct
     {
	a = "s1_a",
	b,
	c = "s1_c",
     };
   variable s2 = struct
     {
	x = "s2_x",
	c = "s2_c",
	y,
     };

   variable s1s2 = struct_combine (s1, s2);
   variable s = struct
     {
	a = s1.a,
	b = s1.b,
	c = s2.c,
	x = s2.x,
	y = s2.y,
     };

   ifnot (_eqs (s, s1s2))
     failed ("struct_combine");

   ifnot (struct_field_exists (s, "y"))
     failed ("struct_field_exists y");
   if (struct_field_exists (s, "xxxx"))
     failed ("struct_field_exists xxxx");
}

define slsh_main ()
{
   start_test ("structfuns");

   test_struct_filter ();
   test_struct_combine ();

   end_test ();
}

