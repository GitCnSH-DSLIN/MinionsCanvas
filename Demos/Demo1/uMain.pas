unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, icBase, StdCtrls, GR32, GR32_Image;

type
  TForm1 = class(TForm)
    imgWorkArea: TicPaintBox;
    Memo1: TMemo;
    lbl1: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
uses
  icLayers, icTool_BrushSimple;
{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var LLayerPanel : TicNormalLayerPanel;
begin //
  //set a drawing tool for mouse operation's response.
  GIntegrator.ActivateTool(TicToolBrushSimple);

  LLayerPanel := TicNormalLayerPanel.Create(imgWorkArea.Layers);
  LLayerPanel.BeginUpdate;
      //with img1.Bitmap do
    with imgWorkArea do
      LLayerPanel.LayerBitmap.SetSize(Width,height);
      //LLayerPanel.LayerBitmap.Clear($FF000000 or Cardinal(Random($FFFFFF)));
    LLayerPanel.LayerBitmap.Clear(clWhite32);
      //LLayerPanel.UpdateLayerThumbnail;

  LLayerPanel.EndUpdate;
  imgWorkArea.SelectedLayer := LLayerPanel;

      //LPanelIndex := GIntegrator.ActivePaintBox.LayerList.SelectedIndex + 1;
  imgWorkArea.Bitmap.SetSizeFrom(LLayerPanel.LayerBitmap);
  //imgWorkArea.LayerList.CombineResult.SetSizeFrom(LLayerPanel.LayerBitmap);
  //if imgWorkArea.LayerList.Count > 0 then
    //imgWorkArea.LayerList.LayerPanels[0].LayerBitmap.SetSizeFrom(LLayerPanel.LayerBitmap);

  /// imgWorkArea.LayerList.Add(LLayerPanel);

end;

end.
