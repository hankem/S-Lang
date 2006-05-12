_debug_info = 1; () = evalfile ("inc.sl");

testing_feature ("looping constructs");

define identity (x)
{
   return x;
}

define test_do_while (count_fun)
{
   variable i = 0;
   variable count = 0;
   do
     {
	if (i == 3)
	  continue;
	i++;
     }
   while (@count_fun (&count) < 6);
   if ((count != 6) or (i != 3))
     failed ("do_while 1: %S", count_fun);

   i = 0;
   count = 0;
   do
     {
	if (i == 3)
	  break;
	i++;
     }
   while (@count_fun (&count) < 6);
   if ((count != 3) or (i != 3))
     failed ("do_while 2: %S", count_fun);
}

define test_while (count_fun)
{
   variable i = 0;
   variable count = 0;

   while (@count_fun (&count) < 6)
     {
	if (i == 3)
	  continue;
	i++;
     }
   if ((count != 6) or (i != 3))
     failed ("while 1: %S", count_fun);

   i = 0;
   count = 0;
   while (@count_fun (&count) < 6)
     {
	if (i == 3)
	  break;
	i++;
     }
   if ((count != 4) or (i != 3))
     failed ("while 2: %S", count_fun);
}

define test_for (count_fun)
{
   variable i = 0;
   variable count = 0;

   for (count = 0; @count_fun (&count) < 6; )
     {
	if (i == 3)
	  continue;
	i++;
     }
   if ((count != 6) or (i != 3))
     failed ("while 1: %S", count_fun);

   i = 0;
   for (count = 0; @count_fun (&count) < 6; )
     {
	if (i == 3)
	  break;
	i++;
     }
   if ((count != 4) or (i != 3))
     failed ("while 2: %S", count_fun);
}

define add_one (x)
{
   @x = @x + 1;
   return @x;
}

define add_one_with_call (x)
{
   @x = @x+1;
   return identity (@x);
}

define add_one_with_loop (x)
{
   variable i = 0;
   while (1)
     {
	@x = @x + 1;
	i++;
	if (i == 3)
	  break;
     }
   @x = @x - 2;
   return @x;
}


test_do_while (&add_one);
test_do_while (&add_one_with_call);
test_do_while (&add_one_with_loop);
   
test_while (&add_one);
test_while (&add_one_with_call);
test_while (&add_one_with_loop);
   
test_for (&add_one);
test_for (&add_one_with_call);
test_for (&add_one_with_loop);
   
print ("Ok\n");

exit (0);

