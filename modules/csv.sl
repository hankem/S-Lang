import ("./csv");

private define read_callback (fp)
{
   variable line;
   if (-1 == fgets (&line, fp))
     return NULL;

   return line;
}

define csv_parser_new ()
{
   if (_NARGS != 1)
     usage ("obj = csv_parser_new (file|fp ; quote='\"', delim=',')");

   variable fp = ();
   if (typeof (fp) != File_Type)
     {
	fp = fopen (fp, "r");
	if (fp == NULL)
	  throw OpenError, "Unable to open CSV file";
     }
   variable delim = qualifier("delim", ',');
   variable quote = qualifier("quote", '"');
   variable csv = _csv_parser_new (&read_callback, fp, delim, quote);
   return csv;
}
