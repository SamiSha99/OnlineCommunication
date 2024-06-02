Class SS_PanelContent_ConfigGM_GameSettings_DisplayNameAndAvatars extends SS_PanelContent_ConfigGM_GameSettings;

function SaveGMConfig()
{
    Class'Hat_GhostPartyPlayer'.default.DisplayNameAndAvatars = Config.OptionValues[SelectedOptionIndex];
    class'Hat_GhostPartyPlayer'.static.StaticSaveConfig();
}

function SetDefault()
{
    
}

function SetSettingValue()
{
    SelectedOptionIndex = FindIndexOfOptionValue(Class'Hat_GhostPartyPlayer'.default.DisplayNameAndAvatars, Config);
}

defaultproperties
{
    ContentName = "DisplayNameAndAvatars"
    Config = {(
        ID = "DisplayNameAndAvatars",
        Name = "DisplayNameAndAvatars",
        Description = "DisplayNameAndAvatars_Desc",
        Default = 0,
        OptionValues = {(0, 1, 2, 3)},
        OptionLabels = {("Both", "Name", "Avatar", "None")}
    )}
}

