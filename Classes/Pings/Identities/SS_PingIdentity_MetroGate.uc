// Hardcoded token that switches to Grooves based on the act in the dead bird studio chapter
Class SS_PingIdentity_MetroGate extends SS_PingIdentity;

static function bool ProcessIdentity(Actor target, out string localizationString, out Array<ConversationReplacement> keys)
{
    local Hat_MetroTicketGate gate;
    
    if(!Super.ProcessIdentity(target, localizationString, keys)) return false;

    foreach GetWorldInfo().DynamicActors(Class'Hat_MetroTicketGate', gate)
    {
        if(gate != target) continue;
        switch(gate.TicketClass)
        {
            case Class'Hat_Collectible_MetroTicket_RouteA': localizationString = "IDENTITY_METROGATE_YELLOW"; break;
            case Class'Hat_Collectible_MetroTicket_RouteB': localizationString = "IDENTITY_METROGATE_GREEN"; break;
            case Class'Hat_Collectible_MetroTicket_RouteC': localizationString = "IDENTITY_METROGATE_BLUE"; break;
            case Class'Hat_Collectible_MetroTicket_RouteD': localizationString = "IDENTITY_METROGATE_PINK"; break;
            default: localizationString = ""; return false;
        }
    }
    
    return true;
}

static function int GetPriority()
{
    return Super.GetPriority() + 1;
}

defaultproperties
{
    IdentityName = "Hat_MetroTicketGate";
}