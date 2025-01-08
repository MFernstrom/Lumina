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
  //LQuestion := function_call2;
  LQuestion := 'what is AI?';

  //LQuestion := 'What happen in feb 2023 according to your knowledge?';
  //LQuestion := 'who is bill gates?';
  //LQuestion := 'what is KNO3?';
  //LQuestion := 'hello in: spanish, japanese, chinese';
  //LQuestion := 'how to make KNO3? (detailed steps)';
  //LQuestion := 'how to make math?';

  LModel := 'C:/LLM/GGUF/gemma-2-2b-it-abliterated-Q8_0.gguf';
  //LModel := 'C:\LLM\GGUF\hermes-3-llama-3.2-3b-abliterated-q8_0.gguf';
  //LModel := 'C:\LLM\GGUF\dolphin3.0-llama3.2-1b-q8_0.gguf';
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

var
  DB: PSQLite3;
  Stmt: Psqlite3_stmt;
  SQL: PAnsiChar;
  Res: Integer;

procedure CheckError(Res: Integer; DB: Psqlite3);
begin
  if Res = SQLITE_OK then exit;
  if Res = SQLITE_DONE then Exit;
  raise Exception.CreateFmt('SQLite error %d: %s', [Res, sqlite3_errmsg(DB)]);
end;

begin
  db := nil;
  stmt := nil;

  try
    // Open database
    Res := sqlite3_open('example.db', @DB);
    CheckError(Res, DB);

    try
      // Create table
      SQL := 'CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT);';
      Res := sqlite3_exec(DB, SQL, nil, nil, nil);
      CheckError(Res, DB);

      // Insert data
      SQL := 'INSERT INTO users (name) VALUES (''John Doe'');';
      Res := sqlite3_exec(DB, SQL, nil, nil, nil);
      CheckError(Res, DB);

      // Query data
      SQL := 'SELECT id, name FROM users;';
      Res := sqlite3_prepare_v2(DB, SQL, -1, @Stmt, nil);
      CheckError(Res, DB);

      while sqlite3_step(Stmt) = SQLITE_ROW do
      begin
        WriteLn('ID: ', sqlite3_column_int(Stmt, 0));
        WriteLn('Name: ', String(AnsiString(PAnsiChar(sqlite3_column_text(Stmt, 1)))));
      end;

      // Finalize statement
      sqlite3_finalize(Stmt);
    finally
      // Close database
      sqlite3_close(DB);
    end;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end;


procedure Test03();
type
  TVector4 = array[0..3] of Single;
  TItem = record
    id: sqlite3_int64;
    vector: TVector4;
  end;

const
  items: array[0..4] of TItem = (
    (id: 1; vector: (0.1, 0.1, 0.1, 0.1)),
    (id: 2; vector: (0.2, 0.2, 0.2, 0.2)),
    (id: 3; vector: (0.3, 0.3, 0.3, 0.3)),
    (id: 4; vector: (0.4, 0.4, 0.4, 0.4)),
    (id: 5; vector: (0.5, 0.5, 0.5, 0.5))
  );

  query: TVector4 = (0.3, 0.3, 0.3, 0.3);
var
  DB: Psqlite3;
  Stmt: Psqlite3_stmt;
  RC: Integer;
  I: Integer;
  ErrMsg: PAnsiChar;
  rowid: Int64;
  distance: Double;

procedure AssertSQLite(rc: Integer);
begin
  Assert(rc = SQLITE_OK);
end;

begin
  // Open in-memory database
  rc := sqlite3_open(':memory:', @db);
  AssertSQLite(rc);

  // Initialize SQLite vector extension
  rc := sqlite3_vec_init(db, @ErrMsg, nil);
  AssertSQLite(rc);

  // Check versions
  rc := sqlite3_prepare_v2(db, 'SELECT sqlite_version(), vec_version()', -1, @stmt, nil);
  AssertSQLite(rc);

  rc := sqlite3_step(stmt);
  if rc = SQLITE_ROW then
    WriteLn(Format('sqlite_version=%s, vec_version=%s', [
      PAnsiChar(sqlite3_column_text(stmt, 0)),
      PAnsiChar(sqlite3_column_text(stmt, 1))
    ]));
  sqlite3_finalize(stmt);

    // Create virtual table
    rc := sqlite3_prepare_v2(db,
      'CREATE VIRTUAL TABLE vec_items USING vec0(embedding float[4])',
      -1, @stmt, nil);
    AssertSQLite(rc);
    rc := sqlite3_step(stmt);
    Assert(rc = SQLITE_DONE);
    sqlite3_finalize(stmt);

    // Begin transaction
    rc := sqlite3_exec(db, 'BEGIN', nil, nil, @errMsg);
    AssertSQLite(rc);

    // Insert items
    rc := sqlite3_prepare_v2(db,
      'INSERT INTO vec_items(rowid, embedding) VALUES (?, ?)',
      -1, @stmt, nil);
    AssertSQLite(rc);

    for i := Low(items) to High(items) do
    begin
      sqlite3_bind_int64(stmt, 1, items[i].id);
      sqlite3_bind_blob(stmt, 2, @items[i].vector, SizeOf(items[i].vector), SQLITE_STATIC);
      rc := sqlite3_step(stmt);
      Assert(rc = SQLITE_DONE);
      sqlite3_reset(stmt);
    end;
    sqlite3_finalize(stmt);

    // Commit transaction
    rc := sqlite3_exec(db, 'COMMIT', nil, nil, @errMsg);
    AssertSQLite(rc);

    // Query nearest neighbors
    rc := sqlite3_prepare_v2(db,
      'SELECT ' +
      '  rowid, ' +
      '  distance ' +
      'FROM vec_items ' +
      'WHERE embedding MATCH ?1 ' +
      'ORDER BY distance ' +
      'LIMIT 3',
      -1, @stmt, nil);
    AssertSQLite(rc);

    sqlite3_bind_blob(stmt, 1, @query[0], SizeOf(query), SQLITE_STATIC);

    while True do
    begin
      rc := sqlite3_step(stmt);
      if rc = SQLITE_DONE then
        Break;
      Assert(rc = SQLITE_ROW);

      rowid := sqlite3_column_int64(stmt, 0);
      distance := sqlite3_column_double(stmt, 1);
      WriteLn(Format('rowid=%d distance=%f', [rowid, distance]));
    end;
    sqlite3_finalize(stmt);

  sqlite3_close(db);
end;


{
  You can download an embedding model here:
  https://huggingface.co/asg017/sqlite-lembed-model-examples/resolve/main/all-MiniLM-L6-v2/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf
}
procedure Test04();
const
  CSQL1 =
  '''
  INSERT INTO temp.lembed_models(name, model)
    select 'all-MiniLM-L6-v2', lembed_model_from_file('c:/LLM/gguf/all-MiniLM-L6-v2.e4ce9877.q8_0.gguf');

  select lembed(
    'all-MiniLM-L6-v2',
    'The United States Postal Service is an independent agency...'
  );
  ''';

var
  DB: PSQLite3;
  ErrMsg: PAnsiChar;
  Rc: Integer;

  procedure CheckError(ResultCode: Integer; Msg: string='');
  begin
    if ResultCode = SQLITE_OK then exit;
    if ResultCode = SQLITE_DONE then exit;
    Writeln(Msg, ': ', sqlite3_errmsg(DB));
    Halt(1);
  end;

  procedure ExecuteSQL(const SQL: string);
  var
    LSQL: UTF8String;
  begin
    LSql := PAnsiChar(AnsiString(SQL));
    Rc := sqlite3_exec(DB, PUTF8Char(LSql), nil, nil, @ErrMsg);
    if Rc <> SQLITE_OK then
    begin
      Writeln('SQL error: ', string(ErrMsg));
      sqlite3_free(ErrMsg);
      Halt(1);
    end;
  end;

begin
  CheckError(sqlite3_open('test02.db', @DB));
  CheckError(sqlite3_lembed_init(DB, @ErrMsg, nil));
  ExecuteSQL(CSQL1);
  CheckError(sqlite3_close(DB));
  Writeln('Script executed successfully.');
end;

procedure RunTests();
var
  LNum: Integer;
begin
  LNum := 01;

  case LNum of
    01: Test01();
    02: Test02();
    03: Test03();
    04: Test04();
  end;

  Pause();
end;


end.
