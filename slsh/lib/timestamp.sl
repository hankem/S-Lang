% Copyright (C) 2020-2021, 2022 John E. Davis
%
% This file is part of the S-Lang Library and may be distributed under the
% terms of the GNU General Public License.  See the file COPYING for
% more information.
%---------------------------------------------------------------------------
% The code here attemps to convert a human readable representation of a
% timestamp, such as Wed May 13 02:38:34 2020 to a Unix time (number
% of secs since the Unix epoch)
%
% Public funtions:
%
%    timestamp_parse:
%       Parses a timestamp and Returns the number of seconds since
%       the Unix EPOCH (1970-01-01T00:00:00Z)
%
private variable Months
  = ["jan", "feb", "mar", "apr", "may", "jun",
     "jul", "aug", "sep", "oct", "nov", "dec"];

% There is an extensive list of timezone abbreviations at
% <https://www.timeanddate.com/time/zones/>.  The problem with
% abbreviations is that they are not unique.  For example, CST
% could refer to Austrailia, North America, or China.
% The ones here are used by slrn.
private variable TZMap = Assoc_Type[Int_Type, 0];
TZMap["EDT"] = -400;		       % US Eastern Daylight Time
TZMap["EST"] = -500;		       % US Eastern Standard Time
TZMap["CDT"] = -500;		       % US Central Daylight Time
TZMap["CST"] = -600;		       % US Central
TZMap["MDT"] = -600;		       % US Mountain Daylight Time
TZMap["MST"] = -700;		       % US Mountain
TZMap["PDT"] = -700;		       % US Pacific Daylight Time
TZMap["PST"] = -800;		       % US Pacific
TZMap["GMT"] = 0;
TZMap["UTC"] = 0;
TZMap["Z"] = 0;
TZMap["CET"] = 100;		       % Central European
TZMap["MET"] = 100;		       % Middle European
TZMap["MEZ"] = 100;		       % Middle European
TZMap["EET"] = 200;		       % Eastern European   
TZMap["MSK"] = 300;		       % Moscow
TZMap["HKT"] = 800;		       % Hong Kong   
TZMap["JST"] = 900;		       % Japan Standard   
TZMap["KST"] = 900;		       % Korean Standard   
TZMap["CAST"] = 930;		       % Central Autsralian   
TZMap["EAST"] = 1000;		       % Eastern Autsralian   
TZMap["NZST"] = 1200;		       % New Zealand Autsralian   

private define map_tzstr_string (tzstr)
{
   return TZMap[strtrim (strup(tzstr))];
}

private variable Cumulative_Days_Per_Month =
  int (cumsum ([0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]));

private variable TS_Formats = {};
private define add_ts_format (re, indices, month_is_int)
{
   variable s = struct
     {
	re = re,
	month_is_int = month_is_int,
	indices = indices,
     };

   list_append (TS_Formats, s);
}
% Tue 12 May 2020 04:37:54 [PM] EDT
add_ts_format (`^[a-zA-Z,]*`		       %  weekday  
	       + ` *\(\d\d?\)[ -]\([a-zA-Z]+\)[ -]\(\d\d\d*\),?`   %  day month year
	       + ` *\(\d\d?\)[:.]\(\d\d\)[:.]?\(\d*\)`  %  hh:mm:ss
	       + ` *\(.*\)`,		       %  AM/PM + tz
	       [1,2,3,4,5,6,7], 0);

%  Sun, Dec 04, 1994 11:05:52 GMT
add_ts_format (`^[a-zA-Z,]+`
	       + ` +\([a-zA-Z]\{3,\}\) \(\d+\),? *\(\d\d\d*\)`%  month, day, year  
	       + ` +\(\d\d?\):\(\d\d\):?\(\d*\)`%  hh:mm:ss  
	       + ` *\(.*\)`,		       %  tz
	       [2,1,3,4,5,6,7], 0);

% Dec 04, 1994 11:05:52 GMT
add_ts_format (`^\([a-zA-Z]\{3,\}\) \(\d+\),? *\(\d\d\d*\)`%  month, day, year  
	       + ` +\(\d\d?\):\(\d\d\):?\(\d*\)`%  hh:mm:ss  
	       + ` *\(.*\)`,		       %  tz
	       [2,1,3,4,5,6,7], 0);

% 2020-09-12T21:17:30 <tz-offset>
add_ts_format (`^\(\d\d\d\d\)-?\(\d\d\)-?\(\d\d\)`
	       + `T\(\d\d\):?\(\d\d\):?\(\d\d\)`
	       + ` *\(.*\)`,
	       [3,2,1,4,5,6,7], 1);

% 5/12/2020, 5:31:57 PM
add_ts_format (`\(\d\d?\)/\(\d\d?\)/\(\d\d\d*\),?`
	       + ` *\(\d\d?\):\(\d\d\):?\(\d*\)`
	       + ` *\(.*\)`,
	       [2,1,3,4,5,6,7], 1);

% Dec 4 11:05:52 2020
add_ts_format (`^\([a-zA-Z]\{3,\}\) +\(\d+\),?`  %  month, day
	       + ` +\(\d\d?\):\(\d\d\):?\(\d*\),?`%  hh:mm:ss
	       + ` +\(\d\d\d*\)`       %  year
	       + ` *\(.*\)`,	       %  tz  
	       [2,1,6,3,4,5,7], 0);

% Tue Dec 4 11:05:52 2020
add_ts_format (`^[A-Za-z,]+`
	       + ` +\([a-zA-Z]\{3,\}\) +\(\d+\),?`  %  month, day
	       + ` +\(\d\d?\):\(\d\d\):?\(\d*\),?`%  hh:mm:ss
	       + ` +\(\d\d\d*\)`       %  year  
	       + ` *\(.*\)`,	       %  tz  
	       [2,1,6,3,4,5,7], 0);

private variable Last_TS_Index = 0;
private define guess_local_timezone_offset ()
{
   variable now = _time(), tm = gmtime(now);
   tm.tm_isdst = -1;  % Force a lookup to see if DST is in effect
   variable secs = now - mktime (tm);
   variable hours = secs/3600;
   return 100*hours + (secs - 3600*hours)/60;
}

define timestamp_parse (timestamp)
{
   timestamp = strtrim (timestamp);
   variable day, month, year, hours, minutes, secs, tz, tzstr;
   variable num = length (TS_Formats);
   loop (num)
     {
	variable fmt = TS_Formats[Last_TS_Index];

	variable matches = string_matches (timestamp, fmt.re);
	if (matches == NULL)
	  {
	     Last_TS_Index = (Last_TS_Index + 1) mod num;
	     continue;
	  }
	variable ind = fmt.indices;
	day = atoi (matches[ind[0]]);
	month = matches[ind[1]];
	year = atoi (matches[ind[2]]);
	hours = atoi (matches[ind[3]]);
	minutes = atoi (matches[ind[4]]);
	secs = atoi (matches[ind[5]]);
	tzstr = matches[ind[6]];

	if (fmt.month_is_int)
	  month = atoi (month) - 1; %  0 to 11
	else
	  {
	     if (strbytelen (month) > 3) month = month[[0,1,2]];
	     month = wherefirst (Months == strlow(month));
	     if (month == NULL) return NULL;
	  }
	break;
     }
   then return NULL;

   if (year < 100)
     {
	% No century
	year += 1900;
	if (year < 1950) year += 100;
     }
   tzstr = strtrim (tzstr);

   % Take care of AM/PM
   if (((tzstr[0] == 'A') || (tzstr[0] == 'P'))
       && (tzstr[1] == 'M')
       && ((tzstr[2] == 0) || (tzstr[2] == ' ')))
     {
	if (tzstr[0] == 'P')
	  hours += 12;
	tzstr = strtrim (tzstr[[2:]]);
     }

   tzstr = strreplace (tzstr, ":", "");
   if (tzstr == "")
     tz = guess_local_timezone_offset ();
   else
     {
	tz = atoi (tzstr);
	if ((tz == 0) && (tzstr[0] != '+') && (tzstr[0] != '-'))
	  tz = map_tzstr_string (tzstr);
     }

   day--;			       %  offset from 0
   % Compute the cumulative number of days, accounting for a leap year
   day += Cumulative_Days_Per_Month[month];
   if ((month > 2)
       && (0 == (year mod 4))
       && ((year mod 100) || (0 == (year mod 400))))
     day++;

   year -= 1970;		       %  Unix EPOCH
   day += 365*year + (year+1)/4;       %  leap year, every 4 years from 72

   % The TZ is hhmm form, so 600 is 6 hours, and 0 minutes
   hours -= tz/100;
   minutes -= tz mod 100;

   return secs + 60L*(minutes + 60L*(hours + 24L*day));
}
