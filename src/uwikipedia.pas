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

unit uwikipedia;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,httpsend,uSpeaker,Utils,RegExpr;
function GetArticle(language,name : string) : string;
function SearchArticles(language,name : string;Start,Stop : Integer) : TStrings;
implementation
const
  url_article = 'http://%s.wikipedia.org/w/index.php?action=raw&title=%s';
  url_file = 'http://%s.wikipedia.org/w/index.php?title=Special:FilePath&file=%s';
  url_search = 'http://%s.wikipedia.org/w/api.php?action=query&list=search&srsearch=%s&sroffset=%d&srlimit=%d&format=json';

function GetArticle(language, name: string): string;
var
  http: THTTPSend;
  sl: TStringList;
begin
  Result := '';
  http := THTTPSend.Create;
  if http.HTTPMethod('GET',Format(url_article,[language,httpencode(name)])) then
    begin
      sl := TStringList.Create;
      sl.LoadFromStream(http.Document);
      Result := sl.Text;
      sl.Free;
    end;
end;

function SearchArticles(language, name: string; Start, Stop: Integer): TStrings;
begin

end;

function HandleTalk(Interlocutor : TInterlocutor;language : string;var sentence : string;var canhandle : Boolean) : Boolean;
var
  tmp,tmp1: String;
  avar: String;
  aOut: String;
  bOut : string = '';
  procedure RemoveTag(aTag : string;AllowShortenClose : Boolean = False);
  var
    ShortCloser: Boolean;
    aTagOpen: Integer;
  begin
    while pos('[['+aTag,lowercase(aout))>0 do
      begin
        bOut := bOut+copy(aout,0,pos('[['+aTag,lowercase(aout))-1);
        aOut := copy(aOut,pos('[['+aTag,lowercase(aout))+2+length(aTag),length(aOut));
        aTagOpen := 1;
        ShortCloser:=False;
        while (aTagOpen>0) and (length(aOut)>0) do
          begin
            if copy(aOut,0,2)='[[' then
              begin
                inc(aTagOpen);
                aOut := copy(aOut,2,length(aOut));
              end;
            if copy(aOut,0,2)=']]' then
              begin
                dec(aTagOpen);
                aOut := copy(aOut,2,length(aOut));
              end;
            aOut := copy(aOut,2,length(aOut));
          end;
      end;
    aOut := bOut+aOut;
    bOut := '';
  end;
  procedure RemoveLinks;
  var
    ShortCloser: Boolean;
    aTagOpen: Integer;
    aText : string = '';
  begin
    while pos('[[',lowercase(aout))>0 do
      begin
        bOut := bOut+copy(aout,0,pos('[[',lowercase(aout))-1);
        aOut := copy(aOut,pos('[[',lowercase(aout))+2,length(aOut));
        aTagOpen := 1;
        while (aTagOpen>0) and (length(aOut)>0) do
          begin
            if copy(aOut,0,2)='[[' then
              begin
                inc(aTagOpen);
                aOut := copy(aOut,2,length(aOut));
              end
            else if copy(aOut,0,2)=']]' then
              begin
                dec(aTagOpen);
                aOut := copy(aOut,2,length(aOut));
              end
            else aText := aText+Copy(aOut,0,1);
            if ((copy(aOut,0,1)=' ') and ((copy(aText,0,4)='http') or (copy(aText,0,5)='mailto'))) or (copy(aOut,0,1)='|') then
              begin
                aText := '';
              end;
            aOut := copy(aOut,2,length(aOut));
          end;
        bOut := bOut+aText;
        aText := '';
      end;
    aOut := bOut+aOut;
    bOut := '';
  end;
  function UpperFirst(aWord : string) : string;
  begin
    Result := '';
    while pos(' ',aWord)>0 do
      begin
        Result := UpperFirst(copy(aWord,0,pos(' ',aWord)-1))+' ';
        aWord := copy(aWord,pos(' ',aWord)+1,length(aWord));
      end;
    Result := Result+UpperCase(copy(aWord,0,1))+lowercase(copy(aWord,2,length(aWord)));
  end;
  label retry;
begin
  Result:=False;
  canhandle:=(pos('$dowikiquerry(',sentence)>0);
  if pos('$getdescription(de)',sentence)>0 then
    begin
      sentence:='Oder alles was in der Wikipedia steht.';
      result := true;
      canhandle:=true;
      exit;
    end;
  if not canhandle then exit;
  tmp := copy(sentence,0,pos('$dowikiquerry(',sentence)-1);
  tmp1 :=copy(sentence,pos('$dowikiquerry(',sentence)+14,length(sentence));
  avar := copy(tmp1,0,pos(')',tmp1)-1);
  tmp1 := copy(tmp1,pos(')',tmp1)+1,length(tmp1));
  if trim(avar) = '' then exit;
retry:
  aOut := GetArticle(language,aVar);
  while (lowercase(copy(aOut,0,pos(' ',aOut)))='#redirect ') or (copy(aOut,0,pos(' ',aOut))='#weiterleitung ') do
    begin
      aOut := copy(aOut,pos(' ',aOut)+1,length(aOut));
      RemoveLinks;
      aOut := StringReplace(aOut,#13#10,'',[rfReplaceAll]);
      aOut := StringReplace(aOut,#13,'',[rfReplaceAll]);
      aOut := StringReplace(aOut,#10,'',[rfReplaceAll]);
      aVar := trim(aOut);
      aOut := GetArticle('de',aVar);
    end;
  if (trim(aOut)='') and (Interlocutor.Speaker.RemoveStopWords(aVar)<>aVar) then
    begin
      aVar := Interlocutor.Speaker.RemoveStopWords(aVar);
      goto retry;
    end;
  if (trim(aOut)='') and (UpperFirst(aVar)<>aVar) then
    begin
      aVar := UpperFirst(aVar);
      goto retry;
    end;

  RemoveTag('bild:');
  RemoveTag('image:');
  RemoveTag('datei:');
  RemoveTag('file:');
  aOut := ReplaceRegExpr('<[^>]+?>',aOut,' ',False);
  aOut := ReplaceRegExpr('{{(.*?)}}',aOut,'',True);
  RemoveLinks;
  //aOut := ReplaceRegExpr('(\[\[).*?\|(.*?)(\]\])',aOut,'$2',True);
  //aOut := ReplaceRegExpr('(\[\[)(.*?)(\]\])',aOut,'$1',True);
  aOut := ReplaceRegExpr('======(.*?)======',aOut,'$1',True);
  aOut := ReplaceRegExpr('=====(.*?)=====',aOut,'$1',True);
  aOut := ReplaceRegExpr('====(.*?)====',aOut,'$1',True);
  aOut := ReplaceRegExpr('===(.*?)===',aOut,'$1',True);
  aOut := ReplaceRegExpr('==(.*?)==',aOut,'$1',True);
  aOut := ReplaceRegExpr('''''''(.*?)''''''',aOut,'$1',True);
  aOut := ReplaceRegExpr('''''(.*?)''''',aOut,'$1',True);
  aOut := StringReplace(aOut,#13#10,'',[rfReplaceAll]);
  aOut := StringReplace(aOut,#13,'',[rfReplaceAll]);
  aOut := StringReplace(aOut,#10,'',[rfReplaceAll]);
  aOut := GetFirstSentence(aOut);
  aOut := StringReplace(aOut,'&nbsp;',' ',[rfReplaceAll]);
  if pos('a:lang',aOut)>0 then
    aOut := '';
  if aOut <> '' then
    begin
      Result := True;
      sentence:=trim(tmp+aout+tmp1);
    end;
end;

resourcestring
  strWiki1                          = '+was|wo|wer+ist|war|sind=wikiquerry';
  strWiki2                          = '+weiss|weiß+jemand|einer+wer|was|wie|womit=wikiquerry+ist|sind|war';

procedure AddSentences;
begin
  if AddSentence(strWiki1,'wiki',stQuestion) then
    AddAnswer('$dowikiquerry($wikiquerry)$ignorelastanswer()');
  if AddSentence(strWiki2,'wiki',stUnknown) then
    AddAnswer('$dowikiquerry($wikiquerry)$ignorelastanswer()');
  if AddSentence(strWiki2,'wiki',stQuestion) then
    AddAnswer('$dowikiquerry($wikiquerry)$ignorelastanswer()');
end;

initialization
  RegisterToSpeaker(@HandleTalk,@AddSentences);
end.

