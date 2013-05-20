() = evalfile ("./test.sl");
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

private define b64decode_string (str, chunk, do_close)
{
   variable b = ""B;

   variable b64 = _base64_decoder_new (&decode_callback, &b);
   variable len = strbytelen (str);
   variable i = 0;
   if (chunk) while (i + chunk < len)
     {
	_base64_decoder_accumulate (b64, str[[i:i+chunk-1]]);
	i += chunk;
     }
   _base64_decoder_accumulate (b64, str[[i:]]);
   if (do_close) _base64_decoder_close (b64);

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
   testing_module ("base64");

   variable i, n = length (Encode_Decode_Map)/2;
   variable in, out, testout;
   _for i (0, n-1, 1)
     {
	in = Encode_Decode_Map[2*i];
	out = Encode_Decode_Map[2*i+1];
	testout = b64encode_string (in);

	if (out != testout)
	  failed ("to encode %s, got %s instead of %s", in, testout, out);
     }

   _for (0, 5, 1)
     {
	variable chunk = ();
	_for i (0, n-1, 1)
	  {
	     out = Encode_Decode_Map[2*i];
	     in = Encode_Decode_Map[2*i+1];
	     testout = b64decode_string (in, chunk, 1);

	     if (out == testout)
	       {
		  % test again, without the pad chars
		  in = strtrans (in, "=", "");
		  testout = b64decode_string (in, chunk, 1);
		  if (out == testout)
		    continue;
	       }
	     failed ("to decode %s, chunk=%d", in, chunk);
	  }
     }

   % don't close -- test for leaks
   _for i (0, n-1, 1)
     {
	out = Encode_Decode_Map[2*i];
	in = Encode_Decode_Map[2*i+1];
	testout = b64decode_string (in, chunk, 0);
     }

   end_test ();
}
