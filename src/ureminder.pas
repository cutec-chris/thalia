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
    Wann ist mein nächster Termin?
    Was steht Dienstag in meinem Kalender?
    Wo ist meine nächste Besprechung?
    Wann ist die Besprechung mit Franzi?
    Erstelle einen Termin für morgen um 14 Uhr.
    Plane eine Besprechung heute um 11 Uhr im Tagungsraum.
    Verschiebe meinen heutigen Termin von 9 Uhr auf 11 Uhr.
    Füge Marcell zu meinem Termin heute um 11 Uhr hinzu.

    Stelle den Timer auf 5 Minuten.
    Zeige mir den Timer.
    Halte den Timer an.
    Stelle den Timer wieder an.
    Setze den Timer zurück.

    Erinnere mich: Daheim anrufen.
    Erinnere mich morgen früh um 8: Schwimmsachen mitnehmen
    Erinnere mich daran „Blumen gießen“, wenn ich nach Hause ankomme.


    Notiere: Nik schlagen.
    Suche meine Notiz Urlaub 2013.
    Zeige mir meine Notizen von gestern.

    Wie wir das Wetter am Samstag?
    Wird es in Lübeck diese Woche regnen?
    Was wird die Höchsttemperatur morgen in Köln?
    Ist es heute windig?

    Sende eine Mail an Peer wegen Urlaub.
    Schreibe eine Mail an Nik mit dem Inhalt: Kommst Du heute wieder zu spät?
    Zeige neue Mails von Nik.
    Zeige Mails von gestern zum Urlaub

    Wo ist Aileen?
    Wo ist mein Chef?
    Wer ist in der Nähe?
    Ist meine Oma zu Hause?
    Benachrichtige mich, wenn Oma zuhause ankommt.
    Benachrichtige Oma, wenn ich das Büro verlasse.

    Suche im Internet nach Akku-Tipps für iPhone.
    Suche auf Wikipedia nach Aluminium.
    Bing-Suche nach Berliner Musikgruppen.
    Rufe www.giga.de auf.
}


interface

uses
  Classes, SysUtils, uSpeaker;

implementation

function HandleTalk(Speaker : TSpeaker;language : string;var sentence : string;var canhandle : Boolean) : Boolean;
begin
  Result:=False;
  canhandle:=(pos('$remind(',sentence)>0);
  if pos('$getdescription(de)',sentence)>0 then
    begin
      sentence:='Ich kann Sie auch an Sachen erinnern.';
      result := true;
      canhandle:=true;
      exit;
    end;
  if not canhandle then exit;


end;

initialization
  RegisterToSpeaker(@HandleTalk);
end.

