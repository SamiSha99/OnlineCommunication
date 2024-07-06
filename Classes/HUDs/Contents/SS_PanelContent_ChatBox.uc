Class SS_PanelContent_ChatBox extends SS_PanelContent;

var string Localization;
var ChatSettings settings;

var Array<OnlineChatLogInfo> Log;

function Init()
{
    Super.Init();
    UpdateLog();
}

function RenderContent(HUD H, SS_Panel panel, float x, float y)
{
    settings.ChatPosClipped.X = x - 0.225f;
    settings.ChatPosClipped.Y = y;
    settings.clippedLimit = 0.44;
    settings.ChatLimitRender = 10;
    settings.topToBottomRender = true;
    Class'SS_ChatFormatter'.static.DrawChat(H, Log, 0.50f * panel.Scale, settings);
}

function OnUpdateContent()
{
    Super.OnUpdateContent();
    UpdateLog();
}

function UpdateLog()
{
    local Array<ConversationReplacement> keys;
    local string text;
    text = GetLocalization();
    Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "owner", Class'OnlineCommunication'.static.GetLocalSteamID() $ "_0");
    GetGameMod().StringAugmenter.DoDynamicArguments(text, keys);
    log.Length = 0;
    log.AddItem(Class'SS_ChatFormatter'.static.BuildChatLog(text));
}

function string GetLocalization()
{
    local string l;
    l = Class'SS_HUDMenu_PingSystemConfig'.static.GetSettingsLocalization(Localization, "ChatBox");
    return Class'Hat_Localizer'.static.ContainsErrorString(l) ? Localization : l;
}

defaultproperties
{

}