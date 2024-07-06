Class SS_PanelContent_Header extends SS_PanelContent;

var bool Center;
var string Header;

function RenderContent(HUD H, SS_Panel panel, float x, float y)
{
    local float opacity;
    opacity = ContentEnabled ? 255 : 128;
    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, opacity);
    panel.DrawBorderedText(H.Canvas, GetLocalization(), (x - (Center ? 0.0f : GAP_CONFIG)) * H.Canvas.ClipX, Y * H.Canvas.ClipY, 0.625f * panel.Scale, true, Center ? TextAlign_Center : TextAlign_Left);
}

function string GetLocalization()
{
    local string l;

    l = Class'SS_HUDMenu_PingSystemConfig'.static.GetSettingsLocalization(Header, "Header");
    
    return Class'Hat_Localizer'.static.ContainsErrorString(l) ? Header : l;
}