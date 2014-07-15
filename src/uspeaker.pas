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

{ TODO : Sätze nicht an Datums beenden }
{ TODO : Säte nicht an Zahlen beenden (1. I. XI.) }
{ TODO : Infos über Chat teilnehmer }
{ TODO : Suchmashcieneneinbindung über browser plugin }
{ TODO : Nachrichten über rss feeds einbinden (thalis, was gibts bei heise.de neues?) }
{ TODO : twitter einbindung }
{ TODO : leo.org einbindung }
unit uSpeaker;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, Utils, FileUtil;

type
  TWordPosition = (wpFirst,wpLast,wpNoMatter);
  TSentenceTyp = (stUnknown,stQuestion,stStatement,stCommand);
  TWordType = (wtNoMatter,wtVerb);
  TWordTyp = packed record
    word : string;
    wordtype : TWordType;
    position : TWordPosition;
  end;

  TSpeaker = class;

  TTalkEvent = procedure(from,sentence : string;Priv : Boolean) of object;
  TGetParameterEvent = function(short : char;long : string) : string of object;
  TShortTalkEvent = procedure(sentence : string) of object;
  THandleTalkEvent = function(Speaker : TSpeaker;language : string;var sentence : string;var canhandle : Boolean) : Boolean;
  TRegisterSentenceEvent = procedure;
  TSpeakerEvent = procedure(Speaker : TSpeaker);

  { TInterlocutor }

  TInterlocutor = class
    procedure UnfocusTimerTimer(Sender: TObject);
  private
    FAnswerto: string;
    FFocused: Boolean;
    FID: string;
    FLastAnswerFound: Boolean;
    FLastConact: TDateTime;
    FLastContact: TDateTime;
    FName: string;
    FProperties : TStringList;
    FSpeaker: TSpeaker;
    FUnicodeAnswer: Boolean;
    function GetProperty(aName : string): string;
    procedure SetAnswerTo(AValue: string);
    procedure SetFocused(const AValue: Boolean);
    procedure SetProperty(aName : string; const AValue: string);
  protected
    FlastCategory : string;
    FLastIndex : LargeInt;
    function StemmGerman(word : string) : string;
    function Stemm(word : string) : string;
  public
    constructor Create(ID : string;Name : string);
    property ID : string read FID;
    property Name : string read FName;
    property Focused : Boolean read FFocused write SetFocused;
    property Properties[aName : string] : string read GetProperty write SetProperty;
    property AnswerTo : string read FAnswerto write SetAnswerTo;
    property LastContact : TDateTime read FLastContact write FLastConact;
    function ReplaceVariables(inp : string) : string;
    property UnicodeAnswer : Boolean read FUnicodeAnswer write FUnicodeAnswer;
    property LastAnswerFound : Boolean read FLastAnswerFound write FLastAnswerFound;
    property Speaker : TSpeaker read FSpeaker write fSpeaker;
    destructor Destroy;override;
  end;
  
  { TInterlokutors }

  TInterlocutors = class(TList)
  private
    function GetItems(ID : string): TInterlocutor;
  public
    property SItems[ID : string] : TInterlocutor read GetItems;default;
  end;

  { TSpeakerInterface }

  TSpeakerInterface = class
  private
    FGetParameter: TGetParameterEvent;
    FSpeaker: TSpeaker;
    FTalk: TTalkEvent;
  public
    procedure Connect;virtual;abstract;
    procedure Disconnect;virtual;abstract;
    procedure Talk(user,sentence : string);virtual;abstract;
    function Process(NeedNewMessage : Boolean = False) : boolean;virtual;abstract;
    function GetID : string;virtual;abstract;
    function IsUser(user : string) : Boolean;virtual;abstract;
    function Whois(user : string) : string;virtual;
    property Speaker : TSpeaker read FSpeaker write FSpeaker;
    property OnTalk : TTalkEvent read FTalk write FTalk;
    property OnGetParameter : TGetParameterEvent read FGetParameter write FGetParameter;
  end;
  
  { TCmdLnInterface }

  TCmdLnInterface = class(TSpeakerInterface)
  public
    procedure Connect;override;
    procedure Disconnect;override;
    procedure Talk(user,sentence : string);override;
    function Process(NeedNewMessage : Boolean = False) : Boolean;override;
    function GetID : string;override;
    function IsUser(user : string) : Boolean;override;
  end;

  { TSpeakerData }

  TSpeakerData = class
  public
    function GetWords(aFilter : string) : TDataSet;virtual;abstract;
    function GetScentences(aFilter : string) : TDataSet;virtual;abstract;
    function GetAnswers(aFilter : string) : TDataSet;virtual;abstract;
    function SetVariable(aInterlocutor : string;aVarname : string;aValue : string) : Boolean;virtual;
    function GetVariable(aInterlocutor : string;aVarname : string) : string;virtual;
  end;
  
  { TSpeaker }

  TSpeaker = class
    procedure FIntfTalk(from, sentence: string;Priv : Boolean);
  private
    FAutofocus: Boolean;
    FBeQuiet: Boolean;
    FData: TSpeakerData;
    FDebugMessage: TShortTalkEvent;
    FFastAnswer: Boolean;
    FIgnoreunicode: Boolean;
    FInterlocutors: TInterlocutors;
    FIntf: TSpeakerInterface;
    FName: string;
    FLangDir : string;
    FAnswerTo : string;
    FSystemMessage: TShortTalkEvent;
    Logpath : string;
    procedure SetData(AValue: TSpeakerData);
    procedure SetIntf(const AValue: TSpeakerInterface);
    procedure SetName(const AValue: string);
    function LoadLanguage(language : string) : Boolean;
  protected
    function GetSentenceTyp(sentence : TStringList) : TSentenceTyp;
    function WordsToSentence(sentence : TStringList) : string;
    function SentenceToStringList(sentence : string;Interlocutor : TInterlocutor = nil) : TStringList;
    function CheckForSentence(words : TStringList;aTyp : TSentenceTyp;Interlocutor : TInterlocutor;priv,stemm : boolean;logfile : string) : Boolean;
    function CheckFocus(words : TStringList) : Boolean;
    function CheckTempFocus(words : TStringList) : Boolean;
    function CheckUnFocus(words : TStringList) : Boolean;
    function GetInterlocutorID(name : string) : string;
    procedure DoAnswer(Interlocutor : TInterlocutor;answer : string;priv : boolean;logfile : string);
    procedure DoSleep(time : DWORD);
  public
    property Name : string read FName write SetName;
    property Interlocutors : TInterlocutors read FInterlocutors;
    property Intf : TSpeakerInterface read FIntf write SetIntf;
    property Data : TSpeakerData read FData write SetData;
    function Analyze(from,sentence : string;priv : Boolean) : Boolean;
    function Processfunctions(Interlocutor : TInterlocutor;answer : string;priv : Boolean;logfile : string) : string;
    function RemoveStopWords(inp : string) : string;
    constructor Create(aName, Language: string; aData: TSpeakerData);
    property BeQuiet : Boolean read FBeQuiet write FBeQuiet;
    property Autofocus : Boolean read FAutofocus write FAutofocus;
    property IgnoreUnicode : Boolean read FIgnoreunicode write FIgnoreunicode;
    function Process(NeedNewMessage : Boolean = False) : Boolean;
    property OnSystemMessage : TShortTalkEvent read FSystemMessage write FSystemMessage;
    property OnDebugMessage : TShortTalkEvent read FDebugMessage write FDebugMessage;
    property FastAnswer : Boolean read FFastAnswer write FFastAnswer;
    destructor Destroy;override;
  end;
  
  { TParserEntry }

  TParserEntry = class(TList)
  private
    FParse : string;
    FInterlocutor: TInterlocutor;
    function GetItems(Index : Integer): TparserEntry;
    procedure SetItems(Index : Integer; const AValue: TparserEntry);
  public
    constructor Create(ToParse : string;Interlocutor : TInterlocutor);
    property Items[Index : Integer] : TparserEntry read GetItems write SetItems;
    function IsValid(words,Variables : TStringList) : Boolean;
  end;

  procedure RegisterToSpeaker(aTalk : THandleTalkEvent;aAddSenences : TRegisterSentenceEvent = nil);
  procedure RegisterChron(aAddChron : TSpeakerEvent);
  function AddSentence(aSentence,aCategory : string;aType : Integer; aPriority: integer=1) : Boolean;
  procedure AddAnswer(aAnswer : string);
  function GetFirstSentence(var inp : string) : string;
implementation
var
  Speaker : TSpeaker;
  TalkHandlers : array of THandleTalkEvent;
  SentenceHandlers : array of TRegisterSentenceEvent;
  ChronHandlers : array of TSpeakerEvent;
resourcestring
  strLanguagedontexists                 = 'The Language dont exists';
  strShortQuestionAnswer                = 'Ja ?';

const
  punctations : array [0..12] of string = (',','.','?','!','...',':',';','(',')','[',']','{','}');
  sentenceends : array [0..2] of string = ('.','?','!');

procedure RegisterToSpeaker(aTalk: THandleTalkEvent; aAddSenences: TRegisterSentenceEvent = nil
  );
begin
  Setlength(TalkHandlers,length(TalkHandlers)+1);
  TalkHandlers[length(TalkHandlers)-1] := aTalk;
  if Assigned(aAddSenences) then
    begin
      Setlength(SentenceHandlers,length(SentenceHandlers)+1);
      SentenceHandlers[length(SentenceHandlers)-1] := aAddSenences;
    end;
end;

procedure RegisterChron(aAddChron: TSpeakerEvent);
begin
  Setlength(ChronHandlers,length(ChronHandlers)+1);
  ChronHandlers[length(ChronHandlers)-1] := aAddChron;
end;

function AddSentence(aSentence, aCategory: string; aType: Integer;
  aPriority: integer): Boolean;
var
  FSentence: TDataSet;
begin
  Result := False;
  if not Assigned(Speaker) then exit;
  if not Assigned(Speaker.Data) then exit;
  FSentence:=Speaker.Data.GetScentences('');
  if not FSentence.Locate('WORDS',aSentence,[loCaseInsensitive]) then
    begin
      FSentence.Insert;
      FSentence.FieldByName('ID').AsLargeInt:=FSentence.RecordCount+1;
      FSentence.FieldByName('WORDS').AsString:=aSentence;
      FSentence.FieldByName('CATEGORY').AsString:=aCategory;
      FSentence.FieldByName('TYPE').AsInteger:=aType;
      FSentence.FieldByName('PRIORITY').AsInteger:=aPriority;
      FSentence.Post;
      Result := True;
    end;
end;

procedure AddAnswer(aAnswer: string);
var
  FAnswer: TDataSet;
  FSent: TDataSet;
begin
  if not Assigned(Speaker) then exit;
  if not Assigned(Speaker.Data) then exit;
  FAnswer:=Speaker.Data.GetAnswers('');
  if not FAnswer.Locate('ANSWER',aAnswer,[loCaseInsensitive]) then
    begin
      FAnswer.Insert;
      IF FAnswer.FieldDefs.IndexOf('REF')>-1 then
        begin
          FSent := Speaker.Data.GetScentences('');
          FAnswer.FieldByName('REF').AsLargeInt:=FSent.FieldByName('ID').AsLargeInt;
        end;
      FAnswer.FieldByName('ANSWER').AsString:=aAnswer;
      FAnswer.Post;
    end;
end;

function GetFirstSentence(var inp : string) : string;
var
  endpos,i : Integer;
  bracket : Integer = 0;
  c: Integer;
label
  restart;
begin
  Result := '';
restart:
  bracket:=0;
  endpos := -1;
  for c := 1 to length(inp)-1 do
    begin
      if copy(inp,c,1)='(' then inc(bracket);
      if copy(inp,c,1)=')' then dec(bracket);
      for i := 0 to length(sentenceends)-1 do
        begin
          if (copy(inp,c,1)=sentenceends[i]) and (bracket=0) then
            begin
              endpos := c;
              break;
            end;
        end;
      if endpos>-1 then break;
    end;
  if endpos=-1 then
    endpos := length(inp);
  Result := result+copy(inp,0,endpos);
  inp := copy(inp,endpos+1,length(inp));
  if (inp <> '') and Isnumeric(copy(Result,length(Result)-2,1)) then goto restart; //example 2.0.4
  if (inp <> '') and (lowercase(copy(Result,length(Result)-2,1))='i') then goto restart; //example 2.0.4
  if (inp <> '') and (lowercase(copy(Result,length(Result)-2,1))='x') then goto restart; //example 2.0.4
  if (inp <> '') and (lowercase(copy(Result,length(Result)-2,1))='v') then goto restart; //example 2.0.4
  if (inp <> '') and (lowercase(copy(Result,length(Result)-2,1))='m') then goto restart; //example 2.0.4
  if (pos('.',inp) > 0) and (pos('.',inp) < 5) then goto restart; //example: b.z.w.
end;

function RemoveStopWords(var inp: string): Boolean;
begin

end;

{ TSpeakerData }

function TSpeakerData.SetVariable(aInterlocutor: string; aVarname: string;
  aValue: string): Boolean;
begin
  Result := False;
end;

function TSpeakerData.GetVariable(aInterlocutor: string; aVarname: string
  ): string;
begin
  Result := '';
end;

{ TSpeakerInterface }

function TSpeakerInterface.Whois(user: string): string;
begin
  Result := '';
end;

procedure TSpeaker.SetName(const AValue: string);
begin
  if FName=AValue then exit;
  FName:=AValue;
end;

function TInterlocutor.StemmGerman(word: string): string;
const
  stemmendings : array[0..10] of string = ('test','est','end','ten','st','te','en','et','e','t','');
var
  i: Integer;
begin
  Result := word;
  for i := low(stemmendings) to high(stemmendings) do
    if copy(Result,length(Result)-length(stemmendings[i]),length(stemmendings[i])) = stemmendings[i] then
      begin
        Result := copy(Result,0,length(Result)-length(stemmendings[i])-1);
        break;
      end;
  Result := StringReplace(Result,'a','a',[rfReplaceAll]);
  Result := StringReplace(Result,'ö','o',[rfReplaceAll]);
  Result := StringReplace(Result,'ü','u',[rfReplaceAll]);
  Result := StringReplace(Result,'ß','ss',[rfReplaceAll]);
end;

procedure TSpeaker.FIntfTalk(from, sentence: string;Priv : Boolean);
var
  tmp: String;
begin
  try
  if from = 'system' then
    begin
      if Assigned(FSystemMessage) then
        FSystemMessage(sentence);
    end
  else if from = 'debug' then
    begin
      if Assigned(FDebugMessage) then
        FDebugMessage(sentence);
    end
  else
    begin
      if Assigned(FSystemMessage) then
        begin
          if priv then
            FSystemMessage('>>PRIVATE '+Uppercase(from)+':'+sentence)
          else
            FSystemMessage('>>'+from+':'+sentence);
        end;
      Analyze(from,sentence,Priv);
    end;
  except
    on e : exception do
    if not BeQuiet then
      writeln('error:'+e.message);
  end;
end;

procedure TSpeaker.SetIntf(const AValue: TSpeakerInterface);
begin
  if FIntf=AValue then exit;
  FIntf:=AValue;
  FIntf.OnTalk:=@FIntfTalk;
  FIntf.Speaker := Self;
end;

procedure TSpeaker.SetData(AValue: TSpeakerData);
begin
  if FData=AValue then Exit;
  FData:=AValue;
end;

function TSpeaker.LoadLanguage(language: string): Boolean;
begin
  Result := True;
end;

function TSpeaker.GetSentenceTyp(sentence: TStringList): TSentenceTyp;
var
  i: Integer;
  questionindex: LongInt;
  statementindex: LongInt;
const
  questionwords : array[0..17] of TWordTyp =
    ((word:'?';wordtype:wtNoMatter;position:wpLast),
     (word:'wer';wordtype:wtNoMatter;position:wpFirst),
     (word:'welche';wordtype:wtNoMatter;position:wpFirst),
     (word:'welcher';wordtype:wtNoMatter;position:wpFirst),
     (word:'welches';wordtype:wtNoMatter;position:wpFirst),
     (word:'wen';wordtype:wtNoMatter;position:wpFirst),
     (word:'wem';wordtype:wtNoMatter;position:wpFirst),
     (word:'wessen';wordtype:wtNoMatter;position:wpFirst),
     (word:'wo';wordtype:wtNoMatter;position:wpFirst),
     (word:'wohin';wordtype:wtNoMatter;position:wpFirst),
     (word:'woher';wordtype:wtNoMatter;position:wpFirst),
     (word:'wann';wordtype:wtNoMatter;position:wpFirst),
     (word:'wie';wordtype:wtNoMatter;position:wpFirst),
     (word:'weshalb';wordtype:wtNoMatter;position:wpFirst),
     (word:'warum';wordtype:wtNoMatter;position:wpFirst),
     (word:'weswegen';wordtype:wtNoMatter;position:wpFirst),
     (word:'wiso';wordtype:wtNoMatter;position:wpFirst),
     (word:'was';wordtype:wtNoMatter;position:wpFirst));
  statementwords : array[0..0] of TWordTyp =
    ((word:'!';wordtype:wtNoMatter;position:wpLast));
  function GetIndex(words : array of TWordTyp) : Integer;
  var
    i : Integer;
    a: Integer;
    function ConditionsOK(idx : Integer) : Boolean;
    begin
      Result := False;
      if (copy(sentence.Names[idx],0,length(words[i].word)) = words[i].word)
      or (copy(sentence[idx],0,length(words[i].word)) = words[i].word)
      then
        begin
          Result := True;
          exit;
        end;
    end;
  begin
    Result := -1;
    for i := 0 to length(words)-1 do
      begin
        case words[i].Position of
        wpFirst:
          if ConditionsOK(0) then
            begin
              Result := i;
              exit;
            end;
        wpLast:
          if ConditionsOK(sentence.Count-1) then
            begin
              Result := i;
              exit;
            end;
        wpNoMatter:
          for a := 0 to sentence.Count-1 do
            if ConditionsOK(a) then
              begin
                Result := i;
                exit;
              end;
        end;
      end;
  end;
begin
  Result := stUnknown;
  if sentence.Count < 2 then exit;
  questionindex := getIndex(questionwords);
  statementindex := getIndex(statementwords);
  if (questionindex = -1) and (statementindex = -1) then exit;
  if (questionindex > statementindex) then
    Result := stQuestion
  else
    Result := stStatement;
end;

function TSpeaker.WordsToSentence(sentence: TStringList): string;
var
  i: Integer;
begin
  Result:='';
  for i := 0 to sentence.Count-1 do
    Result := Result+sentence.Names[i]+' ';
end;

function TSpeaker.SentenceToStringList(sentence: string;Interlocutor : TInterlocutor = nil): TStringList;
var
  words : TStringList;
  aword: String;
  punctation: String;
  i: Integer;
begin
  words := TStringList.Create;
  Result := words;
  sentence := sentence+' ';
  while (length(trim(sentence)) > 0) and (pos(' ',sentence) > 0) do
    begin
      punctation := '';
      if trim(copy(sentence,0,pos(' ',sentence)-1)) <> '' then
        begin
          aword := trim(copy(sentence,0,pos(' ',sentence)-1));
          for i := 0 to length(punctations)-1 do
            if copy(aword,length(aword)-length(punctations[i])+1,length(punctations[i])) = punctations[i] then
              begin
                punctation := punctations[i];
                aword := copy(aword,0,length(aword)-(length(punctations[i])));
                break;
              end;
          if Assigned(Interlocutor) then
            words.Add(Interlocutor.Stemm(lowercase(aword))+'='+aword)
          else
            words.Add(lowercase(aword)+'='+aword);
          if punctation <> '' then
            words.Add(punctation);
        end;
      sentence := copy(sentence,pos(' ',sentence)+1,length(sentence));
    end;
end;

function TSpeaker.CheckForSentence(words: TStringList;aTyp : TSentenceTyp;Interlocutor : TInterlocutor;priv,stemm : boolean;logfile : string): Boolean;
var
  acheck,
  aword : String;
  aOK,atOK: Boolean;
  aop: String;
  NextQuestion: String;
  Idx: LongInt;
  aIdx: Integer;
  tmpRes: String;
  Answer : string;
  Parser: TParserEntry;
  tmp: String;
  FVariables: TStringList;
  tmp1: String;
  i: Integer;
  canhandle : Boolean;
  pInterlocutor: TInterlocutor;
  FSentences: TDataSet;
  FAnswers: TDataSet;
  procedure ReplaceVariables(var aAnswer : string);
  var
    i: Integer;
    varname: String;
    varvalue: String;
  begin
    for i := 0 to FVariables.Count-1 do
      begin
        varname := FVariables.Names[i];
        varvalue := FVariables.ValueFromIndex[i];
        aAnswer := StringReplace(aAnswer,'$'+varname+' ',varvalue+' ',[rfReplaceAll]);
        aAnswer := StringReplace(aAnswer,'$'+varname+')',varvalue+')',[rfReplaceAll]);
      end;
  end;

begin
  Result := False;
  Answer := '';
  FVariables := TStringlist.Create;
  FSentences := Data.GetScentences('"TYPE"='''+IntToStr(Integer(aTyp))+'''');
  FSentences.First;
  while not FSentences.EOF do
    begin
      acheck := FSentences.FieldByName('WORDS').AsString;
      if Stemm then
        pInterlocutor := Interlocutor
      else pInterlocutor:=nil;
      if pos('=>',acheck) > 0 then
        Parser := TParserEntry.Create(copy(acheck,0,pos('=>',acheck)-1),pInterlocutor)
      else
        Parser := TParserEntry.Create(acheck,pInterlocutor);

      aOK := Parser.IsValid(words,FVariables);
      Parser.Free;
      if aOK then
        begin
          if Assigned(FDebugMessage) then
            FDebugMessage('Sentence found'+lineending);
          Result := True;
          if (FSentences.FieldByName('ID').AsLargeInt = Interlocutor.FLastIndex) and (FSentences.FieldByName('CATEGORY').AsString = Interlocutor.FlastCategory) then
            begin
              if Assigned(FDebugMessage) then
               FDebugMessage('duplicate.'+lineending);
              exit;
            end;
          Interlocutor.FLastIndex := FSentences.FieldByName('ID').AsLargeInt;
          Interlocutor.FlastCategory := FSentences.FieldByName('CATEGORY').AsString;
          FAnswers := Data.GetAnswers('"REF"='''+FSentences.FieldByName('ID').AsString+'''');
          Randomize;
          FAnswers.MoveBy(Random(FAnswers.RecordCount));
          if FAnswers.RecordCount>0 then
            begin
              Answer := FAnswers.FieldByName('ANSWER').AsString;
              if Assigned(FDebugMessage) then
                FDebugMessage('Answer:'+Answer+lineending);
            end
          else
            begin
              Result := False;
              if Assigned(FDebugMessage) then
                FDebugMessage('no Answer found'+lineending);
            end;
          if pos('=>',Answer) > 0 then
            begin
              NextQuestion := copy(Answer,pos('=>',Answer)+2,length(Answer));
              Answer := copy(Answer,0,pos('=>',Answer)-1);
            end;
          while Answer <> '' do
            begin
              tmp := Processfunctions(Interlocutor,GetFirstSentence(Answer),priv,logfile);
              ReplaceVariables(tmp);
              for i := low(TalkHandlers) to high(TalkHandlers) do
                begin
                  tmp1 := tmp;
                  if TalkHandlers[i](Self,Interlocutor.Properties['LANGUAGE'],tmp1,canhandle) then
                    tmp := tmp1
                  else if canhandle then
                    Result := False;
                end;
              if Result and (tmp<>'') then
                DoAnswer(Interlocutor,tmp,priv,logfile);
            end;
          if NextQuestion <> '' then
            begin
              Interlocutor.AnswerTo := copy(NextQuestion,pos(';',NextQuestion)+1,length(NextQuestion));
              NextQuestion := copy(NextQuestion,0,pos(';',NextQuestion)-1);
              NextQuestion := Interlocutor.ReplaceVariables(NextQuestion);
              ReplaceVariables(NextQuestion);
              NextQuestion := Processfunctions(Interlocutor,NextQuestion,priv,logfile);
              for i := low(TalkHandlers) to high(TalkHandlers) do
                begin
                  tmp1 := NextQuestion;
                  if TalkHandlers[i](Self,Interlocutor.Properties['LANGUAGE'],tmp1,canhandle) then
                    NextQuestion := tmp1
                  else if canhandle then
                    Result := False;
                end;
              if Result and (NextQuestion<>'') then
                DoAnswer(Interlocutor,NextQuestion,priv,logfile);
            end;
          if Result then
            exit;
        end;
      FSentences.Next;
    end;
  FVariables.Free;
  if not Result then
    begin
      if Assigned(FDebugMessage) then
        FDebugMessage('no Sentence found'+lineending);
      Interlocutor.FLastIndex := -1;
      Interlocutor.FlastCategory := '';
    end;
end;

function TSpeaker.CheckFocus(words: TStringList): Boolean;
begin
  Result := False;
  if (words.Count > 0) and (words.Names[0] = '@'+lowercase(FName)) then
    begin
      words.Delete(0);
      Result := True;
      if (words.Count > 0) then exit;
      if words[0] = ',' then
        words.Delete(0);
      if (words.Count > 0) then exit;
      if words[0] = ':' then
        words.Delete(0);
      exit;
    end;
  if (words.Count > 0) and (words.Names[0] = lowercase(FName)) then
    begin
      words.Delete(0);
      Result := True;
      if (words.Count>0) and (words[0] = ',') then
        words.Delete(0);
      if (words.Count>0) and (words[0] = ':') then
        words.Delete(0);
      exit;
    end;
  if (words.Count > 1) and (words.Names[words.Count-1] = lowercase(FName)) then
    begin
      words.Delete(words.Count-1);
      Result := True;
      exit;
    end;
  if (words.Count > 2) and (words.Names[words.Count-2] = lowercase(FName)) then
    begin
      words.Delete(words.Count-2);
      Result := True;
      exit;
    end;
end;

function TSpeaker.CheckTempFocus(words: TStringList): Boolean;
begin
  Result :=
     (words.IndexOfName('jemand')>-1)
  or (words.IndexOfName('irgendjemand')>-1)
  or (words.IndexOfName('helfen')>-1)
  or (words.IndexOfName('somebody')>-1)
  or (words.IndexOfName('hilfe')>-1)
  ;
end;

function TSpeaker.CheckUnFocus(words: TStringList): Boolean;
begin
  Result := False;
  if (words.Count > 0) and (copy(words.Names[0],0,1) = '@') and Intf.IsUser(copy(words.Names[0],2,length(words[0]))) then
    begin
      Result := True;
      exit;
    end;
  if (words.Count > 0) and Intf.IsUser(words.Names[0]) then
    begin
      Result := True;
      exit;
    end;
  if (words.Count > 1) and Intf.IsUser(words.Names[words.Count-1]) then
    begin
      Result := True;
      exit;
    end;
  if (words.Count > 2) and Intf.IsUser(words.Names[words.Count-2]) then
    begin
      Result := True;
      exit;
    end;
end;

function TSpeaker.GetInterlocutorID(name: string): string;
begin
  if name = '' then
    Result := 'somebody@'+FIntf.GetID
  else
    Result := name+'@'+FIntf.GetID;
end;

function TSpeaker.Analyze(from, sentence: string; priv: Boolean): Boolean;
var
  atyp: TSentenceTyp;
  words: TStringList;
  SR : TSearchRec;
  Interlocutor: TInterlocutor;
  NewInterlocutor : Boolean;
  aFocus: Boolean;
  sl: TStringList;
  i: Integer;
  aOK: Boolean;
  flog : TextFile;
  filename: String;
  InterlocutorID: String;
  Answer: String;
  FSentences: TDataSet;
  FAnswers: TDataSet;
const
  stypes : array [0..3] of string = ('unknown','questions','statements','commands');

  function CheckNonASCII(txt : string) : Boolean;
  var
    a: Integer;
  begin
    Result := False;
    for a := 1 to length(txt) do
      if  (ord(txt[a]) > 127)
      and (ord(txt[a]) <> $C2)
      and (ord(txt[a]) <> $C3)
      and (ord(txt[a]) <> $C5)
      and (ord(txt[a]) <> $C6)
      and (ord(txt[a]) <> $CB)
      and (ord(txt[a]) <> $CE)
      and (ord(txt[a]) <> $CF)
      and (ord(txt[a]) <> $E2)
      then
        Result := True;
  end;

begin
  if from = name then exit;
  InterlocutorID := GetInterlocutorID(from);
  if priv then
    filename := LogPath+DirectorySeparator+ValidateFilename(InterlocutorID+'.txt')
  else
    filename := LogPath+DirectorySeparator+ValidateFilename(FIntf.GetID+'.txt');
  AssignFile(flog,filename);
  try
  if not FileExists(filename) then
    Rewrite(flog)
  else
    Append(flog);
  writeln(flog,'['+TimeToStr(Time)+','+DateToStr(Date)+'] '+from+':'+StringReplace(StringReplace(sentence,#10,'',[rfReplaceAll]),#13,'',[rfReplaceAll]));
  CloseFile(flog);
  except
    if not FBeQuiet then
    writeln(filename);
  end;
  Result := False;
  try
  Interlocutor := Interlocutors[InterlocutorID];
  NewInterlocutor := False;
  if not Assigned(Interlocutor) then
    begin
      Interlocutor := TInterlocutor.Create(InterlocutorID,from);
      Interlocutor.Speaker := Self;
      Interlocutors.Add(Interlocutor);
      NewInterlocutor := True;
      if Assigned(FDebugMessage) then
        FDebugMessage('New Interlocutor:'+InterlocutorID+lineending);
    end
  else
    begin
      if Assigned(FDebugMessage) then
        FDebugMessage('Interlocutor is :'+Interlocutor.FID+lineending);
    end;
  Interlocutor.LastContact:=Now();
  if not FFastAnswer then
    Dosleep(random(10)*1000);
  words := SentenceToStringList(sentence);
  if words.Count=0 then exit;
  aFocus := False;
  if CheckFocus(words) or priv or AutoFocus then
    begin
      Interlocutor.Focused := True;
      aFocus := True;
      if Assigned(FDebugMessage) then
        FDebugMessage('Interlocutor focused.'+lineending);
    end;
  if (not priv) and (not Autofocus) and CheckUnFocus(words) then
    begin
      Interlocutor.Focused := False;
      if Assigned(FDebugMessage) then
        FDebugMessage('Interlocutor unfocused.'+lineending);
    end;
  if Interlocutor.Focused or priv or CheckTempFocus(words) then
    begin
      if priv then
        if Assigned(FDebugMessage) then
          FDebugMessage('Private Chat.'+lineending);
      if NewInterlocutor then
        begin
          randomize;
          if not FFastAnswer then
            Dosleep((5+random(30))*1000);
        end;
      aOK := True;
      if words.count = 1 then
        for i := 0 to length(sentenceends)-1 do
          if words[0] = sentenceends[i] then
            begin
              aOK := False;
              DoAnswer(Interlocutor,strShortQuestionAnswer,priv,filename);
              Interlocutor.FLastIndex:=-1;
              break;
            end;
      if aOK then
        begin
          FDebugMessage('Sentence:'+WordsToSentence(words));
          atyp := GetSentenceTyp(words);
          if Assigned(FDebugMessage) then
            FDebugMessage('Typ:'+stypes[Integer(atyp)]+lineending);
          if (Interlocutor.AnswerTo<>'') and (atyp<>stQuestion) then
            begin
              if Assigned(FDebugMessage) then
                FDebugMessage('No Answer, using Typ 7'+lineending);
              Interlocutor.Properties[Interlocutor.AnswerTo] := StringReplace(sentence,'=','',[rfReplaceAll]);
              FSentences := Data.GetScentences('"TYPE"=''7''');
              FAnswers := Data.GetAnswers('"REF"='''+FSentences.FieldByName('ID').AsString+'''');
              Randomize;
              FAnswers.MoveBy(Random(FAnswers.RecordCount));
              Answer := FAnswers.FieldByName('ANSWER').AsString;
              DoAnswer(Interlocutor,Answer,priv,filename);
              Interlocutor.AnswerTo:='';
              Result := True;
            end
          else
            Result := Result or CheckForSentence(words,atyp,Interlocutor,priv,false,filename);
          if (not Result) and (aFocus or priv) and (atyp=stQuestion) then //Say something when we are asked directly and have no answer
            begin
              if Assigned(FDebugMessage) then
                FDebugMessage('No Answer, using Typ 6'+lineending);
              FSentences := Data.GetScentences('"TYPE"=''6''');
              FAnswers := Data.GetAnswers('"REF"='''+FSentences.FieldByName('ID').AsString+'''');
              Randomize;
              FAnswers.MoveBy(Random(FAnswers.RecordCount));
              Answer := FAnswers.FieldByName('ANSWER').AsString;
              DoAnswer(Interlocutor,Answer,priv,filename);
            end;
        end;
    end;
  except
  end;
  words.Free;
  if Assigned(Interlocutor) then
    Interlocutor.LastAnswerFound := Result;
end;

procedure TSpeaker.DoAnswer(Interlocutor: TInterlocutor; answer: string;
  priv: boolean; logfile: string);
var
  FLog : TextFile;
  tmpanswer: AnsiString;
begin
  tmpanswer := answer;
  if Assigned(FSystemMessage) then
    FSystemMessage('<<'+tmpanswer+lineending);
  Assignfile(flog,logfile);
  if not FileExists(logfile) then
    Rewrite(flog)
  else
    Append(flog);
  writeln(flog,'['+TimeToStr(Time)+','+DateToStr(Date)+'] ANSWER:'+tmpanswer);
  if Interlocutor.UnicodeAnswer and (not IgnoreUnicode) then
    tmpanswer := SysToUTF8(tmpanswer);
  if Assigned(Interlocutor) and priv then
    FIntf.Talk(Interlocutor.Name,tmpanswer)
  else
    FIntf.Talk('',tmpanswer);
  CloseFile(flog);
end;

procedure TSpeaker.DoSleep(time: DWORD);
var
  atime: LongWord;
begin
  atime := DWord(Trunc(Now * 24 * 60 * 60 * 1000));
  while DWord(Trunc(Now * 24 * 60 * 60 * 1000))-atime < time do
    Process;
end;

function TSpeaker.Processfunctions(Interlocutor: TInterlocutor; answer: string;priv : Boolean;logfile : string
  ): string;
var
  i: Integer;
  canhandle: Boolean;
begin
  Result := answer;
  if pos('$time',lowercase(answer)) > 0 then
    Result := copy(Result,0,pos('$time',lowercase(answer))-1)+formatdatetime('hh:mm',time)+copy(Result,pos('$time',lowercase(answer))+5,length(Result));
  if pos('$unfocus',lowercase(answer)) > 0 then
    begin
      Result := copy(Result,0,pos('$unfocus',lowercase(answer))-1)+copy(Result,pos('$unfocus',lowercase(answer))+8,length(Result));
      Interlocutor.Focused:=False;
    end;
  if pos('$weekday',lowercase(answer)) > 0 then
    Result := copy(Result,0,pos('$weekday',lowercase(answer))-1)+LongDayNames[DayOfWeek(date)]+copy(Result,pos('$weekday',lowercase(answer))+5,length(Result));
  if pos('$date',lowercase(answer)) > 0 then
    Result := copy(Result,0,pos('$date',lowercase(answer))-1)+DateToStr(date)+copy(Result,pos('$date',lowercase(answer))+5,length(Result));
  if pos('$ignorelastanswer',lowercase(answer)) > 0 then
    begin
      Result := copy(Result,0,pos('$ignorelastanswer',lowercase(answer))-1)+copy(Result,pos('$ignorelastanswer',lowercase(answer))+17,length(Result));
      Interlocutor.FlastCategory:='';
      Interlocutor.FLastIndex:=-1;
    end;
  if (pos('$getdescription(de)',LowerCase(answer))>0) then
    begin
      Answer := 'Du kannst mich z.b. nach der Uhrzeit, dem Datum, Witzen o.ä Fragen.';
      DoAnswer(Interlocutor,Answer,priv,logfile);
      for i := low(TalkHandlers) to high(TalkHandlers) do
        begin
          answer := '$getdescription(de)';
          canhandle := False;
          if TalkHandlers[i](Self,Interlocutor.Properties['LANGUAGE'],answer,canhandle) then
            DoAnswer(Interlocutor,answer,priv,logfile);
        end;
      Result := '';
    end;
end;

function TSpeaker.RemoveStopWords(inp: string): string;
var
  sl: TStringList;
  i: Integer;
  FWords: TDataSet;
begin
  Result := '';
  FWords := Data.GetWords('"TYPE"='''+'1'+'''');
  sl := SentenceToStringList(inp);
  while not FWords.EOF do
    begin
      if sl.IndexOfName(lowercase(FWords.FieldByName('WORD').AsString))>-1 then
        sl.Delete(sl.IndexOfName(lowercase(FWords.FieldByName('WORD').AsString)));
      FWords.Next;
    end;
  for i := 0 to sl.Count-1 do
    Result := result+sl.ValueFromIndex[i]+' ';
  Result := trim(Result);
end;

constructor TSpeaker.Create(aName,Language: string;aData : TSpeakerData);
var
  i: Integer;
begin
  Data := aData;
  if not LoadLanguage(Language) then raise Exception.Create('failed loading dict');
  FName := aName;
  FInterlocutors := TInterlocutors.Create;
  Logpath := GetConfigDir('thalia')+'log';
  ForceDirectories(Logpath);
  FFastAnswer := False;
  Speaker := Self;
  for i := low(SentenceHandlers) to high(SentenceHandlers) do
    SentenceHandlers[i];
end;

function TSpeaker.Process(NeedNewMessage : Boolean = False): Boolean;
var
  i: Integer;
begin
  Result := True;
  if not Assigned(FIntf) then
    exit;
  Result := FIntf.Process(NeedNewMessage);
  for i := low(ChronHandlers) to high(ChronHandlers) do
    ChronHandlers[i](Self);
{  for i := 0 to Interlocutors.Count-1 do
    if (Now()-TInterlocutor(Interlocutors.Items[i]).LastContact) > EncodeTime(0,2,0,0) then
      TInterlocutor(Interlocutors.Items[i]).Focused := False;}
end;

destructor TSpeaker.Destroy;
begin
  inherited Destroy;
  FData.Free;
  FInterlocutors.Free;
end;

{ TCmdLnInterface }

procedure TCmdLnInterface.Connect;
begin
  Speaker.OnSystemMessage:=nil;
end;

procedure TCmdLnInterface.Disconnect;
begin
end;

procedure TCmdLnInterface.Talk(user,sentence: string);
begin
  writeln(sentence);
end;

function TCmdLnInterface.Process(NeedNewMessage : Boolean = False) : Boolean;
var
  tmp : string;
begin
  if NeedNewMessage then
    begin
      write('>');
      readln(tmp);
      if Assigned(FTalk) then
        FTalk(SystemUserName,tmp,True);
    end;
  Result := True;
end;

function TCmdLnInterface.GetID: string;
begin
  Result:='cmdln';
end;

function TCmdLnInterface.IsUser(user: string): Boolean;
begin
  Result:=False;
end;

{ TInterlokutors }

function TInterlocutors.GetItems(ID : string): TInterlocutor;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count-1 do
    if TInterlocutor(Get(i)).ID = ID then
      begin
        Result := TInterlocutor(Get(i));
        exit;
      end;
end;

{ TInterlocutor }

procedure TInterlocutor.UnfocusTimerTimer(Sender: TObject);
begin
  FFocused := False;
  if Assigned(Speaker.FDebugMessage) then
    Speaker.FDebugMessage('Interlocutor '+FID+' unfocused (timeout).'+lineending);
end;

function TInterlocutor.GetProperty(aName : string): string;
begin
  Result := '';
  if Assigned(Speaker) and Assigned(Speaker.Data) then
    Result := Speaker.Data.GetVariable(Name,aName);
  if Result='' then
    Result := FProperties.Values[aName];
end;

procedure TInterlocutor.SetAnswerTo(AValue: string);
begin
  if FAnswerto=AValue then Exit;
  FAnswerto:=AValue;
end;

procedure TInterlocutor.SetFocused(const AValue: Boolean);
begin
  If FFocused = AValue then exit;
  FFocused := AValue;
end;

procedure TInterlocutor.SetProperty(aName : string; const AValue: string);
begin
  FProperties.Values[aName] := AValue;
  if Assigned(Speaker) and Assigned(Speaker.Data) then
    Speaker.Data.SetVariable(Name,aName,AValue);
end;

function TInterlocutor.Stemm(word: string): string;
begin
  if Properties['LANGUAGE']='de' then
    Result := StemmGerman(word)
  else Result := word;
end;

constructor TInterlocutor.Create(ID: string; Name: string);
begin
  FID := ID;
  FLastIndex := -1;
  Focused := False;
  FProperties := TStringList.Create;
  Properties['TITLE'] := 'ihnen';
  Properties['LANGUAGE'] := 'de';
  Fname := Name;
  FUnicodeAnswer := True;
  FLastAnswerFound := True;
end;

function TInterlocutor.ReplaceVariables(inp: string): string;
var
  i: Integer;
begin
  Result := inp;
  for i := 0 to FProperties.Count-1 do
    Result := StringReplace(Result,'%'+FProperties.Names[i]+'%',FProperties.ValueFromIndex[i],[rfReplaceAll]);
end;

destructor TInterlocutor.Destroy;
begin
  inherited Destroy;
  FProperties.Free;
end;

{ TParserEntry }

function TParserEntry.GetItems(Index : Integer): TparserEntry;
begin

end;

procedure TParserEntry.SetItems(Index : Integer; const AValue: TparserEntry);
begin

end;

constructor TParserEntry.Create(ToParse: string;Interlocutor : TInterlocutor);
var
  DelimiterIndex : Integer = 0;
  ChildParse: String;
begin
  inherited Create;
  ChildParse := '';
  FInterlocutor := Interlocutor;
  FParse := '';
  while pos('(',ToParse) > 0 do
    begin
      FParse := FParse+copy(ToParse,0,pos('(',ToParse)-1);
      ToParse := copy(ToParse,pos('(',ToParse)+1,length(ToParse));
      inc(DelimiterIndex);
      while ((pos('(',ToParse) > 0) and (pos('(',ToParse) < pos(')',ToParse))) or (DelimiterIndex > 0) do
        begin
          if (pos('(',ToParse) > 0) and (pos('(',ToParse) < pos(')',ToParse)) then
            begin
              ChildParse := ChildParse+copy(ToParse,0,pos('(',ToParse)+1);
              ToParse := copy(ToParse,pos('(',ToParse)+1,length(ToParse));
              inc(DelimiterIndex);
            end
          else
            begin
              ChildParse := ChildParse+copy(ToParse,0,pos(')',ToParse)-1);
              ToParse := copy(ToParse,pos(')',ToParse)+1,length(ToParse));
              dec(DelimiterIndex);
            end;
        end;
    end;
  if ToParse <> '' then FParse := FParse+ToParse;
end;

function TParserEntry.IsValid(words,Variables : TStringList): Boolean;
var
  acheck : string;
  aidx: LongInt;
  aword: String;
  partOK: Boolean;
  aOK: Boolean;
  partword: String;
  partlist : TStringList;
  aop: String;
  firstindex: LongInt;
  i : Integer;
  aOldIdx: Integer = -1;
  anword: String;
  anop: String;
  tmp: String;
  aNewIndex: Integer;
  function ShortWord(aWord : string) : string;
  begin
    if Assigned(FInterlocutor) then
      Result := FInterlocutor.Stemm(aWord)
    else Result := aWord;
  end;

begin
  acheck := FParse;
  aOK := True;
  while (copy(acheck,0,1) = '+') or (copy(acheck,0,1) = '-') or (copy(acheck,0,1) = '=') do
    begin
      aidx := pos('+',copy(acheck,2,length(acheck)));
      if ((aidx = 0) or (pos('-',copy(acheck,2,length(acheck))) < aidx)) and (pos('-',copy(acheck,2,length(acheck))) > 0) then
        aidx := pos('-',copy(acheck,2,length(acheck)));
      if ((aidx = 0) or (pos('=',copy(acheck,2,length(acheck))) < aidx)) and (pos('=',copy(acheck,2,length(acheck))) > 0) then
        aidx := pos('=',copy(acheck,2,length(acheck)));
      aword := copy(acheck,0,aidx);
      if aword = '' then aword := acheck;
      acheck := copy(acheck,length(aword)+1,length(acheck));
      aop := copy(aword,0,1);
      aword := copy(aword,2,length(aword))+'|';
      if aop='=' then
        begin
          aidx := pos('+',copy(acheck,2,length(acheck)));
          if ((aidx = 0) or (pos('-',copy(acheck,2,length(acheck))) < aidx)) and (pos('-',copy(acheck,2,length(acheck))) > 0) then
            aidx := pos('-',copy(acheck,2,length(acheck)));
          if ((aidx = 0) or (pos('=',copy(acheck,2,length(acheck))) < aidx)) and (pos('=',copy(acheck,2,length(acheck))) > 0) then
            aidx := pos('=',copy(acheck,2,length(acheck)));
          anword := copy(acheck,0,aidx);
          anop := copy(anword,0,1);
          anword := copy(anword,2,length(anword))+'|';
          anword := copy(anword,0,pos('|',anword)-1);
          aNewIndex := words.IndexOfName(anword);
          if aNewIndex < 0 then aNewIndex:=words.Count;
          for i := 0 to length(sentenceends)-1 do
            if words[aNewIndex-1] = sentenceends[i] then
              dec(aNewIndex);
          for i := aOldIdx+1 to aNewIndex-1 do
            tmp := tmp+words.ValueFromIndex[i]+' ';
          Variables.Values[copy(aword,0,pos('|',aword)-1)]:=copy(tmp,0,length(tmp)-1);
        end
      else
        begin
          partOK := False;
          while pos('|',aword) > 0 do
            begin
              partword := copy(aword,0,pos('|',aword)-1);
              aword := copy(aword,pos('|',aword)+1,length(aword));
              if pos(' ',partword) > 0 then
                begin
                  partlist := TStringList.Create;
                  partlist.Delimiter:=' ';
                  partlist.DelimitedText:=partword;
                  i := 1;
                  firstindex := words.IndexOfName(ShortWord(partlist[0]));
                  partOK := (aop='+') and (firstindex > -1);
                  if partOK then
                    begin
                      while i < partlist.Count do
                        begin
                          partOK := partOK and (words.IndexOfName(ShortWord(partlist[i])) = firstindex+i);
                          inc(i);
                        end;
                    end;
                  partlist.free;
                end
              else if ((aop = '+') and (words.IndexOfName(ShortWord(partword)) <> -1)) or ((aop = '-') and (words.IndexOfName(ShortWord(partword)) = -1)) then
                begin
                  partOK := True;
                  if (aop = '+') then aOldIdx := words.IndexOfName(ShortWord(partword));
                end;
              if partOK then break;
            end;
          aOK := aOK and partOK;
        end;
//      if not aOK then break;
    end;
  Result := aOK;
end;

end.

