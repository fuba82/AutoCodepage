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

unit VclExtend;


interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.StrUtils, System.Math,
  System.Types, System.UITypes, System.Classes, VCL.Graphics, Vcl.Controls,
  Vcl.StdCtrls, Vcl.Forms;


const
  // When an entry is added to the combobox element list with Items.AddObject(...)
  // one can pass this value as parameter AObject to indicate that the entry
  // represents a group header. Unmarked entries are treated as group member
  // entries and get indented by the value (in pixels) of new property "Indent".
  C_GROUP_HDR = -MaxInt;


type
  //
  // Interceptor class for TComboBox to add a grouping functionality.
  // To use this feature one must set the "Style" property of the combobox to
  // csOwnerDrawFixed.
  //
  TComboBox = class(Vcl.StdCtrls.TComboBox)
  strict private const
    // Default values for entry text indentation
    C_STD_MIN_INDENT = 1;
    C_STD_EXT_INDENT = 10;

  strict private
    FStdIndent: integer;
    FIndent:    integer;

    procedure   SetIndent(Value: integer);

    function    NextItemIsDisabled: boolean;
    function    PrevItemIsDisabled: boolean;
    procedure   SelectNextEnabledItem;
    procedure   SelectPrevEnabledItem;
    procedure   KillMessages;

  strict protected
    procedure   WndProc(var Message: TMessage); override;
    procedure   DrawItem(Index: Integer; Rect: TRect; State: TOwnerDrawState); override;
    procedure   CloseUp; override;

  public
    constructor Create(AOwner: TComponent); override;

    property    Indent: integer read FIndent write SetIndent;

  end;



implementation


// =============================================================================
// Interceptor class for TComboBox
// =============================================================================

// -----------------------------------------------------------------------------
// Create / Destroy
// -----------------------------------------------------------------------------

constructor TComboBox.Create(AOwner: TComponent);
begin
  inherited;

  // Init indentation with default values
  FStdIndent := C_STD_MIN_INDENT;
  Indent     := C_STD_EXT_INDENT;
end;


// -----------------------------------------------------------------------------
// Overridden methods
// -----------------------------------------------------------------------------

// Hook message pump
procedure TComboBox.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_KEYDOWN:
    case Message.WParam of
      // If "Down arrow" pressed set focus to next selectable entry downwards
      VK_DOWN:
      if NextItemIsDisabled then
      begin
        SelectNextEnabledItem;
        KillMessages;
        exit;
      end;

      // If "Up arrow" pressed set focus to next selectable entry upwards
      VK_UP:
      if PrevItemIsDisabled then
      begin
        SelectPrevEnabledItem;
        KillMessages;
        exit;
      end;
    end;
  end;

  // Call inherited method in original TComboBox class
  inherited;
end;


// Draw an item of the combobox's list box entries
procedure TComboBox.DrawItem(Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  NewColor:    TColor;
  OrgColorBkg: TColorRef;
  OrgColorFrg: TColorRef;
  OrgRect:     TRect;

begin
  // Taken from the DrawItem implementation in original TComboBox class
  TControlCanvas(Canvas).UpdateTextFlags;

  // Select background color depending on the entry to draw:
  //   - Group header entries and not selected group member entries get the color
  //     of the combobox property "Color"
  //   - Selected group member entries get the system color for highlighted
  //     elements
  if (integer(Items.Objects[Index]) <> C_GROUP_HDR) and
     (odSelected in State)
    then NewColor := clHighlight
    else NewColor := Color;

  // Set DC brush to above color and save the original color
  OrgColorBkg := SetDCBrushColor(Canvas.Handle, ColorToRGB(NewColor));

  // Draw rectangle filled with the color of the DC brush
  FillRect(Canvas.Handle, Rect, GetStockObject(DC_BRUSH));

  // Restore DC brush's color
  SetDCBrushColor(Canvas.Handle, OrgColorBkg);

  // Set DC background color to the same color like above and save the original one
  OrgColorBkg := SetBkColor(Canvas.Handle, ColorToRGB(NewColor));

  // Select text color depending on the entry to draw:
  //   - Group header entries are grey
  //   - Not selected group member entries get the color set in the combobox
  //     property "Font.Color"
  //   - Selected group member entries get the system color for highlighted
  //     text
  if (integer(Items.Objects[Index]) <> C_GROUP_HDR)
    then NewColor := IfThen(odSelected in State, clHighlightText, Font.Color)
    else NewColor := clGrayText;

  // Set text color to above color and save the original color
  OrgColorFrg := SetTextColor(Canvas.Handle, ColorToRGB(NewColor));

  // Save the original rectangle to draw the text in
  OrgRect := Rect;

  // Set text indentation depending on the entry to draw:
  //   - Group header entries and text in the edit area of the combobox get
  //     the internal standard indentation
  //   - Group member entries get the internal standard indentation and
  //     additionally a user configurable one
  if (integer(Items.Objects[Index]) <> C_GROUP_HDR) and
     not (odComboBoxEdit in State)
    then Inc(Rect.Left, FIndent)
    else Inc(Rect.Left, FStdIndent);

  // Draw text
  DrawText(Canvas.Handle,
           PChar(Items[Index]),
           Length(Items[Index]),
           Rect,
           DT_SINGLELINE or DT_LEFT or DT_VCENTER or DT_END_ELLIPSIS);

  // Restore Text and background color to their original values
  SetTextColor(Canvas.Handle, OrgColorFrg);
  SetBkColor(Canvas.Handle, OrgColorBkg);

  // Draw a focus rectangle around focused entries. Because the calling VCL
  // code does the same Win32 API call and this routine draws in XOR mode
  // the rectangle will get erased.
  if (odFocused in State) then
    DrawFocusRect(Canvas.Handle, OrgRect);

  // Call user defined event handler
  if Assigned(OnDrawItem) then
    OnDrawItem(Self, Index, OrgRect, State);
end;


// Called when combobox's list box closes up
procedure TComboBox.CloseUp;
begin
  // If the user selected a group header entry with the mouse
  // delete the selection and beep
  if (ItemIndex <> -1) and (integer(Items.Objects[ItemIndex]) = C_GROUP_HDR) then
  begin
    ItemIndex := -1;
    Beep;
  end;

  // Call user defined event handler
  if Assigned(OnCloseUp) then
    OnCloseUp(Self);
end;


// -----------------------------------------------------------------------------
// Getter / Setter
// -----------------------------------------------------------------------------

// Set user defined indentation for non-group entries
procedure TComboBox.SetIndent(Value: integer);
begin
  FIndent := FStdIndent + Value;
end;


// -----------------------------------------------------------------------------
// Internal worker methods
// -----------------------------------------------------------------------------

// Check if next item downwards is a group header
function TComboBox.NextItemIsDisabled: boolean;
begin
  Result := (ItemIndex < Items.Count - 1) and
            (integer(Items.Objects[ItemIndex + 1]) = C_GROUP_HDR);
end;


// Check if next item upwards is a group header
function TComboBox.PrevItemIsDisabled: boolean;
begin
  Result := (ItemIndex > 0) and
            (integer(Items.Objects[ItemIndex - 1]) = C_GROUP_HDR);
end;


// Select next group member item downwards
procedure TComboBox.SelectNextEnabledItem;
var
  i: Integer;

begin
  for i := ItemIndex + 1 to Items.Count - 1 do
    if integer(Items.Objects[i]) <> C_GROUP_HDR then
    begin
      ItemIndex := i;
      exit;
    end;

  Beep;
end;


// Select next group member item upwards
procedure TComboBox.SelectPrevEnabledItem;
var
  i: Integer;

begin
  for i := ItemIndex - 1 downto 0 do
    if integer(Items.Objects[i]) <> C_GROUP_HDR then
    begin
      ItemIndex := i;
      exit;
    end;

  Beep;
end;


// Empty message queue
procedure TComboBox.KillMessages;
var
  msg: TMsg;

begin
  while PeekMessage(msg, Handle, WM_KEYFIRST, WM_KEYLAST, PM_REMOVE) do;
end;


end.
