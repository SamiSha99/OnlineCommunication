Class SS_ContentToolTip_Text extends SS_ContentToolTip;

var Array<string> Localizations;
var Array<OCLogInfo> Log;
var OCSettings settings;
var bool inited;

function InitToolTip(optional Array<string> locs)
{
    if(inited) return;
    inited = true;
    Localizations = locs;
    GameMod = GetGameMod();
    Build();
}

function Render(HUD H, SS_Panel panel, float x, float y)
{
    settings.ChatPosClipped.X = x;
    settings.ChatPosClipped.Y = y;
    settings.clippedLimit = 0.225;
    settings.ChatLimitRender = 20;
    settings.topToBottomRender = true;
    Class'SS_ChatFormatter'.static.DrawChat(H, Log, 0.6f * panel.Scale, settings);
}

function OnUpdateRequest()
{
    Build();
}

function Build()
{
    local Array<ConversationReplacement> keys;
    local string text, l;

    Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "owner", Class'OnlineCommunication'.static.GetLocalSteamID() $ "_0");
    Log.Length = 0;
    foreach Localizations(l)
    {
        text = GetLocalization(l);
        if(GameMod != None)
            GameMod.StringAugmenter.DoDynamicArguments(text, keys);
        Log.AddItem(Class'SS_ChatFormatter'.static.Build(text)); 
    }
}

function SS_GameMod_OC GetGameMod()
{
    return SS_GameMod_OC(class'OnlineCommunication'.static.GetGameMod('SS_GameMod_OC'));
}

function string GetLocalization(string loc)
{
    local string l;
    l = Class'SS_HUDMenu_PingSystemConfig'.static.GetSettingsLocalization(loc, "tooltip");
    
    return Class'Hat_Localizer'.static.ContainsErrorString(l) ? loc : l;
}