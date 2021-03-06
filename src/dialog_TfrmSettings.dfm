object frmSettings: TfrmSettings
  Left = 300
  Top = 190
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  ClientHeight = 425
  ClientWidth = 418
  Color = clBtnFace
  Constraints.MinHeight = 461
  Constraints.MinWidth = 434
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PopupMode = pmExplicit
  Position = poDefault
  OnCreate = FormCreate
  DesignSize = (
    418
    425)
  PixelsPerInch = 96
  TextHeight = 13
  object lbxGroups: TListBox
    Left = 8
    Top = 8
    Width = 185
    Height = 193
    Anchors = [akLeft, akTop, akBottom]
    ItemHeight = 13
    Sorted = True
    TabOrder = 0
    OnClick = lbxGroupsClick
  end
  object btnAddGroup: TButton
    Left = 24
    Top = 207
    Width = 25
    Height = 25
    Hint = 'Add group'
    Anchors = [akLeft, akBottom]
    Caption = '+'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
    OnClick = btnAddGroupClick
  end
  object btnUpdateGroup: TButton
    Left = 77
    Top = 207
    Width = 46
    Height = 25
    Hint = 'Update group'
    Anchors = [akLeft, akBottom]
    Caption = 'Update'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    OnClick = btnUpdateGroupClick
  end
  object btnDeleteGroup: TButton
    Left = 152
    Top = 207
    Width = 25
    Height = 25
    Hint = 'Delete group'
    Anchors = [akLeft, akBottom]
    Caption = '-'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
    OnClick = btnDeleteGroupClick
  end
  object edtNewGroupName: TLabeledEdit
    Left = 8
    Top = 264
    Width = 185
    Height = 21
    Anchors = [akLeft, akBottom]
    AutoSize = False
    EditLabel.Width = 58
    EditLabel.Height = 13
    EditLabel.Caption = 'Group name'
    TabOrder = 4
    OnChange = edtNewGroupNameChange
  end
  object lblCodepageHeader: TStaticText
    Left = 8
    Top = 296
    Width = 87
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Code page to set'
    FocusControl = cbxCodePage
    ShowAccelChar = False
    TabOrder = 5
  end
  object cbxCodePage: TComboBox
    Left = 8
    Top = 312
    Width = 185
    Height = 21
    AutoDropDown = True
    Style = csOwnerDrawFixed
    Anchors = [akLeft, akBottom]
    ItemHeight = 15
    TabOrder = 6
    OnChange = cbxCodepageChange
  end
  object lblLanguageHeader: TStaticText
    Left = 8
    Top = 344
    Width = 96
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Expected language'
    FocusControl = cbxLanguage
    ShowAccelChar = False
    TabOrder = 7
  end
  object cbxLanguage: TComboBox
    Left = 8
    Top = 360
    Width = 185
    Height = 21
    AutoDropDown = True
    Style = csOwnerDrawFixed
    Anchors = [akLeft, akBottom]
    ItemHeight = 15
    TabOrder = 8
    OnChange = cbxLanguageChange
  end
  object lbxExtensions: TListBox
    Left = 224
    Top = 8
    Width = 185
    Height = 193
    Anchors = [akTop, akRight, akBottom]
    ItemHeight = 13
    MultiSelect = True
    Sorted = True
    TabOrder = 9
    OnClick = lbxExtensionsClick
  end
  object edtNewExtension: TLabeledEdit
    Left = 224
    Top = 264
    Width = 185
    Height = 21
    Hint = 'Separate multiple extensions by semicolon'
    Anchors = [akRight, akBottom]
    AutoSize = False
    CharCase = ecUpperCase
    EditLabel.Width = 127
    EditLabel.Height = 13
    EditLabel.Caption = 'New filename extension(s)'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 12
    OnChange = edtNewExtensionChange
  end
  object btnAddExtension: TButton
    Left = 240
    Top = 207
    Width = 25
    Height = 25
    Hint = 'Add extension'
    Anchors = [akRight, akBottom]
    Caption = '+'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 10
    OnClick = btnAddExtensionClick
  end
  object btnDeleteExtension: TButton
    Left = 368
    Top = 207
    Width = 25
    Height = 25
    Hint = 'Delete extension'
    Anchors = [akRight, akBottom]
    Caption = '-'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 11
    OnClick = btnDeleteExtensionClick
  end
  object btnClose: TButton
    Left = 314
    Top = 392
    Width = 95
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Close'
    TabOrder = 13
    OnClick = btnCloseClick
  end
end
