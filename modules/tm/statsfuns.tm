\function{ad_ktest}
\synopsis{k-sample Anderson-Darling test}
\usage{p = ad_ktest ({X1, X2, ...} [,&statistic] [;qualifiers])}
\description
  The \sfun{ad_ktest} function performs a k-sample Anderson-Darling
  test, which may be used to test the hypothesis that two or more
  statistical samples come from the same underlying parent population.

  The function returns the p-value representing the probability that
  the samples are consistent with a common parent distribution.  If
  the last parameter is a reference, then the variable that it
  references will be set to the value of the statistic upon return.

  The paper that this test is based upon presents two statistical
  tests: one for continuous data where ties are improbable, and one
  for data where ties can occur.  This function returns the p-value
  and statistic for the latter case.  A qualifier may be used to
  obtain the p-value and statistic for the continuous case.
\qualifiers
\qualifier{pval2=&var}{Set the variable \exmp{var} to the p-value for continuous case}
\qualifier{stat2=&var}{Set the variable \exmp{var} to the statistic for the continuous case.}
\notes
  The k-sample test was implemented from the equations found in
  Scholz F.W. and Stephens M.A., "K-Sample Anderson-Darling Tests",
  Journal of the American Statistical Association, Vol 82, 399 (1987).
\seealso{ks_test2, ad_test}
\done


\function{ad_test}
\synopsis{Anderson-Darling test for normality}
\usage{pval = ad_test (X [,&statistic] [;qualifiers])}
\description
  The \sfun{ad_test} function may be used to test the hypothesis that
  random samples \exmp{X} come from a normal distribution.  It returns
  the p-value representing the probability of obtaining such a dataset
  under the assumption that the data represent random samples of the
  underlying distribution.  If the optional second parameter is
  present, then it must be a reference to a variable that will be set
  to the value of the statistic upon return.
\qualifiers
\qualifier{mu=value}{Specifies the known mean of the normal distribution}.
\qualifier{sigma}{Specifies the known standard deviation of the normal distribution}
\qualifier{cdf}{If present, the data will be interpreted as a CDFs of a known, but unspecified, distribution.}
\notes
  For testing the hypothesis that a dataset is sampled from a known,
  not necessarily normal, distribution, convert the random samples
  into CDFs and pass those as the value of X to the \sfun{ad_test}
  function.  Also use the \exmp{cdf} qualifier to let the function
  know that the values are CDFs and not random samples.  When this is
  done, the values of the CDFs will range from 0 to 1, and the p-value
  returned by the function will be computed using an algorithm by
  Marsaglia and Marsaglia: Evaluating the Anderson-Darling
  Distribution, Journal of Statistical Software, Vol. 9, Issue 2, Feb
  2004.
\seealso{ad_ktest, ks_test, t_test, z_test, normal_cdf, }
\done

\function{median}
\synopsis{Compute the median of an array of values}
\usage{m = median (a [,i])}
\description
  This function computes the median of an array of values.  The median
  is defined to be the value such that half of the the array values will be
  less than or equal to the median value and the other half greater than or
  equal to the median value.  If the array has an even number of
  values, then the median value will be the smallest value that is
  greater than or equal to half the values in the array.

  If called with a second argument, then the optional argument
  specifies the dimension of the array over which the median is to be
  taken.  In this case, an array of one less dimension than the input
  array will be returned.
\notes
  This function makes a copy of the input array and then partially
  sorts the copy.  For large arrays, it may be undesirable to allocate
  a separate copy.  If memory use is to be minimized, the
  \ifun{median_nc} function should be used.
\seealso{median_nc, mean}
\done

\function{median_nc}
\synopsis{Compute the median of an array}
\usage{m = median_nc (a [,i])}
\description
  This function computes the median of an array.  Unlike the
  \ifun{median} function, it does not make a temporary copy of the
  array and, as such, is more memory efficient at the expense
  increased run-time.  See the \ifun{median} function for more
  information.
\seealso{median, mean}
\done

\function{mean}
\synopsis{Compute the mean of the values in an array}
\usage{m = mean (a [,i])}
\description
  This function computes the arithmetic mean of the values in an
  array.  The optional parameter \exmp{i} may be used to specify the
  dimension over which the mean it to be take.  The default is to
  compute the mean of all the elements.
\example
  Suppose that \exmp{a} is a two-dimensional MxN array.  Then
#v+
    m = mean (a);
#v-
  will assign the mean of all the elements of \exmp{a} to \exmp{m}.
  In contrast,
#v+
    m0 = mean(a,0);
    m1 = mean(a,1);
#v-
  will assign the N element array to \exmp{m0}, and an array of
  M elements to \exmp{m1}.  Here, the jth element of \exmp{m0} is
  given by \exmp{mean(a[*,j])}, and the jth element of \exmp{m1} is
  given by \exmp{mean(a[j,*])}.
\seealso{stddev, median, kurtosis, skewness}
\done

\function{stddev}
\synopsis{Compute the standard deviation of an array of values}
\usage{s = stddev (a [,i])}
\description
  This function computes the standard deviation of the values in the
  specified array. The optional parameter \exmp{i} may be used to
  specify the dimension over which the standard-deviation it to be
  taken.  The default is to compute the standard deviation of all the
  elements.
\notes
  This function returns the unbiased N-1 form of the sample standard
  deviation.
\seealso{mean, median, kurtosis, skewness}
\done

\function{skewness}
\synopsis{Compute the skewness of an array of values}
\usage{s = skewness (a)}
\description
  This function computes the so-called skewness of the array \exmp{a}.
\seealso{mean, stddev, kurtosis}
\done

\function{kurtosis}
\synopsis{Compute the kurtosis of an array of values}
\usage{s = kurtosis (a)}
\description
 This function computes the so-called kurtosis of the array \exmp{a}.
\notes
 This function is defined such that the kurtosis of the normal
 distribution is 0, and is also known as the ``excess-kurtosis''.
\seealso{mean, stddev, skewness}
\done

\function{binomial}
\synopsis{Compute binomial coefficients}
\usage{c = binomial (n [,m])}
\description
  This function computes the binomial coefficients (n m) where (n m)
  is given by n!/(m!(n-m)!).  If \exmp{m} is not provided, then an
  array of coefficients for m=0 to n will be returned.
\done

\function{chisqr_cdf}
\synopsis{Compute the Chisqr CDF}
\usage{cdf = chisqr_cdf (Int_Type n, Double_Type d)}
\description
 This function returns the probability that a random number
 distributed according to the chi-squared distribution for \exmp{n}
 degrees of freedom will be less than the non-negative value \exmp{d}.
\notes
 The importance of this distribution arises from the fact that if
 \exmp{n} independent random variables \exmp{X_1,...X_n} are
 distributed according to a gaussian distribution with a mean of 0 and
 a variance of 1, then the sum
#v+
    X_1^2 + X_2^2 + ... + X_n^2
#v-
 follows the chi-squared distribution with \exmp{n} degrees of freedom.
\seealso{chisqr_test, poisson_cdf}
\done

\function{poisson_cdf}
\synopsis{Compute the Poisson CDF}
\usage{cdf = poisson_cdf (Double_Type m, Int_Type k)}
\description
 This function computes the CDF for the Poisson probability
 distribution parameterized by the value \exmp{m}.  For values of
 \exmp{m>100} and \exmp{abs(m-k)<sqrt(m)}, the Wilson and Hilferty
 asymptotic approximation is used.
\seealso{chisqr_cdf}
\done

\function{smirnov_cdf}
\synopsis{Compute the Kolmogorov CDF using Smirnov's asymptotic form}
\usage{cdf = smirnov_cdf (x)}
\description
 This function computes the CDF for the Kolmogorov distribution using
 Smirnov's asymptotic form.  In particular, the implementation is based
 upon equation 1.4 from W. Feller, "On the Kolmogorov-Smirnov limit
 theorems for empirical distributions", Annals of Math. Stat, Vol 19
 (1948), pp. 177-190.
\seealso{ks_test, ks_test2, normal_cdf}
\done

\function{normal_cdf}
\synopsis{Compute the CDF for the Normal distribution}
\usage{cdf = normal_cdf (x)}
\description
  This function computes the CDF (integrated probability) for the
  normal distribution.
\seealso{smirnov_cdf, mann_whitney_cdf, poisson_cdf}
\done

\function{mann_whitney_cdf}
\synopsis{Compute the Mann-Whitney CDF}
\usage{cdf = mann_whitney_cdf (Int_Type m, Int_Type n, Int_Type s)}
\description
  This function computes the exact CDF P(X<=s) for the Mann-Whitney
  distribution.  It is used by the \exmp{mw_test} function to compute
  p-values for small values of \exmp{m} and \exmp{n}.
\seealso{mw_test, ks_test, normal_cdf}
\done

\function{kim_jennrich_cdf}
\synopsis{Compute the 2-sample KS CDF using the Kim-Jennrich Algorithm}
\usage{p = kim_jennrich (UInt_Type m, UInt_Type n, UInt_Type c)}
\description
  This function returns the exact two-sample Kolmogorov-Smirnov
  probability that that \exmp{D_mn <= c/(mn)}, where \exmp{D_mn} is
  the two-sample Kolmogorov-Smirnov statistic computed from samples of
  sizes \exmp{m} and \exmp{n}.

  The algorithm used is that of Kim and Jennrich.  The run-time scales
  as m*n.  As such, it is recommended that asymptotic form given by
  the \ifun{smirnov_cdf} function be used for large values of m*n.
\notes
  For more information about the Kim-Jennrich algorithm, see:
  Kim, P.J., and R.I. Jennrich (1973), Tables of the exact sampling
  distribution of the two sample Kolmogorov-Smirnov criterion Dmn(m<n),
  in Selected Tables in Mathematical Statistics, Volume 1, (edited
  by H. L. Harter and D.B. Owen), American Mathematical Society,
  Providence, Rhode Island.
\seealso{smirnov_cdf, ks_test2}
\done

\function{f_cdf}
\synopsis{Compute the CDF for the F distribution}
\usage{cdf = f_cdf (t, nu1, nu2)}
\description
  This function computes the CDF for the distribution and returns its
  value.
\seealso{f_test2}
\done
#d opt-3-parm#1  If the optional parameter is passed to the function, then \
 \__newline__ it must be a reference to a variable that, upon return, will be \
 \__newline__ set to the value of the $1.

\function{ks_test}
\synopsis{One sample Kolmogorov test}
\usage{p = ks_test (CDF [,&D])}
\description
 This function applies the Kolmogorov test to the data represented by
 \exmp{CDF} and returns the p-value representing the probability that
 the data values are ``consistent'' with the underlying distribution
 function. \opt-3-parm{Kolmogorov statistic}.

 The \exmp{CDF} array that is passed to this function must be computed
 from the assumed probability distribution function.  For example, if
 the data are constrained to lie between 0 and 1, and the null
 hypothesis is that they follow a uniform distribution, then the CDF
 will be equal to the data.  In the data are assumed to be normally
 (Gaussian) distributed, then the \ifun{normal_cdf} function can be
 used to compute the CDF.
\example
 Suppose that X is an array of values obtained from repeated
 measurements of some quantity.  The values are are assumed to follow
 a normal distribution with a mean of 20 and a standard deviation of
 3.  The \sfun{ks_test} may be used to test this hypothesis using:
#v+
    pval = ks_test (normal_cdf(X, 20, 3));
#v-
\seealso{ks_test2, ad_test, kuiper_test, t_test, z_test}
\done

\function{ks_test2}
\synopsis{Two-Sample Kolmogorov-Smirnov test}
\usage{prob = ks_test2 (X, Y [,&d])}
\description
 This function applies the 2-sample Kolmogorov-Smirnov test to two
 datasets \exmp{X} and \exmp{Y} and returns p-value for the null
 hypothesis that they share the same underlying distribution.
 \opt-3-parm{statistic}
\notes
 If \exmp{length(X)*length(Y)<=10000}, the \ifun{kim_jennrich_cdf}
 function will be used to compute the exact probability.  Otherwise an
 asymptotic form will be used.
\seealso{ks_test, ad_ktest, kuiper_test, kim_jennrich_cdf}
\done

\function{kuiper_test}
\synopsis{Perform a 1-sample Kuiper test}
\usage{pval = kuiper_test (CDF [,&D])}
\description
 This function applies the Kuiper test to the data represented by
 \exmp{CDF} and returns the p-value representing the probability that
 the data values are ``consistent'' with the underlying distribution
 function.  \opt-3-parm{Kuiper statistic}

 The \exmp{CDF} array that is passed to this function must be computed
 from the assumed probability distribution function.  For example, if
 the data are constrained to lie between 0 and 1, and the null
 hypothesis is that they follow a uniform distribution, then the CDF
 will be equal to the data.  In the data are assumed to be normally
 (Gaussian) distributed, then the \ifun{normal_cdf} function can be
 used to compute the CDF.
\example
 Suppose that X is an array of values obtained from repeated
 measurements of some quantity.  The values are are assumed to follow
 a normal distribution with a mean of 20 and a standard deviation of
 3.  The \sfun{ks_test} may be used to test this hypothesis using:
#v+
    pval = kuiper_test (normal_cdf(X, 20, 3));
#v-
\seealso{kuiper_test2, ks_test, t_test}
\done

\function{kuiper_test2}
\synopsis{Perform a 2-sample Kuiper test}
\usage{pval = kuiper_test2 (X, Y [,&D])}
\description
 This function applies the 2-sample Kuiper test to two
 datasets \exmp{X} and \exmp{Y} and returns p-value for the null
 hypothesis that they share the same underlying distribution.
 \opt-3-parm{Kuiper statistic}
\notes
 The p-value is computed from an asymptotic formula suggested by
 Stephens, M.A., Journal of the American Statistical Association, Vol
 69, No 347, 1974, pp 730-737.
\seealso{ks_test2, kuiper_test}
\done

\function{chisqr_test}
\synopsis{Apply the Chi-square test to a two or more datasets}
\usage{prob = chisqr_test (X_1[], X_2[], ..., X_N [,&t])}
\description
 This function applies the Chi-square test to the N datasets
 \exmp{X_1}, \exmp{X_2}, ..., \exmp{X_N}, and returns the probability
 that each of the datasets were drawn from the same underlying
 distribution.  Each of the arrays \exmp{X_k} must be the same length.
 If the last parameter is a reference to a variable, then upon return
 the variable will be set to the value of the statistic.
\seealso{chisqr_cdf, ks_test2, mw_test}
\done

\function{mw_test}
\synopsis{Apply the Two-sample Wilcoxon-Mann-Whitney test}
\usage{p = mw_test(X, Y [,&w])}
\description
 This function performs a Wilcoxon-Mann-Whitney test and returns the
 p-value for the null hypothesis that there is no difference between
 the distributions represented by the datasets \exmp{X} and \exmp{Y}.

 If a third argument is given, it must be a reference to a variable
 whose value upon return will be to to the rank-sum of \exmp{X}.
\qualifiers
 The function makes use of the following qualifiers:
#v+
     side=">"  :    H0: P(X<Y) >= 1/2    (right-tail)
     side="<"  :    H0: P(X<Y) <= 1/2    (left-tail)
#v-
 The default null hypothesis is that \exmp{P(X<Y)=1/2}.
\notes
 There are a number of definitions of this test.  While the exact
 definition of the statistic varies, the p-values are the same.

 If \exmp{length(X)<50}, \exmp{length(Y)} < 50, and ties are not
 present, then the exact p-value is computed using the
 \ifun{mann_whitney_cdf} function.  Otherwise a normal distribution is
 used.

 This test is often referred to as the non-parametric generalization
 of the Student t-test.
\seealso{mann_whitney_cdf, ks_test2, chisqr_test, t_test}
\done


\function{student_t_cdf}
\synopsis{Compute the Student-t CDF}
\usage{cdf = student_t_cdf (t, n)}
\description
This function computes the CDF for the Student-t distribution for n
degrees of freedom.
\seealso{t_test, normal_cdf}
\done

\function{f_test2}
\synopsis{Apply the Two-sample F test}
\usage{p = f_test2 (X, Y [,&F]}
\description
  This function computes the two-sample F statistic and its p-value
  for the data in the \exmp{X} and \exmp{Y} arrays.  This test is used
  to compare the variances of two normally-distributed data sets, with
  the null hypothesis that the variances are equal.  The return value
  is the p-value, which is computed using the module's \ifun{f_cdf}
  function.
\qualifiers
  The function makes use of the following qualifiers:
#v+
     side=">"  :    H0: Var[X] >= Var[Y]  (right-tail)
     side="<"  :    H0: Var[X] <= Var[Y]  (left-tail)
#v-
\seealso{f_cdf, ks_test2, chisqr_test}
\done

\function{t_test}
\synopsis{Perform a Student t-test}
\usage{pval = t_test (X, mu [,&t])}
\description
 The one-sample t-test may be used to test that the population mean has a
 specified value under the null hypothesis.  Here, \exmp{X} represents a
 random sample drawn from the population and \exmp{mu} is the
 specified mean of the population.   This function computes Student's
 t-statistic and returns the p-value
 that the data X were randomly sampled from a population with the
 specified mean.
 \opt-3-parm{statistic}
\qualifiers
 The following qualifiers may be used to specify a 1-sided test:
#v+
   side="<"       Perform a left-tailed test
   side=">"       Perform a right-tailed test
#v-
\notes
 While the parent population need not be normal, the test assumes
 that random samples drawn from this distribution have means that
 are normally distributed.

 Strictly speaking, this test should only be used if the variance of
 the data are equal to that of the assumed parent distribution.  Use
 the Mann-Whitney-Wilcoxon (\exmp{mw_test}) if the underlying
 distribution is non-normal.
\seealso{mw_test, t_test2}
\done

\function{t_test2}
\synopsis{Perform a 2-sample Student t-test}
\usage{pval = t_test2 (X, Y [,&t])}
\description
 This function compares two data sets \exmp{X} and \exmp{Y} using the
 Student t-statistic.  It is assumed that the the parent populations
 are normally distributed with equal variance, but with possibly
 different means.  The test is one that looks for differences in the
 means.
\notes
 The \exmp{welch_t_test2} function may be used if it is not known that
 the parent populations have the same variance.
\seealso{t_test2, welch_t_test2, mw_test}
\done

\function{welch_t_test2}
\synopsis{Perform Welch's t-test}
\usage{pval = welch_t_test2 (X, Y [,&t])}
\description
 This function applies Welch's t-test to the 2 datasets \exmp{X} and
 \exmp{Y} and returns the p-value that the underlying populations have
 the same mean.  The parent populations are assumed to be normally
 distributed, but need not have the same variance.
 \opt-3-parm{statistic}
\qualifiers
 The following qualifiers may be used to specify a 1-sided test:
#v+
   side="<"       Perform a left-tailed test
   side=">"       Perform a right-tailed test
#v-
\seealso{t_test2}
\done

\function{z_test}
\synopsis{Perform a Z test}
\usage{pval = z_test (X, mu, sigma [,&z])}
\description
  This function applies a Z test to the data \exmp{X} and returns the
  p-value that the data are consistent with a normally-distributed
  parent population with a mean of \exmp{mu} and a standard-deviation
  of \exmp{sigma}.  \opt-3-parm{Z statistic}
\seealso{t_test, mw_test}
\done

\function{kendall_tau}
\synopsis{Kendall's tau Correlation Test}
\usage{pval = kendall_tau (x, y [,&tau])}
\description
  This function computes Kendall's tau statistic for the paired data
  values (x,y), which may or may not have ties.  It returns the
  double-sided p-value associated with the statistic.
\notes
  The implementation is based upon Knight's O(nlogn) algorithm
  described in "A computer method for calculating Kendall’s tau with
  ungrouped data", Journal of the American Statistical Association, 61,
  436-439.

  In the case of no ties, the exact p-value is computed when length(x)
  is less than 30 using algorithm 71 of Applied Statistics (1974) by
  Best and Gipps.  If ties are present, the the p-value is computed
  based upon the normal distribution and a continuity correction.
\qualifiers
 The following qualifiers may be used to specify a 1-sided test:
#v+
   side="<"       Perform a left-tailed test
   side=">"       Perform a right-tailed test
#v-
\seealso{spearman_r, pearson_r, mann_kendall}
\done

\function{mann_kendall}
\synopsis{Mann-Kendall trend test}
\usage{pval = mann_kendall (y [,&tau])}
\description
  The Mann-Kendall test is a non-parametric test that may be used to
  identify a trend in a set of serial data values.  It is closely
  related to the Kendall's tau correlation test.

  The \ifun{mann_kendall} function returns the double-sided p-value
  that may be used as a basis for rejecting the the null-hypothesis
  that there is no trend in the data.

\qualifiers
 The following qualifiers may be used to specify a 1-sided test:
#v+
   side="<"       Perform a left-tailed test
   side=">"       Perform a right-tailed test
#v-
\seealso{spearman_r, pearson_r, mann_kendall}
\done

\function{pearson_r}
\synopsis{Compute Pearson's Correlation Coefficient}
\usage{pval = pearson_r (X, Y [,&r])}
\description
 This function computes Pearson's r correlation coefficient of the two
 datasets \exmp{X} and \exmp{Y}.  It returns the the p-value that
 \exmp{x} and \exmp{y} are mutually independent.
 \opt-3-parm{correlation coefficient}
\qualifiers
 The following qualifiers may be used to specify a 1-sided test:
#v+
   side="<"       Perform a left-tailed test
   side=">"       Perform a right-tailed test
#v-
\seealso{kendall_tau, spearman_r}
\done

\function{spearman_r}
\synopsis{Spearman's Rank Correlation test}
\usage{pval = spearman_r(x, y [,&r])}
\description
  This function computes the Spearman rank correlation coefficient (r)
  and returns the p-value that \exmp{x} and \exmp{y} are mutually
  independent.
  \opt-3-parm{correlation coefficient}
\qualifiers
 The following qualifiers may be used to specify a 1-sided test:
#v+
   side="<"       Perform a left-tailed test
   side=">"       Perform a right-tailed test
#v-
\seealso{kendall_tau, pearson_r}
\done

\function{correlation}
\synopsis{Compute the sample correlation between two datasets}
\usage{c = correlation (x, y)}
\description
  This function computes Pearson's sample correlation coefficient
  between 2 arrays.  It is assumed that the standard deviation of each
  array is finite and non-zero.  The returned value falls in the
  range -1 to 1, with -1 indicating that the data are anti-correlated,
  and +1 indicating that the data are completely correlated.
\seealso{covariance, stddev}
\done

