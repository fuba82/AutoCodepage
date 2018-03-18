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

unit dialog_TfrmSettings;


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils, System.IOUtils,
  System.Math, System.Types, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Forms, Vcl.Dialogs,

  VclExtend,

  NppSupport, NppMenuCmdID, NppPlugin, NppPluginForms,

  DataModule;


type
  TfrmSettings = class(TNppPluginForm)
    lbxGroups: TListBox;
    btnAddGroup: TButton;
    btnUpdateGroup: TButton;
    btnDeleteGroup: TButton;
    edtNewGroupName: TLabeledEdit;
    lblCodepageHeader: TStaticText;
    cbxCodePage: TComboBox;
    lblLanguageHeader: TStaticText;
    cbxLanguage: TComboBox;

    lbxExtensions: TListBox;
    btnAddExtension: TButton;
    btnDeleteExtension: TButton;
    edtNewExtension: TLabeledEdit;

    btnClose: TButton;

    procedure FormCreate(Sender: TObject);

    procedure lbxGroupsClick(Sender: TObject);
    procedure btnAddGroupClick(Sender: TObject);
    procedure btnDeleteGroupClick(Sender: TObject);
    procedure btnUpdateGroupClick(Sender: TObject);

    procedure edtNewGroupNameChange(Sender: TObject);
    procedure cbxCodepageChange(Sender: TObject);
    procedure cbxLanguageChange(Sender: TObject);

    procedure lbxExtensionsClick(Sender: TObject);
    procedure btnAddExtensionClick(Sender: TObject);
    procedure btnDeleteExtensionClick(Sender: TObject);

    procedure edtNewExtensionChange(Sender: TObject);

    procedure btnCloseClick(Sender: TObject);

  private
    FInUpdateGUI: boolean;
    FSettings:    TSettings;

    procedure   InitLists;
    procedure   LoadSettings(const AFilePath: string);

    procedure   UpdateExtensions;

    procedure   PrepareGUI;
    procedure   UpdateGUI(const SkipControls: array of TControl);

    function    ArrayContains(const AArray: array of TControl; AItem: TControl): boolean;

  public
    constructor Create(NppParent: TNppPlugin); override;
    destructor  Destroy; override;

    procedure   InitLanguage; override;

  end;


var
  frmSettings: TfrmSettings;



implementation

{$R *.dfm}


const
  TXT_HINT_BTN_ADD_GROUP:       string = 'Add group';
  TXT_CAPTION_BTN_UPDATE_GROUP: string = 'Update';
  TXT_HINT_BTN_UPDATE_GROUP:    string = 'Update group';
  TXT_HINT_BTN_DEL_GROUP:       string = 'Delete group';

  TXT_CAPTION_EDT_NEW_GROUP:    string = 'Group name';
  TXT_CAPTION_CBX_CODEPAGE:     string = 'Code page to set';
  TXT_CAPTION_CBX_LANGUAGE:     string = 'Expected language';

  TXT_HINT_BTN_ADD_EXT:         string = 'Add extension';
  TXT_HINT_BTN_DEL_EXT:         string = 'Delete extension';

  TXT_CAPTION_EDT_NEW_EXT:      string = 'New filename extension(s)';
  TXT_HINT_EDT_NEW_EXT:         string = 'Separate multiple extensions by semicolon';

  TXT_CAPTION_BTN_CLOSE:        string = 'Close';


type
  TEncodingMapping = record
    Name:        string;
    MenuCommand: integer;
  end;


var
  // ---------------------------------------------------------------------------
  // Mapping of encoding names to the menu command id which has to be send to
  // Notepad++ to switch to this encoding
  // This array is used to fill the entries in the "Codepage to set" combobox
  // ---------------------------------------------------------------------------
  EncodingMappings: array[0..67] of TEncodingMapping = (
    (Name: 'Common'               ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'ANSI'                 ;  MenuCommand: IDM_FORMAT_ANSI          ),
    (Name: 'UTF-8 (no BOM)'       ;  MenuCommand: IDM_FORMAT_AS_UTF_8      ),
    (Name: 'UTF-8 (with BOM)'     ;  MenuCommand: IDM_FORMAT_UTF_8         ),
    (Name: 'UCS-2 Big Endian'     ;  MenuCommand: IDM_FORMAT_UCS_2BE       ),
    (Name: 'UCS-2 Little Endian'  ;  MenuCommand: IDM_FORMAT_UCS_2LE       ),

    (Name: 'Arabic'               ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'ISO 8859-6'           ;  MenuCommand: IDM_FORMAT_ISO_8859_6    ),
    (Name: 'OEM 720'              ;  MenuCommand: IDM_FORMAT_DOS_720       ),
    (Name: 'Windows-1256'         ;  MenuCommand: IDM_FORMAT_WIN_1256      ),

    (Name: 'Baltic'               ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'ISO 8859-4'           ;  MenuCommand: IDM_FORMAT_ISO_8859_4    ),
    (Name: 'ISO 8859-13'          ;  MenuCommand: IDM_FORMAT_ISO_8859_13   ),
    (Name: 'OEM 775'              ;  MenuCommand: IDM_FORMAT_DOS_775       ),
    (Name: 'Windows-1257'         ;  MenuCommand: IDM_FORMAT_WIN_1257      ),

    (Name: 'Celtic'               ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'ISO 8859-14'          ;  MenuCommand: IDM_FORMAT_ISO_8859_14   ),

    (Name: 'Cyrillic'             ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'ISO 8859-5'           ;  MenuCommand: IDM_FORMAT_ISO_8859_5    ),
    (Name: 'KOI8-R'               ;  MenuCommand: IDM_FORMAT_KOI8R_CYRILLIC),
    (Name: 'KOI8-U'               ;  MenuCommand: IDM_FORMAT_KOI8U_CYRILLIC),
    (Name: 'Macintosh'            ;  MenuCommand: IDM_FORMAT_MAC_CYRILLIC  ),
    (Name: 'OEM 855'              ;  MenuCommand: IDM_FORMAT_DOS_855       ),
    (Name: 'OEM 866'              ;  MenuCommand: IDM_FORMAT_DOS_866       ),
    (Name: 'Windows-1251'         ;  MenuCommand: IDM_FORMAT_WIN_1251      ),

    (Name: 'Middle European'      ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'OEM 852'              ;  MenuCommand: IDM_FORMAT_DOS_852       ),
    (Name: 'Windows-1250'         ;  MenuCommand: IDM_FORMAT_WIN_1250      ),

    (Name: 'Chinese'              ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'BIG5 (traditional)'   ;  MenuCommand: IDM_FORMAT_BIG5          ),
    (Name: 'GB2312 (simplified)'  ;  MenuCommand: IDM_FORMAT_GB2312        ),

    (Name: 'East European'        ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'ISO 8859-2'           ;  MenuCommand: IDM_FORMAT_ISO_8859_2    ),

    (Name: 'Greek'                ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'ISO 8859-7'           ;  MenuCommand: IDM_FORMAT_ISO_8859_7    ),
    (Name: 'OEM 737'              ;  MenuCommand: IDM_FORMAT_DOS_737       ),
    (Name: 'OEM 869'              ;  MenuCommand: IDM_FORMAT_DOS_869       ),
    (Name: 'Windows-1253'         ;  MenuCommand: IDM_FORMAT_WIN_1253      ),

    (Name: 'Hebrew'               ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'ISO 8859-8'           ;  MenuCommand: IDM_FORMAT_ISO_8859_8    ),
    (Name: 'OEM 862'              ;  MenuCommand: IDM_FORMAT_DOS_862       ),
    (Name: 'Windows-1255'         ;  MenuCommand: IDM_FORMAT_WIN_1255      ),

    (Name: 'Japanese'             ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'Shift-JIS'            ;  MenuCommand: IDM_FORMAT_SHIFT_JIS     ),

    (Name: 'Korean'               ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'Windows-949'          ;  MenuCommand: IDM_FORMAT_KOREAN_WIN    ),
    (Name: 'EUC-KR'               ;  MenuCommand: IDM_FORMAT_EUC_KR        ),

    (Name: 'North European'       ;  MenuCommand: C_GROUP_HDR              ),
    // (Name: 'ISO 8859-10'          ;  MenuCommand: IDM_FORMAT_ISO_8859_10   ), // not used
    (Name: 'OEM 861: icelandic'   ;  MenuCommand: IDM_FORMAT_DOS_861       ),
    (Name: 'OEM 865: nordic'      ;  MenuCommand: IDM_FORMAT_DOS_865       ),

    (Name: 'Thai'                 ;  MenuCommand: C_GROUP_HDR              ),
    // (Name: 'ISO 8859-11'          ;  MenuCommand: IDM_FORMAT_ISO_8859_11   ), // not used
    (Name: 'TIS-620'              ;  MenuCommand: IDM_FORMAT_TIS_620       ),

    (Name: 'Turkish'              ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'ISO 8859-3'           ;  MenuCommand: IDM_FORMAT_ISO_8859_3    ),
    (Name: 'ISO 8859-9'           ;  MenuCommand: IDM_FORMAT_ISO_8859_9    ),
    (Name: 'OEM 857'              ;  MenuCommand: IDM_FORMAT_DOS_857       ),
    (Name: 'Windows-1254'         ;  MenuCommand: IDM_FORMAT_WIN_1254      ),

    (Name: 'West European'        ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'ISO 8859-1'           ;  MenuCommand: IDM_FORMAT_ISO_8859_1    ),
    (Name: 'ISO 8859-15'          ;  MenuCommand: IDM_FORMAT_ISO_8859_15   ),
    (Name: 'OEM 850'              ;  MenuCommand: IDM_FORMAT_DOS_850       ),
    (Name: 'OEM 858'              ;  MenuCommand: IDM_FORMAT_DOS_858       ),
    (Name: 'OEM 860: portuguese'  ;  MenuCommand: IDM_FORMAT_DOS_860       ),
    (Name: 'OEM 863: french'      ;  MenuCommand: IDM_FORMAT_DOS_863       ),
    (Name: 'OEM 437: US'          ;  MenuCommand: IDM_FORMAT_DOS_437       ),
    (Name: 'Windows-1252'         ;  MenuCommand: IDM_FORMAT_WIN_1252      ),

    (Name: 'Vietnamese'           ;  MenuCommand: C_GROUP_HDR              ),
    (Name: 'Windows-1258'         ;  MenuCommand: IDM_FORMAT_WIN_1258      )

    // (Name: 'South East European'  ;  MenuCommand: C_GROUP_HDR              ),
    // (Name: 'ISO 8859-16'          ;  MenuCommand: IDM_FORMAT_ISO_8859_16   )  // not used
  );


// =============================================================================
// Class TfrmSettings
// =============================================================================

// -----------------------------------------------------------------------------
// Create / Destroy
// -----------------------------------------------------------------------------

constructor TfrmSettings.Create(NppParent: TNppPlugin);
begin
  inherited;

  DefaultCloseAction := caHide;
  FInUpdateGUI       := false;
end;


destructor TfrmSettings.Destroy;
begin
  FSettings.Free;

  inherited;
  frmSettings := nil;
end;


// -----------------------------------------------------------------------------
// Initialization
// -----------------------------------------------------------------------------

// Perform basic initialization tasks
procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  Caption := Plugin.GetName;

  InitLanguage;
  InitLists;
  LoadSettings(TSettings.FilePath);

  UpdateExtensions;

  PrepareGUI();
  UpdateGUI([btnAddGroup, btnUpdateGroup]);
end;


// Set caption of GUI controls
procedure TfrmSettings.InitLanguage;
begin
  inherited;

  btnAddGroup.Hint                  := TXT_HINT_BTN_ADD_GROUP;
  btnUpdateGroup.Caption            := TXT_CAPTION_BTN_UPDATE_GROUP;
  btnUpdateGroup.Hint               := TXT_HINT_BTN_UPDATE_GROUP;
  btnDeleteGroup.Hint               := TXT_HINT_BTN_DEL_GROUP;

  edtNewGroupName.EditLabel.Caption := TXT_CAPTION_EDT_NEW_GROUP;
  lblCodepageHeader.Caption         := TXT_CAPTION_CBX_CODEPAGE;
  lblLanguageHeader.Caption         := TXT_CAPTION_CBX_LANGUAGE;

  btnAddExtension.Hint              := TXT_HINT_BTN_ADD_EXT;
  btnDeleteExtension.Hint           := TXT_HINT_BTN_DEL_EXT;

  edtNewExtension.EditLabel.Caption := TXT_CAPTION_EDT_NEW_EXT;
  edtNewExtension.Hint              := TXT_HINT_EDT_NEW_EXT;

  btnClose.Caption                  := TXT_CAPTION_BTN_CLOSE;
end;


// Init comboboxes
procedure TfrmSettings.InitLists;
var
  Cnt:       integer;
//  ALangType: TNppLang;
  ALangType: integer;
  ALangName: string;
  CbxItems:  TStringList;

begin
  // Fill "Codepage to set" combobox
  for Cnt := Low(EncodingMappings) to High(EncodingMappings) do
    cbxCodePage.Items.AddObject(EncodingMappings[Cnt].Name, TObject(EncodingMappings[Cnt].MenuCommand));

  // Fill "Expected language" combobox
  // At first we need a temporary string list...
  CbxItems := TStringList.Create(false);

  try
    // ...which has to be sorted case insensitive and ignores duplicate entries
    CbxItems.Sorted        := true;
    CbxItems.CaseSensitive := false;
    CbxItems.Duplicates    := dupIgnore;

    // Query Notepad++ for the names of all its supported languages and add
    // the returned strings together with their language code to the list.
    // Additionally create group entries from the first character of the
    // language names.

//    for ALangType := Low(TNppLang) to Pred(High(TNppLang)) do
//    begin
//      // Ignore user defined languages
//      if ALangType = L_USER then continue;
//
//      ALangName := Plugin.GetLanguageName(ALangType);
//      CbxItems.AddObject(UpCase(ALangName[1]), TObject(C_GROUP_HDR));
//      CbxItems.AddObject(ALangName,            TObject(ALangType));
//    end;

    ALangType := Ord(Low(TNppLang));

    repeat
      // Ignore user defined languages
      if ALangType <> Ord(L_USER) then
      begin
        ALangName := Plugin.GetLanguageName(TNppLang(ALangType));

        // Break when language "External" is found
        if SameText(ALangName, 'External') then break;

        CbxItems.AddObject(UpCase(ALangName[1]), TObject(C_GROUP_HDR));
        CbxItems.AddObject(ALangName,            TObject(ALangType));
      end;

      Inc(ALangType);
    until false;

    // Copy the content of the resulting list to the combobox's internal list
    // and add at the beginning of this list an empty entry (represents the
    // case "Language undefined")
    cbxLanguage.Items.AddStrings(CbxItems);
    cbxLanguage.Items.InsertObject(0, '', TObject(C_NO_LANGUAGE));

  finally
    // Free temporary list
    CbxItems.Free;
  end;

  // Set language combobox to entry 0
  if cbxLanguage.Items.Count > 0 then
    cbxLanguage.ItemIndex := 0;
end;


// Load settings from disk file and show settings of first file class available
procedure TfrmSettings.LoadSettings(const AFilePath: string);
var
  Cnt: integer;

begin
  FSettings := TSettings.Create(AFilePath);

  // Set file group entries
  for Cnt := 0 to Pred(FSettings.FileClassCount) do
    lbxGroups.Items.Add(FSettings.FileClassName[Cnt]);

  // Set codepage and language combobox to the settings of first file group
  if FSettings.FileClassCount > 0 then
  begin
    lbxGroups.ItemIndex   := 0;
    cbxCodepage.ItemIndex := cbxCodepage.Items.IndexOfObject(TObject(FSettings.FileClassCodePage[0]));
    cbxLanguage.Itemindex := cbxLanguage.Items.IndexOfObject(TObject(FSettings.FileClassLanguage[0]));
  end;
end;


// -----------------------------------------------------------------------------
// Event handlers
// -----------------------------------------------------------------------------

// Add a file class
procedure TfrmSettings.btnAddGroupClick(Sender: TObject);
var
  GroupList: TStringList;

begin
  if not FSettings.Valid then exit;

  GroupList := TStringList.Create;

  try
    GroupList.Sorted        := true;
    GroupList.CaseSensitive := false;
    GroupList.Duplicates    := dupIgnore;
    GroupList.Delimiter     := ';';

    GroupList.AddStrings(lbxGroups.Items);
    GroupList.Add(edtNewGroupName.Text);

    // Only add a new file group entry if there is no other file group
    // with the same name
    if GroupList.Count > lbxGroups.Count then
    begin
      FSettings.AddFileClass(edtNewGroupName.Text,
                             integer(cbxCodepage.Items.Objects[cbxCodepage.ItemIndex]),
                             integer(cbxLanguage.Items.Objects[cbxLanguage.ItemIndex]));

      lbxGroups.Clear;
      lbxGroups.Items.AddStrings(GroupList);
      lbxGroups.ItemIndex := GroupList.IndexOf(edtNewGroupName.Text);
    end;

    UpdateExtensions;

    PrepareGUI();
    UpdateGUI([btnAddGroup, btnUpdateGroup]);

  finally
    GroupList.Free;
  end;
end;


// Update a file class' parameters
procedure TfrmSettings.btnUpdateGroupClick(Sender: TObject);
var
  Cnt:       integer;
  GroupList: TStringList;

begin
  if not FSettings.Valid then exit;

  GroupList := TStringList.Create;

  try
    GroupList.Sorted        := true;
    GroupList.CaseSensitive := false;
    GroupList.Duplicates    := dupIgnore;
    GroupList.Delimiter     := ';';

    GroupList.AddStrings(lbxGroups.Items);

    // Only update file group data if its name has not changed or if there
    // is no other file group with the same name
    if SameText(GroupList[lbxGroups.ItemIndex], edtNewGroupName.Text) or
       (GroupList.IndexOf(edtNewGroupName.Text) = -1)                 then
    begin
      FSettings.UpdateFileClass(lbxGroups.Items[lbxGroups.ItemIndex],
                                edtNewGroupName.Text,
                                integer(cbxCodepage.Items.Objects[cbxCodepage.ItemIndex]),
                                integer(cbxLanguage.Items.Objects[cbxLanguage.ItemIndex]));

      GroupList.Clear;

      for Cnt := 0 to Pred(FSettings.FileClassCount) do
        GroupList.Add(FSettings.FileClassName[Cnt]);

      lbxGroups.Clear;
      lbxGroups.Items.AddStrings(GroupList);
      lbxGroups.ItemIndex := GroupList.IndexOf(edtNewGroupName.Text);
    end;

    UpdateExtensions;

    PrepareGUI();
    UpdateGUI([btnAddGroup, btnUpdateGroup]);

  finally
    GroupList.Free;
  end;
end;


// Delete a file class
procedure TfrmSettings.btnDeleteGroupClick(Sender: TObject);
begin
  if not FSettings.Valid then exit;

  lbxExtensions.SelectAll;
  btnDeleteExtensionClick(Self);

  FSettings.DeleteFileClass(edtNewGroupName.Text);

  // Reset GUI
  lbxGroups.DeleteSelected;
  edtNewGroupName.Clear;
  cbxCodepage.ItemIndex := -1;
  cbxLanguage.ItemIndex := 0;

  if lbxGroups.Count > 0 then
    lbxGroups.ItemIndex := 0;

  UpdateExtensions;

  PrepareGUI();
  UpdateGUI([btnAddGroup, btnUpdateGroup]);
end;


// Add filename extension(s) to a file class
procedure TfrmSettings.btnAddExtensionClick(Sender: TObject);
var
  I:             integer;
  Cnt:           integer;
  IsValidExt:    boolean;
  Extensions:    TStringDynArray;
  ExtensionList: TStringList;

begin
  if not FSettings.Valid then exit;

  Extensions    := SplitString(edtNewExtension.Text, ';');
  ExtensionList := TStringList.Create;

  try
    ExtensionList.Sorted        := true;
    ExtensionList.CaseSensitive := false;
    ExtensionList.Duplicates    := dupIgnore;
    ExtensionList.Delimiter     := ';';

    ExtensionList.AddStrings(lbxExtensions.Items);

    for Cnt := Low(Extensions) to High(Extensions) do
    begin
      IsValidExt := true;

      // Only accept valid filename extensions
      for I := 1 to Length(Extensions[Cnt]) do
      begin
        if not TPath.IsValidFileNameChar(Extensions[Cnt][I]) then
        begin
          IsValidExt := false;
          break;
        end;
      end;

      if IsValidExt then
      begin
        Extensions[Cnt] := '.' + ReplaceStr(Extensions[Cnt], '.', '');
        if Length(Extensions[Cnt]) > 1 then ExtensionList.Add(Extensions[Cnt]);
      end;
    end;

    // Only update data model if we have a selected file group entry
    if InRange(lbxGroups.ItemIndex, 0, Pred(FSettings.FileClassCount)) then
    begin
      FSettings.SetExtensions(FSettings.FileClassName[lbxGroups.ItemIndex], ExtensionList);

      lbxExtensions.Clear;
      lbxExtensions.Items.AddStrings(ExtensionList);
      lbxExtensions.ItemIndex := ExtensionList.IndexOf(Extensions[0]);
      lbxExtensions.Selected[lbxExtensions.ItemIndex] := true;
    end;

    edtNewExtension.Clear;

    PrepareGUI();
    UpdateGUI([btnAddGroup, btnUpdateGroup]);

  finally
    ExtensionList.Free;
  end;
end;


// Delete filename extension from a file class
procedure TfrmSettings.btnDeleteExtensionClick(Sender: TObject);
begin
  if not FSettings.Valid then exit;

  lbxExtensions.DeleteSelected;
  edtNewExtension.Clear;

  // Only update data model if we have a selected file group entry
  if InRange(lbxGroups.ItemIndex, 0, Pred(FSettings.FileClassCount)) then
    FSettings.SetExtensions(FSettings.FileClassName[lbxGroups.ItemIndex], lbxExtensions.Items);

  if lbxExtensions.Count > 0 then
  begin
    lbxExtensions.ItemIndex := 0;
    lbxExtensions.Selected[lbxExtensions.ItemIndex] := true;
  end;

  PrepareGUI();
  UpdateGUI([btnAddGroup, btnUpdateGroup]);
end;


// Show parameters of selected file class
procedure TfrmSettings.lbxGroupsClick(Sender: TObject);
begin
  UpdateExtensions;

  PrepareGUI();
  UpdateGUI([btnAddGroup, btnUpdateGroup]);
end;


// Change state of GUI controls according to file class name data
procedure TfrmSettings.edtNewGroupNameChange(Sender: TObject);
begin
  UpdateGUI([edtNewGroupName, cbxCodepage, cbxLanguage]);
end;


// Change state of GUI controls according to codepage data
procedure TfrmSettings.cbxCodepageChange(Sender: TObject);
begin
  UpdateGUI([edtNewGroupName, cbxCodepage, cbxLanguage]);
end;


// Change state of GUI controls according to language data
procedure TfrmSettings.cbxLanguageChange(Sender: TObject);
begin
  UpdateGUI([btnAddGroup, edtNewGroupName, cbxCodepage, cbxLanguage]);
end;


// Show filename extension parameters
procedure TfrmSettings.lbxExtensionsClick(Sender: TObject);
begin
  PrepareGUI();
  UpdateGUI([btnAddGroup, btnUpdateGroup]);
end;


// Change state of GUI controls according to filename extension data
procedure TfrmSettings.edtNewExtensionChange(Sender: TObject);
begin
  PrepareGUI();
  UpdateGUI([btnAddGroup, btnUpdateGroup]);
end;


// Close dialog
procedure TfrmSettings.btnCloseClick(Sender: TObject);
begin
  Close;
end;


// -----------------------------------------------------------------------------
// Internal worker methods
// -----------------------------------------------------------------------------

// Store filename extension data in settings data model
procedure TfrmSettings.UpdateExtensions;
begin
  if not FSettings.Valid     then exit;
  if lbxGroups.ItemIndex < 0 then exit;

  lbxExtensions.Clear;
  lbxExtensions.Items.AddStrings(FSettings.FileClassExtensions[lbxGroups.ItemIndex]);

  if FSettings.FileClassExtensions[lbxGroups.ItemIndex].Count > 0 then
  begin
    lbxExtensions.ItemIndex := 0;
    lbxExtensions.Selected[lbxExtensions.ItemIndex] := true;
  end;
end;


// Set state of GUI controls I
procedure TfrmSettings.PrepareGUI;
begin
  btnAddGroup.Enabled    := false;
  btnUpdateGroup.Enabled := false;
end;


// Set state of GUI controls II
procedure TfrmSettings.UpdateGUI(const SkipControls: array of TControl);
begin
  if FInUpdateGUI then exit;

  // Semaphore to lock the following code section
  FInUpdateGUI := true;

  try
    // The array SkipControls can contain controls which should be excluded
    // from GUI update because the caller has already set the state of these
    // controls and doesn't want to get it changed
    if not ArrayContains(SkipControls, edtNewGroupName) then
      if lbxGroups.ItemIndex >= 0 then
        edtNewGroupName.Text     := FSettings.FileClassName[lbxGroups.ItemIndex];

    if not ArrayContains(SkipControls, cbxCodepage) then
      if lbxGroups.ItemIndex >= 0 then
        cbxCodepage.ItemIndex    := cbxCodepage.Items.IndexOfObject(TObject(FSettings.FileClassCodePage[lbxGroups.ItemIndex]));

    if not ArrayContains(SkipControls, cbxLanguage) then
      if lbxGroups.ItemIndex >= 0 then
        cbxLanguage.ItemIndex    := cbxLanguage.Items.IndexOfObject(TObject(FSettings.FileClassLanguage[lbxGroups.ItemIndex]));

    if not ArrayContains(SkipControls, btnAddGroup) then
      btnAddGroup.Enabled        := (edtNewGroupName.Text  <> '')                                              and
                                    ((lbxGroups.ItemIndex = -1) or
                                     not SameText(edtNewGroupName.Text, lbxGroups.Items[lbxGroups.ItemIndex])) and
                                    (cbxCodepage.ItemIndex <> -1);

    if not ArrayContains(SkipControls, btnDeleteGroup) then
      btnDeleteGroup.Enabled     := (lbxGroups.ItemIndex  <> -1);

    if not ArrayContains(SkipControls, btnUpdateGroup) then
      btnUpdateGroup.Enabled     := (lbxGroups.ItemIndex   <> -1) and
                                    (edtNewGroupName.Text  <> '') and
                                    (cbxCodepage.ItemIndex <> -1);

    if not ArrayContains(SkipControls, btnAddExtension) then
      btnAddExtension.Enabled    := (edtNewExtension.Text <> '') and
                                    (lbxGroups.ItemIndex  <> -1);

    if not ArrayContains(SkipControls, btnDeleteExtension) then
      btnDeleteExtension.Enabled := (lbxExtensions.ItemIndex <> -1);

  finally
    // Unlock section
    FInUpdateGUI := false;
  end;
end;


// Check if an array contains a specified GUI control
function TfrmSettings.ArrayContains(const AArray: array of TControl; AItem: TControl): boolean;
var
  Cnt: integer;

begin
  Result := false;

  for Cnt := 0 to Pred(Length(AArray)) do
    if AArray[Cnt] = AItem then exit(true);
end;


end.

