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
unit uUsers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uSpeaker,uwhois, dnssend;

function getUserIP(Speaker : TSpeaker;aUser : string) : string;

implementation

function HandleTalk(Speaker : TSpeaker;language : string;var sentence : string;var canhandle : Boolean) : Boolean;
var
  tmp: String;
  tmp1: String;
  avar: String;
  sl: TStringList;
begin
  Result:=False;
  canhandle:=(pos('$userinfo(',sentence)>0);
  if pos('$getdescription(de)',sentence)>0 then
    begin
      sentence:='Oder Informationen über andere Benutzer erfragen.';
      result := true;
      canhandle:=true;
      exit;
    end;
  if not canhandle then exit;
  tmp := copy(sentence,0,pos('$userinfo(',sentence)-1);
  tmp1 :=copy(sentence,pos('$userinfo(',sentence)+10,length(sentence));
  avar := copy(tmp1,0,pos(')',tmp1)-1);
  tmp1 := copy(tmp1,pos(')',tmp1)+1,length(tmp1));
  if trim(avar) = '' then exit;
  sentence:=getUserIP(Speaker,avar);
  Result := sentence<>'';
end;

function getUserIP(Speaker : TSpeaker;aUser: string): string;
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  sl.Text := Speaker.Intf.Whois(aUser);
  if (sl.Count>0) then
    Result:=sl[0]
  else Result := '';
  sl.Free;
end;

initialization
  RegisterToSpeaker(@HandleTalk);
end.

