{
    This file is part of the AutoCodepage plugin for Notepad++
    Author: Andreas Heim

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License version 3 as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
}

unit Main;


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils, System.DateUtils,
  System.IOUtils, System.Math, System.Types, System.Classes, System.Generics.Defaults,
  System.Generics.Collections,

  SciSupport, NppSupport, NppPlugin, NppPluginForms, NppPluginDockingForms,

  DataModule,

  dialog_TfrmSettings,
  dialog_TfrmAbout;


type
  // Plugin class
  TAutoCodepagePlugin = class(TNppPlugin)
  private type
    TBufferCatalog = TList<LRESULT>;

  private
    FCurFileClassIdx: integer;
    FBuffers:         TBufferCatalog;
    FSettings:        TSettings;
    FIgnoreEvents:    boolean;

    // Functions to handle Notepad++ renaming a document, changing the document
    // language or activating another document's tab
    procedure   CheckFileChanges;
    procedure   CheckLangChanges;
    procedure   CheckBufferChanges;
    procedure   RemoveCurrentBufferFromCatalog;

    // Functions to check if the filename extension or the language of the
    // active Notepad++ document fits the requirements of a certain file class
    function    MatchLangType: boolean;
    function    MatchFileNameExt: boolean;

    // Function to change the encoding of the active Notepad++ document
    procedure   SwitchToEncoding;

    // Retrieves the index of the file class the active document belongs to
    procedure   GetCurFileClassIdx();

  protected
    // Handler for certain Notepad++ events
    procedure   DoNppnReady; override;
    procedure   DoNppnBufferActivated; override;
    procedure   DoNppnLangChanged; override;
    procedure   DoNppnFileRenamed; override;
    procedure   DoNppnFileBeforeSave; override;
    procedure   DoNppnFileSaved; override;
    procedure   DoNppnFileBeforeClose; override;

  public
    constructor Create; override;
    destructor  Destroy; override;

    // Access to basic plugin functions
    procedure   LoadSettings();
    procedure   UnloadSettings();

    procedure   UpdateCurBuffer();

  end;


var
  // Class type to create in startup code
  PluginClass: TNppPluginClass = TAutoCodepagePlugin;

  // Plugin instance variable, this is the reference to use in plugin's code
  Plugin: TAutoCodepagePlugin;



implementation

const
  // Plugin name
  TXT_PLUGIN_NAME:       string = 'AutoCodepage';

  TXT_MENUITEM_SETTINGS: string = 'Settings';
  TXT_MENUITEM_ABOUT:    string = 'About';


// Functions associated to the plugin's Notepad++ menu entries
procedure ShowSettings; cdecl; forward;
procedure ShowAbout; cdecl; forward;


// =============================================================================
// Class TAutoCodepagePlugin
// =============================================================================

// -----------------------------------------------------------------------------
// Create / Destroy
// -----------------------------------------------------------------------------

constructor TAutoCodepagePlugin.Create;
begin
  inherited Create;

  // Store a reference to the instance in a global variable with an appropriate
  // type to get access to its properties and methods
  Plugin := Self;

  // This property is important to extract version infos from the DLL file,
  // so set it right now after creation of the object
  PluginName := TXT_PLUGIN_NAME;

  // Add plugins's menu entries to Notepad++
  AddFuncItem(TXT_MENUITEM_SETTINGS, ShowSettings);
  AddFuncItem(TXT_MENUITEM_ABOUT,    ShowAbout);

  FBuffers         := TBufferCatalog.Create;
  FCurFileClassIdx := -1;
  FIgnoreEvents    := false;
end;


destructor TAutoCodepagePlugin.Destroy;
begin
  // Cleanup
  FBuffers.Free;

  UnloadSettings();

  // It's totally legal to call Free on already freed instances,
  // no checks needed
  frmAbout.Free;
  frmSettings.Free;

  inherited;
end;


// -----------------------------------------------------------------------------
// (De-)Initialization
// -----------------------------------------------------------------------------

// Read settings file
procedure TAutoCodepagePlugin.LoadSettings;
begin
  FSettings := TSettings.Create(TSettings.FilePath);
end;


// Free settings data model
procedure TAutoCodepagePlugin.UnloadSettings;
begin
  FreeAndNil(FSettings);
end;


// Emulate the activation of a document's tab in Notepad++
procedure TAutoCodepagePlugin.UpdateCurBuffer;
begin
  DoNppnBufferActivated();
end;


// -----------------------------------------------------------------------------
// Event handler
// -----------------------------------------------------------------------------

// Called after Notepad++ has started and is ready for work
procedure TAutoCodepagePlugin.DoNppnReady;
begin
  inherited;

  // Load settings and apply them to the active document
  LoadSettings();
  UpdateCurBuffer();
end;


// Called after activating the tab of a file
procedure TAutoCodepagePlugin.DoNppnBufferActivated;
begin
  if FIgnoreEvents then exit;
  CheckBufferChanges();
end;


// Called after changing the language of a file
procedure TAutoCodepagePlugin.DoNppnLangChanged;
begin
  if FIgnoreEvents then exit;
  CheckLangChanges();
end;


// Called after renaming a file in Notepad++
procedure TAutoCodepagePlugin.DoNppnFileRenamed;
begin
  if FIgnoreEvents then exit;
  CheckFileChanges();
end;


// Called just before a file is saved
procedure TAutoCodepagePlugin.DoNppnFileBeforeSave;
begin
  FIgnoreEvents := true;
end;


// Called after a file has been saved
procedure TAutoCodepagePlugin.DoNppnFileSaved;
begin
  FIgnoreEvents := false;
end;


// Called just before a file and its tab is closed
procedure TAutoCodepagePlugin.DoNppnFileBeforeClose;
begin
  RemoveCurrentBufferFromCatalog();
end;


// -----------------------------------------------------------------------------
// Worker methods
// -----------------------------------------------------------------------------

// Change documents encoding if its filename extension and its language
// fits the requirements of a file class
procedure TAutoCodepagePlugin.CheckBufferChanges;
var
  CurBufferId: integer;

begin
  if MatchFileNameExt() and MatchLangType() then
  begin
    CurBufferId := GetCurrentBufferId();

    // Only change encoding if it hasn't been done already
    if not FBuffers.Contains(CurBufferId) then
    begin
      // Remember buffer ID
      FBuffers.Add(CurBufferId);

      // Change encoding
      SwitchToEncoding();
    end;
  end;
end;


// Change documents encoding if its language
// fits the requirements of a file class
procedure TAutoCodepagePlugin.CheckLangChanges;
begin
  if MatchLangType() then
    SwitchToEncoding();
end;


// Change documents encoding if its filename extension
// fits the requirements of a file class
procedure TAutoCodepagePlugin.CheckFileChanges;
begin
  if MatchFileNameExt() then
    SwitchToEncoding();
end;


// Delete reference to current text buffer
procedure TAutoCodepagePlugin.RemoveCurrentBufferFromCatalog;
begin
  FBuffers.Remove(GetCurrentBufferId());
end;


// Request change of encoding
procedure TAutoCodepagePlugin.SwitchToEncoding;
begin
  PerformMenuCommand(FSettings.FileClassCodePage[FCurFileClassIdx]);
end;


// -----------------------------------------------------------------------------
// Test methods
// -----------------------------------------------------------------------------

// Check if the filename extension of the active Notepad++ document
// is part of a file class
function TAutoCodepagePlugin.MatchFileNameExt: boolean;
begin
  GetCurFileClassIdx();
  Result := (FCurFileClassIdx >= 0)
end;


// Check if the selected language of the active Notepad++ document
// is part of a file class
function TAutoCodepagePlugin.MatchLangType: boolean;
var
  LangType: integer;

begin
  Result := false;

  GetCurFileClassIdx();

  if FCurFileClassIdx < 0 then exit;
  if FSettings.FileClassLanguage[FCurFileClassIdx] = C_NO_LANGUAGE then exit(true);

  // Retrieve active documents's language
  LangType := GetLanguageType;

  Result := (LangType = FSettings.FileClassLanguage[FCurFileClassIdx]);
end;


// Searches in the array of file classes the filename extension of the active
// Notepad++ document and sets a global variable to the index of the matching
// file class
procedure TAutoCodepagePlugin.GetCurFileClassIdx();
var
  Cnt:         integer;
  FileNameExt: string;

begin
  FCurFileClassIdx := -1;

  if not Assigned(FSettings) then exit;
  if not FSettings.Valid     then exit;

  // Retrieve filename extension
  FileNameExt := GetFileNameExt;

  // Check if there is a file class where the extension fits to
  for Cnt := 0 to Pred(FSettings.FileClassCount) do
  begin
    if IndexText(FileNameExt, SplitString(FSettings.FileClassExtensions[Cnt].DelimitedText,
                                          FSettings.FileClassExtensions[Cnt].Delimiter)) >= 0 then
    begin
      FCurFileClassIdx := Cnt;
      exit;
    end;
  end;
end;



// -----------------------------------------------------------------------------
// Plugin menu items
// -----------------------------------------------------------------------------

// Show "Settings" dialog in Notepad++
procedure ShowSettings; cdecl;
begin
  if not Assigned(frmSettings) then
  begin
    // Before opening the settings dialog discard own settings object
    Plugin.UnloadSettings();

    // Show settings dialog in a modal state and destroy it after close
    frmSettings := TfrmSettings.Create(Plugin);
    frmSettings.ShowModal;
    frmSettings.Free;

    // Load maybe updated settings and apply it to the active Notepad++ document
    Plugin.LoadSettings();
    Plugin.UpdateCurBuffer();
  end;
end;


// Show "About" dialog in Notepad++
procedure ShowAbout; cdecl;
begin
  if not Assigned(frmAbout) then
  begin
    // Show about dialog in a modal state and destroy it after close
    frmAbout := TfrmAbout.Create(Plugin);
    frmAbout.ShowModal;
    frmAbout.Free;
  end;
end;


end.
