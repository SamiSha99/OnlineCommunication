// Who would have thought that profanity is in fact an expensive call to cast on all tooltips when its going to be used once?
Class SS_ContentToolTip_Text_Profanity extends SS_ContentToolTip_Text;

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
        text = Class'SS_1984'.static.Literally1984(text);
        Log.AddItem(Class'SS_ChatFormatter'.static.Build(text)); 
    }
}