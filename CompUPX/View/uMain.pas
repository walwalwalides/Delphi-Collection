{ ============================================
  Software Name : 	CompUPX
  ============================================ }
{ ******************************************** }
{ Written By WalWalWalides }
{ CopyRight � 2019 }
{ Email : WalWalWalides@gmail.com }
{ GitHub :https://github.com/walwalwalides }
{ ******************************************** }

unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.Actions,
  Vcl.ActnList, Vcl.Menus, System.ImageList, Vcl.ImgList, Vcl.ComCtrls,
  Vcl.ExtCtrls, IniFiles;

type
  TSortOptions = record
    SortColumn: Integer;
    SortDescending: Boolean;
  end;

  Tmode = (modSingle, modMulti);
  TActe = (ActComp, ActDecom);
  TColumnType = (ctText, ctColor, ctProgress);

  TfrmMain = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    OpenFiles1: TMenuItem;
    OpenFolders1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    ActionList1: TActionList;
    actOpenFile: TAction;
    actOpenFolder: TAction;
    actExit: TAction;
    dlgFileOpen: TFileOpenDialog;
    dlgFolderOpen: TFileOpenDialog;
    lvFiles: TListView;
    ilSmall: TImageList;
    ilLarge: TImageList;
    actShowInExplorer: TAction;
    PopupMenu1: TPopupMenu;
    OpeninExplorer1: TMenuItem;
    StatusBar1: TStatusBar;
    actCopyToClipboard: TAction;
    Edit1: TMenuItem;
    CopytoClipboard1: TMenuItem;
    N2: TMenuItem;
    CopytoClipboard2: TMenuItem;
    View1: TMenuItem;
    actRefresh: TAction;
    Refresh1: TMenuItem;
    A1: TMenuItem;
    C1: TMenuItem;
    D1: TMenuItem;
    Option1: TMenuItem;
    actCompress: TAction;
    actOption: TAction;
    actDecompress: TAction;
    actOption1: TMenuItem;
    actAbout: TAction;
    A2: TMenuItem;
    actAbout1: TMenuItem;
    procedure actExitExecute(Sender: TObject);
    procedure actOpenFileExecute(Sender: TObject);
    procedure actOpenFolderExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvFilesColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvFilesCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure actShowInExplorerExecute(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure actCopyToClipboardExecute(Sender: TObject);
    procedure actRefreshExecute(Sender: TObject);
    procedure actCompressExecute(Sender: TObject);
    procedure actDecompressExecute(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure actOptionExecute(Sender: TObject);
    procedure dlgFolderOpenFileOkClick(Sender: TObject; var CanClose: Boolean);
    procedure actAboutExecute(Sender: TObject);
    procedure lvFilesCustomDrawSubItem(Sender: TCustomListView; Item: TListItem; SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvFilesDrawItem(Sender: TCustomListView; Item: TListItem; Rect: TRect; State: TOwnerDrawState);
  private
    FSourceFileList: TStringList;
    FWorkingFileList: TStringList;
    FInterestingFileCount: Integer;
    FSortOptions: TSortOptions;
    FCanceled: Boolean;

    function CompareFileSize(const ASize1, ASize2: string): Integer;
    procedure FindInterestingFiles;
    procedure OnCancelEvent(Sender: TObject);
    procedure ProcessWorkingFileList;
    procedure UpdateFileCount(const aFileCount: Integer);
  protected
    procedure WMDropFiles(var Msg: TMessage); message WM_DROPFILES;
  public
  end;

var
  frmMain: TfrmMain;
  UPXPath, INIPath, Parameters: String;
  iCompress: Integer;
  BoolBrute: Boolean;
  BoolUBrute: Boolean;
  BoolRes: Boolean;
  BoolExport: Boolean;
  BoolReloc: Boolean;
  iIcones: Integer;
  BoolCompat: Boolean;
  BoolForce: Boolean;
  BoolBackup: Boolean;

implementation

{$R *.dfm}

uses
  System.Types, System.Diagnostics, System.IOUtils, System.Math, Winapi.ShellAPI,
  Vcl.Clipbrd,
  uProgress, uFileChecker, uFileUtils, uOption, uAbout,
  Vcl.Themes,
  Vcl.GraphUtil;

var
  sActualFile: string;
  ArrActualFile: array of string;
  openMode: Tmode;
  MyAct: TActe;
  Boolini: Boolean = true;

  // TfrmMain
  // ============================================================================
procedure TfrmMain.FormActivate(Sender: TObject);
var
  INI: TIniFile;
begin
  INI := TIniFile.Create(INIPath + ChangeFileExt(ExtractFileName(Application.ExeName), '.ini'));

  iCompress := INI.ReadInteger('Options', 'Compression', 7);
  BoolBrute := INI.ReadBool('Options', 'Brute', False);
  BoolUBrute := INI.ReadBool('Options', 'UBrute', False);
  BoolRes := INI.ReadBool('Options', 'Ressources', true);
  BoolExport := INI.ReadBool('Options', 'Exports', true);
  BoolReloc := INI.ReadBool('Options', 'Relocations', true);
  iIcones := INI.ReadInteger('Options', 'Icones', 2);
  BoolCompat := INI.ReadBool('Options', 'Compatibilite', False);
  BoolForce := INI.ReadBool('Options', 'Force', False);
  BoolBackup := INI.ReadBool('Options', 'Backup', False);

  INI.Free;

end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  lvFiles.OwnerDraw := true;
  lvFiles.ViewStyle := TViewStyle.vsReport;

  frmMain.Position := poMainFormCenter;
  frmMain.WindowState := wsMaximized;
  FSourceFileList := TStringList.Create;
  FSourceFileList.CaseSensitive := False;
  FSourceFileList.Sorted := true;
  FSourceFileList.Duplicates := dupIgnore;

  FWorkingFileList := TStringList.Create;
  FWorkingFileList.Capacity := 1000;
  FWorkingFileList.CaseSensitive := False;
  FWorkingFileList.Sorted := true;
  FWorkingFileList.Duplicates := dupIgnore;

  DragAcceptFiles(Handle, true);

  FSortOptions.SortColumn := 1;
  FSortOptions.SortDescending := False;

  INIPath := ExtractFilePath(Application.ExeName);
  UPXPath := INIPath + 'upx.exe';
  if not FileExists(UPXPath) then
    MessageDlg('"UPX.exe"  file not found !', mtWarning, [mbOK], 0);

end;

// ----------------------------------------------------------------------------
procedure TfrmMain.FormDestroy(Sender: TObject);
var
  INI: TIniFile;
begin
  INI := TIniFile.Create(INIPath + ChangeFileExt(ExtractFileName(Application.ExeName), '.ini'));

  // INI.WriteString('Options', 'LastFile', LoaderString.Text);

  INI.WriteInteger('Options', 'Compression', iCompress);
  INI.WriteBool('Options', 'Brute', BoolBrute);
  INI.WriteBool('Options', 'UBrute', BoolUBrute);
  INI.WriteBool('Options', 'Ressources', BoolRes);
  INI.WriteBool('Options', 'Exports', BoolExport);
  INI.WriteBool('Options', 'Relocations', BoolReloc);
  INI.WriteInteger('Options', 'Icones', iIcones);
  INI.WriteBool('Options', 'Compatibilite', BoolCompat);
  INI.WriteBool('Options', 'Force', BoolForce);
  INI.WriteBool('Options', 'Backup', BoolBackup);

  INI.Free;

  FSourceFileList.Free;
  FWorkingFileList.Free;

  DragAcceptFiles(Handle, False);
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.lvFilesColumnClick(Sender: TObject; Column: TListColumn);
begin
  if Column.Index = FSortOptions.SortColumn then
    FSortOptions.SortDescending := not FSortOptions.SortDescending
  else
  begin
    FSortOptions.SortColumn := Column.Index;
    FSortOptions.SortDescending := False;
  end;

  lvFiles.AlphaSort;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.lvFilesCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  if FSortOptions.SortColumn = 0 then
    Compare := CompareText(Item1.Caption, Item2.Caption)
  else if FSortOptions.SortColumn = 4 then
    Compare := CompareFileSize(Item1.SubItems[FSortOptions.SortColumn - 1], Item2.SubItems[FSortOptions.SortColumn - 1])
  else
    Compare := CompareText(Item1.SubItems[FSortOptions.SortColumn - 1], Item2.SubItems[FSortOptions.SortColumn - 1]);

  if FSortOptions.SortDescending then
    Compare := -Compare;
end;

// ----------------------------------------------------------------------------
function isMatch(const stext: String): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := Low(ArrActualFile) to High(ArrActualFile) do
    if ArrActualFile[i] = stext then
    begin
      Result := true;
      break;
    end;
end;

procedure TfrmMain.lvFilesCustomDrawSubItem(Sender: TCustomListView; Item: TListItem; SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
begin

  if (openMode = modSingle) then
  begin

    if ((SubItem = 8) and (Item.SubItems.Count > 1)) then
    begin
      if (Item.Caption = sActualFile) then
      begin
        if (MyAct = ActComp) then
           Sender.Canvas.Brush.Color := $CCFFCC;
        if (MyAct = ActDecom) then
          Sender.Canvas.Brush.Color := $FFCCCC;
      end
      else
      begin
        Sender.Canvas.Brush.Color := $CCCCFF;
      end;
    end
    else
    begin
      // Sender.Canvas.Brush.Color := $000000;
      Sender.Canvas.Brush.Color := TListView(Sender).Color;
    end;
  end;

  if (openMode = modMulti) then
  begin

    if ((SubItem = 8) and (Item.SubItems.Count > 1)) then
    begin
      if (isMatch(Item.Caption)) then
      begin
        if (MyAct = ActComp) then
          Sender.Canvas.Brush.Color := $CCFFCC;
        if (MyAct = ActDecom) then
          Sender.Canvas.Brush.Color := $FFCCCC;
      end
      else
      begin
        Sender.Canvas.Brush.Color := $CCCCFF;
      end;
    end
    else
    begin
      // Sender.Canvas.Brush.Color := $000000;
      Sender.Canvas.Brush.Color := TListView(Sender).Color;
    end;
  end;

  if (Boolini = true) then
  begin
    if ((SubItem = 8) and (Item.SubItems.Count > 1)) then
    begin
      Sender.Canvas.Brush.Color := $FFFFFF;
      // Sender.Canvas.Brush.Color := TListView(Sender).Color;
    end;
  end;

end;

function ResizeRect(const ARect: TRect; const DxLeft, DxRight, DyTop, DyBottom: Integer): TRect;
begin
  Result := ARect;
  Inc(Result.Left, DxLeft);
  Dec(Result.Right, DxRight);
  Inc(Result.Top, DyTop);
  Dec(Result.Bottom, DyBottom);
end;

procedure TfrmMain.lvFilesDrawItem(Sender: TCustomListView; Item: TListItem; Rect: TRect; State: TOwnerDrawState);
const
  ListView_Padding = 5;
var
  LRect, LRect2: TRect;
  i, p: Integer;
  LText: string;
  LSize: TSize;
  LDetails: TThemedElementDetails;
  LTextFormat: TTextFormatFlags;
  LColor: TColor;
  LStyleService: TCustomStyleServices;
  LColummnType: TColumnType;
begin
  LStyleService := StyleServices;
  if not LStyleService.Enabled then
    exit;

  Sender.Canvas.Brush.Style := bsSolid;
  Sender.Canvas.Brush.Color := LStyleService.GetSystemColor(clWindow);
  Sender.Canvas.FillRect(Rect);

  LRect := Rect;

  for i := 0 to TListView(Sender).Columns.Count - 1 do
  begin
    LColummnType := TColumnType(TListView(Sender).Columns[i].Tag);
    LRect.Right := LRect.Left + Sender.Column[i].Width;

    LText := '';
    if i = 0 then
      LText := Item.Caption
    else if (i - 1) <= Item.SubItems.Count - 1 then
      LText := Item.SubItems[i - 1];

    case LColummnType of
      ctColor:
        begin
          LDetails := LStyleService.GetElementDetails(tgFixedCellHot);
          LColor := LStyleService.GetSystemColor(clred);
          if (Item.SubItems[8]='100') then
          begin
            LDetails := LStyleService.GetElementDetails(tgFixedCellLast);
            LColor := LStyleService.GetSystemColor(clGreen);
            LStyleService.DrawElement(Sender.Canvas.Handle, LDetails, LRect);

          end;

          LRect2 := LRect;
          LRect2.Left := LRect2.Left + ListView_Padding;

          LTextFormat := TTextFormatFlags(DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_END_ELLIPSIS);
          LStyleService.DrawText(Sender.Canvas.Handle, LDetails, LText, LRect2, LTextFormat, LColor);

        end;

      ctText:
        begin

          LDetails := LStyleService.GetElementDetails(tgCellNormal);
          LColor := LStyleService.GetSystemColor(clWindowText);
          if ([odSelected, odHotLight] * State <> []) then
          begin
            LDetails := LStyleService.GetElementDetails(tgCellSelected);
            LColor := LStyleService.GetSystemColor(clHighlightText);
            LStyleService.DrawElement(Sender.Canvas.Handle, LDetails, LRect);
          end;

          LRect2 := LRect;
          LRect2.Left := LRect2.Left + ListView_Padding;

          LTextFormat := TTextFormatFlags(DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
          LStyleService.DrawText(Sender.Canvas.Handle, LDetails, LText, LRect2, LTextFormat, LColor);
        end;

      ctProgress:
        begin
          if ([odSelected, odHotLight] * State <> []) then
          begin
            LDetails := LStyleService.GetElementDetails(tgCellSelected);
            LStyleService.DrawElement(Sender.Canvas.Handle, LDetails, LRect);
          end;

          LRect2 := ResizeRect(LRect, 2, 2, 2, 2);
          LDetails := LStyleService.GetElementDetails(tpBar);
          LStyleService.DrawElement(Sender.Canvas.Handle, LDetails, LRect2);

          if not TryStrToInt(LText, p) then
            p := 0;

          InflateRect(LRect2, -1, -1);
          LRect2.Right := LRect2.Left + Round(LRect2.Width * p / 100);

          if p < 20 then
          begin
            Sender.Canvas.Brush.Style := bsSolid;
            Sender.Canvas.Brush.Color := clWebFirebrick;
            Sender.Canvas.FillRect(LRect2);
          end
          else if p < 50 then
          begin
            Sender.Canvas.Brush.Style := bsSolid;
            Sender.Canvas.Brush.Color := clWebGold;
            Sender.Canvas.FillRect(LRect2);
          end
          else
          begin
            LDetails := LStyleService.GetElementDetails(tpChunk);
            LStyleService.DrawElement(Sender.Canvas.Handle, LDetails, LRect2);
          end;
        end;
    end;
    Inc(LRect.Left, Sender.Column[i].Width);
  end;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.OnCancelEvent(Sender: TObject);
begin
  FCanceled := true;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.actAboutExecute(Sender: TObject);

var
  F: TfrmAbout;
begin

  if not Assigned(F) then
    Application.CreateForm(TfrmAbout, F);
  F.Position := poMainFormCenter;
  try
    F.ShowModal;
  finally
    FreeAndNil(F);
  end;
end;

procedure TfrmMain.actCompressExecute(Sender: TObject);
var
  i, k: Integer;
  sChooseComFile: string;
  iRepeat: Cardinal;
  T: Integer;
  ipos: Integer;
begin
  fillchar(ArrActualFile, sizeOf(ArrActualFile), 0);
  SetLength(ArrActualFile, FInterestingFileCount);
  MyAct := ActComp;

  Boolini := False;
  lvFiles.Repaint;
  lvFiles.Update;

  Parameters := '';

  if (BoolUBrute = true) then
    Parameters := Parameters + ' --ultra-brute'
  else if (BoolBrute = true) then
    Parameters := Parameters + ' --brute'
  else if (iCompress = 10) then
    Parameters := Parameters + ' --best'
    // value of ratio de compression ( 1 to 9 )
  else
    Parameters := Parameters + ' -' + IntToStr(iCompress);

  if (BoolRes = true) then
    Parameters := Parameters + ' --compress-resources=1'
  else
    Parameters := Parameters + ' --compress-resources=0';

  if (BoolExport = true) then
    Parameters := Parameters + ' --compress-exports=1'
  else
    Parameters := Parameters + ' --compress-exports=0';

  if (BoolReloc = true) then
    Parameters := Parameters + ' --strip-relocs=1'
  else
    Parameters := Parameters + ' --strip-relocs=0';

  Parameters := Parameters + ' --compress-icons=' + IntToStr(iIcones);

  if (BoolCompat = true) then
    Parameters := Parameters + ' --8086';
  if (BoolForce = true) then
    Parameters := Parameters + ' --force';
  if (BoolBackup = true) then
    Parameters := Parameters + ' --backup'
  else
    Parameters := Parameters + ' --no-backup';
  for i := 0 to lvFiles.Items.Count - 1 do
  begin
    sChooseComFile := '';
    T := 0;
    ipos := 0;
    sChooseComFile := lvFiles.Items[i].SubItems[0] + lvFiles.Items[i].Caption;
    if (sChooseComFile <> '') then
    begin
      ipos := pos('.', lvFiles.Items[i].SubItems[3]);
      T := StrToInt(copy(lvFiles.Items[i].SubItems[3], 0, ipos - 1));
      try
      iRepeat := ShellExecute(GetDesktopWindow, 'open', PChar(UPXPath), PChar('"' + UPXPath + '"' + Parameters + ' ' + '"' + PChar(sChooseComFile) + '"'),
        nil, SW_HIDE);
      except;
        Screen.Cursor := crDefault;
        exit;
      end;
      if (iRepeat > 0) then
      begin
        lvFiles.Items[i].SubItems[7] := 'Process';
        k := 0;
        repeat

          Application.ProcessMessages;
          StatusBar1.Panels[0].text := 'Filename : ' + lvFiles.Items[i].Caption;
          if (Round(k div (T + iCompress)) <= 99) then
          begin
            StatusBar1.Panels[1].text := Format('Status : Compressing %d %% - Please Wait... ', [Round(k div (T + iCompress))]);

            lvFiles.Items[i].SubItems[8] := Round(k div (T + iCompress)).ToString;
          end;
          Inc(k);
        until not processExists('UPX.exe');

        if (openMode = modMulti) then
        begin
          ArrActualFile[i] := lvFiles.Items[i].Caption;

        end;

        if (openMode = modSingle) then
        begin
          sActualFile := lvFiles.Items[i].Caption;

        end;
        lvFiles.Items[i].SubItems[8] := '100';
        lvFiles.Items[i].SubItems[7] := 'Finish';
        StatusBar1.Panels[0].text := 'Filename : ' + lvFiles.Items[i].Caption;
        StatusBar1.Panels[1].text := 'Status: Finish';
        lvFiles.Repaint;
        lvFiles.Update;
      end;
    end;
    if ((iRepeat > 0) and (i = lvFiles.Items.Count - 1)) then
    begin
      StatusBar1.Panels[0].text := 'Success';
      StatusBar1.Panels[1].text := 'Compression Process Finished.';
    end;
  end;
end;

procedure TfrmMain.actCopyToClipboardExecute(Sender: TObject);
var
  s: string;
  LColumnIndex: Integer;
  LRowIndex: Integer;
  LCSVList: TStringList;
begin
  LCSVList := TStringList.Create;
  try
    LCSVList.BeginUpdate;
    try
      for LColumnIndex := 0 to lvFiles.Columns.Count - 1 do
      begin
        if s <> '' then
          s := s + ',';
        s := s + AnsiQuotedStr(Trim(lvFiles.Columns[LColumnIndex].Caption), '"');
      end;
      LCSVList.Add(s);

      for LRowIndex := 0 to lvFiles.Items.Count - 1 do
      begin
        s := AnsiQuotedStr(lvFiles.Items[LRowIndex].Caption, '"');
        for LColumnIndex := 1 to lvFiles.Columns.Count - 1 do
        begin
          s := s + ',' + AnsiQuotedStr(Trim(lvFiles.Items[LRowIndex].SubItems[LColumnIndex - 1]), '"');
        end;
        LCSVList.Add(s);
      end;

      Clipboard.AsText := LCSVList.text;
    finally
      LCSVList.EndUpdate;
    end;
  finally
    LCSVList.Free();
  end;
end;

procedure TfrmMain.actDecompressExecute(Sender: TObject);
var
  iRepeat: Cardinal;
  sChooseDecFile: string;
  i, k: Integer;
  ipos: Integer;
  T: Integer;
begin
  fillchar(ArrActualFile, sizeOf(ArrActualFile), 0);
  SetLength(ArrActualFile, FInterestingFileCount);

  MyAct := ActDecom;
  Boolini := False;
  lvFiles.Repaint;
  lvFiles.Update;

  Parameters := ' -d';
  if (BoolBackup = true) then
  begin
    Parameters := Parameters + ' --backup';
  end
  else
    Parameters := Parameters + ' --no-backup';

  for i := 0 to lvFiles.Items.Count - 1 do
  begin
    sChooseDecFile := '';
    T := 0;
    ipos := 0;
    sChooseDecFile := lvFiles.Items[i].SubItems[0] + lvFiles.Items[i].Caption;

    if (sChooseDecFile <> '') then
    begin

      ipos := pos('.', lvFiles.Items[i].SubItems[3]);
      T := StrToInt(copy(lvFiles.Items[i].SubItems[3], 0, ipos - 1));
      try
        iRepeat := ShellExecute(GetDesktopWindow, 'open', PChar(UPXPath), PChar('"' + UPXPath + '"' + Parameters + ' ' + '"' + PChar(sChooseDecFile) + '"'),
        nil, SW_HIDE);
      except
         Screen.Cursor := crDefault;
         exit
      end;
      if (iRepeat > 0) then
      begin
        Screen.Cursor := crHourGlass;
        k := 0;
        repeat
          lvFiles.Items[i].SubItems[7] := 'Process';
          Application.ProcessMessages;
          StatusBar1.Panels[0].text := 'Filename : ' + lvFiles.Items[i].Caption;
          if (Round(k div (T - iCompress)) <= 99) then
          begin
            StatusBar1.Panels[1].text := Format('Status : Decompressing %d %% - Please Wait... ', [Round(k div (T - iCompress))]);
            lvFiles.Items[i].SubItems[8] := Round(k div (T - iCompress)).ToString;

          end;
          Inc(k);
        until not processExists('UPX.exe');

        if (openMode = modMulti) then
          ArrActualFile[i] := lvFiles.Items[i].Caption;

        if (openMode = modSingle) then
          sActualFile := lvFiles.Items[i].Caption;

        lvFiles.Items[i].SubItems[8] := '100';
        lvFiles.Items[i].SubItems[7] := 'Finish';
        StatusBar1.Panels[0].text := 'Filename : ' + lvFiles.Items[i].Caption;
        StatusBar1.Panels[1].text := 'Status : Finish';
        lvFiles.Repaint;
        lvFiles.Update;
      end;

    end;
    if ((iRepeat > 0) and (i = lvFiles.Items.Count - 1)) then
    begin
      StatusBar1.Panels[0].text := 'Success';
      StatusBar1.Panels[1].text := 'Decompression Process Finished.';
      Screen.Cursor := crDefault;
    end;
  end;

  Screen.Cursor := crDefault;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.actExitExecute(Sender: TObject);
begin
  Close;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.actOpenFileExecute(Sender: TObject);
begin
  if dlgFileOpen.Execute then
  begin
    openMode := modSingle;
    FSourceFileList.Assign(dlgFileOpen.Files);
    FindInterestingFiles;
  end;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.actOpenFolderExecute(Sender: TObject);
begin
  if dlgFolderOpen.Execute then
  begin
    openMode := modMulti;
    FSourceFileList.Assign(dlgFolderOpen.Files);
    FindInterestingFiles;
  end;
end;

procedure TfrmMain.actOptionExecute(Sender: TObject);
var
  F: TfrmOption;
begin
  Application.CreateForm(TfrmOption, F);
  F.Position := poMainFormCenter;

  F.CompressionBar.Position := iCompress;
  F.BruteBox.Checked := BoolBrute;
  F.UBruteBox.Checked := BoolUBrute;
  F.RessourcesBox.Checked := BoolRes;
  F.ExportsBox.Checked := BoolExport;
  F.RelocsBox.Checked := BoolReloc;
  F.IconesBox.ItemIndex := iIcones;
  F.CompatibiliteBox.Checked := BoolCompat;
  F.ForceBox.Checked := BoolForce;
  F.BackupBox.Checked := BoolBackup;

  try
    if F.ShowModal = mrOk then
    begin

      iCompress := F.CompressionBar.Position;
      BoolBrute := F.BruteBox.Checked;
      BoolUBrute := F.UBruteBox.Checked;
      BoolRes := F.RessourcesBox.Checked;
      BoolExport := F.ExportsBox.Checked;
      BoolReloc := F.RelocsBox.Checked;
      iIcones := F.IconesBox.ItemIndex;
      BoolCompat := F.CompatibiliteBox.Checked;
      BoolForce := F.ForceBox.Checked;
      BoolBackup := F.BackupBox.Checked;

    end;
  finally

    F.Release;
  end;

end;

// ----------------------------------------------------------------------------
procedure TfrmMain.actRefreshExecute(Sender: TObject);
begin
  if FSourceFileList.Count > 0 then
    FindInterestingFiles;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.actShowInExplorerExecute(Sender: TObject);
var
  LFileName: string;
  LParameter: string;
  LSelectedItem: TListItem;
begin
  LSelectedItem := lvFiles.Selected;

  if Assigned(LSelectedItem) then
  begin
    LFileName := LSelectedItem.SubItems[0] + LSelectedItem.Caption;
    LParameter := Format('/select,"%s"', [LFileName]);
    ShellExecute(Application.Handle, 'open', 'explorer.exe', PChar(LParameter), nil, SW_NORMAL);
  end;
end;

// ----------------------------------------------------------------------------
function TfrmMain.CompareFileSize(const ASize1, ASize2: string): Integer;
var
  s: string;
  LFileSize1, LFileSize2: Integer;
begin
  s := copy(ASize1, 1, Length(ASize1) - 3);
  s := StringReplace(s, ',', '', [rfReplaceAll]);
  LFileSize1 := StrToInt(s);

  s := copy(ASize2, 1, Length(ASize2) - 3);
  s := StringReplace(s, ',', '', [rfReplaceAll]);
  LFileSize2 := StrToInt(s);

  Result := CompareValue(LFileSize1, LFileSize2);
end;

procedure TfrmMain.dlgFolderOpenFileOkClick(Sender: TObject; var CanClose: Boolean);
begin

end;

// ----------------------------------------------------------------------------
procedure TfrmMain.PopupMenu1Popup(Sender: TObject);
begin
  actShowInExplorer.Enabled := Assigned(lvFiles.Selected);
  actCopyToClipboard.Enabled := lvFiles.Items.Count > 0;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.FindInterestingFiles;
var
  LStopwatch: TStopwatch;
begin
  FCanceled := False;

  frmProgress.OnCancel := OnCancelEvent;
  frmProgress.Show;
  frmProgress.Start;
  frmProgress.DisableCancel;

  FInterestingFileCount := 0;
  UpdateFileCount(FInterestingFileCount);
  StatusBar1.Update;
  frmProgress.EnableCancel;

  lvFiles.Clear;
  ilSmall.Clear;
  ilLarge.Clear;
  Application.ProcessMessages;

  LStopwatch := TStopwatch.StartNew;
  FWorkingFileList.BeginUpdate;
  try
    FWorkingFileList.Clear;
    FindExecutableFiles(FSourceFileList, FWorkingFileList);
    LStopwatch.Stop;
  finally
    FWorkingFileList.EndUpdate;
  end;

  if FWorkingFileList.Count = 0 then
    frmProgress.Log(Format('No executable files found (%.0n ms)', [LStopwatch.ElapsedMilliseconds + 0.0]))
  else
    frmProgress.Log(Format('%.0n executable files found (%.0n ms)', [FWorkingFileList.Count + 0.0, LStopwatch.ElapsedMilliseconds + 0.0]));
  frmProgress.Log('');

  if FWorkingFileList.Count > 0 then
  begin
    frmProgress.Log('Examining files...');

    LStopwatch := TStopwatch.StartNew;
    ProcessWorkingFileList;
    LStopwatch.Stop;

    if FCanceled then
      frmProgress.Log(Format('Canceled by user (%.0n ms)', [LStopwatch.ElapsedMilliseconds + 0.0]))
    else
      frmProgress.Log(Format('Completed (%.0n ms)', [LStopwatch.ElapsedMilliseconds + 0.0]));

    frmProgress.Log('');
    frmProgress.Log(Format('%.0n interesting files found', [FInterestingFileCount + 0.0]));
    frmProgress.Log('');
  end;
  frmProgress.Log('Done');

  frmProgress.Stop;

  SetLength(ArrActualFile, FInterestingFileCount);

  actCopyToClipboard.Enabled := lvFiles.Items.Count > 0;
  C1.Enabled := lvFiles.Items.Count > 0; // Enable Compress Button
  D1.Enabled := lvFiles.Items.Count > 0; // Disable Compress Button
  Boolini := true;
  lvFiles.Repaint;
  lvFiles.Update;
end;

// ---------------------------Get File Information-------------------------------------------------
procedure TfrmMain.ProcessWorkingFileList;
var
  LWorkingFileCount: Integer;
  LWorkingFileIndex: Integer;
  LFileName: string;
  LIcon: TIcon;
  LIconHandle: WORD;
  LImageIndex: Integer;
  LListItem: TListItem;

  LFileInformation: TFileInformation;
begin
  LWorkingFileCount := FWorkingFileList.Count;
  LWorkingFileIndex := 0;

  LIcon := TIcon.Create;
  try
    for LFileName in FWorkingFileList do
    begin
      if FCanceled then
        exit;

      Inc(LWorkingFileIndex);
      frmProgress.CurrentFolder := ExtractFilePath(LFileName);
      frmProgress.UpdateProgress(Round((LWorkingFileIndex / LWorkingFileCount) * 100));

      if FileIsInteresting(LFileName, LFileInformation) then
      begin
        Inc(FInterestingFileCount);
        UpdateFileCount(FInterestingFileCount);
        lvFiles.Items.BeginUpdate;
        try
          LIcon.Handle := ExtractAssociatedIcon(Application.Handle, PChar(LFileName), LIconHandle);
          LImageIndex := ilSmall.AddIcon(LIcon);
          ilLarge.AddIcon(LIcon);
          LListItem := lvFiles.Items.Add;

          LListItem.Caption := ExtractFileName(LFileName);
          LListItem.SubItems.Add(ExtractFilePath((LFileName)));

          LListItem.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn', LFileInformation.DataModified));

          LListItem.SubItems.Add(LFileInformation.FileType);

          LListItem.SubItems.Add(Format('%.0n KB', [LFileInformation.FileSize / 1024]));

          LListItem.SubItems.Add(LFileInformation.CPU);
          LListItem.SubItems.Add(LFileInformation.CompilerName);
          LListItem.SubItems.Add(LFileInformation.SKU);
          LListItem.SubItems.Add('StandBy');
          LListItem.SubItems.Add(IntToStr(0));
          LListItem.ImageIndex := LImageIndex;

        finally
          lvFiles.Items.EndUpdate;
          Application.ProcessMessages;
        end;
      end;
    end;
  finally
    LIcon.Free;
  end;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.UpdateFileCount(const aFileCount: Integer);
begin
  if aFileCount = 0 then
    StatusBar1.Panels[0].text := 'No files found'
  else
    StatusBar1.Panels[0].text := Format('%.0n files found', [aFileCount + 0.0]);

  StatusBar1.Refresh;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.WMDropFiles(var Msg: TMessage);
var
  i: Integer;
  LDropHandle: THandle;
  LFileCount: Integer;
  LNameLength: Integer;
  LFileName: string;
begin
  LDropHandle := Msg.wParam;
  LFileCount := DragQueryFile(LDropHandle, $FFFFFFFF, nil, 0);

  FSourceFileList.Clear;
  for i := 0 to LFileCount - 1 do
  begin
    LNameLength := DragQueryFile(LDropHandle, i, nil, 0) + 1;
    SetLength(LFileName, LNameLength);
    DragQueryFile(LDropHandle, i, Pointer(LFileName), LNameLength);
    LFileName := Trim(LFileName);
    FSourceFileList.Add(LFileName);
  end;
  DragFinish(LDropHandle);

  FindInterestingFiles;
end;

end.
