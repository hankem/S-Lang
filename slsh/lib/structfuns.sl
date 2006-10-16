% Struct functions

define struct_filter (s, i)
{
   variable field;
   
   foreach field (get_struct_field_names (s))
     {
	variable value = get_struct_field (s, field);
	if (typeof (value) == Array_Type)
	  set_struct_field (s, field, value[i]);
     }
}

define struct_combine ()
{
   variable args = __pop_args (_NARGS);
   variable fields = String_Type[0];
   variable arg;
   foreach arg (args)
     {
	arg = arg.value;
	if (is_struct_type (arg))
	  arg = get_struct_field_names (arg);
	fields = [fields, arg];
     }
   
   % Get just the unique names
   variable i, a = Assoc_Type[Int_Type];
   _for i (0, length (fields)-1, 1)
     a[fields[i]] = i;
   i = assoc_get_values (a);
   fields = fields[i[array_sort (i)]];

   variable s = @Struct_Type (fields);
   foreach arg (args)
     {
	arg = arg.value;
	if (0 == is_struct_type (arg))
	  continue;
	foreach (get_struct_field_names (arg))
	  {
	     variable field = ();
	     set_struct_field (s, field, get_struct_field (arg, field));
	  }
     }
   return s;
}

define struct_field_exists (s, field)
{   
   return length (where (field == get_struct_field_names (s)));
}

$1 = path_concat (path_dirname (__FILE__), "help/structfuns.hlp");
if (NULL != stat_file ($1))
  add_doc_file ($1);

provide ("structfuns");
