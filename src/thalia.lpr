{*******************************************************************************
  Copyright (C) Christian Ulrich info@cu-tec.de

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or commercial alternative
  contact us for more information

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
*******************************************************************************}
program thalia;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp,uSpeaker,uPluginInterface,
  uIntfStrConsts,ZConnection,ZDataset, zcomponent_nogui,db,FileUtil;

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

  { TSQLData }

  TSQLData = class(TSpeakerData)
  private
    FData : TZConnection;
    FWords : TZQuery;
    FSentences : TZQuery;
    FAnswers : TZQuery;
  public
    constructor Create;
    destructor Destroy; override;
    function GetAnswers(aFilter: string): TDataSet; override;
    function GetScentences(aFilter: string): TDataSet; override;
    function GetWords(aFilter: string): TDataSet; override;
  end;

{ TSQLData }

constructor TSQLData.Create;
begin
  if not Assigned(FData) then
    begin
      FData := TZConnection.Create(nil);
      FWords := TZQuery.Create(nil);
      FSentences := TZQuery.Create(nil);
      FAnswers := TZQuery.Create(nil);
    end;
  FData.Protocol:='sqlite-3';
  FData.Database:=AppendPathDelim(ExtractFileDir(ParamStr(0)))+'dict.db';
  FData.HostName:='localhost';
  FData.Connect;
  FWords.Connection:=FData;
  FSentences.Connection:=FData;
  FAnswers.Connection:=FData;
end;

destructor TSQLData.Destroy;
begin
  FAnswers.Free;
  FSentences.Free;
  FWords.Free;
  FData.Free;
  inherited Destroy;
end;

function TSQLData.GetAnswers(aFilter: string): TDataSet;
begin
  FAnswers.SQL.Text:='select * from "ANSWERS" where '+aFilter;
  FAnswers.Open;
  Result := FAnswers;
end;

function TSQLData.GetScentences(aFilter: string): TDataSet;
begin
  FSentences.SQL.Text:='select * from "SENTENCES" where '+aFilter+' order by PRIORITY Asc,ID Asc';
  FSentences.Open;
  Result := FSentences;
end;

function TSQLData.GetWords(aFilter: string): TDataSet;
begin
  FWords.SQL.Text:='select * from "DICT" where '+aFilter;
  FWords.Open;
  Result := FWords;
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

resourcestring
  strpressanykey                        = 'Press any key to continue...';

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
  FSpeaker := TSpeaker.Create(displayname,'deutsch',TSQLData.Create);
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

