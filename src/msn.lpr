library msn;

{$mode delphi}{$H+}

uses
   Classes
  ,lNet
  ,httpsend
  ,ssl_openssl
  ,SysUtils
  ,Math
  ,md5, synapse;

type
  TTalkCallback = procedure(sender : PChar;sentence : PChar;Priv : Boolean);stdcall;
  TGetParamCallback = function(short : char;long : pchar) : pchar;stdcall;

var
  Talk : TTalkCallback;
  GetParam : TGetParamCallback;
  GetDataMethod : TMethod;
  Connected : Boolean;
  atime : DWORD;

type
  TMSNServer = class;

  { TMSNSwitchboard }

  TMSNSwitchboard = class
    procedure SocketConnect(aSocket: TLSocket);
    procedure SocketDisconnect(aSocket: TLSocket);
    procedure SocketReceive(aSocket: TLSocket);
  private
    FSID : string;
    FAuth : string;
    FParent : TMSNServer;
    procedure DoSendMessage(msg : string);
  public
    Socket : TLTcp;
    Users : TStringList;
    constructor Create(SID : string;Address : string;Auth : string;User : string;Parent : TMSNServer);
    procedure SendMessage(msg : string);
  end;
  
  { TMSNServer }

  TMSNServer = class(TList)
    procedure SocketDisconnect(aSocket: TLSocket);
  private
    FConnected : Boolean;
    function  GetSwitchboards(User : string): TMSNSwitchboard;
    procedure SocketConnect(aSocket: TLSocket);
    procedure SocketReceive(aSocket: TLSocket);
    procedure DoSendMessage(msg : string);
  public
    Socket : TLTcp;
    property Switchboards[User : string] : TMSNSwitchboard read GetSwitchboards;
    constructor Create;
    destructor Destroy;
    procedure Process;
  end;

function RPos(const Substr: string; const S: string): Integer;
var
  SL, i : Integer;
begin
  SL := Length(Substr);
  i := Length(S);
  if (Substr = '') or (S = '') or (SL > i) then begin
    Result := 0;
    Exit;
  end;

  while i >= SL do begin
    if S[i] = Substr[SL] then begin
      if Copy(S, i - SL + 1, SL) = Substr then begin
        Result := i - SL + 1;
        Exit;
      end;
    end;
    Dec(i);
  end;
  Result := i;
end;

{ TMSNSwitchboard }

procedure TMSNSwitchboard.SocketConnect(aSocket: TLSocket);
begin
  Talk('system',PChar('connected to switchboard '+FSID+'...'#10#13),True);
  DoSendMessage('ANS 1 '+GetParam('u','user')+' '+FAuth+' '+FSID);
end;

procedure TMSNSwitchboard.SocketDisconnect(aSocket: TLSocket);
begin
  Talk('system',PChar('disconnected to switchboard '+FSID+'...'#10#13),True);
  FParent.Remove(Self);
  Free;
end;

procedure TMSNSwitchboard.SocketReceive(aSocket: TLSocket);
var
  cmd: TStringList;
  tmp : string;
  sl: TStringList;
  i: Integer;
begin
  cmd := TStringlist.Create;
  aSocket.GetMessage(tmp);
  Talk('debug',PChar(FSID+'<<< '+tmp+#10#13),True);
  cmd.Delimiter:=' ';
  cmd.DelimitedText:=tmp;
  if cmd.Count = 0 then exit;
  if      cmd[0] = 'MSG' then
    begin
      sl := TStringlist.Create;
      sl.text := tmp;
      sl.delete(0);
      while (sl.count > 0) and ((sl[0] = '') or (pos(':',sl[0]) > 0)) do
        sl.delete(0);
      for i := 0 to sl.Count-1 do
        if trim(sl[i]) <> '' then
          Talk(PChar(cmd[2]),PChar(sl[i]+#10#13),True);
      sl.Free;
    end
  else if cmd[0] = 'BYE' then
    begin
      FParent.Remove(Self);
      Free;
    end;
end;

procedure TMSNSwitchboard.DoSendMessage(msg: string);
begin
  Talk('debug',PChar(FSID+'>>> '+msg+#10#13),True);
  Socket.SendMessage(msg+#13#10);
end;

constructor TMSNSwitchboard.Create(SID: string; Address: string; Auth: string;
  User: string;Parent : TMSNServer);
begin
  Socket := TLTcp.Create(nil);
  Socket.OnConnect:=SocketConnect;
  Socket.OnReceive:=SocketReceive;
  Socket.OnDisconnect:=SocketDisconnect;
  FSID := SID;
  FAuth := Auth;
  FParent := Parent;
  Users := TStringList.Create;
  Users.Add(User);
  Socket.Connect(copy(Address,0,pos(':',Address)-1),StrToInt(copy(Address,pos(':',Address)+1,length(Address))));
end;

procedure TMSNSwitchboard.SendMessage(msg: string);
begin
  msg := 'MIME-Version: 1.0'+#13#10
        +'Content-Type: text/plain; charset=UTF-8'+#13#10
        +'X-MMS-IM-Format: FN=MS%20Sans%20Serif; EF=; CO=0; CS=0; PF=0'+#13#10
        +#13#10
        +AnsiToUTF8(msg);
  Talk('debug',PChar(FSID+'>>> MSG 2 N '+IntToStr(length(msg))+#10#13+msg+#10#13),True);
  Socket.SendMessage('MSG 2 N '+IntToStr(length(msg))+#13#10+msg);
end;

var
  MSNServer : TMSNServer;

{ TMSNServer }

procedure TMSNServer.SocketDisconnect(aSocket: TLSocket);
begin
  Talk('system',PChar('disconnected...'#10#13),True);
  if FConnected then
    Connected := False;
end;

function TMSNServer.GetSwitchboards(User : string): TMSNSwitchboard;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count-1 do
    if TMSNSwitchBoard(Items[i]).Users.IndexOfName(User) > -1 then
      begin
        Result := TMSNSwitchBoard(Items[i]);
      end;
end;

procedure TMSNServer.SocketConnect(aSocket: TLSocket);
var
  res : string;
  i: Integer;
begin
  Talk('system',PChar('connected...'#10#13),True);
  DoSendMessage('VER 0 MSNP9 CVR0');
end;

procedure TMSNServer.SocketReceive(aSocket: TLSocket);
var
  tmp,tmp1 : string;
  cmd : TStringList;
  http: THTTPSend;
  FUsername: string;
  FPassword: string;
  sl : TStringList;
  i: Integer;
begin
  FUsername := GetParam('u','user');
  FPassword := GetParam('p','password');
  cmd := TStringlist.Create;
  aSocket.GetMessage(tmp);
  Talk('debug',PChar('<<< '+tmp+#10#13),True);
  cmd.Delimiter:=' ';
  cmd.DelimitedText:=tmp;
  if cmd.Count=0 then
    begin
      cmd.Free;
      exit;
    end;
  if      cmd[0] = 'VER' then
    begin
      DoSendMessage('CVR 1 0x0409 win 4.10 i386 MSNMSGR 5.0.0544 MSMSGS '+FUsername);
    end
  else if cmd[0] = 'CVR' then
    begin
      DoSendMessage('USR 2 TWN I '+GetParam('u','user'));
    end
  else if cmd[0] = 'XFR' then
    begin
      Socket.Disconnect;
      Socket.Connect(copy(cmd[3],0,pos(':',cmd[3])-1),StrToInt(copy(cmd[3],pos(':',cmd[3])+1,length(cmd[3]))));
    end
  else if cmd[0] = 'USR' then
    begin
      if cmd[2] = 'OK' then
        begin
          DoSendMessage('SYN 4 0');
          exit;
        end;
      
      http:= THTTPSend.Create;
      http.HTTPMethod('GET','https://nexus.passport.com/rdr/pprdr.asp');
      tmp := copy(http.Headers.Text,pos('DALogin=',http.Headers.Text)+8,length(http.Headers.Text));
      tmp := copy(tmp,0,pos(',',tmp)-1);
      
      http.Headers.Clear;
      http.Headers.Add('Authorization: Passport1.4 OrgVerb=GET,OrgURL=http%3A%2F%2Fmessenger%2Emsn%2Ecom,sign-in='+StringReplace(FUsername,'@','%40',[rfReplaceAll])+',pwd='+FPassword+','+cmd[4]);
      http.UserAgent:= 'MSMSGS';
      http.HTTPMethod('GET','https://'+tmp);

      Talk('debug',PChar('Tweener: '+http.Headers.Text+#10#13),True);

      tmp := copy(http.Headers.Text,pos('Authentication-Info',http.Headers.Text)+19,length(http.Headers.Text));
      tmp := copy(tmp,pos('t=',tmp),length(tmp));
      tmp := copy(tmp,0,pos('''',tmp)-1);
      http.Free;

      DoSendMessage('USR 3 TWN S '+tmp);
    end
  else if cmd[0] = 'SYN' then
    begin
      //Todo Sync Conact List
      sl := TStringlist.Create;
      sl.Text := tmp;
      for i := 0 to sl.Count-1 do
        if copy(sl[i],0,3) = 'LST' then
          begin
            if copy(sl[i],rpos(' ',sl[i])+1,length(sl[i])) = '8' then
              DoSendMessage('ADD 7 AL '+copy(sl[i],5,length(sl[i])-6));
          end;
      sl.Free;
      DoSendMessage('CHG 5 NLN'); //go online
      FConnected := True;
    end
  else if cmd[0] = 'CHL' then   //Ping
    begin
      Socket.SendMessage('QRY 6 msmsgs@msnmsgr.com 32'+#13#10+MD5Print(MD5String(cmd[2]+'Q1P7W2E4J9R8U3S5')));
      Talk('debug',PChar('>>>QRY 6 msmsgs@msnmsgr.com 32'+#13#10+MD5Print(MD5String(cmd[2]+'Q1P7W2E4J9R8U3S5'))+#10#13),True);
    end
  else if cmd[0] = 'RNG' then
    begin
      Add(TMSNSwitchboard.Create(cmd[1],cmd[2],cmd[4],cmd[6]+'='+cmd[5],Self));
    end
  else if (cmd[0] = 'ADD') and (cmd[2] = 'RL') then
    begin
//      ADD 0 RL 0 maurawani@hotmail.com dreaming%20this%20world
      DoSendMessage('ADD 8 AL '+StringReplace(StringReplace(copy(tmp,12,length(tmp)),#10,'',[rfReplaceAll]),#13,'',[rfReplaceAll]));
    end;
  cmd.Free;
end;

procedure TMSNServer.DoSendMessage(msg: string);
begin
  Talk('debug',PChar('>>> '+msg+#10#13),True);
  Socket.SendMessage(msg+#13#10);
  Socket.CallAction;
end;

constructor TMSNServer.Create;
begin
  Socket := TLTcp.Create(nil);
  Socket.OnConnect:=SocketConnect;
  Socket.OnDisconnect:=SocketDisconnect;
  Socket.OnReceive:=SocketReceive;
  FConnected := False;
  inherited Create;
end;

destructor TMSNServer.Destroy;
begin
  Socket.Free;
end;

procedure TMSNServer.Process;
var
  i: Integer;
begin
  if DWord(Trunc(Now * 24 * 60 * 60))-atime > 60 then
    begin
      atime := DWord(Trunc(Now * 24 * 60 * 60));
      DoSendMessage('PNG');
    end;
  Socket.CallAction;
  for i := 0 to Count-1 do
    begin
      try
        TMSNSwitchboard(Items[i]).Socket.CallAction;
      except
      end;
    end;
end;

procedure GetData(aSocket: TLSocket);
begin
end;

procedure TalkTo(user,sentence : PChar);stdcall;
var
  Switchboard: TMSNSwitchboard;
begin
  if Assigned(MSNServer) then
    begin
      Switchboard := MSNServer.Switchboards[user];
      if Assigned(Switchboard) then
        Switchboard.SendMessage(sentence);
    end;
end;

procedure Connect;stdcall;
var
  server : string;
begin
  Connected := True;
  MSNServer := TMSNServer.Create;
  server := GetParam('s','server');
  if server = '' then server := 'messenger.hotmail.com';//'gateway.messenger.hotmail.com';
  Talk('system',PChar('connecting to server '+server+#10#13),true);
  MSNServer.Socket.Connect(server,1863{80});
end;

procedure Disconnect;stdcall;
begin
  MSNServer.DoSendMessage('OUT');
  MSNServer.Socket.CallAction;
  MSNServer.Free;
  MSNServer := nil;
end;

function GetID : PChar;
begin
  Result := '_MSN';
end;

procedure SetCallbacks(CB : TTalkCallback;GP : TGetParamCallback);stdcall;
begin
  Talk := CB;
  GetParam := GP;
end;

function IsUser(User : PChar) : Boolean;stdcall;
begin
  Result := False;
end;

function Process : Boolean;stdcall;
begin
  if Assigned(MSNServer) then
    MSNServer.Process;
  Result := Connected;
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

