% Struct functions


%!%+
%\function{struct_filter}
%\synopsis{Apply a filter to a struct}
%\usage{struct_filter(Struct_Type s, Int_Type i)}
%\description
%  This function applies the filter \exmp{i} to the fields of a structure
%  by performing the operation
%#v+
%    s.field = s.field[i];
%#v-
%  on each array field of the structure.  Scalar fields will not be modified.
%\seealso{where}
%!%-
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



%!%+
%\function{struct_combine}
%\synopsis{Combine two or more structures}
%\usage{new_s = struct_combine (s1, s2, ...)}
%\description
%  This function creates a new structure from two or more structures
%  \exmp{s1}, \exmp{s2},....  The new structure will have fields formed by the
%  union of the fields of the input structures.  The new structure fields will
%  be given values that correspond to the fields of the input structures.  If
%  more than one structure has the same field name, the value of the field will
%  be given by the last structure.
%  
%  If an input value is a string, then it will be interpreted as a structure
%  with a single field of the corresponding name.  This is a useful feature
%  when one wants to expand a structure with new field names, e.g.,
%#v+
%    s = struct { foo, bar };
%    t = struct_combine (s, "baz");   % t = struct {foo, bar, baz};
%#v-
%\seealso{get_struct_field_names}
%!%-
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


%!%+
%\function{struct_field_exists}
%\synopsis{Determine whether or not a structure contains a specified field}
%\usage{Int_Type struct_field_exists (Struct_Type s, Struct_Type f)}
%\description
% This function may be used to determine if a structure contains a field with
% a specfied name.  It returns 0 if the structure does not contain the field, 
% or non-zero if it does.
%\seealso{get_struct_field_names}
%!%-
define struct_field_exists (s, field)
{   
   return length (where (field == get_struct_field_names (s)));
}

provide ("structfuns");
