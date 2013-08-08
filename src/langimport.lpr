program langimport;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes
  { you can add units after this }
  ,sqlite3ds,FileUtil,SysUtils,db,Windows;

function Ansi2OEM(Const AString: String): String;
var
  lResult: String;
begin
  SetLength(lResult, Length(AString));
  {$IFDEF WIN32}
  CharToOEM(PChar(AString), PChar(lResult)); {32Bit}
  {$ELSE}
  AnsiToOEM(PChar(@AString[1]), PChar(@lResult[1])); {16Bit}
  {$ENDIF}
  Result := lResult;
end;

var
  Data : TSqlite3Dataset;
  f : TextFile;
  tmp : string;
  LangDir: String;
  typ: Integer;
  use: Integer;
  craft: Integer;
  meaning: Integer;
  aword: String;

procedure FindTyp(var aword : string;DoRemove : Boolean = False);
begin
  if pos('{',aword) > 0 then
    begin
              if pos('{pl}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{pl}','',[rfReplaceAll]);
                  typ := 0;
                end
              else if pos('{f}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{f}','',[rfReplaceAll]);
                  typ := 1;
                end
              else if pos('{m}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{m}','',[rfReplaceAll]);
                  typ := 2;
                end
              else if pos('{n}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{n}','',[rfReplaceAll]);
                  typ := 3;
                end
              else if (pos('{f,m}',aword) = pos('{',aword)) or (pos('{m,f}',aword) = pos('{',aword)) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{f,m}','',[rfReplaceAll]);
                  if DoRemove then
                  aword := StringReplace(aword,'{m,f}','',[rfReplaceAll]);
                  typ := 4;
                end
              else if pos('{vt}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{vt}','',[rfReplaceAll]);
                  typ := 5;
                end
              else if pos('{vi}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{vi}','',[rfReplaceAll]);
                  typ := 6;
                end
              else if pos('{vr}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{vr}','',[rfReplaceAll]);
                  typ := 7;
                end
              else if pos('{adj}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{adj}','',[rfReplaceAll]);
                  typ := 8;
                end
              else if pos('{adv}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{adv}','',[rfReplaceAll]);
                  typ := 9;
                end
              else if pos('{prp}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{prp}','',[rfReplaceAll]);
                  typ := 10;
                end
              else if pos('{num}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{num}','',[rfReplaceAll]);
                  typ := 11;
                end
              else if pos('{art}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{art}','',[rfReplaceAll]);
                  typ := 12;
                end
              else if pos('{ppron}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{ppron}','',[rfReplaceAll]);
                  typ := 13;
                end
              else if pos('{conj}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{conj}','',[rfReplaceAll]);
                  typ := 14;
                end
              else if pos('{interj}',aword) = pos('{',aword) then
                begin
                  if DoRemove then
                  aword := StringReplace(aword,'{interj}','',[rfReplaceAll]);
                  typ := 15;
                end;
    end;
end;

procedure ProcessWord(aword : string);
begin
  FindTyp(aword,True);
              aword := stringreplace(aword,'''','',[rfReplaceAll]);
              aword := stringreplace(aword,'"','',[rfReplaceAll]);
              aword := trim(aword);
              if (pos(' ',aword) = 0) and (typ <> -1) and (pos('...',aword) = 0) then
                begin
                  try
                    Data.ExecSQL('insert into dict (WORD,WORDTYPE,CRAFT,USE,MEANING) values ("'+trim(lowercase(aword))+'",'+IntToStr(Typ)+','+IntToStr(craft)+','+IntToStr(use)+','+IntToStr(meaning)+');');
                  except
                    writeln('Failed:("'+lowercase(aword)+'",'+IntToStr(Typ)+','+IntToStr(craft)+','+IntToStr(use)+','+IntToStr(meaning)+');')
                  end;
                end;
              writeln(Ansi2OEM(aword));
end;

begin
  LangDir := AppendPathDelim(AppendPathDelim(AppendPathDelim(ExtractFilePath(ParamStr(0)))+'languages')+Paramstr(1));
  if not DirectoryExists(LangDir) then
    begin
      writeln('Language Directory dont exists !');
      Halt(0);
    end;
  Data := TSqlite3Dataset.Create(nil);
  with Data do
    begin
      FileName:=LangDir+'dict.db';
      TableName:='dict';
      if not FileExists(FileName) then
        begin
          with FieldDefs do
            begin
              Clear;
              Add('ID',ftAutoInc,0,True);
              Add('WORD',ftString,80,False);
              Add('WORDTYPE',ftInteger,0,False);
              Add('CRAFT',ftInteger,0,False);
              Add('USE',ftInteger,0,False);
              Add('MEANING',ftInteger,0,False);
            end;
          CreateTable;
        end;
    end;
  meaning := 0;
  Data.Open;
  Data.ExecSQL('CREATE UNIQUE INDEX IWORD ON dict (WORD)');
  if FileExists(Paramstr(2)) then
    begin
      AssignFile(f,Paramstr(2));
      Reset(f);
      while not EOF(f) do
        begin
          inc(meaning);
          readln(f,tmp);
          if copy(trim(tmp),0,1) = '#' then continue;
          if pos('::',tmp) > 0 then tmp := copy(tmp,0,pos('::',tmp)-1);
          while pos('(',tmp) > 0 do
            begin
              if (pos('(',tmp) > 0) and (pos(')',tmp) > 0) then
                tmp := copy(tmp,0,pos('(',tmp)-1)+copy(tmp,pos(')',tmp)+1,length(tmp))
              else
                tmp := copy(tmp,0,pos('(',tmp)-1);
            end;
          typ := -1;
          use := -1;
          if pos('[alt]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[alt]','',[rfReplaceAll]);
              use := 0;
            end;
          if pos('[obs.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[obs.]','',[rfReplaceAll]);
              use := 1;
            end;
          if pos('[Süddt.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[Süddt.]','',[rfReplaceAll]);
              use := 2;
            end;
          if pos('[Ös.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[Ös.]','',[rfReplaceAll]);
              use := 3;
            end;
          if pos('[Schw.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[Schw.]','',[rfReplaceAll]);
              use := 4;
            end;
          if (pos('[ugs.]',tmp) > 0) or (pos('[coll.]',tmp) > 0) then
            begin
              tmp := StringReplace(tmp,'[coll.]','',[rfReplaceAll]);
              tmp := StringReplace(tmp,'[ugs.]','',[rfReplaceAll]);
              use := 5;
            end;
          if (pos('[übtr.]',tmp) > 0) or (pos('[fig.]',tmp) > 0) then
            begin
              tmp := StringReplace(tmp,'[fig.]','',[rfReplaceAll]);
              tmp := StringReplace(tmp,'[übtr.]','',[rfReplaceAll]);
              use := 6;
            end;
          if pos('[poet.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[poet.]','',[rfReplaceAll]);
              use := 7;
            end;
          if pos('[pej.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[pej.]','',[rfReplaceAll]);
              use := 8;
            end;
          if pos('[vulg.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[vulg.]','',[rfReplaceAll]);
              use := 9;
            end;
          if pos('[slang]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[slang]','',[rfReplaceAll]);
              use := 10;
            end;
          if pos('[slang]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[slang]','',[rfReplaceAll]);
              use := 11;
            end;
          if (pos('[Sprw.]',tmp) > 0) or (pos('[prov.]',tmp) > 0) then
            begin
              tmp := StringReplace(tmp,'[Sprw.]','',[rfReplaceAll]);
              tmp := StringReplace(tmp,'[prov.]','',[rfReplaceAll]);
              use := 12;
            end;
          craft := -1;
          if pos('[agr.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[agr.]','',[rfReplaceAll]);
              craft := 0;
            end;
          if pos('[anat.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[anat.]','',[rfReplaceAll]);
              craft := 1;
            end;
          if pos('[arch.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[arch.]','',[rfReplaceAll]);
              craft := 2;
            end;
          if pos('[astron.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[astron.]','',[rfReplaceAll]);
              craft := 3;
            end;
          if (pos('[auto]',tmp) > 0) or (pos('[auto.]',tmp) > 0) then
            begin
              tmp := StringReplace(tmp,'[auto]','',[rfReplaceAll]);
              tmp := StringReplace(tmp,'[auto.]','',[rfReplaceAll]);
              craft := 4;
            end;
          if pos('[aviat.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[aviat.]','',[rfReplaceAll]);
              craft := 5;
            end;
          if pos('[biochem.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[biochem.]','',[rfReplaceAll]);
              craft := 6;
            end;
          if pos('[biol.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[biol.]','',[rfReplaceAll]);
              craft := 7;
            end;
          if pos('[bot.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[bot.]','',[rfReplaceAll]);
              craft := 8;
            end;
          if pos('[chem.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[chem.]','',[rfReplaceAll]);
              craft := 9;
            end;
          if pos('[comp.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[comp.]','',[rfReplaceAll]);
              craft := 10;
            end;
          if pos('[constr.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[constr.]','',[rfReplaceAll]);
              craft := 11;
            end;
          if pos('[cook.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[cook.]','',[rfReplaceAll]);
              craft := 12;
            end;
          if pos('[econ.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[econ.]','',[rfReplaceAll]);
              craft := 13;
            end;
          if pos('[electr.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[electr.]','',[rfReplaceAll]);
              craft := 14;
            end;
          if pos('[fin.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[fin.]','',[rfReplaceAll]);
              craft := 15;
            end;
          if pos('[geogr.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[geogr.]','',[rfReplaceAll]);
              craft := 16;
            end;
          if pos('[geol.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[geol.]','',[rfReplaceAll]);
              craft := 17;
            end;
          if pos('[gramm.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[gramm.]','',[rfReplaceAll]);
              craft := 18;
            end;
          if pos('[hist.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[hist.]','',[rfReplaceAll]);
              craft := 19;
            end;
          if pos('[jur.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[jur.]','',[rfReplaceAll]);
              craft := 20;
            end;
          if pos('[mach.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[mach.]','',[rfReplaceAll]);
              craft := 21;
            end;
          if pos('[math.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[math.]','',[rfReplaceAll]);
              craft := 22;
            end;
          if pos('[med.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[med.]','',[rfReplaceAll]);
              craft := 23;
            end;
          if pos('[meteo.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[meteo.]','',[rfReplaceAll]);
              craft := 24;
            end;
          if pos('[mil.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[mil.]','',[rfReplaceAll]);
              craft := 25;
            end;
          if pos('[min.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[min.]','',[rfReplaceAll]);
              craft := 26;
            end;
          if pos('[mus.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[mus.]','',[rfReplaceAll]);
              craft := 27;
            end;
          if pos('[naut.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[naut.]','',[rfReplaceAll]);
              craft := 28;
            end;
          if pos('[ornith.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[ornith.]','',[rfReplaceAll]);
              craft := 29;
            end;
          if pos('[pharm.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[pharm.]','',[rfReplaceAll]);
              craft := 30;
            end;
          if pos('[phil.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[phil.]','',[rfReplaceAll]);
              craft := 31;
            end;
          if pos('[phys.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[phys.]','',[rfReplaceAll]);
              craft := 32;
            end;
          if pos('[pol.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[pol.]','',[rfReplaceAll]);
              craft := 33;
            end;
          if pos('[relig.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[relig.]','',[rfReplaceAll]);
              craft := 34;
            end;
          if pos('[sport]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[sport]','',[rfReplaceAll]);
              craft := 35;
            end;
          if pos('[techn.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[techn.]','',[rfReplaceAll]);
              craft := 36;
            end;
          if pos('[textil.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[textil.]','',[rfReplaceAll]);
              craft := 37;
            end;
          if pos('[zool.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[zool.]','',[rfReplaceAll]);
              craft := 38;
            end;
          if pos('[lingu.]',tmp) > 0 then
            begin
              tmp := StringReplace(tmp,'[lingu.]','',[rfReplaceAll]);
              craft := 39;
            end;
          if pos('|',tmp) > 0 then
            tmp := copy(tmp,0,pos('|',tmp)-1);
          FindTyp(tmp);
          while (pos(';',tmp) > 0) or (pos('|',tmp) > 0) do
            begin
              if (pos(';',tmp) > 0) and ((pos('|',tmp) = 0) or (pos(';',tmp) < pos('|',tmp))) then
                begin
                  aword := trim(copy(tmp,0,pos(';',tmp)-1));
                  tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                end
              else
                begin
                  aword := trim(copy(tmp,0,pos('|',tmp)-1));
                  tmp := copy(tmp,pos('|',tmp)+1,length(tmp));
                end;
              ProcessWord(aWord);
            end;
          ProcessWord(tmp);
        end;
      CloseFile(f);
      if not Data.ApplyUpdates then writeln('ApplyUpdates failed !');
    end
  else
    writeln('File '+ParamStr(2)+' dont exists !');
  Data.Close;
  Data.Free;
  writeln('ready.');
  readln;
end.

