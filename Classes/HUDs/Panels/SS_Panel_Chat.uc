Class SS_Panel_Chat extends SS_Panel;

defaultproperties
{
    PanelName = "Chat";
    PanelIcon = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Panel';
    Background = Material'HatinTime_HUD_Settings.GraphicsSettings.MenuBox';

    Begin Object Class=SS_PanelContent_Header Name=ToggleableHeader
        ContentName = "ToggleableHeader"
        Header = "ToggleableHeader"
    End Object
    Contents.Add(ToggleableHeader);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=ToggleOnlineChat
        ContentName = "ToggleOnlineChat"
        Config = {(
            ID = "ToggleOnlineChat",
            Name = "ToggleOnlineChat",
            Description = "ToggleOnlineChat_Desc",
            Default = 1,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        ToolTips = ("ToggleOnlineChat_0", "ToggleOnlineChat_1");
    End Object
    Contents.Add(ToggleOnlineChat);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=ToggleAdditionalEmotes
        ContentName = "ToggleAdditionalEmotes"
        Config = {(
            ID = "ToggleAdditionalEmotes",
            Name = "ToggleAdditionalEmotes",
            Description = "ToggleAdditionalEmotes_Desc",
            Default = 1,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        ToolTips = ("ToggleAdditionalEmotes_0", "ToggleAdditionalEmotes_1", "ToggleAdditionalEmotes_2");
    End Object
    Contents.Add(ToggleAdditionalEmotes);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=EnableEmotes
        ContentName = "EnableEmotes"
        Config = {(
            ID = "EnableEmotes",
            Name = "EnableEmotes",
            Description = "EnableEmotes_Desc",
            Default = 1,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        ToolTips = ("EnableEmotes_0", "EnableEmotes_1");
    End Object
    Contents.Add(EnableEmotes);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=ShowWhoHasMod
        ContentName = "ShowWhoHasMod"
        Config = {(
            ID = "ShowWhoHasMod",
            Name = "ShowWhoHasMod",
            Description = "ShowWhoHasMod_Desc",
            Default = 1,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        ToolTips = ("ShowWhoHasMod_0", "ShowWhoHasMod_1", "ShowWhoHasMod_2");
    End Object
    Contents.Add(ShowWhoHasMod);

    Begin Object Class=SS_PanelContent_Header Name=ChatBoxHeader
        Header = "ChatBoxHeader"
    End Object
    Contents.Add(ChatBoxHeader);

    Begin Object Class=SS_PanelContent_ConfigGM Name=FilterType 
        ContentName = "FilterType"
        Config = {(
            ID = "FilterType",
            Name = "FilterType",
            Description = "FilterType_Desc",
            Default = 1,
            OptionValues = {(0, 1, 2, 3, 4)},
            OptionLabels = {("No Filter", "PECK", "Stars", "!@#?$%^&*", "Nice Compliments")}
        )}
        ToolTips = ("FilterType_0", "FilterType_1", "FilterType_2", "FilterType_3", "FilterType_4", "FilterType_5", "FilterType_6", "FilterType_7");
        ToolTipClass = Class'SS_ContentToolTip_Text_Profanity';
    End Object
    Contents.Add(FilterType);

    Begin Object Class=SS_PanelContent_ConfigGM Name=AntiSpam 
        ContentName = "AntiSpam"
        Config = {(
            ID = "AntiSpam",
            Name = "AntiSpam",
            Description = "AntiSpam_Desc",
            Default = 1,
            OptionValues = {(0, 1, 2)},
            OptionLabels = {("Off", "Last Message", "Visible Messages")}
        )}
        ToolTips = ("AntiSpam_0", "AntiSpam_1", "AntiSpam_2", "AntiSpam_3")
    End Object
    Contents.Add(AntiSpam); 

    Begin Object Class=SS_PanelContent_Config_Slider Name=GlobalScale
        ContentName = "GlobalScale"
        sliderMin = 0.5f; // Extremely unreadable, probably good for those with 4k screens, I think?
        sliderMax = 2.0f;
        PointsAmount = 30;
        DragText = "x";
        Tooltips = ("GlobalScale_0", "GlobalScale_1")
    End Object
    Contents.Add(GlobalScale);

    Begin Object Class=SS_PanelContent_Config_Slider Name=ChatClippedXLimit
        ContentName = "ChatClippedXLimit"
        sliderMin = 0.2f;
        sliderMax = 0.6f;
        Precentage = true;
        Tooltips = ("ChatClippedXLimit_0", "ChatClippedXLimit_1");
    End Object
    Contents.Add(ChatClippedXLimit);

    Begin Object Class=SS_PanelContent_ConfigGM Name=StartingLineType
        ContentName = "StartingLineType"
        Config = {(
            ID = "StartingLineType",
            Name = "StartingLineType",
            Description = "StartingLineType_Desc",
            Default = 0,
            OptionValues = {(0, 1)},
            OptionLabels = {("Asterisk", "None")}
        )}
        Tooltips = ("StartingLineType_0", "StartingLineType_1");
    End Object
    Contents.Add(StartingLineType);

    Begin Object Class=SS_PanelContent_Header Name=AnnouncementsHeader
        ContentName = "AnnouncementsHeader"
        Header = "AnnouncementsHeader"
    End Object
    Contents.Add(AnnouncementsHeader);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=EnableJoin
        ContentName = "EnableJoin"
        Config = {(
            ID = "EnableJoin",
            Name = "EnableJoin",
            Description = "EnableJoin_Desc",
            Default = 1,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        Tooltips = ("EnableJoin_0", "EnableJoin_1");
    End Object
    Contents.Add(EnableJoin);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=EnableLeave
        ContentName = "EnableLeave"
        Config = {(
            ID = "EnableLeave",
            Name = "EnableLeave",
            Description = "EnableLeave_Desc",
            Default = 1,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        Tooltips = ("EnableLeave_0", "EnableLeave_1");
    End Object
    Contents.Add(EnableLeave);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=EnableTimePiece
        ContentName = "EnableTimePiece"
        Config = {(
            ID = "EnableTimePiece",
            Name = "EnableTimePiece",
            Description = "EnableTimePiece_Desc",
            Default = 1,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        Tooltips = ("EnableTimePiece_0", "EnableTimePiece_1");
    End Object
    Contents.Add(EnableTimePiece);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=EnableConnectionFailed
        ContentName = "EnableConnectionFailed"
        Config = {(
            ID = "EnableConnectionFailed",
            Name = "EnableConnectionFailed",
            Description = "EnableConnectionFailed_Desc",
            Default = 1,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        Tooltips = ("EnableConnectionFailed_0", "EnableConnectionFailed_1");
    End Object
    Contents.Add(EnableConnectionFailed);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=EnableVanessaCurse
        ContentName = "EnableVanessaCurse"
        Config = {(
            ID = "EnableVanessaCurse",
            Name = "EnableVanessaCurse",
            Description = "EnableVanessaCurse_Desc",
            Default = 1,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        Tooltips = ("EnableVanessaCurse_0", "EnableVanessaCurse_1");
    End Object
    Contents.Add(EnableVanessaCurse);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=EnableDeathWish
        ContentName = "EnableDeathWish"
        Config = {(
            ID = "EnableDeathWish",
            Name = "EnableDeathWish",
            Description = "EnableVanessaCurse_Desc",
            Default = 1,
            OptionValues = {(0, 1)},
            OptionLabels = {("Off", "On")}
        )}
        Tooltips = ("EnableDeathWish_0", "EnableDeathWish_1");
    End Object
    Contents.Add(EnableDeathWish);
}