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

unit ureminder;

{$mode objfpc}{$H+}

{
x Stelle den Timer auf 5 Minuten.
x Zeige mir den Timer.
x Halte den Timer an.
x Stelle den Timer wieder an.
x Setze den Timer zurück.

Erinnere mich: Daheim anrufen.
Erinnere mich morgen früh um 8: Schwimmsachen mitnehmen
Erinnere mich daran „Blumen gießen“, wenn ich nach Hause ankomme.

Notiere: Nik schlagen.

Suche meine Notiz Urlaub 2013.

Zeige mir meine Notizen von gestern.
}


interface

uses
  Classes, SysUtils, uSpeaker,uspokentimes;

implementation

function HandleTalk(Speaker : TSpeaker;language : string;var sentence : string;var canhandle : Boolean) : Boolean;
begin
  Result:=False;
  canhandle:=(pos('$timer(',sentence)>0)
          or (pos('$showtimer(',sentence)>0)
          or (pos('$starttimer(',sentence)>0)
          or (pos('$stoptimer(',sentence)>0)
          or (pos('$resettimer(',sentence)>0)
          ;
  if pos('$getdescription(de)',sentence)>0 then
    begin
      sentence:='Ich kann Sie auch an Sachen erinnern.';
      result := true;
      canhandle:=true;
      exit;
    end;
  if not canhandle then exit;

end;

procedure Chron(Speaker : TSpeaker);
begin

end;

resourcestring
  strTimer1             = '+timer+auf=time';
  strTimer2             = '+zeig|zeige+timer';
  strTimer3             = '+stoppe|halte+timer';
  strTimer4             = '+starte|stelle+timer';
  strTimer5             = '+setze+timer+zurück';

procedure AddSentences;
begin
  if AddSentence(strTimer1,'reminder',1) then
    AddAnswer('$timer($parsetime($time))$ignorelastanswer');
  if AddSentence(strTimer2,'reminder',1) then
    AddAnswer('$showtimer$ignorelastanswer');
  if AddSentence(strTimer3,'reminder',1) then
    AddAnswer('$stoptimer$ignorelastanswer');
  if AddSentence(strTimer4,'reminder',1) then
    AddAnswer('$starttimer$ignorelastanswer');
  if AddSentence(strTimer5,'reminder',1) then
    AddAnswer('$resettimer$ignorelastanswer');
end;

initialization
  RegisterToSpeaker(@HandleTalk,@AddSentences);
  RegisterChron(@Chron);
end.

