{
    RFC-2045 https://tools.ietf.org/html/rfc2045#section-6.8
    RFC-3548 https://tools.ietf.org/html/rfc3548#page-4
    RFC-4648 https://tools.ietf.org/html/rfc4648#section-5
}
{$MODE FPC}
{$MODESWITCH OUT}
{$MODESWITCH RESULT}
unit dbase64;

interface

//
//  GetEncodedBase64Size
//  GetEncodedBase64UrlSize
//
//      Computes size of encoded data. See example for EncodeBase64 below
//
//  Parameters:
//
//      Size: the size of input data
//
//  Returns:
//
//      Result: the exact size of encoded data
//
function GetEncodedBase64Size(Size: SizeUInt): SizeUInt; inline;
function GetEncodedBase64UrlSize(Size: SizeUInt): SizeUInt; inline;

//
//  EncodeBase64
//  EncodeBase64Url
//
//      Encodes data to base64 or base64url
//
//      Output buffer must point to memory enough
//      for store encoded data. That is, at least
//      GetEncodedBase64Size(Size)
//
//  Parameters:
//
//      Data:      a pointer to input data
//                 It must be valid pointer to memory with at least Size bytes
//                 Data=nil is legal NOOP
//      Size:      size of input data in bytes
//      DataEnd:   pointer to the end of input data.
//                 That is, DataEnd = Data + Size
//      OutBuffer: pointer to the beginning of output buffer
//
//  Returns:
//
//      Result (SizeUInt): size of encoded data
//      Result (PAnsiChar): end of encoded data
//
//  Examples:
//
//      // Encode to base64 and save result to AnsiString
//      function ExampleEncodeBase64(Data: Pointer; Size: SizeUint): AnsiString;
//      begin
//        // Set resulting string to size needed for encoded data
//        SetLength(Result, GetEncodedBase64Size(Size));
//        // Encode
//        EncodeBase64(Data, Size, @Result[1]);
//      end;
//
function EncodeBase64(Data: PByte; Size: SizeUInt; OutBuffer: PAnsiChar): SizeUInt; inline;
function EncodeBase64(Data, DataEnd: PByte; OutBuffer: PAnsiChar): PAnsiChar; inline;
function EncodeBase64Url(Data: PByte; Size: SizeUInt; OutBuffer: PAnsiChar): SizeUInt; inline;
function EncodeBase64Url(Data, DataEnd: PByte; OutBuffer: PAnsiChar): PAnsiChar;

//
//  GetDecodedBase64Size
//  GetDecodedBase64UrlSize
//
//      Computes maximum size of memory required for decoded data.
//
//      It DOES NOT compute exact size of decoded data because
//      encoded data may contain non-base64 characters and, as
//      specified in RFC 2045, they must be ignored by decoder.
//      For example, the following lines
//
//            aGVsbG8=
//            aGVs bG8=
//            a$GV(sb#G)8=
//
//      are different in size, but all encode the same "hello" string.
//
//  Parameters:
//
//      Size: size of encoded base64 data
//
//  Returns:
//
//      Result: maximum required size for store decoded data
//
function GetDecodedBase64Size(Size: SizeUInt): SizeUInt; inline;
function GetDecodedBase64UrlSize(Size: SizeUInt): SizeUInt; inline;

//
//  DecodeBase64Char
//  DecodeBase64UrlChar
//
//      Decodes a base64 character. Can be used for validation
//
//  Parameters:
//
//      C: character
//
//  Returns:
//
//      Result:
//          0..63 - decoded 6-bit sequence
//             -1 - C is not a base64 character
//             -2 - C is padding character '='
//
function DecodeBase64Char(C: AnsiChar): LongInt; inline;
function DecodeBase64UrlChar(C: AnsiChar): LongInt; inline;

//
//  ValidateBase64        - for "strict" base64, aka RFC-3548
//  ValidateBase64Url     - for base64url
//
//      Checks if input data is valid base64 encoded data
//
//      It is not required to validate data before call
//      DecodeBase64 or DecodeBase64Url.
//
//  Parameters:
//
//      Data:      pointer to encoded base64 data
//                 Data=nil is legal NOOP
//      Size:      size of encoded base64 data in bytes
//      DataEnd:   pointer to end of input base64 data
//                 That is, DataEnd = Data + Size
//
//  Returns:
//
//      Cursor: meaning depends on Result
//      Result: BASE64_VALID - this is correct base64 encoded data,
//                             Cursor=DataEnd
//              BASE64_INVALID_CHARACTER - input data contains invalid char
//                             Cursor points to this invalid character
//              BASE64_TRUNCATED - number of characters is not divided by 4
//                             Cursor points to beginning of the data
//
type
  TBase64ValidatorResult = (
    BASE64_VALID = 0,
    BASE64_INVALID_CHARACTER,
    BASE64_TRUNCATED
  );
function ValidateBase64(Data: PAnsiChar; Size: SizeUInt; out Cursor: PAnsiChar): TBase64ValidatorResult; inline;
function ValidateBase64(Data, DataEnd: PAnsiChar; out Cursor: PAnsiChar): TBase64ValidatorResult;
function ValidateBase64Url(Data: PAnsiChar; Size: SizeUInt; out Cursor: PAnsiChar): TBase64ValidatorResult; inline;
function ValidateBase64Url(Data, DataEnd: PAnsiChar; out Cursor: PAnsiChar): TBase64ValidatorResult;

//
//  DecodeBase64
//  DecodeBase64Url
//
//      Decodes base64 data
//
//      These functions do not validate input data, they just skip invalid
//      characters and ignore paddings. This behaviour corresponds to original
//      base64 specification in RFC-2045. If you want to validate data before
//      decode, use ValidateBase64 or ValidateBase64Url.
//
//      This function can be used for "in-place" decoding.
//      That is, you can pass to OutBuffer the same pointer as you pass to Data:
//
//          DataEnd := DecodeBase64(Data, Size, Data);
//
//      Base64 data is always greater than decoded output, so this call
//      guarantees that the data will not be damaged (just rewrited).
//
//  Parameters:
//
//      Data:      pointer to the input base64 data
//                 It must be valid pointer to memory with at least Size bytes
//                 Data=nil is legal NOOP
//      Size:      size of input base64 data in bytes
//      DataEnd:   pointer to end of input base64 data
//                 That is, DataEnd = Data + Size
//      OutBuffer: pointer to the output buffer
//
//  Returns:
//
//      Result (SizeUInt): effective size of decoded data in bytes
//      Result (PByte): pointer to end of decoded data
//                    That is, Result-OutBuffer is size of decoded data in bytes
//
//  Examples:
//
//      // decode and save result to string
//      function ExampleDecodeBase64(Data: Pointer; Size: SizeUInt): AnsiString;
//      var
//        OutSize: SizeUInt;
//      begin
//        // allocate memory for decoding
//        SetLength(Result, GetDecodedBase64Size(Size));
//        // decode and get actual decoded size
//        OutSize := DecodeBase64(Data, Size, @Result[1]);
//        // truncate result string to actual size
//        SetLength(Result, OutSize);
//      end;
//
//      // decode "in-place" and return size of decoded data
//      function ExampleDecodeInPlace(Data: Pointer; Size: SizeUInt): SizeUInt;
//      begin
//        Result := DecodeBase64(Data, Size, Data);
//      end;
//
function DecodeBase64(Data: PAnsiChar; Size: SizeUInt; OutBuffer: PByte): SizeUInt; inline;
function DecodeBase64(Data, DataEnd: PAnsiChar; OutBuffer: PByte): PByte; inline;
function DecodeBase64Url(Data: PAnsiChar; Size: SizeUInt; OutBuffer: PByte): SizeUInt; inline;
function DecodeBase64Url(Data, DataEnd: PAnsiChar; OutBuffer: PByte): PByte; inline;

implementation

const
  BASE64_ENCODING_TABLE: array[0 .. 63] of AnsiChar =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
    'abcdefghijklmnopqrstuvwxyz' +
    '0123456789+/';

  BASE64_DECODING_TABLE: array[0 .. 79] of ShortInt = (
    62, -1, -1, -1, 63, 52, 53, 54, 55, 56,
    57, 58, 59, 60, 61, -1, -1, -1, -2, -1,
    -1, -1,  0,  1,  2,  3,  4,  5,  6,  7,
     8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
    18, 19, 20, 21, 22, 23, 24, 25, -1, -1,
    -1, -1, -1, -1, 26, 27, 28, 29, 30, 31,
    32, 33, 34, 35, 36, 37, 38, 39, 40, 41,
    42, 43, 44, 45, 46, 47, 48, 49, 50, 51
  );

//
//  I don''t want to include second table in executable.
//  Instead, I just use BASE64_DECODING_TABLE to compute
//  content of the table in the initialization of the unit.
//
//  BASE64URL_DECODING_TABLE: array[0 .. 79] of ShortInt = (
//    -1, -1, 62, -1, -1, 52, 53, 54, 55, 56,
//    57, 58, 59, 60, 61, -1, -1, -1, -2, -1,
//    -1, -1,  0,  1,  2,  3,  4,  5,  6,  7,
//     8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
//    18, 19, 20, 21, 22, 23, 24, 25, -1, -1,
//    -1, -1, 63, -1, 26, 27, 28, 29, 30, 31,
//    32, 33, 34, 35, 36, 37, 38, 39, 40, 41,
//    42, 43, 44, 45, 46, 47, 48, 49, 50, 51
//  );
//
var
  BASE64URL_DECODING_TABLE: array[0 .. 79] of ShortInt;

function GetEncodedBase64Size(Size: SizeUInt): SizeUInt;
begin
  Result := ((Size + 2) div 3) * 4;
end;

function GetEncodedBase64UrlSize(Size: SizeUInt): SizeUInt;
begin
  Result := GetEncodedBase64Size(Size);
end;

function _EncodeBase64(Data, DataEnd: PByte; OutBuffer: PAnsiChar): PAnsiChar;
var
  C: Cardinal;
begin
  if Data = nil then
    Exit(OutBuffer);
  while DataEnd - Data > 2 do begin
    C := Cardinal(Pointer(Data)^);
{$IFDEF ENDIAN_LITTLE}
    OutBuffer[0] := BASE64_ENCODING_TABLE[(C shr 2) and $3f];
    OutBuffer[1] := BASE64_ENCODING_TABLE[((C shr 12) and $f) or ((C and $3) shl 4)];
    OutBuffer[2] := BASE64_ENCODING_TABLE[((C shr 22) and $3) or ((C shr 6) and $3C)];
    OutBuffer[3] := BASE64_ENCODING_TABLE[(C shr 16) and $3f];
{$ELSE}
    OutBuffer[0] := BASE64_ENCODING_TABLE[(C shr 26) and $3f];
    OutBuffer[1] := BASE64_ENCODING_TABLE[(C shr 20) and $3f];
    OutBuffer[2] := BASE64_ENCODING_TABLE[(C shr 14) and $3f];
    OutBuffer[3] := BASE64_ENCODING_TABLE[(C shr 8) and $3f];
{$ENDIF}
    Inc(Data, 3);
    Inc(OutBuffer, 4);
  end;
  if DataEnd - Data = 2 then begin
    C := Word(Pointer(Data)^);
{$IFDEF ENDIAN_LITTLE}
    OutBuffer[0] := BASE64_ENCODING_TABLE[(C shr 2) and $3f];
    OutBuffer[1] := BASE64_ENCODING_TABLE[((C shr 12) and $F) or ((C shl 4) and $30)];
    OutBuffer[2] := BASE64_ENCODING_TABLE[(C shr 6) and $3C];
{$ELSE}
    OutBuffer[0] := BASE64_ENCODING_TABLE[C shr 10];
    OutBuffer[1] := BASE64_ENCODING_TABLE[(C shr 4) and $3f];
    OutBuffer[2] := BASE64_ENCODING_TABLE[(C shl 2) and $3f];
{$ENDIF}
    OutBuffer[3] := '=';
    Exit(OutBuffer + 4);
  end else if DataEnd - Data = 1 then begin
    C := Data^;
    OutBuffer[0] := BASE64_ENCODING_TABLE[C shr 2];
    OutBuffer[1] := BASE64_ENCODING_TABLE[(C shl 4) and $30];
    OutBuffer[2] := '=';
    OutBuffer[3] := '=';
    Exit(OutBuffer + 4);
  end;
  Result := OutBuffer;
end;

function EncodeBase64(Data: PByte; Size: SizeUInt; OutBuffer: PAnsiChar): SizeUInt;
begin
  Result := _EncodeBase64(Data, Data + Size, OutBuffer) - OutBuffer;
end;

function EncodeBase64(Data, DataEnd: PByte; OutBuffer: PAnsiChar): PAnsiChar;
begin
  Result := _EncodeBase64(Data, DataEnd, OutBuffer);
end;

function EncodeBase64Url(Data: PByte; Size: SizeUInt; OutBuffer: PAnsiChar): SizeUInt;
begin
  Result := EncodeBase64Url(Data, Data + Size, OutBuffer) - OutBuffer;
end;

procedure _Translate(Data: PAnsiChar; Size: SizeInt; From, _To: AnsiChar);
var
  L: LongInt;
begin
  L := IndexChar(Data^, Size, From);
  while L <> -1 do begin
    Data[L] := _To;
    Inc(Data, L);
    Dec(Size, L);
    L := IndexChar(Data^, Size, From);
  end;
end;

function EncodeBase64Url(Data, DataEnd: PByte; OutBuffer: PAnsiChar): PAnsiChar;
begin
  if Data = nil then
    Exit(OutBuffer);
  Result := _EncodeBase64(Data, DataEnd, OutBuffer);
  _Translate(OutBuffer, Result - OutBuffer, '+', '-');
  _Translate(OutBuffer, Result - OutBuffer, '/', '_');
end;

function GetDecodedBase64Size(Size: SizeUInt): SizeUInt;
begin
  Result := ((Size + 3) div 4) * 3;
end;

function GetDecodedBase64UrlSize(Size: SizeUInt): SizeUInt;
begin
  Result := GetDecodedBase64Size(Size);
end;

function _DecodeBase64Char(C: LongInt; Url: Boolean): LongInt; inline;
begin
  Result := C - 43;
  if (Result < 0) or (Result > High(BASE64_DECODING_TABLE)) then
    Exit(-1);
  if Url then begin
    Result := BASE64URL_DECODING_TABLE[Result];
  end else
    Result := BASE64_DECODING_TABLE[Result];
end;

function DecodeBase64Char(C: AnsiChar): LongInt;
begin
  Result := _DecodeBase64Char(Ord(C), False);
end;

function DecodeBase64UrlChar(C: AnsiChar): LongInt;
begin
  Result := _DecodeBase64Char(Ord(C), True);
end;

function _DecodeBase64(Data, DataEnd: PAnsiChar; OutBuffer: PByte; Url: Boolean): PByte;
label
  LByte1, LByte2, LByte3, LByte4;
var
  L: LongInt;
begin
  if Data = nil then
    Exit(OutBuffer);

  while Data < DataEnd do begin
LByte1:
    L := _DecodeBase64Char(Byte(Data^), Url);
    if L < 0 then begin
      Inc(Data);
      if Data >= DataEnd then
        Exit(OutBuffer);
      goto LByte1;
    end;
    OutBuffer[0] := (L and $3F) shl 2;

LByte2:
    Inc(Data);
    if Data >= DataEnd then begin
      Exit(OutBuffer);
    end;
    L := _DecodeBase64Char(Byte(Data^), Url);
    if L < 0 then begin
      goto LByte2;
    end;
    OutBuffer[0] := OutBuffer[0] or ((L and $30) shr 4);
    OutBuffer[1] := (L and $0F) shl 4;

LByte3:
    Inc(Data);
    if Data >= DataEnd then begin
      Exit(OutBuffer + 1);
    end;
    L := _DecodeBase64Char(Byte(Data^), Url);
    if L < 0 then begin
      goto LByte3;
    end;
    OutBuffer[1] := OutBuffer[1] or ((L and $3C) shr 2);
    OutBuffer[2] := (L and $03) shl 6;

LByte4:
    Inc(Data);
    if Data >= DataEnd then begin
      Exit(OutBuffer + 2);
    end;
    L := _DecodeBase64Char(Byte(Data^), Url);
    if L < 0 then begin
      goto LByte4;
    end;
    OutBuffer[2] := OutBuffer[2] or (L and $3F);
    Inc(OutBuffer, 3);

    Inc(Data);
  end;
  Exit(OutBuffer);
end;

function DecodeBase64(Data: PAnsiChar; Size: SizeUInt; OutBuffer: PByte): SizeUInt;
begin
  Result := _DecodeBase64(Data, Data + Size, OutBuffer, False) - OutBuffer;
end;

function DecodeBase64(Data, DataEnd: PAnsiChar; OutBuffer: PByte): PByte;
begin
  Result := _DecodeBase64(Data, DataEnd, OutBuffer, False);
end;

function DecodeBase64Url(Data: PAnsiChar; Size: SizeUInt; OutBuffer: PByte): SizeUInt;
begin
  Result := _DecodeBase64(Data, Data + Size, OutBuffer, True) - OutBuffer;
end;

function DecodeBase64Url(Data, DataEnd: PAnsiChar; OutBuffer: PByte): PByte;
begin
  Result := _DecodeBase64(Data, DataEnd, OutBuffer, True);
end;

function ValidateBase64(Data: PAnsiChar; Size: SizeUInt; out Cursor: PAnsiChar): TBase64ValidatorResult;
begin
  Result := ValidateBase64(Data, Data + Size, Cursor);
end;

function ValidateBase64(Data, DataEnd: PAnsiChar; out Cursor: PAnsiChar): TBase64ValidatorResult;
begin
  if Data = nil then begin
    Cursor := nil;
    Exit(BASE64_VALID);
  end;  
  if (DataEnd - Data) mod 4 <> 0 then begin
    Cursor := Data;
    Exit(BASE64_TRUNCATED);
  end;
  while DataEnd - Data > 4 do begin
    if DecodeBase64Char(Data^) < 0 then begin
      Cursor := Data;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    if DecodeBase64Char((Data + 1)^) < 0 then begin
      Cursor := Data + 1;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    if DecodeBase64Char((Data + 2)^) < 0 then begin
      Cursor := Data + 2;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    if DecodeBase64Char((Data + 3)^) < 0 then begin
      Cursor := Data + 3;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    Inc(Data, 4);
  end;
  if Data < DataEnd then begin
    if DecodeBase64Char(Data^) < 0 then begin
      Cursor := Data;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    if DecodeBase64Char((Data + 1)^) < 0 then begin
      Cursor := Data + 1;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    if DecodeBase64Char((Data + 2)^) = -1 then begin
      Cursor := Data + 2;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    if DecodeBase64Char((Data + 3)^) = -1 then begin
      Cursor := Data + 3;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    Inc(Data, 4);
  end;
  Cursor := Data;
  Result := BASE64_VALID;
end;

function ValidateBase64Url(Data: PAnsiChar; Size: SizeUInt; out Cursor: PAnsiChar): TBase64ValidatorResult;
begin
  Result := ValidateBase64Url(Data, Data + Size, Cursor);
end;

function ValidateBase64Url(Data, DataEnd: PAnsiChar; out Cursor: PAnsiChar): TBase64ValidatorResult;
begin
  while DataEnd - Data > 4 do begin
    if DecodeBase64UrlChar(Data^) < 0 then begin
      Cursor := Data;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    if DecodeBase64UrlChar((Data + 1)^) < 0 then begin
      Cursor := Data + 1;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    if DecodeBase64UrlChar((Data + 2)^) < 0 then begin
      Cursor := Data + 2;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    if DecodeBase64UrlChar((Data + 3)^) < 0 then begin
      Cursor := Data + 3;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    Inc(Data, 4);
  end;
  if Data < DataEnd then begin
    if DecodeBase64UrlChar(Data^) < 0 then begin
      Cursor := Data;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    Inc(Data);
  end;
  if Data < DataEnd then begin
    if DecodeBase64UrlChar(Data^) < 0 then begin
      Cursor := Data;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    Inc(Data);
  end;
  if Data < DataEnd then begin
    if DecodeBase64UrlChar(Data^) = -1 then begin
      Cursor := Data;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    Inc(Data);
  end;
  if Data < DataEnd then begin
    // FIXME if previous byte was padding ('='),
    //       this one must be padding too
    if DecodeBase64UrlChar(Data^) = -1 then begin
      Cursor := Data;
      Exit(BASE64_INVALID_CHARACTER);
    end;
    Inc(Data);
  end;
  Cursor := Data;
  Result := BASE64_VALID;
end;

initialization
  Move(BASE64_DECODING_TABLE[0], BASE64URL_DECODING_TABLE[0], Length(BASE64_DECODING_TABLE));
  BASE64URL_DECODING_TABLE[Ord('_') - 43] := BASE64URL_DECODING_TABLE[Ord('/') - 43];
  BASE64URL_DECODING_TABLE[Ord('/') - 43] := -1;
  BASE64URL_DECODING_TABLE[Ord('-') - 43] := BASE64URL_DECODING_TABLE[Ord('+') - 43];
  BASE64URL_DECODING_TABLE[Ord('+') - 43] := -1;
end.
