Class SS_PanelContent_Config_Base extends SS_PanelContent;

const GAP_OFFSET = 0.075f;
const GAP_RIGHT_SLIDER = 0.05f;

function Init()
{
    Super.Init();
    SetSettingValue();
}

function RenderContent(HUD H, SS_Panel panel, float x, float y)
{
    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, ContentEnabled ? 255 : 128);
    panel.DrawBorderedText(H.Canvas, GetTitleLocalization(), (x - GAP_CONFIG + 0.01f) * H.Canvas.ClipX, Y * H.Canvas.ClipY, 0.5f * panel.Scale, true, TextAlign_Left);
    RenderConfigButton(H, panel, x, y);
}

function RenderConfigButton(HUD H, SS_Panel panel, float x, float y)
{
       
}

function string GetTitleLocalization()
{
    local string l;

    l = Class'SS_HUDMenu_PingSystemConfig'.static.GetSettingsLocalization(ContentName, "configs");
    
    return Class'Hat_Localizer'.static.ContainsErrorString(l) ? string(ContentName) : l;
}

// Happens when A/D gets pressed, varies between each config
function OnKeyPress(HUD H, SS_Panel panel, bool right, bool release)
{

}

function SetDefault()
{
    
}

function SetSettingValue()
{
    
}

// Refresh configs current settings just in case
function OnUpdateContent()
{
    Super.OnUpdateContent();
    SetSettingValue();
}

defaultproperties
{
    ContentName = "None"
}