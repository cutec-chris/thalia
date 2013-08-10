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

function HandleTalk(var sentence : string;var canhandle : Boolean) : Boolean;
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
begin
  Result:=False;
  canhandle:=(pos('$dowikiquerry(',sentence)>0);
  tmp := copy(sentence,0,pos('$dowikiquerry(',sentence)-1);
  tmp1 :=copy(sentence,pos('$dowikiquerry(',sentence)+14,length(sentence));
  avar := copy(tmp1,0,pos(')',tmp1)-1);
  tmp1 := copy(tmp1,pos(')',tmp1)+1,length(tmp1));
  if trim(avar) = '' then exit;
  aOut := GetArticle('de',aVar);
  RemoveTag('bild:');
  RemoveTag('image:');
  RemoveTag('datei:');
  RemoveTag('file:');
  aOut := ReplaceRegExpr('<[^>]+?>',aOut,' ',False);
  aOut := ReplaceRegExpr('{{(.*?)}}',aOut,'',True);
  aOut := ReplaceRegExpr('(\[\[).*?\|(.*?)(\]\])',aOut,'$2',True);
  aOut := ReplaceRegExpr('(\[\[)(.*?)(\]\])',aOut,'$1',True);
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
  if aOut <> '' then
    begin
      Result := True;
      sentence:=trim(tmp+aout+tmp1);
    end;
end;

initialization
  RegisterToSpeaker(@HandleTalk);
end.

