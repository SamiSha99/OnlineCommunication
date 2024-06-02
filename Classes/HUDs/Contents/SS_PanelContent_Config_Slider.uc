// Also includes selection values for custom ones, assuming this will ever happen
Class SS_PanelContent_Config_Slider extends SS_PanelContent_Config_Base;

var float SliderMin, SliderMax;

var float SliderPosNormal;
var float dragLength;
var float leftEnd, rightEnd;

var int PointsAmount; // If -1 = Loose slider
var int DecimalAmount;

var bool IsSliding;
var Vector2D handlerClickPos, Clips;

var string DragText;
var bool Precentage;

function RenderContent(HUD H, SS_Panel panel, float x, float y)
{
    local Vector2D pos, mousePos;
    local float opacity, handlerPosX, sliderWidthHalf;
    local string msg;
    local float textLengthX, textLengthY;

    Super.RenderContent(H, panel, x, y);
    pos.Y = y;
    opacity = 255;  
    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, opacity);
    
    // Slider Position
    pos.X = x + GAP_CONFIG - GAP_OFFSET - GAP_RIGHT_SLIDER;
    RenderButton(H, panel, 0, pos);

    // Handler Math Hell
    sliderWidthHalf = (Buttons[0].Size.X * panel.Scale)/2/H.Canvas.ClipX;
    leftEnd  = x + GAP_CONFIG - GAP_OFFSET - GAP_RIGHT_SLIDER - sliderWidthHalf;
    rightEnd = x + GAP_CONFIG - GAP_OFFSET - GAP_RIGHT_SLIDER + sliderWidthHalf;
    Clips.X = H.Canvas.ClipX;
    Clips.Y = H.Canvas.ClipY;
    handlerPosX = Lerp(leftEnd, rightEnd, FClamp(SliderPosNormal, 0, 1));

    msg = FormatValue(SliderMin);
    panel.DrawBorderedText(H.Canvas, msg, leftEnd * H.Canvas.ClipX - Buttons[1].Size.X*3/4 * panel.Scale, pos.Y * H.Canvas.ClipY, 0.3f, true, TextAlign_Right);
    
    msg = FormatValue(SliderMax);
    panel.DrawBorderedText(H.Canvas, msg, rightEnd * H.Canvas.ClipX + Buttons[1].Size.X*3/4 * panel.Scale, pos.Y * H.Canvas.ClipY, 0.3f, true, TextAlign_Left);

    if(IsSliding)
    {
        mousePos = panel.GetMousePos(H);
        mousePos.X /= H.Canvas.ClipX;
        mousePos.Y /= H.Canvas.ClipY;
        dragLength = FClamp(handlerPosX + mousePos.X - handlerClickPos.X, leftEnd, rightEnd);

        if(PointsAmount != 0)
        {
            pos.X = leftEnd + Round((dragLength - leftEnd)/(rightEnd - leftEnd) * PointsAmount)/float(PointsAmount) * (rightEnd - leftEnd);
        }
        else
            pos.X = dragLength;
    }
    else
    {
        dragLength = FClamp(handlerPosX, leftEnd, rightEnd);
        pos.X = Lerp(leftEnd, rightEnd, FClamp(SliderPosNormal, 0, 1));
    } 
    
    RenderButton(H, panel, 1, pos);
    if(Buttons[1].BeingHovered)
    {
        msg = FormatValue(PointToValue());
        H.Canvas.TextSize(msg, textLengthX, textLengthY, 0.4f, 0.4f);
        Class'SS_Color'.static.SetDrawColor(H, 0, 0, 0, 192);
        panel.DrawCenter(H, pos.X * H.Canvas.ClipX, pos.Y * H.Canvas.ClipY - Buttons[1].Size.Y * panel.Scale, textLengthX * 1.4f, textLengthY + textLengthX * 0.4f, H.Canvas.DefaultTexture);
        Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, 255);
        panel.DrawBorderedText(H.Canvas, msg, pos.X * H.Canvas.ClipX, pos.Y * H.Canvas.ClipY - Buttons[1].Size.Y * panel.Scale, 0.4f, true, TextAlign_Center);
    }
}

function string FormatValue(float v)
{
    local string num;
    if(Precentage)
        num = Round(v * 100) $ "%" $ DragText;
    else
    {
        num $= v;
        num = (DecimalAmount <= 0 ? String(Int(num)) : Left(num, InStr(num, ".") + 1 + DecimalAmount)) $ DragText;
    }
    return num;
}

function OnClickContent(HUD H, SS_Panel panel, string arg)
{
    isSliding = false;
    if(arg ~= "slider-handle")
    {
        isSliding = true;
        Buttons[1].CanBeHovered = false;
        handlerClickPos = panel.GetMousePos(H);
        handlerClickPos.X /= Clips.X;
        handlerClickPos.Y /= Clips.Y;
    }

    Super.OnClickContent(H, panel, arg);
}

function CancelSlide()
{
    local float val;
    IsSliding = false;
    handlerClickPos = vect2d(0, 0);

    val = (dragLength - leftEnd)/(rightEnd - leftEnd);
    if(PointsAmount != 0)
        val = Round(val * PointsAmount)/float(PointsAmount);
    SliderPosNormal = FClamp(val, 0, 1);
    SaveGMConfig();
    Buttons[1].CanBeHovered = true;
}

function float PointToValue()
{
    local float val;
    val = (dragLength - leftEnd)/(rightEnd - leftEnd);
    if(PointsAmount != 0)
        val = Round(val * PointsAmount)/float(PointsAmount); // Yandere Dev will never recover from this line of code
    return Lerp(SliderMin, SliderMax, FClamp(val, 0, 1));
}

function SaveGMConfig()
{
    GetGameMod().ChatSettings.SetSettingFloat(ContentName, GetSliderSelectedValue());
}

function SetSettingValue()
{
    local float settingsVal;
    Buttons[0].MatInstance.SetScalarParameterValue('CutPointsAmount', PointsAmount + 1);
    settingsVal = GetGameMod().ChatSettings.GetSettingFloat(ContentName);
    SliderPosNormal = (settingsVal - SliderMin) / (SliderMax-SliderMin);
}

function float GetSliderSelectedValue()
{
    return Lerp(SliderMin, SliderMax, SliderPosNormal);
}

defaultproperties
{
    Buttons(0) = {(
        Argument = "slider",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Slider',
        Size = (X = 368, Y = 48),
        CanBeHovered = false
    )};
    Buttons(1) = {(
        Argument = "slider-handle",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_SliderHandle',
        Size = (X = 24, Y = 48),
        Shine = true
    )};
    PointsAmount = 0;
    SliderMin = 0.0f;
    sliderMax = 1.0f;
    dragLength = -1;
    DecimalAmount = 2;
}

