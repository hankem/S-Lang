% -*- mode: slang; mode: fold -*-

import("json");

private define _json_generate (); %{{{

private define json_generate_number (number) %{{{
{
   return string(number);
}
%}}}

private define json_generate_boolean (bool) %{{{
{
   switch (bool)
     { case 1: return "true"; }
     { case 0: return "false"; }
   throw Json_Invalid_Json_Error, sprintf(`invalid boolean value '\%03o'; only '\000' and '\001' are allowed`, bool);
}
%}}}

private define json_generate_null () %{{{
{
   return "null";
}
%}}}

private define json_generate_object (indent, q, object) %{{{
{
   variable json = "{";
   variable keys = assoc_get_keys (object);
   variable n_values = length (keys);
   if (n_values)
     {
	variable new_indent = indent + q.indent;
	json += q.post_vsep;
	if (q.sort != NULL)
	  keys = keys[array_sort ( (typeof (q.sort) == Ref_Type) ? (keys, q.sort) : (keys) )];
	variable key;
	foreach key (keys)
	  json += new_indent
		+ _json_generate_string (key)
		+ q.pre_nsep + ":" + q.post_nsep
		+ _json_generate (new_indent, q, object[key])
		+ (n_values--, n_values ? q.pre_vsep + "," : "") + q.post_vsep;
     }
   json += indent + "}";
   return json;
}
%}}}

private define json_generate_array (indent, q, array) %{{{
{
   variable json = "["B;
   variable n_values = length (array);
   if (n_values)
     {
	json += q.post_vsep;
	variable new_indent = indent + q.indent;
	variable value;
	foreach value (array)
          {
             json += new_indent;
             json += _json_generate (new_indent, q, value);
             json += (n_values--, n_values ? q.pre_vsep + "," : "");
             json += q.post_vsep;
          }
     }
   json += indent;
   json += "]";
   return json;
}
%}}}

private define _json_generate (%indent, q,       % still on the stack
                                           data)
{
   variable type = typeof (data);
   switch (type)
     { case Assoc_Type:
	return json_generate_object (data);
     }
     { case List_Type:
	return json_generate_array (data);
     }
   _pop_n (2);  % simple values don't need (indent, q) arguments
   switch(type)
     { case String_Type or case BString_Type:
	return _json_generate_string (data);
     }
     { case UChar_Type:
	return json_generate_boolean (data);
     }
     { case Null_Type:
	return json_generate_null ();
     }
     {  if (0 < __is_numeric(data) < 3)
	  return json_generate_number (data);
	throw Json_Invalid_Json_Error, "$type does not represent a JSON data structure"$;
     }
}

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

   return struct {
      pre_nsep  = only_whitespace (qualifier ("pre_nsep", "")),
      post_nsep = only_whitespace (qualifier ("post_nsep", " ")),
      pre_vsep  = only_whitespace (qualifier ("pre_vsep", "")),
      post_vsep = only_whitespace (post_vsep),
      indent    = only_whitespace (indent),
      sort      = sort  % can be NULL, 1, or Ref_Type
   };
}
%}}}

define json_generate (data)
{
   return _json_generate (""B, process_qualifiers(;; __qualifiers), data);
}

%}}}
