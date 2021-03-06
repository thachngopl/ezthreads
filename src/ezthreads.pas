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
  Classes, SysUtils, variants, fgl;

type

  //forward
  IEZThread = interface;
  IEZThreadSettings = interface;

  TEZState = (
    esStopped,
    esStarted
  );

  TEZStates = set of TEZState;

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

  { IEZAwait }
  (*
    settings pertaining to await groups
  *)
  IEZAwait = interface
    ['{37AEEC70-FBB9-44FC-94FC-B27E03977D4C}']
    //property methods
    function GetGroupID: String;
    function GetSettings: IEZThreadSettings;
    function GetThread: IEZThread;
    function GetThreadID: String;

    //properties
    (*
      current group id for this thread
    *)
    property GroupID : String read GetGroupID;

    (*
      current thread id for this thread
    *)
    property ThreadID : String read GetThreadID;
    property Settings : IEZThreadSettings read GetSettings;
    property Thread : IEZThread read GetThread;

    //methods
    (*
      will group this thread to another thread
    *)
    function Group(Const AThread:IEZThread):IEZAwait;

    (*
      will group this thread to a new group id, provided the id
    *)
    function UpdateGroupID(Const AGroupID:String):IEZAwait;
  end;

  { IEZThreadSettings }
  (*
    settings for an ezthread that deal with the operation of the thread
  *)
  IEZThreadSettings = interface
    ['{1EE5C618-DA56-4101-BE75-1FD25F131ED2}']
    function GetAwait: IEZAwait;
    //property methods
    function GetMaxRunTime: Cardinal;
    function GetSynchStopEvents: Boolean;
    function GetThread: IEZThread;
    function GetForceTerminate: Boolean;

    //properties
    (*
      maximum time a method is allowed to run without being aborted
    *)
    property MaxRuntime : Cardinal read GetMaxRunTime;

    (*
      if maximum time is met, and this setting is true, the
      thread will be forcefully terminated, otherwise stop
      events will be triggered and the background thread will continue
      processing until it can check if it has been terminated
    *)
    property ForceTerminate : Boolean read GetForceTerminate;

    (*
      when true, stop events are wrapped in a synchronize call
    *)
    property SynchronizeStopEvents : Boolean read GetSynchStopEvents;

    property Await : IEZAwait read GetAwait;

    (*
      parent thread these settings belong to
    *)
    property Thread : IEZThread read GetThread;

    //methods
    function UpdateMaxRuntime(Const ARuntime:Cardinal):IEZThreadSettings;
    function UpdateForceTerminate(Const AForce:Boolean):IEZThreadSettings;
    function UpdateSynchronizeStopEvents(Const ASynch:Boolean):IEZThreadSettings;
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
    function GetState: TEZState;

    //properties
    property Settings:IEZThreadSettings read GetSettings;
    property Events:IEZThreadEvents read GetEvents;
    property Exists[Const AName:String]:Boolean read GetExists;
    property ByName[Const AName:String]:Variant read GetByName;default;
    property State:TEZState read GetState;

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
  PEZArgs = ^TEZArgs;

  { TEZThreadImpl }
  (*
    base implementation of an IEZThread, also realizes settings and events
    to keep things together
  *)
  TEZThreadImpl = class(
    TInterfacedObject,
    IEZThreadEvents,
    IEZThreadSettings,
    IEZAwait,
    IEZThread
  )
  strict protected
    type

      { TInternalThread }
      (*
        actual thread used in a TEZThreadImpl
      *)
      TInternalThread = class(TThread)
      strict private
        FError: TThreadMethod;
        FErrorCall: TThreadCallback;
        FErrorNestCall: TThreadNestedCallback;
        FStart: TThreadMethod;
        FStartCall: TThreadCallback;
        FStartNestCall: TThreadNestedCallback;
        FSuccess: TThreadMethod;
        FSuccessCall: TThreadCallback;
        FSuccessNestCall: TThreadNestedCallback;
        FThread: IEZThread;
        FCaller: TThread;
        function GetThread: IEZThread;
        procedure SetThread(Const AValue: IEZThread);
      strict protected
        type

          { TEventHelper }
          (*
            holds a refernce to ezthread
          *)
          TEventHelper = class
          strict private
            FCaller: TThread;
            FThread: IEZThread;
            procedure SetThread(Const AValue: IEZThread);
          strict protected
            procedure DoSynchMethod;virtual;abstract;
          public
            property Thread : IEZThread read FThread write SetThread;
            property Caller : TThread read FCaller write FCaller;
            procedure SynchMethod;
            constructor Create(Const AThread:IEZThread;
              Const ACaller:TThread);virtual;overload;
            destructor Destroy; override;
          end;

          { TObjHelper }
          (*
            helper specializing in calling object thread methods
          *)
          TObjHelper = class(TEventHelper)
          strict private
            FMethod: TThreadMethod;
          strict protected
            procedure DoSynchMethod; override;
          public
            property Method : TThreadMethod read FMethod write FMethod;
            constructor Create(const AThread: IEZThread;Const ACaller:TThread;
              Const AMethod:TThreadMethod);overload;
          end;

          { TCallHelper }
          (*
            helper specializing in calling callback thread methods
          *)
          TCallHelper = class(TEventHelper)
          strict private
            FCallback: TThreadCallback;
          strict protected
            procedure DoSynchMethod; override;
          public
            property Callback : TThreadCallback read FCallback write FCallback;
            constructor Create(const AThread: IEZThread;Const ACaller:TThread;
              Const ACallback:TThreadCallback);overload;
          end;

          { TNestCallHelper }
          (*
            helper specializing in calling nested callback thread methods
          *)
          TNestCallHelper = class(TEventHelper)
          strict private
            FNestCallback: TThreadNestedCallback;
          strict protected
            procedure DoSynchMethod; override;
          public
            property NestedCallback : TThreadNestedCallback read FNestCallback write FNestCallback;
            constructor Create(const AThread: IEZThread;Const ACaller:TThread;
              Const ANestCallback:TThreadNestedCallback); overload;
          end;
      protected
        procedure Execute; override;
      public
        (*
          reference to parent ezthread
        *)
        property EZThread : IEZThread read GetThread write SetThread;
        property Caller : TThread read FCaller write FCaller;

        (*
          all possible requested methods to run during Execute
        *)
        property StartMethod : TThreadMethod read FStart write FStart;
        property StartCallback : TThreadCallback read FStartCall write FStartCall;
        property StartNestedCallback : TThreadNestedCallback read FStartNestCall write FStartNestCall;

        property ErrorMethod : TThreadMethod read FError write FError;
        property ErrorCallback : TThreadCallback read FErrorCall write FErrorCall;
        property ErrorNestedCallback : TThreadNestedCallback read FErrorNestCall write FErrorNestCall;

        property Success : TThreadMethod read FSuccess write FSuccess;
        property SuccessCallback : TThreadCallback read FSuccessCall write FSuccessCall;
        property SuccessNestedCallback : TThreadNestedCallback read FSuccessNestCall write FSuccessNestCall;

        procedure RaiseStopEvents;
        destructor Destroy; override;
      end;

      (*
        meta class for internal thread
      *)
      TInternalThreadClass = class of TInternalThread;
  strict private
    type
      TMonitorThread = class;
      TMonitorList = TFPGMapObject<String,TMonitorThread>;

      { TMonitorThread }
      (*
        monitors the internal worker thread when caller specifies
        a timeout or stop has been called
      *)
      TMonitorThread = class(TThread)
      public
        type
          TOnDone = procedure(AThread:IEZThread) of object;
      strict private
        FID: String;
        FList: TMonitorList;
        FOnDone: TOnDone;
        FThread: TInternalThread;
        FStopRequest: Boolean;
        FKilled: Boolean;
      protected
        procedure Execute; override;
        procedure DoOnDone(AThread:IEZThread);
      public
        property OnDone : TOnDone read FOnDone write FOnDone;
        property InternalThread : TInternalThread read FThread write FThread;
        property ID : String read FID write FID;
        property List : TMonitorList read FList write FList;
        procedure StopMonitor;
        destructor Destroy; override;
      end;
  strict private
    FMaxRunTime: Cardinal;
    FStart,
    FError,
    FSuccess,
    FOnStart,
    FOnStop: TThreadMethod;
    FStartCall,
    FErrorCall,
    FSuccessCall,
    FOnStartCall,
    FOnStopCall: TThreadCallback;
    FStartNestCall,
    FErrorNestCall,
    FSuccessNestCall,
    FOnStartNestCall,
    FOnStopNestCall: TThreadNestedCallback;
    FArgs: TEZArgs;
    FMonitorThreads: TMonitorList;
    FSynchStopEvents,
    FForceTerminate: Boolean;
    FThreadID,
    FGroupID: String;
    FState: TEZState;
    function GetAwait: IEZAwait;
    function GetByName(const AName: String): Variant;
    function GetExists(const AName: String): Boolean;
    function GetForceTerminate: Boolean;
    function GetGroupID: String;
    function GetMaxRunTime: Cardinal;
    function GetOnStart: TThreadMethod;
    function GetOnStartCall: TThreadCallback;
    function GetOnStartNestCall: TThreadNestedCallback;
    function GetOnStop: TThreadMethod;
    function GetOnStopCall: TThreadCallback;
    function GetOnStopNestCall: TThreadNestedCallback;
    function GetState: TEZState;
    function GetSynchStopEvents: Boolean;
    function GetThread: IEZThread;
    function GetSettings: IEZThreadSettings;
    function GetEvents: IEZThreadEvents;
    function GetThreadID: String;
    function IndexOfArg(Const AName:String):Integer;
    procedure UpdateState(AThread:IEZThread);
  strict protected
    (*
      method can be overridden to instantiate a child internal thread
      instead of the base internal thread
    *)
    function DoGetThreadClass : TInternalThreadClass;virtual;
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
    property SynchronizeStopEvents : Boolean read GetSynchStopEvents;
    property ForceTerminate : Boolean read GetForceTerminate;
    property GroupID : String read GetGroupID;
    property ThreadID : String read GetThreadID;

    property Thread : IEZThread read GetThread;
    property Settings:IEZThreadSettings read GetSettings;
    property Await : IEZAwait read GetAwait;
    property Events:IEZThreadEvents read GetEvents;
    property Exists[Const AName:String]:Boolean read GetExists;
    property ByName[Const AName:String]:Variant read GetByName;default;
    property State:TEZState read GetState;

    //methods
    function UpdateOnStart(Const AOnStart:TThreadMethod):IEZThreadEvents;
    function UpdateOnStartCallback(Const AOnStart:TThreadCallback):IEZThreadEvents;
    function UpdateOnStartNestedCallback(Const AOnStart:TThreadNestedCallback):IEZThreadEvents;
    function UpdateOnStop(Const AOnStop:TThreadMethod):IEZThreadEvents;
    function UpdateOnStopCallback(Const AOnStop:TThreadCallback):IEZThreadEvents;
    function UpdateOnStopNestedCallback(Const AOnStop:TThreadNestedCallback):IEZThreadEvents;
    function UpdateMaxRuntime(Const ARuntime:Cardinal):IEZThreadSettings;
    function UpdateForceTerminate(Const AForce:Boolean):IEZThreadSettings;
    function UpdateSynchronizeStopEvents(Const ASynch:Boolean):IEZThreadSettings;
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
    function Group(Const AThread:IEZThread):IEZAwait;
    function UpdateGroupID(Const AGroupID:String):IEZAwait;
    procedure Start;
    procedure Stop;
    constructor Create;virtual;
    destructor Destroy; override;
  end;

  (*
    meta class for TEZThreadImpl
  *)
  TEZThreadImplClass = class of TEZThreadImpl;

  (*
    awaits *all* thread groups running at the time of calling
  *)
  procedure Await(Const ASleep:Cardinal=10);overload;

  (*
    awaits a particular thread
  *)
  procedure Await(Const AThread:IEZThread;Const ASleep:Cardinal=10);overload;

  (*
    awaits a particular thread group
  *)
  procedure Await(Const AGroupID:String;Const ASleep:Cardinal=10);overload;


implementation
uses
  syncobjs, ezthreads.collection;
var
  Critical : TCriticalSection;
  Collection : IEZCollection;

procedure Await(Const ASleep:Cardinal=10);
var
  I:Integer;
  LGroups:TStringArray;
begin
  //fetch the current thread groups
  LGroups:=Collection.ThreadGroups;

  //call await for each group id
  for I:=0 to High(LGroups) do
    Await(LGroups[I],ASleep);
end;

procedure Await(const AThread: IEZThread;Const ASleep:Cardinal=10);
begin
  //use thread id here to check against non-nil result
  while Collection.Threads[AThread.Settings.Await.ThreadID] <> nil do
    Sleep(ASleep);
end;

procedure Await(const AGroupID: String;Const ASleep:Cardinal);
begin
  //threads add and remove themselves from the collection, so
  while Collection.Exists(AGroupID) do
    Sleep(ASleep)
end;

{ TEZThreadImpl.TInternalThread.TNestCallHelper }

procedure TEZThreadImpl.TInternalThread.TNestCallHelper.DoSynchMethod;
begin
  try
    if Assigned(FNestCallback) then
      FNestCallback(Thread);
  finally
    Free;
  end;
end;

constructor TEZThreadImpl.TInternalThread.TNestCallHelper.Create(
  const AThread: IEZThread;Const ACaller:TThread; const ANestCallback: TThreadNestedCallback);
begin
  inherited Create(AThread,ACaller);
  FNestCallback:=ANestCallback;
end;

{ TEZThreadImpl.TInternalThread.TCallHelper }

procedure TEZThreadImpl.TInternalThread.TCallHelper.DoSynchMethod;
begin
  try
    if Assigned(FCallback) then
      FCallback(Thread);
  finally
    Free;
  end;
end;

constructor TEZThreadImpl.TInternalThread.TCallHelper.Create(
  const AThread: IEZThread;Const ACaller:TThread; const ACallback: TThreadCallback);
begin
  inherited Create(AThread,ACaller);
  FCallback:=ACallback;
end;

{ TEZThreadImpl.TInternalThread.TObjHelper }

procedure TEZThreadImpl.TInternalThread.TObjHelper.DoSynchMethod;
begin
  try
    if Assigned(FMethod) then
      FMethod(Thread);
  finally
    Free;
  end;
end;

constructor TEZThreadImpl.TInternalThread.TObjHelper.Create(
  const AThread: IEZThread;Const ACaller:TThread; const AMethod: TThreadMethod);
begin
  inherited Create(AThread,ACaller);
  FMethod:=AMethod;
end;

{ TEZThreadImpl.TInternalThread.TEventHelper }

procedure TEZThreadImpl.TInternalThread.TEventHelper.SetThread(
  const AValue: IEZThread);
begin
  FThread:=nil;
  FThread:=AValue;
end;

procedure TEZThreadImpl.TInternalThread.TEventHelper.SynchMethod;
begin
  //console apps should not use this, since we are based on TThread class
  TThread.Synchronize(Caller,DoSynchMethod);
end;

constructor TEZThreadImpl.TInternalThread.TEventHelper.Create(
  const AThread: IEZThread;Const ACaller:TThread);
begin
  Thread:=AThread;
  FCaller:=ACaller;
end;

destructor TEZThreadImpl.TInternalThread.TEventHelper.Destroy;
begin
  FThread:=nil;
  inherited Destroy;
end;

{ TEZThreadImpl.TMonitorThread }

procedure TEZThreadImpl.TMonitorThread.Execute;
var
  LElapsed,
  LSleep,
  LMax:Cardinal;
  LForceKill:Boolean;
  LThread:IEZThread;

  (*
    safely removes a monitor thread by id from a monitor list
  *)
  procedure RemoveID(Const AID:String;Const AList:TMonitorList);
  begin
    Critical.Enter;
    try
      //remove ourselves from the list
      if AList.IndexOf(AID) < 0 then
        Exit;
      AList.Remove(AID);
    finally
      Critical.Leave;
    end;
  end;
begin
  try
    FStopRequest:=False;
    FKilled:=False;
    LElapsed:=0;
    LMax:=FThread.EZThread.Settings.MaxRuntime;
    LForceKill:=FThread.EZThread.Settings.ForceTerminate;
    LThread:=FThread.EZThread;

    //if we're finished, nothing to do
    if FThread.Finished then
    begin
      DoOnDone(LThread);
      RemoveID(FID,FList);
      Exit;
    end;

    //we only care if the maximum has been specified, otherwise this thread
    //can run until the end of time
    if LMax > 0 then
    begin
      try
        LSleep:=LMax div 10;
        while LElapsed < LMax do
        begin
          Sleep(LSleep);
          Inc(LElapsed,LSleep);
          if FThread.Finished then
            Exit;
        end;

        //if we get here, then the thread has passed the alotted max, so forcefull
        //terminate it
        if not FThread.Finished then
          FThread.Terminate;

        //since we terminated, caller will still expect
        //for their events to occur
        FThread.RaiseStopEvents;

        //if settings say we should forcefull terminate, do so but
        //be warned, this may cause problems...
        //here we check one last time for finished to make sure to avoid if possible
        if (not FThread.Finished)
          and (LForceKill)
        then
        begin
          DoOnDone(LThread);
          KillThread(FThread.Handle);
          FKilled:=True;
        end;
      finally
        RemoveID(FID,FList);
      end;
    end
    //otherwise just wait until a stop request is made
    else
    begin
      try
        while not FStopRequest
          and (Assigned(FThread) and (not FThread.Finished))do
        begin
          if not Assigned(FThread) then
            Exit;
          if FThread.Finished then
            Exit;
          Sleep(10);
        end;
      finally
        DoOnDone(LThread);
      end;
    end;
  finally
    RemoveID(FID,FList);
  end;
end;

procedure TEZThreadImpl.TMonitorThread.DoOnDone(AThread: IEZThread);
begin
  if Assigned(FOnDone) then
    FOnDone(AThread);
end;

procedure TEZThreadImpl.TMonitorThread.StopMonitor;
begin
  FStopRequest:=True;
end;

destructor TEZThreadImpl.TMonitorThread.Destroy;
begin
  if Assigned(FThread) and (not FKilled) then
    FThread.Free;
  inherited Destroy;
end;

{ TEZThreadImpl.TInternalThread }

function TEZThreadImpl.TInternalThread.GetThread: IEZThread;
begin
  Result:=FThread;
end;

procedure TEZThreadImpl.TInternalThread.SetThread(const AValue: IEZThread);
begin
  FThread:=nil;
  FThread:=AValue;
end;

procedure TEZThreadImpl.TInternalThread.Execute;
begin
  if Assigned(FThread) then
  begin
    try
      //attempt to run all applicable StartMethod methods
      if Assigned(FStart) then
      begin
        FStart(FThread);
        if Terminated then
          Exit;
      end;
      if Assigned(FStartCall) then
      begin
        FStartCall(FThread);
        if Terminated then
          Exit;
      end;
      if Assigned(FStartNestCall) then
      begin
        FStartNestCall(FThread);
        if Terminated then
          Exit;
      end;

      //now run success methods
      if Assigned(FSuccess) then
      begin
        FSuccess(FThread);
        if Terminated then
          Exit;
      end;
      if Assigned(FSuccessCall) then
      begin
        FSuccessCall(FThread);
        if Terminated then
          Exit;
      end;
      if Assigned(FSuccessNestCall) then
      begin
        FSuccessNestCall(FThread);
        if Terminated then
          Exit;
      end;

      if not Terminated then
        RaiseStopEvents;
    except on E:Exception do
    begin
      //todo - expand the ErrorMethod methods to accept either a TException or
      //just an ErrorMethod message string

      //guarantee all ErrorMethod methods are called with try..finally
      if Assigned(FError) then
        try
          FError(FThread);
        finally
        end;
      if Assigned(FErrorCall) then
        try
          FErrorCall(FThread);
        finally
        end;
      if Assigned(FErrorNestCall) then
        try
          FErrorNestCall(FThread);
        finally
        end;
      try
        if not Terminated then
          RaiseStopEvents;
      finally
      end;
    end
    end;
  end;
end;

procedure TEZThreadImpl.TInternalThread.RaiseStopEvents;
begin
  //below we use the appropriate synch helper object to handle the
  //method. these objects free themselves once done
  if FThread.Settings.SynchronizeStopEvents then
  begin
    if Assigned(FThread.Events.OnStop) then
      TObjHelper.Create(FThread,FCaller,FThread.Events.OnStop).SynchMethod;
    if Assigned(FThread.Events.OnStopCallback) then
      TCallHelper.Create(FThread,FCaller,FThread.Events.OnStopCallback).SynchMethod;
    if Assigned(FThread.Events.OnStopNestedCallback) then
      TNestCallHelper.Create(FThread,FCaller,FThread.Events.OnStopNestedCallback).SynchMethod;
  end
  //otherwise caller does not want the stop events to be raised (perhaps
  //they are in a console app? https://forum.lazarus.freepascal.org/index.php?topic=23442.0)
  else
  begin
    if Assigned(FThread.Events.OnStop) then
      FThread.Events.OnStop(FThread);
    if Assigned(FThread.Events.OnStopCallback) then
      FThread.Events.OnStopCallback(FThread);
    if Assigned(FThread.Events.OnStopNestedCallback) then
      FThread.Events.OnStopNestedCallback(FThread);
  end;
end;

destructor TEZThreadImpl.TInternalThread.Destroy;
begin
  FThread:=nil;
  inherited Destroy;
end;

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

function TEZThreadImpl.GetForceTerminate: Boolean;
begin
  Result:=FForceTerminate;
end;

function TEZThreadImpl.GetGroupID: String;
begin
  Result:=FGroupID;
end;

function TEZThreadImpl.GetByName(const AName: String): Variant;
begin
  if Exists[AName] then
    Result:=FArgs[IndexOfArg(AName)].Data
  else
    Result:=nil;
end;

function TEZThreadImpl.GetAwait: IEZAwait;
begin
  Result:=Self as IEZAwait;
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

function TEZThreadImpl.GetState: TEZState;
begin
  Result:=FState;
end;

function TEZThreadImpl.GetSynchStopEvents: Boolean;
begin
  Result:=FSynchStopEvents;
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

function TEZThreadImpl.GetThreadID: String;
begin
  Result:=FThreadID;
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

procedure TEZThreadImpl.UpdateState(AThread:IEZThread);
begin
  //on done gets called before monitor thread removes itself from list,
  //so count of 1 actually means we'll be stopped
  Critical.Enter;
  try
    if FMonitorThreads.Count <= 1 then
    begin
      FState:=esStopped;

      //once stopped, remove this thread from the collection
      Collection.Remove(AThread);
    end;
  finally
    Critical.Leave;
  end;
end;

function TEZThreadImpl.DoGetThreadClass: TInternalThreadClass;
begin
  //base class returns base internal thread class
  Result:=TInternalThread;
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

function TEZThreadImpl.UpdateForceTerminate(const AForce: Boolean): IEZThreadSettings;
begin
  FForceTerminate:=AForce;
  Result:=GetSettings;
end;

function TEZThreadImpl.UpdateSynchronizeStopEvents(const ASynch: Boolean): IEZThreadSettings;
begin
  FSynchStopEvents:=ASynch;
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
  FStartCall:=AStart;
  FErrorCall:=AError;
  FSuccessCall:=ASuccess;
  Result:=GetThread;
end;

function TEZThreadImpl.Setup(const AStart: TThreadCallback): IEZThread;
begin
  Result:=Setup(AStart,nil,nil);
end;

function TEZThreadImpl.Setup(const AStart: TThreadNestedCallback;
  const AError: TThreadNestedCallback; const ASuccess: TThreadNestedCallback): IEZThread;
begin
  FStartNestCall:=AStart;
  FErrorNestCall:=AError;
  FSuccessNestCall:=ASuccess;
  Result:=GetThread;
end;

function TEZThreadImpl.Setup(const AStart: TThreadNestedCallback): IEZThread;
begin
  Result:=Setup(AStart,nil,nil);
end;

function TEZThreadImpl.Setup(const AStart: TThreadMethod;
  const AError: TThreadMethod; const ASuccess: TThreadMethod): IEZThread;
begin
  FStart:=AStart;
  FError:=AError;
  FSuccess:=ASuccess;
  Result:=GetThread;
end;

function TEZThreadImpl.Setup(const AStart: TThreadMethod): IEZThread;
begin
  Result:=Setup(AStart,nil,nil);
end;

function TEZThreadImpl.Group(const AThread: IEZThread): IEZAwait;
begin
  Result:=nil;
  UpdateGroupID(AThread.Settings.Await.GroupID);
  Result:=GetAwait;
end;

function TEZThreadImpl.UpdateGroupID(const AGroupID: String): IEZAwait;
begin
  Result:=nil;
  if FState = esStarted then
    raise Exception.Create('group id cannot be changed while thread is started');
  FGroupID:=AGroupID;
  Result:=GetAwait;
end;

procedure TEZThreadImpl.Start;
var
  LIntThread:TInternalThread;
  LMonThread:TMonitorThread;
  LThread:IEZThread;
begin
  //raise on start events
  if Assigned(FOnStart) then
    FOnStart(GetThread);
  if Assigned(FOnStartCall) then
    FOnStartCall(GetThread);
  if Assigned(FOnStartNestCall) then
    FOnStartNestCall(GetThread);

  LThread:=GetThread;

  //for await support, add ourself to the collection
  Collection.Add(LThread);

  //create and initialize an internal thread
  LIntThread:=DoGetThreadClass.Create(True);
  LIntThread.FreeOnTerminate:=False;//we handle memory
  LIntThread.EZThread:=LThread;
  LIntThread.StartMethod:=FStart;
  LIntThread.StartCallback:=FStartCall;
  LIntThread.StartNestedCallback:=FStartNestCall;
  LIntThread.Success:=FSuccess;
  LIntThread.SuccessCallback:=FSuccessCall;
  LIntThread.SuccessNestedCallback:=FSuccessNestCall;
  LIntThread.ErrorMethod:=FError;
  LIntThread.ErrorCallback:=FErrorCall;
  LIntThread.ErrorNestedCallback:=FErrorNestCall;
  LIntThread.Caller:=TThread.CurrentThread;

  //create and setup monitor thread
  LMonThread:=TMonitorThread.Create(True);
  LMonThread.FreeOnTerminate:=True;//memory freed automatically
  LMonThread.ID:=TGuid.NewGuid.ToString();
  FMonitorThreads.Add(LMonThread.ID);
  LMonThread.List:=FMonitorThreads;
  LMonThread.InternalThread:=LIntThread;
  LMonThread.OnDone:=UpdateState;

  Critical.Enter;
  try
    //start the internal thread
    LIntThread.Start;

    //update state
    FState:=esStarted;

    //start the monitor thread
    LMonThread.Start;
  finally
    Critical.Leave;
  end;
end;

procedure TEZThreadImpl.Stop;
var
  I:Integer;
begin
  for I:=0 to Pred(FMonitorThreads.Count) do
    FMonitorThreads.Data[I].StopMonitor;

  //monitor threads will remove themselves from the list
  //so wait until this has been done
  while FMonitorThreads.Count > 0 do
    Continue;
end;

constructor TEZThreadImpl.Create;
begin
  FState:=esStopped;
  FMaxRunTime:=0;
  FSynchStopEvents:=False;
  FForceTerminate:=False;
  FOnStart:=nil;
  FOnStop:=nil;
  FOnStartCall:=nil;
  FOnStopCall:=nil;
  SetLength(FArgs,0);
  FThreadID:=TGuid.NewGuid.ToString;
  FGroupID:=TGuid.NewGuid.ToString;
  FMonitorThreads:=TMonitorList.Create(False);
end;

destructor TEZThreadImpl.Destroy;
begin
  Stop;
  FMonitorThreads.Free;
  SetLength(FArgs,0);
  inherited Destroy;
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
  Collection:=TEZCollectionImpl.Create;
finalization
  if Assigned(Critical) then
    Critical.Free;
  Collection:=nil;
end.

