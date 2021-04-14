% Copyright (C) 2012-2020,2021 John E. Davis
%
% This file is part of the S-Lang Library and may be distributed under the
% terms of the GNU General Public License.  See the file COPYING for
% more information.
%---------------------------------------------------------------------------
import ("chksum");

private variable CRC8_Map = Assoc_Type[Struct_Type];
define chksum_add_crc8_subtype (subtype)
{
   subtype = strtrans(subtype, "-_", "");
   CRC8_Map[strlow(subtype)] = @__qualifiers;
}

chksum_add_crc8_subtype("";		poly=0xD5, seed=0x00, refin=0, refout=0, xorout=0x00);
chksum_add_crc8_subtype("dvb-s2"; 	poly=0xD5, seed=0x00, refin=0, refout=0, xorout=0x00);
chksum_add_crc8_subtype("cdma2000";	poly=0x9B, seed=0xFF, refin=0, refout=0, xorout=0x00);
chksum_add_crc8_subtype("darc";		poly=0x39, seed=0x00, refin=1, refout=1, xorout=0x00);
chksum_add_crc8_subtype("ebu";		poly=0x1D, seed=0xFF, refin=1, refout=1, xorout=0x00);
chksum_add_crc8_subtype("i-code";	poly=0x1D, seed=0xFD, refin=0, refout=0, xorout=0x00);
chksum_add_crc8_subtype("itu";		poly=0x07, seed=0x00, refin=0, refout=0, xorout=0x55);
chksum_add_crc8_subtype("maxim";	poly=0x31, seed=0x00, refin=1, refout=1, xorout=0x00);
chksum_add_crc8_subtype("rohc";		poly=0x07, seed=0xFF, refin=1, refout=1, xorout=0x00);
chksum_add_crc8_subtype("wcdma";	poly=0x9B, seed=0x00, refin=1, refout=1, xorout=0x00);

private variable CRC16_Map = Assoc_Type[Struct_Type];
define chksum_add_crc16_subtype (subtype)
{
   subtype = strtrans(subtype, "-_", "");
   CRC16_Map[strlow(subtype)] = @__qualifiers;
}

chksum_add_crc16_subtype("";		poly=0x1021U, seed=0xFFFFU, refin=0, refout=0, xorout=0x0000U);
chksum_add_crc16_subtype("ccitt-0";	poly=0x1021U, seed=0xFFFFU, refin=0, refout=0, xorout=0x0000U);
chksum_add_crc16_subtype("ARC";		poly=0x8005U, seed=0x0000U, refin=1, refout=1, xorout=0x0000U);
chksum_add_crc16_subtype("AUG-CCITT";	poly=0x1021U, seed=0x1D0FU, refin=0, refout=0, xorout=0x0000U);
chksum_add_crc16_subtype("BUYPASS";	poly=0x8005U, seed=0x0000U, refin=0, refout=0, xorout=0x0000U);
chksum_add_crc16_subtype("CDMA2000";	poly=0xC867U, seed=0xFFFFU, refin=0, refout=0, xorout=0x0000U);
chksum_add_crc16_subtype("DDS-110";	poly=0x8005U, seed=0x800DU, refin=0, refout=0, xorout=0x0000U);
chksum_add_crc16_subtype("DECT-R";	poly=0x0589U, seed=0x0000U, refin=0, refout=0, xorout=0x0001U);
chksum_add_crc16_subtype("DECT-X";	poly=0x0589U, seed=0x0000U, refin=0, refout=0, xorout=0x0000U);
chksum_add_crc16_subtype("DNP";		poly=0x3D65U, seed=0x0000U, refin=1, refout=1, xorout=0xFFFFU);
chksum_add_crc16_subtype("EN-13757";	poly=0x3D65U, seed=0x0000U, refin=0, refout=0, xorout=0xFFFFU);
chksum_add_crc16_subtype("GENIBUS";	poly=0x1021U, seed=0xFFFFU, refin=0, refout=0, xorout=0xFFFFU);
chksum_add_crc16_subtype("MAXIM";	poly=0x8005U, seed=0x0000U, refin=1, refout=1, xorout=0xFFFFU);
chksum_add_crc16_subtype("MCRF4XX";	poly=0x1021U, seed=0xFFFFU, refin=1, refout=1, xorout=0x0000U);
chksum_add_crc16_subtype("RIELLO";	poly=0x1021U, seed=0xB2AAU, refin=1, refout=1, xorout=0x0000U);
chksum_add_crc16_subtype("T10-DIF";	poly=0x8BB7U, seed=0x0000U, refin=0, refout=0, xorout=0x0000U);
chksum_add_crc16_subtype("TELEDISK";	poly=0xA097U, seed=0x0000U, refin=0, refout=0, xorout=0x0000U);
chksum_add_crc16_subtype("TMS37157";	poly=0x1021U, seed=0x89ECU, refin=1, refout=1, xorout=0x0000U);
chksum_add_crc16_subtype("USB";		poly=0x8005U, seed=0xFFFFU, refin=1, refout=1, xorout=0xFFFFU);
chksum_add_crc16_subtype("A";		poly=0x1021U, seed=0xC6C6U, refin=1, refout=1, xorout=0x0000U);
chksum_add_crc16_subtype("KERMIT";	poly=0x1021U, seed=0x0000U, refin=1, refout=1, xorout=0x0000U);
chksum_add_crc16_subtype("MODBUS";	poly=0x8005U, seed=0xFFFFU, refin=1, refout=1, xorout=0x0000U);
chksum_add_crc16_subtype("X-25";	poly=0x1021U, seed=0xFFFFU, refin=1, refout=1, xorout=0xFFFFU);
chksum_add_crc16_subtype("XMODEM";	poly=0x1021U, seed=0x0000U, refin=0, refout=0, xorout=0x0000U);

private variable CRC32_Map = Assoc_Type[Struct_Type];
define chksum_add_crc32_subtype (subtype)
{
   subtype = strtrans(subtype, "-_", "");
   CRC32_Map[strlow(subtype)] = @__qualifiers;
}

chksum_add_crc32_subtype("";		poly=0x04C11DB7U, seed=0xFFFFFFFFU, refin=1, refout=1, xorout=0xFFFFFFFFU);
chksum_add_crc32_subtype("BZIP2";	poly=0x04C11DB7U, seed=0xFFFFFFFFU, refin=0, refout=0, xorout=0xFFFFFFFFU);
chksum_add_crc32_subtype("C";		poly=0x1EDC6F41U, seed=0xFFFFFFFFU, refin=1, refout=1, xorout=0xFFFFFFFFU);
chksum_add_crc32_subtype("D";		poly=0xA833982BU, seed=0xFFFFFFFFU, refin=1, refout=1, xorout=0xFFFFFFFFU);
chksum_add_crc32_subtype("MPEG-2";	poly=0x04C11DB7U, seed=0xFFFFFFFFU, refin=0, refout=0, xorout=0x00000000U);
chksum_add_crc32_subtype("POSIX";	poly=0x04C11DB7U, seed=0x00000000U, refin=0, refout=0, xorout=0xFFFFFFFFU);
chksum_add_crc32_subtype("Q";		poly=0x814141ABU, seed=0x00000000U, refin=0, refout=0, xorout=0x00000000U);
chksum_add_crc32_subtype("JAMCRC";	poly=0x04C11DB7U, seed=0xFFFFFFFFU, refin=1, refout=1, xorout=0x00000000U);
chksum_add_crc32_subtype("XFER";	poly=0x000000AFU, seed=0x00000000U, refin=0, refout=0, xorout=0x00000000U);

private define parse_name (name)
{
   name = strlow (name);
   variable q = __qualifiers;
   variable subtype = qualifier ("type", NULL);
   variable words = strchop (name, '/', 0);

   % Convert crc-8 to crc8, i-code to icode, etc
   name = strtrans(words[0], "-_", "");
   if (strncmp(name, "crc", 3))
     return name, q;

   if (length (words) > 1)
     subtype = words[1];
   else if (subtype == NULL)
     {
	if (q != NULL)
	  return name, q;
	subtype = "";
     }

   subtype = strtrans (strlow (subtype), "-_", "");
   variable map = NULL;

   if (name == "crc8")
     map = CRC8_Map;
   else if (name == "crc16")
     map = CRC16_Map;
   else if (name == "crc32")
     map = CRC32_Map;

   if ((map != NULL)
       && assoc_key_exists (map, subtype))
     return name, map[subtype];

   throw UndefinedNameError, "Unknown $name type: $subtype"$;
}

private define chksum_accumulate (c, str)
{
   _chksum_accumulate (c.obj, str);
}

private define chksum_close (c)
{
   variable chksum = _chksum_close (c.obj);
   c.obj = NULL;
   return chksum;
}

define chksum_new (name)
{
   variable q;
   (name, q) = parse_name (name;; __qualifiers);
   return struct
     {
	obj = _chksum_new (name;; q),
	accumulate = &chksum_accumulate,
	close = &chksum_close,
	name = name,
     };
}


define chksum_file (fp, type)
{
   variable q;
   (type, q) = parse_name (type;; __qualifiers);

   variable file = NULL;
   if (typeof (fp) != File_Type)
     {
	file = fp;
	fp = fopen (file, "rb");
	if (fp == NULL)
	  throw OpenError, "Error opening $file"$;
     }

   variable c = _chksum_new (type;; q);

   variable buf;
   while (-1 != fread_bytes (&buf, 4096, fp))
     {
	_chksum_accumulate (c, buf);
     }
   % Allow the interpreter to close fp when it goes out of scope
   return _chksum_close (c);
}

define md5sum_new ()
{
   return chksum_new ("md5");
}

define md5sum (str)
{
   variable c = _chksum_new ("md5");
   _chksum_accumulate (c, str);
   return _chksum_close (c);
}

define md5sum_file (file)
{
   return chksum_file (file, "md5");
}

define sha1sum_new ()
{
   return chksum_new ("sha1");
}

define sha1sum (str)
{
   variable c = _chksum_new ("sha1");
   _chksum_accumulate (c, str);
   return _chksum_close (c);
}

define sha1sum_file (file)
{
   return chksum_file (file, "sha1");
}

define crc8_new ()
{
   return chksum_new ("crc8";; __qualifiers);
}

define crc8sum (str)
{
   variable name, q;
   (name, q) = parse_name ("crc8";; __qualifiers);
   variable c = _chksum_new (name;; q);
   _chksum_accumulate (c, str);
   return _chksum_close(c);
}

define crc8sum_file (file)
{
   return chksum_file (file, "crc8";;__qualifiers);
}

define crc16_new ()
{
   return chksum_new ("crc16";; __qualifiers);
}

define crc16sum (str)
{
   variable name, q;
   (name, q) = parse_name ("crc16";; __qualifiers);
   variable c = _chksum_new (name;; q);
   _chksum_accumulate (c, str);
   return _chksum_close(c);
}

define crc16sum_file (file)
{
   return chksum_file (file, "crc16";;__qualifiers);
}

define crc32_new ()
{
   return chksum_new ("crc32";; __qualifiers);
}

define crc32sum (str)
{
   variable name, q;
   (name, q) = parse_name ("crc32";; __qualifiers);
   variable c = _chksum_new (name;; q);
   _chksum_accumulate (c, str);
   return _chksum_close(c);
}

define crc32sum_file (file)
{
   return chksum_file (file, "crc32";;__qualifiers);
}

