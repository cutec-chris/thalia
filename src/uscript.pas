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

unit uscript;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uSpeaker;

implementation

var
  Timer : TDateTime;

function HandleTalk(Interlocutor : TInterlocutor;language : string;var sentence : string;var canhandle : Boolean) : Boolean;
var
  tmp: String;
  tmp1: String;
  afunc: String;
  avar: String;
begin
  Result:=False;
  canhandle:=(pos('$script(',sentence)>0)
          ;
  if not canhandle then exit;
  tmp := sentence;
  sentence:='';
  while pos('$',tmp)>0 do
    begin
      sentence:=sentence+copy(tmp,0,pos('$',tmp)-1);
      tmp1 :=copy(tmp,pos('$',tmp)+1,length(tmp));
      tmp:=copy(tmp,pos(')',tmp)+1,length(tmp));
      afunc := copy(tmp1,0,pos('(',tmp1)-1);
      tmp1 :=copy(tmp,pos('(',tmp)+1,length(tmp));
      avar := copy(tmp1,0,pos(')',tmp1)-1);
      tmp1 := copy(tmp1,pos(')',tmp1)+1,length(tmp1));
      //next function in func, parameters in avar
      case afunc of
      'script':
        begin

        end;
      end;
      sentence:=sentence+tmp1;
    end;
end;

procedure Chron(Speaker : TSpeaker);
begin

end;

procedure CompileScripts;
begin

end;

initialization
  RegisterToSpeaker(@HandleTalk);
  RegisterChron(@Chron);
  CompileScripts;
end.

