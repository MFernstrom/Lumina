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

program Testbed;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UTestbed in 'UTestbed.pas',
  Lumina in '..\..\src\Lumina.pas';

begin
  try
    RunTests();
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
