unit uIPLocation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,LNet,LHttp;
  
type
  TIPLocation = record
    Latitude,
    Lonitude : double;
  end;
  
function GetLocationFromIP(ip : string) : TIPLocation;

implementation

function GetLocationFromIP(ip : string) : TIPLocation;
begin
end;

end.

