Class SS_PanelContent_Config_Input extends SS_PanelContent_Config_Base;

var bool SaveTypeName; // Key presses are name, set this to true to listen to key press

var float animationTime, animationAmount;
var Vector2d FocusSize;
var Color textColor;
var bool centerText;

var float TextSize;
var string FillerText;
var float FillerOpacity;

var SS_BubbleTalker_InputText InputInstance;
var string DefaultInput;
var string InputText;
var string ForcedInput; // Input that will always be part of the string, no way to remove at all
var int InputLimit;
var transient bool IsInputtingName;
var transient float InputCursorBlink;
const CursorBlinkCycle = 1.3;

var bool DONT_PUT_UNDER_SCORE_IDIOT;

var float scale;

function RenderConfigButton(HUD H, SS_Panel panel, float x, float y)
{
    local Vector2d pos;
    local string text;
    
    scale = panel.Scale;
    pos = vect2d(x + GAP_CONFIG - GAP_OFFSET - GAP_RIGHT_SLIDER, y);
    RenderButton(H, Panel, 0, pos);
    
    if(IsInputtingName && Len(InputText) <= 0)
    {
        text = Class'SS_HUDMenu_PingSystemConfig'.static.GetSettingsLocalization(FillerText, "inputs");
        Class'SS_Color'.static.SetDrawColor(H, textColor.R, textColor.G, textColor.B, FillerOpacity);
        H.Canvas.Font = class'Hat_FontInfo'.static.GetDefaultFont(text);
        panel.DrawBorderedText(H.Canvas, text, pos.x * H.Canvas.ClipX - (centerText ? 0.0f : Buttons[0].Size.X/2.2f * scale), pos.y * H.Canvas.ClipY, TextSize * scale, false, centerText ? TextAlign_Center: TextAlign_Left,,0);
    }
    else if(Len(InputText) > 0 && ContentEnabled)
    {
        // Return original value
        Class'SS_Color'.static.SetDrawColor(H, textColor.R, textColor.G, textColor.B, 255);
        text = InputText;
        if (!DONT_PUT_UNDER_SCORE_IDIOT && IsInputtingName && Len(InputText) <= InputLimit && InputCursorBlink >= CursorBlinkCycle/2) text $= "_";
        H.Canvas.Font = class'Hat_FontInfo'.static.GetDefaultFont(text);
        panel.DrawBorderedText(H.Canvas, text, pos.x * H.Canvas.ClipX - (centerText ? 0.0f : Buttons[0].Size.X/2.2f * scale), pos.y * H.Canvas.ClipY, TextSize * scale, false, centerText ? TextAlign_Center: TextAlign_Left,,0);
    }
    
    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, 255);
}

function TickContent(HUD H, float d)
{
    local Vector2d size2D;
    local LinearColor lc;
    if (IsInputtingName)
	{
        AnimationTime = FClamp(AnimationTime + d*4, 0.0f, 1.0f);
        if (InputCursorBlink > 0) InputCursorBlink -= d;
		else InputCursorBlink = CursorBlinkCycle;
	}
    else
    {
        AnimationTime = FClamp(AnimationTime - d*4, 0.0f, 1.0f);
    }

    AnimationAmount = Class'Hat_Math'.static.InterpolationEaseInEaseOutJonas(0.0f, 1.0f, AnimationTime, 4);

    Buttons[0].Size.X = Lerp(default.Buttons[0].Size.X * scale, FocusSize.X * scale, AnimationAmount);
    Buttons[0].Size.Y = Lerp(default.Buttons[0].Size.Y * scale, FocusSize.Y * scale, AnimationAmount);
    size2D = Class'SS_Button'.static.CalculateButtonUVSize(Buttons[0].Size.X, Buttons[0].Size.Y);
    lc = MakeLinearColor(size2D.X, size2D.Y, 0, 0);
    Buttons[0].MatInstance.SetVectorParameterValue(Buttons[0].uvSizeParameter, lc);
		
}

function OnInputRecieved(HUD H, coerce string s)
{
    InputText $= s;
}

function OnBackSpace(string OldInputText)
{

}

function OnPasteInput(string paste)
{
    InputText $= paste;
}

function SetDefault()
{
    InputText = GetGameMod().ChatSettings.GetSettingString(ContentName, true);
}

function SetSettingValue()
{
    InputText = GetGameMod().ChatSettings.GetSettingString(ContentName);
}

function OnClickContent(HUD H, SS_Panel panel, string arg)
{
    Super.OnClickContent(H, panel, arg);
    if(IsInputtingName) return;
    EnableInputting(H);
}

function EnableInputting(HUD H)
{
    local SS_GameMod_PingSystem gm;

    gm = GetGameMod();
    if(gm == None || gm.ActiveInputContentPanel != None) return;

    gm.ActiveInputContentPanel = self;

    if (!IsInputtingName)
	{
		IsInputtingName = true;
		InputCursorBlink = CursorBlinkCycle;
		InputInstance = new class'SS_BubbleTalker_InputText';
        InputInstance.InitInputText(self, Hat_HUD(H));
	}
}

function DisableInputting(HUD H)
{
    local SS_GameMod_PingSystem gm;

    gm = GetGameMod();
    if(InputInstance == None) return;
    if(gm == None) return;

    OnPreSaveSettings(InputText);
    
    if(!SaveTypeName && gm.ChatSettings.SetSettingString(Caps(ContentName), InputText) || 
        gm.ChatSettings.SetSettingName(Caps(ContentName), Name(InputText)))
    {
        gm.SaveChatSettings();
        UpdateMainPanel(H);
    }

    InputInstance.Detach(H.PlayerOwner);
    
    InputInstance = None;
    IsInputtingName = false;

    if(gm.ActiveInputContentPanel == self) gm.ActiveInputContentPanel = None;
}

function OnPreSaveSettings(out string value)
{

}

defaultproperties
{
    TextSize = 0.4f
    InputLimit = 256;
   
    FocusSize = (X = 350, Y = 50)
    Buttons(0) = {(
        Argument = "input",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_ColorPicker',
        Size = (X = 350, Y = 50)
    )};
    InputText = "";
    FillerText = ""
    FillerOpacity = 96;
    textColor = (R=0, G=0, B=0);
    Scale = 1.0f;
}