Class SS_PanelContent_Config_InputColor extends SS_PanelContent_Config_Input;

var int oldColorBlindValue;

function Init()
{
	Super.Init();
	InputTextToColor();
}

function RenderConfigButton(HUD H, SS_Panel panel, float x, float y)
{
    local Vector2d pos;
    local string text;
    local Color tensityColor;
    scale = panel.Scale;
    pos = vect2d(x + GAP_CONFIG - GAP_OFFSET - GAP_RIGHT_SLIDER, y);
    RenderButton(H, Panel, 0, pos);
    if(IsInputtingName || Buttons[0].BeingHovered)
    {
        // Auto fill reference
        text = InputText;
        while(Len(text) < InputLimit) text $= "0";
        tensityColor = Class'SS_Color'.static.Hex(text);
        if(Class'OnlineCommunication'.static.GetColorIntensity(tensityColor) > 150.0f)
            Class'SS_Color'.static.SetDrawColor(H, 0,0,0, 96); // hard to read so we amp it down
        else
            Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, 160);
        H.Canvas.Font = class'Hat_FontInfo'.static.GetDefaultFont(text);
        panel.DrawBorderedText(H.Canvas, text, pos.x * H.Canvas.ClipX - Buttons[0].Size.X/2.2f * scale, pos.y * H.Canvas.ClipY, 0.55f * scale, false, TextAlign_Left,,0);

        // Switch between black and white cuz intensity
        if(Class'OnlineCommunication'.static.GetColorIntensity(tensityColor) > 186.0f)
            Class'SS_Color'.static.SetDrawColor(H, 0,0,0);
        else
            Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255);

        text = InputText;
        if (IsInputtingName && Len(InputText) <= InputLimit && InputCursorBlink >= CursorBlinkCycle/2) text $= "_";
        H.Canvas.Font = class'Hat_FontInfo'.static.GetDefaultFont(text);
        panel.DrawBorderedText(H.Canvas, text, pos.x * H.Canvas.ClipX - Buttons[0].Size.X/2.2f * scale, pos.y * H.Canvas.ClipY, 0.55f * scale, false, TextAlign_Left,,0);
    }
    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, 255);
}

function TickContent(HUD H, float d)
{
    Super.TickContent(H, d);
    SetColorBlind();
}

function OnUpdateContent()
{
    SetColorBlind(true);
    Super.OnUpdateContent();
}

function SetColorBlind(optional bool forced = false)
{
    if(OldColorBlindValue == Class'Hat_HUD'.default.PostProcessColorBlindness && !forced) return;
    OldColorBlindValue = Class'Hat_HUD'.default.PostProcessColorBlindness;
    Buttons[0].MatInstance.SetScalarParameterValue('ColorBlindMode', OldColorBlindValue);
}

function InputTextToColor()
{
    local LinearColor lc;
    local string hex;

    hex = InputText;
    while(Len(hex) < InputLimit) hex $= "0";
    lc = Class'SS_Color'.static.HexToLinearColor(hex);
	Buttons[0].MatInstance.SetScalarParameterValue('GammaCorrection', Class'Engine'.static.GetDisplayGamma());
	Buttons[0].MatInstance.SetVectorParameterValue('ChoiceColor', lc);
    
}

function OnInputRecieved(HUD H, string s)
{
    if(!IsCharHex(s)) return;
    InputText $= s;
    InputTextToColor();
}

function OnPasteInput(string paste)
{
    local Array<string> chars;
    paste -= "#";
    chars = Class'OnlineCommunication'.static.SplitStringToChars(paste);
    chars.Length = Min(InputLimit - Len(InputText), chars.Length);
    while(chars.Length > 0 && Len(InputText) < InputLimit)
    {
        InputText $= chars[0];
        chars.Remove(0, 1);
    }
    InputTextToColor();
}


function OnBackSpace(string OldInputText)
{
    InputTextToColor();
}

function OnPreSaveSettings(out string value)
{
    while(Len(value) < InputLimit) value $= "0";
}

function bool IsCharHex(string c)
{
	switch(caps(c))
	{
		//case "#": return true;
		case "0": case "8":
		case "1": case "9":
		case "2": case "A":
		case "3": case "B":
		case "4": case "C":
		case "5": case "D":
		case "6": case "E":
		case "7": case "F":
			return true;

	}
	return false;
}

defaultproperties
{
    TextSize = 0.5f;
    InputLimit = 7;
    Buttons(0) = {(
        Argument = "input",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_ColorPicker',
        Size = (X = 150, Y = 50)
    )};
    ForcedInput = "#";
    OldColorBlindValue = -1;
}