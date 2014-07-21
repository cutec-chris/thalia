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

Erinnere mich wenn ich zuhause eintreffe ans abwaschen

Notiere: Nik schlagen.

Suche meine Notiz Urlaub 2013.

Zeige mir meine Notizen von gestern.
}


interface

uses
  Classes, SysUtils, uSpeaker,uspokentimes;

implementation

var
  Timer : TDateTime;

resourcestring
  strTimer1             = '+timer+auf=time';
  strTimer2             = '+zeig|zeige+timer';
  strTimerQ2            = '+steht|macht+timer';
  strTimerQ3            = '+timer+gesetzt';
  strShowTimerAnswer    = 'Der Timer läuft $showtimer() ab.$ignorelastanswer()';
  strTimer3             = '+stoppe|halte+timer';
  strTimer4             = '+starte+timer';
  strTimer5             = '+setze+timer+zurück';
  strNoTimerSet         = 'Es ist kein Timer gestellt !';

procedure AddSentences;
begin
  if AddSentence(strTimer1,'reminder',stUnknown) then
    AddAnswer('$timer($time)OK$ignorelastanswer()');
  if AddSentence(strTimer2,'reminder',stUnknown) then
    AddAnswer(strShowTimerAnswer);
  if AddSentence(strTimerQ2,'reminder',stQuestion) then
    AddAnswer(strShowTimerAnswer);
  if AddSentence(strTimerQ3,'reminder',stQuestion) then
    AddAnswer(strShowTimerAnswer);
  if AddSentence(strTimer3,'reminder',stUnknown) then
    AddAnswer('OK$stoptimer()$ignorelastanswer()');
  if AddSentence(strTimer4,'reminder',stUnknown) then
    AddAnswer('OK$starttimer()$ignorelastanswer()');
  if AddSentence(strTimer5,'reminder',stUnknown) then
    AddAnswer('OK$resettimer()$ignorelastanswer()');
end;

function HandleTalk(Interlocutor : TInterlocutor;language : string;var sentence : string;var canhandle : Boolean) : Boolean;
var
  tmp: String;
  tmp1: String;
  afunc: String;
  avar: String;
  aNewTime: TDateTime;
  aNewTimeDiff: TDateTime;
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
      sentence:='Ich kann Sie auch an Sachen erinnern und einen Timer setzen.';
      result := true;
      canhandle:=true;
      exit;
    end;
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
      'showtimer':
        begin
          if Interlocutor.Properties['TIMER'] <> '' then
            begin
              sentence := sentence+SpokenTimeRangeToStr(Now()+StrToFloat(Interlocutor.Properties['TIMERVAL']));
              Result := True;
            end
          else
            begin
              sentence := strNoTimerSet;
              Result := True;
              exit;
            end;
        end;
      'starttimer':
        begin
          if Interlocutor.Properties['TIMER'] <> '' then
            begin
              Interlocutor.Properties['TIMERVAL'] := Interlocutor.Properties['TIMER'];
              Result := True;
            end
          else
            begin
              sentence := strNoTimerSet;
              Result := True;
              exit;
            end;
        end;
      'stoptimer','resettimer':
        begin
          if Interlocutor.Properties['TIMER'] <> '' then
            begin
              Interlocutor.Properties['TIMERVAL'] := '';
              Result := True;
            end
          else
            begin
              sentence := strNoTimerSet;
              Result := True;
              exit;
            end;
        end;
      'timer':
        begin
          if ParseTime(avar,aNewTime,aNewTimeDiff) then
            begin
              Interlocutor.Properties['TIMER'] := FloatToStr(aNewTime);
              Interlocutor.Properties['TIMERVAL'] := Interlocutor.Properties['TIMER'];
              result := True;
            end;
        end;
      end;
      sentence:=sentence+tmp1;
    end;
end;

procedure Chron(Speaker : TSpeaker);
begin

end;

initialization
  RegisterToSpeaker(@HandleTalk,@AddSentences);
  RegisterChron(@Chron);
end.

