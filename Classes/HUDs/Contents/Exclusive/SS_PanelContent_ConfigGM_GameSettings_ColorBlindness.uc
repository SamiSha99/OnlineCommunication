Class SS_PanelContent_ConfigGM_GameSettings_ColorBlindness extends SS_PanelContent_ConfigGM_GameSettings;

function SaveGMConfig()
{
    class'Hat_HUD'.default.PostProcessColorBlindness = Config.OptionValues[SelectedOptionIndex];
    class'Hat_HUD'.static.StaticSaveConfig();
}

function SetDefault()
{
    
}

function SetSettingValue()
{
    SelectedOptionIndex = FindIndexOfOptionValue(class'Hat_HUD'.default.PostProcessColorBlindness, Config);
}

defaultproperties
{
    ContentName = "ColorBlindness"
    Config = {(
        ID = "ColorBlindness",
        Name = "ColorBlindness",
        Description = "ColorBlindness_Desc",
        Default = 0,
        OptionValues = {(0, 1, 2, 3)},
        OptionLabels = {("Off", "Protanopia", "Deuteranopia", "Tritanopia")}
    )}
}

