program Hausinterface;

{$mode objfpc}{$H+}

uses
  heaptrc,
  cmem,
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, unithaus
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(THeizung, Heizung);
  Application.Run;
end.

