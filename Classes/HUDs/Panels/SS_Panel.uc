Class SS_Panel extends Hat_HUDElement;

var float Scale; // is 1 when 1080p, less if smaller, more if larger

enum FocusType
{
    FT_Slider,
    FT_Input
};

var SS_HUDMenu_PingSystemConfig ConfigMenu;

// Panel
var name PanelName;
var MaterialInterface PanelIcon;
var OCButton PanelButton;
var float FocusAmount, FocusProgress;

var Color BackgroundColor;
var float ContentsStartPosY;
var float PanelSizeY; // % Y

// Contents we are going to render and mess with
var Array<SS_PanelContent> Contents;
var SS_PanelContent HoveredContent;
var int HoveredButtonIndex; // Index of button
var string HighlightedButton, LastHighlightedButton;

// Highlight and Pressing
var MaterialInstanceTimeVarying PressedButton;

var SS_PanelScrollBar ScrollBar;

var MaterialInterface Background, BackgroundTooltip;
var MaterialInstanceTimeVarying BackgroundInstance, BackgroundTooltipInstance;

var SS_ContentToolTip_Text ToolTip;

const BUTTON_ON_HOVER = 'OnHover';
const BUTTON_ON_CLICK = 'OnClick';

function Init(HUD H, SS_HUDMenu_PingSystemConfig Menu, int index)
{
    BackgroundInstance = Class'OnlineCommunication'.static.InitMaterial(Background);
    BackgroundTooltipInstance = Class'OnlineCommunication'.static.InitMaterial(BackgroundTooltip);
    ScrollBar.Init();
    ConfigMenu = Menu;
    BuildPanelButton(index);
    BuildPanel();
}

function RenderPanel(HUD H, float backgroundWidth, float backgroundHeight, float backgroundPosX)
{
    local Vector2d title, contentPos;
    local int i;
    local string msg;
    local float maskHeight;
    local bool HoveredOnContent;
    
    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, 255);


    if(BackgroundInstance != None)
        DrawCenterMat(H, H.Canvas.ClipX * backgroundPosX, H.Canvas.ClipY * 0.5f, backgroundWidth, backgroundHeight, BackgroundInstance);
    
    if(HoveredContent != None && HoveredContent.ToolTip.Localizations.Length > 0)
        RenderToolTip(H, backgroundWidth, backgroundHeight, backgroundPosX);
    
    title.X = backgroundPosX - backgroundWidth/2/H.Canvas.ClipX + 0.01f;
    title.Y = H.Canvas.ClipY * 0.5f - backgroundHeight/2;
    
    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, 255);

    msg = Class'SS_HUDMenu_PingSystemConfig'.static.GetSettingsLocalization(PanelName, "panels");
    H.Canvas.Font = GetChatFont(msg);
    
    DrawBorderedText(H.Canvas, msg, (title.X + 0.01f) * H.Canvas.ClipX, title.Y, 0.8f * scale, true, TextAlign_Left);

    contentPos.X = backgroundPosX;

    if(Contents.Length <= 0) return;

    maskHeight = backgroundHeight * 0.9f;
    H.Canvas.PushMaskRegion(title.X, title.Y + 0.05f * backgroundHeight, backgroundWidth * 1.25f, maskHeight, 'Configs');

    if(PanelSizeY < maskHeight/H.Canvas.ClipY)
        contentPos.Y = ContentsStartPosY;
    else
        contentPos.Y = Lerp(ContentsStartPosY, ContentsStartPosY - ScrollBar.maxScrollYPos, ScrollBar.simulatedScroll);

    for(i = 0; i < Contents.length; i++)
    {
        if(RenderContentHover(H, Contents[i], vect2d(ContentPos.X - backgroundWidth * 0.05f/H.Canvas.ClipX/4, ContentPos.Y), vect2d(backgroundWidth * 0.875f/H.Canvas.ClipX, Contents[i].ContentSizeClipped.Y)))
            HoveredOnContent = true;
        Contents[i].RenderContent(H, self, contentPos.X, contentPos.Y);
        contentPos.Y += Contents[i].ContentSizeClipped.Y;
    }
    H.Canvas.PopMaskRegion('Configs');

    if(!HoveredOnContent && !ConfigMenu.IsUsingKeys) HoveredContent = None;

    // Scroll Bar
    if(PanelSizeY > maskHeight/H.Canvas.ClipY)
    {
        contentPos.Y = 0.5f; 
        contentPos.X = backgroundPosX + backgroundWidth/2/H.Canvas.ClipX - 0.0275f; 
        ScrollBar.RenderScrollBar(H, self, maskHeight, contentPos);
    }
    

    if(highlightedButton ~= "") lastHighlightedButton = "";
}

function TickPanel(HUD H, float d)
{
    local int i;

    for(i = 0; i < Contents.length; i++) Contents[i].TickContent(H, d);
}

function TickPanelFocus(HUD h, float d)
{
    ScrollBar.Tick(H, self, d);
}

// Faded Black hover to show which one you are focusing at, QoL.
function bool RenderContentHover(HUD H, SS_PanelContent ContentItem, Vector2D ContentPos, Vector2D ContentSizeClipped)
{
    local bool inAreaContent;
    if(!ContentIsAConfig(ContentItem)) return false;

    ContentPos.X *= H.Canvas.ClipX;
    ContentPos.Y *= H.Canvas.ClipY;
    ContentSizeClipped.X *= H.Canvas.ClipX;
    ContentSizeClipped.Y *= H.Canvas.ClipY;
    
    inAreaContent = IsMouseInArea(H, ContentPos.X, ContentPos.Y, ContentSizeClipped.X, ContentSizeClipped.Y);
    if(inAreaContent && !ConfigMenu.IsUsingKeys || ConfigMenu.IsUsingKeys && HoveredContent == ContentItem)
    {
        Class'SS_Color'.static.SetDrawColor(H, 0, 0, 0, 128);
        DrawCenter(H, ContentPos.X, ContentPos.Y, ContentSizeClipped.X, ContentSizeClipped.Y, H.Canvas.DefaultTexture);
        Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, 255);
        if(HoveredContent != ContentItem)
        {
            OnContentHover(H, ContentItem);
        }
        return true;
    }
    return false;
}

function OnContentHover(HUD H, SS_PanelContent ContentItem) 
{
    HoveredContent = ContentItem;
    ContentItem.OnContentHover();
    PlaySound(H, SoundCue'HatInTime_Hud.SoundCues.CursorMove');
}

function bool ContentIsAConfig(SS_PanelContent ContentItem)
{
    if(!ContentItem.ContentEnabled) return false;
    if(ContentItem.IsA('SS_PanelContent_Config_Base')) return true;
    if(ContentItem.IsA('SS_PanelContent_ButtonURL')) return true;
    return false;
}

// Return true if hovering on this Panel Button
function bool RenderPanelButton(HUD H, Vector2d pos, optional float preScale = 1.0f)
{
    local bool isHovering;
    local float focus;
    local OCButton button;

    button = PanelButton;
    focus = PanelButton.Size.Y/8 * FocusAmount * preScale; // +12.5%
    Class'SS_Color'.static.SetDrawColor(H, 223 + 32 * FocusAmount, 223 + 32 * FocusAmount, 223 + 32 * FocusAmount, 255);
    DrawCenterMat(H, pos.X, pos.Y - focus, PanelButton.size.X * preScale, PanelButton.size.Y * preScale, PanelButton.matInstance);
    isHovering = IsMouseInArea(H, pos.X, pos.Y - (PanelButton.size.Y/4 * preScale) - focus/2, PanelButton.size.X * preScale, (PanelButton.size.Y/2 * preScale) + focus);
    
    if(button.MatInstance != None && (IsHovering || PanelButton.buttonID == button.buttonID))
        button.MatInstance.SetScalarParameterValue(BUTTON_ON_HOVER, 1.0f);
    else
        button.MatInstance.SetScalarParameterValue(BUTTON_ON_HOVER, 0.0f);
    
    return isHovering;
}

function RenderToolTip(HUD H, float backgroundWidth, float backgroundHeight, float backgroundPosX)
{
    DrawCenterMat(H, H.Canvas.ClipX * 0.8f, H.Canvas.ClipY * 0.5f, backgroundWidth * 0.5f, backgroundHeight, BackgroundTooltipInstance);
    HoveredContent.ToolTip.Render(H, self, 0.675f, 0.5 - backgroundHeight/H.Canvas.ClipY/2 + 0.025);
}

function RenderButton(HUD H, out OCButton cb, Vector2D pos)
{
    local bool isHovering;

    DrawCenterMat(H, pos.X * H.Canvas.ClipX, pos.Y * H.Canvas.ClipY, cb.size.X * scale, cb.size.Y, cb.matInstance);
    
    if(!cb.CanBeHovered) return;

    if(!ConfigMenu.IsUsingKeys)
        isHovering = IsMouseInArea(H, pos.X * H.Canvas.ClipX, pos.Y * H.Canvas.ClipY, cb.size.X * scale, cb.size.Y);

    cb.BeingHovered = isHovering;
    if(isHovering) 
        OnHover(H, cb);
    if(cb.MatInstance != None)
        cb.MatInstance.SetScalarParameterValue(class'SS_Panel'.const.BUTTON_ON_HOVER, IsHovering ? 1.0f : 0.0f);       
}

function BuildPanelButton(int index)
{
    if(PanelIcon == None) return;
    PanelButton.ButtonID = 'Panel';
    PanelButton.Argument = Name(""$Index);
    PanelButton.Material = PanelIcon;
    PanelButton = Class'SS_Button'.static.BuildButton(PanelButton); 
}

function BuildPanel()
{
    local int i;
    
    PanelSizeY = 0;
    
    for(i = 0; i < Contents.Length; i++)
    {
        Contents[i].Init();
        Contents[i].ContentEnabled = EnableIf(Contents[i].EnabledIf);
        PanelSizeY += Contents[i].ContentSizeClipped.Y;
    }
}

// Runs when switching to this panel
function OnFocus(HUD H)
{
    ScrollBar.scrollPoint = 0;
    ScrollBar.simulatedScroll = 0;  
    UpdatePanelContent();
}

function UpdatePanelContent()
{
    local int i;
    for(i = 0; i < Contents.Length; i++) Contents[i].OnUpdateContent();
}

function bool OnClick(HUD H, bool release)
{
    local int i;
    local string ButtonID, Argument;
    local Array<string> Splits;
    local OCButton b;
    local SS_GameMod_PingSystem GM;

    if(release)
    {
        OnRelease(H);
        return true;
    }

    if(HighlightedButton ~= "") return true;

    splits = SplitString(highlightedButton, "_", false);
    ButtonID = splits[0];
    Argument = splits[1];

    if(ButtonID ~= "scrollbar")
    {
        ScrollBar.OnClick(H, Argument, self);
        return true;
    }

    GM = ConfigMenu.GameMod;

    for(i = 0; i < Contents.Length; i++)
    {
        if(!(String(Contents[i].ContentName) ~= ButtonID)) continue;
        if(GM.ActiveInputContentPanel != None && GM.ActiveInputContentPanel != Contents[i])
        {
            GM.ActiveInputContentPanel.DisableInputting(H);
            GM.ActiveInputContentPanel = None;
        }
        Contents[i].OnClickContent(H, self, Argument);
        OnClickContent(H, ButtonID, Argument);
        foreach Contents[i].Buttons(b) if(String(b.Argument) ~= Argument) PressedButton = b.MatInstance;
    }

    if(PressedButton != None)
        PressedButton.SetScalarParameterValue(BUTTON_ON_CLICK, 1.0f);
    
    ValidateContent();
    return GM.ActiveInputContentPanel == None || !GM.ActiveInputContentPanel.IsA('SS_PanelContent_Config_InputKey');
}

function bool OnClickAlt(HUD H, bool release)
{
    if(release) return false;

    CancelAnyFocus(H, 0, true);

    return true;
}

// Also runs from Pressing left/right when HoveredContent is none.
function bool OnPressUp(HUD H, bool menu, bool release)
{
    local int index;
    return false;
    if(release) return false;
    index = Contents.Find(HoveredContent);
    HoveredContent = Contents[Max(0, --index)];
    HoveredButtonIndex = INDEX_NONE;
    OnContentHover(H, HoveredContent);
	return false;
}

function bool OnPressDown(HUD H, bool menu, bool release)
{
    
    local int index;
    return false;
    if(release) return false;
    index = Contents.Find(HoveredContent);
    HoveredContent = Contents[Min(Contents.Length - 1, ++index)];
    HoveredButtonIndex = INDEX_NONE;
    OnContentHover(H, HoveredContent);
	return false;
}

function bool OnPressLeft(HUD H, bool menu, bool release)  {return false;} //{return OnPressHorizontal(H, false, release);}
function bool OnPressRight(HUD H, bool menu, bool release) {return false;} // {return OnPressHorizontal(H, true, release);}

function bool OnPressHorizontal(HUD H, bool right, bool release)
{
    if(release)
    {
        //if(HoveredContent.IsA('SS_PanelContent_Config_Base')) SS_PanelContent_Config_Base(HoveredContent).OnKeyPress(H, self, true, true);
        return false;
    }

    if(HoveredContent == None)
    {
        OnPressUp(H, false, release);
        return false;
    }

    if(right)
        HoveredButtonIndex = Min(HoveredContent.Buttons.Length - 1, ++HoveredButtonIndex);
    else
        HoveredButtonIndex = Max(0, --HoveredButtonIndex);
    OnHover(H, HoveredContent.Buttons[HoveredButtonIndex]);
    //if(HoveredContent.IsA('SS_PanelContent_Config_Base')) SS_PanelContent_Config_Base(HoveredContent).OnKeyPress(H, self, true, false);
    return false;
}

function bool OnXClick(HUD H, bool release)
{
	if(release) return false;
    OnClick(H, release);
    return false;
}

// Only on gamepads. Y button on Xbox.
function bool OnYClick(HUD H, bool release)
{
    if(release) return false;
    OnAltClick(H, release);
    return false;
}

function OnClickContent(HUD H, string ButtonID, string Argument)
{
    PlaySound(H, SoundCue'HatInTime_Hud.SoundCues.MenuNext');
}

function CancelAnyFocus(HUD H, FocusType ft, optional bool allTypes = false)
{
    local int i;

    ValidateContent();
    
    for(i = 0; i < Contents.Length; i++)
        switch(allTypes ? 0 : int(ft))
        {
            case 0:
                if(Contents[i].IsA('SS_PanelContent_Config_Slider') && SS_PanelContent_Config_Slider(Contents[i]).IsSliding)
                    SS_PanelContent_Config_Slider(Contents[i]).CancelSlide();
                if(!allTypes) break;
            case 1:
                if(Contents[i].IsA('SS_PanelContent_Config_Input') && SS_PanelContent_Config_Input(Contents[i]).IsInputtingName)
                    SS_PanelContent_Config_Input(Contents[i]).DisableInputting(H);
                if(!allTypes) break;            
        }
    
}

function ValidateContent()
{
    local int i;
    for(i = 0; i < Contents.Length; i++) Contents[i].ContentEnabled = EnableIf(Contents[i].EnabledIf);
}

function OnRelease(HUD H)
{
    ScrollBar.OnRelease(H, self);
    CancelAnyFocus(H, 1);
    if(PressedButton != None)
        PressedButton.SetScalarParameterValue(BUTTON_ON_CLICK, 0.0f);
    PressedButton = None;
}

function OnHover(HUD H, OCButton CB)
{
    HighlightedButton = CB.ButtonID $ "_" $ CB.Argument;
    if(LastHighlightedButton ~= "" || ConfigMenu.IsUsingKeys && !(LastHighlightedButton ~= HighlightedButton))
        PlaySound(H, SoundCue'HatinTime_SFX_Photoshooting.SoundCues.Drawing_Cursor_Select_SmallSize');
    HighlightedButton = CB.ButtonID $ "_" $ CB.Argument;
    LastHighlightedButton = HighlightedButton;
}

function Font GetChatFont(string msg)
{
    return Class'Hat_FontInfo'.static.GetDefaultFont(msg);
}

function bool EnableIf(string argument)
{
    local Array<string> splits;
    local string a, b, datatype, rule;
    local SS_CommunicationSettings cs;
    if(argument ~= "") return true;
    
    splits = SplitString(argument, " ");
    cs = ConfigMenu.GameMod.ChatSettings;
    switch(locs(splits[0]))
    {
        // Config check
        case "config":
            a $= Class'SS_GameMod_PingSystem'.static.GetConfigValue(Class'SS_GameMod_PingSystem', Name(splits[1]));
            splits[0] = "int";
            break;
        case "string":  a $= cs.GetSettingString(splits[1]);    break;
        case "float":   a $= cs.GetSettingFloat(splits[1]);     break;
        case "int":     a $= cs.GetSettingInt(splits[1]);       break;
    }
    datatype = splits[0];
    rule = splits[2];
    b = splits[3];
    return Class'OnlineCommunication'.static.CompareVolatile(a, b, datatype, rule);
}

defaultproperties
{
    SharedInCoop = true;
    ContentsStartPosY = 0.225f;
    RealTime = true;
    Background = MaterialInstanceConstant'HatinTime_HUD_Settings.GameSettings.MenuBox';
    BackgroundTooltip = MaterialInstanceConstant'SS_PingSystem_Content.GraphicsSettings.MenuBox_Tooltip';

    PanelButton = {(
        Size = (X = 48, Y = 96),
        Offset = (X = 0, Y = 0.5f),
        Shine = true
    )}

    Begin Object Class=SS_PanelScrollBar Name=Scroll
    End Object
    ScrollBar = Scroll
    
    Begin Object Class=SS_ContentToolTip_Text Name=ToolTip
    End Object
    ToolTip = ToolTip;

    Scale = 1.0f;
}