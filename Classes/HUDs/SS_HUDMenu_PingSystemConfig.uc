Class SS_HUDMenu_PingSystemConfig extends Hat_HUDMenu
    dependsOn(SS_ChatFormatter);

var bool IsConfigLoadout;
var Hat_HUDMenuSettings oldconfig;

var SS_GameMod_OC GameMod;

var Array<SS_Panel> Panels;
var Array< Class<SS_Panel> > PanelsClasses;
var int SelectedPanel, HoveredPanel, LastHoveredPanel;

var MaterialInterface MouseMat;
var MaterialInstanceTimeVarying MouseMatInstance;

var bool IsUsingKeys;
var Vector2D LastMousePosition;

function OnOpenHUD(HUD H, optional String command)
{
    local int i;
    local SS_Panel instance;
    Super.OnOpenHUD(H, command);
    GameMod = SS_GameMod_OC(Class'OnlineCommunication'.static.GetGameMod('SS_GameMod_OC'));
    MouseMatInstance = Class'OnlineCommunication'.static.InitMaterial(MouseMat);
    LastMousePosition = GetMousePos(H);
    for(i = 0; i < PanelsClasses.Length; i++)
    {
        instance = new PanelsClasses[i];
        instance.Init(H, self, i);
        Panels.AddItem(instance);
    }
}

function OnOpenHUDFromConfigLoadout(Hat_HUD H)
{
    local Hat_HUDMenu_ModLevelSelect modSelect;
    IsConfigLoadout = true;
    HideIfPaused = false;
    oldconfig = Hat_HUDMenuSettings(h.GetHUD(Class'Hat_HUDMenuSettings'));
    if(oldconfig != None)
    {
        oldconfig.Enabled = false;
        oldconfig.Current_Menu = none;
    }
    modSelect = Hat_HUDMenu_ModLevelSelect(H.GetHUD(Class'Hat_HUDMenu_ModLevelSelect'));
    if(modselect != None)
    {
        modSelect.IsMenuFrozen = true;
    }
}

function OnCloseHUD(HUD H)
{
    local int i;
    local Hat_HUDMenu_ModLevelSelect modSelect;
    
    if(oldconfig != None)
    {
        CloseHUD(H, oldconfig.class);
    }
    modSelect = Hat_HUDMenu_ModLevelSelect(Hat_HUD(H).GetHUD(Class'Hat_HUDMenu_ModLevelSelect'));
    if(modselect != None)
        modSelect.IsMenuFrozen = false;

    if(GameMod.ActiveInputContentPanel != None)
    {
        GameMod.ActiveInputContentPanel.DisableInputting(H);
        GameMod.ActiveInputContentPanel = None;
    }

    for(i = 0; i < Panels.Length; i++)
        Panels[i].CloseHUD(H, Panels[i].Class, true);
    Super.OnCloseHUD(H);
}

function bool Tick(HUD H, float d)
{
    local int i;
    local bool PanelButtonHighlighted, isFocusedPanel;

    if(!Super.Tick(H, d)) return false;

    Panels[SelectedPanel].TickPanelFocus(H, d);

    for(i = 0; i < Panels.Length; i++)
    {
        Panels[i].TickPanel(H, d);
        isFocusedPanel = Panels[SelectedPanel].PanelButton.Argument == Panels[i].PanelButton.Argument;
        if(HoveredPanel != -1)
            PanelButtonHighlighted = Panels[HoveredPanel].PanelButton.Argument == Panels[i].PanelButton.Argument;
        
        if(PanelButtonHighlighted || isFocusedPanel)
            Panels[i].FocusProgress = FClamp(Panels[i].FocusProgress + d*4, 0.0f, 1.0f);
        else
            Panels[i].FocusProgress = FClamp(Panels[i].FocusProgress - d*4, 0.0f, 1.0f);

        Panels[i].FocusAmount = Class'Hat_Math'.static.InterpolationEaseInEaseOutJonas(0.0f, 1.0f, Panels[i].FocusProgress, 4);

        Panels[i].PanelButton.MatInstance.SetScalarParameterValue('OnClick', isFocusedPanel ? 1.0f : 0.0f);
    }
	return true;
}

function bool Render(HUD H)
{
    local float backgroundWidth, backgroundHeight, backgroundPosX, scale;
    local vector2d mousePos, pos;
    local int i;
    local bool isHoveringPanelButton;

    if(!Super.Render(H)) return false;
    
    backgroundWidth = H.Canvas.ClipX * 0.6f;
    backgroundHeight = H.Canvas.ClipY * 0.7f;
    scale = H.Canvas.ClipY/1080.0f;
    
    if(IsConfigLoadout) 
    {
        H.Canvas.SetDrawColor(0, 0, 0, 128);
        DrawCenter(H, H.Canvas.ClipX * 0.5f, H.Canvas.ClipY * 0.5f, H.Canvas.ClipX, H.Canvas.ClipY, H.Canvas.DefaultTexture);
    }

    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, 255);

    if(!IsUsingKeys)
        Panels[SelectedPanel].highlightedButton = "";
    
    HoveredPanel = -1;
    backgroundPosX = 0.35f;
    
    pos.X = H.Canvas.ClipX * backgroundPosX + backgroundWidth/2 + (Class'SS_Panel'.default.PanelButton.Size.X/2 * scale) - H.Canvas.ClipX * 0.005f;
    pos.Y = H.Canvas.ClipY * 0.5f - backgroundHeight/2;

    Class'Hat_HUDInputButtonRender'.static.Render(H, HatControllerBind_Menu_PageRight, pos.X + Abs(Sin(GetWorldInfo().TimeSeconds * Pi/3)) * 0.01f * H.Canvas.ClipX, pos.Y - (Class'SS_Panel'.default.PanelButton.Size.Y/4 * scale), Hat_HUD(H).IsGamePad() ? 50 : 40);

    for(i = Panels.Length - 1; i >= 0; i--)
    {
        pos.X = H.Canvas.ClipX * backgroundPosX + backgroundWidth/2 - (Panels[i].PanelButton.Size.X/2 * scale) - (Panels.Length - 1 - i) * (Panels[i].PanelButton.Size.X * scale);
        pos.X -= H.Canvas.ClipX * 0.005f;
        
        isHoveringPanelButton = Panels[i].RenderPanelButton(H, pos, scale);
        if(isHoveringPanelButton)
        {
            HoveredPanel = i;
            if(LastHoveredPanel == -1)
            {
                PlaySound(H, SoundCue'HatInTime_Hud.SoundCues.CursorMove');
                LastHoveredPanel = HoveredPanel;
            }
        }

        if(Panels[i].PanelButton.MatInstance != None && (isHoveringPanelButton || Panels[i].PanelButton.Argument == Panels[SelectedPanel].PanelButton.Argument))
            Panels[i].PanelButton.MatInstance.SetScalarParameterValue('OnHover', 1.0f);
        else
            Panels[i].PanelButton.MatInstance.SetScalarParameterValue('OnHover', 0.0f);
    }
    
    pos.X -= Class'SS_Panel'.default.PanelButton.Size.X * scale;
    Class'Hat_HUDInputButtonRender'.static.Render(H, HatControllerBind_Menu_PageLeft, pos.X - Abs(Sin(GetWorldInfo().TimeSeconds * Pi/3)) * 0.015f * H.Canvas.ClipX, pos.Y - (Class'SS_Panel'.default.PanelButton.Size.Y/4 * scale), scale*(Hat_HUD(H).IsGamePad() ? 50 : 40));
    
    Panels[SelectedPanel].Scale = scale;
    Panels[SelectedPanel].RenderPanel(H, backgroundWidth, backgroundHeight, backgroundPosX);
    
    if(Panels[SelectedPanel].highlightedButton ~= "") Panels[SelectedPanel].lastHighlightedButton = "";
    if(HoveredPanel == -1) LastHoveredPanel = -1;

    Class'SS_Color'.static.SetDrawColor(H, 255,255,255,255);
    class'Hat_HUDInputButtonRender'.static.Render(H, HatControllerBind_Menu_Cancel, H.Canvas.ClipX * 0.92f, H.Canvas.ClipY * 0.95, 90);
    class'Hat_HUDMenuLoadout'.static.DrawBorderedText(H.Canvas, "Leave", H.Canvas.ClipX * 0.94f, H.Canvas.ClipY * 0.95, 0.8f, true, TextAlign_Left);

    mousePos = GetMousePos(H);
    if(LastMousePosition != GetMousePos(H))
    {
        LastMousePosition = mousePos;
        IsUsingKeys = false;
    }

    if(MouseMatInstance != None && !IsUsingKeys && !IsConfigLoadout)
    {
        DrawCenterMat(H, LastMousePosition.X + 16*scale, LastMousePosition.Y + 16*scale, 40*scale, 40*scale, MouseMatInstance);
    }

    return true;
}

function bool OnPageClick(HUD H, bool right, bool release)
{
    if(release) return false;
    if(GameMod.ActiveInputContentPanel != None) return false;
    SwitchPanel(H, Clamp(SelectedPanel + right ? 1 : -1, 0, Panels.Length - 1));
    return true;
}


function bool OnClick(HUD H, bool release)
{   
    if(MouseMatInstance != None)
        MouseMatInstance.SetScalarParameterValue('OnClick', release ? 0.0f : 1.0f);

    if(HoveredPanel != -1 && !release)
    {
        SwitchPanel(H, HoveredPanel);
        return true;
    }

    Panels[SelectedPanel].OnClick(H, release);

    if(release)
        OnRelease(H);

    return true;
}

function bool OnAltClick(HUD H, bool release)
{
    // IsUsingKeys = false;
    return Panels[SelectedPanel].OnClickAlt(H, release);
}

function bool OnPressUp(HUD H, bool menu, bool release)
{
    // IsUsingKeys = true;
	return Panels[SelectedPanel].OnPressUp(H, menu, release);
}

function bool OnPressDown(HUD H, bool menu, bool release)
{
    // IsUsingKeys = true;
	return Panels[SelectedPanel].OnPressDown(H, menu, release);
}

function bool OnPressLeft(HUD H, bool menu, bool release)
{
    // IsUsingKeys = true;
	return Panels[SelectedPanel].OnPressLeft(H, menu, release);
}

function bool OnPressRight(HUD H, bool menu, bool release)
{
    // IsUsingKeys = true;
	return Panels[SelectedPanel].OnPressRight(H, menu, release);
}

// Only on gamepads. X button on Xbox.
function bool OnXClick(HUD H, bool release)
{
	return Panels[SelectedPanel].OnXClick(H, release);
}

// Only on gamepads. Y button on Xbox.
function bool OnYClick(HUD H, bool release)
{
    return Panels[SelectedPanel].OnYClick(H, release);
}

function SwitchPanel(HUD H, int index)
{
    PlaySound(H, SoundCue'HatInTime_Hud.SoundCues.MenuNext');
    SelectedPanel = index;
    Panels[SelectedPanel].OnFocus(H);
}

function OnRelease(HUD H)
{
    
}

function bool DisablesMovement(HUD H)
{
    return true;
}
function bool DisablesCameraMovement(HUD H)
{
    return true;
}

static function string GetSettingsLocalization(coerce string key, coerce string section, optional out coerce string result)
{
    result =  Localize(section, key, "communication_settings");
    return result;
}

defaultproperties
{
    SharedInCoop = true;
    
    RealTime = true;
    HideIfPaused = true;

    HoveredPanel = -1;
    MouseMat = Material'SS_PingSystem_Content.UIMouse';

    // PanelsClasses.Add(Class'SS_Panel_Original');
    PanelsClasses.Add(Class'SS_Panel_Ping');
    PanelsClasses.Add(Class'SS_Panel_Chat');
    PanelsClasses.Add(Class'SS_Panel_Coloring');
    PanelsClasses.Add(Class'SS_Panel_Advanced');
    PanelsClasses.Add(Class'SS_Panel_Help');
}