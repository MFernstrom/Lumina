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

procedure Test01();
var
  LLumina: TLumina;
  LPerf: TLumina.PerformanceResult;
  LQuestion: string;
  LModel: string;
begin
  //LQuestion := 'What happen in feb 2023 according to your knowledge?';
  //LQuestion := 'who is bill gates?';
  //LQuestion := 'what is KNO3?';
  LQuestion := 'hello in: spanish, japanese, chinese';

  //LModel := 'C:/LLM/GGUF/Phi-3.5-mini-instruct-Q4_K_M.gguf';
  LModel := 'C:/LLM/GGUF/gemma-2-2b-it-abliterated-Q8_0.gguf';
  //LModel := 'C:/LLM/GGUF/Hermes-3-Llama-3.1-8B.Q4_K_M.gguf';
  //LModel := 'C:/LLM/GGUF/Falcon3-1B-Instruct-abliterated-Q8_0.gguf';
  try
    LLumina := TLumina.Create();
    try
      if LLumina.SimpleInference(LQuestion, LModel) then
      //LLumina.SimpleInference('Who is Bill Gates?', 'C:/LLM/GGUF/gemma-2-2b-it-abliterated-Q8_0.gguf');
      //if LLumina.SimpleInference('Who is Bill Gates?', 'C:/LLM/GGUF/Hermes-3-Llama-3.1-8B.Q4_K_M.gguf') then
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
