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

unit Lumina;

{$I Lumina.Defines.inc}

interface

uses
  WinApi.Windows,
  System.Generics.Collections,
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Math,
  Lumina.Deps,
  Lumina.Common;

const
  CHATML_TEMPLATE = '<|im_start|>{role} {content}<|im_end|><|im_start|>assistant';
  GEMMA_TEMPLATE  = '<start_of_turn>{role} {content}<end_of_turn>';
  PHI_TEMPLATE    = '<|{role}|> {content}<|end|><|assistant|>';

type

  { TLumina }
  TLumina = class(TObject)
  public type
    { TLumina.NextTokenCallback }
    NextTokenCallback = procedure(const AToken: string; const AUserData: Pointer);

    { TLumina.CancelCallback }
    CancelCallback    = function(const AUserData: Pointer): Boolean;

    { TLumina.ProgressCallback }
    ProgressCallback  = procedure(const AModelFilename: string; const AProgress: Single; const AUserData: Pointer);

    { TLumina.PerformanceResult }
    PerformanceResult = record
      TokensPerSecond: Double;
      TotalInputTokens: Int32;
      TotalOutputTokens: Int32;
    end;
  private type
    TNextTokenCallback = TCallback<NextTokenCallback>;
    TCancelCallback = TCallback<CancelCallback>;
    TProgressCallback = TCallback<ProgressCallback>;
  private
    FNextTokenCallback: TNextTokenCallback;
    FCancelCallback: TCancelCallback;
    FProgressCallback: TProgressCallback;
    FError: string;
    FPerf: TLumina.PerformanceResult;
    FModelFilename: string;
    FModelProgress: Single;
    function TokenToPiece(const AContext: Pllama_context; const AToken: llama_token; const ASpecial: Boolean): string;
    function CalcPerformance(const AContext: Pllama_context): TLumina.PerformanceResult;
    procedure SetError(const AText: string; const AArgs: array of const);
    procedure Print(const AText: string);
    function OnCancel(): Boolean;
    procedure OnNextToken(const AToken: string);
    procedure OnProgress();
  public
    ScriptRunning: UInt32;
    constructor Create(); virtual;
    destructor Destroy(); override;

    function  GetError(): string;

    function  GetNextTokenCallback(): TLumina.NextTokenCallback;
    procedure SetNextTokenCallback(const AHandler: TLumina.NextTokenCallback; const AUserData: Pointer);

    function  GetCancelCallback(): CancelCallback;
    procedure SetCancelCallback(const AHandler: TLumina.CancelCallback; const AUserData: Pointer);

    function  GetProgressCallback(): ProgressCallback;
    procedure SetProgressCallback(const AHandler: TLumina.ProgressCallback; const AUserData: Pointer);

    function  SimpleInference(const AQuestion, AModelFilename: string; const ATempate: string=''; const AMaxContext: UInt32=512; const AGPULayers: Int32=-1; const AMaxThreads: Int32=4): Boolean;
    function  GetPerformanceResult(): TLumina.PerformanceResult;
  end;

implementation


{ TLumina }
function TLumina.TokenToPiece(const AContext: Pllama_context; const AToken: llama_token; const ASpecial: Boolean): string;
var
  LTokens: Int32;
  LCheck: Int32;
  LBuffer: TArray<UTF8Char>;
begin
  try
    SetLength(LBuffer, 9);
    LTokens := llama_token_to_piece(llama_get_model(AContext), AToken, @LBuffer[0], 8, 0, ASpecial);
    if LTokens < 0 then
      begin
        SetLength(LBuffer, (-LTokens)+1);
        LCheck := llama_token_to_piece(llama_get_model(AContext), AToken, @LBuffer[0], -LTokens, 0, ASpecial);
        Assert(LCheck = -LTokens);
        LBuffer[-LTokens] := #0;
      end
    else
      begin
        LBuffer[LTokens] := #0;
      end;
    Result := UTF8ToString(@LBuffer[0]);
  except
    on E: Exception do
    begin
      SetError(E.Message, []);
      Exit;
    end;
  end;
end;

function TLumina.CalcPerformance(const AContext: Pllama_context): PerformanceResult;
var
  LTotalTimeSec: Double;
  APerfData: llama_perf_context_data;
begin
  APerfData := llama_perf_context(AContext);

  // Convert milliseconds to seconds
  LTotalTimeSec := APerfData.t_eval_ms / 1000;

  // Total input tokens (n_p_eval assumed to be input tokens)
  Result.TotalInputTokens := APerfData.n_p_eval;

  // Total output tokens (n_eval assumed to be output tokens)
  Result.TotalOutputTokens := APerfData.n_eval;

  // Calculate tokens per second (total tokens / time in seconds)
  if LTotalTimeSec > 0 then
    Result.TokensPerSecond := (Result.TotalInputTokens + Result.TotalOutputTokens) / LTotalTimeSec
  else
    Result.TokensPerSecond := 0;
end;

procedure TLumina.Print(const AText: string);
begin
  if not HasConsoleOutput() then Exit;
  Write(AText);
end;

procedure TLumina.SetError(const AText: string; const AArgs: array of const);
begin
  FError := Format(AText, AArgs);
end;

function TLumina.OnCancel(): Boolean;
begin
  if Assigned(FCancelCallback.Handler) then
    Result := FCancelCallback.Handler(FCancelCallback.UserData)
  else
    // check for ESC press by default
    Result := Boolean(GetAsyncKeyState(VK_ESCAPE) <> 0);
end;

procedure TLumina.OnNextToken(const AToken: string);
begin
  if Assigned(FNextTokenCallback.Handler) then
    FNextTokenCallback.Handler(AToken, FNextTokenCallback.UserData)
  else
    Print(AToken);
end;

procedure TLumina.OnProgress();
begin
  if Assigned(FProgressCallback.Handler) then
    FProgressCallback.Handler(FModelFilename, FModelProgress, FProgressCallback.UserData);
end;


constructor TLumina.Create();
begin
  inherited;
end;

destructor TLumina.Destroy();
begin
  inherited;
end;

procedure log_callback(level: ggml_log_level; const text: PUTF8Char; user_data: Pointer); cdecl;
begin
  //
  //write(text);
end;

procedure cerr_callback(const text: PUTF8Char; user_data: Pointer); cdecl;
begin
  //write(text);
end;


function progress_callback(progress: Single; user_data: Pointer): Boolean; cdecl;
var
  LProgress: single;
  LFilename: string;
begin
  LFilename := TPath.GetFileName(PString(user_data)^);
  LProgress := progress * 100.0;
  if HasConsoleOutput() then
  begin
    Write(Format(#13+'Loading %s(%3.2f%%)...', [LFilename, LProgress]));
  end;
  if LProgress >= 100  then
  begin
    if HasConsoleOutput() then
    begin
      // clear line
      Write(#13 + #27 + '[K');

      // move cursor up one line
      //Write(#27 + '[1A');
    end;
  end;

  Result := True;
end;

function progress_callback2(progress: Single; user_data: Pointer): Boolean; cdecl;
var
  LProgress: single;
  LFilename: string;
  LLumina: TLumina;
begin
  Result := True;
  if not Assigned(user_data) then Exit;

  LLumina := TLumina(user_data);
  LLumina.FModelProgress := progress * 100.0;

  if Assigned(LLumina.GetProgressCallback()) then
  begin
    LLumina.OnProgress();
    Exit;
  end;

  LFilename := LLumina.FModelFilename;
  LProgress := progress * 100.0;
  if HasConsoleOutput() then
  begin
    Write(Format(#13+'Loading %s(%3.2f%%)...', [LFilename, LProgress]));
  end;
  if LProgress >= 100  then
  begin
    if HasConsoleOutput() then
    begin
      // clear line
      Write(#13 + #27 + '[K');

      // move cursor up one line
      //Write(#27 + '[1A');
    end;
  end;

end;

function  TLumina.GetError(): string;
begin
  Result := FError;
end;

function  TLumina.GetNextTokenCallback(): NextTokenCallback;
begin
  Result := FNextTokenCallback.Handler;
end;

procedure TLumina.SetNextTokenCallback(const AHandler: NextTokenCallback; const AUserData: Pointer);
begin
  FNextTokenCallback.Handler := AHandler;
  FNextTokenCallback.UserData := AUserData;
end;

function  TLumina.GetCancelCallback(): CancelCallback;
begin
  Result := FCancelCallback.Handler;
end;

procedure TLumina.SetCancelCallback(const AHandler: CancelCallback; const AUserData: Pointer);
begin
  FCancelCallback.Handler := AHandler;
  FCancelCallback.UserData := AUserData;
end;

function  TLumina.GetProgressCallback(): ProgressCallback;
begin
  Result := FProgressCallback.Handler;
end;

procedure TLumina.SetProgressCallback(const AHandler: TLumina.ProgressCallback; const AUserData: Pointer);
begin
  FProgressCallback.Handler := AHandler;
  FProgressCallback.UserData := AUserData;
end;

function TLumina.SimpleInference(const AQuestion, AModelFilename, ATempate: string; const AMaxContext: UInt32; const AGPULayers: Int32; const AMaxThreads: Int32): Boolean;
var
  model_params: llama_model_params;
  model: Pllama_model;
  n_prompt: Integer;
  prompt_tokens: TArray<llama_token>;
  ctx_params: llama_context_params;
  n_predict: integer;
  ctx: Pllama_context;
  sparams: llama_sampler_chain_params;
  smpl: Pllama_sampler;
  n: Integer;
  S: string;
  batch: llama_batch;
  new_token_id: llama_token;
  n_pos: Integer;
  LPrompt: UTF8String;
  LFilename: string;
  LText: string;
  LFirstToken: Boolean;
  LBuffer: array of UTF8Char;
  v: Int32;
  buf: array[0..255] of UTF8Char;
  key: string;
  max_context: integer;
  LTokenResponse: TTokenResponse;

  function BuildPrompt(const AModel: Pllama_model; const AText: string): PUTF8Char;
  var
    chatMessages: llama_chat_message;
    size, tmplsize: integer;
  begin
    ChatMessages.role := 'user';
    ChatMessages.content := AsUTF8(AText);
    size := StrLen(ChatMessages.content);
    size := (size * 2) + 512;
    SetLength(LBuffer, size);
    FillChar(LBuffer[0], size, 0);

    tmplsize := llama_chat_apply_template(AModel, nil, @ChatMessages, 1, True, @LBuffer[0], size);
    if tmplsize > size then
    begin
      LBuffer := nil;
      SetLength(LBuffer, tmplsize);
      llama_chat_apply_template(AModel, nil, @ChatMessages, 1, True, @LBuffer[0], tmplsize);
    end;
    Result := @LBuffer[0];
  end;

begin
  Result := False;
  FError := '';

  redirect_cerr_to_callback(cerr_callback, nil);
  try
    LFirstToken := True;
    LFilename := AModelFilename;
    llama_log_set(log_callback, nil);

    //n_predict := 512;
    model_params := llama_model_default_params();

    //model_params.progress_callback := progress_callback;
    //model_params.progress_callback_user_data := @LFilename;

    model_params.progress_callback := progress_callback2;
    model_params.progress_callback_user_data := Self;

    FModelProgress := 0;
    FModelFilename := AModelFilename;

    if AGPULayers < 0 then
      model_params.n_gpu_layers := MaxInt
    else
      model_params.n_gpu_layers := AGPULayers;

    model :=  llama_load_model_from_file( AsUtf8(AModelFilename), model_params);
    if not Assigned(model) then
    begin
      SetError('Failed to load model: "%s"', [AModelFilename]);
      Exit;
    end;

    max_context := 0;
    for v := 0 to llama_model_meta_count(model)-1 do
    begin
      llama_model_meta_key_by_index(model, v, @buf[0], length(buf));
      key := string(buf);
      if key.Contains('context_length') then
      begin
        llama_model_meta_val_str_by_index(model, v, @buf[0], length(buf));
        key := string(buf);
        max_context :=  key.ToInteger;
        break;
      end;
    end;

    if max_context > 0 then
      n_predict := EnsureRange(AMaxContext, 512, max_context)
    else
      n_predict := 512;


    LText :=  ATempate;
    if LText.IsEmpty then
      //LText := CHATML_TEMPLATE;
      LPrompt := BuildPrompt(model, AQuestion)
    else
      begin
      LText := LText.Replace('{role}', 'user');
      LText := LText.Replace('{content}', AQuestion);
      LPrompt := UTF8Encode(LText);
    end;

    n_prompt := -llama_tokenize(model, PUTF8Char(LPrompt), Length(LPrompt), nil, 0, true, true);

    SetLength(prompt_tokens, n_prompt);

    if llama_tokenize(model, PUTF8Char(LPrompt), Length(LPrompt), @prompt_tokens[0], Length(prompt_tokens), true, true) < 0 then
    begin
      SetError('Failed to tokenize prompt', []);
    end;

    ctx_params := llama_context_default_params();
    ctx_params.n_ctx := n_prompt + n_predict - 1;
    ctx_params.n_batch := n_prompt;
    ctx_params.no_perf := false;
    ctx_params.n_threads := EnsureRange(AMaxThreads, 1, GetPhysicalProcessorCount());
    ctx_params.n_threads_batch := ctx_params.n_threads;

    ctx := llama_new_context_with_model(model, ctx_params);
    if ctx = nil then
    begin
      SetError('Failed to create inference context', []);
      llama_free_model(model);
      exit;
    end;

    sparams := llama_sampler_chain_default_params();
    smpl := llama_sampler_chain_init(sparams);
    llama_sampler_chain_add(smpl, llama_sampler_init_greedy());

    batch := llama_batch_get_one(@prompt_tokens[0], Length(prompt_tokens));

    n_pos := 0;

    FPerf := Default(TLumina.PerformanceResult);

    while n_pos + batch.n_tokens < n_prompt + n_predict do
    begin
      if OnCancel() then
        Break;

      n := llama_decode(ctx, batch);
      if n <> 0 then
      begin
        SetError('Failed to decode context', []);
        llama_sampler_free(smpl);
        llama_free(ctx);
        llama_free_model(model);
        Exit;
      end;

      n_pos := n_pos + batch.n_tokens;

      new_token_id := llama_sampler_sample(smpl, ctx, -1);
      if llama_token_is_eog(model, new_token_id) then
          break;

      s := TokenToPiece(ctx, new_token_id, false);
      if LFirstToken then
      begin
        s := s.Trim();
        LFirstToken := False;
      end;

      case LTokenResponse.AddToken(s) of
        tpaWait:
        begin
        end;

        tpaAppend:
        begin
          OnNextToken(LTokenResponse.LastWord(False));
        end;

        tpaNewline:
        begin
          OnNextToken(#10);
          OnNextToken(LTokenResponse.LastWord(True));
        end;
      end;

      batch := llama_batch_get_one(@new_token_id, 1);
    end;

    FPerf := CalcPerformance(ctx);

    llama_sampler_free(smpl);
    llama_free(ctx);
    llama_free_model(model);

    Result := True;

  finally
    restore_cerr();
  end;
end;

function TLumina.GetPerformanceResult(): TLumina.PerformanceResult;
begin
  Result := FPerf;
end;


end.
