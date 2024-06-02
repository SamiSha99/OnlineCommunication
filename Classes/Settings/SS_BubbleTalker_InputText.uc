/**
 *
 * Copyright 2018-2019 Gears for Breakfast ApS. All Rights Reserved.
 */
class SS_BubbleTalker_InputText extends Hat_BubbleTalker_InputText
	dependson(SS_HUDMenu_PingSystemConfig);

var SS_PanelContent_Config_Input SettingsConfig;
var Hat_HUD SettingsMenuHUD;

var transient bool bCtrl;

var bool ListenToKeyOnly;

function InitInputText(SS_PanelContent_Config_Input PanelContent, HUD H)
{
	SettingsConfig = PanelContent;
	SettingsMenuHUD = Hat_HUD(h);
	AddToInteractions(H.PlayerOwner,'', SettingsConfig.InputLimit);
}

function DrawInputText(HUD H, Hat_BubbleTalkerQuestion element, float fTime, float fX, float fY) { return; }
function TickInputText(Hat_BubbleTalkerQuestion element, float d) { return; }

function bool InputKey( int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE )
{
	local string oldInput;
	
	if(ListenToKeyOnly && EventType == IE_PRESSED)
	{
		SettingsConfig.OnInputRecieved(PlayerControllers[0].myHUD, Key);
		return true;
	}

	if (Key == 'LeftControl' || Key == 'RightControl')
	{
		if (EventType == IE_Released)
			bCtrl = false;
		else if (EventType == IE_Pressed)
			bCtrl = true;
	}

	if (!Super.InputKey(ControllerId, Key, EventType, AmountDepressed, bGamepad) && (EventType == IE_Pressed || EventType == IE_Repeat)) return false;
	if (SettingsConfig == None) return true;
	if (Key == 'BackSpace' && Len(SettingsConfig.InputText) > 0 && (EventType == IE_Pressed || EventType == IE_Repeat))
	{
		oldInput = SettingsConfig.InputText;
		if(SettingsConfig.ForcedInput != "" && (Len(SettingsConfig.InputText) <= Len(SettingsConfig.ForcedInput) || bCtrl))
		{
			SettingsConfig.InputText = SettingsConfig.ForcedInput;
		}
		else
		{
			SettingsConfig.InputText = Left(SettingsConfig.InputText, Len(SettingsConfig.InputText) - 1);
		}
		SettingsConfig.OnBackSpace(oldInput);
		return true;
	}

	return true;
}

function AddCharacter(string s)
{
	if(bCtrl)
	{
		switch(caps(s))
		{
			case "V":
				SettingsConfig.OnPasteInput(PlayerControllers[0].PasteFromClipboard());
				break;
			case "C":
				OnCopy();
				break;
		}
		return;
	}

	Result = "";
	if(IsHoldingLeftShift || IsHoldingRightShift)
		s = Caps(s);
	else 
		s = Locs(s);

	Super.AddCharacter(s);
	if (SettingsConfig != None && Len(SettingsConfig.InputText) < CharacterLength)
	{
		SettingsConfig.OnInputRecieved(PlayerControllers[0].myHUD, Result);
	}
}

function OnCopy()
{
	PlayerControllers[0].CopyToClipboard(SettingsConfig.InputText);
}

function PlaySoundToPlayerControllers(SoundCue c) {}