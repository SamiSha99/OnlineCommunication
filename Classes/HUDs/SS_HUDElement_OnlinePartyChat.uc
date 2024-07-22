Class SS_HUDElement_OnlinePartyChat extends Hat_HUDMenu
    dependsOn(SS_ChatFormatter, SS_GameMod_OC, SS_Color);

var SS_GameMod_OC GameMod;

var Array<OCLogInfo> chat;

const CHAT_RENDER_AMOUNT_LIMIT = 12;
const CHAT_ARRAY_LIMIT = 25;
const CHAT_BUTTON_SIZE_SMALL = 48;

// Buttons
var bool bChatExpanded;
var bool bCustomConfigMenu;

var Array<OCButton> buttons;
var int highlightedButton;
var bool bDragging;

// To-Do: configurable scaler built into this HUD!
var Vector2D ChatPosClipped, MouseDragStartPos, OriginalChatPos;
var float ChatClippedXLimit;

// Mouse
var MaterialInterface MouseMat;
var MaterialInstanceTimeVarying MouseMatInstance;

const BUTTON_ON_HOVER = 'OnHover';
const BUTTON_ON_CLICK = 'OnClick';

function OnOpenHUD(HUD H, optional String command)
{   

	Super.OnOpenHUD(H, command);

    MouseMatInstance = Class'OnlineCommunication'.static.InitMaterial(MouseMat);
        
    buttons = Class'SS_Button'.static.BuildButtons(buttons);

    SetTimer(H, 0.01f, false, NameOf(LoadSettings), self);
}

function LoadSettings()
{
    if(GameMod != None && GameMod.ChatSettings != None)
    {
        ChatClippedXLimit = GameMod.ChatSettings.ChatClippedXLimit == 0 ? 0.3f : GameMod.ChatSettings.ChatClippedXLimit;
        ChatPosClipped = GameMod.ChatSettings.ChatPosClipped;
    }
}

function bool Render(HUD H)
{
    local float scale;
    local OCSettings settings;

    if(!Super.Render(H)) return false;
    if(bCustomConfigMenu) return false;
   
    scale = FMin(H.Canvas.ClipX, H.Canvas.ClipY) / 1080.0f;
    scale *= Class'SS_CommunicationSettings'.default.GlobalScale * 0.625f;
    
    settings.ChatPosClipped = ChatPosClipped;
    settings.forceVisiblity = bChatExpanded;
    settings.clippedLimit = ChatClippedXLimit;
    settings.ChatLimitRender = CHAT_RENDER_AMOUNT_LIMIT;

    H.Canvas.Font = settings.f;
    Class'SS_ChatFormatter'.static.DrawChat(H, chat, scale, settings);
    
    if(!bChatExpanded) return true;
    DrawChatEditor(H, scale, settings);
    
    return true;
}

function bool Tick(HUD H, float d)
{
    local int i;

    if(!Super.Tick(H, d)) return false;

    for(i = 0; i < chat.Length; i++)
    {
        chat[i].lifetime = FMax(chat[i].lifetime - d, 0.0f);
        chat[i].shake = FMax(chat[i].shake - d * 40, 0.0f);
    }

    return true;
}

function DrawChatEditor(HUD H, float scale, OCSettings settings)
{
    local OCButton cb;
    local Vector2d mousePos;
    local int i;
    local float clipX, clipY, buttonYPos, buttonXPos;
    local bool isHighlightingButton;
    const BUTTON_OFFSET = 6;

    clipX = H.Canvas.ClipX;
    clipY = H.Canvas.ClipY;

    buttonYPos = ChatPosClipped.Y * clipY + CHAT_BUTTON_SIZE_SMALL;

    if(bDragging)
    {
        ChatPosClipped.X = FClamp(OriginalChatPos.X + (GetMousePosX(H) - MouseDragStartPos.X)/clipX, 0, 1.0f - CHAT_BUTTON_SIZE_SMALL/clipX);
        ChatPosClipped.Y = FClamp(OriginalChatPos.Y + (GetMousePosY(H) - MouseDragStartPos.Y)/clipY, 0 - 0.5 * CHAT_BUTTON_SIZE_SMALL/clipY, 1.0f - 1.5*CHAT_BUTTON_SIZE_SMALL/clipY);
    }

    for(i = 0; i < buttons.Length; i++)
    {
        cb = buttons[i];
        switch(cb.buttonID)
        {
            case 'BUTTON_DRAG':
                buttonXPoS = ChatPosClipped.X * clipX + cb.size.x/2;
                break;
            case 'BUTTON_DOWNSCALE':
                buttonXPoS = ChatPosClipped.X * clipX + 3 * cb.size.x/2 + BUTTON_OFFSET;
                break;
            case 'BUTTON_UPSCALE':
                buttonXPoS = ChatPosClipped.X * clipX + 5 * cb.size.x/2 + BUTTON_OFFSET * 2;
                break;
            case 'BUTTON_CONFIG':
                buttonXPoS = (ChatPosClipped.X + FMax(0.2f, ChatClippedXLimit)) * clipX - cb.size.x/2;
                break;
            case 'BUTTON_RESET':
                buttonXPoS = (ChatPosClipped.X + FMax(0.2f, ChatClippedXLimit)) * clipX - 3 * cb.size.x/2 - BUTTON_OFFSET;
                break;
            default:
                break;
        }

        if(IsMouseInArea(H, buttonXPoS, buttonYPos, cb.size.x, cb.size.y) || cb.buttonID == 'BUTTON_DRAG' && bDragging)
        {
            buttons[i].MatInstance.SetScalarParameterValue(BUTTON_ON_HOVER, 1.0f);       
            highlightedButton = i;
            isHighlightingButton = true;
        }
        else
            buttons[i].MatInstance.SetScalarParameterValue(BUTTON_ON_HOVER, 0.0f);
        
        DrawCenter(H, buttonXPoS, buttonYPos, cb.size.x, cb.size.y, cb.MatInstance);   
    }

    // tooltip
    if(highlightedButton != -1 && !bDragging) RenderToolTip(H, scale, settings);   

    if(!isHighlightingButton) highlightedButton = -1;

    if(MouseMatInstance != None)
    {
        mousePos = GetMousePos(H);
        DrawCenterMat(H, mousePos.X + 20 - 4, mousePos.Y + 20 - 4, 40, 40, MouseMatInstance);
    }
}

function RenderToolTip(HUD H, float scale, OCSettings settings)
{
    local float posX, posY, mouseX, mouseY, clipX, clipY, tooltipScale;
    local TextAlign alignment;
    local string tooltip;
    local float textLengthX, textLengthY, correctFontScale; 
    local bool right, down;

    mouseX = GetMousePosX(H);
    mouseY = GetMousePosY(H);
    clipX = H.Canvas.ClipX;
    clipY = H.Canvas.ClipY;
    
    right = mouseX > clipX * 0.5f;
    down = mouseY > clipY * 0.5f;

    tooltipScale = Class'SS_CommunicationSettings'.default.GlobalScale * 0.5f;

    posX = FMax(tooltipScale, 1.0f) * scale * (right ? -1 : 1) * CHAT_BUTTON_SIZE_SMALL/0.8f + mouseX;
    alignment = right ? TextAlign_Right : TextAlign_Left;

    posY = FMax(tooltipScale, 1.0f) * scale * (down ? -1 : 1) * CHAT_BUTTON_SIZE_SMALL/0.8f + mouseY; 
    
    Class'SS_HUDMenu_PingSystemConfig'.static.GetSettingsLocalization(buttons[highlightedButton].buttonID, "chatexpand", tooltip);
    
    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, 255);
    GameMod.StringAugmenter.DoDynamicArguments(tooltip);
    correctFontScale = Class'SS_ChatFormatter'.static.GetCorrectFontScale(tooltip, settings.f);
    H.Canvas.TextSize(tooltip, textLengthX, textLengthY, 0.7f * tooltipScale * correctFontScale, 0.7f * tooltipScale * correctFontScale);
    Class'SS_Color'.static.SetDrawColor(H, 108, 180, 238, 255);
    DrawCenter(H, posX + (right ? -textLengthX : textLengthX)/2, posY, textLengthX * 1.08f, textLengthY + textLengthX * 0.08f, H.Canvas.DefaultTexture);
    Class'SS_Color'.static.SetDrawColor(H, 31, 117, 254, 255);
    DrawCenter(H, posX + (right ? -textLengthX : textLengthX)/2, posY, textLengthX * 1.06f, textLengthY + textLengthX * 0.06f, H.Canvas.DefaultTexture);
    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, 255);
    DrawBorderedText(H.Canvas, tooltip, posX, posY, 0.7f * tooltipScale * correctFontScale, false, alignment, 0.5f, 4.0f/correctFontScale);
}

function bool ExpandChat(HUD H)
{
    bChatExpanded = !bChatExpanded;
    if(!bChatExpanded && GameMod != None)
    {
        if(GameMod.ChatSettings == None) GameMod.LoadChatSettings();
        UpdateSettings();
    }
    bDragging = false;
    return false;
}

function UpdateSettings()
{
    GameMod.ChatSettings.ChatPosClipped = ChatPosClipped;
    GameMod.SaveChatSettings();
}

function bool OnRecievedChatLogCommand(string _id, optional string section = "templates", optional Array<ConversationReplacement> keys, optional string fileName = "onlinechat")
{
    local string script;
    local OCLogInfo log;

    if(_id == "") return false;
    if(!Class'SS_ChatFormatter'.static.GetLocalizationLog(_id, section, filename, script)) return false;
    if(GameMod.StringAugmenter != None) GameMod.StringAugmenter.DoDynamicArguments(script, keys);
    
    script = Class'SS_1984'.static.Literally1984(script);

    log = Class'SS_ChatFormatter'.static.Build(script);
    InsertLogIntoChat(log);
    return true;
}

function AddEmoteToChat(Array<ConversationReplacement> keys, optional Surface EmoteIcon = None, optional String EmoteText = "", optional Hat_GhostPartyPlayerStateBase Sender = None, optional bool emotingToOther)
{
    local string script;
    local OCLogInfo log;
    local OCSegment EmoteSegment;

    if(!Class'SS_ChatFormatter'.static.GetLocalizationLog(emotingToOther ? "EMOTE_REPLY_TO_OTHER" : "EMOTE_REPLY", "templates", "onlinechat", script)) return;

    if(keys.Length < 0 || EmoteIcon == None && EmoteText ~= "")
    {
        Class'SS_GameMod_OC'.static.Print("BAD EMOTE RECIEVED, IGNORING!!!");
        return;
    }

    if(GameMod.StringAugmenter != None) GameMod.StringAugmenter.DoDynamicArguments(script, keys);
    
    script = Class'SS_1984'.static.Literally1984(script);
    log = Class'SS_ChatFormatter'.static.Build(script);

    // Add the player response
    EmoteSegment = Class'SS_ChatFormatter'.static.CreateSegment(EmoteText, EmoteIcon, EmoteIcon != None ? GetColor(White) : Class'SS_Color'.static.Hex(Class'SS_CommunicationSettings'.default.ChatEmoteTextColor));
    log.Segments[log.Segments.Length - 1].AddSpace = true;
    log.Segments.AddItem(EmoteSegment);
    
    InsertLogIntoChat(log);
}

function InsertLogIntoChat(OCLogInfo loginfo)
{
    Class'SS_ChatFormatter'.static.AddStartOfLogIndicator(loginfo);

    if(LogIsDuplicate(loginfo)) return;
    
    loginfo.lifetime = GetLifeTime();
    chat.InsertItem(0, loginfo);
    if(chat.Length > CHAT_ARRAY_LIMIT) chat.Length = CHAT_ARRAY_LIMIT;
}

function bool LogIsDuplicate(OCLogInfo loginfo)
{
    local int i, u, spamlevel, max;
    local bool notDupe;
    
    if(chat.Length <= 0) return false;
        
    spamlevel = Class'SS_CommunicationSettings'.default.AntiSpam;
    if(spamlevel <= 0) return false;

    max = spamlevel >= 2 ? chat.Length : 1;
    for(i = 0; i < max; i++)
    {
        if(chat[i].Segments.Length != loginfo.Segments.Length) continue;
        notDupe = false;
        for(u = 0; u < chat[i].Segments.Length; u++)
        {
            if(chat[i].Segments[u] == loginfo.Segments[u]) continue;
            notDupe = true;
            break;
        }
        if(notDupe) continue;
        if(spamlevel != 1 && i != 0 && chat[i].lifetime <= 0) break;
        if(i == 0) chat[i].lifetime = GetLifeTime();
        chat[i].Combo++;
        chat[i].shake = FMin(15, chat[i].shake + chat[i].Combo * 3);
        return true;
    }
    return false;
}

function Color GetColor(ColorName _ColorName)
{
    return Class'SS_Color'.static.GetColor(_ColorName);
}

function float GetLifeTime()
{
    return 10.0f; // not to be confused with the ping config lifetime!
}

function bool OnClick(HUD H, bool release)
{
    if(!bChatExpanded) return false;

    if(MouseMatInstance != None)
        MouseMatInstance.SetScalarParameterValue('OnClick', release ? 0.0f : 1.0f);

    if(release)
    {
        OnRelease(H);
        return true;
    }

    if(highlightedButton == -1) return true;

    buttons[highlightedButton].MatInstance.SetScalarParameterValue(BUTTON_ON_CLICK, 1.0f);
    
    switch(buttons[highlightedButton].buttonID)
    {
        case 'BUTTON_DRAG':
            bDragging = true;
            MouseDragStartPos = GetMousePos(H);
            OriginalChatPos = ChatPosClipped;
            break;
        case 'BUTTON_DOWNSCALE':
            GameMod.ChatSettings.SetSettingFloat("GlobalScale", FClamp(Class'SS_CommunicationSettings'.default.GlobalScale - 0.05f, 0.5f, 2.0f));
            break;
        case 'BUTTON_UPSCALE':
            GameMod.ChatSettings.SetSettingFloat("GlobalScale", FClamp(Class'SS_CommunicationSettings'.default.GlobalScale + 0.05f, 0.5f, 2.0f));
            break;
        case 'BUTTON_RESET':
            GameMod.ChatSettings.SetSettingFloat("GlobalScale", GameMod.ChatSettings.GetSettingFloat("GlobalScale", true));
            ChatPosClipped = default.ChatPosClipped;
            break;
        case 'BUTTON_CONFIG':
            OnRelease(H);
            bChatExpanded = false;
            SS_HUDMenu_PingSystemConfig(OpenHUD(H, Class'SS_HUDMenu_PingSystemConfig')).GameMod = GameMod;
            bCustomConfigMenu = true;
            break;
    }
    UpdateSettings();

    return true;
}

function OnRelease(HUD H)
{
    bDragging = false;
    MouseDragStartPos = vect2d(0,0);
    OriginalChatPos = vect2d(0,0);
    UnclickAllButtons();
}

function UnclickAllButtons()
{
    local int i;
    for(i = 0; i < buttons.Length; i++) buttons[i].MatInstance.SetScalarParameterValue(BUTTON_ON_CLICK, 0.0f);
}

function bool DisablesMovement(HUD H)
{
    return bChatExpanded;
}

function bool DisablesCameraMovement(HUD H)
{
    return bChatExpanded;
}

defaultproperties
{
    //RequiresMouse = true;
    SharedInCoop = true;
    HideIfPaused = true;
    WantsTick = true;
    ChatPosClipped = (X = 0.0125f, Y = 0.666f)
    RenderIndex = -2;
    ChatClippedXLimit = 0.3f;
    highlightedButton = -1;

    MouseMat = Material'SS_PingSystem_Content.UIMouse';

    buttons(0) = {(
        buttonID = "BUTTON_DRAG",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Drag'
    )};
    
    buttons(1) = {(
        buttonID = "BUTTON_DOWNSCALE",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Minus'
    )};

    buttons(2) = {(
        buttonID = "BUTTON_UPSCALE",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Plus'
    )};

    buttons(3) = {(
        buttonID = "BUTTON_CONFIG",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Config'
    )};
    
    buttons(4) = {(
        buttonID = "BUTTON_RESET",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Restore'
    )};
}