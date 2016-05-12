() = evalfile ("./test.sl");
require ("base64");

private define decode_callback (strp, buf)
{
   @strp = @strp + buf;
}

private define b64encode_string (str, chunk)
{
   variable b = ""B;

   variable b64 = _base64_encoder_new (&decode_callback, &b);
   variable len = strbytelen (str);
   variable i = 0;

   if (chunk) while (i + chunk < len)
     {
	_base64_encoder_accumulate (b64, str[[i:i+chunk-1]]);
	i += chunk;
     }
   _base64_encoder_accumulate (b64, str[[i:]]);
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

private variable Random_Words = "\
weaselsnout phocomelus taiga recomposer grammarian bipeltate vicinage\r\n\
stoichiometry tufaceous resubstitute unparaphrased gey crystalloid\r\n\
Bretonian Caesareanize schlemiel floriform proximo uterus cloisonless\r\n\
proboscideous coacervate enthronize bitterhearted sorcerer cineraceous\r\n\
historically civilizatory nondispersal guipure hemiparaplegia uninodal\r\n\
symphilous overcuriously nieve scunder laparocolotomy subproblem\r\n\
encarpium macrochemistry unadornable encollar Cimmerian\r\n\
septendecennial delictum housecoat nudicaul nonbursting oysterroot\r\n\
stunningly Synentognathi prediscontented onofrite acapnial\r\n\
superspinous fibrinoplastin serrated Sabbatean lovely Hunkerism witful\r\n\
inflict yerk proreformist wheyness rouvillite swishy twigger\r\n\
onychonosus coterell nonabstract gonorrhea morglay turriform\r\n\
reforfeiture grailer kick profaneness pyrophorus reeshle\r\n\
coelomesoblast fordone posteroinferior haploscopic thig Catalaunian\r\n\
arkosic holometer ineptitude silverwork diphenylquinomethane bod\r\n\
untaintedly epifolliculitis basifugal geldant gymnocarpic gateado\r\n\
scumbling jetware\r\n\
";

private variable Encoded_Random_Words = "\
d2Vhc2Vsc25vdXQgcGhvY29tZWx1cyB0YWlnYSByZWNvbXBvc2VyIGdyYW1t\
YXJpYW4gYmlwZWx0YXRlIHZpY2luYWdlDQpzdG9pY2hpb21ldHJ5IHR1ZmFj\
ZW91cyByZXN1YnN0aXR1dGUgdW5wYXJhcGhyYXNlZCBnZXkgY3J5c3RhbGxv\
aWQNCkJyZXRvbmlhbiBDYWVzYXJlYW5pemUgc2NobGVtaWVsIGZsb3JpZm9y\
bSBwcm94aW1vIHV0ZXJ1cyBjbG9pc29ubGVzcw0KcHJvYm9zY2lkZW91cyBj\
b2FjZXJ2YXRlIGVudGhyb25pemUgYml0dGVyaGVhcnRlZCBzb3JjZXJlciBj\
aW5lcmFjZW91cw0KaGlzdG9yaWNhbGx5IGNpdmlsaXphdG9yeSBub25kaXNw\
ZXJzYWwgZ3VpcHVyZSBoZW1pcGFyYXBsZWdpYSB1bmlub2RhbA0Kc3ltcGhp\
bG91cyBvdmVyY3VyaW91c2x5IG5pZXZlIHNjdW5kZXIgbGFwYXJvY29sb3Rv\
bXkgc3VicHJvYmxlbQ0KZW5jYXJwaXVtIG1hY3JvY2hlbWlzdHJ5IHVuYWRv\
cm5hYmxlIGVuY29sbGFyIENpbW1lcmlhbg0Kc2VwdGVuZGVjZW5uaWFsIGRl\
bGljdHVtIGhvdXNlY29hdCBudWRpY2F1bCBub25idXJzdGluZyBveXN0ZXJy\
b290DQpzdHVubmluZ2x5IFN5bmVudG9nbmF0aGkgcHJlZGlzY29udGVudGVk\
IG9ub2ZyaXRlIGFjYXBuaWFsDQpzdXBlcnNwaW5vdXMgZmlicmlub3BsYXN0\
aW4gc2VycmF0ZWQgU2FiYmF0ZWFuIGxvdmVseSBIdW5rZXJpc20gd2l0ZnVs\
DQppbmZsaWN0IHllcmsgcHJvcmVmb3JtaXN0IHdoZXluZXNzIHJvdXZpbGxp\
dGUgc3dpc2h5IHR3aWdnZXINCm9ueWNob25vc3VzIGNvdGVyZWxsIG5vbmFi\
c3RyYWN0IGdvbm9ycmhlYSBtb3JnbGF5IHR1cnJpZm9ybQ0KcmVmb3JmZWl0\
dXJlIGdyYWlsZXIga2ljayBwcm9mYW5lbmVzcyBweXJvcGhvcnVzIHJlZXNo\
bGUNCmNvZWxvbWVzb2JsYXN0IGZvcmRvbmUgcG9zdGVyb2luZmVyaW9yIGhh\
cGxvc2NvcGljIHRoaWcgQ2F0YWxhdW5pYW4NCmFya29zaWMgaG9sb21ldGVy\
IGluZXB0aXR1ZGUgc2lsdmVyd29yayBkaXBoZW55bHF1aW5vbWV0aGFuZSBi\
b2QNCnVudGFpbnRlZGx5IGVwaWZvbGxpY3VsaXRpcyBiYXNpZnVnYWwgZ2Vs\
ZGFudCBneW1ub2NhcnBpYyBnYXRlYWRvDQpzY3VtYmxpbmcgamV0d2FyZQ0K";

list_append (Encode_Decode_Map, Random_Words);
list_append (Encode_Decode_Map, Encoded_Random_Words);

define slsh_main ()
{
   testing_module ("base64");

   variable i, n = length (Encode_Decode_Map)/2;
   variable chunk, in, out, testout;
   variable chunks = [0, 1, 2, 3, 4, 5, 23, 47, 71, 103];
   foreach chunk (chunks)
     {
	_for i (0, n-1, 1)
	  {
	     in = Encode_Decode_Map[2*i];
	     out = Encode_Decode_Map[2*i+1];
	     testout = b64encode_string (in, chunk);

	     if (out != testout)
	       failed ("to encode %s, got %s instead of %s", in, testout, out);
	  }
     }

   foreach chunk (chunks)
     {
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
	testout = b64decode_string (in, 7, 0);
     }

   end_test ();
}
