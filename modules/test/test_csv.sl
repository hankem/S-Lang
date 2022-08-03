() = evalfile ("./test.sl");
require ("csv");

private variable Table = struct {author = {}, title = {}, sample = {}};

private define add_entry (author, title, sample)
{
   list_append (Table.author, author);
   list_append (Table.title, title);
   list_append (Table.sample, sample);
}

add_entry ("Poe, Edgar Allan", "The Raven", "\
Once upon a midnight dreary, while I pondered weak and weary,\n\
Over many a quaint and curious volume of forgotten lore,\n\
While I nodded, nearly napping, suddenly there came a tapping,\n\
As of some one gently rapping, rapping at my chamber door.\n\
\"Tis some visitor,\" I muttered, tapping at my chamber door -\n\
Only this, and nothing more.");

add_entry ("Frost, Robert", "Mending Wall", "\
He moves in darkness as it seems to me,\n\
Not of woods only and the shade of trees.\n\
He will not go behind his father's saying,\n\
And he likes having thought of it so well\n\
He says again, \"Good fences make good neighbors.\"");

private define test_csv (file)
{
   variable names = get_struct_field_names (Table);

   variable table = csv_readcol (file; has_header, init_size=1);
   if (any(names != get_struct_field_names (table)))
     {
	failed ("1: csv_read/write failed to produce a table with the expected column names");
	return;
     }
   foreach (names)
     {
	variable name = ();
	ifnot (_eqs(get_struct_field (table, name), get_struct_field (table, name)))
	  {
	     failed ("1: column %S entries are not equal", name);
	     return;
	  }
     }

   if (typeof(file) == File_Type)
     {
	clearerr (file);
	() = fseek (file, 0, SEEK_SET);
     }

   table = csv_readcol (file, 1, 3; has_header);
   if (any(names[[1,3]-1] != get_struct_field_names (table)))
     {
	failed ("2: csv_read/write failed to produce a table with the expected column names");
	return;
     }
   foreach (get_struct_field_names (table))
     {
	name = ();
	ifnot (_eqs(get_struct_field (table, name), get_struct_field (table, name)))
	  {
	     failed ("2: column %S entries are not equal", name);
	     return;
	  }
     }

   if (typeof(file) == File_Type)
     {
	clearerr (file);
	() = fseek (file, 0, SEEK_SET);
     }
   table = csv_readcol (file, names[2], names[0]; has_header);
   if (any(names[[2,0]] != get_struct_field_names (table)))
     {
	failed ("3: csv_read/write failed to produce a table with the expected column names");
	return;
     }
   foreach (get_struct_field_names (table))
     {
	name = ();
	ifnot (_eqs(get_struct_field (table, name), get_struct_field (table, name)))
	  {
	     failed ("3: column %S entries are not equal", name);
	     return;
	  }
     }
}

private define test_empty_file (file)
{
   variable s = struct
     {
	col1name = String_Type[0], col2name = Int_Type [0], col3name = Float_Type[0],
     };
   csv_writecol (file, s);
   variable s1 = csv_readcol (file; has_header, type2='i', type3='f');

   ifnot (_eqs(s, s1))
     {
	failed ("csv_read/writecol for a file with no rows");
     }

   () = open (file, O_WRONLY|O_TRUNC);
   s1 = csv_readcol (file; header=get_struct_field_names(s), type="sif");
   ifnot (_eqs(s, s1))
     {
	failed ("csv_read/writecol for empty file failed");
     }

}

private define test_embedded_cr (file)
{
   variable fp = fopen (file, "w");
   variable f0 = "ABC\rDEF", f1 = `quot\r,ed"`, f2 = "\rXYZ";
   () = fprintf (fp, "%S,\"%S\"\",%S\n", f0, f1, f2);
   () = fclose (fp);
   variable s = csv_readcol (file);
   if (3 != length (get_struct_field_names (s)))
     {
	failed ("test_embedded_cr: wrong num fields");
     }
   if ((s.col1[0] != f0) || (s.col2[0] != f1) || (s.col3[0] != f2))
     {
	failed ("test_embedded_cr: column values do not match");
     }
}


private define test_embedded_comments (file)
{
   variable fp = fopen (file, "w");
   () = fputs (`
#comment line
name
"Value
#1"
#another comment
Value #2
`,
	       fp);
   () = fclose (fp);
   variable s = csv_readcol (file; has_header, comment="#");
   if (length (s.name) != 2)
     failed ("test_embedded_comments: expected 2 rows");
   if (s.name[0] != "Value\n#1")
     failed ("test_embedded_comments: value 1 incorrect");
   if (s.name[1] != "Value #2")
     failed ("test_embedded_comments: value 2 incorrect");
}

private define test_rdb (file)
{
   variable n = 10;
   variable x = [0:2*PI:#n];
   variable s0 = struct
     {
	idx = [1:n], x = x, sinx = sin(x), fsinx,
     };
   variable fsinx = typecast (s0.sinx, Float_Type);
   s0.fsinx = fsinx;

   csv_writecol (file, s0; rdb);
   variable s1 = csv_readcol (file; rdb, type4='f');
   ifnot (_eqs (s0, s1))
     {
	failed ("rdb 1");
     }

   s1 = csv_readcol (file; rdb, type='A', type4='f');
   ifnot (_eqs (s0, s1))
     {
	failed ("rdb 2");
     }
}


define slsh_main ()
{
   testing_module ("csv");

   variable file = sprintf ("/tmp/testcsv-%ld.csv", _time() mod getpid());
   csv_writecol (file, Table);
   test_csv (file);
   test_csv (fopen (file, "r"));
   test_csv (fgetslines (fopen (file, "r")));
   test_empty_file (file);
   test_embedded_comments (file);
   test_embedded_cr (file);
   test_rdb (file);
   () = remove (file);
   end_test ();
}
