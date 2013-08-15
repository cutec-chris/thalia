unit umath;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MathParser, uSpeaker,Utils;

implementation

function HandleTalk(Speaker : TSpeaker;language : string;var sentence : string;var canhandle : Boolean) : Boolean;
var
  Parser: TMathParser;
  aOut: String;
  tmp: String;
  tmp1: String;
  avar: String;
  aTree: PTTermTreeNode;
  aRes: Extended;
begin
  Result:=False;
  canhandle:=(pos('$parse(',sentence)>0);
  if pos('$getdescription(de)',sentence)>0 then
    begin
      sentence:='Oder Mathematische berechnungen.';
      result := true;
      canhandle:=true;
      exit;
    end;
  if not canhandle then exit;
  tmp := copy(sentence,0,pos('$parse(',sentence)-1);
  tmp1 :=copy(sentence,pos('$parse(',sentence)+7,length(sentence));
  avar := copy(tmp1,0,rpos(')',tmp1)-1);
  tmp1 := copy(tmp1,rpos(')',tmp1)+1,length(tmp1));
  if trim(avar) = '' then exit;
  Parser := TMathParser.Create;
  aTree := Parser.ParseTerm(aVar);
  if Parser.ParseError=mpeNone then
    begin
      aOut := Parser.FormatTerm(aTree)+' = ';
      aRes := Parser.CalcTree(aTree);
      if Parser.ParseError=mpeNone then
        aOut := aOut+FloatToStr(aRes)
      else aOut := '';
    end;
  if aOut <> '' then
    begin
      Result := True;
      sentence:=trim(tmp+aout+tmp1);
    end;
  Parser.Free;
end;

initialization
  RegisterToSpeaker(@HandleTalk);
end.

