unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, LazSerial, HTTPSend, lclintf;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnConnect: TButton;
    btnDownload: TButton;
    btnLoadFromFile: TButton;
    btnReset: TButton;
    btnLoad: TButton;
    btnSaveToFile: TButton;
    btnUpload: TButton;
    btnRemove: TButton;
    edtScriptNo: TEdit;
    imgLogo: TImage;
    Label1: TLabel;
    memoConsole: TMemo;
    memoScript: TMemo;
    openDlg: TOpenDialog;
    Panel3: TPanel;
    Panel4: TPanel;
    saveDlg: TSaveDialog;
    serial: TLazSerial;
    Panel1: TPanel;
    Panel2: TPanel;
    statusBar: TStatusBar;
    procedure btnConnectClick(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure btnLoadFromFileClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnSaveToFileClick(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure imgLogoClick(Sender: TObject);
    procedure serialRxData(Sender: TObject);
  private


  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.btnResetClick(Sender: TObject);
begin
  memoConsole.Lines.Clear;

  Sleep(2);

  if serial.Active then begin
     //DTR line is in Arduino boartds the reset of an ucontroller
     serial.SetDTR(false);
     Sleep(2);
     serial.SetDTR(true);

  end;
end;

procedure TfrmMain.btnLoadClick(Sender: TObject);

var
  httpClient: THTTPSend;
  strm: TFileStream;
  //l: longint;
begin

  try
    httpClient:= THTTPSend.Create;
    strm := TFileStream.Create('mystream', fmCreate or fmOpenReadWrite);

    if httpClient.HTTPMethod('GET', 'http://biotronika.pl/downloader.php?nodeid='+edtScriptNo.Text) then  begin
      httpClient.Document.SaveToStream(strm);
      strm.Position:=0;
      memoScript.Lines.LoadFromStream(strm);
      frmMain.Caption:='downloader - https://biotronics.eu/node/'+edtScriptNo.Text;
      statusBar.Caption:='Downloaded from portal: https://biotronics.eu/node/'+edtScriptNo.Text+ ' Click on top bar to see therapy page!';
    end;

  finally
    httpClient.Free;
    strm.Free;
  end;

end;

procedure TfrmMain.btnSaveToFileClick(Sender: TObject);
var s:string;
begin
  if memoScript.Lines.Count>0 then begin;

    if memoScript.Lines[0].Chars[0]='#' then

      // Get file name from first line if it is commnet
      s:= memoScript.Lines[0];
      saveDlg.FileName:= trim(copy(s,2,Length(s)));

      if saveDlg.Execute then
        memoScript.Lines.SaveToFile(saveDlg.FileName);

  end;
end;

procedure TfrmMain.btnUploadClick(Sender: TObject);
begin
    if serial.Active then begin


     //List existed script
     serial.WriteData('ls'#13#10);
    end;



end;

procedure TfrmMain.FormCreate(Sender: TObject);
var s: string;
begin
  s:=ApplicationName;

  if pos('(',s)>0 then
    s:= trim(LeftStr(s,pos('(',s)-1));

  if StrToIntDef(s,0)>0 then begin
     edtScriptNo.Text:=s;
     frmMain.btnLoadClick(Sender);


  end;
end;

procedure TfrmMain.imgLogoClick(Sender: TObject);
begin
   OpenURL('https://biotronics.eu/node/'+edtScriptNo.Text);
end;


procedure TfrmMain.serialRxData(Sender: TObject);
var s,ss: string;
    i: integer;

begin
//Read data from serial port
  sleep (100);

  s:= serial.ReadData;

  ss:='';

  for i:=1 to Length(s) do
     if (s[i]= #10) and (s[i-1]<> #13) then
       ss := ss + #13#10
     else
       ss:=ss+s[i];

  memoConsole.Lines.Add(ss);

end;

(*
begin

  try
    // Navigate to proper "directory":

    if Registry.OpenKeyReadOnly('\SOFTWARE\Classes\InnoSetupScriptFile\shell\Compile\Command') then
      CompileCommand:=Registry.ReadString(''); //read the value of the default name
  finally
    Registry.Free;
  end;
end; *)

procedure TfrmMain.btnConnectClick(Sender: TObject);
var f : textFile;
    s: string;

begin
  s:=ExtractFilePath(Application.ExeName)+'\downloader.port';

  AssignFile(f,s);
  {$I-}
  Reset(f);
  {$I+}
  if IOResult=0 then  begin
     readln(f,s);
     serial.Device:=s;
  //CloseFile(f);
  end;

  serial.ShowSetupDialog;
  serial.Open;

    if serial.Active then  begin
       Rewrite(f);
       {$I-}
       Writeln(f,serial.Device);
       {$I+}


    end;
   CloseFile(f);

end;

procedure TfrmMain.btnDownloadClick(Sender: TObject);
var i : integer;
    s : string;
begin

  if serial.Active then begin


     //Delete existing script
     serial.WriteData('mem'#13#10);
     sleep(200);
     serial.WriteData('@'#13#10);
     sleep(200);


     for i:=0 to memoScript.Lines.Count do  begin

         serial.WriteData('mem @'#13#10);

         s := memoScript.Lines[i];
         if (s<>'') and (s<>'@') then begin
           serial.WriteData(s+#13#10);
         end;

         serial.WriteData('@'#13#10);
         Application.ProcessMessages;

         sleep(100);
     end;


  end;


end;

procedure TfrmMain.btnLoadFromFileClick(Sender: TObject);
begin
  if openDlg.Execute then
    memoScript.Lines.LoadFromFile(openDlg.FileName);
end;

procedure TfrmMain.btnRemoveClick(Sender: TObject);
begin

  if serial.Active then begin

    //List remove script from device
    serial.WriteData('rm'#13#10);

  end;
end;


end.

