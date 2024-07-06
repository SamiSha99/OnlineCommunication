Class SS_PanelScrollBar extends Component;

var Array<OCButton> Buttons;

var float maxScrollYPos;
var float scrollPoint; // from 0 - 1
var float simulatedScroll;
var bool isScrollingDrag;

// For holding up/down buttons, slide repeatedly
var bool isHolding;
var float HoldingTime;
var string HoldArgument;

var float MouseClickY;
// var float BarPosY;

function Init() 
{
    Buttons = Class'SS_Button'.static.BuildButtons(Buttons);
    simulatedScroll = 0;
    scrollPoint = 0;
}

function Reset()
{
    simulatedScroll = 0;
    scrollPoint = 0;
}

function RenderScrollBar(HUD H, SS_Panel p, float maskHeight, Vector2D pos)
{
    local float maskHeightClipped;
    local float topY, bottomY, y, x;
    local OCButton cb;
    local float dragY;

    maskHeight *= 0.8334f;

    maskHeightClipped = maskHeight/H.Canvas.ClipY;
    maxScrollYPos = p.PanelSizeY - maskHeightClipped;

    x = pos.X;
    y = pos.Y;

    // Do not ask, it works
    Buttons[3].Size.Y = maskHeight;
    cb = Buttons[3];
    p.RenderButton(H, cb, pos);
    Buttons[3] = cb;

    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255);
    topY = y - (maskHeight + Buttons[0].Size.Y)/2/H.Canvas.ClipY;
    bottomY = y + (maskHeight + Buttons[0].Size.Y)/2/H.Canvas.ClipY;
    
    cb = Buttons[0];
    p.RenderButton(H, cb, vect2d(x, topY));
    Buttons[0] = cb;

    cb = Buttons[1];
    p.RenderButton(H, cb, vect2d(x, bottomY));
    Buttons[1] = cb;
    
    topY = y - (maskHeight - Buttons[2].Size.Y)/2/H.Canvas.ClipY;
    bottomY = y + (maskHeight - Buttons[2].Size.Y)/2/H.Canvas.ClipY;

    cb = Buttons[2];
    
    dragY = 0;
    if(isScrollingDrag)
    {
        dragY = (p.GetMousePosY(H) - MouseClickY)/H.Canvas.ClipY;
        simulatedScroll = FClamp(((Lerp(topY, bottomY, scrollPoint) + dragY) - topY)/(bottomY - topY), 0, 1);
    }
    
    p.RenderButton(H, cb, vect2d(x, Lerp(topY, bottomY, simulatedScroll)));
    Buttons[2] = cb;
}

function Tick(HUD H, SS_Panel p, float d)
{
    if(!isScrollingDrag)
        simulatedScroll = Lerp(simulatedScroll, scrollPoint, d * 10);
    if(isHolding)
    {
        if(HoldingTime > 0.0f)
        {
            HoldingTime = FMax(0.0f, HoldingTime - d);
            if(HoldingTime <= 0.0f)
            {
                HoldingTime = 0.1f;
                ScrollByButton(H, p, HoldArgument ~= "down"); 
            }
        }
    }
}

function OnClick(HUD H, string Argument, SS_Panel p)
{
    local OCButton b;
    switch(Argument)
    {
        case "hold": 
            isScrollingDrag = true; 
            MouseClickY = p.GetMousePosY(H); 
            break;
        case "up": 
        case "down": 
            isHolding = true;
            HoldingTime = 0.5f;
            holdArgument = Argument;
            ScrollByButton(H, p, Argument ~= "down"); 
            break;
    }
    foreach Buttons(b) if(String(b.Argument) ~= Argument) p.PressedButton = b.MatInstance;
    p.PressedButton.SetScalarParameterValue(p.BUTTON_ON_CLICK, 1.0f);
    H.PlaySound(SoundCue'HatInTime_Hud.SoundCues.MenuNext');
}

// Buttons that nudges the panel up/down
function ScrollByButton(HUD H, SS_Panel p, optional bool down = false)
{
    local float normal;
    normal = 0.06f/MaxScrollYPos;
    scrollPoint = FClamp(scrollPoint + (down ? normal : -normal), 0.0f, 1.0f);
}

function OnRelease(HUD H, SS_Panel p)
{
    if(isScrollingDrag)
    {
        isScrollingDrag = false;
        MouseClickY = -1;
        scrollPoint = simulatedScroll;
    }
    
    isHolding = false;
}

defaultproperties
{
    Buttons(0) = {(
        ButtonID = "scrollbar",
        Argument = "up",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Up'
    )};
    Buttons(1) = {(
        ButtonID = "scrollbar",
        Argument = "down",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Down'
    )};
    Buttons(2) = {(
        ButtonID = "scrollbar",
        Argument = "hold",
        Size = (X = 48, Y = 96),
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_ScrollBar_Holder'
    )};
    Buttons(3) = {(
        ButtonID = "scrollbar",
        Argument = "empty",
        Size = (X = 48),
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Empty_Back',
        CanBeHovered = false
    )};
    MouseClickY = -1;
}