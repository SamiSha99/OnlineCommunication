// For the Rift Portals in Spaceship for now, anything else will fallback.
Class SS_PingIdentity_RiftPortal extends SS_PingIdentity;

static function bool ProcessIdentity(Actor target, out string localizationString, out Array<ConversationReplacement> keys)
{
    local string lk, rightMost;
    local Hat_TimeRiftPortal p;

    if(!Super.ProcessIdentity(target, localizationString, keys)) return false;

    localizationString = "IDENTITY_RIFT_PORTAL";

    lk = "";

    if(Class'SS_PingSystem_Private'.const.DANGEROUS_SHOULD_ALWAYSLOADED_FIX)
    {
        foreach GetWorldInfo().DynamicActors(Class'Hat_TimeRiftPortal', p) if(p == target){lk = p.Hourglass; break;}
    }
    else if(Class'OnlineCommunication'.static.InSpaceShip())
    {
        rightMost = GetRightMost(target.Name);
        switch(int(rightMost))
        {
            case 0: lk = "Spaceship_WaterRift_MailRoom"; break;
            case 1: lk = "Spaceship_WaterRift_Gallery"; break;
            case 2: lk = "TimeRift_Cave_Tour"; break;
        }
    }

    Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "rift_name",  "HatinTimeGame>levels>" $ lk);

    return true;
}

static function int GetPriority()
{
    return Super.GetPriority() + 1;
}

defaultproperties
{
    IdentityName = "Hat_TimeRiftPortal";
}