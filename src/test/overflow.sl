() = evalfile ("inc.sl");

testing_feature ("literal integer overflow");

private define check_overflow (str, overflow)
{
   try
     {
	() = eval (str + ";");
	if (overflow)
	  failed ("Expected %s to generate an overflow error", str);
     }
   catch AnyError:
     {
	if (overflow == 0)
	  failed ("Obtained unexpected overflow error for %s", str);
     }
}
if (Int16_Type == Short_Type)
{
   check_overflow ("123456h", 1);
   check_overflow ("32768h", 1);
   check_overflow ("-32768h", 0);
   check_overflow ("65535hu", 0);
}
if (Int32_Type == Int_Type)
{
   check_overflow ("-2147483648", 0);
   check_overflow ("2147483648", 1);
   check_overflow ("4294967295U", 0);
   check_overflow ("4294967296U", 1);
}

print ("Ok\n");

exit (0);

