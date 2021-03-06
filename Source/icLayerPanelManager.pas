unit icLayerPanelManager;

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1 or LGPL 2.1 with linking exception
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * Alternatively, the contents of this file may be used under the terms of the
 * Free Pascal modified version of the GNU Lesser General Public License
 * Version 2.1 (the "FPC modified LGPL License"), in which case the provisions
 * of this license are applicable instead of those above.
 * Please see the file LICENSE.txt for additional information concerning this
 * license.
 *
 *
 * The Initial Developer of this unit are
 *   Ma Xiaoguang and Ma Xiaoming < gmbros[at]hotmail[dot]com >
 *
 * Contributor(s):
 *
 * ***** END LICENSE BLOCK ***** *)

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}


uses
{ Delphi }
  Types, Windows, Controls, Classes,
{ Graphics32 }
  GR32, GR32_Image, GR32_Layers, GR32_RangeBars,
{ miniGlue lib }
  icBase, icLayers;

type
  TicSelectedPanelArea = (spaUnknown,
                          spaVisibleMark,
                          spaStageMark,
                          spaLogoThumbnail,
                          spaLayerThumbnail,
                          spaMaskLinkageMark,
                          spaMaskThumbnail,
                          spaLayerCaption);

  { TicLayerPanelCustomTheme }

  TicLayerPanelCustomTheme = class(TObject)
  private
    procedure SetObjectSpan(AValue: Integer);
  protected
    FObjectSpan : Integer;

    function GetLayerVisibleIconRect(const APanelRect: TRect): TRect; virtual; abstract;

    function GetPanelAreaAtXY(APanel: TicLayer;
      const APanelRect: TRect; const AX, AY: Integer): TicSelectedPanelArea; virtual; abstract;
  public
    constructor Create;

    procedure Paint(ABuffer: TBitmap32; APanel: TicLayer;
      const ARect: TRect); virtual; abstract;

    function GetSnapshot(APanel: TicLayer;
      const AWidth, AHeight: Integer): TBitmap32; virtual; abstract;

    property ObjectSpan : Integer read FObjectSpan write SetObjectSpan;
  end;

  { TicLayerPanelStdTheme }

  TicLayerPanelStdTheme = class(TicLayerPanelCustomTheme)
  private
    FLayerVisibleIcon : TBitmap32;
    FLayerStageIcon   : TBitmap32;
    FMaskStageIcon    : TBitmap32;
    FMaskLinkedIcon   : TBitmap32;
    FMaskUnlinkedIcon : TBitmap32;
    FSpanColor        : TColor32;
    FSelectedColor    : TColor32;
    FDeselectedColor  : TColor32;
    FDisabledColor    : TColor32;
  protected
    function GetLayerVisibleIconRect(const APanelRect: TRect): TRect; override;

    function GetPanelAreaAtXY(APanel: TicLayer;
      const APanelRect: TRect; const AX, AY: Integer): TicSelectedPanelArea; override;

    procedure DrawLayerVisibleIcon(ABuffer: TBitmap32; const ARect: TRect; const AVisible: Boolean);
    procedure DrawProcessStageIcon(ABuffer: TBitmap32; const ARect: TRect; const AStage: TicLayerProcessStage);
    procedure DrawMaskLinkIcon(ABuffer: TBitmap32; const ARect: TRect; const ALinked: Boolean);
    procedure DrawPanelBorder(ABuffer: TBitmap32; const ARect: TRect);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Paint(ABuffer: TBitmap32; APanel: TicLayer;
      const ARect: TRect); override;

    function GetSnapshot(APanel: TicLayer;
      const AWidth, AHeight: Integer): TBitmap32; override;
  end;

  { TicLayerPanelManager }

  TicScrollPanelThread = class; // forward declaration
  
  TicLayerPanelManager = class(TCustomPaintBox32)
  private
    FScrollLocked   : Boolean;                 // lock execution of the scroll bars
    FVertScroll     : TRangeBar;
    FPanelTheme     : TicLayerPanelCustomTheme;
    FViewportOffset : TPoint;                  // offset of the viewport
    FWorkSize       : TPoint;                  // maximum scrollable area
    FLeftButtonDown : Boolean;                 // if mouse left button is pressed
    FWheelDelta     : Integer;

    // for render snapshot of a moving panel by mouse move
    FMouseX, FMouseY  : Integer;
    FLastX, FLastY    : Integer;
    FMouseDownX       : Integer;
    FMouseDownY       : Integer;
    FSnapshotOffsetY  : Integer;
    FMovingPanelIndex : Integer;
    FMovingPanel      : TicLayer;
    FIsPanelMoving    : Boolean;
    FSnapshotTopLeft  : TPoint;
    FPanelSnapshot    : TBitmap32;
    FScrollThread     : TicScrollPanelThread;


    procedure SetLayerList(const AValue: TLayerCollection);
    procedure ScrollThreadStop;

    function GetPanelRect(const APanelIndex: Integer): TRect;
    function GetPanelIndexAtXY(AX, AY: Integer): Integer;
    function CanScrollDown: Boolean;
    function CanScrollUp: Boolean;
    function IsRectInViewport(const ARect: TRect): Boolean; // dertermine if any part of a rect is in the viewport

    // callbacks
    procedure ScrollHandler(Sender: TObject);
  protected
    FLayerList      : TLayerCollection;
    procedure PreparePanelSnapshotRendering(const AMouseX, AMouseY: Integer); virtual;
    procedure CheckLayout; virtual;
    procedure Scroll(Dy: Integer); virtual;
    procedure DoPaintBuffer; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    function ScrollPanelInViewport(const APanelIndex: Integer): Boolean; virtual;
    function ScrollSelectedPanelInViewport: Boolean;
    function GetPanelSnapshot(const APanelIndex: Integer): TBitmap32;
    function GetSelectedPanelSnapshot: TBitmap32;
    function DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    function DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Resize; override;

    property LayerList : TLayerCollection read FLayerList write SetLayerList;
  published
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

  { TicScrollPanelThread }

  TicScrollPanelThread = class(TThread)
  private
    FPanelManager : TicLayerPanelManager;
  protected
    procedure Execute; override;
  public
    constructor Create(APanelManager: TicLayerPanelManager);
  end;

implementation

uses
{ Delphi }
  SysUtils, Graphics, Forms, Math,
{ Graphics32 }
  GR32_LowLevel,
{ miniGlue lib }
  icMath;

type
  TicPaintBoxAccess = class(TicPaintBox);
{$R icIcons.res}

const
  MIN_OBJECT_SPAN    = 2;
  MAX_OBJECT_SPAN    = 20;
  LAYER_PANEL_HEIGHT = 40;

{ TicLayerPanelCustomTheme }

constructor TicLayerPanelCustomTheme.Create;
begin
  inherited;

  FObjectSpan := 5;
end;

procedure TicLayerPanelCustomTheme.SetObjectSpan(AValue: Integer);
begin
  FObjectSpan := Clamp(AValue, MIN_OBJECT_SPAN, MAX_OBJECT_SPAN);
end;

{ TicLayerPanelStdTheme }

constructor TicLayerPanelStdTheme.Create;
begin
  inherited;

  FLayerVisibleIcon := TBitmap32.Create;
  FLayerVisibleIcon.LoadFromResourceName(HInstance, 'EYEOPEN');

  FLayerStageIcon := TBitmap32.Create;
  FLayerStageIcon.LoadFromResourceName(HInstance, 'ONLAYER');
  
  FMaskStageIcon := TBitmap32.Create;
  FMaskStageIcon.LoadFromResourceName(HInstance, 'ONMASK');

  FMaskLinkedIcon   := TBitmap32.Create;
  FMaskLinkedIcon.LoadFromResourceName(HInstance, 'MASKLINKED');

  FMaskUnlinkedIcon := TBitmap32.Create;
  FMaskUnlinkedIcon.LoadFromResourceName(HInstance, 'MASKUNLINKED');

  FSpanColor       := clSilver32;
  FSelectedColor   := Color32(clHighlight);
  FDeselectedColor := Color32(clBtnFace);
  FDisabledColor   := $FFDFDFDF;
end;

destructor TicLayerPanelStdTheme.Destroy;
begin
  FMaskLinkedIcon.Free;
  FMaskUnlinkedIcon.Free;
  FMaskStageIcon.Free;
  FLayerStageIcon.Free;
  FLayerVisibleIcon.Free;

  inherited;
end;

// calculate an area from ARect for drawing EYE icon
function TicLayerPanelStdTheme.GetLayerVisibleIconRect(
  const APanelRect: TRect): TRect;
begin
  Result.TopLeft := APanelRect.TopLeft;
  Result.Right   := APanelRect.Left + FLayerVisibleIcon.Width + FObjectSpan;
  Result.Bottom  := APanelRect.Bottom;
end;

function TicLayerPanelStdTheme.GetPanelAreaAtXY(APanel: TicLayer;
  const APanelRect: TRect; const AX, AY: Integer): TicSelectedPanelArea;
var
  LRect      : TRect;
  LSize      : TSize;
  LTestPoint : TPoint;
  LBmp       : TBitmap32;
  LSpan2     : Integer;
begin
  Result     := spaUnknown;
  LTestPoint := Point(AX, AY);
  LSize      := icMath.GetRectSize(APanelRect);
  LSpan2     := FObjectSpan * 2;
  LBmp       := nil;

  // if point on layer visible mark ...

  LRect := GetLayerVisibleIconRect(APanelRect);

  if Windows.PtInRect(LRect, LTestPoint) then
  begin
    Result := spaVisibleMark;
    Exit;
  end;

  // if point on stage mark ...
  { TODO -ox2nie -cfunctionality : please fix it. temporary disabled for name convention }
  (*
  case APanel.LayerProcessStage of
    lpsLayer:
      begin   *)
        LBmp := FLayerStageIcon;
      (*end;

    lpsMask:
      begin
        LBmp := FMaskStageIcon;
      end;
  end;   *)

  LRect.Left  := LRect.Right + 1;
  LRect.Right := LRect.Left + LBmp.Width + FObjectSpan - 1;
  
  if Windows.PtInRect(LRect, LTestPoint) then
  begin
    Result := spaStageMark;
    Exit;
  end;

  // if point on layer logo thumbnail ...
  (*if APanel.IsLogoThumbEnabled then
  begin
    LRect.Left  := LRect.Right + 1;
    LRect.Right := LRect.Left + APanel.LogoThumbnail.Width + LSpan2 - 1;

    if Windows.PtInRect(LRect, LTestPoint) then
    begin
      Result := spaLogoThumbnail;
      Exit;
    end;
  end;  *)
  
  // if point on layer thumbnail ...
  (*if APanel.IsLayerThumbEnabled then*)
  begin
    LRect.Left  := LRect.Right + 1;
    LRect.Right := LRect.Left + APanel.LayerThumbnail.Width + LSpan2 - 1;

    if Windows.PtInRect(LRect, LTestPoint) then
    begin
      Result := spaLayerThumbnail;
      Exit;
    end;
  end;

  // if mask enabled ...
  (*
  if APanel.IsMaskEnabled then
  begin
    // if point on Mask-Link mark ...

    if APanel.IsMaskLinked then
    begin
      LBmp := FMaskLinkedIcon;
    end
    else
    begin
      LBmp := FMaskUnlinkedIcon;
    end;

    LRect.Left  := LRect.Right + 1;
    LRect.Right := LRect.Left + LBmp.Width + FObjectSpan - 1;

    if Windows.PtInRect(LRect, LTestPoint) then
    begin
      Result := spaMaskLinkageMark;
      Exit;
    end;

    // if point on Mask thumbnail ...

    LRect.Left  := LRect.Right + 1;
    LRect.Right := LRect.Left + APanel.MaskThumbnail.Width + LSpan2 - 1;

    if Windows.PtInRect(LRect, LTestPoint) then
    begin
      Result := spaMaskThumbnail;
      Exit;
    end;
  end; *)

  // if point on caption area ...

  LRect.Left   := LRect.Right + 1;
  LRect.Right  := APanelRect.Right;

  if Windows.PtInRect(LRect, LTestPoint) then
  begin
    Result := spaLayerCaption;
  end;
  
end;

procedure TicLayerPanelStdTheme.DrawLayerVisibleIcon(ABuffer: TBitmap32;
  const ARect: TRect; const AVisible: Boolean);
var
  LRectSize : TSize;
  LIconRect : TRect;
begin
  LRectSize := icMath.GetRectSize(ARect);

  LIconRect.Left   := ARect.Left + (LRectSize.cx - FLayerVisibleIcon.Width) div 2;
  LIconRect.Top    := ARect.Top  + (LRectSize.cy - FLayerVisibleIcon.Height) div 2;
  LIconRect.Right  := LIconRect.Left + FLayerVisibleIcon.Width;
  LIconRect.Bottom := LIconRect.Top  + FLayerVisibleIcon.Height;

  if AVisible then
  begin
    ABuffer.Draw(LIconRect, FLayerVisibleIcon.BoundsRect, FLayerVisibleIcon);
  end;
  
  ABuffer.FrameRectS(LIconRect, clGray32);
end;

procedure TicLayerPanelStdTheme.DrawProcessStageIcon(ABuffer: TBitmap32;
  const ARect: TRect; const AStage: TicLayerProcessStage);
var
  LRectSize : TSize;
  LIconRect : TRect;
  LBmp      : TBitmap32;
begin
  LRectSize := icMath.GetRectSize(ARect);
  LBmp      := nil;

  case AStage of
    lpsLayer:
      begin
        LBmp := FLayerStageIcon;
      end;

    lpsMask:
      begin
        LBmp := FMaskStageIcon;
      end;
  end;

  LIconRect.Left   := ARect.Left + (LRectSize.cx - LBmp.Width) div 2;
  LIconRect.Top    := ARect.Top + (LRectSize.cy - LBmp.Height) div 2;
  LIconRect.Right  := LIconRect.Left + LBmp.Width;
  LIconRect.Bottom := LIconRect.Top  + LBmp.Height;

  ABuffer.Draw(LIconRect, LBmp.BoundsRect, LBmp);
  ABuffer.FrameRectS(LIconRect, clGray32);
end;

procedure TicLayerPanelStdTheme.DrawMaskLinkIcon(ABuffer: TBitmap32;
  const ARect: TRect; const ALinked: Boolean);
var
  LRectSize : TSize;
  LIconRect : TRect;
  LBmp      : TBitmap32;
begin
  LRectSize := icMath.GetRectSize(ARect);

  if ALinked then
  begin
    LBmp := FMaskLinkedIcon;
  end
  else
  begin
    LBmp := FMaskUnlinkedIcon;
  end;

  LIconRect.Left   := ARect.Left + (LRectSize.cx - LBmp.Width) div 2;
  LIconRect.Top    := ARect.Top + (LRectSize.cy - LBmp.Height) div 2;
  LIconRect.Right  := LIconRect.Left + LBmp.Width;
  LIconRect.Bottom := LIconRect.Top  + LBmp.Height;

  ABuffer.Draw(LIconRect, LBmp.BoundsRect, LBmp);
end;

procedure TicLayerPanelStdTheme.DrawPanelBorder(ABuffer: TBitmap32;
  const ARect: TRect);
begin
  ABuffer.LineS(ARect.Left, ARect.Top, ARect.Left, ARect.Bottom, clWhite32);
  ABuffer.LineS(ARect.Left, ARect.Top, ARect.Right, ARect.Top, clWhite32);
  ABuffer.LineS(ARect.Right, ARect.Top, ARect.Right, ARect.Bottom, clGray32);
  ABuffer.LineS(ARect.Left, ARect.Bottom, ARect.Right, ARect.Bottom, clGray32);
end;

procedure TicLayerPanelStdTheme.Paint(ABuffer: TBitmap32;
  APanel: TicLayer; const ARect: TRect);
var
  LRect         : TRect;
  LSize         : TSize;
  LBmp          : TBitmap32;
  LCaptionColor : TColor32;
begin
  LSize := icMath.GetRectSize(ARect);
  LBmp  := nil;

  ABuffer.BeginUpdate;
  try
    // draw layer visible mark
    LRect := GetLayerVisibleIconRect(ARect);
    DrawLayerVisibleIcon(ABuffer, LRect, APanel.Visible);
    ABuffer.LineS(LRect.Right, LRect.Top, LRect.Right, LRect.Bottom, FSpanColor);

    // draw process stage mark
    (*
    case APanel.LayerProcessStage of
      lpsLayer:
        begin   *)
          LBmp := FLayerStageIcon;
        (*end;

      lpsMask:
        begin
          LBmp := FMaskStageIcon;
        end;
    end;   *)

    LRect.Left  := LRect.Right;
    LRect.Right := LRect.Left + LBmp.Width + FObjectSpan;
    (*DrawProcessStageIcon(ABuffer, LRect, APanel.LayerProcessStage);*)
    ABuffer.LineS(LRect.Right, LRect.Top, LRect.Right, LRect.Bottom, FSpanColor);
    (*
    // draw logo thumbnail
    if APanel.IsLogoThumbEnabled then
    begin
      LRect.Left   := LRect.Right + FObjectSpan;
      LRect.Top    := LRect.Top + (LSize.cy - APanel.LogoThumbnail.Height) div 2;
      LRect.Right  := LRect.Left + APanel.LogoThumbnail.Width;
      LRect.Bottom := LRect.Top + APanel.LogoThumbnail.Height;
      ABuffer.Draw(LRect.Left, LRect.Top, APanel.LogoThumbnail);

      LRect.Top    := ARect.Top;
      LRect.Right  := LRect.Right + FObjectSpan;
      LRect.Bottom := ARect.Bottom;
    ABuffer.LineS(LRect.Right, LRect.Top, LRect.Right, LRect.Bottom, FSpanColor);
    end;*)

    // draw layer thumbnail
    (*if APanel.IsLayerThumbEnabled then*)
    begin
    LRect.Left   := LRect.Right + FObjectSpan;
    LRect.Top    := LRect.Top + (LSize.cy - APanel.LayerThumbnail.Height) div 2;
    LRect.Right  := LRect.Left + APanel.LayerThumbnail.Width;
    LRect.Bottom := LRect.Top + APanel.LayerThumbnail.Height;
    ABuffer.Draw(LRect.Left, LRect.Top, APanel.LayerThumbnail);

    LRect.Top    := ARect.Top;
    LRect.Right  := LRect.Right + FObjectSpan;
    LRect.Bottom := ARect.Bottom;
    ABuffer.LineS(LRect.Right, LRect.Top, LRect.Right, LRect.Bottom, FSpanColor);
    end;

    // draw Mask-Link mark
    (*if APanel.IsMaskEnabled then
    begin
      if APanel.IsMaskLinked then
      begin
        LBmp := FMaskLinkedIcon;
      end
      else
      begin
        LBmp := FMaskUnlinkedIcon;
      end;

      LRect.Left  := LRect.Right;
      LRect.Right := LRect.Left + LBmp.Width + FObjectSpan;
      DrawMaskLinkIcon(ABuffer, LRect, APanel.IsMaskLinked);
      ABuffer.LineS(LRect.Right, LRect.Top, LRect.Right, LRect.Bottom, FSpanColor);

      // draw Mask thumbnail
      LRect.Left   := LRect.Right + FObjectSpan;
      LRect.Top    := ARect.Top + (LSize.cy - APanel.MaskThumbnail.Height) div 2;
      LRect.Right  := LRect.Left + APanel.MaskThumbnail.Width;
      LRect.Bottom := ARect.Top + APanel.MaskThumbnail.Height;
      ABuffer.Draw(LRect.Left, LRect.Top, APanel.MaskThumbnail);

      LRect.Top    := ARect.Top;
      LRect.Right  := LRect.Right + FObjectSpan;
      LRect.Bottom := ARect.Bottom;
      ABuffer.LineS(LRect.Right, LRect.Top, LRect.Right, LRect.Bottom, FSpanColor);
    end;*)


    // fill background color for the panel
    LRect.Left   := LRect.Right + 1;
    LRect.Top    := ARect.Top;
    LRect.Right  := ARect.Right;
    LRect.Bottom := ARect.Bottom;

    if APanel.IsSelected then
    begin
      if APanel.IsLayerEnabled then
      begin
        ABuffer.FillRectS(LRect, FSelectedColor);
        LCaptionColor := clWhite32;
      end
      else
      begin
        ABuffer.FillRectS(LRect, FDisabledColor);
        LCaptionColor := clBlack32;
      end;
    end
    else
    begin
      ABuffer.FillRectS(LRect, FDeselectedColor);
      LCaptionColor := clBlack32;
    end;

    // draw panel caption
    LRect.Left := LRect.Left + FObjectSpan;
    LRect.Top  := LRect.Top + ( LSize.cy - ABuffer.TextHeight(APanel.DisplayName) ) div 2;

    ABuffer.RenderText(LRect.Left, LRect.Top, APanel.DisplayName, 0, LCaptionColor);
    // draw panel border
    DrawPanelBorder(ABuffer, ARect);
  finally
    ABuffer.EndUpdate;
  end;
end;

function TicLayerPanelStdTheme.GetSnapshot(APanel: TicLayer;
  const AWidth, AHeight: Integer): TBitmap32;
var
  LBackColor : TColor32;
begin
  Result := nil;

  if not Assigned(APanel) then
  begin
    Exit;
  end;

  if (AWidth <= 0) or (AHeight < LAYER_PANEL_HEIGHT) then
  begin
    Exit;
  end;

  LBackColor := Color32(clBtnFace);

  Result             := TBitmap32.Create;
  Result.DrawMode    := dmBlend;
  Result.CombineMode := cmMerge;
  
  Result.SetSize(AWidth, AHeight);
  Result.Clear(LBackColor);

  Self.Paint(Result, APanel, Result.BoundsRect);
  Result.FrameRectS(Result.BoundsRect, LBackColor); // clear border
end;

{ TicLayerManager }

constructor TicLayerPanelManager.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle := [csAcceptsControls, csCaptureMouse, csClickEvents,
                   csDoubleClicks, csReplicatable, csOpaque];
    
  Options := [pboAutoFocus, pboWantArrowKeys];
  TabStop := True; //to receive Tabkey and focusable as default 

  FScrollLocked   := False;
  FViewportOffset := Point(0, 0);
  FLeftButtonDown := False;
  FWheelDelta     := LAYER_PANEL_HEIGHT div 2;

  FPanelTheme := TicLayerPanelStdTheme.Create;

  FVertScroll := TRangeBar.Create(Self);
  with FVertScroll do
  begin
    Parent       := Self;
    BorderStyle  := bsNone;
    Kind         := sbVertical;
    Align        := alRight;
    Width        := GetSystemMetrics(SM_CYVSCROLL) div 3 * 2;
    OnUserChange := ScrollHandler;
  end;

  // for render snapshot of a moving panel by mouse move
  FPanelSnapshot := nil;
  FScrollThread  := nil;
  FIsPanelMoving := False;
end;

destructor TicLayerPanelManager.Destroy;
begin
  ScrollThreadStop;
  FPanelSnapshot.Free;
  FVertScroll.Free;
  FPanelTheme.Free;

  inherited;
end;

procedure TicLayerPanelManager.Resize;
var
  LHeight : Integer;
  LDelta  : Integer;
begin
  inherited;

  LHeight := FWorkSize.Y + Self.FViewportOffset.Y;

  if LHeight < Self.ClientHeight then
  begin
    LDelta := Self.ClientHeight - LHeight;

    Inc(FViewportOffset.Y, LDelta);

    if FViewportOffset.Y > 0 then
    begin
      FViewportOffset.Y := 0;
    end;

    FScrollLocked := True;
    try
      FVertScroll.Position := Abs(FViewportOffset.Y);
    finally
      FScrollLocked := False;
    end;
  end;
end;

procedure TicLayerPanelManager.SetLayerList(const AValue: TLayerCollection);
begin
  FLayerList := AValue;
  CheckLayout;
  
  // make the selected panel fully showing in the viewport ...
  FViewportOffset := Point(0, 0);
  ScrollSelectedPanelInViewport;
  
  Invalidate;
end;

procedure TicLayerPanelManager.ScrollThreadStop;
begin
  if Assigned(FScrollThread) then
  begin
    FScrollThread.Terminate;
    //FScrollThread.WaitFor;
    FreeAndNil(FScrollThread);
  end;
end;

function TicLayerPanelManager.GetPanelRect(const APanelIndex: Integer): TRect;
begin
  Result.Left   := 0;
  ///Result.Top    := (FLayerList.MaxIndex - APanelIndex) * LAYER_PANEL_HEIGHT + FViewportOffset.Y;
  Result.Top    := (FLayerList.Count-1 - APanelIndex) * LAYER_PANEL_HEIGHT + FViewportOffset.Y;
  Result.Right  := Self.ClientWidth - 1;
  Result.Bottom := Result.Top + LAYER_PANEL_HEIGHT - 1;
end;

function TicLayerPanelManager.GetPanelIndexAtXY(AX, AY: Integer): Integer;
var
  LYActual: Integer;
begin
  Result := -1;

  if Assigned(FLayerList) and (FLayerList.Count > 0) then
  begin
    LYActual := AY + Abs(FViewportOffset.Y);

    if LYActual < FWorkSize.Y then
    begin
      Result := FLayerList.Count - LYActual div LAYER_PANEL_HEIGHT -1;
    end;
  end;
end;

function TicLayerPanelManager.CanScrollDown: Boolean;
begin
  Result := FViewportOffset.Y + FWorkSize.Y > Self.ClientHeight;
end;

function TicLayerPanelManager.CanScrollUp: Boolean;
begin
  Result := FViewportOffset.Y < 0;
end;

// dertermine if any part of a rect is in the viewport
function TicLayerPanelManager.IsRectInViewport(const ARect: TRect): Boolean;
begin
  Result := Windows.PtInRect(Self.ClientRect, ARect.TopLeft) or
            Windows.PtInRect(Self.ClientRect, ARect.BottomRight);
end;

procedure TicLayerPanelManager.ScrollHandler(Sender: TObject);
begin
  if Sender = FVertScroll then
  begin
    if not FScrollLocked then
    begin
      FViewportOffset.Y := 0 - Round(FVertScroll.Position);
      Invalidate;
    end;
  end;
end;

procedure TicLayerPanelManager.PreparePanelSnapshotRendering(
  const AMouseX, AMouseY: Integer);
var
  LPanelIndex : Integer;
  LPanelRect  : TRect;
  LPanel      : TCustomLayer;
begin
  FMovingPanelIndex := -1;
  FMovingPanel := nil;

  if Assigned(FLayerList) and (FLayerList.Count > 0) then
  begin
    LPanelIndex := GetPanelIndexAtXY(AMouseX, AMouseY);
    LPanel      := FLayerList[LPanelIndex];

    if Assigned(LPanel) then
    begin
      FMovingPanel      := TicLayer(LPanel);
      FMovingPanelIndex := LPanelIndex;
      LPanelRect        := Self.GetPanelRect(LPanelIndex);
      FSnapshotOffsetY  := LPanelRect.Top - AMouseY;

      if Assigned(FPanelSnapshot) then
      begin
        FreeAndNil(FPanelSnapshot);
      end;

      FPanelSnapshot := GetPanelSnapshot(LPanelIndex);
      FPanelSnapshot.MasterAlpha := $7F;
    end;
  end;
end;

procedure TicLayerPanelManager.CheckLayout;
begin
  if Assigned(FLayerList) then
  begin
    // update WorkSize
    FWorkSize         := Point(Self.ClientWidth, FLayerList.Count * LAYER_PANEL_HEIGHT);
    FVertScroll.Range := FWorkSize.Y;
  end;
end;

procedure TicLayerPanelManager.Scroll(Dy: Integer);
var
  LHeight : Integer;
begin
  FViewportOffset.Y := FViewportOffset.Y + Dy;

  // limit the scrolling amount
  LHeight := FViewportOffset.Y + FWorkSize.Y;
  if LHeight < Self.ClientHeight then
  begin
    Inc(FViewportOffset.Y, Self.ClientHeight - LHeight);
  end;

  if FViewportOffset.Y > 0 then
  begin
    FViewportOffset.Y := 0;
  end;

  // update scroll bar
  FScrollLocked := True;
  try
    FVertScroll.Position := Abs(FViewportOffset.Y);
  finally
    FScrollLocked := False;
  end;
end;

procedure TicLayerPanelManager.DoPaintBuffer;
var
  i, y, LMaxY : Integer;
  LLayer      : TCustomLayer;
  LRect       : TRect;
begin
  CheckLayout;
  Buffer.Clear( Color32(clBtnFace) );

  if Assigned(FLayerList) then
  begin
    if FLayerList.Count > 0 then
    begin
      for i := FLayerList.Count-1 downto 0 do
      begin
        LLayer := FLayerList[i];
        LRect       := GetPanelRect(i);

        // only render the panel that in the viewport area...
        if IsRectInViewport(LRect) and (LLayer is TicLayer) then
        begin
          FPanelTheme.Paint(Buffer, TicLayer(LLayer), LRect);
        end;
      end;

      // render panel snapshot, if any ...
      if FIsPanelMoving then
      begin
        LMaxY := Min(FWorkSize.Y, Self.ClientHeight) - LAYER_PANEL_HEIGHT;
        y     := FMouseY + FSnapshotOffsetY;
        y     := Clamp(y, 0, LMaxY);

        Buffer.Draw(0, y, FPanelSnapshot);

        FSnapshotTopLeft := Point(0, y); // for other use ...
      end;
    end;
  end;

  Buffer.FrameRectS(Buffer.BoundsRect, clBlack32);
end;

procedure TicLayerPanelManager.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  LIndex      : Integer;
  LPanelRect  : TRect;
  LLayer : TicLayer;
begin
  if Button = mbLeft then
  begin
    FMouseDownX    := X;
    FMouseDownY    := Y;
    FLastX         := X;
    FLastY         := Y;
    FIsPanelMoving := False;
    LIndex := GetPanelIndexAtXY(X, Y);

    // dealing with double click on a panel
    if ssDouble	in Shift then
    begin

      if LIndex >= 0 then
      begin
        LPanelRect  := Self.GetPanelRect(LIndex);
        LLayer := FLayerList[LIndex] as TicLayer;

        case FPanelTheme.GetPanelAreaAtXY(LLayer, LPanelRect, X, Y) of
          spaLayerThumbnail:
            begin
              if Assigned(LLayer.OnLayerThumbDblClick) then
              begin
                LLayer.OnLayerThumbDblClick(LLayer);
              end;
            end;
          (*
          spaMaskThumbnail:
            begin
              if Assigned(LLayerPanel.OnMaskThumbDblClick) then
              begin
                LLayerPanel.OnMaskThumbDblClick(LLayerPanel);
              end;
            end;

          spaLogoThumbnail:
            begin
              if Assigned(LLayerPanel.OnLogoThumbDblClick) then
              begin
                LLayerPanel.OnLogoThumbDblClick(LLayerPanel);
              end;
            end;
           *)
          spaLayerCaption:
            begin
              if Assigned(LLayer.OnPanelDblClick) then
              begin
                LLayer.OnPanelDblClick(LLayer);
              end;
            end;
        end;
      end;
    end
    else
    begin
      // If the Double-Click has not been fired, we mark
      // the mouse left button is pressed. Doing this is for
      // preventing from the Double-Click opens a dialog and
      // after the dialog is closed, the current panel is still
      // in Moving mode.
      if (LIndex >= 0) and (FLayerList[LIndex] is TicLayer) then // exclude rubber band wich is TElasticLayer
      begin
        LLayer := FLayerList[LIndex] as TicLayer;
        TicPaintBoxAccess(FLayerList.Owner).SelectedLayer := LLayer;
      end;
      FLeftButtonDown := True;
    end;
  end;

  inherited; // respond to OnMouseDown
end;

procedure TicLayerPanelManager.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  FMouseX := X;
  FMouseY := Y;

  if FLeftButtonDown then
  begin
    if Abs(FMouseY - FMouseDownY) > 8 then
    begin
      if not FIsPanelMoving then
      begin
        // prepare for moving a panel that under current mouse position
        PreparePanelSnapshotRendering(X, Y);
        FIsPanelMoving := Assigned(FPanelSnapshot);
      end;
    end;

    if FIsPanelMoving then
    begin
      if not Assigned(FScrollThread) then
      begin
        FScrollThread := TicScrollPanelThread.Create(Self);
      end;
      
      if Y <> FLastY then
      begin
        Invalidate;
      end;
    end;

    FLastX := X;
    FLastY := Y;
  end;
  
  inherited; // respond to OnMouseMove
end;

procedure TicLayerPanelManager.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  LIndex      : Integer;
  LLayer      : TicLayer;
  LPanelRect  : TRect;
  LValidArea  : TRect;
  LPos        : TPoint;
begin
  if FLeftButtonDown then
  begin
    FLeftButtonDown := False;

    if Assigned(FLayerList) then
    begin
      if FIsPanelMoving then
      begin
        FIsPanelMoving := False;
        ScrollThreadStop;

        LValidArea.TopLeft := ClientRect.TopLeft;
        LValidArea.Right   := ClientWidth;
        LValidArea.Bottom  := Min(ClientHeight, FWorkSize.Y);
        
        if Windows.PtInRect( LValidArea, Point(X, Y) ) then
        begin
          LPos := Point(X, Y);
        end
        else
        begin
          // get center point of the snapshot of a moving layer panel
          LPos.X := FSnapshotTopLeft.X + ClientWidth div 2;
          LPos.Y := FSnapshotTopLeft.Y + LAYER_PANEL_HEIGHT div 2;
        end;

        LIndex := GetPanelIndexAtXY(LPos.X, LPos.Y);

        // If the layer order is changed, the external callbacks should to
        // take care of the refreshing of the GUI of layer manager,
        // otherwise, we should to refresh the view by ourselves.
        if (FMovingPanelIndex <> LIndex) then
        begin
          ///FLayerList.Move(FMovingPanelIndex, LIndex);
          FMovingPanel.Index := LIndex;
          //FLayerList.SelectLayerPanel(LIndex);
          GIntegrator.InvalidateListeners;
        end
        else
        begin
          Invalidate;
        end;
      end
      else
      begin
        LIndex := GetPanelIndexAtXY(X, Y);

        if LIndex >= 0 then
        begin
          LPanelRect  := Self.GetPanelRect(LIndex);
          LLayer := FLayerList[LIndex] as TicLayer;

          case FPanelTheme.GetPanelAreaAtXY(LLayer, LPanelRect, X, Y) of
            spaVisibleMark:
              begin
                LLayer.Visible := not LLayer.Visible;
              end;

            spaStageMark:
              begin
                // do nothing yet
              end;

            spaLayerThumbnail:
              begin
                ///FLayerList.SelectLayerPanel(LIndex);
                TicPaintBoxAccess(FLayerList.Owner).SelectedLayer := LLayer;
                //FLayerList.SelectedPanel.LayerProcessStage := lpsLayer;
              end;
            (*
            spaMaskLinkageMark:
              begin
                LLayerPanel.IsMaskLinked := not LLayerPanel.IsMaskLinked;
              end;

            spaMaskThumbnail:
              begin
                FLayerList.SelectLayerPanel(LIndex);
                FLayerList.SelectedPanel.LayerProcessStage := lpsMask;
              end;
            *)
            spaLogoThumbnail,
            spaLayerCaption:
              begin
                //FLayerList.SelectLayerPanel(LIndex);
                TicPaintBoxAccess(FLayerList.Owner).SelectedLayer := LLayer;
              end;
          end;

          if ScrollSelectedPanelInViewport then
          begin
            Invalidate;
          end;
        end;
      end;
    end;
  end;

  inherited;  // respond to OnMouseUp
end;

procedure TicLayerPanelManager.KeyDown(var Key: Word; Shift: TShiftState);
var
  LCurIndex    : Integer;
  LTargetIndex : Integer;
  LLayer : TicLayer;
begin
  if FIsPanelMoving then
  begin
    Exit;
  end;

  if Assigned(FLayerList) and (FLayerList.Count > 1) then
  begin
          LLayer := TicPaintBoxAccess(FLayerList.Owner).SelectedLayer;
          LCurIndex := LLayer.Index;
    case Key of
      VK_UP:
        begin
          ///LCurIndex    := FLayerList.SelectedIndex;
          LTargetIndex := LCurIndex + 1;

          if LCurIndex < FLayerList.Count then
          begin
            if ssShift in Shift then
            begin
              //FLayerList.Move(LCurIndex, LTargetIndex);
              LLayer.Index := LTargetIndex;
            end
            else
            begin
              //FLayerList.SelectLayerPanel(LTargetIndex);
              TicPaintBoxAccess(FLayerList.Owner).SelectedLayer := LLayer;
            end;

            ScrollSelectedPanelInViewport;
          end;
        end;
        
      VK_DOWN:
        begin
          ///LCurIndex    := FLayerList.SelectedIndex;
          
          LTargetIndex := LCurIndex - 1;

          if LCurIndex > 0 then
          begin
            if ssShift in Shift then
            begin
              ///FLayerList.Move(LCurIndex, LTargetIndex);
              LLayer.Index := LTargetIndex;
            end
            else
            begin
              //FLayerList.SelectLayerPanel(LTargetIndex);
              with TicPaintBoxAccess(FLayerList.Owner) do
              begin
                SelectedLayer := TicLayer(Layers[LTargetIndex]); 
              end;
            end;

            ScrollSelectedPanelInViewport;
          end;
        end;
    end;
  end;

  inherited;  // respond to OnKeyDown
end;

function TicLayerPanelManager.ScrollPanelInViewport(
  const APanelIndex: Integer): Boolean;
var
  LRect : TRect;
begin
  Result := False;
  
  if Assigned(FLayerList) and (FLayerList.Count > 0) and (APanelIndex < FLayerList.Count ) then
  begin
    LRect := GetPanelRect(APanelIndex);

    if LRect.Top < Self.ClientRect.Top then
    begin
      Self.Scroll(Self.ClientRect.Top - LRect.Top);
      Result := True;
    end
    else if LRect.Bottom > Self.ClientRect.Bottom then
    begin
      Self.Scroll(Self.ClientRect.Bottom - LRect.Bottom);
      Result := True;
    end;
  end;
end;

function TicLayerPanelManager.ScrollSelectedPanelInViewport: Boolean;
var
  LIndex : Integer;
begin
  Result := False;
  
  if Assigned(FLayerList) and (FLayerList.Count > 0) and assigned(TicPaintBoxAccess(FLayerList.Owner).SelectedLayer) then
  begin
    ///LIndex := FLayerList.SelectedIndex;
    LIndex := TicPaintBoxAccess(FLayerList.Owner).SelectedLayer.Index;
    Result := ScrollPanelInViewport(LIndex);
  end;
end;

function TicLayerPanelManager.GetPanelSnapshot(
  const APanelIndex: Integer): TBitmap32;
var
  LPanel : TicLayer;
begin
  Result := nil;

  if Assigned(FLayerList) and (FLayerList.Count > 0) and (APanelIndex < FLayerList.Count ) then
  begin
    LPanel := FLayerList[APanelIndex] as TicLayer;
    Result := FPanelTheme.GetSnapshot(LPanel, Self.ClientWidth, LAYER_PANEL_HEIGHT);
  end;
end;

function TicLayerPanelManager.GetSelectedPanelSnapshot: TBitmap32;
begin
  Result := nil;

  if Assigned(FLayerList) then
  begin
    ///Result := GetPanelSnapshot(FLayerList.SelectedIndex);
    Result := GetPanelSnapshot(TicPaintBoxAccess(FLayerList.Owner).SelectedLayer.Index);
  end;
end;

function TicLayerPanelManager.DoMouseWheelDown(Shift: TShiftState;
  MousePos: TPoint): Boolean;
begin
  Result := CanScrollDown;

  if Result then
  begin
    Self.Scroll(-FWheelDelta);
    Invalidate;
  end;
end;

function TicLayerPanelManager.DoMouseWheelUp(Shift: TShiftState;
  MousePos: TPoint): Boolean;
begin
  Result := CanScrollUp;

  if Result then
  begin
    Self.Scroll(FWheelDelta);
    Invalidate;
  end;
end;

{ TicScrollPanelThread }

constructor TicScrollPanelThread.Create(APanelManager: TicLayerPanelManager);
begin
  FPanelManager   := APanelManager;
  FreeOnTerminate := False;

  inherited Create(False);
  
  Priority := tpLower;
end;

procedure TicScrollPanelThread.Execute;
var needToScroll : boolean;
begin
  if Assigned(FPanelManager) then
  begin
    while (not Terminated) do
    begin
      needToScroll := false;
      with FPanelManager do
      begin
        if FIsPanelMoving and (FMouseX >= 0) and (FMouseX < ClientWidth) then
        begin
          if FMouseY < 0 then
          begin
            if CanScrollUp then
            begin
              Scroll(LAYER_PANEL_HEIGHT);
              Invalidate;
              needToScroll := true;
            end;
          end
          else if FMouseY > ClientHeight then
          begin
            if CanScrollDown then
            begin
              Scroll(-LAYER_PANEL_HEIGHT);
              Invalidate;
              needToScroll := true;
            end;
          end;

          if needToScroll then
          Sleep(100);
        end;
      end;
    end;
  end;
end;

end.
