% -*- mode: slang; mode: fold -*-

import("json");

%{{{ Type Handlers

% Forward declarations
private define generate_object ();
private define generate_array ();

private variable Type_Map = Ref_Type[0];
private define add_type_handler (type, func)
{
   variable idx = __class_id (type);
   variable n = length (Type_Map);
   if (idx >= n)
     {
	variable new_map = Ref_Type[idx+1];
	new_map[[0:n-1]] = Type_Map;
	Type_Map = new_map;
     }
   Type_Map[idx] = func;
}

add_type_handler (Assoc_Type, &generate_object);
add_type_handler (List_Type, &generate_array);
add_type_handler (Array_Type, &generate_array);

private define generate_string (indent, q, data)
{
   return _json_encode_string (data);
}
add_type_handler (String_Type, &generate_string);
add_type_handler (BString_Type, &generate_string);

private define generate_boolean (indent, q, data)
{
   if (data == 1) return "true"B;
   if (data == 0) return "false"B;
   throw Json_Invalid_Json_Error, sprintf(`invalid boolean value '\%03o'; only '\000' and '\001' are allowed`, data);
}
add_type_handler (UChar_Type, &generate_boolean);

private define generate_null (indent, q, data)
{
   return "null"B;
}
add_type_handler (Null_Type, &generate_null);

private define generate_number (indent, q, data)
{
   return string (data);
}
foreach $1 (
	    [Char_Type, % UChar_Type,
	     Short_Type, UShort_Type,
	     Int_Type, UInt_Type,
	     Long_Type, ULong_Type,
#ifexists LLong_Type
	     LLong_Type, ULLong_Type,
#endif
	     Float_Type, Double_Type,
	    ])
{
   add_type_handler ($1, &generate_number);
}

private define default_handler (indent, q, data)
{
   if (0 < __is_numeric(data) < 3)
     return generate_number (data);

   variable type = _typeof (data);
   throw Json_Invalid_Json_Error, "$type does not represent a JSON data structure"$;
}
Type_Map[where (_isnull (Type_Map))] = &default_handler;

private define get_generate_func (type)
{
   try
     {
	variable func = Type_Map[__class_id (type)];
	if (func == NULL) throw IndexError;
	return func;
     }
   catch IndexError:
     throw Json_Invalid_Json_Error, "$type does not represent a JSON data structure"$;
}

%}}}

private define _json_encode (indent, q, data)
{
   return (@get_generate_func(typeof (data)))(indent, q, data);
}

private define generate_object (indent, q, object) %{{{
{
   variable json = "{"B;
   variable keys = assoc_get_keys (object);
   variable n_values = length (keys);
   if (n_values)
     {
	if (q.sort != NULL)
	  keys = keys[array_sort ( (typeof (q.sort) == Ref_Type) ? (keys, q.sort) : (keys) )];

	% pvs indent KEY nsep VAL vsep pvs indent KEY nsep VAL vsep
	% ... pvs indent KEY nsep VAL pvs
	variable new_indent = indent + q.indent;
	variable sep = q.vsep + q.post_vsep + new_indent, nsep = q.nsep;

	json += q.post_vsep + new_indent;

	variable i, key = keys[0], val = object[key];
	variable type = typeof (val);
	variable func = get_generate_func (type);

	json += _json_encode_string (key) + nsep
	  + (@func)(new_indent, q, val);

	_for i (1, n_values-1, 1)
          {
	     key = keys[i]; val = object[key];
	     variable next_type = typeof(val);
	     if (next_type == String_Type)
	       {
		  json = bstrcat (__tmp(json), sep, _json_encode_string (key),
				  nsep, _json_encode_string (val));
		  continue;
	       }

	     if (next_type != type)
	       {
		  func = get_generate_func (next_type);
		  type = next_type;
	       }

	     json = bstrcat (__tmp(json), sep, _json_encode_string (key),
			     nsep, (@func)(new_indent, q, val));
          }
	json += q.post_vsep;
     }
   return __tmp(json) + indent + "}";
}
%}}}

private define generate_array (indent, q, array) %{{{
{
   variable json = "[";
   variable n_values = length (array);
   if (n_values)
     {
	%  pvs, new_indent, VALUE, vsep, pvs, new_indent, VALUE, vsep, pvs, ..., new_indent, VALUE, pvs
	json += q.post_vsep;

	variable new_indent = indent + q.indent;
	variable sep = q.vsep + q.post_vsep + new_indent;
	variable i = 0, a = array[i];
	variable type = typeof (a);
	variable func = get_generate_func (type);

	json += new_indent + (@func)(new_indent, q, a);

	if ((typeof (array) == Array_Type)
	    && (0 == any(_isnull(array))))
	  {
	     if (type == String_Type) _for i (1, n_values-1, 1)
	       json = bstrcat (__tmp(json), sep, _json_encode_string(array[i]));
	     else _for i (1, n_values-1, 1)
	       json = bstrcat (__tmp(json), sep, (@func)(new_indent, q, array[i]));
	  }
	else _for i (1, n_values-1, 1)
	  {
	     a = array[i];
	     variable next_type = typeof (a);
	     if (next_type == String_Type)
	       {
		  json = bstrcat (__tmp(json), sep, _json_encode_string(a));
		  continue;
	       }

	     if (next_type != type)
	       {
		  func = get_generate_func (next_type);
		  type = next_type;
	       }
	     json = bstrcat (__tmp(json), sep, (@func)(new_indent, q, a));
	  }

	json += q.post_vsep;
     }
   return __tmp(json) + indent + "]";
}
%}}}

% process_qualifiers %{{{

private define only_whitespace (s)
{
   return ""B + str_delete_chars (s, "^ \t\n\r");
}

private define process_qualifiers ()
{
   variable post_vsep = "|" + qualifier ("post_vsep", "\n  ");
   variable indent = "";
   variable tok = strtok (post_vsep, "\n");
   if (length (tok) > 1)
     {
	indent = tok[-1];
	tok[-1] = "";
	post_vsep = strjoin (tok, "\n");
     }
   variable sort = qualifier ("sort");  % == NULL, if qualifier "sort" does not exist
   if (qualifier_exists ("sort") && typeof (sort) != Ref_Type)
     sort = 1;

   variable q = struct {
      pre_nsep  = only_whitespace (qualifier ("pre_nsep", "")),
      post_nsep = only_whitespace (qualifier ("post_nsep", " ")),
      pre_vsep  = only_whitespace (qualifier ("pre_vsep", "")),
      post_vsep = only_whitespace (post_vsep),
      indent    = only_whitespace (indent),
      sort      = sort  % can be NULL, 1, or Ref_Type
   };
   return struct {
      nsep = q.pre_nsep + ":" + q.post_nsep,
      vsep = q.pre_vsep + ",",
      @q
   };
}
%}}}

define json_encode (data)
{
   variable json = _json_encode (""B, process_qualifiers(;; __qualifiers), data);
   return typecast (json, String_Type);
}
