() = evalfile ("./common.sl");

require ("rand");
require ("listfuns");

define test_heap (n, dir)
{
   variable rnums = rand_uniform (n);

   variable i;
   variable list = {};
   _for i (0, n/2-1, 1)
     list_append (list, rnums[i]);

   variable h = heap_new (list; dir=dir);

   _for i (n/2, n-1, 1)
     h.add (rnums[i]);

   list = {};
   while (h.length ())
     {
	list_append (list, h.remove());
     }
   rearrange (rnums, array_sort (rnums; dir=dir));

   if (length (rnums) != length (list))
     failed ("length of list != length of array");

   if (length (rnums) && any (rnums != list_to_array (list)))
     failed ("heap sorted list does not match sorted array");
}

define slsh_main ()
{
   start_test ("listfuns");
   srand (0);
   variable i;
   _for i (0, 33, 1)
     {
	test_heap (i, 1);
	test_heap (i, -1);
     }
   end_test();
}
