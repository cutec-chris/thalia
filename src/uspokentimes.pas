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

unit uspokentimes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Utils;

//heute,morgen,übermorgen...
//um 8
//am 24.04. um 8:34
//15 min
//in 15 min
function ParseTime(aTimeIn : string;aTimeOut : TDateTime;aTimeDifference : TDateTime) : Boolean;
function SpokenTimeRangeToStr(aTime : TDateTime) : string;

implementation

resourcestring
  strNow                   = 'jetzt';
  strToday                 = 'heute';
  strTomorrow              = 'morgen';
  strTomorrow1             = 'übermorgen';
  strTomorrow2             = 'überübermorgen';
  strYesterday             = 'gestern';
  strYesterday1            = 'vorgestern';
  strYesterday2            = 'vorvorgestern';
  strOn                    = 'am ';
  strAt                    = 'um ';
  strIn                    = 'in ';
  strbefore                = 'vor ';
  strSec                   = 'sek';
  strSec2                  = 's';
  strSec3                  = 'Sekunden';
  strMin                   = 'min';
  strMin2                  = 'm';
  strMin3                  = 'Minuten';
  strHour                  = 'Std';
  strHour2                 = 'h';
  strHour3                 = 'Stunden';
  strDay                   = 'T';
  strDay3                  = 'Tage';

function ParseTime(aTimeIn: string; aTimeOut: TDateTime;
  aTimeDifference: TDateTime): Boolean;
var
  NewDay: TDateTime;
  aTime: TDateTime;
  tmp: String;
  aUnit: String;
  bUnit: double = -1;
begin
  Result := False;
  if aTimeIn='' then exit;
  aTimeIn:=trim(LowerCase(aTimeIn));
  aUnit := copy(aTimeIn,rpos(' ',aTimeIn)+1,length(aTimeIn));
  if (aUnit = strSec)
  or (aUnit = strSec2)
  or (aUnit = strSec3)
  then bUnit := 1/SecsPerDay;
  if (aUnit = strMin)
  or (aUnit = strMin2)
  or (aUnit = strMin3)
  then bUnit := 1/MinsPerDay;
  if (aUnit = strHour)
  or (aUnit = strHour2)
  or (aUnit = strHour3)
  then bUnit := 1/HoursPerDay;
  if (aUnit = strDay)
  or (aUnit = strDay3)
  then bUnit := 1;
  if bUnit<>-1 then
    begin
      aTimeDifference:=bUnit;
      aTimeIn:=copy(aTimeIn,0,rpos(' ',aTimeIn)-1);
      if copy(aTimeIn,0,length(strIn))=strIn then
        begin
          aTimeIn:=copy(aTimeIn,Length(strIn)+1,length(aTimeIn));
          aTimeOut:=0;
        end
      else aTimeOut:=Now();
      if IsNumeric(aTimeIn) then
        begin
          aTimeOut:=aTimeOut+(StrToInt(aTimeIn)*bUnit);
          Result := True;
        end;
    end;

  if aTimeIn=strNow then
    begin
      aTimeOut:=Now();
      aTimeDifference:=0;
      Result := True;
      exit;
    end;
  if aTimeIn=strToday then
    begin
      aTimeOut:=trunc(Now())+0.5; //12 Uhr
      aTimeDifference:=1;
      Result := True;
      exit;
    end;
  if aTimeIn=strTomorrow then
    begin
      aTimeOut:=trunc(Now()+1)+0.5; //12 Uhr
      aTimeDifference:=1;
      Result := True;
      exit;
    end;
  if aTimeIn=strTomorrow1 then
    begin
      aTimeOut:=trunc(Now()+2)+0.5; //12 Uhr
      aTimeDifference:=1;
      Result := True;
      exit;
    end;
  if aTimeIn=strTomorrow2 then
    begin
      aTimeOut:=trunc(Now()+3)+0.5; //12 Uhr
      aTimeDifference:=1;
      Result := True;
      exit;
    end;
  if aTimeIn=strYesterday then
    begin
      aTimeOut:=trunc(Now()-1)+0.5; //12 Uhr
      aTimeDifference:=1;
      Result := True;
      exit;
    end;
  if aTimeIn=strYesterday1 then
    begin
      aTimeOut:=trunc(Now()-2)+0.5; //12 Uhr
      aTimeDifference:=1;
      Result := True;
      exit;
    end;
  if aTimeIn=strYesterday2 then
    begin
      aTimeOut:=trunc(Now()-3)+0.5; //12 Uhr
      aTimeDifference:=1;
      Result := True;
      exit;
    end;
  if copy(aTimeIn,0,length(strOn))=strOn then
    begin
      aTimeIn:=copy(aTimeIn,Length(strOn)+1,length(aTimeIn));
      if pos(' ',aTimeIn)>-1 then
        begin
          tmp := copy(aTimeIn,0,pos(' ',aTimeIn)-1);
          aTimeIn:=copy(aTimeIn,pos(' ',aTimeIn)+1,length(aTimeIn));
        end
      else
        begin
          tmp := aTimeIn;
          aTimeIn:='';
        end;
      if not TryStrToDateTime(tmp,aTimeOut) then
        aTimeOut:=Now();
      aTimeOut:=trunc(aTimeOut)+0.5; //12 Uhr
      aTimeDifference:=1;
      Result := True;
    end;
  if copy(aTimeIn,0,length(strAt))=strAt then
    begin
      aTimeIn:=copy(aTimeIn,Length(strAt)+1,length(aTimeIn));
      if pos(' ',aTimeIn)>-1 then
        begin
          tmp := copy(aTimeIn,0,pos(' ',aTimeIn)-1);
          aTimeIn:=copy(aTimeIn,pos(' ',aTimeIn)+1,length(aTimeIn));
        end
      else
        begin
          tmp := aTimeIn;
          aTimeIn:='';
        end;
      if not TryStrToTime(tmp,aTime) then
        aTime:=Now();
      aTimeOut:=trunc(aTimeOut)+frac(aTime);
      aTimeDifference:=0.1;
      Result := True;
    end;
  Result := trim(aTimeIn)='';
end;

function SpokenTimeRangeToStr(aTime: TDateTime): string;
var
  bTime: ValReal;
begin
  bTime := Abs(aTime-Now());
  if bTime = 0 then exit;
  if Now()-aTime > 0 then
    result := strIn+' '
  else
    result := strbefore+' ';
  if bTime<(1/MinsPerDay) then //unter einer Minute
    Result := Result+IntToStr(round(SecsPerDay/bTime))+' '+strSec
  else if bTime<(1/HoursPerDay) then //unter einer h
    Result := Result+IntToStr(round(MinsPerDay/bTime))+' '+strMin
  else if bTime<(1) then //unter einem Tag
    Result := Result+IntToStr(round(HoursPerDay/bTime))+' '+strHour
  else if bTime<(1) then //unter einem Tag
    Result := Result+IntToStr(round(bTime))+' '+strday;
end;

end.

