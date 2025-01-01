program Testbed;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  UTestbed in 'UTestbed.pas',
  Lumina in '..\..\src\Lumina.pas',
  Lumina.Deps in '..\..\src\Lumina.Deps.pas',
  Lumina.Common in '..\..\src\Lumina.Common.pas';

begin
  try
    RunTests();
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
