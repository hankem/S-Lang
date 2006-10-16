% These functions were taken from the jed editor

private variable Features;
if (0 == __is_initialized (&Features))
  Features = Assoc_Type [Int_Type,0];

private define pop_feature_namespace (nargs)
{
   variable f, ns = current_namespace ();
   if (nargs == 2)
     ns = ();
   f = ();
   if ((ns == NULL) or (ns == ""))
     ns = "Global";
   return strcat (ns, ".", f);
}

define _featurep ()
{
   variable f;
   f = pop_feature_namespace (_NARGS);
   return Features[f];
}

define provide ()
{
   variable f = pop_feature_namespace (_NARGS);
   Features[f] = 1;
}

define require ()
{
   variable f, file;
   variable ns = current_namespace ();
   switch (_NARGS)
     {
      case 1:
	f = ();
	file = f;
     }
     {
      case 2:
	(f, ns) = ();
	file = f;
     }
     {
      case 3:
	(f, ns, file) = ();
     }
     {
	usage ("require (feature [,namespace [,file]])");
     }

   if (_featurep (f, ns))
     return;

   if (ns == NULL)
     () = evalfile (file);
   else
     () = evalfile (file, ns);
#iffalse
   !if (_featurep (f, ns))
     vmessage ("***Warning: feature %s not provided by %s", f, file);
#endif
}

$1 = path_concat (path_dirname (__FILE__), "help/require.hlp");
if (NULL != stat_file ($1))
  add_doc_file ($1);

