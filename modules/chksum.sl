import ("chksum");

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
   return struct
     {
	obj = _chksum_new (name),
	accumulate = &chksum_accumulate,
	close = &chksum_close,
	name = name,
     };
}

define md5sum_new ()
{
   return chksum_new ("md5");
}

define sha1sum_new ()
{
   return chksum_new ("sha1");
}

define md5sum (str)
{
   variable c = _chksum_new ("md5");
   _chksum_accumulate (c, str);
   return _chksum_close (c);
}

define sha1sum (str)
{
   variable c = _chksum_new ("sha1");
   _chksum_accumulate (c, str);
   return _chksum_close (c);
}

define chksum_file (file, type)
{
   variable fp = fopen (file, "rb");
   if (fp == NULL)
     throw OpenError, "Error opening $file";

   variable c = _chksum_new (type);

   variable buf;
   while (-1 != fread_bytes (&buf, 4096, fp))
     {
	_chksum_accumulate (c, buf);
     }
   return _chksum_close (c);
}

define md5sum_file (file)
{
   return chksum_file (file, "md5");
}

define sha1sum_file (file)
{
   return chksum_file (file, "sha1");
}
