unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, LazSerial, HTTPSend, lclintf;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnLoadFromFile: TButton;
    btnSaveToFile: TButton;
    ButtonSerialConnect: TButton;
    btnDownload: TButton;
    ButtonSerialClose: TButton;
    btnLoad: TButton;
    btnUpload: TButton;
    ButtonExe1: TButton;
    ButtonExe2: TButton;
    ButtonExe3: TButton;
    ButtonRTCSync: TButton;
    ButtonRTCSync1: TButton;
    ButtonRTCSync2: TButton;
    ButtonRTCSync3: TButton;
    ButtonReset: TButton;
    ButtonRTCSync5: TButton;
    EditExe1: TEdit;
    EditExe2: TEdit;
    EditExe3: TEdit;
    edtScriptNo: TEdit;
    imgLogo: TImage;
    Label1: TLabel;
    labLinkTherapy: TLabel;
    memoConsole: TMemo;
    memoScript: TMemo;
    openDlg: TOpenDialog;
    Panel4: TPanel;
    Panel5: TPanel;
    saveDlg: TSaveDialog;
    serial: TLazSerial;
    Panel1: TPanel;
    Panel2: TPanel;
    statusBar: TStatusBar;
    procedure ButtonExe1Click(Sender: TObject);
    procedure ButtonResetClick(Sender: TObject);
    procedure ButtonRTCSync1Click(Sender: TObject);
    procedure ButtonRTCSync2Click(Sender: TObject);
    procedure ButtonRTCSync3Click(Sender: TObject);
    procedure ButtonRTCSync5Click(Sender: TObject);
    procedure ButtonRTCSyncClick(Sender: TObject);
    procedure ButtonSerialConnectClick(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure btnLoadFromFileClick(Sender: TObject);

    procedure ButtonSerialCloseClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnSaveToFileClick(Sender: TObject);
    procedure btnUploadClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure imgLogoClick(Sender: TObject);
    procedure labLinkTherapyClick(Sender: TObject);
    procedure serialRxData(Sender: TObject);
  private
    readBuffer :string;


  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }



procedure TfrmMain.ButtonSerialCloseClick(Sender: TObject);
begin
  serial.Close;
  memoConsole.Lines.Clear;
  statusBar.SimpleText:='Serial port was closed.';
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
      //frmMain.Caption:='downloader - https://biotronics.eu/node/'+edtScriptNo.Text;
      statusBar.SimpleText:='Downloaded from portal: https://biotronics.eu/node/'+edtScriptNo.Text;
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
      memoConsole.Clear;


     //List existed script
     serial.WriteData('ls'#13#10);
    end;



end;

procedure TfrmMain.FormCreate(Sender: TObject);
var s: string;
begin
  readBuffer:='';
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
   OpenURL('https://biotronics.eu');
end;

procedure TfrmMain.labLinkTherapyClick(Sender: TObject);
begin
     OpenURL('https://biotronics.eu/node/'+edtScriptNo.Text);
end;


procedure TfrmMain.serialRxData(Sender: TObject);
var s : string;
    i: integer;

begin
//Read data from serial port
  //sleep (100);

  s:= serial.ReadData;

  for i:=1 to Length(s) do
     if (s[i]= #10)  then begin
       //if (s[i-1]<> #13) then ss := ss + #13#10 else ss:=ss+#10;
       memoConsole.Lines.Add(readBuffer);
       readBuffer:='';
     end else
       readBuffer:=readBuffer+s[i];



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

procedure TfrmMain.ButtonSerialConnectClick(Sender: TObject);
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

procedure TfrmMain.ButtonExe1Click(Sender: TObject);
var s : string;
begin
    if Sender = ButtonExe1 then begin s:=EditExe1.Text; end else
    if Sender = ButtonExe2 then begin s:=EditExe2.Text; end else
    if Sender = ButtonExe3 then begin s:=EditExe3.Text; end;

    if (s<>'') and serial.Active then begin
       serial.WriteData(Trim(s)+#13#10);
       sleep(20);
    end;
end;

procedure TfrmMain.ButtonResetClick(Sender: TObject);
begin
  if serial.Active then begin
     //Clear terminal window
     memoConsole.Lines.Clear;
     readBuffer:='';

     //DTR line is in Arduino boartds the reset of an ucontroller
     serial.SetDTR(false);
     Sleep(2);
     serial.SetDTR(true);
  end;
end;

procedure TfrmMain.ButtonRTCSync1Click(Sender: TObject);
begin
     if serial.Active then begin
        serial.WriteData('rm'#13#10);
     end;
end;

procedure TfrmMain.ButtonRTCSync2Click(Sender: TObject);
begin
     if serial.Active then begin
        serial.WriteData('gettime'#13#10);
     end;
end;

procedure TfrmMain.ButtonRTCSync3Click(Sender: TObject);
begin
     if serial.Active then begin
        serial.WriteData('off'#13#10);
     end;
end;

procedure TfrmMain.ButtonRTCSync5Click(Sender: TObject);
begin
     if serial.Active then begin
        serial.WriteData('ls'#13#10);
     end;
end;

procedure TfrmMain.ButtonRTCSyncClick(Sender: TObject);
var s : string;
begin
     if serial.Active then begin
        s:= FormatDateTime( 'hh nn ss',Now);
        serial.WriteData('settime ' + s + #13#10);
     end;
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


     for i:=0 to memoScript.Lines.Count-1 do  begin

         serial.WriteData('mem @'#13#10);
         sleep(20);

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




end.

