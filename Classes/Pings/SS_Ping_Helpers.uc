CLass SS_Ping_Helpers extends Object;

const DEFAULT_PING_LIFETIME = 10;
const CONNECTION_SUCCEED_DURATION = 15;

static function TriggerPingSound(Vector pingLocation, Actor source, optional int desperationLevel = 1)
{
    local SoundCue pingSound;
    local float volume, range;
    
    if(Class'OnlineCommunication'.static.IsGamePaused()) return;
    pingSound = GetPingSound(desperationLevel);

    volume = Class'SS_CommunicationSettings'.default.PingNotificationMasterVolume;
    Class'OnlineCommunication'.static.GetPlayerNearest(pingLocation, range);
    
    range /= 100;
    if(range > Class'SS_CommunicationSettings'.default.PingNotificationRange)
    {
        range -= Class'SS_CommunicationSettings'.default.PingNotificationRange;
        volume *= Lerp(1, 0, range/Class'SS_CommunicationSettings'.default.PingNotificationDecayingRange);
    }
    CreatePingAudioComponent(pingSound, source, volume);
}

// Returns section,section1,section2,default and so on
// Priority:
// 1) Active Candles
// 2) Active Deathwishes
// 3) Map_Act (YourMapName_0/1/2/3/99)
// 4) Map
// 5) Default
static function string GetPotentialPingSections()
{
    local Array < class < Hat_SnatcherContract_DeathWish > > ActiveDeathWishes;
    local class < Hat_SnatcherContract_DeathWish > dw;
    local string sections, map;
    local int actID;
    
    if(class'Hat_SnatcherContract_DeathWish'.static.IsAnyActive(true, true))
    {
        ActiveDeathWishes = class'Hat_SnatcherContract_DeathWish'.static.GetActiveDeathWishes();
        // Passive Contracts
        foreach ActiveDeathWishes(dw) if(dw.default.IsPassive) sections $= String(dw)$",";
        // Normal Contracts
        foreach ActiveDeathWishes(dw) if(!dw.default.IsPassive) sections $= String(dw)$",";
    }

    map = `GameManager.GetCurrentMapFileName();
    actID = `GameManager.GetCurrentAct();
    if(actID != INDEX_NONE) sections $= map$"_"$actID$",";
    sections $= map$",";
    sections $= "default";
    return sections;
}

static function SoundCue GetPingSound(optional int desperationLevel = 1)
{
    switch(Class'SS_GameMod_PingSystem'.default.PingSoundType)
    {
        case 0: return FRand() <= 0.04f ? SoundCue'HatinTime_SFX_Cruise.SoundCues.Cruise_Task_Fail' : SoundCue'HatinTime_SFX_Cruise.SoundCues.Cruise_Task_Appear';
        case 1: return FRand() <= 0.04f ? SoundCue'SS_PingSystem_Content.punchhit_crit' : SoundCue'HatInTime_Weapons.SoundCues.PunchHit';
        case 2: return SoundCue'SS_PingSystem_Content.trumpet_ping';
        case 3: return FRand() <= 0.04f ? SoundCue'HatInTime_Voice_HatKidApphia2.hatkid_intro_beep_cue' : SoundCue'HatinTime_Voice_HatKidApphia4.NewEmoteCue_hatkid_intro_boop_cue';
        case 4: return SoundCue'HatinTime_SFX_MafiaTown2.SoundCues.MafiaTown_BellHit';
        case 5: return SoundCue'HatinTime_SFX_UI.Badge_ReadyToUnlock_FlashBeep_cue';
        case 6: return SoundCue'HatinTime_Voice_CruiseSeals.SoundCues.CruiseSeals_MumbleEgg';
        case 7: return SoundCue'RumbiFactory_W.RumbiBoxAppear';
        case 8: return SoundCue'HatinTime_SFX_Player.SoundCues.Tickets_Pickup';

        case 9: return SoundCue'SS_PingSystem_Content.freediscordnitro_cue';
        case 10: return SoundCue'SS_PingSystem_Content.notif_tf2_alert_cue';
        case 11: return SoundCue'SS_PingSystem_Content.DRG_Pointer_cue';
        case 12: return SoundCue'SS_PingSystem_Content.hots_wc3_ping_cue';
        case 13: return SoundCue'SS_PingSystem_Content.starcraft_2_ping_cue';
        case 14: return SoundCue'SS_PingSystem_Content.portal2ping_cue';
        case 15: return SoundCue'SS_PingSystem_Content.wow_cue';
        case 16: return SoundCue'SS_PingSystem_Content.vine_boom_cue';
        
        
        // too much effort? yes.
        case 96:
            if(desperationLevel >= 3) 
                return SoundCue'SS_PingSystem_Content.Desperate.DesperatePlea_Warning_L3_Cue';
            else if(desperationLevel == 2)
                return SoundCue'SS_PingSystem_Content.Desperate.DesperatePlea_Warning_L2_Cue';
            return SoundCue'SS_PingSystem_Content.Desperate.DesperatePlea_Cue';
        // Load the package, hopefully
        case 97: return SoundCue(DynamicLoadObject(Class'SS_CommunicationSettings'.default.CustomSoundPackage, Class'SoundCue', true));
        case 99: return SoundCue'SS_PingSystem_Meme_Content.Sounds.meme_cue';
        default: return None; // No sound, includes option 98
    }
    return None;
}

/* How long the ping will persist, this is a local adjustment and is irrelevant to the ghost recievers */
static function float GetLifeTime()
{
    if(Class'SS_GameMod_PingSystem'.default.PingLifeTime == 0) return DEFAULT_PING_LIFETIME;
    if(Class'SS_GameMod_PingSystem'.default.PingLifeTime == 99) return 0; // lifespan set to 0 = forever
    return Class'SS_GameMod_PingSystem'.default.PingLifeTime;
}

static function string GetGhostName(EmoteChatInfo eci, optional int index = INDEX_NONE, optional bool StreamerMode = false)
{
    if(Class'Engine'.static.IsEditor()) return Localize("debugging", "GHOST_NAME", "onlinechat");
    if(!StreamerMode) return eci.SteamName;
    return Localize("streamer_mode", "streamer_ghost_" $ Min(eci.SubID, 1), "onlinechat") @ "#"$(index == INDEX_NONE ? GetRightMost(eci.PlayerState.Name) : String(index));
}

// Cheap and done localy, just pass subid
static function string GetLocalNameCheap(optional int subid = 0, optional bool StreamerMode = false)
{
    local string coopExtra;
    if(Class'Engine'.static.IsEditor()) return Localize("debugging", "PLAYER_NAME", "onlinechat");
    coopExtra = (subid != 0 ? " (2)" : "");
    if(!StreamerMode) return Class'OnlineCommunication'.static.GetLocalSteamName() $ coopExtra;
    return Localize("streamer_mode", "streamer_player_" $ Min(subid, 1), "onlinechat");
}

// Returns the playerstate of the Local
static function Hat_GhostPartyPlayerState GetLocalPlayerState(optional int subID = 0)
{
    return Hat_GhostPartyPlayerState(class'Hat_GhostPartyPlayerStateBase'.static.GetLocalPlayerState(subID));
}

/* 
* A temporary "ban" in seconds on someone who's connection is unstable, this could be an issue from your side too so a headsup!
* a simple solution would be to reconnect to online party to fix this
* this detection only occurs if the player leaves before 15 seconds of being in (none interrupted) connection. Anything higher than 15 is assumed as left
* common to those who repeatedly join and leave online party whether manually done quickly or unstable connection
*/
static function int GetFailedConnectionTimeOutDuration()
{
    return 150;
}

static function bool IsPlayerStateTimedOut(Array<GhostTimeOut> GhostsTimeOut, Hat_GhostPartyPlayerStateBase playerState)
{
    local GhostTimeOut ghost;

    foreach GhostsTimeOut(ghost)
    {
        if(!(ghost.SteamID ~= playerState.GetNetworkingIDString())) continue;
        return true;
    }
    return false;
}

static function bool IsConnectionFailed(EmoteChatInfo ghost)
{
    if(!ghost.PlayerState.IsConnectionFailed()) return false;
    // Important that sometimes the player is connected for a LONG TIME and randomly disconnects can be safely discarded as simply as if they left.
    if(Class'WorldInfo'.static.GetWorldInfo().RealTimeSeconds - ghost.StartingConnectionTime > CONNECTION_SUCCEED_DURATION) return false;
    return true;
}

// 0 - Confirm Press
// 1 - On Release
// 2 - Quick Cast
static function int GetPingCastingType()
{
    return Class'SS_GameMod_PingSystem'.default.PingCastType;
}

static function bool PingingForbidden(Hat_Player plyr)
{
	local Hat_PlayerController pc;
    local Hat_HUD hud;

    if(plyr == None) return false; // Uh... excuse me?
    
    if (Class'OnlineCommunication'.static.InCinematicOrFrozen(plyr)) return true;
    if (plyr.IsTaunting("Level_Intro_Front")) return true;
    if (plyr.IsTaunting("Level_Intro_Back")) return true;
    if (plyr.IsTaunting("Bench_Sit")) return true;
	if (plyr.Health <= 0) return true;
	if (plyr.bWaitingForCaveRiftIntro) return true;
	if (plyr.IsTaunting("Died")) return true;
	if (plyr.IsNewItemState()) return true;
	
	pc = Hat_PlayerController(plyr.Controller);
    if (pc == None) return true;
    if (pc.IsTalking()) return true;

    hud = Hat_HUD(pc.myHUD);
    if(hud == None) return true;
    if(IsAnyOfTheseHUDsEnabled(hud)) return true;
    
    if(SS_HUDElement_OnlinePartyChat(hud.GetHUD(Class'SS_HUDElement_OnlinePartyChat')).bChatExpanded) return true;
	
	return false;
}

static function bool IsAnyOfTheseHUDsEnabled(Hat_HUD hud)
{
    local Hat_HUDElement elm;

    foreach hud.m_hElements(elm)
    {
        if(
            elm.IsA('Hat_HUDMenuDecorations') ||
            elm.IsA('Hat_HUDElementContract') ||
            elm.IsA('Hat_HUDMenu_ModLevelSelect') ||
            elm.IsA('Hat_HUDMenu_MetroFood') ||
            elm.IsA('Hat_HUDMenuShop') ||
            elm.IsA('Hat_HUDMenuDeathWish') ||
            elm.IsA('Hat_HUDElementActTitleCard') ||
            elm.IsA('Hat_HUDElementLoadingScreen') ||
            elm.IsA('SS_HUDMenu_PingSystemConfig')
        )
        {
            if(!elm.enabled) continue;
            return true;
        }
    }
    return false;
}

static function AudioComponent CreatePingAudioComponent(
    SoundCue ASound,
    Actor SourceActor,
    optional float VolumeMultiplier = 1.0f, 
    optional float PitchMultiplier = 1.0f,
    optional float FadeInTime = 0,
    optional bool bSuppressSubtitles = false,
    optional bool bSuppressSpatialization = false)
{
	local AudioComponent AC;

	if(SourceActor != None)
	{
        AC = SourceActor.CreateAudioComponent(ASound, false, true);
        if(AC != None)
        {
            AC.VolumeMultiplier = VolumeMultiplier;
            AC.PitchMultiplier = PitchMultiplier;
            AC.bAutoDestroy = true;
            AC.SubtitlePriority = 10000;
            AC.bSuppressSubtitles = bSuppressSubtitles;
            AC.FadeIn(FadeInTime, 1.f);
            if( bSuppressSpatialization )
            {
                AC.bAllowSpatialization = false;
            }
            return AC;
        }
    }
    return None;
}
