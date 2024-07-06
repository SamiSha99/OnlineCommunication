Class SS_PanelContent extends Component
    abstract;

const GAP_CONFIG = 0.25f;

var Name ContentName;
var bool ContentEnabled;
var string EnabledIf; // String of rules
var Array<OCButton> buttons;
var Vector2D ContentSizeClipped;

var Array<String> ToolTips;
var SS_ContentToolTip_Text Tooltip;
var Class<SS_ContentToolTip_Text> ToolTipClass;

function Init()
{
    BuildButtons();
}

function OnUpdateContent()
{
    if(Tooltip != None)
        Tooltip.OnUpdateRequest();
}

function SS_GameMod_PingSystem GetGameMod()
{
    return SS_GameMod_PingSystem(class'OnlineCommunication'.static.GetGameMod('SS_GameMod_PingSystem'));
}

// The Content Renderer
function RenderContent(HUD H, SS_Panel panel, float x, float y);

// The Tick function
function TickContent(HUD H, float d);

// Renders buttons and sends OnHover response to the Panel to figure out which button they are hovering on, this is bad if buttons overlap.
function RenderButton(HUD H, SS_Panel panel, int i, Vector2D pos)
{
    local bool isHovering;

    panel.DrawCenterMat(H, pos.X * H.Canvas.ClipX, pos.Y * H.Canvas.ClipY, Buttons[i].size.X * panel.Scale, Buttons[i].size.Y * panel.Scale, Buttons[i].matInstance);
    
    if(!ContentEnabled || !Buttons[i].CanBeHovered) return;
    
    if(!Panel.ConfigMenu.IsUsingKeys)
        isHovering = ContentEnabled && panel.IsMouseInArea(H, pos.X * H.Canvas.ClipX, pos.Y * H.Canvas.ClipY, Buttons[i].size.X * panel.Scale, Buttons[i].size.Y * panel.Scale);
    else if (Panel.HoveredButtonIndex != INDEX_NONE && Panel.HoveredContent.ContentName == ContentName && Panel.HoveredButtonIndex == i) 
    {
        isHovering = ContentEnabled;
    }
    Buttons[i].BeingHovered = isHovering;
    if(isHovering) 
        panel.OnHover(H, Buttons[i]);
    if(Buttons[i].MatInstance != None)
        Buttons[i].MatInstance.SetScalarParameterValue(class'SS_Panel'.const.BUTTON_ON_HOVER, IsHovering ? 1.0f : 0.0f);       
}

// Called by Init() builds the buttons and their mat instances
function BuildButtons()
{
    local int i;
    for(i = 0; i < Buttons.Length; i++) Buttons[i].ButtonID = ContentName;
    Buttons = Class'SS_Button'.static.BuildButtons(Buttons);
}

function OnContentHover()
{
    if(ToolTips.Length <= 0) return;
    if(ToolTip == None)
        ToolTip = new ToolTipClass;
    

    if(ToolTip != None)
        ToolTip.InitToolTip(Tooltips);
}

// OnClick recieved due to Hover being valid for this class
function OnClickContent(HUD H, SS_Panel panel, string arg)
{
    OnUpdateContent();
}

// Call this to update all components, assuming they are using OnUpdateContent()
function UpdateMainPanel(HUD H)
{
    local SS_HUDMenu_PingSystemConfig hud;
    hud = SS_HUDMenu_PingSystemConfig(Hat_HUD(H).GetHUD(Class'SS_HUDMenu_PingSystemConfig'));
    hud.Panels[hud.SelectedPanel].UpdatePanelContent();
}

defaultproperties
{
    ContentEnabled = true;
    ContentSizeClipped = (Y = 0.0555f); // In Clip
    ToolTipClass = Class'SS_ContentToolTip_Text';
}