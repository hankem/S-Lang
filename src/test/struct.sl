() = evalfile ("inc.sl");

testing_feature ("structures");

variable S = struct
{
   a, b, c,
};

S.a = "a";
S.b = "b";
S.c = "c";

variable U = @Struct_Type ("a", "b", "c");
variable abc = get_struct_field_names (U);
if ((abc[0] != "a")
    or (abc[1] != "b")
    or (abc[2] != "c"))
  failed ("@Struct_Type");

abc = ["a", "b", "c"];
U = @Struct_Type (abc);
if (length (where (abc != get_struct_field_names (U))))
  failed ("@Struct_Type([abc])");

variable T = @S;

if (S.a != T.a) failed ("Unable to copy via @S");
if (S.b != T.b) failed ("Unable to copy via @S");
if (S.c != T.c) failed ("Unable to copy via @S");

if (_eqs (S, T) == 0)
  failed ("_eqs(S,T) 1");

T.a = "XXX";
if (T.a == S.a) failed ("Unable to copy via @S");

if (_eqs (S, T))
  failed ("_eqs(S,T) 2");

set_struct_fields (T, 1, 2, "three");
if ((T.c != "three") or (T.a != 1) or (T.b != 2))
  failed ("set_struct_fields");

T.a++;
T.a += 3;
T.a -= 20;
if (T.a != -15)
  failed ("structure arithmetic");

#ifexists Complex_Type
T.a += 3+2i;			       %  =-18+2i
T.a -= 2*T.a - T.a;		       %  = 0
if (T.a != 0)
  failed ("structure arithmetic with complex fields");
#endif

T.c = S;
S.a = T;

if (T != T.c.a)
  failed ("Unable to create a circular list");

if (0 == _eqs (T, T.c.a))
  failed ("_eqs(T,T)");

T.a = [1:10];
S.a = [1:10];
T.b = S.b;
T.c = T;
S.c = S;

if (0 == _eqs (S,T))
  failed ("_eqs(S,T) circular 1");
T.c = S;
S.c = T;
if (0 == _eqs (S,T))
  failed ("_eqs(S,T) circular 2");
T.c = 1;
S.c = 0;

T.a = [1:10]*1;
T.a *= 2;
ifnot (_eqs(T.a, 2*[1:10]))
  failed ("T.a *= 2 for an array");

typedef struct
{
   TT_x, TT_y
}
TT;

T = @TT;
S = @T;
if (0 == _eqs (T,S))
  failed ("_eqs(T,S) for type TT");

if (typeof (T) != TT)
  failed ("typeof(T)");
if (0 == is_struct_type (T))
  failed ("is_struct_type");
S = typecast (T, Struct_Type);
if (typeof (S) != Struct_Type)
  failed ("typecast");
if (T != T)
  failed ("typedefed T != T");

if (_eqs (T,S))
  failed ("_eqs(T,S) for S and T different");

T = TT[3];
private variable i = where (T == T[2]);
if (length (i) != 1)
  failed ("where on array of TT, found length=%d", length(i));

% C structures

S = get_c_struct ();
if ((typeof (S.h) != Short_Type)
    or (typeof (S.l) != Long_Type)
    or (typeof (S.b) != Char_Type))
  failed ("get_c_struct field types");

private define print_struct(s)
{
   foreach (get_struct_field_names (s))
     {
	variable f = ();
	vmessage ("S.%s = %S", f, get_struct_field (s, f));
     }
}

#ifexists Complex_Type
S.z = 1+2i;
#endif
S.a = [1:10];
#ifexists Double_Type
S.d = PI;
#endif
S.s = "foobar";
S.ro_str = "FOO";

loop (10)
  set_c_struct (S);

loop (10)
  T = get_c_struct ();

%print_struct (T);

if ((not __is_same(S.a, T.a))
#ifexists Complex_Type
    or (S.z != T.z)
#endif
#ifexists Double_Type
    or (S.d != T.d)
#endif
    or (T.ro_str != "read-only"))
  failed ("C Struct");

loop (10)
  get_c_struct_via_ref (&T);

%print_struct (T);

if ((not __is_same(S.a, T.a))
#ifexists Complex_Type
    or (S.z != T.z)
#endif
#ifexists Double_Type
    or (S.d != T.d)
#endif
    or (T.ro_str != "read-only"))
  failed ("C Struct");

private define count_args ()
{
   if (_NARGS != 0)
     failed ("foreach using with NULL");
}
private define test_foreach_using_with_null (s)
{
   foreach (s) using ("next")
     {
	s = ();
     }
   count_args ();
}
test_foreach_using_with_null (NULL);

private define test_foreach ()
{
   variable s = struct
     {
	val = 1,
	next = struct
	  {
	     val = 2,
	     next = struct
	       {
		  val = 3,
		  next = NULL
	       }
	  }
     };
   variable c = 0;
   variable ss;
   foreach ss (s)
     c += ss.val;
   foreach ss (s) using ("next")
     c += 2*ss.val;

   if (c != 18)
     {
	failed ("foreach using implicit next");
     }
   try
     {
	foreach (s) using ("foo", "bar")
	  ss = ();
     }
   catch AnyError: return;

   failed ("Expected foreach with bad using clause to fail");
}
test_foreach ();

define return_struct_fun (c)
{
   variable s = struct
     {
	X
     };
   variable t = struct
     {
	c
     };
   s.X = Struct_Type[3];
   s.X[*] = t;
   t.c = c;
   return s;
}
() = return_struct_fun (1);
if (return_struct_fun(PI).X[2].c != PI)
  failed ("f(a).X[b].c");
$1 = &return_struct_fun;
if ((@$1)(PI).X[2].c != PI)
  failed ("f(a).X[b].c");

% Test operator overloading

typedef struct
{
   x, y, z
}
Vector_Type;

private define vector (a, b, c)
{
   variable v = @Vector_Type;
   v.x = a;
   v.y = b;
   v.z = c;
   return v;
}

private define vector_sqr (v)
{
   return v.x^2 + v.y^2 + v.z^2;
}
private define vector_abs (v)
{
   return sqrt (vector_sqr (v));
}
private define vector_chs (v)
{
   v = @v;
   v.x = -v.x;
   v.y = -v.y;
   v.z = -v.z;
   return v;
}

private variable Num_Destroyed = 0;
private define destroy_vector (v)
{
   Num_Destroyed++;
}

__add_unary ("-", Vector_Type, &vector_chs, Vector_Type);
__add_unary ("abs", Double_Type, &vector_abs, Vector_Type);
__add_unary ("sqr", Double_Type, &vector_sqr, Vector_Type);
__add_destroy (Vector_Type, &destroy_vector);

private define vector_plus (v1, v2)
{
   variable v = @Vector_Type;
   v.x = v1.x + v2.x;
   v.y = v1.y + v2.y;
   v.z = v1.z + v2.z;
   return v;
}
__add_binary ("+", Vector_Type, &vector_plus, Vector_Type, Vector_Type);

private define vector_minus (v1, v2)
{
   variable v = @Vector_Type;
   v.x = v1.x - v2.x;
   v.y = v1.y - v2.y;
   v.z = v1.z - v2.z;
   return v;
}
__add_binary ("-", Vector_Type, &vector_minus, Vector_Type, Vector_Type);

private define scalar_vector_mul (a, u)
{
   variable v = @Vector_Type;
   v.x = a*u.x;
   v.y = a*u.y;
   v.z = a*u.z;
   return v;
}
__add_binary ("*", Vector_Type, &scalar_vector_mul, Any_Type, Vector_Type);

private define dotprod (u, v)
{
   return u.x*v.x + u.y*v.y + u.z*v.z;
}
__add_binary ("*", Double_Type, &dotprod, Vector_Type, Vector_Type);

private define vector_scalar_mul (v, a)
{
   return scalar_vector_mul (a,v);
}
__add_binary ("*", Vector_Type, &vector_scalar_mul, Vector_Type, Any_Type);

private define vector_eqs (a,b)
{
   return ((a.x == b.x)
	   and (a.y == b.y)
	   and (a.z == b.z));
}
__add_binary ("==", Char_Type, &vector_eqs, Vector_Type, Vector_Type);

private define vector_neqs (a,b)
{
   return not vector_eqs (a, b);
}
__add_binary ("!=", Char_Type, &vector_neqs, Vector_Type, Vector_Type);

private define vector_string (a)
{
   if (_NARGS != 1)
     failed ("__add_string: _NARGS!=1");
   sprintf ("[%S,%S,%S]", a.x, a.y, a.z);
}
__add_string (Vector_Type, &vector_string);

private define vector_aget (i, v)
{
   return vector (v.x[i], v.y[i], v.z[i]);
}
__add_aget (Vector_Type, &vector_aget);

private define vector_aput (i, v)
{
   variable u = ();
   v.x[i] = u.x;
   v.y[i] = u.y;
   v.z[i] = u.z;
}
__add_aput (Vector_Type, &vector_aput);

typedef struct
{
   ax, ay, az,
}
Matrix33_Type;

private define matrix33 (ax, ay, az)
{
   variable m = @Matrix33_Type;
   m.ax = vector (ax[0], ax[1], ax[2]);
   m.ay = vector (ay[0], ay[1], ay[2]);
   m.az = vector (az[0], az[1], az[2]);
   return m;
}
private define matrix_vector_mul (m, v)
{
   return vector (m.ax*v, m.ay*v, m.az*v);
}
__add_binary ("*", Vector_Type, &matrix_vector_mul, Matrix33_Type, Vector_Type);

private define test_matrix_vector_mul ()
{
   variable v = vector (1, 2, 3);
   variable m = matrix33 ([4, 5, 6], [7, 8, 9], [1,2,3]);
   variable mv = m*v;
   if (typeof (mv) != Vector_Type)
     failed ("typeof Matrix33_Type*Vector_Type");
   if ((mv.x != (4*1+5*2+6*3))
       || (mv.y != (7*1+8*2+9*3))
       || (mv.z != (1*1+2*2+3*3)))
     failed ("Matrix33_Type*Vector_Type");
}
test_matrix_vector_mul ();

private define test_aget_aput ()
{
   variable v = vector ([0:10], [1:11], [2:12]);
   variable u = v[3];
   if ((u.x != 3) || (u.y != 4) || (u.z != 5))
     failed ("vector aget");

   v[4] = u + vector(1,1,1);
   u = v[4];
   if ((u.x != 4) || (u.y != 5) || (u.z != 6))
     failed ("vector aput");
}
test_aget_aput ();

private define test_destroy ()
{
   Num_Destroyed = 0;
   variable v1 = vector(1,2,3), v2 = vector (3, 4, 5);
   try
     {
	() = @Vector_Type + "foo";
     }
   catch AnyError;
   if (Num_Destroyed != 1)
     failed ("Expected Num_Destroyed = 1, found %S", Num_Destroyed);
   Num_Destroyed = 0;

   variable v3 = v1 + v2;
   if (Num_Destroyed)
     failed ("unexpected destroy method called");
   v3 = 0;
   v2 = v1;
   if (Num_Destroyed != 2)
     failed ("expected destroy method to be called 2 times");
   v2 = 0;
   if (Num_Destroyed != 2)
     failed ("expected destroy method to be called 2 times");
   v1 = 0;
   if (Num_Destroyed != 3)
     failed ("expected destroy method to be called 3 times");

   __add_destroy (Vector_Type, &destroy_vector);
   __add_destroy (Vector_Type, &destroy_vector);
   __add_destroy (Vector_Type, &destroy_vector);
   __add_destroy (Vector_Type, &destroy_vector);
}
test_destroy ();

private variable X = vector (1,2,3);

if (not vector_eqs (-X, vector_chs (X)))
  failed ("Vector chs(X)");

if (sqr(X) != vector_sqr(X))
  failed ("Vector sqr(X)");

if (abs(X) != vector_abs(X))
  failed ("Vector abs(X)");

if (vector_string (X) != string (X))
  failed ("Vector string(X)");

private define vector_to_list (v)
{
   return {v.x, v.y, v.z};
}
private define is_vector_eq_to_list (v, l)
{
   return ((length (l) == 3)
	   && (l[0] == v.x) && (l[1] == v.y) && (l[2] == v.z));
}
__add_typecast (Vector_Type, List_Type, &vector_to_list);

private define vector_to_complex (v)
{
   return v.x + 1j*v.y;
}
private define is_vector_eq_to_complex (v, z)
{
   return (vector_to_complex (v) == z);
}
__add_typecast (Vector_Type, Complex_Type, &vector_to_complex);

private define vector_to_stdout (v)
{
   return stdout;
}
private define is_vector_eq_to_stdout (v, s)
{
   return ((vector_to_stdout(v) == s)
	   && (fileno (s) == fileno (v)));
}
__add_typecast (Vector_Type, File_Type, &vector_to_stdout);

private define vector_to_string (v)
{
   return sprintf ("%S e_x + %S e_y + %S e_z", v.x, v.y, v.z);
}
private define is_vector_eq_to_string (v, z)
{
   return ((vector_to_string (v) == z)
	   && (0 == strcmp (v, z)));
}
__add_typecast (Vector_Type, String_Type, &vector_to_string);

private define test_typecast (to, eqsfun)
{
   variable v = vector (4,5,6);
   variable l = typecast (v, to);
   ifnot ((@eqsfun) (v, l))
     failed ("simple vector not equal to %S", to);
   v = [vector(4,5,6),
		 vector (7,8,9),
		 vector (1i,2i,3i)];
   l = typecast (v, to);
   _for (0, length (v)-1, 1)
     {
	variable i = ();
	ifnot ((@eqsfun) (v[i], l[i]))
	  failed ("array of vectors not equal to array of %S", to);
     }
}
test_typecast (List_Type, &is_vector_eq_to_list);
test_typecast (Complex_Type, &is_vector_eq_to_complex);
test_typecast (File_Type, &is_vector_eq_to_stdout);
test_typecast (String_Type, &is_vector_eq_to_string);

% test binary
private variable Y = vector (4, 5, 6);

if (X == X) ; else failed ("Vector == Vector");
if (X == Y) failed ("Vector X == Vector Y");
if (X + vector (3,3,3) != Y) failed ("Vector +");
if (X + 3*vector(1,1,1) != Y) failed ("Vector *");
if (X + vector(1,1,1)*3 != Y) failed ("* Vector");
if (Y - X != vector (3,3,3)) failed ("Vector -");

if (X == NULL)
  failed ("X is NULL??");

% Now test arrays of Vector_Type
X = Vector_Type[3];

X[0] = vector (1,2,3);
X[1] = vector (1,2,3);
X[2] = vector (1,2,3);
%X = Vector_Type[3];

%Y = vector_chs (X);
Y = -X;

if (not vector_eqs (Y[0], vector_chs (X[0])))
  failed ("Vector chs(X)");

Y = sqr(X);
if (Y[1] != vector_sqr(X[1]))
  failed ("Vector sqr(X)");

Y = abs (X);
if (Y[2] != vector_abs(X[2]))
  failed ("Vector abs(X)");

Y = 2*X;
if (Y[2] != 2*X[2])
  failed ("Vector 2*X");

Y = X + 2*X;
if (Y[2] != 3*X[2])
  failed ("Vector 3*X");

Y = (X == X);
if (length (where (Y != 1)))
  failed ("X == X");

private define test_duplicate_fields (fields, isok)
{
   try
     {
	() = eval ("struct {$fields}"$);
	if (0 == isok)
	  failed ("Created a struct with duplicate fields");
     }
   catch DuplicateDefinitionError;
   catch AnyError:
     {
	failed ("Unexpected error when creating a struct with duplicate fields %s", fields);
     }
}
test_duplicate_fields ("a", 1);
test_duplicate_fields ("a, a", 0);
test_duplicate_fields ("a, b, c", 1);
test_duplicate_fields ("a, b, a", 0);
test_duplicate_fields ("a, a, b", 0);
test_duplicate_fields ("a, b, c, b, e", 0);
test_duplicate_fields ("a, b, c, b, e, a", 0);
test_duplicate_fields ("a, b, c, d, e, e", 0);

private define test_struct_with_assign (exprs)
{
   variable i, n = length (exprs);
   variable fields = array_map (String_Type, &sprintf, ("field%d", [1:n]));

   variable s0 = @Struct_Type(fields);
   variable s1_expr = "struct {\n";
   _for i (0, n-1, 1)
     {
	variable expr = exprs[i];
	variable field = fields[i];

	if (expr != NULL)
	  {
	     s1_expr = strcat (s1_expr, field, "= ", expr, ",\n");
	     set_struct_field (s0, field, eval(expr));
	     continue;
	  }

	s1_expr = strcat (s1_expr, field, ",\n");
     }
   s1_expr = strcat (s1_expr, "};");

   variable s1 = eval (s1_expr);
   if (not _eqs (s0, s1))
     failed ("structures are not equal: %s", s1_expr);
}

test_struct_with_assign ([NULL]);
test_struct_with_assign ([NULL, "3"]);
#ifexists Double_Type
test_struct_with_assign (["3*sin(2)", NULL]);
#endif
test_struct_with_assign (["13", "[1:10]"]);
test_struct_with_assign (["-2", NULL, "[1:10]"]);
test_struct_with_assign (["-10", "[1:10]", "NULL"]);
test_struct_with_assign (["&strcat", "[1:10]", "NULL", NULL]);
test_struct_with_assign (["struct{a,b}"]);
test_struct_with_assign (["struct{a,b}", NULL]);
#ifexists Complex_Type
test_struct_with_assign (["1+2j", NULL]);
#endif
test_struct_with_assign (["\"string\""]);

define test_struct_refs ()
{
   variable s = struct {foo, bar};
   variable f = &s.bar;
   @f = 7;
   if (s.bar != 7)
     failed ("ref to s.bar via f");

   @(&s.bar) = 3;
   if (s.bar != 3)
     failed ("@(&s.bar)");

   @&s.bar = "foo";
   if (s.bar != "foo")
     failed ("@&s.bar");
}
test_struct_refs ();

private define test_internal_struct_type ()
{
   variable t;

   loop (5)
     {
	t = new_test_type ();
	t.field1 = 7;
	t.field2 = 3;
	t.field1 += 4;
	t.field1 -= t.field2;
	if (t.field1 != 8)
	  failed ("new_test_type");
     }
}
test_internal_struct_type ();

private define test_it (p)
{
   loop (5)
     {
	variable userdata = struct{items};

	p.any = @userdata;
	p.any.items = {};

	p.any = @userdata;
	variable x = @userdata;
	p.any = x;
	x.items = {};
     }
}
test_it (new_test_type ());

define test_struct_merge ()
{
   variable s = struct
     {
	x = 3,
	@ @Vector_Type,
	t = 1,
     };
   if (s.x != NULL)
     failed ("struct merge: x is non-NULL");

   s = struct
     {
	@ vector(1,2,3)+vector(4,5,6),
	x = -1, y = -2,
     };
   if ((s.z != 9) || (s.x != -1) || (s.y != -2))
     failed ("struct merge: vector+vector");
}
test_struct_merge ();

private define test_push_struct_fields ()
{
   variable field, fields = ["foo", "bar", "baz"];
   variable v0 = {"20", "30", "40"}, v1, v2;

   variable s = @Struct_Type(fields);
   set_struct_fields (s, __push_list (v0));

   variable i, n;

   % usage form 1
   n = _push_struct_field_values(s);
   if (n != length (fields))
     failed ("Expected _push_struct_field_values to return %d, got %d", length(fields), n);

   _for i (0, n-1, 1)
     {
	v1 = ();
	v2 = get_struct_field (s, fields[i]);
	if (v1 != v2)
	  failed ("Expecting _push_struct_field_values to push %S at i=%d, found %S", v2, i, v1);
     }

   % usage form 2
   v1 = {_push_struct_field_values (s, fields)};
   ifnot (_eqs (v1, v0))
     failed ("_push_struct_field_values usage form 2 produced incorrect result");

   v2 = { _push_struct_field_values (s, String_Type[0]) };
   if (length (v2) != 0)
     failed ("Expected _push_struct_field_values to return nothing for an empty array");

   if (NULL != _push_struct_field_values (s, "b i z a r r e"))
     failed ("_push_struct_field_values failed to return NULL for non-existent field");
}

test_push_struct_fields ();

% Intrinsic structure
private define test_intrinsic_structure ()
{
   variable s = Intrinsic_Struct;
   if (s.name != "My_Struct")
     failed ("Intrinsic_Struct name: %S", s.name);

   try
     {
	s.name = "foo";
	failed ("Intrinsic_Struct.name should be read-only");
     }
   catch ReadOnlyError;
   s.i = 37;
   s.s = "foobar";
   s.d = PI;
   if ((s.i != 37) || (s.s != "foobar") || (s.d != PI))
     failed ("Intrinsic_Struct field read/write error");
}
test_intrinsic_structure();

private define test_struct_with_reserved_fields ()
{
   variable s = struct
     {
	public = "*public*",
	define = "*define*",
	not = "*not*",
	xor = "*xor*",
	then = "*then*",
	else = "*else*",
	struct = "*struct*",
     };

   variable name, names = get_struct_field_names (s);
   foreach name (names)
     {
	variable v = get_struct_field (s, name);
	if (v != "*$name*"$)
	  failed ("struct with reserved name %S", name);
     }
   s.struct = struct
     {
	struct = "<struct>",
     };
   if (s.struct.struct != "<struct>")
     failed ("s.struct with struct failure");
   s.struct.struct = "foo";
   if (s.struct.struct != "foo")
     failed ("s.struct as LVALUE");
}
test_struct_with_reserved_fields ();

print ("Ok\n");
exit (0);

