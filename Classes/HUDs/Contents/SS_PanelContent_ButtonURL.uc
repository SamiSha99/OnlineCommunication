Class SS_PanelContent_ButtonURL extends SS_PanelContent;

var string Localization;
var string URL;
var bool Shine;
function Init()
{
    Buttons[0].Shine = Shine;
    Super.Init();
}
function RenderContent(HUD H, SS_Panel panel, float x, float y)
{
    RenderButton(H, panel, 0, vect2d(x,y));
    panel.DrawBorderedText(H.Canvas, GetLocalization(), x * H.Canvas.ClipX, y * H.Canvas.ClipY, 0.5f * panel.Scale, true, TextAlign_Center);
}

function string GetLocalization()
{
    local string l;

    l = Class'SS_ChatFormatter'.static.GetSettingsLocalization(Localization, "ButtonURL");
    
    return Class'Hat_Localizer'.static.ContainsErrorString(l) ? Localization : l;
}

function OnClickContent(HUD H, SS_Panel panel, string arg)
{
    Super.OnClickContent(H, panel, arg);
    if(URL ~= "") return;
    Class'Hat_GameManager_Base'.static.OpenBrowserURL(URL);
}

defaultproperties
{
    Buttons(0) = {(
        Argument = "openlink",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Empty',
        Size = (X = 240, Y = 48)
    )};
}