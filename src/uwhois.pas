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

