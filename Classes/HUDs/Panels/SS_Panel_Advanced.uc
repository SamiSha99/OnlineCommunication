Class SS_Panel_Advanced extends SS_Panel;

defaultproperties
{
    PanelName = "Advanced";
    PanelIcon = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Panel_Advanced';
    Background = MaterialInstanceConstant'HatinTime_HUD_Settings.InputSettings.MenuBox';

    Begin Object Class=SS_PanelContent_Header Name=KeyBindSettings 
        Header = "KeyBindSettings"
    End Object
    Contents.Add(KeyBindSettings);

    Begin Object Class=SS_PanelContent_Config_InputKey Name=PingHotKey 
        ContentName = "PingHotKey"
        Tooltips = ("PingHotKey_0", "PingHotKey_1")
    End Object
    Contents.Add(PingHotKey);

    Begin Object Class=SS_PanelContent_Config_InputKey Name=ExpandChatHotkey 
        ContentName = "ExpandChatHotkey"
        Tooltips = ("ExpandChatHotkey_0", "ExpandChatHotkey_1", "ExpandChatHotkey_2")
    End Object
    Contents.Add(ExpandChatHotkey);

    Begin Object Class=SS_PanelContent_Header Name=CommunicationChannelSettings 
        Header = "CommunicationChannelSettings"
    End Object
    Contents.Add(CommunicationChannelSettings);

    Begin Object Class=SS_PanelContent_ConfigGM Name=ChannelType 
        ContentName = "ChannelType"
        Config = {(
            ID = "ChannelType",
            Name = "ChannelType",
            Description = "ChannelType_Desc",
            Default = 0,
            OptionValues = {(0, 1, 2)},
            OptionLabels = {("All", "Steam Friends", "Private")}
        )}
        IsModConfig = false
        Tooltips = ("ChannelType_0", "ChannelType_1", "ChannelType_2", "ChannelType_3", "ChannelType_4")
    End Object
    Contents.Add(ChannelType);
    
    Begin Object Class=SS_PanelContent_Config_Input Name=PrivateChannelName 
        ContentName = "PrivateChannelName"
        FillerText = "PrivateChannelFiller"
        EnabledIf = "Int ChannelType == 2"
            Tooltips = ("PrivateChannelName_0", "PrivateChannelName_1", "PrivateChannelName_2");
    End Object
    Contents.Add(PrivateChannelName);

    // Begin Object Class=SS_PanelContent_Header Name=OfficialGameSettings 
        // Header = "OfficialGameSettings"
    // End Object
    // Contents.Add(OfficialGameSettings);
// 
    // Begin Object Class=SS_PanelContent_ConfigGM_GameSettings_ColorBlindness Name=ColorBlindness 
    // End Object
    // Contents.Add(ColorBlindness);
    // 
    // Begin Object Class=SS_PanelContent_ConfigGM_GameSettings_DisplayNameAndAvatars Name=DisplayNameAndAvatars 
    // End Object
    // Contents.Add(DisplayNameAndAvatars);
}