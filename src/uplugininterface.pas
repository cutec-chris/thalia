unit uPluginInterface;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,uSpeaker,uIntfStrConsts
  {$IFDEF WINDOWS}
  ,Windows
  {$ENDIF}
  {$IFDEF UNIX}
  ,dl
  {$ENDIF}
  ;

type
  TGetParamCallback = function(short : char;long : pchar) : pchar;stdcall;
  TTalkToFunction = procedure(user,sentence : PChar); stdcall;
  TWOPFunction = procedure;stdcall;
  TProcessFunction = function : Boolean;stdcall;
  TTalkCallback = procedure(sender : PChar;sentence : PChar;Priv : Boolean);stdcall;
  TSetCallbacksFunction = procedure(CB : TTalkCallback;GP : TGetParamCallback);stdcall;
  TGetIDFunction = function : PChar;stdcall;
  TIsUserFunction = function(User : PChar) : Boolean;stdcall;
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
  public
    constructor Create(intf : string);
    destructor Destroy;override;
    procedure Connect;override;
    procedure Disconnect;override;
    procedure Talk(user,sentence : string);override;
    function Process : Boolean;override;
    function GetID : string;override;
    function IsUser(user : string) : Boolean;override;
  end;

implementation

var
  FGetParameter : TGetParameterEvent;
  FTalk : TTalkEvent;

{ TPluginInterface }

procedure FTalkCallback(Sender : pchar;Sentence: PChar;Priv : Boolean);stdcall;
begin
  if Assigned(FTalk) then
    FTalk(Sender,Sentence,Priv);
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
  {$ELSE}
  FLib := dlopen(PChar(LibPath),RTLD_LAZY);
  if not Assigned(FLib) then raise Exception.Create(strPluginInvalid);
  FTalkTo := TTalkToFunction(dlsym(FLib,'TalkTo'));
  FConnect := TWOPFunction(dlsym(FLib,'Connect'));
  FDisconnect := TWOPFunction(dlsym(FLib,'DisConnect'));
  FProcess := TProcessFunction(dlsym(FLib,'Process'));
  FGetID := TGetIDFunction(dlsym(FLib,'GetID'));
  FIsUser := TIsUserFunction(dlsym(FLib,'IsUser'));
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

procedure TPluginInterface.Talk(user,sentence: string);
begin
  FTalkTo(PChar(user),PChar(sentence));
end;

function TPluginInterface.Process: Boolean;
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

end.

