unit unitchoosetherapy;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Grids, myFunctions;

type

  { TFormChooseTherapy }

  TFormChooseTherapy = class(TForm)
    ButtonChoose: TButton;
    ButtonSearch: TButton;
    ComboBoxLanguage: TComboBox;
    EditSearchString: TEdit;
    ImageBack: TImage;
    ImageNext: TImage;
    Label1: TLabel;
    Label2: TLabel;
    LabelPage: TLabel;
    Label24: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Shape3: TShape;
    StringGrid: TStringGrid;

    procedure ButtonChooseClick(Sender: TObject);
    procedure ButtonSearchClick(Sender: TObject);
    procedure EditSearchStringChange(Sender: TObject);
    procedure EditSearchStringKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);
    procedure ImageBackClick(Sender: TObject);
    procedure ImageNextClick(Sender: TObject);

    //procedure LoadEAPTherapiesFromFile;

    function Choose(SearchString: string):TBioresonanceTherapy;
    procedure FillGridOfTherapies(BioresonanceTherapies:TBioresonanceTherapies);
    procedure Search (SearchString : string);
  private
    F_Therapy : TBioresonanceTherapy;
    F_Therapies : TBioresonanceTherapies;


  public
    F_Page : integer;

  end;

var
  FormChooseTherapy: TFormChooseTherapy;

implementation

{$R *.lfm}

{ TFormChooseTherapy }

procedure TFormChooseTherapy.FillGridOfTherapies(BioresonanceTherapies:TBioresonanceTherapies);
var i : integer;
begin

  StringGrid.RowCount:= 1; //Clear fields, but not change grid size
  StringGrid.RowCount:=Length(BioresonanceTherapies)+1;

  for i:= 0 to Length(BioresonanceTherapies)-1 do
    with StringGrid do begin
        Cells[0,i+1]     := BioresonanceTherapies[i].Name;
        Cells[1,i+1]     := BioresonanceTherapies[i].TherapyScript;
        Cells[2,i+1]     := BioresonanceTherapies[i].Devices;
    end;

end;

procedure TFormChooseTherapy.Search (SearchString : string);
var content : string;
          s : string;
begin

  F_Therapy.Name:='Unknow';
  //setlength(F_Therapy.Points,0);
  F_Therapy.Devices:='';
  F_Therapy.TherapyScript:='';
  F_Therapy.Description:='';

  s := 'title=' + trim(SearchString) ;
  s:= s+ '&langcode='+trim(ComboBoxLanguage.Text);
  if F_Page > 0 then s := s + '&page=' + IntToStr(F_Page);

  GetContentFromREST(content,  LISTS_DEF[LIST_BIORESONANCE_THERAPY].RestURL , s );
  GetBioresonanceTherapiesFromContent( content, F_Therapies);
  FillGridOfTherapies(F_Therapies);


end;

function  TFormChooseTherapy.Choose(SearchString: string):TBioresonanceTherapy;
(* elektros 2020-05-25
 * Open choose window to select an EAP therapy from portal (via REST/JSON)
 *   SearchString - Search text contained in title
 *   result - comlex chosen therapy
 *)
begin

  F_Page := 0;
  Search(EditSearchString.Text);
  Self.ShowModal;

  result:= F_Therapy;

end;





procedure TFormChooseTherapy.ButtonChooseClick(Sender: TObject);
var idx : integer;
begin
  idx := StringGrid.Row;
  if idx >0 then F_Therapy:=F_Therapies[idx-1];


  Close;
end;

procedure TFormChooseTherapy.ButtonSearchClick(Sender: TObject);
begin
  Search(EditSearchString.Text);
end;

procedure TFormChooseTherapy.EditSearchStringChange(Sender: TObject);
begin
  F_Page := 0;
  LabelPage.Caption := IntToStr(F_Page);
end;

procedure TFormChooseTherapy.EditSearchStringKeyPress(Sender: TObject;
  var Key: char);
begin
  if ord(Key) = VK_RETURN then begin
     Key := #0;
     ButtonSearchClick(Sender);
  end;
end;

procedure TFormChooseTherapy.FormShow(Sender: TObject);
begin
  EditSearchString.SetFocus;
end;

procedure TFormChooseTherapy.ImageBackClick(Sender: TObject);
begin
  F_Page := F_Page -1;
  if F_Page <0 then F_Page :=0;
  LabelPage.Caption := IntToStr(F_Page);
  Search(EditSearchString.Text);
end;

procedure TFormChooseTherapy.ImageNextClick(Sender: TObject);
begin
  F_Page := F_Page +1;
  LabelPage.Caption := IntToStr(F_Page);
  Search(EditSearchString.Text);

end;

end.

