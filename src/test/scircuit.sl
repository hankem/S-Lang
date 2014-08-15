() = evalfile ("inc.sl");

testing_feature ("Short Ciruit Operators");

private variable Fired = 0;
private define fun (tf)
{
   Fired++;
   return tf;
}

private define test_sc (one)
{
   Fired = 0;
   if (one && fun(one) && 0 && fun(0) && fun (one))
     failed ("Simple &&");
   if (Fired != 1)
     failed ("&& is not short circuiting (one=%d)", one);

   Fired = 0;
   if (0 == (0 || fun(one) || 0 || fun(0) || fun (one)))
     failed ("Simple || (one=%d)", one);
   if (Fired != 1)
     failed ("|| is not short circuiting (one=%d)", one);

   Fired = 0;
   if (0 == (fun(0) && fun(0) || one || fun(one)))
     failed ("mixed && || (one=%d)", one);
   if (Fired != 1)
     failed ("mixed && || did not short circuit: Fired=%d", Fired);

   Fired = 0;
   if (one && fun(0) || one && fun(0) || 0 && fun(0))
     {
	failed ("mixed || && 2 (one=%d)", one);
     }
   if (Fired != 2)
     failed ("mixed || && 2 did not short circuit (one=%d)", one);

   variable a = [1,2];
   if (length (a) > 5 && a[5] == 3)
     failed ("Simple && case 2 failed (one=%d)", one);
}

test_sc (1);
test_sc (256);
test_sc (1024);

print ("Ok\n");

exit (0);

