() = evalfile ("./common.sl");

require ("rand");
require ("listfuns");

private define cmp_func (a, b)
{
   if (a > b) return 1;
   if (a < b) return -1;
   return 0;
}

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
	variable obj = h.peek ();
	if (obj != h.remove ())
	  failed ("h.peek");
	list_append (list, obj);
     }
   rearrange (rnums, array_sort (rnums; dir=dir));

   if (length (rnums) != length (list))
     failed ("length of list != length of array");

   if (length (rnums) && any (rnums != list_to_array (list)))
     failed ("heap sorted list does not match sorted array");

   % shuffle the list, then sort the list using a custom sort function
   list = list[rand_permutation (length(list))];
   i = list_sort (list; dir=dir, cmp=&cmp_func);
   list = list[i];
   if (length (rnums) && any (rnums != list_to_array (list)))
     failed ("sorted list using a custom sort function");
}

define slsh_main ()
{
   start_test ("listfuns");

   try
     {
	heap_new ();
	failed ("heap_new usage");
     }
   catch UsageError;

   srand (0);
   variable i;
   _for i (0, 33, 1)
     {
	test_heap (i, 1);
	test_heap (i, -1);
     }
   end_test();
}
