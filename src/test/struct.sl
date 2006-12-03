_debug_info = 1; () = evalfile ("inc.sl");

testing_feature ("structures");

variable S = struct 
{
   a, b, c
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
  failed ("_eqs(S,T) circular 1");
T.c = 1;
S.c = 0;

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
static variable i = where (T == T[2]);
if (length (i) != 1)
  failed ("where on array of TT, found length=%d", length(i));

% C structures

S = get_c_struct ();
if ((typeof (S.h) != Short_Type)
    or (typeof (S.l) != Long_Type)
    or (typeof (S.b) != Char_Type))
  failed ("get_c_struct field types");

static define print_struct(s)
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

static define count_args ()
{
   if (_NARGS != 0)
     failed ("foreach using with NULL");
}
static define test_foreach_using_with_null (s)
{
   foreach (s) using ("next")
     {
	s = ();
     }
   count_args ();
}
test_foreach_using_with_null (NULL);

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

static define vector (a, b, c)
{
   variable v = @Vector_Type;
   v.x = a;
   v.y = b;
   v.z = c;
   return v;
}

static define vector_sqr (v)
{
   return v.x^2 + v.y^2 + v.z^2;
}
static define vector_abs (v)
{
   return sqrt (vector_sqr (v));
}
static define vector_chs (v)
{
   v = @v;
   v.x = -v.x;
   v.y = -v.y;
   v.z = -v.z;
   return v;
}

__add_unary ("-", Vector_Type, &vector_chs, Vector_Type);
__add_unary ("abs", Double_Type, &vector_abs, Vector_Type);
__add_unary ("sqr", Double_Type, &vector_sqr, Vector_Type);

static define vector_plus (v1, v2)
{
   variable v = @Vector_Type;
   v.x = v1.x + v2.x;
   v.y = v1.y + v2.y;
   v.z = v1.z + v2.z;
   return v;
}
__add_binary ("+", Vector_Type, &vector_plus, Vector_Type, Vector_Type);

static define vector_minus (v1, v2)
{
   variable v = @Vector_Type;
   v.x = v1.x - v2.x;
   v.y = v1.y - v2.y;
   v.z = v1.z - v2.z;
   return v;
}
__add_binary ("-", Vector_Type, &vector_minus, Vector_Type, Vector_Type);

static define scalar_vector_mul (a, u)
{
   variable v = @Vector_Type;
   v.x = a*u.x;
   v.y = a*u.y;
   v.z = a*u.z;
   return v;
}
__add_binary ("*", Vector_Type, &scalar_vector_mul, Any_Type, Vector_Type);

static define vector_scalar_mul (v, a)
{
   return scalar_vector_mul (a,v);
}
__add_binary ("*", Vector_Type, &vector_scalar_mul, Vector_Type, Any_Type);

static define vector_eqs (a,b)
{
   return ((a.x == b.x)
	   and (a.y == b.y)
	   and (a.z == b.z));
}
__add_binary ("==", Char_Type, &vector_eqs, Vector_Type, Vector_Type);

static define vector_neqs (a,b)
{
   return not vector_eqs (a, b);
}
__add_binary ("!=", Char_Type, &vector_neqs, Vector_Type, Vector_Type);

static define vector_string (a)
{
   if (_NARGS != 1)
     failed ("__add_string: _NARGS!=1");
   sprintf ("[%S,%S,%S]", a.x, a.y, a.z);
}
__add_string (Vector_Type, &vector_string);

static variable X = vector (1,2,3);

if (not vector_eqs (-X, vector_chs (X)))
  failed ("Vector chs(X)");

if (sqr(X) != vector_sqr(X))
  failed ("Vector sqr(X)");

if (abs(X) != vector_abs(X))
  failed ("Vector abs(X)");

if (vector_string (X) != string (X))
  failed ("Vector string(X)");


% test binary
static variable Y = vector (4, 5, 6);

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

static define test_duplicate_fields (fields, isok)
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
   

print ("Ok\n");
exit (0);

