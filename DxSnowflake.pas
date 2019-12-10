//Delphi版雪花算法
//作者：不得闲
//https://github.com/suiyunonghen/DelphiSnowflake
//QQ: 75492895
unit DxSnowflake;

interface
uses {$IF Defined(MSWINDOWS)}Winapi.Windows{$ELSEIF Defined(MACOS)}Macapi.Mach,Macapi.ObjCRuntime
{$ELSEIF Defined(POSIX)}{$ENDIF},System.SysUtils,System.Generics.Collections,System.DateUtils;

type
  TWorkerID = 0..1023;
  TDxSnowflake = class
  private
    FStartUnix: int64;
    FWorkerID: TWorkerID;
    fTime: Int64;
    fstep: int64;
    FStartEpoch: Int64;
    freq: Int64;
    startC: Int64;
    function CurrentUnix: Int64;
  public
    constructor Create(StartTime: TDateTime);
    destructor Destroy;override;
    property WorkerID: TWorkerID read FWorkerID write FWorkerID;
    function Generate: Int64;
  end;

implementation

const
  Epoch: int64 = 1539615188; //北京时间2018-10-15号
  //工作站的节点位数
  WorkerNodeBits:Byte = 10;
  //序列号的节点数
	StepBits: Byte = 12;
  timeShift: Byte = 22;
	nodeShift: Byte = 12;
var
	WorkerNodeMax: int64;
	nodeMask:int64;

	stepMask:int64;

procedure InitNodeInfo;
begin
	WorkerNodeMax := -1 xor (-1 shl WorkerNodeBits);
	nodeMask := WorkerNodeMax shl StepBits;
	stepMask := -1 xor (-1 shl StepBits);
end;
{ TDxSnowflake }

constructor TDxSnowflake.Create(StartTime: TDateTime);
{$IF Defined(POSIX)}
var
  res: timespec;
{$ENDIF}
begin
  if StartTime >= Now then
    FStartEpoch := DateTimeToUnix(IncMinute(Now,-2))
  else if YearOf(StartTime) < 1984 then
    FStartEpoch := Epoch
  else FStartEpoch := DateTimeToUnix(StartTime);
  FStartEpoch := FStartEpoch * 1000;//ms
  FStartUnix := DateTimeToUnix(Now) * 1000;
  {$IF Defined(MSWINDOWS)}
  //获得系统的高性能频率计数器在一毫秒内的震动次数
  queryperformancefrequency(freq);
  QueryPerformanceCounter(startC);
  {$ELSEIF Defined(MACOS)}
  startC := AbsoluteToNanoseconds(mach_absolute_time) div 1000000;
  {$ELSEIF Defined(POSIX)}
  clock_gettime(CLOCK_MONOTONIC, @res);
  startC := (Int64(1000000000) * res.tv_sec + res.tv_nsec) div 1000000;
  {$ENDIF}
end;


function TDxSnowflake.CurrentUnix: Int64;
var
  nend: Int64;
{$IF Defined(POSIX)}
  res: timespec;
{$ENDIF}
begin
  {$IF Defined(MSWINDOWS)}
  QueryPerformanceCounter(nend);
  Result := FStartUnix + (nend - startC) * 1000 div freq;
  {$ELSEIF Defined(MACOS)}
  nend := AbsoluteToNanoseconds(mach_absolute_time) div 1000000;
  Result := FStartUnix + nend - startC;
  {$ELSEIF Defined(POSIX)}
  clock_gettime(CLOCK_MONOTONIC, @res);
  nend := (Int64(1000000000) * res.tv_sec + res.tv_nsec) div 1000000;
  Result := FStartUnix + nend - startC;
  {$ENDIF}
end;

destructor TDxSnowflake.Destroy;
begin
  inherited;
end;

function TDxSnowflake.Generate: Int64;
var
  curtime: Int64;
begin
  TMonitor.Enter(Self);
  try
    curtime := CurrentUnix;//DateTimeToUnix(Now) * 1000;
    if curtime = fTime then
    begin
      fstep := (fstep + 1) and stepMask;
      if fstep = 0 then
      begin
        while curtime <= fTime do
          curtime := CurrentUnix;//DateTimeToUnix(Now) * 1000;
      end;
    end
    else fstep := 0;
    fTime := curtime;
    Result := (curtime - FStartEpoch) shl timeShift or FWorkerID shl nodeShift  or fstep;
  finally
    TMonitor.Exit(Self);
  end;
end;

initialization
  InitNodeInfo;
end.
