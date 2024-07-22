// For any random announcement checks, most functions here handled in the GameMod
Class SS_AnnouncerManager extends Object;

var SS_GameMod_OC GameMod;

var Array < Class < SS_Announcer > > AnnouncerClasses;
var Array < SS_Announcer > AnnouncerObjects;

function Init()
{
    local Class<SS_Announcer> aC;
    local SS_Announcer a;

    foreach AnnouncerClasses(aC)
    {
        if(!ac.static.ShouldCreate()) continue;
        a = new aC;
        a.Init();
        a.GameMod = GameMod;
        AnnouncerObjects.AddItem(a);
    }
}

function Tick(float d)
{
    local int i;
    for(i = 0; i < AnnouncerObjects.Length; i++) AnnouncerObjects[i].Tick(d);
}

function GhostTick(float d)
{
    local int i;
    for(i = 0; i < AnnouncerObjects.Length; i++) AnnouncerObjects[i].GhostTick(d);
}

function bool OnPing(Hat_PlayerController pc, optional bool released = false)
{
    local int i;
    for(i = 0; i < AnnouncerObjects.Length; i++) if(!AnnouncerObjects[i].OnPing(pc, released)) return false;
    return true;
}

function OnCollectibleSpawned(Object InCollectible)
{
    local int i;
    for(i = 0; i < AnnouncerObjects.Length; i++) AnnouncerObjects[i].OnCollectibleSpawned(InCollectible);
}

function OnPreOpenHUD(HUD H, out class<Object> InHUDElement)
{
    local int i;
    for(i = 0; i < AnnouncerObjects.Length; i++) AnnouncerObjects[i].OnPreOpenHUD(H, InHUDElement);
}

function OnRemoteEvent(Name EventName)
{
    local int i;
    for(i = 0; i < AnnouncerObjects.Length; i++) AnnouncerObjects[i].OnRemoteEvent(EventName);
}

function OnAnnouncementRecieved()
{
    local int i;
    for(i = 0; i < AnnouncerObjects.Length; i++) AnnouncerObjects[i].OnAnnouncementRecieved();
}

defaultproperties
{
    AnnouncerClasses.Add(Class'SS_Announcer_VC');
    AnnouncerClasses.Add(Class'SS_Announcer_RadioOverride');
    AnnouncerClasses.Add(Class'SS_Announcer_DeathWish');
    // AnnouncerClasses.Add(Class'SS_Announcer_GhostPartyActSelect');
}