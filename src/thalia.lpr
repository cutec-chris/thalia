program thalia;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, Classes, SysUtils, CustApp, uSpeaker, uPluginInterface,
  uIntfStrConsts, zdbc, laz_synapse, general_nogui, uwikipedia, umath, uUsers;

type
  { TThalia }

  TThalia = class(TCustomApplication)
    function FSpeakerGetParameter(short: char; long: string): string;
    procedure FSpeakerSystemMessage(sentence: string);
    procedure FSpeakerDebugMessage(sentence: string);
    procedure ThaliaException(Sender: TObject; E: Exception);
  private
    FSpeaker : TSpeaker;
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TThalia }

function TThalia.FSpeakerGetParameter(short: char; long: string): string;
begin
  Result := GetOptionValue(short,long);
  if ((short = 'c') or (long = 'channel')) and (result[1] <> '#') then
    result := '#'+result;
end;

procedure TThalia.FSpeakerSystemMessage(sentence: string);
begin
  if not HasOption('q','quiet') then
    write(sentence);
end;

procedure TThalia.FSpeakerDebugMessage(sentence: string);
begin
  if not HasOption('q','quiet') then
    if HasOption('d','debug') then
      write(sentence);
end;

procedure TThalia.ThaliaException(Sender: TObject; E: Exception);
var
  FrameCount: integer;
  Frames: PPointer;
  FrameNumber:Integer;
begin
  if HasOption('q','quiet') then exit;
  WriteLn('  Stack trace:');
  WriteLn(BackTraceStrFunc(ExceptAddr));
  FrameCount:=ExceptFrameCount;
  Frames:=ExceptFrames;
  for FrameNumber := 0 to FrameCount-1 do
    WriteLn(BackTraceStrFunc(Frames[FrameNumber]));
end;

procedure TThalia.DoRun;
var
  ErrorMsg: String;
begin
  // parse parameters
  if HasOption('h','help') then begin
    WriteHelp;
    Halt;
  end;

  { add your program here }

  if not HasOption('i','interface') then
    FSpeaker.Intf := TCmdLnInterface.Create
  else
    FSpeaker.Intf := TPluginInterface.Create(GetOptionValue('i','interface'));
  if not Assigned(FSpeaker.Intf) then Terminate;
  FSpeaker.Intf.OnGetParameter:=@FSpeakerGetParameter;
  FSpeaker.OnSystemMessage:=@FSpeakerSystemMessage;
  FSpeaker.OnDebugMessage:=@FSpeakerDebugMessage;
  if not HasOption('q','quiet') then
    writeln('Connecting...');
  FSpeaker.Intf.Connect;
  if not HasOption('q','quiet') then
    writeln('Started OK...');
  while FSpeaker.Process(True) do sleep(100);
  if not HasOption('q','quiet') then
    writeln('Disconnecting...');
  FSpeaker.Intf.Disconnect;
  // stop program loop
  write(strPressanykey);
  readln;
  Terminate;
end;

constructor TThalia.Create(TheOwner: TComponent);
var
  displayname: String;
begin
  inherited Create(TheOwner);
  displayname := GetOptionValue('u','displayname');
  if displayname = '' then
    displayname := 'Thalia';
  FSpeaker := TSpeaker.Create(displayname,'deutsch');
  FSpeaker.FastAnswer := HasOption('a','fastanswer');
  FSpeaker.BeQuiet := HasOption('q','quiet');
  FSpeaker.Autofocus := HasOption('f','autofocus');
  FSpeaker.IgnoreUnicode := HasOption('i','ignoreunicode');
  OnException :=@ThaliaException;
end;

destructor TThalia.Destroy;
begin
  if Assigned(FSpeaker) then
    begin
      if Assigned(FSpeaker.Intf) then
        FSpeaker.Intf.Disconnect;
      FSpeaker.Free;
    end;
  inherited Destroy;
end;

procedure TThalia.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ',ExeName,' [options]');
  writeln(' -h    --help      Show this help screen');
  writeln(' -i    --interface Select input plugin');
  writeln('Example:');
  writeln(' thalia --interface=irc --server=irc.mynetwork.com --channel=#thalia');
end;

var
  Application: TThalia;
begin
  Application:=TThalia.Create(nil);
  Application.Run;
  Application.Free;
end.

