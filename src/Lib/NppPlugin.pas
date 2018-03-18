{
    This file was originally created by Damjan Zobo Cvetko
    Modified by Andreas Heim for using in the AutoCodepage plugin for Notepad++

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
}

unit NppPlugin;


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils, System.IOUtils,
  System.Types, System.Classes, Vcl.Dialogs, Vcl.Forms,

  SciSupport, NppSupport, NppMenuCmdID;


const
  FNITEM_NAMELEN = 64;
  C_NO_LANGUAGE  = -1;


type
  // Plugin metaclass
  // Eleminates the need to edit the file NppPluginInclude.pas for every new plugin
  TNppPluginClass = class of TNppPlugin;


  // Plugin base class
  TNppPlugin = class(TObject)
  private type
    PFuncPluginCmd = procedure; cdecl;

    TFuncItem = record
      ItemName    : array[0..FNITEM_NAMELEN-1] of nppChar;
      Func        : PFuncPluginCmd;
      CmdID       : Integer;
      Checked     : Boolean;
      ShortcutKey : PShortcutKey;
    end;

  private
    FPluginName:          nppString;
    FPluginMajorVersion:  integer;
    FPluginMinorVersion:  integer;
    FPluginReleaseNumber: integer;
    FSCNotification:      PSCNotification;
    FFuncArray:           array of TFuncItem;

  protected
    // Internal utils
    procedure   GetVersionInfo;

    function    AddFuncItem(Name: nppString; Func: PFuncPluginCmd): Integer; overload;
    function    AddFuncItem(Name: nppString; Func: PFuncPluginCmd; ShortcutKey: TShortcutKey): Integer; overload;

    // Hooks
    procedure   DoNppnReady; virtual;
    procedure   DoNppnFileBeforeLoad; virtual;
    procedure   DoNppnFileLoadFailed; virtual;
    procedure   DoNppnSnapshotDirtyFileLoaded; virtual;
    procedure   DoNppnFileBeforeOpen; virtual;
    procedure   DoNppnFileOpened; virtual;
    procedure   DoNppnFileBeforeClose; virtual;
    procedure   DoNppnFileClosed; virtual;
    procedure   DoNppnFileBeforeSave; virtual;
    procedure   DoNppnFileSaved; virtual;
    procedure   DoNppnFileBeforeRename; virtual;
    procedure   DoNppnFileRenameCancel; virtual;
    procedure   DoNppnFileRenamed; virtual;
    procedure   DoNppnFileBeforeDelete; virtual;
    procedure   DoNppnFileDeleteFailed; virtual;
    procedure   DoNppnFileDeleted; virtual;
    procedure   DoNppnBeforeShutDown; virtual;
    procedure   DoNppnCancelShutDown; virtual;
    procedure   DoNppnShutdown; virtual;
    procedure   DoNppnBufferActivated; virtual;
    procedure   DoNppnLangChanged; virtual;
    procedure   DoNppnReadOnlyChanged; virtual;
    procedure   DoNppnDocOrderChanged; virtual;
    procedure   DoNppnShortcutRemapped; virtual;
    procedure   DoNppnWordStylesUpdated; virtual;
    procedure   DoNppnToolbarModification; virtual;

    property    PluginName:         nppString       read FPluginName         write FPluginName;
    property    PluginMajorVersion: integer         read FPluginMajorVersion write FPluginMajorVersion;
    property    PluginMinorVersion: integer         read FPluginMinorVersion write FPluginMinorVersion;
    property    SCNotification:     PSCNotification read FSCNotification;

  public
    NppData: TNppData;

    constructor Create; virtual;
    destructor  Destroy; override;

    procedure   BeforeDestruction; override;

    // Plugin interface methods
    procedure   MessageProc(var Msg: TMessage); virtual;
    procedure   BeNotified(SN: PSCNotification);
    procedure   SetInfo(ANppData: TNppData); virtual;
    function    GetFuncsArray(out FuncsCount: integer): Pointer;
    function    GetName: nppPChar;

    // Utils and Npp message wrappers
    function    CmdIdFromDlgId(DlgId: Integer): Integer;

    function    GetMajorVersion: integer;
    function    GetMinorVersion: integer;
    function    GetReleaseNumber: integer;
    function    GetNppDir: string;
    function    GetPluginsDir: string;
    function    GetPluginsConfigDir: string;
    function    GetPluginsDocDir: string;
    function    GetPluginDllPath: string;
    function    GetOpenFilesCnt(CntType: integer): integer;
    function    GetOpenFiles(CntType: integer): TStringDynArray;
    function    GetFullCurrentPath: string;
    function    GetCurrentDirectory: string;
    function    GetFullFileName: string;
    function    GetFileNameWithoutExt: string;
    function    GetFileNameExt: string;
    procedure   GetFileLine(out FileName: string; out Line: integer);
    function    GetWord: string;
    function    GetEncoding: integer;
    function    GetEOLFormat: integer;
    function    GetLanguageType: integer;  // see TNppLang
    function    GetLanguageName(ALangType: TNppLang): string;
    function    GetLanguageDesc(ALangType: TNppLang): string;
    function    GetCurrentView: integer;
    function    GetCurrentBufferId: LRESULT;
    function    GetBufferDirty: boolean;

    procedure   PerformMenuCommand(MenuCmdId: integer; Param: integer = 0);
    procedure   SwitchToFile(FileName: string);
    function    OpenFile(FileName: string; ReadOnly: boolean = false): boolean; overload;
    function    OpenFile(FileName: string; Line: Integer; ReadOnly: boolean = false): boolean; overload;

  end;



implementation


// =============================================================================
// Class TNppPlugin
// =============================================================================

// -----------------------------------------------------------------------------
// Create / Destroy
// -----------------------------------------------------------------------------

constructor TNppPlugin.Create;
begin
  inherited;
end;


destructor TNppPlugin.Destroy;
var
  i: integer;

begin
  for i:=0 to Length(FFuncArray)-1 do
  begin
    if Assigned(FFuncArray[i].ShortcutKey) then
      Dispose(FFuncArray[i].ShortcutKey);
  end;

  inherited;
end;


//  This is hacking for troubble...
//  We need to unset the Application handler so that the forms
//  don't get berserk and start throwing OS error 1004.
//  This happens because the main NPP HWND is already lost when the
//  DLL_PROCESS_DETACH gets called, and the form tries to allocate a new
//  handler for sending the "close" windows message...
procedure TNppPlugin.BeforeDestruction;
begin
  Application.Handle := 0;
  Application.Terminate;

  inherited;
end;


// -----------------------------------------------------------------------------
// Plugin interface
// -----------------------------------------------------------------------------

procedure TNppPlugin.MessageProc(var Msg: TMessage);
var
  hm: HMENU;
  i:  integer;

begin
  if (Msg.Msg = WM_CREATE) then
  begin
    hm := GetMenu(NppData.NppHandle);

    for i := 0 to Pred(Length(FFuncArray)) do
    begin
      if (FFuncArray[i].ItemName[0] = '-') then
        ModifyMenu(hm, FFuncArray[i].CmdID, MF_BYCOMMAND or MF_SEPARATOR, 0, nil);
    end;
  end;

  Dispatch(Msg);
end;


procedure TNppPlugin.BeNotified(SN: PSCNotification);
begin
  // For some notifications hwndFrom doesn't contain the Npp window handle
  // if (HWND(SN^.nmhdr.hwndFrom) <> NppData.NppHandle) then exit;

  // Provide notification data to derived classes
  FSCNotification := SN;

  case SN^.nmhdr.code of
    NPPN_READY:                   DoNppnReady;
    NPPN_FILEBEFORELOAD:          DoNppnFileBeforeLoad;
    NPPN_FILELOADFAILED:          DoNppnFileLoadFailed;
    NPPN_SNAPSHOTDIRTYFILELOADED: DoNppnSnapshotDirtyFileLoaded;
    NPPN_FILEBEFOREOPEN:          DoNppnFileBeforeOpen;
    NPPN_FILEOPENED:              DoNppnFileOpened;
    NPPN_FILEBEFORECLOSE:         DoNppnFileBeforeClose;
    NPPN_FILECLOSED:              DoNppnFileClosed;
    NPPN_FILEBEFORESAVE:          DoNppnFileBeforeSave;
    NPPN_FILESAVED:               DoNppnFileSaved;
    NPPN_FILEBEFORERENAME:        DoNppnFileBeforeRename;
    NPPN_FILERENAMECANCEL:        DoNppnFileRenameCancel;
    NPPN_FILERENAMED:             DoNppnFileRenamed;
    NPPN_FILEBEFOREDELETE:        DoNppnFileBeforeDelete;
    NPPN_FILEDELETEFAILED:        DoNppnFileDeleteFailed;
    NPPN_FILEDELETED:             DoNppnFileDeleted;
    NPPN_BEFORESHUTDOWN:          DoNppnBeforeShutDown;
    NPPN_CANCELSHUTDOWN:          DoNppnCancelShutDown;
    NPPN_SHUTDOWN:                DoNppnShutdown;
    NPPN_BUFFERACTIVATED:         DoNppnBufferActivated;
    NPPN_LANGCHANGED:             DoNppnLangChanged;
    NPPN_READONLYCHANGED:         DoNppnReadOnlyChanged;
    NPPN_DOCORDERCHANGED:         DoNppnDocOrderChanged;
    NPPN_SHORTCUTREMAPPED:        DoNppnShortcutRemapped;
    NPPN_WORDSTYLESUPDATED:       DoNppnWordStylesUpdated;
    NPPN_TB_MODIFICATION:         DoNppnToolbarModification;
  end;
end;


procedure TNppPlugin.SetInfo(ANppData: TNppData);
begin
  Self.NppData       := ANppData;
  Application.Handle := NppData.NppHandle;
end;


function TNppPlugin.GetFuncsArray(out FuncsCount: integer): Pointer;
begin
  FuncsCount := Length(FFuncArray);
  Result     := FFuncArray;
end;


function TNppPlugin.GetName: nppPChar;
begin
  Result := nppPChar(PluginName);
end;


// -----------------------------------------------------------------------------
// Internal utils
// -----------------------------------------------------------------------------

procedure TNppPlugin.GetVersionInfo;
var
  lptstrFilename: string;
  dwHandle:       DWORD;
  dwLen:          DWORD;
  lpData:         pointer;
  puLen:          DWORD;
  FileInfo:       PVSFixedFileInfo;

begin
  FPluginMajorVersion  := 0;
  FPluginMinorVersion  := 0;

  lptstrFilename := GetPluginDllPath;
  if not FileExists(lptstrFilename) then exit;

  dwLen := GetFileVersionInfoSize(PChar(lptstrFilename), dwHandle);
  if dwLen = 0 then exit;

  GetMem(lpData, dwLen);

  try
    if GetFileVersionInfo(PChar(lptstrFilename), dwHandle, dwLen, lpData) then
    begin
      if VerQueryValue(lpData, '\', pointer(FileInfo), puLen) then
      begin
        FPluginMajorVersion  := (FileInfo.dwFileVersionMS) shr 16;
        FPluginMinorVersion  := (FileInfo.dwFileVersionMS) and $FFFF;
        FPluginReleaseNumber := (FileInfo.dwFileVersionLS) shr 16;
      end;
    end;

  finally
    FreeMem(lpData);
  end;
end;


function TNppPlugin.AddFuncItem(Name: nppString; Func: PFuncPluginCmd): integer;
var
  i: Integer;

begin
  i := Length(FFuncArray);
  SetLength(FFuncArray, i+1);

  StringToWideChar(Name, FFuncArray[i].ItemName, Length(FFuncArray[i].ItemName));

  FFuncArray[i].Func        := Func;
  FFuncArray[i].ShortcutKey := nil;

  Result := i;
end;


function TNppPlugin.AddFuncItem(Name: nppString; Func: PFuncPluginCmd;
  ShortcutKey: TShortcutKey): Integer;
var
  i: Integer;

begin
  i := AddFuncItem(Name, Func);
  New(FFuncArray[i].ShortcutKey);

  FFuncArray[i].ShortcutKey.IsCtrl  := ShortcutKey.IsCtrl;
  FFuncArray[i].ShortcutKey.IsAlt   := ShortcutKey.IsAlt;
  FFuncArray[i].ShortcutKey.IsShift := ShortcutKey.IsShift;
  FFuncArray[i].ShortcutKey.Key     := ShortcutKey.Key;

  Result := i;
end;


// -----------------------------------------------------------------------------
// Utils and message wrapper methods
// -----------------------------------------------------------------------------

function TNppPlugin.CmdIdFromDlgId(DlgId: Integer): Integer;
begin
  Result := FFuncArray[DlgId].CmdId;
end;


function TNppPlugin.GetMajorVersion: integer;
begin
  Result := FPluginMajorVersion;
end;


function TNppPlugin.GetMinorVersion: integer;
begin
  Result := FPluginMinorVersion;
end;


function TNppPlugin.GetReleaseNumber: integer;
begin
  Result := FPluginReleaseNumber;
end;


function TNppPlugin.GetNppDir: string;
var
  s: string;

begin
  SetLength(s, MAX_PATH);

  SendMessage(NppData.NppHandle, NPPM_GETNPPDIRECTORY, MAX_PATH, LPARAM(nppPChar(s)));
  SetLength(s, StrLen(PChar(s)));

  Result := s;
end;


function TNppPlugin.GetPluginsDir: string;
begin
  Result := TPath.Combine(GetNppDir, 'plugins');
end;


function TNppPlugin.GetPluginsConfigDir: string;
var
  s: string;

begin
  SetLength(s, MAX_PATH);

  SendMessage(NppData.NppHandle, NPPM_GETPLUGINSCONFIGDIR, MAX_PATH, LPARAM(nppPChar(s)));
  SetLength(s, StrLen(PChar(s)));

  Result := s;
end;


function TNppPlugin.GetPluginsDocDir: string;
begin
  Result := TPath.Combine(GetPluginsDir, 'doc');
end;


function TNppPlugin.GetPluginDllPath: string;
begin
  Result := TPath.Combine(GetPluginsDir, ReplaceStr(GetName, ' ', '') + '.dll')
end;


function TNppPlugin.GetOpenFilesCnt(CntType: integer): integer;
begin
  Result := SendMessage(NppData.NppHandle, NPPM_GETNBOPENFILES, 0, LPARAM(CntType));
end;


function TNppPlugin.GetOpenFiles(CntType: integer): TStringDynArray;
var
  Cnt:    integer;
  Idx:    integer;
  Buffer: array of PChar;

begin
  Cnt := GetOpenFilesCnt(CntType);
  SetLength(Buffer, Cnt);

  for Idx := 0 to Pred(Cnt) do
    Buffer[Idx] := StrAlloc(MAX_PATH);

  Cnt := SendMessage(NppData.NppHandle, NPPM_GETOPENFILENAMES, WPARAM(Buffer), LPARAM(Cnt));
  SetLength(Result, Cnt);

  for Idx := 0 to Pred(Cnt) do
  begin
    SetString(Result[Idx], Buffer[Idx], StrLen(Buffer[Idx]));
    StrDispose(Buffer[Idx]);
  end;
end;


function TNppPlugin.GetFullCurrentPath: string;
begin
  SetLength(Result, MAX_PATH);

  SendMessage(NppData.NppHandle, NPPM_GETFULLCURRENTPATH, MAX_PATH, LPARAM(nppPChar(Result)));
  SetLength(Result, StrLen(PChar(Result)));
end;


function TNppPlugin.GetCurrentDirectory: string;
begin
  SetLength(Result, MAX_PATH);

  SendMessage(NppData.NppHandle, NPPM_GETCURRENTDIRECTORY, MAX_PATH, LPARAM(nppPChar(Result)));
  SetLength(Result, StrLen(PChar(Result)));
end;


function TNppPlugin.GetFullFileName: string;
begin
  SetLength(Result, MAX_PATH);

  SendMessage(NppData.NppHandle, NPPM_GETFILENAME, MAX_PATH, LPARAM(nppPChar(Result)));
  SetLength(Result, StrLen(PChar(Result)));
end;


function TNppPlugin.GetFileNameWithoutExt: string;
begin
  SetLength(Result, MAX_PATH);

  SendMessage(NppData.NppHandle, NPPM_GETNAMEPART, MAX_PATH, LPARAM(nppPChar(Result)));
  SetLength(Result, StrLen(PChar(Result)));
end;


function TNppPlugin.GetFileNameExt: string;
begin
  SetLength(Result, MAX_PATH);

  SendMessage(NppData.NppHandle, NPPM_GETEXTPART, MAX_PATH, LPARAM(nppPChar(Result)));
  SetLength(Result, StrLen(PChar(Result)));
end;


procedure TNppPlugin.GetFileLine(out FileName: string; out Line: integer);
var
  r: LRESULT;

begin
  FileName := GetFullCurrentPath;

  r    := SendMessage(NppData.ScintillaMainHandle, SCI_GETCURRENTPOS, 0, 0);
  Line := SendMessage(NppData.ScintillaMainHandle, SCI_LINEFROMPOSITION, WPARAM(r), 0);
end;


function TNppPlugin.GetWord: string;
const
  BUF_LEN = 1024;

begin
  SetLength(Result, BUF_LEN+1);

  SendMessage(NppData.NppHandle, NPPM_GETCURRENTWORD, BUF_LEN, LPARAM(nppPChar(Result)));
  SetLength(Result, StrLen(PChar(Result)));
end;


function TNppPlugin.GetEncoding: integer;
begin
  Result := SendMessage(NppData.NppHandle, NPPM_GETBUFFERENCODING, WPARAM(GetCurrentBufferId), 0);
end;


function TNppPlugin.GetEOLFormat: integer;
begin
  Result := SendMessage(NppData.NppHandle, NPPM_GETBUFFERFORMAT, WPARAM(GetCurrentBufferId), 0);
end;


function TNppPlugin.GetLanguageType: integer;
begin
  Result := SendMessage(NppData.NppHandle, NPPM_GETBUFFERLANGTYPE, WPARAM(GetCurrentBufferId), 0);
  if Result = -1 then Result := C_NO_LANGUAGE;
end;


function TNppPlugin.GetLanguageName(ALangType: TNppLang): string;
var
  BufLen: LRESULT;

begin
  BufLen := SendMessage(NppData.NppHandle, NPPM_GETLANGUAGENAME, WPARAM(ALangType), 0);
  SetLength(Result, BufLen+1);

  BufLen := SendMessage(NppData.NppHandle, NPPM_GETLANGUAGENAME, WPARAM(ALangType), LPARAM(nppPChar(Result)));
  SetLength(Result, BufLen);
end;


function TNppPlugin.GetLanguageDesc(ALangType: TNppLang): string;
var
  BufLen: LRESULT;

begin
  BufLen := SendMessage(NppData.NppHandle, NPPM_GETLANGUAGEDESC, WPARAM(ALangType), 0);
  SetLength(Result, BufLen+1);

  BufLen := SendMessage(NppData.NppHandle, NPPM_GETLANGUAGEDESC, WPARAM(ALangType), LPARAM(nppPChar(Result)));
  SetLength(Result, BufLen);
end;


function TNppPlugin.GetCurrentView: integer;
begin
  Result := SendMessage(NppData.NppHandle, NPPM_GETCURRENTVIEW, 0, 0);
end;


function TNppPlugin.GetCurrentBufferId: LRESULT;
begin
  Result := SendMessage(NppData.NppHandle, NPPM_GETCURRENTBUFFERID, 0, 0);
end;


function TNppPlugin.GetBufferDirty: boolean;
begin
  Result := (SendMessage(NppData.ScintillaMainHandle, SCI_GETMODIFY, 0, 0) <> 0);
end;


procedure TNppPlugin.PerformMenuCommand(MenuCmdId: integer; Param: integer = 0);
begin
  SendMessage(NppData.NppHandle, NPPM_MENUCOMMAND, WPARAM(Param), LPARAM(MenuCmdId));
end;


procedure TNppPlugin.SwitchToFile(FileName: string);
begin
  SendMessage(NppData.NppHandle, NPPM_SWITCHTOFILE, 0, LPARAM(nppPChar(FileName)));
end;


function TNppPlugin.OpenFile(FileName: string; Line: integer; ReadOnly: boolean = false): boolean;
var
  Ret: boolean;

begin
  Ret := OpenFile(FileName, ReadOnly);

  if Ret then
    SendMessage(NppData.ScintillaMainHandle, SCI_GOTOLINE, Line, 0);

  Result := Ret;
end;


function TNppPlugin.OpenFile(FileName: string; ReadOnly: boolean = false): boolean;
var
  Cnt:       integer;
  Ret:       integer;
  FileNames: TStringDynArray;

begin
  // ask if we are not already opened
  FileNames := GetOpenFiles(ALL_OPEN_FILES);

  for Cnt := Low(FileNames) to High(FileNames) do
  begin
    if SameFileName(FileNames[Cnt], FileName) then
    begin
      // activate document tab and exit
      SwitchToFile(FileName);
      exit(true);
    end;
  end;

  // open the file
  Ret    := SendMessage(NppData.NppHandle, NPPM_DOOPEN, 0, LPARAM(nppPChar(FileName)));
  Result := (Ret <> 0);

  // if requested set read-only state
  if Result and ReadOnly then
    PerformMenuCommand(IDM_EDIT_SETREADONLY, 1);
end;


// -----------------------------------------------------------------------------
// Notification hooks
// -----------------------------------------------------------------------------

procedure TNppPlugin.DoNppnReady;
begin
  // When overriding this ensure to call "inherited"

  // Retrieve version infos from plugin's DLL file
  // and write them to internal variables
  GetVersionInfo();
end;


procedure TNppPlugin.DoNppnToolbarModification;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileBeforeClose;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileOpened;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileClosed;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileBeforeOpen;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileBeforeSave;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileSaved;
begin
  // override this
end;


procedure TNppPlugin.DoNppnShutdown;
begin
  // override this
end;


procedure TNppPlugin.DoNppnBufferActivated;
begin
  // override this
end;


procedure TNppPlugin.DoNppnLangChanged;
begin
  // override this
end;


procedure TNppPlugin.DoNppnWordStylesUpdated;
begin
  // override this
end;


procedure TNppPlugin.DoNppnShortcutRemapped;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileBeforeLoad;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileLoadFailed;
begin
  // override this
end;


procedure TNppPlugin.DoNppnReadOnlyChanged;
begin
  // override this
end;


procedure TNppPlugin.DoNppnDocOrderChanged;
begin
  // override this
end;


procedure TNppPlugin.DoNppnSnapshotDirtyFileLoaded;
begin
  // override this
end;


procedure TNppPlugin.DoNppnBeforeShutDown;
begin
  // override this
end;


procedure TNppPlugin.DoNppnCancelShutDown;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileBeforeRename;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileRenameCancel;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileRenamed;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileBeforeDelete;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileDeleteFailed;
begin
  // override this
end;


procedure TNppPlugin.DoNppnFileDeleted;
begin
  // override this
end;


end.
