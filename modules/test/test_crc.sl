() = evalfile ("./test.sl");
require ("chksum");

private variable CRC8_Map = Assoc_Type[];
private variable CRC16_Map = Assoc_Type[];
private variable CRC32_Map = Assoc_Type[];

private define addcrc (map, name,r0,r1,poly,seed,refin,refout,xorout)
{
   map[name] = struct
     {
	s0 = "Four score and seven years ago",
	s1 = "123456789",
	r0 = r0,
	r1 = r1,
	poly = poly,
	seed = seed,
	refin = refin,
	refout = refout,
	xorout = xorout,
     };
}

private define addcrc8(name,r0,r1,poly,seed,refin,refout,xorout)
{
   addcrc (CRC8_Map, name,r0,r1,poly,seed,refin,refout,xorout);
}

addcrc8("CRC-8", 0x3EU, 0xBCU, 0xD5U, 0x00U, 0, 0, 0x00U);
addcrc8("CRC-8/CDMA2000", 0xE6U, 0xDAU, 0x9BU, 0xFFU, 0, 0, 0x00U);
addcrc8("CRC-8/DARC", 0x4DU, 0x15U, 0x39U, 0x00U, 1, 1, 0x00U);
addcrc8("CRC-8/DVB-S2", 0x3EU, 0xBCU, 0xD5U, 0x00U, 0, 0, 0x00U);
addcrc8("CRC-8/EBU", 0x1FU, 0x97U, 0x1DU, 0xFFU, 1, 1, 0x00U);
addcrc8("CRC-8/I-CODE", 0x00U, 0x7EU, 0x1DU, 0xFDU, 0, 0, 0x00U);
addcrc8("CRC-8/ITU", 0xB5U, 0xA1U, 0x07U, 0x00U, 0, 0, 0x55U);
addcrc8("CRC-8/MAXIM", 0x98U, 0xA1U, 0x31U, 0x00U, 1, 1, 0x00U);
addcrc8("CRC-8/ROHC", 0xC4U, 0xD0U, 0x07U, 0xFFU, 1, 1, 0x00U);
addcrc8("CRC-8/WCDMA", 0xDCU, 0x25U, 0x9BU, 0x00U, 1, 1, 0x00U);

private define addcrc16(name,r0,r1,poly,seed,refin,refout,xorout)
{
   addcrc (CRC16_Map, name,r0,r1,poly,seed,refin,refout,xorout);
}

addcrc16("CRC-16", 0x8FAAU, 0x29B1U, 0x1021U, 0xFFFFU, 0, 0, 0x0000U);
addcrc16("CRC-16/CCITT-0", 0x8FAAU, 0x29B1U, 0x1021U, 0xFFFFU, 0, 0, 0x0000U);
addcrc16("CRC-16/ARC", 0xE78CU, 0xBB3DU, 0x8005U, 0x0000U, 1, 1, 0x0000U);
addcrc16("CRC-16/AUG-CCITT", 0x54A3U, 0xE5CCU, 0x1021U, 0x1D0FU, 0, 0, 0x0000U);
addcrc16("CRC-16/BUYPASS", 0xC772U, 0xFEE8U, 0x8005U, 0x0000U, 0, 0, 0x0000U);
addcrc16("CRC-16/CDMA2000", 0xA2C5U, 0x4C06U, 0xC867U, 0xFFFFU, 0, 0, 0x0000U);
addcrc16("CRC-16/DDS-110", 0x475BU, 0x9ECFU, 0x8005U, 0x800DU, 0, 0, 0x0000U);
addcrc16("CRC-16/DECT-R", 0x9854U, 0x007EU, 0x0589U, 0x0000U, 0, 0, 0x0001U);
addcrc16("CRC-16/DECT-X", 0x9855U, 0x007FU, 0x0589U, 0x0000U, 0, 0, 0x0000U);
addcrc16("CRC-16/DNP", 0x5F10U, 0xEA82U, 0x3D65U, 0x0000U, 1, 1, 0xFFFFU);
addcrc16("CRC-16/EN-13757", 0x0D60U, 0xC2B7U, 0x3D65U, 0x0000U, 0, 0, 0xFFFFU);
addcrc16("CRC-16/GENIBUS", 0x7055U, 0xD64EU, 0x1021U, 0xFFFFU, 0, 0, 0xFFFFU);
addcrc16("CRC-16/MAXIM", 0x1873U, 0x44C2U, 0x8005U, 0x0000U, 1, 1, 0xFFFFU);
addcrc16("CRC-16/MCRF4XX", 0x24BCU, 0x6F91U, 0x1021U, 0xFFFFU, 1, 1, 0x0000U);
addcrc16("CRC-16/RIELLO", 0x0FB0U, 0x63D0U, 0x1021U, 0xB2AAU, 1, 1, 0x0000U);
addcrc16("CRC-16/T10-DIF", 0xD885U, 0xD0DBU, 0x8BB7U, 0x0000U, 0, 0, 0x0000U);
addcrc16("CRC-16/TELEDISK", 0x3CEFU, 0x0FB3U, 0xA097U, 0x0000U, 0, 0, 0x0000U);
addcrc16("CRC-16/TMS37157", 0x8A0CU, 0x26B1U, 0x1021U, 0x89ECU, 1, 1, 0x0000U);
addcrc16("CRC-16/USB", 0x578DU, 0xB4C8U, 0x8005U, 0xFFFFU, 1, 1, 0xFFFFU);
addcrc16("CRC-16/A", 0xCE93U, 0xBF05U, 0x1021U, 0xC6C6U, 1, 1, 0x0000U);
addcrc16("CRC-16/KERMIT", 0x86E8U, 0x2189U, 0x1021U, 0x0000U, 1, 1, 0x0000U);
addcrc16("CRC-16/MODBUS", 0xA872U, 0x4B37U, 0x8005U, 0xFFFFU, 1, 1, 0x0000U);
addcrc16("CRC-16/X-25", 0xDB43U, 0x906EU, 0x1021U, 0xFFFFU, 1, 1, 0xFFFFU);
addcrc16("CRC-16/XMODEM", 0xA5EFU, 0x31C3U, 0x1021U, 0x0000U, 0, 0, 0x0000U);

private define addcrc32(name,r0,r1,poly,seed,refin,refout,xorout)
{
   addcrc (CRC32_Map, name,r0,r1,poly,seed,refin,refout,xorout);
}
addcrc32("CRC-32", 0x3CFE93B8U, 0xCBF43926U, 0x04C11DB7U, 0xFFFFFFFFU, 1, 1, 0xFFFFFFFFU);
addcrc32("CRC-32/BZIP2", 0x1CFC038AU, 0xFC891918U, 0x04C11DB7U, 0xFFFFFFFFU, 0, 0, 0xFFFFFFFFU);
addcrc32("CRC-32/C", 0xA3E98C0DU, 0xE3069283U, 0x1EDC6F41U, 0xFFFFFFFFU, 1, 1, 0xFFFFFFFFU);
addcrc32("CRC-32/D", 0x40A73E0DU, 0x87315576U, 0xA833982BU, 0xFFFFFFFFU, 1, 1, 0xFFFFFFFFU);
addcrc32("CRC-32/MPEG-2", 0xE303FC75U, 0x0376E6E7U, 0x04C11DB7U, 0xFFFFFFFFU, 0, 0, 0x00000000U);
addcrc32("CRC-32/POSIX", 0x4E7FDC75U, 0x765E7680U, 0x04C11DB7U, 0x00000000U, 0, 0, 0xFFFFFFFFU);
addcrc32("CRC-32/Q", 0x099A5C02U, 0x3010BF7FU, 0x814141ABU, 0x00000000U, 0, 0, 0x00000000U);
addcrc32("CRC-32/JAMCRC", 0xC3016C47U, 0x340BC6D9U, 0x04C11DB7U, 0xFFFFFFFFU, 1, 1, 0x00000000U);
addcrc32("CRC-32/XFER", 0x636909D5U, 0xBD0BE338U, 0x000000AFU, 0x00000000U, 0, 0, 0x00000000U);

private define test_crc_file (func, data)
{
   variable tmpfile = sprintf ("/tmp/test_crc_%d_%d", getpid(), _time());
   variable fp = fopen (tmpfile, "wb");
   if (fp == NULL)
     return;
   () = fwrite (data, fp);
   () = fclose (fp);
   variable s = (@func)(tmpfile;; __qualifiers);
   () = remove (tmpfile);
   return s;
}


private define check_crcmap (type, map, sumfunc, sumfile)
{
   foreach (assoc_get_keys (map))
     {
	variable key = ();
	variable s = map[key];

	variable cs, r;

	cs = chksum_new (type; seed=s.seed, poly=s.poly,
			 refin=s.refin, refout=s.refout, xorout=s.xorout);
	cs.accumulate (s.s0);
	r = cs.close();
	if (r != s.r0)
	  {
	     failed ("%S `%S' produced 0x%X, expected 0x%X",
		     key, s.s0, r, s.r0);
	  }

	cs = chksum_new (key);
	cs.accumulate (s.s0);
	r = cs.close();
	if (r != s.r0)
	  {
	     failed ("%S as key `%S' produced 0x%X, expected 0x%X",
		     key, s.s0, r, s.r0);
	  }

	cs = chksum_new (type; seed=s.seed, poly=s.poly,
			 refin=s.refin, refout=s.refout, xorout=s.xorout);
	foreach (s.s1)
	  {
	     variable ch = ();
	     cs.accumulate (char(ch));
	  }
	r = cs.close();
	if (r != s.r1)
	  {
	     failed ("%S `%S' produced 0x%X, expected 0x%X",
		     key, s.s1, r, s.r1);
	  }

	r = (@sumfunc)(s.s1;
		       seed=s.seed, poly=s.poly,
		       refin=s.refin, refout=s.refout, xorout=s.xorout);
	if (r != s.r1)
	  {
	     failed ("sumfunc=%S", sumfunc);
	  }

	r = test_crc_file (sumfile, s.s1;
			   seed=s.seed, poly=s.poly,
			   refin=s.refin, refout=s.refout, xorout=s.xorout);
	if (r != s.r1)
	  failed ("sumfile=%S", sumfile);
     }
}

private define test_module (module_name)
{
   testing_module (module_name);
   check_crcmap ("crc8", CRC8_Map, &crc8sum, &crc8sum_file);
   check_crcmap ("crc16", CRC16_Map, &crc16sum, &crc16sum_file);
   check_crcmap ("crc32", CRC32_Map, &crc32sum, &crc32sum_file);

   if (crc8_new().name != "crc8") failed ("crc8_new");
   if (crc16_new().name != "crc16") failed ("crc16_new");
   if (crc32_new().name != "crc32") failed ("crc32_new");
}

define slsh_main ()
{
   test_module ("chksum/crc");
   end_test ();
}

