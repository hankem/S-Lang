prepend_to_slang_load_path (".");
set_import_module_path ("./objs:" + get_import_module_path ());
require ("base64");

private define decode_callback (strp, buf)
{
   @strp = @strp + buf;
}

private define b64encode_string (str)
{
   variable b = ""B;

   variable b64 = _base64_encoder_new (&decode_callback, &b);
   _base64_encoder_accumulate (b64, str);
   _base64_encoder_close (b64);

   return b;
}

private variable Encode_Decode_Map =
{
   "1", "MQ==",
   "12","MTI=",
   "123", "MTIz",
   "1234", "MTIzNA==",

   "Four score and seven years ago",
   "Rm91ciBzY29yZSBhbmQgc2V2ZW4geWVhcnMgYWdv",

   "Four score and seven years ago our fathers brought forth on this continent a new nation, conceived in liberty, and dedicated to the proposition that all men are created equal.",
   "Rm91ciBzY29yZSBhbmQgc2V2ZW4geWVhcnMgYWdvIG91ciBmYXRoZXJzIGJyb3VnaHQgZm9ydGggb24gdGhpcyBjb250aW5lbnQgYSBuZXcgbmF0aW9uLCBjb25jZWl2ZWQgaW4gbGliZXJ0eSwgYW5kIGRlZGljYXRlZCB0byB0aGUgcHJvcG9zaXRpb24gdGhhdCBhbGwgbWVuIGFyZSBjcmVhdGVkIGVxdWFsLg==",
};

define slsh_main ()
{
   variable i, n = length (Encode_Decode_Map)/2;
   variable failed = 0;
   _for i (0, n-1, 1)
     {
	variable in = Encode_Decode_Map[2*i];
	variable out = Encode_Decode_Map[2*i+1];
	variable testout = b64encode_string (in);

	if (out == testout)
	  continue;

	() = fprintf (stderr, "FAILED to encode %s, got %s instead of %s\n",
		      in, testout, out);
	failed++;
     }

   if (failed)
     exit (1);

   exit (0);
}
