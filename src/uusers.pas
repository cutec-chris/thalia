unit uUsers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uSpeaker;

implementation

function HandleTalk(Speaker : TSpeaker;language : string;var sentence : string;var canhandle : Boolean) : Boolean;
begin
  Result:=False;
  canhandle:=(pos('$userinfo(',sentence)>0);
  {
  if pos('$getdescription(de)',sentence)>0 then
    begin
      sentence:='Oder Informationen über andere Benutzer erfragen.';
      result := true;
      canhandle:=true;
      exit;
    end;
  }
  if not canhandle then exit;
end;

end.

