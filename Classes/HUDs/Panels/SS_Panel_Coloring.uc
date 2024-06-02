Class SS_Panel_Coloring extends SS_Panel;

defaultproperties
{
    PanelName = "Color";
    PanelIcon = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Panel_Coloring';
    Background = MaterialInstanceConstant'SS_PingSystem_Content.GraphicsSettings.MenuBox_Color';
    
    Begin Object Class=SS_PanelContent_ButtonURL Name=OpenHexPicker
        ContentName = "OpenHexPicker"
        // URL = "https://htmlcolors.com/google-color-picker"
        URL = "https://g.co/kgs/AKsgHmG"
        Localization = "OpenHexPicker_Button"
        Shine = true
    End Object
    Contents.Add(OpenHexPicker);

    Begin Object Class=SS_PanelContent_Config_InputColor Name=PlayerColor
        ContentName = "PlayerColor"
        ToolTips = ("PlayerColor_Example_0", "PlayerColor_Example_1", "PlayerColor_Example_2", "PlayerColor_Example_3");
    End Object
    Contents.Add(PlayerColor);
    
    Begin Object Class=SS_PanelContent_Config_InputColor Name=EnemyColor
        ContentName = "EnemyColor"
        ToolTips = ("EnemyColor_Example_0", "EnemyColor_Example_1", "EnemyColor_Example_2");
    End Object
    Contents.Add(EnemyColor);

    Begin Object Class=SS_PanelContent_Config_InputColor Name=NonePlayableColor 
        ContentName = "NonePlayableColor"
        Tooltips = ("NPCColor_Example_0", "NPCColor_Example_1", "NPCColor_Example_2");
    End Object
    Contents.Add(NonePlayableColor);
    
    Begin Object Class=SS_PanelContent_Config_InputColor Name=LocationColor 
        ContentName = "LocationColor"
        ToolTips = ("LocationColor_Example_0", "LocationColor_Example_1", "LocationColor_Example_2");
    End Object
    Contents.Add(LocationColor);

    Begin Object Class=SS_PanelContent_Config_InputColor Name=ObjectColor 
        ContentName = "ObjectColor"
        ToolTips = ("ObjectColor_Example_0", "ObjectColor_Example_1", "ObjectColor_Example_2");
    End Object
    Contents.Add(ObjectColor);
    
    Begin Object Class=SS_PanelContent_Config_InputColor Name=ImportantColor 
        ContentName = "ImportantColor"        
        ToolTips = ("ImportantColor_Example_0", "ImportantColor_Example_1", "ImportantColor_Example_2");
    End Object
    Contents.Add(ImportantColor);

    Begin Object Class=SS_PanelContent_Config_InputColor Name=ChatEmoteTextColor
        ContentName = "ChatEmoteTextColor"
        ToolTips = ("EmoteColor_Example_0", "EmoteColor_Example_1", "EmoteColor_Example_2");
    End Object
    Contents.Add(ChatEmoteTextColor);
}