prepend_to_slang_load_path (".");
set_import_module_path ("./${ARCH}objs:"$+get_import_module_path ());
require ("stats.sl");

private define test_chisqr_test ()
{
   % This example comes from Conover, 1980, section 4.2
   variable nfailed = 0;
   variable x = [6, 14, 17, 9];
   variable y = [30, 32, 17, 3];
   variable t, p;
   p = chisqr_test (x, y, &t);
   if (abs(t - 17.3) > 0.1)
     {
	nfailed++;
	() = fprintf (stderr, "chisqr_test: Expected 17.3, got t=%S\n", t);
     }
   x = [13, 73];
   y = [17, 57];
   p = chisqr_test (x, y, &t);
   if (abs(t - 1.61) > 0.01)
     {
	nfailed++;
	() = fprintf (stderr, "chisqr_test: Expected 1.61, got t=%S\n", t);
     }
   % Conover 1980, example 2, pg 159.  EXCEPT: Conover has 1.55 for the
   % statistic, but an explicit calculation yields 1.524...  Is this a
   % misprint?
   p = chisqr_test ([16,14.], [14,6.], [13,10.], [13,8.], &t);
   if (abs(t - 1.524) > 0.01)
     {
	nfailed++;
	() = fprintf (stderr, "chisqr_test: Expected 1.524, got t=%S\n", t);
     }
   return nfailed;
}

private define test_f ()
{
   variable nfailed = 0;
   variable x, y, s, p;
   variable s0, p0;
   %variable x = [41, 34, 33, 36, 40, 25, 31, 37, 34, 30, 38];
   %variable y = [52, 57, 62, 55, 64, 57, 56, 55];

   % This test comes from the Gnumeric documentation for the f-test
   x = [68.5, 83, 83, 66.5, 58.1, 82.4];
   y = [81.5, 85.2, 87.1, 69.3, 73.5, 65.5, 73.4, 56.1];

   %vmessage("stddev x/y = %g", stddev(x)/stddev(y));
   p = f_test2 (x, y, &s);
   p0 = 0.920666, s0 = 1.039706;
   ifnot (feqs (p,p0) || feqs (s,s0))
     {
	nfailed++;
	() = fprintf (stderr, "f_test2 test 1 failed\n");
     }

   p = f_test2 (x, y, &s; side=">");
   p0 = 0.53667;
   ifnot (feqs (p,p0))
     {
	nfailed++;
	() = fprintf (stderr, "f_test2 size=> failed: expected %g, got %g\n", p0, p);
     }

   p = f_test2 (x, y, &s; side="<");
   p0 = 0.46333;
   ifnot (feqs (p,p0))
     {
	nfailed++;
	() = fprintf (stderr, "f_test2 side=< failed: expected %g, got %g\n", p0, p);
     }
   return nfailed;
}

private define test_kendall ()
{
   variable nfailed = 0;
   variable x, y, p, s, cdf;
   variable expected_s, expected_p;

   % Example from Higgins 2004 based upon table 5.3.1
   x = [68, 70, 71, 72];
   y = [153, 155, 140, 180];
   p = kendall_tau (x, y, &s);
   expected_p = 0.375;
   expected_s = 0.33;
   if (not feqs (s, expected_s, 0, 0.01))
     {
	() = fprintf (stderr, "*** kendall_tau statistic: %g, expected %g\n",
		      s, expected_s);
	nfailed++;
     }
#iffalse
   % Before this can be used, I need to implement the exact probability.
   if (not feqs (p, expected_p))
     {
	() = fprintf (stderr, "*** kendall_tau pval= %g, expected %g\n",
		     p, expected_p);
	nfailed++;
     }
#endif

   % Higgins 2004 example 5.3.1
   % Rabbit data (table 5.2.1)
   x = [6,16,8,18,17,4,3,1,5,7,15,2,13,12,10,11,14,9];
   y = [5,17,6,18,14,8,2,1,7,3,15,4,16,13,12,10,9,11];

   p = kendall_tau (x, y, &s);
   expected_p = 0.0;
   expected_s = 0.73;
   if (not feqs (s, expected_s, 0, 0.01))
     {
	() = fprintf (stderr, "*** kendall_tau statistic: %g, expected %g\n",
		      s, expected_s);
	nfailed++;
     }
   if (not feqs (p, expected_p, 0, 1e-4))
     {
	() = fprintf (stderr, "*** kendall_tau pval= %g, expected %g\n",
		     p, expected_p);
	nfailed++;
     }
   return nfailed;
}

private define test_ks ()
{
   variable nfailed = 0;
   variable x, y, p, s, cdf;
   variable expected_s, expected_p;

   % Example 6.1-1 from Conover 1980
   x = [0.621, 0.503, 0.203, 0.477, 0.710,
	0.581, 0.329, 0.480, 0.554, 0.382];
   cdf = x;			       %  uniform distribtion
   p = ks_test (x, &s);
   expected_s = 0.29;
   if (not feqs (s, expected_s))
     {
	() = fprintf (stderr, "*** ks_test statistic: %g, expected %g\n",
		      s, expected_s);
	nfailed++;
     }

   % Example 5.4 in Hollander-Wolfe 1999
   x = [-0.15, 8.6, 5, 3.71, 4.29, 7.74, 2.48, 3.25, -1.15, 8.38];
   y = [2.55, 12.07, 0.46, 0.35, 2.69, -0.94, 1.73, 0.73, -0.35, -0.37];
   expected_p = 0.0524;
   p = ks_test2 (x,y, &s);
   if (not feqs (p, 0.0524))
     {
	() = fprintf (stderr, "*** ks_test2 pval=: %g, expected %g\n");
	nfailed++;
     }
   return nfailed;
}

private define test_mw_cdf (N)
{
   variable nfailed = 0;
   variable n;
   _for n (1, N-1, 1)
     {
	variable m = N-n;
	variable rmin = (n*(n+1))/2, rmax = m*n + rmin;
	variable r, lastp = 0, p;
	_for r (rmin, rmax, 1)
	  {
	     p = mann_whitney_cdf (n, m, r);
	     if (lastp > p)
	       () = fprintf (stderr, "mann_whitney_cdf(%d,%d,%g) to be increasing\n",
			     n, m, r);
	  }
	ifnot (feqs (p, 1.0, 0.0001))
	  {
	     () = fprintf (stderr, "mann_whitney_cdf (%d, %d, [%d:%d]) failed: s=%g\n",
			   n, m, rmin, rmax,p);
	  }
     }
   return nfailed;
}

private define test_mw_test ()
{
   variable nfailed = 0;
   variable w, ew;
   variable x, y, p, ep;

   % Example 4.1 from Hollander and Wolfe (2nd Edition)
   x = [0.8, 0.83, 1.89, 1.04, 1.45, 1.38, 1.91, 1.64, 0.73, 1.46];
   y = [1.15, 0.88, 0.9, 0.74, 1.21];

   p = mw_test (y, x, &w);
   ifnot (feqs(w, 30))
     {
	nfailed++;
	vmessage ("mw_test 1 returned %S, expected 30", w);
     }

   % Example 2.4.2 Higgins 2004 (Strawberry plants)
   x = [0.55, 0.67, 0.63, 0.79, 0.81, 0.85, 0.68];   %  treated
   y = [0.65, 0.59, 0.44, 0.60, 0.47, 0.58, 0.66, 0.52, 0.51];    %  untreated
   % H0: E(x)<=E(y)
   ew = 84;
   ep = 0.0039;
   p = mw_test (x, y, &w; side=">");
   if (w != ew)
     {
	nfailed++;
	() = fprintf (stderr, "mw_test 2 returned %S, expected %S\n", w, ew);
     }
   ifnot (feqs (p, ep))
     {
	nfailed++;
	() = fprintf (stderr, "mw_test 2 returned pval=%g, expected %g\n", p, ep);
     }

   % Example 2.4.1 (Higgins 2004)
   x = [37,49,55,57];		       %  new
   y = [23,31,46];		       %  traditional
   % H0: E(x)<=E(y)
   p = mw_test (x,y, &w; side=">");
   ew = 21;
   ep = 0.0571;
   if (w != ew)
     {
	nfailed++;
	() = fprintf (stderr, "mw_test 3 returned %S, expected %S\n", w, ew);
     }
   ifnot (feqs (p, ep))
     {
	nfailed++;
	() = fprintf (stderr, "mw_test 3 returned pval=%g, expected %g\n", p, ep);
     }

   % Example 2.6.1 Higgins
   x = [3.6, 3.9, 4.0, 4.3];	       %  brand1
   y = [3.8, 4.1, 4.5, 4.8];	       %  brand2
   p = mw_test (x, y, &w);
   ew = 1+3+4+6;
   ep = 0.1714*2;
   if (w != ew)
     {
	nfailed++;
	() = fprintf (stderr, "mw_test 4 returned %S, expected %S\n", w, ew);
     }
   ifnot (feqs (p, ep))
     {
	nfailed++;
	() = fprintf (stderr, "mw_test 4 returned pval=%g, expected %g\n", p, ep);
     }

   % Conover 1980, section 5.1 example 1
   x = [14.8,7.3,5.6,6.3,9.0,4.2,10.6,12.5,12.9,16.1,11.4,2.7];
   y = [12.7,14.2,12.6,2.1,17.7,11.8,16.9,7.9,16.0,10.6,5.6,5.6,7.6,11.3,8.3,
	6.7,3.6,1.0,2.4,6.4,9.1,6.7,18.6,3.2,6.2,6.1,15.3,10.6,1.8,5.9,9.9,
	10.6,14.8,5.0,2.6,4.0];
   ew = 321; ep = 0.26;
   p = mw_test (x, y, &w; side=">");
   if (w != ew)
     {
	nfailed++;
	() = fprintf (stderr, "mw_test 5 returned %S, expected %S\n", w, ew);
     }
   ifnot (feqs (p, ep))
     {
	nfailed++;
	() = fprintf (stderr, "mw_test 5 returned pval=%g, expected %g\n", p, ep);
     }
   return nfailed;
}

private define test_spearman ()
{
   variable nfailed = 0;
   variable x, y, p, s, cdf;
   variable expected_s, expected_p;

   % Higgins 2004 example 5.2.1
   % Rabbit data (table 5.2.1)
   x = [6,16,8,18,17,4,3,1,5,7,15,2,13,12,10,11,14,9];
   y = [5,17,6,18,14,8,2,1,7,3,15,4,16,13,12,10,9,11];

   p = spearman_r (x, y, &s);
   expected_p = 0;
   expected_s = 0.897;
   if (not feqs (s, expected_s))
     {
	() = fprintf (stderr, "*** spearman_r statistic: %g, expected %g\n",
		      s, expected_s);
	nfailed++;
     }
   if (not feqs (p, expected_p))
     {
	() = fprintf (stderr, "*** spearman_r pval= %g, expected %g\n",
		     p, expected_p);
	nfailed++;
     }

   % Higgins 2004 example 5.2.3
   x = [8,8,7,8,5,6,6,9,8,7];
   y = [7,8,8,5,6,4,5,8,6,9];
   p = spearman_r (x, y, &s);
   expected_p = 0.2832;
   expected_s = 0.375;
   if (not feqs (s, expected_s))
     {
	() = fprintf (stderr, "*** spearman_r statistic: %g, expected %g\n",
		      s, expected_s);
	nfailed++;
     }
   if (not feqs (p, expected_p))
     {
	() = fprintf (stderr, "*** spearman_r pval= %g, expected %g\n",
		     p, expected_p);
	nfailed++;
     }
   return nfailed;
}

private variable XData = [
-0.15, %1
 8.60, %9
 5.00, %6
 3.71, %4
 4.29, %5
 7.74, %7
 2.48, %2
 3.25, %3
-1.15, %0
 8.38  %8
];
private variable YData = [
 2.55,
12.07,
 0.46,
 0.35,
 2.69,
-0.94,
 1.73,
 0.73,
-0.35,
-0.37
];

private define test_mean_stddev ()
{
   variable nfailed = 0;
   ifnot (feqs (sum(XData)/length(XData), mean(XData), 1e-6))
     {
	() = fprintf (stderr, "test_mean_stddev: mean failed\n");
	nfailed++;
     }

   variable n = length(XData);
   if (0 == (n & 0x1))
     n--;

   variable x1 = XData[array_sort(XData)][n/2];
   variable x2 = median (XData);
   if (x1 != x2)
     {
	() = fprintf (stderr, "median, found %g, expected %g\n", x2, x1);
	nfailed++;
     }

   x1 = stddev (XData);
   x2 = sqrt(sum((XData-mean(XData))^2)/(length(XData)-1));
   ifnot (feqs (x1, x2, 1e-6))
     {
	() = fprintf (stderr, "stddev, found %g, expected %g\n", x1, x2);
	nfailed++;
     }
   return nfailed;
}

private define wikipedia_sample_skewness (x)
{
   variable n = length(x)*1.0;
   variable xbar = sum(x)/n;
   variable dx = x-xbar;
   return sqrt(n)*sum(dx*dx*dx)/sum(dx*dx)^1.5;
}

private define wikipedia_sample_kurtosis (x)
{
   variable n = length(x)*1.0;
   variable xbar = sum(x)/n;
   variable dx = x-xbar;
   return (n*sum(dx^4))/sum(dx*dx)^2 - 3;
}

define test_skewness_kurtosis ()
{
   variable nfailed = 0;
   variable w = wikipedia_sample_skewness (XData);
   variable s = skewness (XData);
   ifnot (feqs (w,s,1e-6))
     () = fprintf (stderr, "Expected skewness = %g, found %g\n", w, s);

   w = wikipedia_sample_kurtosis (XData);
   s = kurtosis (XData);
   ifnot (feqs (w,s,1e-6))
     () = fprintf (stderr, "Expected kurtosis = %g, found %g\n", w, s);
   return nfailed;
}

private define test_binomial ()
{
   variable nfailed = 0;
   variable expected = [1, 4, 6, 4, 1];
   variable m, n = 4;
   variable ans = binomial (n);
   ifnot (_eqs (expected, ans))
     {
	() = fprintf (stderr, "binomial(4) produced an incorrect result\n");
	nfailed++;
     }
   _for m (0, n, 1)
     {
	if (binomial(n,m) != expected[m])
	  {
	     () = fprintf (stderr, "Incorrect value for binomial(%d,%d)\n", n, m);
	     nfailed++;
	  }
     }
   return nfailed;
}

private define test_student_t ()
{
   variable nfailed = 0;
   variable x, y, p, t, p0, t0;

   x = [35,40,12,15,21,14,46,10,28,48,
	16,30,32,48,31,22,12,39,19,25];
   y = [ 2,27,38,31, 1,19, 1,34, 3, 1,
	 2, 3, 2, 1, 2, 1, 3,29,37, 2];
   t0 = 3.54;
   p0 = 0.0011;	  %  computed by http://www.graphpad.com/quickcalcs/ttest2.cfm

   p = t_test2 (x, y, &t);
   ifnot ((feqs (p,p0)) || feqs (t,t0))
     {
	nfailed++;
	() = fprintf (stderr, "t_test2 failed:\n");
	() = fprintf (stderr, " p = %S, p0 = %S, t = %g, t0 = %g\n",
				p, p0, t, t0);
     }

   x = [10,20,50,57,32,12,6,17,9,11];
   t0 = 1.3328;
   p0 = 0.2153;	  %  computed by http://www.graphpad.com/quickcalcs/
   p = t_test (x, 30, &t);
   ifnot ((feqs (p,p0)) || feqs (t,t0))
     {
	nfailed++;
	() = fprintf (stderr, "t_test 1 failed:\n");
	() = fprintf (stderr, " p = %S, p0 = %S, t = %g, t0 = %g\n",
				p, p0, t, t0);
     }

   t0 = 1.3328;
   p0 = 0.0033;	  %  computed by http://www.graphpad.com/quickcalcs/
   p = t_test (x, 45, &t);
   ifnot ((feqs (p,p0)) || feqs (t,t0))
     {
	nfailed++;
	() = fprintf (stderr, "t_test 2 failed:\n");
	() = fprintf (stderr, " p = %S, p0 = %S, t = %g, t0 = %g\n",
				p, p0, t, t0);
     }
   return nfailed;
}

define slsh_main ()
{
   variable nfailed, total_failed = 0;

   nfailed = test_mean_stddev ();
   if (nfailed)
     () = fprintf (stdout, "testing mean/stddev: %d failures\n", nfailed);
   total_failed += nfailed;

   nfailed = test_chisqr_test ();
   if (nfailed)
     () = fprintf (stderr, "testing Chi-square: %d failures\n", nfailed);
   total_failed += nfailed;

   nfailed = test_f ();
   if (nfailed)
     () = fprintf (stdout, "testing F tests: %d failures\n", nfailed);
   total_failed += nfailed;

   nfailed = test_kendall ();
   if (nfailed)
     () = fprintf (stdout, "testing Kendall tau: %d failures\n", nfailed);
   total_failed += nfailed;

   nfailed = test_ks ();
   if (nfailed)
     () = fprintf (stdout, "testing K-S: %d failures\n", nfailed);
   total_failed += nfailed;

   nfailed = test_mw_cdf (2);
   nfailed += test_mw_cdf (3);
   nfailed += test_mw_cdf (10);
   nfailed += test_mw_cdf (21);

   nfailed += test_mw_test ();
   if (nfailed)
     () = fprintf (stdout, "testing Mann-Whitney: %d failures\n", nfailed);
   total_failed += nfailed;

   nfailed = test_spearman ();
   if (nfailed)
     () = fprintf (stdout, "testing spearman r: %d failures\n", nfailed);
   total_failed += nfailed;

   nfailed = test_binomial ();
   if (nfailed)
     () = fprintf (stdout, "testing basic statistical functions: %d failures\n", nfailed);
   total_failed += nfailed;

   nfailed = test_student_t ();
   if (nfailed)
     () = fprintf (stdout, "testing Student t_tests: %d failures\n", nfailed);
   total_failed += nfailed;

   exit (total_failed > 0);
}


