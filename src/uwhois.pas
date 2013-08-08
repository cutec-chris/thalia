unit uwhois;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LNet;

type

  { TWhoisClient }

  TWhoisClient = class
    procedure SocketConnect(aSocket: TLSocket);
    procedure SocketDisconnect(aSocket: TLSocket);
    procedure SocketReceive(aSocket: TLSocket);
  private
    FDomain : string;
    FCommand : string;
  public
    Socket : TLTcp;
    procedure Execute(Domain : string);
    constructor Create;
    destructor Destroy;
  end;

implementation

{ TWhoisClient }

procedure TWhoisClient.SocketConnect(aSocket: TLSocket);
begin
  Socket.SendMessage(FCommand);
end;

procedure TWhoisClient.SocketDisconnect(aSocket: TLSocket);
begin

end;

procedure TWhoisClient.SocketReceive(aSocket: TLSocket);
begin

end;

procedure TWhoisClient.Execute(Domain: string);
begin
  FDomain := Domain;
  FCommand := Format('+%1:s',[FDomain]);
  Socket.Connect('whois.arin.net',43);
end;

constructor TWhoisClient.Create;
begin
  Socket := TLTcp.Create(nil);
  Socket.OnConnect:=@SocketConnect;
  Socket.OnReceive:=@SocketReceive;
  Socket.OnDisconnect:=@SocketDisconnect;
end;

destructor TWhoisClient.Destroy;
begin
  Socket.Free;
end;

end.

