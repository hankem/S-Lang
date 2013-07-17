() = evalfile ("./test.sl");
require ("histogram");

private variable Random_Number = _time ();
private define urand_1 (x)
{
   Random_Number = typecast (Random_Number * 69069UL + 1013904243UL, UInt32_Type);
   return Random_Number/4294967296.0;
}
private define urand (n)
{
   if (n == 0)
     return Double_Type[0];

   return array_map (Double_Type, &urand_1, [1:n]);
}

define test_hist1d (n, m)
{
   variable pts = urand (n); pts = pts[array_sort(pts)];
   variable edges = [1:m]/(1.1*m);
   variable max_edges;
   variable rev_indices;

   variable h = hist1d (pts, edges, &rev_indices);

   if (length (edges) == 0)
     {
	if (length (h) != 0)
	  failed ("hist1d(%S,%S): hist1d returned wrong size histogram");

	if (length (rev_indices) != 0)
	  failed ("hist1d(%S,%S): hist1d returned wrong size rev-ind array");

	return;
     }

   max_edges = max(edges);
   variable len = length (where (pts >= max_edges));
   if (len != h[-1])
     failed ("hist1d(%S,%S); last bin: expect %d, found %d",
	     n, m, len, h[-1]);

   len = length (where (pts < edges[0]));
   if (len + sum (h) != length (pts))
     failed ("hist1d: total number expect is wrong");

   _for (0, m-1, 1)
     {
	variable i = ();
	variable j = rev_indices[i];

	!if (length (j))
	  continue;

	if (length (where ((j < 0) or (j >= n))))
	  failed ("hist1d: reverse index out of range");

	variable p = pts[j];

	if (length (where (p < edges[i])))
	  failed ("hist1d: reverse index problem 2");

	if (i != m-1)
	  {
	     if (length (where (p >= edges[i+1])))
	       failed ("hist1d: reverse index problem 2");
	  }
     }
}

define test_hist1d_uc (n, edges)
{
   variable pts = typecast (256 * urand (n), UChar_Type);
   variable rev_indices;

   variable h1 = hist1d (pts, edges, &rev_indices);
   variable h2 = hist1d (pts, edges);

   if (length (where (h1 != h2)))
     failed ("hist1d on unsigned chars");
}

define do_test_hist1d (n, m)
{
   test_hist1d (n, m);
   test_hist1d_uc (n, [-3:0]);
   test_hist1d_uc (n*10, [-3,0.01]);
   test_hist1d_uc (n*10, [-3:10]);
   test_hist1d_uc (n*10, [-3:10:0.1]);
   test_hist1d_uc (n*10, [0:254]);
   test_hist1d_uc (n*10, [0:254:0.1]);
   test_hist1d_uc (n*10, [0:255]);
   test_hist1d_uc (n*10, [0:256]);
   test_hist1d_uc (n*10, [-1,256]);
   test_hist1d_uc (n*10, [255,256]);
   test_hist1d_uc (n*10, [255:256:0.1]);
   test_hist1d_uc (n*10, [255.1:270]);
   test_hist1d_uc (n*10, [256:270]);
   test_hist1d_uc (n*10, [254.9,255.0]);
   test_hist1d_uc (n*10, [254.9,255.01]);
}

define test_hist2d (num, nr, nc) %{{{
{
   variable r = urand(num);
   variable c = urand(num);

   variable gr, gc;
   gr = [1:nr]/(1.1*nr);
   gc = [1:nc]/(1.1*nc);

   variable rev, img;
   img = hist2d (r, c, gr, gc, &rev);

   % all data points got binned
   variable i = where ((r >= gr[0]) and (c >= gc[0]));
   if (sum(img) != length(i))
     failed ("histogram sum");

   % the reverse indices include every point
   _for (0, nr-1, 1)
     {
	variable ir = ();
	variable rlo, rhi;
	rlo = gr[ir];
	if (ir == nr-1)
	  rhi = 10;
	else
	  rhi = gr[ir+1];

	_for (0, nc-1, 1)
	  {
	     variable ic = ();
	     variable clo, chi;

	     i = rev[ir, ic];
	     if (0 == length (i))
	       continue;

	     clo = gc[ic];
	     if (ic == nc-1)
	       chi = 10;
	     else
	       chi = gc[ic+1];

	     if (length (where ((rlo > r[i]) or (r[i] >= rhi)
				or (clo > c[i]) or (c[i] >= chi))))
	       failed ("hist2d: Reverse index problem");
	  }
     }
}

do_test_hist1d (20, 5);
do_test_hist1d (20, 4);
do_test_hist1d (20, 3);
do_test_hist1d (20, 2);
do_test_hist1d (20, 1);

do_test_hist1d (20, 500);
do_test_hist1d (20, 400);
do_test_hist1d (20, 300);
do_test_hist1d (20, 200);
do_test_hist1d (20, 100);

% Now test oddball cases

do_test_hist1d (0, 5);
do_test_hist1d (1, 5);
do_test_hist1d (0, 1);
do_test_hist1d (0, 0);

test_hist2d (20, 1, 1);
test_hist2d (200, 1, 3);
test_hist2d (20, 10, 20);
test_hist2d (20, 10, 30);
test_hist2d (20000, 10, 30);

private variable Test_Number = 0;
private define test_rebin (new_grid, old_grid, input_h, sum_ok, expected)
{
   variable new_h = hist1d_rebin (new_grid, old_grid, input_h);

   Test_Number++;

   if (sum_ok)
     {
	if (sum (new_h) != sum (input_h))
	  failed ("hist1d_rebin[%d]: sum: %S != %S",
		  Test_Number, sum(new_h), sum(input_h));
     }
   if (expected != NULL)
     {
	variable i = where (expected != new_h);
	if (length (i))
	  {
	     i = i[0];
	     failed ("hist1d_rebin[%d]: expected %S in bin %d, found %S (diff=%S)",
		     Test_Number, expected[i], i, new_h[i], expected[i] - new_h[i]);
	  }
     }
}

private define test_module (module_name)
{
   testing_module (module_name);

   variable g0 = [0,1,2,3,4,5,6];
   variable h0 = [1,2,3,4,5,6,7];

%test_rebin ([0,1], [0], [1], 1, [0.5, 0.5]);

   test_rebin ([0,2,4,6], g0, h0, 1, [3,7,11,7]);
   test_rebin ([0,2,4], g0, h0, 1, [3,7,18]);
   test_rebin ([0], g0, h0, 1, [28]);
   test_rebin ([-1], g0, h0, 1, [28]);
   test_rebin ([-1,0], g0, h0, 1, [0,28]);
   test_rebin ([-1,0,6,7,8], g0, h0, 1, [0,21,0,0,7]);
   test_rebin ([-1,0,0.5,7,8], g0, h0, 1, [0,0.5, 20.5,0,7]);
   test_rebin ([1.5,2.5], g0, h0, 0, [2.5,23.5]);
   test_rebin ([8], g0, h0, 0, [7]);
   test_rebin ([-1,9], g0, h0, 1, [21, 7]);
   test_rebin ([1,10], [-4], [12], 1, [0, 12]);
   test_rebin (Double_Type[0], g0, h0, 0, Double_Type[0]);
   test_rebin ([1:10], [1,5,10], [1,2,3], 1,
	       [0.25,0.25,0.25,0.25,0.4,0.4,0.4,0.4,0.4,3]);
}

define slsh_main ()
{
   test_module ("hist");
   end_test ();
}
