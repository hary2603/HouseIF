unit unithaus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, fphttpclient, fpjson, jsonparser,syncobjs,dateutils;

type

  { TSolarData }

  TSolarData=class
  private
    FLock      : TCriticalSection;
  public
    DateString : String;
    TimeString : String;
    KOLLEKTOR_VL : integer;
    KOLLEKTOR_RL : integer;
    KOLLEKTOR_MWL : double;
    WARMWASSER_TUnten : integer;
    WARMWASSER_TOben  : integer;
    PUFFER_Toben      : integer;
    PUFFER_TUnten     : integer;
    VORLAUF_Haus      : double;
    VORLAUF_WKS_SOLL  : double;
    VORLAUF_WKS_IST   : double;
    KESSEL_OEL        : integer;
    KESSEL_HOLZ       : integer;
    PUMPE_SOLAR       : boolean;
    PUMPE_LADE        : boolean;
    PUMPE_WW          : boolean;
    PUMPE_HK1         : boolean;
    PUMPE_HK2         : boolean;
    BRENNER           : boolean;
    STOERUNG          : boolean;
    ZONENVENTIL       : String;
    UPDTime           : Integer;
    constructor Create;
    destructor  Destroy;override;
    procedure   UpdateData;
    procedure   LockData;
    procedure   ReleaseData;
  end;

  var
  { THeizung }
  GCurrent : TSolarData;
  Gserver  : string;


type

  { TUpdateThread }

  TUpdateThread=class(TThread)
  private
  public
    procedure Execute;override;
  end;

  THeizung = class(TForm)
    bClose: TButton;
    lVL_HAUS: TLabel;
    lVL_W_IST: TLabel;
    OEL_AUS: TImage;
    STOERUNG: TImage;
    Pumpe_S_AUS: TImage;
    Pumpe_W_AUS: TImage;
    OK: TImage;
    ZV_Rechts: TImage;
    ZV_Links: TImage;
    Pumpe_S_EIN: TImage;
    Schema: TImage;
    OEL_EIN: TImage;
    Pumpe_W_EIN: TImage;
    lPSOL: TLabel;
    lKOLLRL: TLabel;
    lPLADE: TLabel;
    lZVentil: TLabel;
    lWWTu: TLabel;
    lWWTo: TLabel;
    lKOLLVL: TLabel;
    lKOLLMWL: TLabel;
    lUpdateTS: TLabel;
    lPUTu: TLabel;
    lPUTo: TLabel;
    lKOEL: TLabel;
    lKHolz: TLabel;
    Timer: TTimer;
    procedure bCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private
    FUpdater : TUpdateThread;
    { private declarations }
  public


    { public declarations }
  end;

var
  Heizung: THeizung;

implementation

{$R *.lfm}

{ TUpdateThread }

procedure TUpdateThread.Execute;
begin
  while not terminated do
   begin
     GCurrent.UpdateData;
   end;
end;

{ TSolarData }

constructor TSolarData.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
end;

destructor TSolarData.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

procedure TSolarData.UpdateData; // Zyklisches abfragen per http request
var s      : string;
    json   : TJSONData;
    jo,jso : TJSONObject;
    jp     : TJSONParser;
    st     : TDateTime;

begin
  sleep(2000);
  With TFPHttpClient.Create(Nil) do
    try
      st := Now;
      s:='';
      try
        S:=Get(gserver)
      except
        UPDTime:=-1;
        exit;
      end;
      UPDTime := MilliSecondsBetween(Now,St);
      FLock.Acquire;
      try
        try
          jp := TJSONParser.Create(s);
          json := jp.Parse;
          if json is TJSONObject then
           begin
             jo := json as TJSONObject;
             jso := jo.Find('TS') as TJSONObject;
             DateString := jso.Find('DATE').AsString;
             TimeString := jso.Find('TIME').AsString;
             jso := jo.Find('KOLLEKTOR') as TJSONObject;
             KOLLEKTOR_VL  := jso.Find('VL').AsInteger;
             KOLLEKTOR_RL  := jso.Find('RL').AsInteger;
             KOLLEKTOR_MWL := jso.Find('MWL').AsFloat;
             jso := jo.Find('WARMWASSER') as TJSONObject;
             WARMWASSER_TOben   := jso.Find('TOben').AsInteger;
             WARMWASSER_TUnten  := jso.Find('TUnten').AsInteger;

             jso := jo.Find('VORLAUF') as TJSONObject;
             VORLAUF_Haus := jso.Find('Haus').AsFloat;
             VORLAUF_WKS_SOLL := jso.Find('Werkstatt_soll').AsFloat;
             VORLAUF_WKS_IST := jso.Find('Werkstatt_ist').AsFloat;

             jso := jo.Find('PUFFER') as TJSONObject;
             PUFFER_Toben  := jso.Find('TOben').AsInteger;
             PUFFER_TUnten := jso.Find('TUnten').AsInteger;
             jso := jo.Find('KESSEL') as TJSONObject;
             KESSEL_OEL  := jso.Find('OEL').AsInteger;
             KESSEL_HOLZ := jso.Find('HOLZ').AsInteger;
             jso := jo.Find('PUMPEN') as TJSONObject;
             PUMPE_SOLAR  := jso.Find('SOLARPUMPE').AsString='EIN';
             PUMPE_LADE   := jso.Find('LADEPUMPE').AsString='EIN';
             PUMPE_WW     := jso.Find('WWPUMPE').AsString='EIN';
             PUMPE_HK1    := jso.Find('HK1PUMPE').AsString='EIN';
             PUMPE_HK2    := jso.Find('HK2PUMPE').AsString='EIN';
             BRENNER      := jo.Find('OELBRENNER').AsString='EIN';
             STOERUNG     := jo.Find('BRENNERSTOERUNG').AsString='JA';
             ZONENVENTIL  := jo.Find('ZONENVENTIL').AsString;
           end;
        except
          UPDTime:=-2;
        end;
      finally
        jp.free;
        FLock.Release;
      end;
  finally
    Free;
  end;
end;

procedure TSolarData.LockData;
begin
  FLock.Acquire;
end;

procedure TSolarData.ReleaseData;
begin
  FLock.Release;
end;

{ THeizung }

procedure THeizung.FormCreate(Sender: TObject);
begin
  if paramstr(1)='' then
   begin
//    Gserver:='http://hinterface.no-ip.org/cgi/json'
     Gserver:='http://10.0.0.130/data.json'
   end
  else
    begin
      Gserver:=(paramstr(1));
    end;

  GCurrent:=TSolarData.Create;
  FUpdater:=TUpdateThread.Create(false);
  Timer.Enabled:=true;
end;

procedure THeizung.bCloseClick(Sender: TObject);
begin
  Close;
end;

procedure THeizung.FormPaint(Sender: TObject);
begin
  Canvas.Draw(0,0,Schema.Picture.Bitmap);
end;





procedure THeizung.TimerTimer(Sender: TObject);
begin
  if not assigned(GCurrent) then
   exit;
  GCurrent.LockData;
  try
    if GCurrent.UPDTime>0 then
     begin
       //Canvas.Draw(random(200),random(200),STOERUNG.Picture.Bitmap);

       lUpdateTS.Caption:=GCurrent.DateString+' | '+GCurrent.TimeString+' ['+inttostr(GCurrent.UPDTime)+']';
       lKOLLVL.Caption  := inttostr(GCurrent.KOLLEKTOR_VL)+' °C';
       lKOLLRL.Caption  := inttostr(GCurrent.KOLLEKTOR_RL)+' °C';
       lKOLLMWL.Caption := floattostr(GCurrent.KOLLEKTOR_MWL)+' kW';
       lKHolz.Caption   := inttostr(GCurrent.KESSEL_HOLZ)+' °C';
       lKOEL.Caption    := inttostr(GCurrent.KESSEL_OEL)+' °C';
       lPUTo.Caption    := inttostr(GCurrent.PUFFER_Toben)+' °C';
       lPUTu.Caption    := inttostr(GCurrent.PUFFER_TUnten)+' °C';
       lWWTu.Caption    := inttostr(GCurrent.WARMWASSER_TUnten)+' °C';
       lWWTo.Caption    := inttostr(GCurrent.WARMWASSER_TOben)+' °C';
       lVL_HAUS.Caption := FloatToStr(GCurrent.VORLAUF_Haus)+' °C';
       lVL_W_IST.Caption := FloatToStr(GCurrent.VORLAUF_WKS_IST)+' °C';
     // lPLADE.Caption   := BoolToStr(GCurrent.PUMPE_LADE,'EIN','AUS');
     //  lPSOL.Caption    := BoolToStr(GCurrent.PUMPE_SOLAR,'EIN','AUS');
       lZVentil.Caption := GCurrent.ZONENVENTIL;

        if GCurrent.PUMPE_LADE = TRUE then
        begin
             Canvas.Draw(142,329,Pumpe_W_EIN.Picture.Bitmap);
        end
        else
        begin
             Canvas.Draw(142,329,Pumpe_W_AUS.Picture.Bitmap);
        end;
        if GCurrent.PUMPE_SOLAR = TRUE then
        begin
             Canvas.Draw(391,249,Pumpe_S_EIN.Picture.Bitmap);
        end
        else
        begin
             Canvas.Draw(391,249,Pumpe_S_AUS.Picture.Bitmap);
        end;

        //GCurrent.PUMPE_WW := true;
        //GCurrent.PUMPE_HK1 := true;
        //GCurrent.PUMPE_HK2:= true;
        //GCurrent.STOERUNG:= true;

        if GCurrent.PUMPE_WW = TRUE then
        begin
             Canvas.Draw(586,169,Pumpe_S_EIN.Picture.Bitmap);
        end
        else
        begin
             Canvas.Draw(586,169,Pumpe_S_AUS.Picture.Bitmap);
        end;

        if GCurrent.PUMPE_HK1 = TRUE then
        begin
             Canvas.Draw(622,169,Pumpe_S_EIN.Picture.Bitmap);
        end
        else
        begin
             Canvas.Draw(622,169,Pumpe_S_AUS.Picture.Bitmap);
        end;

        if GCurrent.PUMPE_HK2 = TRUE then
        begin
             Canvas.Draw(658,169,Pumpe_S_EIN.Picture.Bitmap);
        end
        else
        begin
             Canvas.Draw(658,169,Pumpe_S_AUS.Picture.Bitmap);
        end;

        if GCurrent.BRENNER = TRUE then
        begin
           Canvas.Draw(706,302,OEL_EIN.Picture.Bitmap);
        end
        else
        begin
           Canvas.Draw(706,302,OEL_AUS.Picture.Bitmap);
        end;

        if GCurrent.STOERUNG = True then     // Anzeige Brennerstörung
        begin
           Canvas.Draw(712,330,STOERUNG.Picture.Bitmap);
        end
        else
        begin
           Canvas.Draw(712,330,OK.Picture.Bitmap);
        end;

         if GCurrent.ZONENVENTIL = 'BOILER' then
        begin
            Canvas.Draw(391,320,ZV_Rechts.Picture.Bitmap);
        end
        else
        begin
           Canvas.Draw(391,320,ZV_Links.Picture.Bitmap);
        end;
     end
    else
      if GCurrent.UPDTime=-2 then
        lUpdateTS.Caption:='PARSE FAIL'
      else
        lUpdateTS.Caption:='NET FAIL'
  finally
    GCurrent.ReleaseData;
  end;
end;

end.

