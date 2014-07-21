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
unit uPluginInterface;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,uSpeaker
  {$IFDEF WINDOWS}
  ,Windows
  {$ENDIF}
  {$IFDEF UNIX}
  ,dl
  {$ENDIF}
  ;

type
  TGetParamCallback = function(short : char;long : pchar) : pchar;stdcall;
  TTalkToFunction = procedure(user,sentence : PChar;FSentenceID : Int64); stdcall;
  TWOPFunction = procedure;stdcall;
  TProcessFunction = function : Boolean;stdcall;
  TTalkCallback = procedure(sender : PChar;sentence : PChar;Priv : Boolean;FSentenceID : Int64);stdcall;
  TSetCallbacksFunction = procedure(CB : TTalkCallback;GP : TGetParamCallback);stdcall;
  TGetIDFunction = function : PChar;stdcall;
  TIsUserFunction = function(User : PChar) : Boolean;stdcall;
  TWhoisFunction = function(User : PChar) : PChar;stdcall;
  { TPluginInterface }

  TPluginInterface = class(TSpeakerInterface)
  private
    {$IFDEF WINDOWS}
    FLib : THandle;
    {$ELSE}
    FLib : Pointer;
    {$ENDIF}
    FTalkTo : TTalkToFunction;
    FConnect : TWOPFunction;
    FDisconnect : TWOPFunction;
    FProcess : TProcessFunction;
    FGetID : TGetIDFunction;
    FIsUser : TIsUserFunction;
    FWhois : TWhoisFunction;
  public
    constructor Create(intf : string);
    destructor Destroy;override;
    procedure Connect;override;
    procedure Disconnect;override;
    procedure Talk(user,sentence : string;AnswerTo : Int64 = -1);override;
    function Process(NeedNewMessage : Boolean = False) : Boolean;override;
    function GetID : string;override;
    function IsUser(user : string) : Boolean;override;
    function Whois(user : string) : string;override;
  end;

implementation
resourcestring
  strPluinnotFound                      = 'The Inerface dont exists.';
  strPluginInvalid                      = 'The Interface coudnt be loaded';
var
  FGetParameter : TGetParameterEvent;
  FTalk : TTalkEvent;

{ TPluginInterface }

procedure FTalkCallback(Sender : pchar;Sentence: PChar;Priv : Boolean;FSentenceID : Int64);stdcall;
begin
  if Assigned(FTalk) then
    FTalk(Sender,Sentence,Priv,FSentenceID);
end;

function FGetParamCallback(short: char; long: pchar): pchar;stdcall;
begin
  if Assigned(FGetParameter) then
    Result := PChar(FGetParameter(short,long));
end;

constructor TPluginInterface.Create(intf: string);
var
  LibPath: String;
begin
  LibPath := ExtractFilePath(ParamStr(0))+'plugins'+DirectorySeparator+{$IFDEF UNIX}'lib'+{$ENDIF}intf+{$IFDEF WINDOWS}'.dll'{$ENDIF}{$IFDEF UNIX}'.so'{$ENDIF};
  if not FileExists(LibPath) then Exception.Create(strPluinnotFound);
  {$IFDEF WINDOWS}
  FLib := LoadLibrary(PChar(LibPath));
  if FLib = 0 then Exception.Create(strPluinnotFound);
  FTalkTo := TTalkToFunction(GetProcAddress(FLib,'TalkTo'));
  FConnect := TWOPFunction(GetProcAddress(FLib,'Connect'));
  FDisconnect := TWOPFunction(GetProcAddress(FLib,'DisConnect'));
  FProcess := TProcessFunction(GetProcAddress(FLib,'Process'));
  FGetID := TGetIDFunction(GetProcAddress(FLib,'GetID'));
  FIsUser := TIsUserFunction(GetProcAddress(FLib,'IsUser'));
  FWhois := TWhoisFunction(GetProcAddress(FLib,'Whois'));
  {$ELSE}
  FLib := dlopen(PChar(LibPath),RTLD_LAZY);
  if not Assigned(FLib) then raise Exception.Create(strPluginInvalid);
  FTalkTo := TTalkToFunction(dlsym(FLib,'TalkTo'));
  FConnect := TWOPFunction(dlsym(FLib,'Connect'));
  FDisconnect := TWOPFunction(dlsym(FLib,'DisConnect'));
  FProcess := TProcessFunction(dlsym(FLib,'Process'));
  FGetID := TGetIDFunction(dlsym(FLib,'GetID'));
  FIsUser := TIsUserFunction(dlsym(FLib,'IsUser'));
  FWhois := TWhoisFunction(dlsym(FLib,'Whois'));
  {$ENDIF}
end;

destructor TPluginInterface.Destroy;
begin
  inherited Destroy;
  {$IFDEF WINDOWS}
  if Flib <> 0 then
    FreeLibrary(FLib);
  {$ELSE}
  if Assigned(FLib) then
    dlclose(FLib);
  {$ENDIF}
end;

procedure TPluginInterface.Connect;
var
  SetCallbacks : TSetCallbacksFunction;
begin
  FGetParameter := OnGetParameter;
  FTalk := OnTalk;
  {$IFDEF WINDOWS}
  SetCallbacks := TSetCallbacksFunction(GetProcAddress(FLib,'SetCallbacks'));
  SetCallbacks(@FTalkCallback,@FGetParamCallback);
  {$ELSE}
  SetCallbacks := TSetCallbacksFunction(dlsym(FLib,'SetCallbacks'));
  SetCallbacks(@FTalkCallback,@FGetParamCallback);
  {$ENDIF}
  FConnect;
end;

procedure TPluginInterface.Disconnect;
begin
  FDisconnect;
end;

procedure TPluginInterface.Talk(user, sentence: string; AnswerTo: Int64);
begin
  FTalkTo(PChar(user),PChar(sentence),AnswerTo);
end;

function TPluginInterface.Process(NeedNewMessage: Boolean): Boolean;
begin
  Result := FProcess();
end;

function TPluginInterface.GetID: string;
begin
  Result:= string(FGetID());
end;

function TPluginInterface.IsUser(user: string): Boolean;
begin
  Result:=FIsUser(PChar(user));
end;

function TPluginInterface.Whois(user: string): string;
begin
  Result := '';
  if Assigned(FWhois) then
    Result := FWhois(PChar(User));
end;

end.

