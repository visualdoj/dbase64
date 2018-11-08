{$MODE FPC}
{$MODESWITCH OUT}
{$MODESWITCH RESULT}
uses
  strings,
  dbase64;

// Test compilation of examples
      function ExampleEncodeBase64(Data: Pointer; Size: SizeUint): AnsiString;
      begin
        // Set resulting string to size needed for encoded data
        SetLength(Result, GetEncodedBase64Size(Size));
        // Encode
        EncodeBase64(Data, Size, @Result[1]);
      end;

      // decode and save result to string
      function ExampleDecodeBase64(Data: Pointer; Size: SizeUInt): AnsiString;
      var
        OutSize: SizeUInt;
      begin
        // allocate memory for decoding
        SetLength(Result, GetDecodedBase64Size(Size));
        // decode and get actual decoded size
        OutSize := DecodeBase64(Data, Size, @Result[1]);
        // truncate result string to this size
        SetLength(Result, OutSize);
      end;

      // decode "in-place" and return size of decoded data
      function ExampleDecodeInPlace(Data: Pointer; Size: SizeUInt): SizeUInt;
      begin
        Result := DecodeBase64(Data, Size, Data);
      end;

procedure Assert(B: Boolean; Msg: PAnsiChar);
begin
  if not B then
    Writeln(Msg);
end;

function DumpLineToStr(P: PByte; Size: LongInt): AnsiString;
var
  I: LongInt;
begin
  Result := '';
  for I := 0 to 15 do begin
    if Size > I then begin
      Result := Result + HexStr(P[I], 2);
    end else
      Result := Result + '  ';
    if I mod 4 = 3 then
      Result := Result + '  ';
  end;
  Result := Result + '| ';
  for I := 0 to 15 do begin
    if Size <= I then
      break;
    if (P[I] >= 32) and (P[I] < 127) then begin
      Result := Result + Char(P[I])
    end else
      Result := Result + '?';
  end;
end;

function DumpToStr(P: Pointer; Size: LongInt): AnsiString;
begin
  Result := '';
  while Size > 0 do begin
    if Size >= 16 then begin
      Result := Result + DumpLineToStr(P, 16) + LineEnding;
      Size := Size - 16;
      Inc(P, 16);
    end else begin
      Result := Result + DumpLineToStr(P, Size) + LineEnding;
      Break;
    end;
  end;
end;

procedure Dump(P: Pointer; Size: LongInt);
begin
  Write(DumpToStr(P, Size));
end;

procedure TestDecode(Buf: PAnsiChar; Valid: Boolean);
var
  Data: array of AnsiChar;
  E: PByte;
  Cursor: PAnsiChar;
begin
  if (ValidateBase64(Buf, StrLen(Buf), Cursor) = BASE64_VALID) <> Valid then begin
    Writeln('Wrong ValidateBase64 result for ', Buf);
    Writeln('                                ', Space(Cursor - Buf), '^');
  end;
  SetLength(Data, StrLen(Buf));
  Move(Buf^, Data[0], StrLen(Buf));
  E := DecodeBase64(@Data[0], @Data[Length(Data)], @Data[0]);
  Dump(@Data[0], E - PByte(@Data[0]));
end;

procedure TestEncode(Buf: PAnsiChar);
var
  S: AnsiString;
begin
  SetLength(S, GetEncodedBase64Size(StrLen(Buf)));
  EncodeBase64(PByte(Buf), StrLen(Buf), @S[1]);
  if S <> '' then begin
    Writeln(S);
  end else
    Writeln(' (empty string)');
end;

procedure TestDecodeUrl(Buf: PAnsiChar; Valid: Boolean);
var
  Data: array of AnsiChar;
  E: PByte;
  Cursor: PAnsiChar;
begin
  if (ValidateBase64Url(Buf, StrLen(Buf), Cursor) = BASE64_VALID) <> Valid then begin
    Writeln('Wrong ValidateBase64Url result for ', Buf);
    Writeln('                                   ', Space(Cursor - Buf), '^');
  end;
  SetLength(Data, StrLen(Buf));
  Move(Buf^, Data[0], StrLen(Buf));
  E := DecodeBase64Url(@Data[0], @Data[Length(Data)], @Data[0]);
  Dump(@Data[0], E - PByte(@Data[0]));
end;

procedure TestEncodeUrl(Buf: PAnsiChar);
var
  S: AnsiString;
begin
  SetLength(S, GetEncodedBase64Size(StrLen(Buf)));
  EncodeBase64Url(PByte(Buf), StrLen(Buf), @S[1]);
  if S <> '' then begin
    Writeln(S);
  end else
    Writeln(' (empty string)');
end;

const
  CPU_STRING = {$IF Defined(CPUARM)} 'arm'
               {$ELSEIF Defined(CPUAVR)} 'avr'
               {$ELSEIF Defined(CPUAMD64) or Defined(CPUX86_64)} 'intel-64'
               {$ELSEIF Defined(CPU68) or Defined(CPU86K) or Defined(CPUM68K)} 'Motorola 680x0'
               {$ELSEIF Defined(CPUPOWERPC) or Defined(CPUPOWERPC32) or Defined(CPUPOWERPC64)} 'PowerPC'
               {$ELSEIF Defined(CPU386) or Defined(CPUi386)} 'i386'
               {$ELSE} 'uknown arch'
               {$ENDIF};
  ENDIAN_STRING = {$IF Defined(ENDIAN_LITTLE)}{$IF Defined(ENDIAN_BIG)}'little/big endian'{$ELSE}'little endian'{$ENDIF}
                  {$ELSE}{$IF Defined(ENDIAN_BIG)}'big endian'{$ELSE}'unknown endian'{$ENDIF}{$ENDIF};
  BITS_STRING = {$IF Defined(CPU64)}'64'{$ELSEIF Defined(CPU32)}'32'{$ELSEIF Defined(CPU16)}'16'{$ELSE}'?'{$ENDIF};
  OS_STRING = {$IF Defined(AMIGA)} 'amiga'
              {$ELSEIF Defined(ATARI)} 'Atari'
              {$ELSEIF Defined(GO32V2) or Defined(DPMI)} 'MS-DOS go32v2'
              {$ELSEIF Defined(MACOS)} 'Classic Macintosh'
              {$ELSEIF Defined(MSDOS)} 'MS-DOS'
              {$ELSEIF Defined(OS2)} 'OS2'
              {$ELSEIF Defined(EMX)} 'EMX'
              {$ELSEIF Defined(PALMOS)} 'PalmOS'
              {$ELSEIF Defined(BEOS)} 'BeOS'
              {$ELSEIF Defined(DARWIN)} 'MacOS or iOS'
              {$ELSEIF Defined(FREEBSD)} 'FreeBSD'
              {$ELSEIF Defined(NETBSD)} 'NetBSD'
              {$ELSEIF Defined(SUNOS)} 'SunOS'
              {$ELSEIF Defined(SOLARIS)} 'Solaris'
              {$ELSEIF Defined(QNX)} 'QNX RTP'
              {$ELSEIF Defined(LINUX)} 'Linux'
              {$ELSEIF Defined(UNIX)} 'Unix'
              {$ELSEIF Defined(WIN32)} '32-bit Windows'
              {$ELSEIF Defined(WIN64)} '64-bit Windows'
              {$ELSEIF Defined(WINCE)} 'Windows CE or Windows Mobile'
              {$ELSEIF Defined(WINDOWS)} 'Windows'
              {$ELSE} 'Unknown OS'
              {$ENDIF};
  PLATFORM_STRING = CPU_STRING + ' ' + BITS_STRING + '-bits (' + ENDIAN_STRING + '), ' + OS_STRING;

begin
  Write(stderr, PLATFORM_STRING);
  Writeln(stderr);
  TestEncode('Hello world!');
  TestEncode('Hello world!!');
  TestEncode('Hello world!!!');
  TestEncode('abc123!?$*&()''-=@~');
  TestEncodeUrl('abc123!?$*&()''-=@~');
  TestDecode('TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlzIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2YgdGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGludWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRoZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4=', True);
  TestEncode('Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure.');

  Writeln;
  Writeln('RFC-4648 test vectors');
  TestEncode('');
  TestEncode('f');
  TestEncode('fo');
  TestEncode('foo');
  TestEncode('foob');
  TestEncode('fooba');
  TestEncode('foobar');
  TestDecode('', True);
  TestDecode('Zg==', True);
  TestDecode('Zm8=', True);
  TestDecode('Zm9v', True);
  TestDecode('Zm9vYg==', True);
  TestDecode('Zm9vYmE=', True);
  TestDecode('Zm9vYmFy', True);
  TestEncodeUrl('');
  TestEncodeUrl('f');
  TestEncodeUrl('fo');
  TestEncodeUrl('foo');
  TestEncodeUrl('foob');
  TestEncodeUrl('fooba');
  TestEncodeUrl('foobar');
  TestDecodeUrl('', True);
  TestDecodeUrl('Zg==', True);
  TestDecodeUrl('Zm8=', True);
  TestDecodeUrl('Zm9v', True);
  TestDecodeUrl('Zm9vYg==', True);
  TestDecodeUrl('Zm9vYmE=', True);
  TestDecodeUrl('Zm9vYmFy', True);

  Writeln;
  Writeln('Some cases with + and /');
  TestEncode(#$FF#$EF);
  TestDecode('/+8=', True);
  TestEncodeUrl(#$FF#$EF);
  TestDecodeUrl('_-8=', True);

  Writeln;
  Writeln('Some cases with garbage inside or truncated');
  TestDecode('Z[m](9)v-_', False);
  TestDecode('Z    m'#13#10'   9   vYg-_==', False);
  TestDecode('Z[m]9vY(m)-_E=', False);
  TestDecode('Z,m,9,v,Y,m,F,y-_', False);
  TestDecode('/+8', False);
  TestDecode('Zm9vYg', False);
  TestDecodeUrl('Z[m](9)v+/', False);
  TestDecodeUrl('Z    m'#13#10'   9   vYg+/==', False);
  TestDecodeUrl('Z[m]9vY(m)+/E=', False);
  TestDecodeUrl('Z,m,9,v,Y,m,F,y+/', False);
  TestDecodeUrl('_-8', True);
  TestDecodeUrl('Zm9vYg', True);

  Assert(DecodeBase64Char('A') =  0, 'Wrong base64 A -> 6-bits!');
  Assert(DecodeBase64Char('Z') = 25, 'Wrong base64 Z -> 6-bits!');
  Assert(DecodeBase64Char('a') = 26, 'Wrong base64 a -> 6-bits!');
  Assert(DecodeBase64Char('z') = 51, 'Wrong base64 z -> 6-bits!');
  Assert(DecodeBase64Char('0') = 52, 'Wrong base64 0 -> 6-bits!');
  Assert(DecodeBase64Char('9') = 61, 'Wrong base64 9 -> 6-bits!');
  Assert(DecodeBase64Char('+') = 62, 'Wrong base64 + -> 6-bits!');
  Assert(DecodeBase64Char('/') = 63, 'Wrong base64 / -> 6-bits!');
  Assert(DecodeBase64Char('-') = -1, 'Wrong base64 - -> 6-bits!');
  Assert(DecodeBase64Char('_') = -1, 'Wrong base64 _ -> 6-bits!');
  Assert(DecodeBase64UrlChar('A') =  0, 'Wrong base64url A -> 6-bits!');
  Assert(DecodeBase64UrlChar('Z') = 25, 'Wrong base64url Z -> 6-bits!');
  Assert(DecodeBase64UrlChar('a') = 26, 'Wrong base64url a -> 6-bits!');
  Assert(DecodeBase64UrlChar('z') = 51, 'Wrong base64url z -> 6-bits!');
  Assert(DecodeBase64UrlChar('0') = 52, 'Wrong base64url 0 -> 6-bits!');
  Assert(DecodeBase64UrlChar('9') = 61, 'Wrong base64url 9 -> 6-bits!');
  Assert(DecodeBase64UrlChar('+') = -1, 'Wrong base64url + -> 6-bits!');
  Assert(DecodeBase64UrlChar('/') = -1, 'Wrong base64url / -> 6-bits!');
  Assert(DecodeBase64UrlChar('-') = 62, 'Wrong base64url - -> 6-bits!');
  Assert(DecodeBase64UrlChar('_') = 63, 'Wrong base64url _ -> 6-bits!');
end.
