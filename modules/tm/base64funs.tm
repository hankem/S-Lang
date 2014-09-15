\function{_base64_decoder_accumulate}
\synopsis{Accumulate data to be base64 decoded}
\usage{_base64_decoder_accumulate(Base64_Type b64, String_Type data)}
\description
  This routine adds a tring to the base64 decoder queue of the
  specifed Base64_Type object, previously instantiated using the
  \ifun{_base64_decoder_new}.

  See the documentation for \ifun{_base64_decoder_new} for more
  detailed usage.
\seealso{_base64_decoder_new, _base64_decoder_close, _base64_encoder_new}
\done

\function{_base64_decoder_new}
\synopsis{Intantiate a new base64 decoder}
\usage{Base64_Type _base64_decoder_new (Ref_Type func [,func_data])}
\description
  This routine returns instantiates a Base64_Type decoder object that
  may be used to decode base64 data.  It require a single
  \exmp{Ref_Type} parameter that is a reference to a callback function
  that the decoder will call with with (partially) decoded data.  The second
  argument, \exmp{func_data}, is optional.  If present it will also be
  passed to the callback function.

  The callback function must be defined to accept one or two
  parameters, depending upon whether the \ifun{_base64_decoder_new} function
  was called with the optional \exmp{func_data} argument.  If
  \exmp{func_data} was passed, then it will be passed as the first
  argument to the callback function.  The (partially) encoded string
  is passed as the last argument.  The callback function shall return
  nothing.
\example
  The following example defines a function that base64-decodes a string.
#v+
   private define decode_callback (strp, decoded_str)
   {
     @strp = @strp + decoded_str;
   }

   define b64decode_string (str)
   {
     variable b = ""B;     % The decoded string is binary
     variable b64 = _base64_decoder_new (&decode_callback, &b);
     _base64_decoder_accumulate (b64, str);
     _base64_decoder_close (b64);
     return b;
   }
#v-
\example
  The following example takes data from an input file pointer
  \exmp{fpin} and writes the decoded data to an output file pointer
  \exmp{fpout}:
#v+
   private define decoder_callback (fpout, data)
   {
      () = fwrite (data, fpout);
   }

   define base64_decode_file (fpin, fpout)
   {
      variable b64 = _base64_decoder_new (&encoder_callback, fpout);
      variable line;
      while (-1 != fgets (&line, fpin))
        _base64_decoder_accumulate (b64, line);
      _base64_decoder_close (b64);
   }
#v-
\seealso{_base64_decoder_accumulate, _base64_decoder_close, _base64_encoder_new}
\done

\function{_base64_decoder_close}
\synopsis{Flush and delete a base64 decoder}
\usage{_base64_decoder_close (Base64_Type b64)}
\description
  This function must be called when there is no more data for the
  specified base64 decoder to process.  See the documentation for
  \ifun{_base64_decoder_new} for additional information and usage.
\seealso{_base64_decoder_new, _base64_decoder_accumulate, _base64_encoder_close}
\done

\function{_base64_encoder_accumulate}
\synopsis{Accumulate data to be base64 encoded}
\usage{_base64_encoder_accumulate(Base64_Type b64, BString_Type data)}
\description
  This routine adds a binary string to the encoder queue of the
  specifed Base64_Type object, previously instantiated using the
  \ifun{_base64_encoder_new}.

  See the documentation for \ifun{_base64_encoder_new} for more
  detailed usage.
\seealso{_base64_encoder_new, _base64_encoder_close, _base64_decoder_new}
\done

\function{_base64_encoder_new}
\synopsis{Intantiate a new base64 encoder}
\usage{Base64_Type _base64_encoder_new (Ref_Type func [,func_data])}
\description
  This routine returns instantiates a Base64_Type decoder object that
  may be used to base64-encode data.  It require a single
  \exmp{Ref_Type} parameter that is a reference to a callback function
  that the encoder will call with the data to be encoded.  The second
  argument, \exmp{func_data}, is optional.  If present it will also be
  passed to the callback function.

  The callback function must be defined to accept one or two
  parameters, depending upon whether the \ifun{_base64_encoder_new} function
  was called with the optional \exmp{func_data} argument.  If
  \exmp{func_data} was passed, then it will be passed as the first
  argument to the callback function.  The (partially) encoded string
  is passed as the last argument.  The callback function shall return
  nothing.
\example
  The following example defines a function that base64 encodes a string.
#v+
   private define encode_callback (strp, encoded_str)
   {
     @strp = @strp + encoded_str;
   }

   define b64encode_string (bstr)
   {
     variable s = "";
     variable b64 = _base64_encoder_new (&encode_callback, &s);
     _base64_encoder_accumulate (b64, bstr);
     _base64_encoder_close (b64);
     return b;
   }
#v-
\example
  The following example takes data from an input file pointer
  \exmp{fpin} and writes the encoded data to an output file pointer
  \exmp{fpout}:
#v+
   private define encoder_callback (fpout, encoded_data)
   {
      () = fputs (encoded_data, fpout);
   }

   define define base64_encode_file (fpin, fpout)
   {
      variable b64 = _base64_encoder_new (&encoder_callback, fpout);
      variable bytes;
      while (-1 != fread_bytes (&bytes, 512, fpin))
        _base64_encoder_accumulate (b64, bytes);
      _base64_encoder_close (b64);
   }
#v-
\seealso{_base64_encoder_accumulate, _base64_encoder_close, _base64_decoder_new}
\done

\function{_base64_encoder_close}
\synopsis{Flush and delete a base64 encoder}
\usage{_base64_encoder_close (Base64_Type b64)}
\description
  This function must be called when there is no more data for the
  specified base64 encoder to process.  See the documentation for
  \ifun{_base64_encoder_new} for additional information and usage.
\seealso{_base64_encoder_new, _base64_encoder_accumulate, _base64_decoder_close}
\done

