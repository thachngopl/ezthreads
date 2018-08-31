{ ezthreads

  Copyright (c) 2018 mr-highball

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.
}

unit ezthreads;

{$mode delphi}{$H+}
{$modeswitch nestedprocvars}

interface

uses
  Classes, SysUtils, variants;

type

  //forward
  IEZThread = interface;

  (*
    callback method for ezthreads
  *)
  TThreadCallback = procedure(Const AThread:IEZThread);

  (*
    nested callback method for ezthreads
  *)
  TThreadNestedCallback = procedure(Const AThread:IEZThread) is nested;

  (*
    object method for ezthreads
  *)
  TThreadMethod = procedure(Const AThread:IEZThread) of object;

  (*
    callback method for cleaning up arguments
  *)
  TArgCleanupCallback = procedure(Const AArg:Variant);

  (*
    nested callback method for cleaning up arguments
  *)
  TArgCleanupNestedCallback = procedure(Const AArg:Variant) is nested;

  (*
    object method for cleaning up arguments
  *)
  TArgCleanupMethod = procedure(Const AArg:Variant) of object;

  TVariantArray = array of Variant;


  { IEZThreadSettings }
  (*
    settings for an ezthread that deal with the operation of the thread
  *)
  IEZThreadSettings = interface
    ['{1EE5C618-DA56-4101-BE75-1FD25F131ED2}']
    //property methods
    function GetMaxRunTime: Cardinal;
    function GetThread: IEZThread;

    //properties
    (*
      maximum time a method is allowed to run without being aborted
    *)
    property MaxRuntime : Cardinal read GetMaxRunTime;

    (*
      parent thread these settings belong to
    *)
    property Thread : IEZThread read GetThread;

    //methods
    function UpdateMaxRuntime(Const ARuntime:Cardinal):IEZThreadSettings;
  end;

  { IEZThreadEvents }
  (*
    all events that can be registered with an ezthread
  *)
  IEZThreadEvents = interface
    ['{7709EF05-BC0F-41A2-AB2B-2FCD8F305D8D}']
    //property methods
    function GetOnStart: TThreadMethod;
    function GetOnStartCall: TThreadCallback;
    function GetOnStartNestCall: TThreadNestedCallback;
    function GetOnStop: TThreadMethod;
    function GetOnStopCall: TThreadCallback;
    function GetOnStopNestCall: TThreadNestedCallback;
    function GetThread: IEZThread;

    //properties
    (*
      called once the thread successfully starts
    *)
    property OnStart : TThreadMethod read GetOnStart;
    property OnStartCallback : TThreadCallback read GetOnStartCall;
    property OnStartNestedCallback : TThreadNestedCallback read GetOnStartNestCall;

    (*
      called once the thread successfully stops either by force or by
      finishing gracefully
    *)
    property OnStop : TThreadMethod read GetOnStop;
    property OnStopCallback : TThreadCallback read GetOnStopCall;
    property OnStopNestedCallback : TThreadNestedCallback read GetOnStopNestCall;

    (*
      parent thread these settings belong to
    *)
    property Thread : IEZThread read GetThread;

    //methods
    function UpdateOnStart(Const AOnStart:TThreadMethod):IEZThreadEvents;
    function UpdateOnStartCallback(Const AOnStart:TThreadCallback):IEZThreadEvents;
    function UpdateOnStartNestedCallback(Const AOnStart:TThreadNestedCallback):IEZThreadEvents;
    function UpdateOnStop(Const AOnStop:TThreadMethod):IEZThreadEvents;
    function UpdateOnStopCallback(Const AOnStop:TThreadCallback):IEZThreadEvents;
    function UpdateOnStopNestedCallback(Const AOnStop:TThreadNestedCallback):IEZThreadEvents;
  end;

  (*
    IEZThread provides a simple to use and flexible interface
    for performing multithreaded tasks
  *)
  IEZThread = interface
    ['{998776BC-86C1-432D-B864-BC3A5FF6860A}']
    //property methods
    function GetSettings: IEZThreadSettings;
    function GetEvents: IEZThreadEvents;
    function GetExists(const AName: String): Boolean;
    function GetByName(const AName: String): Variant;

    //properties
    property Settings:IEZThreadSettings read GetSettings;
    property Events:IEZThreadEvents read GetEvents;
    property Exists[Const AName:String]:Boolean read GetExists;
    property ByName[Const AName:String]:Variant read GetByName;default;

    //methods
    (*
      add a single argument to this ezthread and an optional
      cleanup method (will overwrite if name exists)
    *)
    function AddArg(Const AName:String;Const AArg:Variant;
      Const AOnFinish:TArgCleanupMethod;
      Const AOnFinishCall:TArgCleanupCallback;
      Const AOnFinishNestedCall:TArgCleanupNestedCallback):IEZThread;overload;
    function AddArg(Const AName:String;Const AArg:Variant;
      Const AOnFinish:TArgCleanupCallback):IEZThread;overload;
    function AddArg(Const AName:String;Const AArg:Variant;
      Const AOnFinish:TArgCleanupNestedCallback):IEZThread;overload;
    function AddArg(Const AName:String;Const AArg:Variant):IEZThread;overload;

    (*
      add several arguments at one time, note that this doesn't offer
      a cleanup method, so if an argument requires one, utilize the single
      add method
    *)
    function AddArgs(Const ANames:TStringArray;
      Const AArgs:TVariantArray):IEZThread;

    (*
      sets up the thread with methods to run for starting/error/success
    *)
    function Setup(Const AStart:TThreadCallback;
      Const AError:TThreadCallback;Const ASuccess:TThreadCallback):IEZThread;overload;
    function Setup(Const AStart:TThreadCallback):IEZThread;overload;

    function Setup(Const AStart:TThreadNestedCallback;
      Const AError:TThreadNestedCallback;Const ASuccess:TThreadNestedCallback):IEZThread;overload;
    function Setup(Const AStart:TThreadNestedCallback):IEZThread;overload;

    function Setup(Const AStart:TThreadMethod;
      Const AError:TThreadMethod;Const ASuccess:TThreadMethod):IEZThread;overload;
    function Setup(Const AStart:TThreadMethod):IEZThread;overload;

    (*
      starts the thread
    *)
    procedure Start;

    (*
      stops thread if started
    *)
    procedure Stop;
  end;

  { TEZArg }
  (*
    simple structure to hold argument data and callback methods
  *)
  TEZArg = packed record
  private
    FCallback: TArgCleanupCallback;
    FData: Variant;
    FMethod: TArgCleanupMethod;
    FName: String;
    FNestCallback: TArgCleanupNestedCallback;
  public
    property Name : String read FName;
    property Data : Variant read FData;
    property Callback : TArgCleanupCallback read FCallback;
    property NestedCallback : TArgCleanupNestedCallback read FNestCallback;
    property Method : TArgCleanupMethod read FMethod;
    constructor Create(Const AName:String;Const AData:Variant;
      Const ACallback:TArgCleanupCallback;Const ANestedCallback:TArgCleanupNestedCallback;
      Const AMethod:TArgCleanupMethod);
  end;

  (*
    array of arguments
  *)
  TEZArgs = array of TEZArg;

  { TEZThreadImpl }
  (*
    base implementation of an IEZThread, also realizes settings and events
    to keep things together
  *)
  TEZThreadImpl = class(
    TInterfacedObject,
    IEZThreadEvents,
    IEZThreadSettings,
    IEZThread
  )
  strict private
    FMaxRunTime: Cardinal;
    FOnStart,
    FOnStop: TThreadMethod;
    FOnStartCall,
    FOnStopCall: TThreadCallback;
    FOnStartNestCall,
    FOnStopNestCall: TThreadNestedCallback;
    FArgs: TEZArgs;
    function GetByName(const AName: String): Variant;
    function GetExists(const AName: String): Boolean;
    function GetMaxRunTime: Cardinal;
    function GetOnStart: TThreadMethod;
    function GetOnStartCall: TThreadCallback;
    function GetOnStartNestCall: TThreadNestedCallback;
    function GetOnStop: TThreadMethod;
    function GetOnStopCall: TThreadCallback;
    function GetOnStopNestCall: TThreadNestedCallback;
    function GetThread: IEZThread;
    function GetSettings: IEZThreadSettings;
    function GetEvents: IEZThreadEvents;
    function IndexOfArg(Const AName:String):Integer;
  strict protected
  public
    //events
    property OnStart : TThreadMethod read GetOnStart;
    property OnStartCallback : TThreadCallback read GetOnStartCall;
    property OnStartNestedCallback : TThreadNestedCallback read GetOnStartNestCall;
    property OnStop : TThreadMethod read GetOnStop;
    property OnStopCallback : TThreadCallback read GetOnStopCall;
    property OnStopNestedCallback : TThreadNestedCallback read GetOnStopNestCall;
  public
    //properties
    property MaxRuntime : Cardinal read GetMaxRunTime;
    property Thread : IEZThread read GetThread;
    property Settings:IEZThreadSettings read GetSettings;
    property Events:IEZThreadEvents read GetEvents;
    property Exists[Const AName:String]:Boolean read GetExists;
    property ByName[Const AName:String]:Variant read GetByName;default;

    //methods
    function UpdateOnStart(Const AOnStart:TThreadMethod):IEZThreadEvents;
    function UpdateOnStartCallback(Const AOnStart:TThreadCallback):IEZThreadEvents;
    function UpdateOnStartNestedCallback(Const AOnStart:TThreadNestedCallback):IEZThreadEvents;
    function UpdateOnStop(Const AOnStop:TThreadMethod):IEZThreadEvents;
    function UpdateOnStopCallback(Const AOnStop:TThreadCallback):IEZThreadEvents;
    function UpdateOnStopNestedCallback(Const AOnStop:TThreadNestedCallback):IEZThreadEvents;
    function UpdateMaxRuntime(Const ARuntime:Cardinal):IEZThreadSettings;
    function AddArg(Const AName:String;Const AArg:Variant;
      Const AOnFinish:TArgCleanupMethod;
      Const AOnFinishCall:TArgCleanupCallback;
      Const AOnFinishNestedCall:TArgCleanupNestedCallback):IEZThread;overload;
    function AddArg(Const AName:String;Const AArg:Variant;
      Const AOnFinish:TArgCleanupCallback):IEZThread;overload;
    function AddArg(Const AName:String;Const AArg:Variant;
      Const AOnFinish:TArgCleanupNestedCallback):IEZThread;overload;
    function AddArg(Const AName:String;Const AArg:Variant;
      Const AOnFinish:TArgCleanupMethod):IEZThread;overload;
    function AddArg(Const AName:String;Const AArg:Variant):IEZThread;overload;
    function AddArgs(Const ANames:TStringArray;
      Const AArgs:TVariantArray):IEZThread;
    function Setup(Const AStart:TThreadCallback;
      Const AError:TThreadCallback;Const ASuccess:TThreadCallback):IEZThread;overload;
    function Setup(Const AStart:TThreadCallback):IEZThread;overload;
    function Setup(Const AStart:TThreadNestedCallback;
      Const AError:TThreadNestedCallback;Const ASuccess:TThreadNestedCallback):IEZThread;overload;
    function Setup(Const AStart:TThreadNestedCallback):IEZThread;overload;
    function Setup(Const AStart:TThreadMethod;
      Const AError:TThreadMethod;Const ASuccess:TThreadMethod):IEZThread;overload;
    function Setup(Const AStart:TThreadMethod):IEZThread;overload;
    procedure Start;
    procedure Stop;
    constructor Create;virtual;
  end;

implementation
uses
  syncobjs;
var
  Critical : TCriticalSection;
{ TEZThreadImpl }

function TEZThreadImpl.GetMaxRunTime: Cardinal;
begin
  Result:=FMaxRunTime;
end;

function TEZThreadImpl.GetExists(const AName: String): Boolean;
var
  I:Integer;
begin
  I:=IndexOfArg(AName);
  Result:=I >= 0;
end;

function TEZThreadImpl.GetByName(const AName: String): Variant;
begin
  if Exists[AName] then
    Result:=FArgs[IndexOfArg(AName)].Data
  else
    Result:=nil;
end;

function TEZThreadImpl.GetOnStart: TThreadMethod;
begin
  Result:=FOnStart;
end;

function TEZThreadImpl.GetOnStartCall: TThreadCallback;
begin
  Result:=FOnStartCall;
end;

function TEZThreadImpl.GetOnStartNestCall: TThreadNestedCallback;
begin
  Result:=FOnStartNestCall;
end;

function TEZThreadImpl.GetOnStop: TThreadMethod;
begin
  Result:=FOnStop;
end;

function TEZThreadImpl.GetOnStopCall: TThreadCallback;
begin
  Result:=FOnStopCall;
end;

function TEZThreadImpl.GetOnStopNestCall: TThreadNestedCallback;
begin
  Result:=FOnStopNestCall;
end;

function TEZThreadImpl.GetThread: IEZThread;
begin
  Result:=Self as IEZThread;
end;

function TEZThreadImpl.GetSettings: IEZThreadSettings;
begin
  Result:=Self as IEZThreadSettings;
end;

function TEZThreadImpl.GetEvents: IEZThreadEvents;
begin
  Result:=Self as IEZThreadEvents;
end;

function TEZThreadImpl.IndexOfArg(const AName: String): Integer;
var
  I:Integer;
begin
  Result:=-1;
  Critical.Enter;
  try
    for I:=0 to High(FArgs) do
      if FArgs[I].Name=AName then
      begin
        Result:=I;
        Exit;
      end;
  finally
    Critical.Leave;
  end;
end;

function TEZThreadImpl.UpdateOnStart(const AOnStart: TThreadMethod): IEZThreadEvents;
begin
  FOnStart:=AOnStart;
  Result:=GetEvents;
end;

function TEZThreadImpl.UpdateOnStartCallback(const AOnStart: TThreadCallback): IEZThreadEvents;
begin
  FOnStartCall:=AOnStart;
  Result:=GetEvents;
end;

function TEZThreadImpl.UpdateOnStartNestedCallback(
  const AOnStart: TThreadNestedCallback): IEZThreadEvents;
begin
  FOnStartNestCall:=AOnStart;
  Result:=GetEvents;
end;

function TEZThreadImpl.UpdateOnStop(const AOnStop: TThreadMethod): IEZThreadEvents;
begin
  FOnStop:=AOnStop;
  Result:=GetEvents;
end;

function TEZThreadImpl.UpdateOnStopCallback(const AOnStop: TThreadCallback): IEZThreadEvents;
begin
  FOnStopCall:=AOnStop;
  Result:=GetEvents;
end;

function TEZThreadImpl.UpdateOnStopNestedCallback(
  const AOnStop: TThreadNestedCallback): IEZThreadEvents;
begin
  FOnStopNestCall:=AOnStop;
  Result:=GetEvents;
end;

function TEZThreadImpl.UpdateMaxRuntime(const ARuntime: Cardinal): IEZThreadSettings;
begin
  FMaxRunTime:=ARunTime;
  Result:=GetSettings;
end;

function TEZThreadImpl.AddArg(const AName: String; const AArg: Variant;
  const AOnFinish: TArgCleanupMethod; const AOnFinishCall: TArgCleanupCallback;
  const AOnFinishNestedCall: TArgCleanupNestedCallback): IEZThread;
var
  I:Integer;
  LArg:TEZArg;
begin
  //see if this arg already exists by fetching the index
  I:=IndexOfArg(AName);

  //regardless of existing, we are either going to perform and
  //update or create, so create the argument with the params
  LArg:=TEZArg.Create(AName,AArg,AOnFinishCall,AOnFinishNestedCall,AOnFinish);

  //enter critical section to avoid collisions
  Critical.Enter;
  try
    //we need to add a new arg
    if I < 0 then
    begin
      SetLength(FArgs,Succ(Length(FArgs)));
      FArgs[High(FArgs)]:=LArg;
    end
    //update existing arg
    else
    begin
      //in the case of an update we need to make sure any cleanup methods
      //get called if specified
      try
        if Assigned(FArgs[I].Callback) then
          FArgs[I].Callback(FArgs[I].Data);
        if Assigned(FArgs[I].Method) then
          FArgs[I].Method(FArgs[I].Data);
      finally
      end;

      //rewrite the arg
      FArgs[I]:=LArg;
    end;
  finally
    Critical.Leave;
  end;

  //lastly return the thread
  Result:=GetThread;
end;

function TEZThreadImpl.AddArg(const AName: String; const AArg: Variant;
  const AOnFinish: TArgCleanupCallback): IEZThread;
begin
  Result:=AddArg(AName,AArg,nil,AOnFinish,nil);
end;

function TEZThreadImpl.AddArg(const AName: String; const AArg: Variant;
  const AOnFinish: TArgCleanupNestedCallback): IEZThread;
begin
  Result:=AddArg(AName,AArg,nil,nil,AOnFinish);
end;

function TEZThreadImpl.AddArg(const AName: String; const AArg: Variant;
  const AOnFinish: TArgCleanupMethod): IEZThread;
begin
  Result:=AddArg(AName,AArg,AOnFinish,nil,nil);
end;

function TEZThreadImpl.AddArg(const AName: String; const AArg: Variant): IEZThread;
begin
  Result:=AddArg(AName,AArg,nil,nil,nil);
end;

function TEZThreadImpl.AddArgs(const ANames: TStringArray;
  const AArgs: TVariantArray): IEZThread;
var
  I:Integer;
begin
  //assumes arrays are equal
  for I:=0 to High(AArgs) do
    AddArg(ANames[I],AArgs[I]);
  Result:=GetThread;
end;

function TEZThreadImpl.Setup(const AStart: TThreadCallback;
  const AError: TThreadCallback; const ASuccess: TThreadCallback): IEZThread;
begin
  //todo
  Result:=GetThread;
end;

function TEZThreadImpl.Setup(const AStart: TThreadCallback): IEZThread;
begin
  Result:=Setup(AStart,TThreadCallback(nil),TThreadCallback(nil));
end;

function TEZThreadImpl.Setup(const AStart: TThreadNestedCallback;
  const AError: TThreadNestedCallback; const ASuccess: TThreadNestedCallback): IEZThread;
begin
  //todo
  Result:=GetThread;
end;

function TEZThreadImpl.Setup(const AStart: TThreadNestedCallback): IEZThread;
begin
  Result:=Setup(AStart,nil,nil);
end;

function TEZThreadImpl.Setup(const AStart: TThreadMethod;
  const AError: TThreadMethod; const ASuccess: TThreadMethod): IEZThread;
begin
  //todo
  Result:=GetThread;
end;

function TEZThreadImpl.Setup(const AStart: TThreadMethod): IEZThread;
begin
  Result:=Setup(AStart,TThreadMethod(nil),TThreadMethod(nil));
end;

procedure TEZThreadImpl.Start;
begin
  //todo
end;

procedure TEZThreadImpl.Stop;
begin
  //todo
end;

constructor TEZThreadImpl.Create;
begin
  FMaxRunTime:=0;
  FOnStart:=nil;
  FOnStop:=nil;
  FOnStartCall:=nil;
  FOnStopCall:=nil;
  SetLength(FArgs,0);
end;

{ TEZArg }

constructor TEZArg.Create(Const AName:String;Const AData:Variant;
  Const ACallback:TArgCleanupCallback;Const ANestedCallback:TArgCleanupNestedCallback;
  Const AMethod:TArgCleanupMethod);
begin
  FName:=AName;
  FData:=AData;
  FMethod:=AMethod;
  FCallback:=ACallback;
  FNestCallback:=ANestedCallback;
end;

initialization
  Critical:=TCriticalSection.Create;
finalization
  if Assigned(Critical) then
    Critical.Free;
end.

