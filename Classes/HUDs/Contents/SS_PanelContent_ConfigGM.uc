// Also includes selection values for custom ones, assuming this will ever happen
Class SS_PanelContent_ConfigGM extends SS_PanelContent_Config_Base;

var bool IsModConfig;
var GameModInfoConfig Config;
var int SelectedOptionIndex;

function RenderContent(HUD H, SS_Panel panel, float x, float y)
{
    local Vector2D pos;
    local float textSizeX, textSizeY, scale, opacity;

    Super.RenderContent(H, panel, x, y);

    pos.Y = y;
    opacity = 255;
    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, opacity);

    // Current choice text, also checkbox position
    pos.X = x + GAP_CONFIG - GAP_OFFSET - GAP_RIGHT_SLIDER;

    H.Canvas.TextSize(Config.OptionLabels[SelectedOptionIndex], textSizeX, textSizeY, 0.5f * panel.Scale, 0.5f * panel.Scale);
    scale = panel.scale * 0.55f * FMin(1.0f,  (GAP_OFFSET * 2 * H.Canvas.ClipX - Buttons[0].size.X * panel.Scale * 1.5f) / textSizeX);
    panel.DrawBorderedText(H.Canvas, Config.OptionLabels[SelectedOptionIndex], pos.X * H.Canvas.ClipX, pos.Y * H.Canvas.ClipY, scale, true, TextAlign_Center);
    
    // left button
    pos.X = x + GAP_CONFIG - (GAP_OFFSET*2) - GAP_RIGHT_SLIDER;
    RenderButton(H, panel, 0, pos);
    // right button
    pos.X = x + GAP_CONFIG - GAP_RIGHT_SLIDER;
    RenderButton(H, panel, 1, pos);
}

function int FindIndexOfOptionValue(int value, GameModInfoConfig c)
{
    local int i;
    for(i = 0; i < c.OptionValues.Length; i++) 
        if(c.OptionValues[i] == value) return i;
    return 0;
}

function bool FindGameModInfoConfig(out Array<GameModInfoConfig> gmics, out GameModInfoConfig gmic, coerce string id)
{
    local GameModInfo gmi;
    local GameModInfoConfig empty;
    
    if(gmics.Length == 0)
    {
        Class'GameMod'.static.GetClassMod(Class'SS_GameMod_PingSystem', gmi);
        gmics = gmi.configs;
    }

    if(id == "") return false;

    foreach gmics(gmic) if(gmic.id ~= id) return true;

    gmic = empty;
    
    return false;
}

function OnClickContent(HUD H, SS_Panel panel, string arg)
{
    local int lastIndex;
    
    lastIndex = config.OptionValues.Length - 1;
    
    if(arg ~= "up" && SelectedOptionIndex >= lastIndex)
        SelectedOptionIndex = 0;
    else if(arg ~= "down" && SelectedOptionIndex <= 0)
        selectedOptionIndex = lastindex;
    else
        selectedOptionIndex += (arg ~= "up" ? 1 : -1);
    SaveGMConfig();
    Super.OnClickContent(H, panel, arg);
}

function SaveGMConfig()
{
    if(IsModConfig)
        Class'GameMod'.static.SaveConfigValue(Class'SS_GameMod_PingSystem', ContentName, Config.OptionValues[SelectedOptionIndex]);
    else
        GetGameMod().ChatSettings.SetSettingInt(ContentName, Config.OptionValues[SelectedOptionIndex]);
}

function SetDefault()
{
    
}

function SetSettingValue()
{
    local int SelectedOptionValuesRaw;
    local Array<GameModInfoConfig> gmics;
    
    if(IsModConfig)
    {
        FindGameModInfoConfig(gmics, Config, ContentName);
        SelectedOptionValuesRaw = class'GameMod'.static.GetConfigValue(class'SS_GameMod_PingSystem', ContentName);    
    }
    else
    {
        SelectedOptionValuesRaw = GetGameMod().ChatSettings.GetSettingInt(ContentName);
    }
    SelectedOptionIndex = FindIndexOfOptionValue(SelectedOptionValuesRaw, Config);
}

function OnKeyPress(HUD H, SS_Panel panel, bool right, bool release)
{
    // panel.OnClick(H, release);
}

defaultproperties
{
    IsModConfig = true;
    Buttons(0) = {(
        Argument = "down",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Left'
    )};
    Buttons(1) = {(
        Argument = "up",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Right'
    )};
}

