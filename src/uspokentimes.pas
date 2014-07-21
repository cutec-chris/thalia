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
  Classes, SysUtils;

//heute,morgen,übermorgen...
//um 8
//am 24.04. um 8:34
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
  strSec                   = 's';
  strMin                   = 'min';
  strHour                  = 'h';
  strDay                   = 'T';

function ParseTime(aTimeIn: string; aTimeOut: TDateTime;
  aTimeDifference: TDateTime): Boolean;
var
  NewDay: TDateTime;
  aTime: TDateTime;
  tmp: String;
begin
  Result := False;
  aTimeIn:=trim(LowerCase(aTimeIn));
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
    end;
  Result := trim(aTimeIn)='';
end;

function SpokenTimeRangeToStr(aTime: TDateTime): string;
begin
  if Now()-aTime < 0 then
    result := strIn+' '
  else
    result := strbefore+' ';
  if Abs(Now()-aTime)<(1/MinsPerDay) then //unter einer Minute
    Result := Result+IntToStr(round(SecsPerDay/Abs(Now()-aTime)))+' '+strSec
  else if Abs(Now()-aTime)<(1/HoursPerDay) then //unter einer h
    Result := Result+IntToStr(round(MinsPerDay/Abs(Now()-aTime)))+' '+strMin
  else if Abs(Now()-aTime)<(1) then //unter einem Tag
    Result := Result+IntToStr(round(HoursPerDay/Abs(Now()-aTime)))+' '+strHour
  else if Abs(Now()-aTime)<(1) then //unter einem Tag
    Result := Result+IntToStr(round(Abs(Now()-aTime)))+' '+strday;
end;

end.

