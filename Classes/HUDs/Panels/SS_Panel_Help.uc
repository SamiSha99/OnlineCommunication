Class SS_Panel_Help extends SS_Panel;

defaultproperties
{
    PanelName = "Help";
    PanelIcon = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Panel_Help';
    Background = Material'HatinTime_GhostParty.Materials.JoinActMenuBox';
    
    Begin Object Class=SS_PanelContent_Header Name=HelpText 
        Header = "HelpText"
        Center = true;
    End Object
    Contents.Add(HelpText);

    Begin Object Class=SS_PanelContent_ButtonURL Name=OpenDocuments
        ContentName = "OpenDocuments"
        URL = "https://github.com/SamiSha99/OnlineCommunication/wiki"
        Localization = "OpenDocuments_Button"
        Shine = true
    End Object
    Contents.Add(OpenDocuments);

    Begin Object Class=SS_PanelContent_ConfigGMCheckbox Name=ToggleDebugging
        ContentName = "ToggleDebugging"
        ToolTips = ("ToggleDebugging_0", "ToggleDebugging_1", "ToggleDebugging_2", "ToggleDebugging_3", "ToggleDebugging_4", "ToggleDebugging_5", "ToggleDebugging_6", "ToggleDebugging_7");
    End Object
    Contents.Add(ToggleDebugging);
}