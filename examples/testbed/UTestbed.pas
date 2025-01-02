{===============================================================================
  _                  _
 | |    _  _  _ __  (_) _ _   __ _ ™
 | |__ | || || '  \ | || ' \ / _` |
 |____| \_,_||_|_|_||_||_||_|\__,_|
        Local Generative AI

 Copyright © 2024-present tinyBigGAMES™ LLC
 All Rights Reserved.

 https://github.com/tinyBigGAMES/Lumina

===============================================================================}

unit UTestbed;

interface

procedure RunTests();

implementation

uses
  WinApi.Windows,
  System.SysUtils,
  System.IOUtils,
  System.Math,
  Lumina;

procedure Pause();
begin
  WriteLn;
  Write('Press ENTER to continue...');
  ReadLn;
  WriteLn;
end;

procedure InfoCallback(const AText: string; const AUserData: Pointer);
var
  LLumina: TLumina;
begin
  LLumina := TLumina(AUserData);
  if not Assigned(LLumina) then Exit;

  // Uncomment to display model info
  //LLumina.Print(AText, []);
end;

procedure ProgressCallback(const AModelFilename: string; const AProgress: Single; const AUserData: Pointer);
var
  LLumina: TLumina;
begin
  LLumina := TLumina(AUserData);
  if not Assigned(LLumina) then Exit;

  LLumina.Print(#13+'Loading %s(%3.2f%%)...', [AModelFilename, AProgress]);
  if AProgress >= 100  then
  begin
    // clear line
    LLumina.Print(#13 + #27 + '[K', []);
  end;
end;

function CancelCallback(const AUserData: Pointer): Boolean;
begin
  Result := Boolean(GetAsyncKeyState(VK_ESCAPE) <> 0);
end;

procedure Test01();
var
  LLumina: TLumina;
  LPerf: TLumina.PerformanceResult;
  LQuestion: string;
  LModel: string;
begin
  LQuestion := 'what is AI?';

  //LQuestion := 'What happen in feb 2023 according to your knowledge?';
  //LQuestion := 'who is bill gates?';
  //LQuestion := 'what is KNO3?';
  //LQuestion := 'hello in: spanish, japanese, chinese';

  //LModel := 'C:/LLM/GGUF/Phi-3.5-mini-instruct-Q4_K_M.gguf';
  LModel := 'C:/LLM/GGUF/gemma-2-2b-it-abliterated-Q8_0.gguf';
  //LModel := 'C:/LLM/GGUF/Hermes-3-Llama-3.1-8B.Q4_K_M.gguf';
  //LModel := 'C:/LLM/GGUF/Falcon3-1B-Instruct-abliterated-Q8_0.gguf';
  try
    LLumina := TLumina.Create();
    try
      LLumina.SetInfoCallback(InfoCallback, LLumina);
      LLumina.SetProgressCallback(ProgressCallback, LLumina);
      LLumina.SetCancelCallback(CancelCallback, LLumina);

      if LLumina.LoadModel(LModel) then
      begin
      if LLumina.SimpleInference(LQuestion) then
        begin
          LPerf := LLumina.GetPerformanceResult();
          writeln;
          writeln;
          writeln('Input Tokens: ', LPerf.TotalInputTokens);
          writeln('Output Tokens: ', LPerf.TotalOutputTokens);
          writeln('Tokens/Sec   : ', LPerf.TokensPerSecond:3:2);
        end
      else
        begin
          WriteLn('Error: ', LLumina.GetError());
        end;

        LLumina.UnloadModel();
      end;
    finally
      LLumina.Free();
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end;

procedure Test02();
begin
end;

procedure Test03();
begin
end;

procedure Test04();
begin
end;

procedure RunTests();
begin
  Test01();
  Pause();
end;

end.
