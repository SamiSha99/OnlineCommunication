// Ghost Player
Class SS_PingIdentity_GhostPlayer extends SS_PingIdentity;

static function bool ProcessIdentity(Actor target, out string localizationString, out Array<ConversationReplacement> keys)
{
    local Hat_GhostPartyPlayer ghost;
    local Hat_GhostPartyPlayerStateBase ps;
    if(!Super.ProcessIdentity(target, localizationString, keys)) return false;
    ghost = Hat_GhostPartyPlayer(target);
    ps = ghost.PlayerState;
    Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "other", ps.GetNetworkingIDString() $ "_" $ ps.SubID);
    localizationString = "IDENTITY_GHOSTPLAYER";
    return true;
}

static function int GetPriority()
{
    return Super.GetPriority() + 1;
}

defaultproperties
{
    IdentityName = "Hat_GhostPartyPlayer";
}