_debug_info = 1; () = evalfile ("inc.sl");

testing_feature ("NaN and Inf");

if (isnan (0))
  failed ("isnan(0)");
if (isnan (0.0))
  failed ("isnan(0.0)");
if (0 == isnan (_NaN))
  failed ("isnan (_NaN)");
if (isnan (_Inf))
  failed ("isnan (_Inf)");
if (isinf (0))
  failed ("isinf(0)");
if (isinf (0.0))
  failed ("isinf(0.0)");
if (isinf (_NaN))
  failed ("isinf(_NaN)");
if (0 == isinf (_Inf))
  failed ("isinf (_Inf)");

print ("Ok\n");

exit (0);

