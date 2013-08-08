library irc;

{$H+}

uses
   Classes
  ,SysUtils
  ,uirc;

type
  TTalkCallback = procedure(sender : PChar;sentence : PChar;Priv : Boolean);stdcall;
  TGetParamCallback = function(short : char;long : pchar) : pchar;stdcall;

  { TFakeObject }

  TFakeObject = class
    procedure Debug(const S: string);
    procedure SystemMsg(const S: string);
    procedure MessageReceived(From : string;Msg : string;PrivateMessage : Boolean);
    procedure OnConnect(Snder : TObject);
  end;

var
  Talk : TTalkCallback;
  GetParam : TGetParamCallback;
  FO : TFakeObject;
  FChannel : string;
  IRCServer : TIRCClient;
  username: String;

{ TFakeObject }

procedure TFakeObject.Debug(const S: string);
begin
  Talk(Pchar('debug'),PChar(s+#10#13),true);
end;

procedure TFakeObject.SystemMsg(const S: string);
begin
  Talk(PChar('system'),PChar(s+#10#13),true);
end;

procedure TFakeObject.MessageReceived(From: string; Msg: string;
  PrivateMessage: Boolean);
begin
  Talk(PChar(From),PChar(Msg+#10#13),PrivateMessage);
end;

procedure TFakeObject.OnConnect(Snder: TObject);
begin
  if FChannel <> '' then
    IRCServer.Join(FChannel);
end;

procedure TalkTo(user,sentence : PChar);stdcall;
var
  i : integer;
begin
//  for i := 0 to length(sentence) do
//    IRCServer.DoSleep(100);
  if Assigned(IRCServer) then
    begin
      if user <> '' then
        IRCServer.SendMessage(user,sentence)
      else if GetParam('c','channel') <> '' then
        IRCServer.SendMessage(GetParam('c','channel'),sentence)
      else
        IRCServer.SendMessage('',sentence);
    end;
end;

procedure Connect;stdcall;
begin
  IRCServer := TIRCClient.Create;
  FO := TFakeObject.Create;
  IRCServer.OnMessageReceived:=@FO.MessageReceived;
  IRCServer.OnDebug:=@FO.Debug;
  IRCServer.OnSystemMsg:=@FO.SystemMsg;
  IRCServer.OnConnected:=@FO.OnConnect;
  IRCServer.Nickname := GetParam('n','displayname');
  if IRCServer.Nickname = '' then
    IRCServer.Nickname := 'Thalia';
  IRCServer.Username:=IRCServer.Nickname;
  IRCServer.Password := GetParam('p','password');
  FChannel := GetParam('c','channel');
  IRCServer.Server := GetParam('s','server');
  Talk('system',PChar('connecting to server '+GetParam('s','server')+#10#13),true);
  IRCServer.Connected := True;
end;

procedure Disconnect;stdcall;
begin
  IRCServer.Free;
  IRCServer := nil;
end;

function GetID : PChar;
begin
  Result := PChar(FChannel);
end;

function IsUser(User : PChar) : Boolean;stdcall;
begin
  Result := IRCServer.Users.IndexOf(lowercase(User)) > -1;
end;

procedure SetCallbacks(CB : TTalkCallback;GP : TGetParamCallback);stdcall;
begin
  Talk := CB;
  GetParam := GP;
end;

function Process : Boolean;stdcall;
begin
  if Assigned(IRCServer) then
    IRCServer.Process;
  Result := IRCServer.Connected;
end;

exports
  SetCallbacks,
  TalkTo,
  Connect,
  DisConnect,
  Process,
  IsUser,
  GetID;

begin
end.
