() = evalfile ("./common.sl");

require ("timestamp");

private define test_timestamp (t_expected, dates)
{
   variable bad = 0;
   foreach (dates)
     {
	variable ts = ();
	variable t = timestamp_parse (ts);
	if (t != t_expected)
	  {
	     () = fprintf (stderr, "ERROR: %S --> %S, expected %S\n", ts, t, t_expected);
	     bad++;
	  }
     }
   return bad;
}

define slsh_main ()
{
   start_test ("timestamp");

   variable t_expected, dates, bad = 0;

   t_expected = 1588455117;
   dates =
     {
	"Tue, 2 May 2020 22.31.57 +0100",
	"May  2 17:31:57 2020 EDT",
	"2020-05-02T21:31:57Z",
	"2020-05-02T21:31:57+00:00",
	"2020-05-02T17:31:57-04:00",
	"20200502T173157-0400",
	"Tue, 02 May 2020 21:31:57 +0000",
	"Tue, 2 May 2020 21:31:57 +0000",
	"Tuesday, 02-May-20 21:31:57 UTC",
	"Tuesday, 02-May-20 9:31:57PM UTC",
	"Tuesday, 2-May-20 21:31:57 UTC",
	"Tuesday, 2-May-2020 21:31:57 UTC",
	"Tuesday, 2-May-2020, 21:31:57Z",
	"2020-05-02T21:31:57+00:00",
	"5/02/2020, 5:31:57 PM EDT",
	"5/2/2020, 5:31:57 PM EDT",
	"5/2/20, 5:31:57 PM EDT",
	"Tue May 2 17:31:57 2020 EDT",
	"May 2, 17:31:57, 2020 EDT",
     };
   bad += test_timestamp (t_expected, dates);

   t_expected = 1591137060;
   dates =
     {
	"June 2, 2020 5:31 PM EST",
	"Jun 2, 2020 5:31 PM EST",
	"Thu Jun 2, 2020 5:31 PM EST",
	"Thursday, Jun 2, 2020 5:31 PM EST",
	"Thursday, June 2, 2020 5:31 PM EST",
     };
   bad += test_timestamp (t_expected, dates);

   t_expected = 1611445148;
   dates =
     {
	"Sat, 23 Jan 2021 23:39:08 +0000 (UTC)",
     };
   bad += test_timestamp (t_expected, dates);

   t_expected = 97027200;
   dates =
     {
	"1973-01-28T00:00:00Z",
     };
   bad += test_timestamp (t_expected, dates);

   t_expected = 1597014697;
   dates =
     {
	"2020-08-09T23:11:37Z",
	"Sun Aug  9 19:11:37 2020 EDT",
     };
   bad += test_timestamp (t_expected, dates);

   % Test the current line without a timezone specified
   variable now = _time();
   dates = [strftime ("%b %d, %Y %H:%M:%S", localtime(now))];
   bad += test_timestamp (now, dates);

   if (bad) failed ("%d timestamps failed to parse", bad);

   end_test ();
}

