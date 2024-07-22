Class SS_Panel_Ping extends SS_Panel;

function OnClickContent(HUD H, string ButtonID, string Argument)
{
    if(ButtonID ~= "PingSoundType")
        PlaySound(H, Class'SS_Ping_Helpers'.static.GetPingSound());
    else
        Super.OnClickContent(H, ButtonID, Argument);
}

defaultproperties
{
    PanelName = "Ping";
    PanelIcon = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Panel_Location';
    Background = MaterialInstanceConstant'HatinTime_HUD_Settings.GameSettings.MenuBox';
    
    Begin Object Class=SS_PanelContent_Header Name=ToggleableHeader 
        Header = "ToggleableHeader"
    End Object
    Contents.Add(ToggleableHeader);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=TogglePingSystem
        ContentName = "TogglePingSystem"
        Config = {(
            ID = "TogglePingSystem",
            Name = "TogglePingSystem",
            Description = "TogglePingSystem_Desc",
            Default = 1,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        ToolTips = ("TogglePingSystem_0", "TogglePingSystem_1");
    End Object
    Contents.Add(TogglePingSystem);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=TogglePingButton
        ContentName = "TogglePingButton"
        Config = {(
            ID = "TogglePingButton",
            Name = "TogglePingButton",
            Description = "TogglePingButton_Desc",
            Default = 1,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        ToolTips = ("TogglePingButton_0", "TogglePingButton_1");
    End Object
    Contents.Add(TogglePingButton);

    Begin Object Class=SS_PanelContent_Header Name=PingHeader 
        Header = "PingHeader"
    End Object
    Contents.Add(PingHeader);

    Begin Object Class=SS_PanelContent_ConfigGM Name=PingLifeTime 
        ContentName = "PingLifeTime"
        Config = {(
            ID = "PingLifeTime",
            Name = "PingLifeTime",
            Description = "PingLifeTime_Desc",
            Default = 10,
            OptionValues = {(3, 5, 8, 10, 12, 15, 20, 25, 30, 50, 60, 75, 99)},
            OptionLabels = {("3", "5", "8", "10", "12", "15", "20", "25", "30", "50", "60", "75", "Forever")}
        )}
        ToolTips = ("PingLifeTime_0", "PingLifeTime_1");
    End Object
    Contents.Add(PingLifeTime);

    Begin Object Class=SS_PanelContent_ConfigGM Name=PingCastType 
        ContentName = "PingCastType"
        Config = {(
            ID = "PingCastType",
            Name = "PingCastType",
            Description = "PingCastType_Desc",
            Default = 10,
            OptionValues = {(0, 1, 2)},
            OptionLabels = {("Confirm", "On Release", "Quick Cast")}
        )}
        ToolTips = ("PingCastType_0", "PingCastType_1", "PingCastType_2", "PingCastType_3", "PingCastType_4");
    End Object
    Contents.Add(PingCastType);

    Begin Object Class=SS_PanelContent_ConfigGM Name=PingSpotFeature
        ContentName = "PingSpotFeature"
        Config = {(
            ID = "PingSpotFeature",
            Name = "PingSpotFeature",
            Description = "PingSpotFeature_Desc",
            Default = 3,
            OptionValues = {(0, 1, 2, 3)},
            OptionLabels = {("Off", "Game Pads Only", "Keyboard Only", "All Inputs")}
        )}
        ToolTips = ("PingSpotFeature_0", "PingSpotFeature_1", "PingSpotFeature_2");
    End Object
    Contents.Add(PingSpotFeature);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=AllowHatHelperToAttract
        ContentName = "AllowHatHelperToAttract"
        Config = {(
            ID = "AllowHatHelperToAttract",
            Name = "AllowHatHelperToAttract",
            Description = "AllowHatHelperToAttract_Desc",
            Default = 0,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        ToolTips = ("AllowHatHelperToAttract_0", "AllowHatHelperToAttract_1", "AllowHatHelperToAttract_2");
    End Object
    Contents.Add(AllowHatHelperToAttract);

    Begin Object Class=SS_PanelContent_Header Name=NotificationHeader 
        Header = "NotificationHeader"
    End Object
    Contents.Add(NotificationHeader);

    Begin Object Class=SS_PanelContent_ConfigGM Name=PingSoundType 
        ContentName = "PingSoundType"
        Config = {(
            ID = "PingSoundType",
            Name = "PingSoundType",
            Description = "PingSoundType_Desc",
            Default = 0,
            OptionValues = {(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 96, 97, 98, 99)},
            OptionLabels = {("Ship Shape", "Punch", "Trumpet", "Boop!", "Bell", "Flash", "egg", "Appear", "Storybook Page", "Discord", "Team Fortress 2", "Deep Rock Galactic", "HotS/WC3", "StarCraft 2", "Portal 2", "Wow", "Vine Boom", "Desperation", "Custom Sound", "No Sound", "Random Memes")}
        )}
        ToolTips = ("PingSoundType_0", "PingSoundType_1", "PingSoundType_2");
    End Object
    Contents.Add(PingSoundType);

    Begin Object Class=SS_PanelContent_ChatBox Name=CustomSoundNote
        ContentName = "CustomSoundNote"
        Localization = "CustomSoundNote"
    End Object
    Contents.Add(CustomSoundNote);

    Begin Object Class=SS_PanelContent_Config_Input Name=CustomSoundPackage 
        ContentName = "CustomSoundPackage"
        FillerText = "SoundPathWay"
        EnabledIf = "int PingSoundType == 97"
        ToolTips = ("CustomSoundPackage_0", "CustomSoundPackage_1", "CustomSoundPackage_2")
    End Object
    Contents.Add(CustomSoundPackage);

    Begin Object Class=SS_PanelContent_Config_Slider Name=PingNotificationMasterVolume
        ContentName = "PingNotificationMasterVolume"
        Precentage = true;
        EnabledIf = "int PingSoundType != 98"
        ToolTips = ("PingNotificationMasterVolume_0", "PingNotificationMasterVolume_1")
    End Object
    Contents.Add(PingNotificationMasterVolume);

    Begin Object Class=SS_PanelContent_Config_Slider Name=PingNotificationRange
        ContentName = "PingNotificationRange"
        DragText = "m"
        SliderMin = 15
        SliderMax = 100
        PointsAmount = 17;
        DecimalAmount = 0;
        ToolTips = ("PingNotificationRange_0", "PingNotificationRange_1");
    End Object
    Contents.Add(PingNotificationRange);
    
    Begin Object Class=SS_PanelContent_Config_Slider Name=PingNotificationDecayingRange
        ContentName = "PingNotificationDecayingRange"
        DragText = "m"
        SliderMin = 0
        SliderMax = 150
        PointsAmount = 15;
        DecimalAmount = 0;
        ToolTips = ("PingNotificationDecayingRange_0", "PingNotificationDecayingRange_1");
    End Object
    Contents.Add(PingNotificationDecayingRange);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=DontSendIfOutOfRange
        ContentName = "DontSendIfOutOfRange"
        Config = {(
            ID = "DontSendIfOutOfRange",
            Name = "DontSendIfOutOfRange",
            Description = "DontSendIfOutOfRange_Desc",
            Default = 0,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        ToolTips = ("DontSendIfOutOfRange_0", "DontSendIfOutOfRange_1");
    End Object
    Contents.Add(DontSendIfOutOfRange);
    
    Begin Object Class=SS_PanelContent_Header Name=CrossHairHeader 
        Header = "CrossHairHeader"
    End Object
    Contents.Add(CrossHairHeader);

    Begin Object Class=SS_PanelContent_Config_InputColor Name=PingCrossHairColor
        ContentName = "PingCrossHairColor"
        ToolTips = ("PingCrossHairColor_0", "PingCrossHairColor_1");
    End Object
    Contents.Add(PingCrossHairColor);

    Begin Object Class=SS_PanelContent_Config_Slider Name=PingCrossHairAlpha
        ContentName = "PingCrossHairAlpha"
        Precentage = true;
        ToolTips = ("PingCrossHairAlpha_0", "PingCrossHairAlpha_1");
    End Object
    Contents.Add(PingCrossHairAlpha);
    
    // Roughly 64 - 256 pixels in % for 1080p screens
    Begin Object Class=SS_PanelContent_Config_Slider Name=PingCrossHairSize
        ContentName = "PingCrossHairSize"
        SliderMin = 0.5f;
        SliderMax = 2.0f;
        Precentage = true;
        ToolTips = ("PingCrossHairSize_0", "PingCrossHairSize_1");
    End Object

    Contents.Add(PingCrossHairSize);
}