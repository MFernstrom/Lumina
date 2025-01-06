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

const
function_call1 =
'''
Cutting Knowledge Date: December 2023
Today Date: 23 July 2024

When you receive a tool call response, use the output to format an answer to the orginal user question.

You are a helpful assistant with tool calling capabilities.<|eot_id|><|start_header_id|>user<|end_header_id|>

Given the following functions, please respond with a JSON for a function call with its proper arguments that best answers the given prompt.

Respond in the format {"name": function name, "parameters": dictionary of argument name and its value}. Do not use variables.

{
    "type": "function",
    "function": {
    "name": "get_current_conditions",
    "description": "Get the current weather conditions for a specific location",
    "parameters": {
        "type": "object",
        "properties": {
        "location": {
            "type": "string",
            "description": "The city and state, e.g., San Francisco, CA"
        },
        "unit": {
            "type": "string",
            "enum": ["Celsius", "Fahrenheit"],
            "description": "The temperature unit to use. Infer this from the user's location."
        }
        },
        "required": ["location", "unit"]
    }
    }
}

Question: what is the weather like in San Fransisco?
''';

function_call2 =
'''
You are an expert in composing functions. You are given a question and a set of possible functions.
Based on the question, you will need to make one or more function/tool calls to achieve the purpose.
If none of the functions can be used, point it out. If the given question lacks the parameters required by the function,also point it out. You should only return the function call in tools call sections.
If you decide to invoke any of the function(s), you MUST respond in the format of [func_name1(params_name1=params_value1, params_name2=params_value2...), func_name2(params)]

Here is a list of functions in JSON format that you can invoke.
[
    {
        "name": "get_user_info",
        "description": "Retrieve details for a specific user by their unique identifier. Note that the provided function is in Python 3 syntax.",
        "parameters": {
            "type": "dict",
            "required": [
                "user_id"
            ],
            "properties": {
                "user_id": {
                "type": "integer",
                "description": "The unique identifier of the user. It is used to fetch the specific user details from the database."
            },
            "special": {
                "type": "string",
                "description": "Any special information or parameters that need to be considered while fetching user details.",
                "default": "none"
                }
            }
        }
    }
]


Can you retrieve the details for the user with the ID 7890, who has black as their special request?
Can you retrieve the details for the user with the ID 6889, who has white as their special request?
Can you retrieve the details for the user with the ID 1000, who has red as their special request?

''';

procedure Test01();
var
  LLumina: TLumina;
  LPerf: TLumina.PerformanceResult;
  LQuestion: string;
  LModel: string;
begin
  LQuestion := function_call2;
  //LQuestion := 'what is AI?';

  //LQuestion := 'What happen in feb 2023 according to your knowledge?';
  //LQuestion := 'who is bill gates?';
  //LQuestion := 'what is KNO3?';
  //LQuestion := 'hello in: spanish, japanese, chinese';
  //LQuestion := 'how to make KNO3? (detailed steps)';
  //LQuestion := 'how to make math?';

  //LModel := 'C:/LLM/GGUF/gemma-2-2b-it-abliterated-Q8_0.gguf';
  //LModel := 'C:\LLM\GGUF\hermes-3-llama-3.2-3b-abliterated-q8_0.gguf';
  LModel := 'C:\LLM\GGUF\dolphin3.0-llama3.2-1b-q8_0.gguf';
  try
    LLumina := TLumina.Create();
    try
      LLumina.SetInfoCallback(InfoCallback, LLumina);
      LLumina.SetProgressCallback(ProgressCallback, LLumina);
      LLumina.SetCancelCallback(CancelCallback, LLumina);

      if LLumina.LoadModel(LModel, '', 1024*8) then
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
