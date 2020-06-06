unit unitMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, LazSerial,  lclintf,  fphttpclient, fpjson, jsonparser;

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
    EditScriptNo: TEdit;
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
    LastPrompt: boolean;
    UploadingFromDevice:boolean;


  public
    const VERSION ='2020-06-06 (alpha)';

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }



procedure TfrmMain.ButtonSerialCloseClick(Sender: TObject);
begin
  serial.Close;

  statusBar.SimpleText:='Serial port was closed.';
end;

procedure TfrmMain.btnLoadClick(Sender: TObject);
var
  Http: TFPHttpClient;
  Content : string;
  Json : TJSONData;
  i    : integer;

begin
  Http:=TFPHttpClient.Create(Nil);
  memoScript.Lines.Clear;
  try

     Content:=Http.Get('https://biotronics.eu/terapie_list?_format=json'); //  this is just an example data
     JSON:=GetJSON(Content);
     try
        for i:= 0 to Json.Count-1 do begin
          if Json.FindPath('['+IntToStr(i)+'].nid[0].value').AsString = EditScriptNo.Text then begin
              statusBar.SimpleText:=Json.FindPath('['+IntToStr(i)+'].title[0].value').AsString;
              memoScript.Lines.Add(Json.FindPath('['+IntToStr(i)+'].field_skrypt[0].value').AsString);
              Content:='';
              Break;

          end;
        end;

     finally
       JSON.Free;
     end;
  finally
    Http.Free;
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
      memoScript.Clear;
      UploadingFromDevice:=true;


     //List existed script
     serial.WriteData('ls'#13#10);
    end;



end;





procedure TfrmMain.FormCreate(Sender: TObject);
var s: string;
begin

  Self.Caption:='downloader '+VERSION;
  readBuffer:='';
  s:=ApplicationName;

  if pos('(',s)>0 then
    s:= trim(LeftStr(s,pos('(',s)-1));

  if StrToIntDef(s,0)>0 then begin
     EditScriptNo.Text:=s;
     frmMain.btnLoadClick(Sender);


  end;
end;

procedure TfrmMain.imgLogoClick(Sender: TObject);
begin
   OpenURL('https://biotronics.eu');
end;

procedure TfrmMain.labLinkTherapyClick(Sender: TObject);
begin
     OpenURL('https://biotronics.eu/node/'+EditScriptNo.Text);
end;


procedure TfrmMain.serialRxData(Sender: TObject);
var s : string;
    i: integer;

begin
//Read data from serial port
  //sleep (100);

  s:= serial.ReadData;

  for i:=1 to Length(s) do begin

      //Reset UploadingFromDevice mode after proompt obtained
      if (s[i]='>') then UploadingFromDevice:=false;

      if (s[i]=#10)  then begin

        if LastPrompt then begin

          LastPrompt:=false;
          memoConsole.Lines.Delete(memoConsole.Lines.Count-1);
          if UploadingFromDevice then memoScript.Lines.Delete(memoScript.Lines.Count-1);
        end;

         memoConsole.Lines.Add(readBuffer);
         if UploadingFromDevice and (trim(readBuffer)<>'>ls') then memoScript.Lines.Add(readBuffer);
         readBuffer:='';

      end else
         readBuffer:=readBuffer+s[i];

  end;

  if SizeOf(readBuffer) >0 then begin

     if LastPrompt then begin

       LastPrompt:=false;
       memoConsole.Lines.Delete(memoConsole.Lines.Count-1);
       if UploadingFromDevice then memoScript.Lines.Delete(memoScript.Lines.Count-1);
     end;

     memoConsole.Lines.Add(readBuffer);
     if UploadingFromDevice then memoScript.Lines.Add(readBuffer);
     LastPrompt:=true;

  end;



end;


procedure TfrmMain.ButtonSerialConnectClick(Sender: TObject);
var f : textFile;
    s: string;

begin
  s:=ExtractFilePath(Application.ExeName)+'\downloader.port';

  LastPrompt := false;
  UploadingFromDevice:=false;

  AssignFile(f,s);
  {$I-}
  Reset(f);

  if IOResult=0 then  begin
     readln(f,s);
     serial.Device:=s;
     readln(f,s);
     if s='br__9600' then serial.BaudRate := br__9600 else
     if s='br115200' then serial.BaudRate := br115200;

  end;
  {$I+}

  serial.ShowSetupDialog;
  serial.Open;

    if serial.Active then  begin
       Rewrite(f);
       {$I-}
       Writeln(f,serial.Device);
       WriteLn(f,serial.BaudRate);
       {$I+}

       memoConsole.Lines.Clear;
       statusBar.SimpleText:='Serial port is open.';

    end;
   CloseFile(f);

end;

procedure TfrmMain.ButtonExe1Click(Sender: TObject);
var s : string;
begin
    if (Sender = ButtonExe1) or (Sender = EditExe1) then begin s:=EditExe1.Text; end else
    if (Sender = ButtonExe2) or (Sender = EditExe2) then begin s:=EditExe2.Text; end else
    if (Sender = ButtonExe3) or (Sender = EditExe3) then begin s:=EditExe3.Text; end;

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
     LastPrompt:=false;

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
         sleep(30);

         s := memoScript.Lines[i];
         if (s<>'') and (s<>'@') then begin
           serial.WriteData(s+#13#10);
         end;

         serial.WriteData('@'#13#10);
         Application.ProcessMessages;

         sleep(180);
     end;


  end;


end;

procedure TfrmMain.btnLoadFromFileClick(Sender: TObject);
begin
  if openDlg.Execute then
    memoScript.Lines.LoadFromFile(openDlg.FileName);
end;




end.

