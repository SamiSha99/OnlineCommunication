// For the Rift Portals in Spaceship for now, anything else will fallback.
Class SS_PingIdentity_SnatcherMinion_Mail extends SS_PingIdentity;

static function bool ProcessIdentity(Actor target, out string localizationString, out Array<ConversationReplacement> keys)
{
    local Hat_NPC_SnatcherMinion_Mail_Base m;

    if(!Super.ProcessIdentity(target, localizationString, keys)) return false;

    localizationString = "Hat_NPC_SnatcherMinion";

    //mail = Hat_NPC_SnatcherMinion_Mail_Base(target);

    foreach GetWorldInfo().DynamicActors(Class'Hat_NPC_SnatcherMinion_Mail_Base', m)
    {
        if(m != target) continue;
        if(m.HasReceivedMail) 
            localizationString = "IDENTITY_SNATCHERMINION_RECEIVED_MAIL";
        else if(!m.MailAlertMesh.HiddenGame) 
            localizationString = "IDENTITY_SNATCHERMINION_WAITING_FOR_MAIL";
        break;
    }
    return true;
}

static function int GetPriority()
{
    return Super.GetPriority() + 1;
}

defaultproperties
{
    IdentityName = "Hat_NPC_SnatcherMinion_Mail_Base";
}