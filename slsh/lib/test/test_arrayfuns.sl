() = evalfile ("./common.sl");

require ("arrayfuns");

define slsh_main ()
{
   start_test ("arrayfuns");

   variable a = [1:10], b;

   b = reverse (a);
   ifnot (_eqs(b, [10:1:-1]))
     failed ("reverse");

   b = shift (a, 1);
   ifnot (_eqs (b, [[2:10], 1]))
     failed ("shift 1");
   b = shift (a, -1);
   ifnot (_eqs (b, [10, [1:9]]))
     failed ("shift -1");

   variable i = [8, 9, 2, 1, 0, 7, 5, 6, 4, 3], i1;
   b = @a;
   i1 = @i;
   rearrange (b, i);
   ifnot (_eqs (i, i1))
     failed ("rearrange modified the indices");
   ifnot (_eqs (b, a[i]))
     failed ("rearrange");
   i[3] = i[7];
   try
     {
	rearrange (b, i);
	failed ("Expected rearrange to fail on a bad permutation");
     }
   catch AnyError;

   end_test ();
}
