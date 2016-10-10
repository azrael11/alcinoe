{*************************************************************
www:          http://sourceforge.net/projects/alcinoe/              
svn:          svn checkout svn://svn.code.sf.net/p/alcinoe/code/ alcinoe-code              
Author(s):    St�phane Vander Clock (skype/email: svanderclock@yahoo.fr)
							
product:      Alcinoe Common functions
Version:      4.00

Description:  Alcinoe Common Functions

Legal issues: Copyright (C) 1999-2013 by Arkadia Software Engineering

              This software is provided 'as-is', without any express
              or implied warranty.  In no event will the author be
              held liable for any  damages arising from the use of
              this software.

              Permission is granted to anyone to use this software
              for any purpose, including commercial applications,
              and to alter it and redistribute it freely, subject
              to the following restrictions:

              1. The origin of this software must not be
                 misrepresented, you must not claim that you wrote
                 the original software. If you use this software in
                 a product, an acknowledgment in the product
                 documentation would be appreciated but is not
                 required.

              2. Altered source versions must be plainly marked as
                 such, and must not be misrepresented as being the
                 original software.

              3. This notice may not be removed or altered from any
                 source distribution.

              4. You must register this software by sending a picture
                 postcard to the author. Use a nice stamp and mention
                 your name, street address, EMail address and any
                 comment you like to say.

Know bug :

History :     09/01/2005: correct then AlEmptyDirectory function
              25/05/2006: Move some function to AlFcnFile
              25/02/2008: Update AlIsValidEmail
              06/10/3008: Update AlIsValidEmail
              03/03/2010: add ALIsInt64
              26/06/2012: Add xe2 support
Link :

**************************************************************}
unit ALCommon;

interface

{$IF CompilerVersion >= 25} {Delphi XE4}
  {$LEGACYIFEND ON} // http://docwiki.embarcadero.com/RADStudio/XE4/en/Legacy_IFEND_(Delphi)
{$IFEND}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
Type TalLogType = (VERBOSE, DEBUG, INFO, WARN, ERROR, ASSERT);
procedure ALLog(Const Tag: String; Const msg: String; const _type: TalLogType = TalLogType.INFO);

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
type TALCustomDelayedFreeObjectProc = procedure(var aObject: Tobject) of object;
var ALCustomDelayedFreeObjectProc: TALCustomDelayedFreeObjectProc;
{$IFDEF DEBUG}
var ALFreeAndNilRefCountWarn: boolean;
threadvar ALCurThreadFreeAndNilRefCountWarn: integer; // 0 = Not set (use value from ALFreeAndNilRefCountWarn)  | 1 Mean true | any other value mean false
{$ENDIF}
Procedure ALFreeAndNil(var Obj; const adelayed: boolean = false); overload;
Procedure ALFreeAndNil(var Obj; const adelayed: boolean; const aRefCountWarn: Boolean); overload; {$IFNDEF DEBUG}inline;{$ENDIF}

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
Function AlBoolToInt(Value:Boolean):Integer;
Function AlIntToBool(Value:integer):boolean;
Function ALMediumPos(LTotal, LBorder, LObject : integer):Integer;
{$IFDEF MSWINDOWS}
function AlLocalDateTimeToGMTDateTime(Const aLocalDateTime: TDateTime): TdateTime;
function ALGMTNow: TDateTime;
{$ENDIF}
function ALUnixMsToDateTime(const aValue: Int64): TDateTime;
function ALDateTimeToUnixMs(const aValue: TDateTime): Int64;
Function ALInc(var x: integer; Count: integer): Integer;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
const ALMAXUInt64: UInt64 = 18446744073709551615;
      ALMAXInt64: Int64 = 9223372036854775807;
      ALMAXINT: integer = 2147483647; // this is unecessarily because MAXINT system const exists but just for consistency
      ALNullDate = -0.5; // There are no TDateTime values from �1 through 0
                         // dt := -0.5;
                         // writeln(formatFloat('0.0', dt));                    => -0.5
                         // writeln(DateTimeToStr(dt));                         => 1899/12/30 12:00:00.000
                         //
                         // dt := encodedatetime(1899,12,30,12,00,00,000);
                         // writeln(formatFloat('0.0', dt));                    => 0.5
                         // writeln(DateTimeToStr(dt));                         => 1899/12/30 12:00:00.000

implementation

uses system.Classes,
     {$IFDEF MSWINDOWS}
     Winapi.Windows,
     {$ENDIF}
     {$IF defined(ANDROID)}
     Androidapi.JNI.JavaTypes,
     Androidapi.Helpers,
     ALAndroidApi,
     {$IFEND}
     {$IF defined(IOS)}
     iOSapi.Foundation,
     Macapi.Helpers,
     {$IFEND}
     {$IF defined(FMX)}
     Fmx.types,
     {$IFEND}
     system.sysutils,
     system.DateUtils;

{***********************************************************************************************}
procedure ALLog(Const Tag: String; Const msg: String; const _type: TalLogType = TalLogType.INFO);
{$IF defined(IOS)}
var aMsg: String;
{$ELSEIF defined(MSWINDOWS) and defined(FMX)}
var aMsg: String;
{$IFEND}
begin
  {$IF defined(ANDROID)}
  case _type of
    TalLogType.VERBOSE: TJALLog.JavaClass.v(StringToJString(Tag), StringToJString(msg));
    TalLogType.DEBUG: TJALLog.JavaClass.d(StringToJString(Tag), StringToJString(msg));
    TalLogType.INFO: TJALLog.JavaClass.i(StringToJString(Tag), StringToJString(msg));
    TalLogType.WARN: TJALLog.JavaClass.w(StringToJString(Tag), StringToJString(msg));
    TalLogType.ERROR: TJALLog.JavaClass.e(StringToJString(Tag), StringToJString(msg));
    TalLogType.ASSERT: TJALLog.JavaClass.wtf(StringToJString(Tag), StringToJString(msg)); // << wtf for What a Terrible Failure but everyone know that it's for what the fuck !
  end;
  {$ELSEIF defined(IOS)}
  // https://forums.developer.apple.com/thread/4685
  if msg <> '' then aMsg := ' => ' + msg
  else aMsg := '';
  case _type of
    TalLogType.VERBOSE: NSLog(StringToID('[V] ' + Tag + aMsg));
    TalLogType.DEBUG:   NSLog(StringToID('[D][V] ' + Tag + aMsg));
    TalLogType.INFO:    NSLog(StringToID('[I][D][V] ' + Tag + aMsg));
    TalLogType.WARN:    NSLog(StringToID('[W][I][D][V] ' + Tag + aMsg));
    TalLogType.ERROR:   NSLog(StringToID('[E][W][I][D][V] ' + Tag + aMsg));
    TalLogType.ASSERT:  NSLog(StringToID('[A][E][W][I][D][V] ' + Tag + aMsg));
  end;
  {$ELSEIF defined(MSWINDOWS) and defined(FMX)}
  if msg <> '' then aMsg := ' => ' + stringReplace(msg, '%', '%%', [rfReplaceALL]) // https://quality.embarcadero.com/browse/RSP-15942
  else aMsg := '';
  case _type of
    TalLogType.VERBOSE: Log.d('[V] ' + Tag + aMsg + ' |');
    TalLogType.DEBUG:   Log.d('[D][V] ' + Tag + aMsg + ' |');
    TalLogType.INFO:    Log.d('[I][D][V] ' + Tag + aMsg + ' |');
    TalLogType.WARN:    Log.d('[W][I][D][V] ' + Tag + aMsg + ' |');
    TalLogType.ERROR:   Log.d('[E][W][I][D][V] ' + Tag + aMsg + ' |');
    TalLogType.ASSERT:  Log.d('[A][E][W][I][D][V] ' + Tag + aMsg + ' |');
  end;
  {$IFEND}
end;

{******************************************}
Function AlBoolToInt(Value:Boolean):Integer;
Begin
  If Value then result := 1
  else result := 0;
end;

{******************************************}
Function AlIntToBool(Value:integer):boolean;
begin
  result := Value <> 0;
end;

{***************************************************************}
Function ALMediumPos(LTotal, LBorder, LObject : integer):Integer;
Begin
  result := (LTotal - (LBorder*2) - LObject) div 2 + LBorder;
End;

{****************}
{$IFDEF MSWINDOWS}
function AlLocalDateTimeToGMTDateTime(Const aLocalDateTime: TDateTime): TdateTime;

  {--------------------------------------------}
  function InternalCalcTimeZoneBias : TDateTime;
  const Time_Zone_ID_DayLight = 2;
  var TZI: TTimeZoneInformation;
      TZIResult: Integer;
      aBias : Integer;
  begin
    TZIResult := GetTimeZoneInformation(TZI);
    if TZIResult = -1 then Result := 0
    else begin
      if TZIResult = Time_Zone_ID_DayLight then aBias := TZI.Bias + TZI.DayLightBias
      else aBias := TZI.Bias + TZI.StandardBias;
      Result := EncodeTime(Abs(aBias) div 60, Abs(aBias) mod 60, 0, 0);
      if aBias < 0 then Result := -Result;
    end;
  end;

begin
  Result := aLocalDateTime + InternalCalcTimeZoneBias;
end;
{$ENDIF}

{****************}
{$IFDEF MSWINDOWS}
{The same like Now but used
 GMT-time not local time.}
function ALGMTNow: TDateTime;
begin
  result := AlLocalDateTimeToGMTDateTime(NOW);
end;
{$ENDIF}

{******************************************************}
Function ALInc(var x: integer; Count: integer): Integer;
begin
  inc(X, count);
  result := X;
end;

{*******************************************************}
{Accepts number of milliseconds in the parameter aValue,
 provides 1000 times more precise value of TDateTime}
function ALUnixMsToDateTime(const aValue: Int64): TDateTime;
begin
  Result := IncMilliSecond(UnixDateDelta, aValue);
end;

{********************************************************}
{Returns UNIX-time as the count of milliseconds since the
 UNIX epoch. Can be very useful for the purposes of
 special precision.}
function ALDateTimeToUnixMs(const aValue: TDateTime): Int64;
begin
  result := MilliSecondsBetween(UnixDateDelta, aValue);
  if aValue < UnixDateDelta then result := -result;
end;

{***************************************************************}
Procedure ALFreeAndNil(var Obj; const adelayed: boolean = false);
var Temp: TObject;
begin
  Temp := TObject(Obj);
  if temp = nil then exit;
  TObject(Obj) := nil;
  {$IF defined(FMX)}
  if Temp is TFMXObject then begin
    TFMXObject(Temp).Parent := nil; // if parent is assigned then their will be a pointer that will forbid the free
    if assigned(TFMXObject(Temp).Owner) then TFMXObject(Temp).Owner.RemoveComponent(TFMXObject(Temp));
  end;
  {$IFEND}
  if adelayed and assigned(ALCustomDelayedFreeObjectProc) then ALCustomDelayedFreeObjectProc(Temp)
  else begin
    {$IF defined(AUTOREFCOUNT)}
    if temp.refcount = 1 then begin // refcount is an Integer (4 bytes) so it's mean that all read / write are atomic no need to lock (but is this true under ios/android?)
      temp.Free;
      temp := nil;
    end
    else begin
      Temp.DisposeOf; // TComponent Free Notification mechanism notifies registered components that particular
                      // component instance is being freed. Notified components can handle that notification inside
                      // virtual Notification method and make sure that they clear all references they may hold on
                      // component being destroyed.
                      //
                      // Free Notification mechanism is being triggered in TComponent destructor and without DisposeOf
                      // and direct execution of destructor, two components could hold strong references to each
                      // other keeping themselves alive during whole application lifetime.
      {$IF defined(DEBUG)}
      if ALFreeAndNilRefCountWarn and
        ((ALCurThreadFreeAndNilRefCountWarn = 0) or
         (ALCurThreadFreeAndNilRefCountWarn = 1)) then begin
        if (Temp.RefCount - 1) and (not $40000000{Temp.objDisposedFlag}) <> 0 then
          ALLog('ALFreeAndNil', Temp.ClassName + ' | Refcount is not null (' + Inttostr((Temp.RefCount - 1) and (not $40000000{Temp.objDisposedFlag})) + ')', TalLogType.warn);
      end;
      {$IFEND}
      temp := nil;
    end;
    {$ELSE}
    temp.Free;
    temp := nil;
    {$IFEND}
  end;
end;

{*************************************************************************************}
Procedure ALFreeAndNil(var Obj; const adelayed: boolean; const aRefCountWarn: Boolean);
{$IFDEF DEBUG}
var aOldCurThreadFreeAndNilRefCountWarn: integer;
{$ENDIF}
begin
  {$IFDEF DEBUG}
  aOldCurThreadFreeAndNilRefCountWarn := ALCurThreadFreeAndNilRefCountWarn;
  if aRefCountWarn then ALCurThreadFreeAndNilRefCountWarn := 1
  else ALCurThreadFreeAndNilRefCountWarn := 2;
  try
  {$ENDIF}

    ALFreeAndNil(Obj, adelayed);

  {$IFDEF DEBUG}
  finally
    ALCurThreadFreeAndNilRefCountWarn := aOldCurThreadFreeAndNilRefCountWarn;
  end;
  {$ENDIF}
end;

initialization
  ALCustomDelayedFreeObjectProc := nil;
  {$IFDEF DEBUG}
  ALFreeAndNilRefCountWarn := False;
  {$ENDIF}

end.
