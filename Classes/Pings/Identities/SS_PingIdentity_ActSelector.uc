// Act Selector a little more flavored for clarity, in theory it should work with modded chapters
Class SS_PingIdentity_ActSelector extends SS_PingIdentity;

static function bool ProcessIdentity(Actor target, out string localizationString, out Array<ConversationReplacement> keys)
{
    local Hat_ActSelector actSelector;
    local Hat_ChapterInfo ci;
    
    if(!Super.ProcessIdentity(target, localizationString, keys)) return false;

    actSelector = Hat_ActSelector(target);
    ci = actSelector.GetChapterInfo();
    Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "chapter_name", "HatinTimeGame>levels>" $ ci.ChapterName);
    localizationString = "IDENTITY_ACT_SELECTOR";
    return true;
}

static function int GetPriority()
{
    return Super.GetPriority() + 1;
}

defaultproperties
{
    IdentityName = "Hat_ActSelector";
}