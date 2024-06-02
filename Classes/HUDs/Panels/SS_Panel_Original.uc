Class SS_Panel_Original extends SS_Panel;

defaultproperties
{
    PanelName = "Original";
    PanelIcon = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Panel_Original';
    
    Begin Object Class=SS_PanelContent_ChatBox Name=OriginalNote 
        Localization = "OriginalNote"
    End Object
    Contents.Add(OriginalNote);


    Begin Object Class=SS_PanelContent_Header Name=PingHeader 
        Header = "PingHeader"
    End Object
    Contents.Add(PingHeader);

    Begin Object Class=SS_PanelContent_ConfigGM Name=PingLifeTime 
        ContentName = "PingLifeTime"
        ToolTips = ("PingLifeTime_0", "PingLifeTime_1");
    End Object
    Begin Object Class=SS_PanelContent_ConfigGM Name=PingSoundType 
        ContentName = "PingSoundType"
        ToolTips = ("PingSoundType_0", "PingSoundType_1", "PingSoundType_2");
    End Object
    Begin Object Class=SS_PanelContent_ConfigGM Name=PingCastType 
        ContentName = "PingCastType"
        ToolTips = ("PingCastType_0", "PingCastType_1", "PingCastType_2", "PingCastType_3", "PingCastType_4");
    End Object
    Begin Object Class=SS_PanelContent_ConfigGM Name=PingSpotFeature
        ContentName = "PingSpotFeature"
        ToolTips = ("PingSpotFeature_0", "PingSpotFeature_1", "PingSpotFeature_2");
    End Object
    Contents.Add(PingLifeTime);
    Contents.Add(PingSoundType);
    Contents.Add(PingCastType);
    Contents.Add(PingSpotFeature);

    Begin Object Class=SS_PanelContent_Header Name=SafetyHeader 
        Header = "SafetyHeader"
    End Object
    Contents.Add(SafetyHeader);

    Begin Object Class=SS_PanelContent_ConfigGM Name=FilterType 
        ContentName = "FilterType"
        ToolTips = ("FilterType_0", "FilterType_1", "FilterType_2", "FilterType_3", "FilterType_4", "FilterType_5", "FilterType_6", "FilterType_7");
        ToolTipClass = Class'SS_ContentToolTip_Text_Profanity';
    End Object
    Contents.Add(FilterType);
    Begin Object Class=SS_PanelContent_ConfigGM Name=AntiSpam 
        ContentName = "AntiSpam"
        ToolTips = ("AntiSpam_0", "AntiSpam_1", "AntiSpam_2", "AntiSpam_3")
    End Object
    Contents.Add(AntiSpam);

    Begin Object Class=SS_PanelContent_Header Name=ToggleableHeader 
        Header = "ToggleableHeader"
    End Object
    Contents.Add(ToggleableHeader);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=TogglePingSystem
        ContentName = "TogglePingSystem"
        ToolTips = ("TogglePingSystem_0");
    End Object
    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=TogglePingButton
        ContentName = "TogglePingButton"
        ToolTips = ("TogglePingButton_0");
    End Object
    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=ToggleOnlineChat
        ContentName = "ToggleOnlineChat"
        ToolTips = ("ToggleOnlineChat_0");
    End Object
    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=ToggleAdditionalEmotes
        ContentName = "ToggleAdditionalEmotes"
        ToolTips = ("ToggleAdditionalEmotes_0");
    End Object
    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=ToggleDebugging
        ContentName = "ToggleDebugging"
        ToolTips = ("ToggleDebugging_0");
    End Object
    
    Contents.Add(TogglePingSystem);
    Contents.Add(TogglePingButton);
    Contents.Add(ToggleOnlineChat);
    Contents.Add(ToggleAdditionalEmotes);
    Contents.Add(ToggleDebugging);
}