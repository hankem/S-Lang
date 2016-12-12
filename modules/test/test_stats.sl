() = evalfile("./test.sl");
require ("stats.sl");

private define test_chisqr_test ()
{
   % This example comes from Conover, 1980, section 4.2
   variable x = [6, 14, 17, 9];
   variable y = [30, 32, 17, 3];
   variable t, p;
   p = chisqr_test (x, y, &t);
   if (abs(t - 17.3) > 0.1)
     failed ("chisqr_test: Expected 17.3, got t=%S", t);
   x = [13, 73];
   y = [17, 57];
   p = chisqr_test (x, y, &t);
   if (abs(t - 1.61) > 0.01)
     failed ("chisqr_test: Expected 1.61, got t=%S", t);
   % Conover 1980, example 2, pg 159.  EXCEPT: Conover has 1.55 for the
   % statistic, but an explicit calculation yields 1.524...  Is this a
   % misprint?
   p = chisqr_test ([16,14.], [14,6.], [13,10.], [13,8.], &t);
   if (abs(t - 1.524) > 0.01)
     failed ("chisqr_test: Expected 1.524, got t=%S", t);
}

private define test_f ()
{
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
     failed ("f_test2 test 1 failed");

   p = f_test2 (x, y, &s; side=">");
   p0 = 0.53667;
   ifnot (feqs (p,p0))
     failed ("f_test2 size=> failed: expected %g, got %g", p0, p);

   p = f_test2 (x, y, &s; side="<");
   p0 = 0.46333;
   ifnot (feqs (p,p0))
     failed ("f_test2 side=< failed: expected %g, got %g", p0, p);
}

private define map_cdf_to_pval (cdf)
{
   variable side = qualifier ("side", NULL);

   variable pval = cdf;		       %  side="<"
   if (side == ">")
     pval = 1.0 - cdf;
   else if (side != "<")	       %  double-sided
     pval = 2.0 * _min (1.0-pval, pval);

   return pval;
}

private define nsqr_kendall_tau (x, y, w_ref)
{
   variable n = length (x);
   if (n != length (y))
     throw InvalidParmError, "Arrays must be the same length for nsqr_kendall_tau";

   variable i;
   variable nx = 0.0, ny = 0.0, diff=0.0;
   _for i (0, n-2, 1)
     {
	variable j = [i+1:n-1];
	variable dx = sign(x[i] - x[j]);
	variable dy = sign(y[i] - y[j]);
	nx += sum(abs(dx));
	ny += sum(abs(dy));
	diff += sum (dx*dy);	       %  concordant - discordant
     }

   variable tau = diff/(sqrt(nx)*sqrt(ny));

   @w_ref = tau;

   variable sigma = sqrt((4.0*n+10.0)/(9.0*n*(n-1)));
   return map_cdf_to_pval (normal_cdf(tau/sigma) ;; __qualifiers);
}

private define run_kendall_test (x, y, ep, es)
{
   variable p, s;

   p = kendall_tau (x, y, &s);
   ifnot (feqs (s, es, 0, 0.01))
     failed ("*** kendall_tau statistic: %g, expected %g", s, es);
   ifnot (feqs (p, ep, 0, 0.02))
     failed ("*** kendall_tau pvalue: %g, expected %g", p, ep);
   %vmessage ("s=%S, expected_s=%S", s, es);
   %vmessage ("p=%S, expected_p=%S", p, ep);
}

private define test_kendall_tau ()
{
   variable x, y, p, s, cdf;
   variable expected_s, expected_p;

   % IDL R_CORRELATE example
   x = [257, 208, 296, 324, 240, 246, 267, 311, 324, 323, 263,
	305, 270, 260, 251, 275, 288, 242, 304, 267];
   y = [201, 56, 185, 221, 165, 161, 182, 239, 278, 243, 197,
	271, 214, 216, 175, 192, 208, 150, 281, 196];
   expected_p = 0.000118729;
   expected_s = 0.624347;
   run_kendall_test (x, y, expected_p, expected_s);

   % From Armitage and Berry (1994, p. 466) via statsdirect.com 
   x = [4,10,3,1,9,2,6,7,8,5];
   y = [5,8,6,2,10,3,9,4,7,1];
   expected_p = 0.0466;
   expected_s = 0.5111;
   run_kendall_test (x, y, expected_p, expected_s);

   % Wine example from Herve Abdi in Encyclopedia of Measurement and
   % Statistics (2007)
   x = [1,3,2,4];
   y = [1,4,2,3];
   expected_p = 2*(1.0/6);
   expected_s = 2.0/3.0;
   run_kendall_test (x, y, expected_p, expected_s);

   % Example from Higgins 2004 based upon table 5.3.1
   x = [68, 70, 71, 72];
   y = [153, 155, 140, 180];
   expected_p = 2 * 0.375;	       %  2-sided
   expected_s = 0.33;
   run_kendall_test (x, y, expected_p, expected_s);

   % Problem 4.3 from Higgins
   x = [3,7,15,24,85,180,360];
   y = [2500,3200,4300,5300,5900,6700,6900];
   expected_p = 2.0/5040.0;
   expected_s = 1;
   run_kendall_test (x, y, expected_p, expected_s);

   % Higgins 2004 example 5.3.1
   % Rabbit data (table 5.2.1)
   x = [6,16,8,18,17,4,3,1,5,7,15,2,13,12,10,11,14,9];
   y = [5,17,6,18,14,8,2,1,7,3,15,4,16,13,12,10,9,11];
   expected_p = 0.0;
   expected_s = 0.73;
   run_kendall_test (x, y, expected_p, expected_s);

   % Example 6.1 Gibbons & Chakraborti, 2003
   x = [1,5,9,7,4,6,8,2,3];
   y = [4,3,6,8,2,7,9,1,5];
   expected_p = 0.022 * 2;	       %  2-tailed
   expected_s = 40.0/72.0;
   run_kendall_test (x, y, expected_p, expected_s);

   % Data tested against www.wessa.net/rwasp_kendall.wasp
   x = [1,1,1,1,2,2,2,2,3,4,5,6,7,7,7,7];
   y = [1,1,1,2,1,2,2,2,3,5,4,7,6,7,7,7];
   expected_p = 4.49419021606445e-05;
   expected_s = 0.8529412150383;
   run_kendall_test (x, y, expected_p, expected_s);

   % scipy example (its p-value is wrong, so
   % www.wessa.net/rwasp_kendall.wasp value is used below)
   x = [12, 2, 1, 12, 2];
   y = [1, 4, 7, 1, 0];
   expected_p = 0.420456647872925; % scipy: 0.24821309157521476;
   expected_s = -0.47140452079103173;
   run_kendall_test (x, y, expected_p, expected_s);

   % Data tested against www.wessa.net/rwasp_kendall.wasp
   x = [12,14,14,17,19,19,19,19,19,20,21,21,21,21,21,22,23,24,24,24,26,26,27];
   y = [11,4,4,2,0,0,0,0,0,0,4,0,4,0,0,0,0,4,0,0,0,0,0];
   expected_p = 0.0389842391014099;
   expected_s = -0.376201540231705;
   run_kendall_test (x, y, expected_p, expected_s);
}

private define test_ks ()
{
   variable x, y, p, s, cdf;
   variable expected_s, expected_p;

   % Example 6.1-1 from Conover 1980
   x = [0.621, 0.503, 0.203, 0.477, 0.710,
	0.581, 0.329, 0.480, 0.554, 0.382];
   cdf = x;			       %  uniform distribtion
   p = ks_test (x, &s);
   expected_s = 0.29;
   ifnot (feqs (s, expected_s))
     failed ("*** ks_test statistic: %g, expected %g", s, expected_s);

   % Example 5.4 in Hollander-Wolfe 1999
   x = [-0.15, 8.6, 5, 3.71, 4.29, 7.74, 2.48, 3.25, -1.15, 8.38];
   y = [2.55, 12.07, 0.46, 0.35, 2.69, -0.94, 1.73, 0.73, -0.35, -0.37];
   expected_p = 0.0524;
   p = ks_test2 (x,y, &s);
   ifnot (feqs (p, expected_p))
     failed ("*** ks_test2 pval=: %g, expected %g", p, expected_p);
}

private define test_mw_cdf (N)
{
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
	       failed ("mann_whitney_cdf(%d,%d,%g) to be increasing", n, m, r);
	  }
	ifnot (feqs (p, 1.0, 0.0001))
	  failed ("mann_whitney_cdf (%d, %d, [%d:%d]) failed: s=%g", n, m, rmin, rmax,p);
     }
}

private define test_mw_test ()
{
   variable w, ew;
   variable x, y, p, ep;

   % Example 4.1 from Hollander and Wolfe (2nd Edition)
   x = [0.8, 0.83, 1.89, 1.04, 1.45, 1.38, 1.91, 1.64, 0.73, 1.46];
   y = [1.15, 0.88, 0.9, 0.74, 1.21];

   p = mw_test (y, x, &w);
   ifnot (feqs(w, 30))
     failed ("mw_test 1 returned %S, expected 30", w);

   % Example 2.4.2 Higgins 2004 (Strawberry plants)
   x = [0.55, 0.67, 0.63, 0.79, 0.81, 0.85, 0.68];   %  treated
   y = [0.65, 0.59, 0.44, 0.60, 0.47, 0.58, 0.66, 0.52, 0.51];    %  untreated
   % H0: E(x)<=E(y)
   ew = 84;
   ep = 0.0039;
   p = mw_test (x, y, &w; side=">");
   if (w != ew)
     failed ("mw_test 2 returned %S, expected %S", w, ew);
   ifnot (feqs (p, ep))
     failed ("mw_test 2 returned pval=%g, expected %g", p, ep);

   % Example 2.4.1 (Higgins 2004)
   x = [37,49,55,57];		       %  new
   y = [23,31,46];		       %  traditional
   % H0: E(x)<=E(y)
   p = mw_test (x,y, &w; side=">");
   ew = 21;
   ep = 0.0571;
   if (w != ew)
     failed ("mw_test 3 returned %S, expected %S", w, ew);
   ifnot (feqs (p, ep))
     failed ("mw_test 3 returned pval=%g, expected %g", p, ep);

   % Example 2.6.1 Higgins
   x = [3.6, 3.9, 4.0, 4.3];	       %  brand1
   y = [3.8, 4.1, 4.5, 4.8];	       %  brand2
   p = mw_test (x, y, &w);
   ew = 1+3+4+6;
   ep = 0.1714*2;
   if (w != ew)
     failed ("mw_test 4 returned %S, expected %S", w, ew);
   ifnot (feqs (p, ep))
     failed ("mw_test 4 returned pval=%g, expected %g", p, ep);

   % Conover 1980, section 5.1 example 1
   x = [14.8,7.3,5.6,6.3,9.0,4.2,10.6,12.5,12.9,16.1,11.4,2.7];
   y = [12.7,14.2,12.6,2.1,17.7,11.8,16.9,7.9,16.0,10.6,5.6,5.6,7.6,11.3,8.3,
	6.7,3.6,1.0,2.4,6.4,9.1,6.7,18.6,3.2,6.2,6.1,15.3,10.6,1.8,5.9,9.9,
	10.6,14.8,5.0,2.6,4.0];
   ew = 321; ep = 0.26;
   p = mw_test (x, y, &w; side=">");
   if (w != ew)
     failed ("mw_test 5 returned %S, expected %S", w, ew);
   ifnot (feqs (p, ep))
     failed ("mw_test 5 returned pval=%g, expected %g", p, ep);
}

private define test_spearman ()
{
   variable x, y, p, s, cdf;
   variable expected_s, expected_p;

   % Higgins 2004 example 5.2.1
   % Rabbit data (table 5.2.1)
   x = [6,16,8,18,17,4,3,1,5,7,15,2,13,12,10,11,14,9];
   y = [5,17,6,18,14,8,2,1,7,3,15,4,16,13,12,10,9,11];

   p = spearman_r (x, y, &s);
   expected_p = 0;
   expected_s = 0.897;
   ifnot (feqs (s, expected_s))
     failed ("*** spearman_r statistic: %g, expected %g", s, expected_s);
   ifnot (feqs (p, expected_p))
     failed ("*** spearman_r pval= %g, expected %g", p, expected_p);

   % Higgins 2004 example 5.2.3
   x = [8,8,7,8,5,6,6,9,8,7];
   y = [7,8,8,5,6,4,5,8,6,9];
   p = spearman_r (x, y, &s);
   expected_p = 0.2832;
   expected_s = 0.375;
   ifnot (feqs (s, expected_s))
     failed ("*** spearman_r statistic: %g, expected %g", s, expected_s);
   ifnot (feqs (p, expected_p))
     failed ("*** spearman_r pval= %g, expected %g", p, expected_p);
}

private define check_pval_and_t (name, pv, t, pv_exp, t_exp)
{
   if (feqs (pv, pv_exp) && feqs (t, t_exp))
     return;

   failed ("%s: pv=%S!=%S, t=%S!=%S", name, pv, pv_exp, t, t_exp);
}

private define test_ad_ktest ()
{
   % This test is from Scholz & Stephens
   variable datasets =
     {
	[38.7, 41.5, 43.8, 44.5, 45.5, 46.0, 47.7, 58.0],
	[39.2, 39.3, 39.7, 41.4, 41.8, 42.9, 43.3, 45.8],
	[34.0, 35.0, 39.0, 40.0, 43.0, 43.0, 44.0, 45.0],
	[34.0, 34.8, 34.8, 35.4, 37.2, 37.8, 41.2, 42.8],
     };

   variable pval, t, pval2, t2;
   pval = ad_ktest (datasets, &t; pval2=&pval2, stat2=&t2);
   check_pval_and_t ("ad_ktest1", pval, t, 0.00219, 4.480);
   check_pval_and_t ("ad_ktest1", pval2, t2, 0.00227, 4.449);

   % This examples comes from
   % <http://tools.ietf.org/html/draft-ietf-ippm-testplan-rfc2680-02>
   datasets =
     {
	[114, 175, 138, 142, 181, 105],
	[115, 128, 136, 127, 139, 138],
     };
   pval = ad_ktest (datasets, &t; pval2=&pval2, stat2=&t2);
   check_pval_and_t ("ad_ktest2", pval, t, 0.18607, 0.62679);
   check_pval_and_t ("ad_ktest2", pval2, t2, 0.20604, 0.52043);

   % This example comes from kSamples.R package
   datasets =
     {
	[0.824, 0.216, 0.538, 0.685],
	[0.448, 0.348, 0.443, 0.722],
	[0.403, 0.268, 0.440, 0.087],
     };
   pval = ad_ktest (__push_list(datasets), &t; pval2=&pval2, stat2=&t2);
   check_pval_and_t ("ad_ktest3", pval, t, 0.193, 0.70807);
   check_pval_and_t ("ad_ktest3", pval2, t2, 0.190135, 0.72238);
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

private define test_mean_stddev (xdata)
{
   variable m0 = sum(1.0*xdata)/length(xdata);
   variable m1 = mean(xdata);
   ifnot (feqs (m0, m1, 1e-6, 1e-7))
     failed ("test_mean_stddev: mean failed: got %S, expected %S", m0, m1);

   variable n = length(xdata);
   if (0 == (n & 0x1))
     n--;

   variable x1 = xdata[array_sort(xdata)][n/2];
   variable x2 = median (xdata);
   if (x1 != x2)
     failed ("median %S: found %g, expected %g", xdata, x2, x1);
   x2 = median_nc (xdata);
   if (x1 != x2)
     failed ("median_nc %S: found %g, expected %g", xdata, x2, x1);

   x1 = stddev (xdata);
   x2 = sqrt(sum((xdata-mean(xdata))^2)/(length(xdata)-1));
   ifnot (feqs (x1, x2, 1e-6, 1e-7))
     failed ("stddev, found %g, expected %g", x1, x2);

   variable a = Double_Type [length(xdata), 3];
   a[*,0] = xdata; a[*,1] = xdata; a[*,2] = xdata;
   x2 = stddev (a, 0);
   if (length (x2) != 3)
     failed ("stddev(a,0): expected an array of 3, got %d", length (x2));
   ifnot (all (feqs(x2, x1, 1e-6, 1e-7)))
     {
	failed ("stddev(%S,0) produced incorrect values", a);
     }
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
   variable w = wikipedia_sample_skewness (XData);
   variable s = skewness (XData);
   ifnot (feqs (w,s,1e-6, 1e-7))
     failed ("Expected skewness = %g, found %g", w, s);

   w = wikipedia_sample_kurtosis (XData);
   s = kurtosis (XData);
   ifnot (feqs (w,s,1e-6, 1e-7))
     failed ("Expected kurtosis = %g, found %g", w, s);
}

private define test_binomial ()
{
   variable expected = [1, 4, 6, 4, 1];
   variable m, n = 4;
   variable ans = binomial (n);
   ifnot (_eqs (expected, ans))
     failed ("binomial(4) produced an incorrect result");
   _for m (0, n, 1)
     {
	if (binomial(n,m) != expected[m])
	  failed ("Incorrect value for binomial(%d,%d)", n, m);
     }
}

private define test_student_t ()
{
   variable x, y, p, t, p0, t0;

   x = [35,40,12,15,21,14,46,10,28,48,
	16,30,32,48,31,22,12,39,19,25];
   y = [ 2,27,38,31, 1,19, 1,34, 3, 1,
	 2, 3, 2, 1, 2, 1, 3,29,37, 2];
   t0 = 3.54;
   p0 = 0.0011;	  %  computed by http://www.graphpad.com/quickcalcs/ttest2.cfm

   p = t_test2 (x, y, &t);
   ifnot ((feqs (p,p0)) || feqs (t,t0))
     failed ("t_test2 failed:\n p = %S, p0 = %S, t = %g, t0 = %g", p, p0, t, t0);

   x = [10,20,50,57,32,12,6,17,9,11];
   t0 = 1.3328;
   p0 = 0.2153;	  %  computed by http://www.graphpad.com/quickcalcs/
   p = t_test (x, 30, &t);
   ifnot ((feqs (p,p0)) || feqs (t,t0))
     failed ("t_test 1 failed:\n p = %S, p0 = %S, t = %g, t0 = %g", p, p0, t, t0);

   t0 = 1.3328;
   p0 = 0.0033;	  %  computed by http://www.graphpad.com/quickcalcs/
   p = t_test (x, 45, &t);
   ifnot ((feqs (p,p0)) || feqs (t,t0))
     failed ("t_test 2 failed:\n p = %S, p0 = %S, t = %g, t0 = %g", p, p0, t, t0);
}

private define check_poisson_cdf (m, k, p)
{
   variable p1 = poisson_cdf (m, k);
   if (fneqs (p, p1, 1e-6))
     failed ("poisson_cdf(%S,%S) returned %S, expected %S, diff=%S", m, k, p1, p, abs(p-p1));
}

private define test_poisson_cdf ()
{
   % The CDFs were computed from http://www.xuru.org/
   check_poisson_cdf (6, 12, 0.991172516482);
   check_poisson_cdf (245, 300, 0.999702001313651);
   check_poisson_cdf (245, 345, 0.9999999993);
   check_poisson_cdf (345, 245, 8.407230482e-9);
   check_poisson_cdf (500.0, 500, 0.5118911217);
   check_poisson_cdf (500.0, 450, 0.01240835055);
   check_poisson_cdf (50000.0, 50000, 0.501189413);
   check_poisson_cdf (50000.0, 49900, 0.3283840695);
   check_poisson_cdf (50000.0, 50500, 0.9873021349);
}

private define test_mean_stddev_with_datatypes (xdata)
{
   variable type;

   foreach type ([Char_Type, UChar_Type, Int16_Type, UInt16_Type,
		  Int_Type, UInt_Type, Long_Type, ULong_Type,
		  Float_Type, Double_Type,
		 ])
     {
	test_mean_stddev (typecast (xdata, type));
     }
}

define slsh_main ()
{
   testing_module ("stats");

   variable xdata = 256*urand(10);
   test_mean_stddev_with_datatypes (xdata);
   xdata = 256*urand(11);
   test_mean_stddev_with_datatypes (xdata);

   % The following array caused problems for median_nc in the previous
   % implmentation
   xdata = [221, 125, 163, 230, 13, 67, 125, 215, 122, 108];
   test_mean_stddev_with_datatypes (xdata);

   xdata = [1,1,1];
   test_mean_stddev_with_datatypes (xdata);
   xdata = [1,1];
   test_mean_stddev_with_datatypes (xdata);

   test_chisqr_test ();
   test_f ();
   test_kendall_tau ();
   test_ks ();
   test_mw_cdf (2);
   test_mw_cdf (3);
   test_mw_cdf (10);
   test_mw_cdf (21);
   test_mw_test ();
   test_ad_ktest ();
   test_spearman ();
   test_binomial ();
   test_student_t ();
   test_poisson_cdf ();

   end_test ();
}
