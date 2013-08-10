unit uwikipedia;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,httpsend,uSpeaker,Utils;
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

function HandleTalk(var sentence : string;var canhandle : Boolean) : Boolean;
var
  tmp,tmp1: String;
  avar: String;
  aOut: String;
begin
  Result:=False;
  canhandle:=(canhandle or (pos('$dowikiquerry(',sentence)>-1));
  tmp := copy(sentence,0,pos('$dowikiquerry(',sentence)-1);
  tmp1 :=copy(sentence,pos('$dowikiquerry(',sentence)+14,length(sentence));
  avar := copy(tmp1,0,pos(')',tmp1)-1);
  tmp1 := copy(tmp1,pos(')',tmp1)+1,length(tmp1));
  aOut := GetArticle('de',aVar);
  GetFirstSentence(aOut);
  if aOut <> '' then
    begin
      Result := True;
      sentence:=tmp+aout+tmp1;
    end;
end;

initialization
  RegisterToSpeaker(@HandleTalk);
end.

