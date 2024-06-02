// Hardcoded token that switches to Grooves based on the act in the dead bird studio chapter
Class SS_PingIdentity_Collectible_ConductorToken extends SS_PingIdentity;

static function bool ProcessIdentity(Actor target, out string localizationString, out Array<ConversationReplacement> keys)
{
    local Hat_Collectible_HighscoreToken token;
    if(!Super.ProcessIdentity(target, localizationString, keys)) return false;

    token = Hat_Collectible_HighscoreToken(target);
    
    localizationString = (token.Mesh.Materials[0] == token.AltMaterial || token.Mesh.Materials[0] == token.AltMaterialTranslucent) ? "IDENTITY_TOKEN_DJ" : "IDENTITY_TOKEN_CONDUCTOR";
    
    return true;
}

static function int GetPriority()
{
    return Super.GetPriority() + 1;
}

defaultproperties
{
    IdentityName = "Hat_Collectible_HighscoreToken";
}