{* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
                   _                  _
                  | |    _  _  _ __  (_) _ _   __ _ ™
                  | |__ | || || '  \ | || ' \ / _` |
                  |____| \_,_||_|_|_||_||_||_|\__,_|
                         Local Generative AI

                 Copyright © 2024-present tinyBigGAMES™ LLC
                          All Rights Reserved.

                    Website: https://tinybiggames.com
                    Email  : support@tinybiggames.com

                 See LICENSE file for license information
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *}

unit Lumina.Common;

{$I Lumina.Defines.inc}

interface

uses
  WinApi.Windows,
  System.SysUtils,
  System.IOUtils,
  System.StrUtils,
  System.Classes,
  System.Math,
  System.RegularExpressions;

type
  { TCallback }
  TCallback<T> = record
    Handler: T;
    UserData: Pointer;
  end;

  { TBaseObject }
  TBaseObject = class(TObject)
  public
    constructor Create(); virtual;
    destructor Destroy(); override;
  end;

  { TTokenResponse }

  // AddToken return messages - for TResponse.AddToken
  //  paWait = No new (full) words, just wait for more incoming tokens
  //  Append = Append existing line with latest word
  //  NewLine = start new line then print the latest word
  TTokenPrintAction = (tpaWait, tpaAppend, tpaNewline);

  { TResponse
    Helper to handle incoming tokens during streaming
      Example uses:
      - Tabulate tokens into full words based on wordbreaks
      - Control wordwrap/linechanges for console or custom GUI without wordwrap functionality
        (Does change the print resolution from Token to logical words)
  }
  TTokenResponse = record
  private
    FRaw: string;                  // Full response as is
    FTokens: array of string;      // Actual tokens
    //FLineLengthMax: Integer;       // Define confined space, in chars for fixed width font
    FWordBreaks: array of char;    // What is considered a logical word-break
    FLineBreaks: array of char;    // What is considered a logical line-break
    FWords: array of String;       // Response but as array of "words"
    FWord: string;                // Current word accumulating
    FLine: string;                // Current line accumulating
    FFinalized: Boolean;          // Know the finalization is done
    FRightMargin: Integer;
    function HandleLineBreaks(const AToken: string): Boolean;
    function SplitWord(const AWord: string; var APrefix, ASuffix: string): Boolean;
    function GetLineLengthMax(): Integer;
  public
    class operator Initialize (out ADest: TTokenResponse);
    procedure SetRightMargin(const AMargin: Integer);
    function AddToken(const aToken: string): TTokenPrintAction;
    function LastWord(const ATrimLeft: Boolean=False): string;
    function Finalize: Boolean;
  end;

procedure Pause();
function  AsUTF8(const AText: string): Pointer;
function  EnableVirtualTerminalProcessing(): DWORD;
function  ResourceExists(aInstance: THandle; const aResName: string): Boolean;
function  HasConsoleOutput: Boolean;
function  GetPhysicalProcessorCount(): DWORD;
procedure GetConsoleSize(AWidth: PInteger; AHeight: PInteger);

implementation

var
  Marshaller: TMarshaller;

procedure Pause();
begin
  WriteLn;
  Write('Press ENTER to continue...');
  ReadLn;
  WriteLn;
end;

function AsUTF8(const AText: string): Pointer;
begin
  Result := Marshaller.AsUtf8(AText).ToPointer;
end;

function EnableVirtualTerminalProcessing(): DWORD;
var
  HOut: THandle;
  LMode: DWORD;
begin
  HOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if HOut = INVALID_HANDLE_VALUE then
  begin
    Result := GetLastError;
    Exit;
  end;

  if not GetConsoleMode(HOut, LMode) then
  begin
    Result := GetLastError;
    Exit;
  end;

  LMode := LMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING;
  if not SetConsoleMode(HOut, LMode) then
  begin
    Result := GetLastError;
    Exit;
  end;

  Result := 0;  // Success
end;

function ResourceExists(aInstance: THandle; const aResName: string): Boolean;
begin
  Result := Boolean((FindResource(aInstance, PChar(aResName), RT_RCDATA) <> 0));
end;

function HasConsoleOutput: Boolean;
var
  Stdout: THandle;
begin
  Stdout := GetStdHandle(Std_Output_Handle);
  Win32Check(Stdout <> Invalid_Handle_Value);
  Result := Stdout <> 0;
end;

function GetPhysicalProcessorCount(): DWORD;
var
  BufferSize: DWORD;
  Buffer: PSYSTEM_LOGICAL_PROCESSOR_INFORMATION;
  ProcessorInfo: PSYSTEM_LOGICAL_PROCESSOR_INFORMATION;
  Offset: DWORD;
begin
  Result := 0;
  BufferSize := 0;

  // Call GetLogicalProcessorInformation with buffer size set to 0 to get required buffer size
  if not GetLogicalProcessorInformation(nil, BufferSize) and (GetLastError = ERROR_INSUFFICIENT_BUFFER) then
  begin
    // Allocate buffer
    GetMem(Buffer, BufferSize);
    try
      // Call GetLogicalProcessorInformation again with allocated buffer
      if GetLogicalProcessorInformation(Buffer, BufferSize) then
      begin
        ProcessorInfo := Buffer;
        Offset := 0;

        // Loop through processor information to count physical processors
        while Offset + SizeOf(SYSTEM_LOGICAL_PROCESSOR_INFORMATION) <= BufferSize do
        begin
          if ProcessorInfo.Relationship = RelationProcessorCore then
            Inc(Result);

          Inc(ProcessorInfo);
          Inc(Offset, SizeOf(SYSTEM_LOGICAL_PROCESSOR_INFORMATION));
        end;
      end;
    finally
      FreeMem(Buffer);
    end;
  end;
end;

procedure  GetConsoleSize(AWidth: PInteger; AHeight: PInteger);
var
  LConsoleInfo: TConsoleScreenBufferInfo;
begin
  GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), LConsoleInfo);
  if Assigned(AWidth) then
    AWidth^ := LConsoleInfo.dwSize.X;

  if Assigned(AHeight) then
  AHeight^ := LConsoleInfo.dwSize.Y;
end;

{ TBaseObject }
constructor TBaseObject.Create();
begin
  inherited;
end;

destructor TBaseObject.Destroy();
begin
  inherited;
end;

{ TTokenResponse }
class operator TTokenResponse.Initialize (out ADest: TTokenResponse);
begin
  // Defaults
  ADest.FRaw := '';
  SetLength(ADest.FTokens, 0);
  SetLength(ADest.FWordBreaks, 0);
  SetLength(ADest.FLineBreaks, 0);
  SetLength(ADest.FWords, 0);
  ADest.FWord := '';
  ADest.FLine := '';
  ADest.FFinalized := False;
  ADest.FRightMargin := 10;

  // If stream output is sent to a destination without wordwrap,
  // the TTokenResponse will find wordbreaks and split into lines by full words

  // Stream is tabulated into full words based on these break characters
  // !Syntax requires at least one!
  SetLength(ADest.FWordBreaks, 4);
  ADest.FWordBreaks[0] := ' ';
  ADest.FWordBreaks[1] := '-';
  ADest.FWordBreaks[2] := ',';
  ADest.FWordBreaks[3] := '.';

  // Stream may contain forced line breaks
  // !Syntax requires at least one!
  SetLength(ADest.FLineBreaks, 2);
  ADest.FLineBreaks[0] := #13;
  ADest.FLineBreaks[1] := #10;


  ADest.SetRightMargin(10);
end;

function TTokenResponse.AddToken(const aToken: string): TTokenPrintAction;
var
  LPrefix, LSuffix: string;
begin
  // Keep full original response
  FRaw := FRaw + aToken;                    // As continuous string
  Setlength(FTokens, Length(FTokens)+1);    // Make space
  FTokens[Length(FTokens)-1] := aToken;     // As an array

  // Accumulate "word"
  FWord := FWord + aToken;

  // If stream contains linebreaks, print token out without added linebreaks
  if HandleLineBreaks(aToken) then
    exit(TTokenPrintAction.tpaAppend)

  // Check if a natural break exists, also split if word is longer than the allowed space
  // and print out token with or without linechange as needed
  else if SplitWord(FWord, LPrefix, LSuffix) or FFinalized then
    begin
      // On last call when Finalized we want access to the line change logic only
      // Bad design (fix on top of a fix) Would be better to separate word slipt and line logic from eachother
      if not FFinalized then
        begin
          Setlength(FWords, Length(FWords)+1);        // Make space
          FWords[Length(FWords)-1] := LPrefix;        // Add new word to array
          FWord := LSuffix;                         // Keep the remainder of the split
        end;

      // Word was split, so there is something that can be printed

      // Need for a new line?
      if Length(FLine) + Length(LastWord) > GetLineLengthMax() then
        begin
          Result  := TTokenPrintAction.tpaNewline;
          FLine   := LastWord;                  // Reset Line (will be new line and then the word)
        end
      else
        begin
          Result  := TTokenPrintAction.tpaAppend;
          FLine   := FLine + LastWord;          // Append to the line
        end;
    end
  else
    begin
      Result := TTokenPrintAction.tpaWait;
    end;
end;

function TTokenResponse.HandleLineBreaks(const AToken: string): Boolean;
var
  LLetter, LLineBreak: Integer;
begin
  Result := false;

  for LLetter := Length(AToken) downto 1 do                   // We are interested in the last possible linebreak
  begin
    for LLineBReak := 0 to Length(Self.FLineBreaks)-1 do       // Iterate linebreaks
    begin
      if AToken[LLetter] = FLineBreaks[LLineBreak] then        // If linebreak was found
      begin
        // Split into a word by last found linechange (do note the stored word may have more linebreak)
        Setlength(FWords, Length(FWords)+1);                          // Make space
        FWords[Length(FWords)-1] := FWord + LeftStr(AToken, Length(AToken)-LLetter); // Add new word to array

        // In case aToken did not end after last LF
        // Word and new line will have whatever was after the last linebreak
        FWord := RightStr(AToken, Length(AToken)-LLetter);
        FLine := FWord;

        // No need to go further
        exit(true);
      end;
    end;
  end;
end;

function TTokenResponse.Finalize: Boolean;
begin
  // Buffer may contain something, if so make it into a word
  if FWord <> ''  then
    begin
      Setlength(FWords, Length(FWords)+1);      // Make space
      FWords[Length(FWords)-1] := FWord;        // Add new word to array
      Self.FFinalized := True;                // Remember Finalize was done (affects how last AddToken-call behaves)
      exit(true);
    end
  else
    Result := false;
end;

function TTokenResponse.LastWord(const ATrimLeft: Boolean): string;
begin
  Result := FWords[Length(FWords)-1];
  if ATrimLeft then
    Result := Result.TrimLeft;
end;

function TTokenResponse.SplitWord(const AWord: string; var APrefix, ASuffix: string): Boolean;
var
  LLetter, LSeparator: Integer;
begin
  Result := false;

  for LLetter := 1 to Length(AWord) do               // Iterate whole word
  begin
    for LSeparator := 0 to Length(FWordBreaks)-1 do   // Iterate all separating characters
    begin
      if AWord[LLetter] = FWordBreaks[LSeparator] then // check for natural break
      begin
        // Let the world know there's stuff that can be a reason for a line change
        Result := True;

        APrefix := LeftStr(AWord, LLetter);
        ASuffix := RightStr(AWord, Length(AWord)-LLetter);
      end;
    end;
  end;

  // Maybe the word is too long but there was no natural break, then cut it to LineLengthMax
  if Length(AWord) > GetLineLengthMax() then
  begin
    Result := True;
    APrefix := LeftStr(AWord, GetLineLengthMax());
    ASuffix := RightStr(AWord, Length(AWord)-GetLineLengthMax());
  end;
end;

function TTokenResponse.GetLineLengthMax(): Integer;
begin
  GetConsoleSize(@Result, nil);
  Result := Result - FRightMargin;
end;

procedure TTokenResponse.SetRightMargin(const AMargin: Integer);
var
  LWidth: Integer;
begin
  GetConsoleSize(@LWidth, nil);
  FRightMargin := EnsureRange(AMargin, 1, LWidth);
end;

initialization
begin
  SetConsoleCP(CP_UTF8);
  SetConsoleOutputCP(CP_UTF8);
  EnableVirtualTerminalProcessing();
end;

finalization
begin
end;

end.
