() = evalfile ("inc.sl");

testing_feature ("stack functions");

private define push(a)
{
   foreach (a)
     ;
}

private define check_stack (f, a)
{
   variable n = _stkdepth ();
   if (n != length (a))
     failed ("%s: _stkdepth != %d", f, n);
   variable list = __pop_list (n);
   ifnot (_eqs (list_to_array (list), a))
     failed ("%s: stack mismatch", f);
   __push_list (list);
}

private define check_stack_funcs ()
{
   push ([1,2,3,4,5]);
   _stk_roll (0);
   check_stack ("_stk_roll 0", [1,2,3,4,5]);
   _stk_roll (1);
   check_stack ("_stk_roll 1", [1,2,3,4,5]);
   _stk_roll (2);
   check_stack ("_stk_roll 2", [1,2,3,5,4]);
   _stk_roll (-2);
   check_stack ("_stk_roll -2", [1,2,3,4,5]);
   _stk_roll (-5); check_stack ("_stk_roll -5", [2,3,4,5,1]);
   _stk_roll (5); check_stack ("_stk_roll 5", [1,2,3,4,5]);

   _stk_reverse (0); check_stack ("_stk_reverse 0", [1,2,3,4,5]);
   _stk_reverse (1); check_stack ("_stk_reverse 1", [1,2,3,4,5]);
   _stk_reverse (3); check_stack ("_stk_reverse 3", [1,2,5,4,3]);
   try
     {
	_stk_reverse (-3);
	failed ("Expected _stk_reverse -3 to fail");
     }
   catch StackUnderflowError;
   check_stack ("_stk_reverse -3 corruption", [1,2,5,4,3]);

   dup (); check_stack ("dup", [1,2,5,4,3,3]);
   pop (); check_stack ("pop", [1,2,5,4,3]);
   exch (); check_stack ("exch", [1,2,5,3,4]);
}
check_stack_funcs ();

print ("Ok\n");

exit (0);

