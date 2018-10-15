//Delphi版雪花算法
//作者：不得闲
//QQ: 75492895
unit DxSnowflake;

interface
uses System.SysUtils,System.SyncObjs,System.Generics.Collections,System.DateUtils;

type
  TWorkerID = 0..1023;
  TDxSnowflake = class
  private
    FWorkerID: TWorkerID;
    FLocker: TCriticalSection;
    fTime: Int64;
    fstep: int64;
  public
    constructor Create;
    destructor Destroy;override;
    property WorkerID: TWorkerID read FWorkerID write FWorkerID;
    function Generate: Int64;
  end;

implementation

const
  Epoch: int64 = 1539615188000; //北京时间2018-10-15号
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

constructor TDxSnowflake.Create;
begin
  FLocker := TCriticalSection.Create;
end;


destructor TDxSnowflake.Destroy;
begin
  FLocker.Free;
  inherited;
end;

function TDxSnowflake.Generate: Int64;
var
  curtime: Int64;
begin
  FLocker.Acquire;
  try
    curtime := DateTimeToUnix(Now) * 1000;
    if curtime = fTime then
    begin
      fstep := (fstep + 1) and stepMask;
      if fstep = 0 then
      begin
        while curtime <= fTime do
          curtime := DateTimeToUnix(Now) * 1000;
      end;
    end
    else fstep := 0;
    fTime := curtime;
    Result := (curtime - Epoch) shl timeShift or FWorkerID shl nodeShift  or fstep;
  finally
    FLocker.Release;
  end;
end;

initialization
  InitNodeInfo;
end.
