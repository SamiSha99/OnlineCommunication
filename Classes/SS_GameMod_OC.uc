Class SS_GameMod_OC extends GameMod
    dependson(SS_Ping_Identifier)
    Config(Mods);

struct EmoteChatInfo
{
    var Hat_GhostPartyPlayerStateBase PlayerState;
    var SS_PingSpot PingSpot;

    var float LastEmoteMessageTime;

    var string SteamName;
    var string SteamID;
    var byte SubID; // For coop ghosts
    var float StartingConnectionTime; // To "properly" assume if they intetionally disconnected or "minor disconnect, oopsy!"
    var bool HasModInstalled;

    // Inspired by this video: https://www.youtube.com/watch?v=mMiXr-3lQh8
    var float MuteTime, PingCastMuteTime;
    // Desperation for ping spams, mute time is frozen when ping limited
    var float DesperationTime;
    var int Desperation;
};

struct EmoteChatInfo_LocalPlayers extends EmoteChatInfo
{
    var Interaction KeyCaptureInteraction;
    var SS_HUDElement_Ping PingHUD;
    var Hat_Player player;
    var Hat_PlayerController pc;
};

struct GhostTimeOut
{
    var float Duration;
    var string SteamID;

    structdefaultproperties
    {
        Duration = 60;
    }
};

const FROSTBURN_CLIFFS_2 = class'SS_PingSystem_Private';

// When it doesn't work, just let them open it manually.
var config int OpenExpandedConfigMenu;

var SS_CommunicationSettings ChatSettings;
var SS_PanelContent_Config_Input ActiveInputContentPanel;
var SS_HUDElement_OnlinePartyChat OnlineChatHUD;
var SS_DynamicString StringAugmenter;
var SS_AnnouncerManager AnnouncerManager;

// Both of these are use WorldInfo.TimeSeconds
var float nextCheckTime;
var float nextUpdateTime;

var Array<EmoteChatInfo> GhostReader;
var Array<EmoteChatInfo_LocalPlayers> LocalReader;

var Array<GhostTimeOut> GhostsTimeOut;

var bool StreamerMode;
var bool PingFromEmote;

var Array<SoundCue> ReferenceSounds;

function OnModLoaded()
{
    HookActorSpawn(class'Hat_Player', 'hat_player');
    HookActorSpawn(class'Hat_GhostPartyPlayerBase', 'ghost');
    SetTimer(0.01, false, NameOf(PostModLoading), self);
}

function PostModLoading()
{
    Class'SS_PingSupport'.static.ApplyReferences(self); // Apparently doesn't run on modloaded, which is... so stupid lol, so let's run in the next iteration after the mod was loaded
}

function OnModUnloaded()
{
    local int i;
    local Interaction inting;
    for(i = 0; i < LocalReader.Length; i++)
    {
        inting = LocalReader[i].KeyCaptureInteraction;
        Class'OnlineCommunication'.static.UnRegisterInputEvent(Class'OnlineCommunication'.static.GetPlayer(i), inting);
        LocalReader[i].KeyCaptureInteraction = None;
    }
    LocalReader.Length = 0;
    GhostReader.Length = 0;
}

function Tick(float d)
{
    local float realestDelta;
    
    realestDelta = GetRealTick(d);
    ManageMute(realestDelta);
    ManageTimedOutGhosts(realestDelta);

    if(AnnouncerManager != None) 
        AnnouncerManager.Tick(realestDelta);

    if(nextUpdateTime < WorldInfo.RealTimeSeconds - FMax(realestDelta, (1.0f/FROSTBURN_CLIFFS_2.const.ONLINE_PARTY_READER_UPDATE)))
    {
        UpdateGhosts();
    }

    if(StreamerMode) UpdateGhostShowcaseName(); // Replace ghosts name tag to show as the Ghost's PlayerState ID, also spam unhide on them

    if(nextCheckTime < WorldInfo.RealTimeSeconds - FMax(realestDelta, (1.0f/FROSTBURN_CLIFFS_2.const.GHOST_CHECKS_TICK)))
        TickGhost((1.0f/FROSTBURN_CLIFFS_2.const.GHOST_CHECKS_TICK));
    
}

function OnHookedActorSpawn(Object NewActor, Name Identifier)
{
    local Hat_Player plyr;

    switch(Caps(Identifier))
    {
        case "HAT_PLAYER":
            plyr = Hat_Player(NewActor);
            SetTimer(0.01f, false, NameOf(OnPostHookedActorSpawn), self, plyr);
            break;
        case "GHOST":
            if(ChatSettings != None)
                ChatSettings.UpdateMetaStates();
            break;
    }

    if(Class'SS_PingSupport'.static.HookedActorRequiresSupport(NewActor))
        AttachPingSupport(Actor(NewActor));
}

function OnOnlinePartySettingsUpdated(bool bOnline, Name LobbyName, bool bWasOnline, Name PrevLobbyName)
{
    local Array<ConversationReplacement> keys;
    if(!bOnline) return;
    if(ChatSettings != None)
        ChatSettings.UpdateMetaStates();

    if(LobbyName != PrevLobbyName)
    {
        Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "lobby", LobbyName == 'None' ? ">ghostparty>lobby>LobbyNameRandom" : String(LobbyName));
        OnRecievedChatLogCommand("SWITCH_LOBBY", "templates", "onlinechat", keys);
    }
}

function OnPlayerEmote(class<Hat_GhostPartyEmote_Base> Emote, Actor Player, bool bPlaySound)
{
    local Hat_ObjectiveActor_GhostPartyPlayer flag;
    local Hat_GhostPartyPlayerStateBase playerState, other;
    local Array<ConversationReplacement> keys;
    local bool reply;
    local int i;
    if(!Class'SS_CommunicationSettings'.default.EnableEmotes || OnlineChatHUD == None) return;

    Print("Emote:" @ emote @ "| Player:" @ Player @ "| Play Sound =?" @ bPlaySound);

    if(Player.IsA('Hat_GhostPartyPlayer'))
    {
        flag = Hat_GhostPartyPlayer(player).ObjectiveActor;
        playerState = Hat_GhostPartyPlayer(player).PlayerState;
        // A Ghost needs to be subscriber, otherwise a lot of bugs happen.
        i = GhostReader.Find('PlayerState', PlayerState);
        if(i == INDEX_NONE || GhostReader[i].LastEmoteMessageTime == flag.EmoteMessageTime) return;
        GhostReader[i].LastEmoteMessageTime = flag.EmoteMessageTime;
    }
    else if(Player.IsA('Hat_Player')) 
    {
        flag = Hat_Player(Player).ObjectiveActor_GhostParty;
        playerState = Class'Hat_GhostPartyPlayerStateBase'.static.GetLocalPlayerState(Hat_Player(Player).GetPlayerIndex());
    }

    if(flag == None || playerState == None) 
    {
        Print("Failed to get Flag or PlayerState Emote holder!! Flag:" @ flag @ "| PlayerState:" @ playerState);
        return;
    }

    Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "owner", playerState.GetNetworkingIDString()$"_"$playerState.SubID);
    reply = GetOtherActor(Player, other);
    if(reply)
        Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "other", other.GetNetworkingIDString()$"_"$other.SubID);
    
    OnlineChatHUD.AddEmoteToChat(keys, flag.EmoteIcon, flag.LocalizedEmoteMessage, playerState, reply);
}

function OnPostHookedActorSpawn(Hat_Player plyr)
{
    LoadChatSettings();
    if(StringAugmenter == None)
    {
        StringAugmenter = new Class'SS_DynamicString';
        StringAugmenter.GameMod = self;
    }

    if(ChatSettings != None)
    {
        ChatSettings.GameMod = self;
        ChatSettings.Init();
    }

    AddLocalPlayer(plyr);
    UpdateGhosts(); // Forced on load
    OpenOnlineChat(plyr.Controller);
    OpenPingHUD(plyr.Controller);

    if(AnnouncerManager == None) 
    {
        AnnouncerManager = new Class'SS_AnnouncerManager';
        AnnouncerManager.GameMod = self;
        AnnouncerManager.Init();    
    }
}

// key dictionary identified as long as a command string serperated by PRIMARY delim |
// COMMAND TYPE|KEY VARIABLES
// Example:
// do_ping?map=subcon&lobby=peck
event OnOnlinePartyCommand(string Command, Name CommandChannel, Hat_GhostPartyPlayerStateBase Sender) 
{
    local Array<string> splits;
    
    if(!Class'Engine'.static.IsEditor() && Sender == None) return;
    if(FROSTBURN_CLIFFS_2.const.COMMMAND_CHANNEL_NAME != CommandChannel) return;

    if(InStr(Command, FROSTBURN_CLIFFS_2.const.COMMAND_PRIMARY_DELIM, false) == INDEX_NONE)
    {
        Print("MISSING " $ FROSTBURN_CLIFFS_2.const.COMMAND_PRIMARY_DELIM $ " IN THE ARGUMENTS IN COMMAND: \"" @ Command $ "\"");
        return;
    }

    splits = SplitString(Command, FROSTBURN_CLIFFS_2.const.COMMAND_PRIMARY_DELIM);

    DoCommand(splits[0], Sender, splits[1]);
}

function OnRemoteEvent(Name EventName)
{
    if(AnnouncerManager != None) AnnouncerManager.OnRemoteEvent(EventName);
}

function OnPreOpenHUD(HUD InHUD, out class<Object> InHUDElement)
{
    local Hat_HUDMenu_ModLevelSelect modselect;

    // Override Old Config Menu
    if(String(InHUDElement) ~= "Hat_HUDMenuSettings")
    {
        modselect = Hat_HUDMenu_ModLevelSelect(Hat_HUD(InHUD).GetHUD(Class'Hat_HUDMenu_ModLevelSelect'));

        // to-do: run the check after a frame and see if the passed preview in this settings menu is the right one
        if(modselect != None && (modselect.PreviewMod.PackageName ~= "OnlineCommunication" || modselect.PreviewMod.WorkshopId == GetGameModFromClass(Class).WorkshopID))
        {
            Print("You thought it was going to automatically open the extended config menu but it was me Dio!");
            Print("modselect != None =?" @ modselect != None @ "| modselect.PreviewMod.PackageName =>" @ modselect.PreviewMod.PackageName);
            Print("modselect.PreviewMod.WorkshopId" @ modselect.PreviewMod.WorkshopId @ "| GetGameModFromClass(Class).WorkshopID =>" @ GetGameModFromClass(Class).WorkshopID);
        
            SetTimer(0.01f, false, nameof(OpenConfigMenuViaLoadout), self, InHUD);
        }
    }

    if(AnnouncerManager != None) AnnouncerManager.OnPreOpenHUD(InHUD, InHUDElement);
}

function OnConfigChanged(Name ConfigName) 
{
    switch(ConfigName)
    {
        case 'OpenExpandedConfigMenu':
            OpenConfigMenuViaLoadout(GetALocalPlayerController().myHUD);
            break;
    }
}

function OnCollectibleSpawned(Object InCollectible)
{
    if(AnnouncerManager != None)
        AnnouncerManager.OnCollectibleSpawned(InCollectible);
};

function bool LoadChatSettings() { return Class'SS_CommunicationSettings'.static.LoadChatSettings(ChatSettings); }
function bool SaveChatSettings() { return Class'SS_CommunicationSettings'.static.SaveChatSettings(ChatSettings); }

// d should still be accurate, real time!!
function TickGhost(float d)
{
    nextCheckTime = WorldInfo.RealTimeSeconds;
    // streamer mode breaks emote, is this intentional?
    if(StreamerMode != Class'SS_1984'.static.ShouldHideName())
    {
        StreamerMode = Class'SS_1984'.static.ShouldHideName();
        UpdateGhostShowcaseName(true);
    }
    if(AnnouncerManager != None) AnnouncerManager.GhostTick(d);
    ValidateLocalInfo();
  
    nextCheckTime = WorldInfo.RealTimeSeconds;
}

function ManageMute(float realestDelta)
{
    local int i;

    // Local
    for(i = 0; i < LocalReader.Length; i++)
    {
        LocalReader[i].MuteTime = FMax(0.0f, LocalReader[i].MuteTime - realestDelta);
        LocalReader[i].PingCastMuteTime = FMax(0.0f, LocalReader[i].PingCastMuteTime - realestDelta);
        if(LocalReader[i].MuteTime <= FROSTBURN_CLIFFS_2.const.MUTE_TIME_MUTING_THRESHOLD && LocalReader[i].DesperationTime > 0)
        {
            LocalReader[i].DesperationTime = FMax(0.0f, LocalReader[i].DesperationTime - realestDelta);
            if(LocalReader[i].DesperationTime <= 0.0f)
            {
                LocalReader[i].Desperation = 0;
                if(Class'SS_CommunicationSettings'.default.PingSoundType == 96)
                    LocalReader[i].Player.PlaySound(SoundCue'SS_PingSystem_Content.Desperate.DesperationReset');
            }
        }
    }

    // Ghosts, can go out of sync lmao xd
    for(i = 0; i < GhostReader.Length; i++)
    {
        GhostReader[i].MuteTime = FMax(0.0f, GhostReader[i].MuteTime - realestDelta);
        GhostReader[i].PingCastMuteTime = FMax(0.0f, GhostReader[i].PingCastMuteTime - realestDelta);
        if(GhostReader[i].MuteTime <= FROSTBURN_CLIFFS_2.const.MUTE_TIME_MUTING_THRESHOLD && GhostReader[i].DesperationTime > 0)
        {
            GhostReader[i].DesperationTime = FMax(0.0f, GhostReader[i].DesperationTime - realestDelta);
            if(GhostReader[i].DesperationTime <= 0.0f)
            {
                GhostReader[i].Desperation = 0;
            }
        }
    }
}

function ManageTimedOutGhosts(float realestDelta)
{
    local int i;

    for(i = 0; i < GhostsTimeOut.Length; i++)
    {
        GhostsTimeOut[i].Duration -= realestDelta;
        if(GhostsTimeOut[i].Duration <= 0)
        {
            GhostsTimeOut.Remove(i, 1);
            i--;
        }
    }
}

// This manages the GhostReader array for all Ghosts in the currently connected lobby, both joining and leaving
// including those who move to different maps
// Note: The GhostReader will still have references even if you disconnect, to-do: cleanup on going offline via manual choice.
function UpdateGhosts()
{
    local EmoteChatInfo inst;
    local bool bGhostInList;
    local int i, u;
    local Array<Object> PlayerStateObjects;
    local Array<Hat_GhostPartyPlayerStateBase> PlayerStates;
    local Hat_GhostPartyPlayerStateBase ps;
    local Array<ConversationReplacement> keys;
    Hat_PlayerController(GetALocalPlayerController()).GetGhostPartyPlayerStates(PlayerStateObjects);

    for(i = 0; i < PlayerStateObjects.Length; i++)
    {
        ps = Hat_GhostPartyPlayerStateBase(PlayerStateObjects[i]);
        if (ps.IsPublic) continue; // "IsPublic" = nameless lobbies, we don't do those! (for privacy reasons)
        if (ps.IsDestroyed) continue;
        if (ps.IsLocalPlayer()) continue; // Locals are handled elsewhere
        if (ps.IsConnectionFailed()) continue; // join/leave spam lmao
        if(Class'SS_Ping_Helpers'.static.IsPlayerStateTimedOut(GhostsTimeOut, ps)) continue;
        PlayerStates.AddItem(Hat_GhostPartyPlayerStateBase(PlayerStateObjects[i]));
    }

    foreach PlayerStates(ps)
    {
        bGhostInList = false;
        for(i = 0; i < GhostReader.Length; i++)
        {
            if(GhostReader[i].PlayerState == None) continue; // bad listing
            if(GhostReader[i].PlayerState != ps) continue;
            bGhostInList = true;
            break;
        }
        if(bGhostInList) continue;
        inst.PlayerState = ps;
        inst.SteamID = ps.GetNetworkingIDString();
        inst.SteamName = ps.GetDisplayName();
        // In case of coop (0 = player 1 | 1 = player 2 (thanks undrew))
        inst.SubID = ps.SubID;
        inst.StartingConnectionTime = WorldInfo.RealTimeSeconds;

        Print("New connection established with \"" $ inst.SteamName $ "\" (" $ inst.SteamID $ ")" @ (inst.SubID == 0 ? "" : "(Partner)"));

        if(!ps.IsConnectionFailed() && Class'SS_CommunicationSettings'.default.EnableJoin)
        {
            Class'SS_ChatFormatter'.static.AddkeywordReplacement(keys, "joiner", Class'SS_Ping_Helpers'.static.GetGhostName(inst,,StreamerMode));
            OnRecievedChatLogCommand("JOINED_GAME", "templates", "onlinechat", keys);
        }
        GhostReader.AddItem(inst);
    }
    
    for(i = 0; i < GhostReader.Length; i++)
    {
        bGhostInList = false;
        if(GhostReader[i].PlayerState == None) continue; // ?
        
        for(u = 0; u < PlayerStates.Length; u++)
        {
            if(GhostReader[i].PlayerState == None) break; // bad lmao
            if(GhostReader[i].PlayerState != PlayerStates[u]) continue;
            bGhostInList = true;
            break;
        }
        if(bGhostInList) continue;
        
        
        Class'SS_ChatFormatter'.static.AddkeywordReplacement(keys, "leaver", Class'SS_Ping_Helpers'.static.GetGhostName(GhostReader[i],,StreamerMode));
        if(Class'SS_CommunicationSettings'.default.EnableConnectionFailed && Class'SS_Ping_Helpers'.static.IsConnectionFailed(GhostReader[i]))
        {
            Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "time_out_duration", Class'SS_Ping_Helpers'.static.GetFailedConnectionTimeOutDuration());
            OnRecievedChatLogCommand("GHOST_CONNECTION_FAILED", "templates", "onlinechat", keys);
            TimeOutFailedConnection(GhostReader[i].PlayerState);
        }
        else if(Class'SS_CommunicationSettings'.default.EnableLeave)
            OnRecievedChatLogCommand("LEFT_GAME", "templates", "onlinechat", keys);
        
        if(Class'SS_Ping_Helpers'.static.IsConnectionFailed(GhostReader[i]))
            Print("\"" $ GhostReader[i].PlayerState.GetDisplayName() $ "\" (" $ GhostReader[i].PlayerState.GetNetworkingIDString() $ ") failed to connect or has poor connection, will be timed out for " @ Class'SS_Ping_Helpers'.static.GetFailedConnectionTimeOutDuration() @ "seconds.");
        else
            Print("\"" $ GhostReader[i].PlayerState.GetDisplayName() $ "\" (" $ GhostReader[i].PlayerState.GetNetworkingIDString() $ ") left the lobby.");

        if(GhostReader[i].PingSpot != None)
            GhostReader[i].PingSpot.Destroy();
        GhostReader.Remove(i, 1);
        i--;
    }

    nextUpdateTime = WorldInfo.RealTimeSeconds;
}

function UpdateGhostShowcaseName(optional bool force = false)
{
    local int i;
    local string map, ghostName;
    local Hat_GhostPartyPlayer ghost;
    if(!force && !StreamerMode) return;

    map = `GameManager.GetCurrentMapFilename();

    for(i = 0; i < GhostReader.Length; i++)
    {
        if(!(GhostReader[i].PlayerState.CurrentMapName ~= map)) continue;
        if(GhostReader[i].PlayerState.GhostActor == None) continue;
        ghost = Hat_GhostPartyPlayer(GhostReader[i].PlayerState.GhostActor);
        ghostName = Class'SS_Ping_Helpers'.static.GetGhostName(GhostReader[i],,StreamerMode);
        // Print("Renaming with" @ ghostName);
        if(Name(ghost.TextRenderComponent.Text) != Name(ghostName))
            ghost.TextRenderComponent.Text = ghostName;
        
        ghost.TextRenderComponent.SetHidden(false);
    }
}

function ValidateLocalInfo()
{
    local int i;
    for(i = 0; i < LocalReader.Length; i++)
    {
        if(LocalReader[i].player != None) continue;
        LocalReader.Remove(i, 1);
        i--;
    }
}

function AddLocalPlayer(Hat_Player player)
{
    local Interaction inting, oldInter;
    local EmoteChatInfo_LocalPlayers dummy;
    local Hat_PlayerController pc;
    local int i;

    pc = Hat_PlayerController(player.Controller);
    if(pc == class'Hat_PlayerController'.static.GetPlayer2())
        dummy.SubID = 1;
    else if(pc == class'Hat_PlayerController'.static.GetPlayer1())
        dummy.SubID = 0;
    else
    {
        Print("WARNING! THIS IS NOT A PLAYER 0/1! WHAT IS THIS??? ABORTING!");
        return;
    }

    Class'OnlineCommunication'.static.RegisterInputEvent(player, inting, ReceivedNativeInputKey);
    if(inting == None)
    {
        Print("Couldn't register a key event listener, inting to player" @ player $ ", inting returned" @ inting);
        return;
    }

    // Local
    dummy.KeyCaptureInteraction = inting; 
    dummy.player = player;
    dummy.pc = pc;
    dummy.PingHUD = OpenPingHUD(player.Controller);
    
    // General
    dummy.PlayerState = Class'Hat_GhostPartyPlayerStateBase'.static.GetLocalPlayerState(dummy.subID); // Thankfully not used, much.
    dummy.SteamID = Class'OnlineCommunication'.static.GetLocalSteamID();
    dummy.SteamName = Class'OnlineCommunication'.static.GetLocalSteamName();

    // Clean up for player swapper mods!!!
    for(i = 0; i < LocalReader.Length; i++)
    {
        if(LocalReader[i].SubID != dummy.SubID) continue;
        Print("Possible Input Detected, Removing Input Event for Index Player ["$dummy.SubID$"]");
        oldInter = LocalReader[i].KeyCaptureInteraction;
        Class'OnlineCommunication'.static.UnRegisterInputEvent(dummy.player, oldInter);
        LocalReader[i].KeyCaptureInteraction = None;
        LocalReader.Remove(i, 1);
        i--;
    }

    LocalReader.AddItem(dummy); // his name is chaos and he has 100k HP
}

function bool GetOtherActor(Actor target, optional out Hat_GhostPartyPlayerStateBase psResult)
{
    local Actor a;
    local Vector hitloc, hitnorm, start, end;
    local EmoteChatInfo gr;
    local EmoteChatInfo_LocalPlayers lr;
    local color p;
    start = target.Location + vect(0,0,30);
    end = start + Normal(Vector(target.Rotation)) * 500;

    target.FlushPersistentDebugLines();
    if(Class'SS_CommunicationSettings'.default.ToggleDebugging)
    {
        p = Class'SS_Color'.static.GetColorByName("Hot_Pink");
        Class'SS_Ping_Identifier'.static.Debug_DrawLines(0.1f, 0.5f, start, end, p);
        Class'SS_Ping_Identifier'.static.Debug_DrawBox(0.1f, 0.5f, (end - start)/2 + start, vect(50, 50, 200), p);
        Class'SS_Ping_Identifier'.static.Debug_DrawBox(0.1f, 0.5f, VLerp(start, end, 0.25), vect(50, 50, 200), p);
        Class'SS_Ping_Identifier'.static.Debug_DrawBox(0.1f, 0.5f, VLerp(start, end, 0.75), vect(50, 50, 200), p);
        Class'SS_Ping_Identifier'.static.Debug_DrawBox(0.1f, 0.5f, start + Normal(end - start) * 50, vect(50, 50, 200), p);
        Class'SS_Ping_Identifier'.static.Debug_DrawBox(0.1f, 0.5f, end - Normal(end - start) * 50, vect(50, 50, 200), p);
    }
    
    foreach target.TraceActors(Class'Actor', a, hitloc, hitnorm, end, start, vect(50, 50, 200))
    {
        if(!a.IsA('Hat_GhostPartyPlayerBase') && !a.IsA('Hat_Player')) continue;

        if(a.IsA('Hat_Player'))
        {
            foreach LocalReader(lr)
            {
                if(lr.Player != Hat_Player(a)) continue;
                psResult = lr.PlayerState == None ? Class'Hat_GhostPartyPlayerStateBase'.static.GetLocalPlayerState(lr.Player.GetPlayerIndex()) : lr.PlayerState;
                return true;
            }
        }
        else
        {
            foreach GhostReader(gr)
            {
                if(gr.PlayerState != Hat_GhostPartyPlayerBase(a).PlayerState) continue;
                psResult = gr.PlayerState;
                return true;
            }
        }
    }
    return false;
}

function PrepareOnlinePartyCommand(string command, optional Pawn sendingPlayer = None)
{
    if(Class'SS_CommunicationSettings'.default.ChannelType == 2 && Len(Class'SS_CommunicationSettings'.default.PrivateChannelName) > 0) 
    {
        command $= "&PrivateChannelName=" $ Class'SS_CommunicationSettings'.default.PrivateChannelName;
    }

    switch(Class'SS_CommunicationSettings'.default.ChannelType)
    {
        case 2:
            if(Len(Class'SS_CommunicationSettings'.default.PrivateChannelName) > 0)
                command $= "&PrivateChannelName=" $ Class'SS_CommunicationSettings'.default.PrivateChannelName;
            break;
        case 1:
            command $= "&FriendsOnly=True";
            break;
    }

    if(Class'Engine'.static.IsEditor())
        OnOnlinePartyCommand(command, FROSTBURN_CLIFFS_2.const.COMMMAND_CHANNEL_NAME, None);
    else
        SendOnlinePartyCommand(command, FROSTBURN_CLIFFS_2.const.COMMMAND_CHANNEL_NAME, sendingPlayer);
}

function OpenConfigMenuViaLoadout(HUD InHUD)
{
    local Hat_HUD h;
    local SS_HUDMenu_PingSystemConfig configMenu;
    h = Hat_HUD(InHUD);

    if(OnlineChatHUD != None && OnlineChatHUD.bCustomConfigMenu)
    {
        OnlineChatHUD.bCustomConfigMenu = false;
        OnlineChatHUD.bChatExpanded = true;
        h.CloseHUD(Class'SS_HUDMenu_PingSystemConfig');
        OnlineChatHUD.ExpandChat(h);
    }

    configMenu = SS_HUDMenu_PingSystemConfig(h.OpenHUD(Class'SS_HUDMenu_PingSystemConfig'));
    configMenu.OnOpenHUDFromConfigLoadout(h);
}

function DoCommand(string Command, Hat_GhostPartyPlayerStateBase Sender, string parameters)
{
    local Array<Dictionary> mapDict;
    local string localization, section, map, target, channel;
    local Vector loc;
    local Rotator r;
    local Array<ConversationReplacement> keys;
    local float range;
    local Actor a, targetActor;
    local string targetName, targetID;
    // local Class<Hat_SnatcherContract_DeathWish> dwC;

    if(InStr(parameters, "=") == INDEX_NONE) return;
    
    mapDict = Class'DictionaryTools'.static.BuildDictionaryArray(parameters);

    switch(Class'SS_CommunicationSettings'.default.ChannelType)
    {
        // Friends Only
        case 1:
            if(!Sender.IsOnlineFriend) return;
            break;
        
        // Private Channel
        case 2:
            if(!class'DictionaryTools'.static.GetValue(channel, mapDict, "PrivateChannelName")) return;
            if(!(channel ~= Class'SS_CommunicationSettings'.default.PrivateChannelName)) return;
            break;

        // All chat
        default:
            // recieved a message with a defined channel but the reciever is all chat, therefore not allowed!
            if(class'DictionaryTools'.static.GetValue(channel, mapDict, "PrivateChannelName") && Len(channel) > 0) return;
            // received a message from someone who only want their friends to know about it 
            if(class'DictionaryTools'.static.GetValueBool(mapDict, "FriendsOnly") && !Sender.IsOnlineFriend) return;
            break;
    }

    if(Class'SS_CommunicationSettings'.default.ToggleDebugging)
    {
        Print("Recieved Command for \"" $ command $"\" |" @ parameters);
        Print("from" @ Sender.GetDisplayName() @ "(Steam ID:" @ Sender.GetNetworkingIDString() $ ")");
    }

    if(!Class'DictionaryTools'.static.GetValue(localization, mapDict, "localization"))
    {
        if(Class'SS_CommunicationSettings'.default.ToggleDebugging) 
            Print("NO LOCALIZATION KEY PASSED!!! Remember to pass \"localization=yourlocalizationkey\"! Params:" @ parameters);
        return;
    }

    map = `GameManager.GetCurrentMapFilename();

    switch(Command)
    {
        case "ping":
            if(!Class'SS_CommunicationSettings'.default.TogglePingSystem) return;
            if(!Class'Engine'.static.IsEditor() && !(Sender.CurrentMapName ~= map)) return;
            if(map ~= "1VCMansion") return;

            if(!Class'DictionaryTools'.static.GetValue(target, mapDict, "target")) target = "";
            if(!Class'DictionaryTools'.static.GetValue(section, mapDict, "section")) section = "default";

            if(target != "")
            {
                targetName = Repl(target, "_" $ GetRightMost(target), "", false);
                targetID = GetRightMost(target);
                foreach AllActors(Class'Actor', a)
                {
                    if(!a.IsA(Name(targetName))) continue;
                    if(String(a.Name) ~= (targetName $ "_" $ targetID))
                    {
                        targetActor = a;
                        break;
                    }
                }
            }

            // Mainly for spaceship because its the most volatile mod installation discrepancy location.
            // Unless a ghost player
            if(!(targetName ~= "Hat_GhostPartyPlayer") && !(targetName ~= "Arg_GhostPartyPlayer") && targetActor == None && Class'SS_Ping_Identifier'.static.PingHasOption("StrictMapContext", map)) return;

            if(targetActor != None)
            {
                if(Class'DictionaryTools'.static.GetValueFloat(range, mapDict, "offsetRange"))
                {
                    Class'DictionaryTools'.static.GetValueRotator(r, mapDict, "dirP", "dirY", "dirR");
                    loc = targetActor.Location + Normal(Vector(targetActor.Rotation + r)) * range;
                }
                else 
                    loc = targetActor.Location; 
            }
            else
                Class'DictionaryTools'.static.GetValueVector(loc, mapDict, "x", "y", "z");
            
            keys = Class'DictionaryTools'.static.BuildKeyReplacements(mapDict, "localization,section,x,y,z,offsetRange,dirP,dirY,dirR");
            SpawnGhostPing(loc, localization, section, targetActor, Sender, keys);
            break;
        
        case "announce":
            if(!(Sender.CurrentMapName ~= map)) return;
            AnnouncerManager.OnAnnouncementRecieved();
            break;

        case "deathwish":
            if(!Class'SS_CommunicationSettings'.default.EnableDeathWish) return;

            Class'DictionaryTools'.static.GetValue(section, mapDict, "section");
            switch(section)
            {
                case "contracts":
                case "contracts_summer":
                    break;
                default:
                    section = "contracts";
                    break;
            }

            // No map limit, but if people want it? sure.
            if(Class'DictionaryTools'.static.GetValueBool(mapDict, "isMapSpecific") && !(Sender.CurrentMapName ~= map)) return;
            keys = Class'DictionaryTools'.static.BuildKeyReplacements(mapDict, "localization,section,isMapSpecific");
            Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "owner", Sender.GetNetworkingIDString()$"_"$Sender.SubID);
            OnRecievedChatLogCommand(localization, section, "announcements", keys);
            break;

        default:
            Print("NO COMMAND???");
            break;
    }
}

// Try pinging a point
function bool TryPing(Hat_PlayerController pc)
{
    local bool pingSpawned;
    local EmoteChatInfo_LocalPlayers lr;
    local PingLocalizedResult result;
    local SS_PingSupport volume;
    local Vector l;
    local Rotator offset;
    local float range;
    local string command;
    
    PingFromEmote = false;
    if(!Class'SS_Ping_Identifier'.static.TryPing(pc, result, Class'SS_Ping_Helpers'.static.GetPotentialPingSections())) return false;
    
    Print("We pinged actor called:" @ result.actor);
    if(result.actor.IsA('SS_PingSupport'))
    {
        volume = SS_PingSupport(result.actor);
        if(volume.IsValid())
        {
            result.PingLocation = volume.PingReference.Location;
            result.actor = volume.PingReference;
        }
    }
    pingSpawned = SpawnPing(result, pc);
    
    if(pingSpawned)
    {
        if(OnlineChatHUD != None)
        {
            foreach LocalReader(lr)
            {
                if(lr.player != Hat_Player(pc.Pawn)) continue;
                Class'SS_ChatFormatter'.static.AddKeywordReplacement(result.keys, "owner", lr.SteamID $ "_" $ lr.SubID);
                break;
            }
            OnRecievedChatLogCommand(result.Localization, result.section, "pings", result.keys);
        }
        l = result.PingLocation;
        
        command = "ping?";
        command $= "x="$l.X$"&y="$l.Y$"&z="$l.Z;
        command $= "&localization="$result.Localization;
        command $= "&section="$result.section;
        command $= "&target="$result.actor;
        if(l != result.Actor.Location)
        {
            offset = Rotator(Normal(l - result.Actor.Location)) - result.Actor.Rotation;
            range = VSize2D(l - result.Actor.Location);
            command $= "&dirP="$offset.Pitch;
            command $= "&dirY="$offset.Yaw;
            command $= "&dirR="$offset.Roll;
            command $= "&offsetRange="$range;
        }
        command $= "&"$Class'DictionaryTools'.static.KeysToDictionaryCommand(result.keys);
        Print("Sending Command:" @ command);
        PrepareOnlinePartyCommand(command, pc.Pawn);
    }
    return pingSpawned;
}

function bool ShouldSilentlyPing(Vector pingLocation)
{
    local float range, maxRange;

    if(!Class'SS_CommunicationSettings'.default.DontSendIfOutOfRange) return false;
    
    maxRange = Class'SS_CommunicationSettings'.default.PingNotificationRange;
    maxRange += Class'SS_CommunicationSettings'.default.PingNotificationDecayingRange;

    Class'OnlineCommunication'.static.GetPlayerNearest(pingLocation, range);

    return range/100.0f > maxRange;
}

function bool SpawnPing(PingLocalizedResult pingInfo, optional PlayerController LocalPlayer = None)
{
    local EmoteChatInfo_LocalPlayers lp;
    local string soundPath;
    local SoundCue customSound;

    if(LocalIsMuted(LocalPlayer, true)) return false;
    
    if(DoLocalPing(pingInfo.PingLocation, LocalPlayer, pingInfo.Actor, lp))
    {
        if(Class'SS_Ping_Identifier'.static.PingHasCustomSound(pingInfo.section, pingInfo.localization, lp.Desperation, soundPath))
            customSound = SoundCue(DynamicLoadObject(soundPath, Class'SoundCue', true));
        
        Class'SS_Ping_Helpers'.static.TriggerPingSound(pingInfo.PingLocation, LocalPlayer.Pawn, lp.Desperation, customSound);
    }
    return true;
}

// The recieved ping from a ghost
function SpawnGhostPing(Vector loc, optional string localization = "", optional string section = "default", optional Actor target = None, optional Hat_GhostPartyPlayerStateBase sender = None, optional Array<ConversationReplacement> keys)
{
    local EmoteChatInfo grRes;
    local string soundPath;
    local SoundCue customSound;

    if(!Class'Engine'.static.IsEditor() && IsMuted(Sender)) return;

    if(!DoGhostPing(loc, localization, sender, target, grRes)) return;

    if(Class'SS_Ping_Identifier'.static.PingHasCustomSound(section, localization, grRes.Desperation, soundPath))
        customSound = SoundCue(DynamicLoadObject(soundPath, Class'SoundCue', true));
    Class'SS_Ping_Helpers'.static.TriggerPingSound(loc, Sender.GhostActor, grRes.Desperation, customSound);
    
    if(OnlineChatHUD == None) return;
    Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "owner", sender.GetNetworkingIDString() $ "_" $ sender.SubID);
    OnRecievedChatLogCommand(localization, section, "pings", keys);
}

function bool DoLocalPing(Vector loc, PlayerController pc, optional Actor a, optional out EmoteChatInfo_LocalPlayers localReaderRes)
{
    local SS_PingSpot spot;
    local int i;
    
    if(pc == None) return false;

    for(i = 0; i < LocalReader.Length; i++)
    {
        if(LocalReader[i].player != Hat_Player(pc.Pawn)) continue;
        
        if(!ShouldSilentlyPing(loc))
        {
            spot = `GameManager.Spawn(class'SS_PingSpot',,, loc);
            spot.SetPing(LocalReader[i], a);
            
            if(LocalReader[i].PingSpot != None)
                LocalReader[i].PingSpot.Destroy();

            LocalReader[i].PingSpot = spot;
        }

        LocalReader[i].MuteTime += FROSTBURN_CLIFFS_2.const.MUTE_TIME_PER_PING + FROSTBURN_CLIFFS_2.const.DESPERATION_MUTE * LocalReader[i].Desperation;
        LocalReader[i].PingCastMuteTime = (FROSTBURN_CLIFFS_2.const.DELAY_PER_PING);
        LocalReader[i].Desperation = Min(LocalReader[i].Desperation + 1, FROSTBURN_CLIFFS_2.const.DESPERATION_MAX_STACKS);
        LocalReader[i].DesperationTime = FROSTBURN_CLIFFS_2.const.DESPERATION_DURATION;

        localReaderRes = LocalReader[i];

        return true;
    }

    return false;
}

// Instate if not yet, reinstate if already been done
function bool DoGhostPing(Vector loc, string className, Hat_GhostPartyPlayerStateBase sender, optional Actor targetActor = None, optional out EmoteChatInfo grRes)
{   
    local SS_PingSpot spot;
    local int i;

    if(Sender == None) return false;

    for(i = 0; i < GhostReader.Length; i++)
    {
        if(!(GhostReader[i].steamID ~= sender.GetNetworkingIDString())) continue;
        if(GhostReader[i].SubID != sender.SubID) continue;

        if(!ShouldSilentlyPing(loc))
        {
            spot = `GameManager.Spawn(class'SS_PingSpot',,, loc);
            spot.SetPingGhost(GhostReader[i], targetActor);

            if(GhostReader[i].PingSpot != None)
                GhostReader[i].PingSpot.Destroy();

            GhostReader[i].PingSpot = spot;
        }
        GhostReader[i].MuteTime += FROSTBURN_CLIFFS_2.const.MUTE_TIME_PER_PING + FROSTBURN_CLIFFS_2.const.DESPERATION_MUTE * LocalReader[i].Desperation;
        GhostReader[i].PingCastMuteTime = (FROSTBURN_CLIFFS_2.const.DELAY_PER_PING);
        GhostReader[i].Desperation = Min(GhostReader[i].Desperation + 1, FROSTBURN_CLIFFS_2.const.DESPERATION_MAX_STACKS);
        GhostReader[i].DesperationTime = FROSTBURN_CLIFFS_2.const.DESPERATION_DURATION;

        grRes = GhostReader[i];
        return true;
    }

    return false;
}

function float GetRealTick(float d)
{
    return (d/(WorldInfo.TimeDilation * CustomTimeDilation));
}

function int GetLocalReaderIndex(Hat_Player player)
{
    local int i;
    for(i = 0; i < LocalReader.Length; i++)
    {
        if(LocalReader[i].player != player) continue;
        return i;
    }
    return INDEX_NONE;
}

function bool LocalIsMuted(PlayerController pc, optional bool silent = false) 
{ 
    local Hat_Player plyr;
    local EmoteChatInfo_LocalPlayers lr;
    if(pc == None) return false;
    plyr = Hat_Player(pc.Pawn);
    if(plyr == None) return false;

    foreach LocalReader(lr)
    {
        if(lr.player != plyr) continue;
        if(lr.PingCastMuteTime <= 0 && lr.MuteTime <= FROSTBURN_CLIFFS_2.const.MUTE_TIME_MUTING_THRESHOLD) return false;
        if(lr.PingCastMuteTime <= 0 && !silent)
        {
            pc.Pawn.PlaySound(SoundCue'HatinTime_SFX_UI2.SoundCues.DeathWishFail');
            if(OnlineChatHUD != None)
                OnRecievedChatLogCommand("PLAYER_PING_LIMITED", "default", "pings");
        }
        return true;
    }
    return false; 
}

function bool IsMuted(Hat_GhostPartyPlayerStateBase Sender)
{
    local EmoteChatInfo pg16lmao;
    local string SteamID;

    if(Sender == None) return false;
    SteamID = Sender.GetNetworkingIDString();
    if(SteamID ~= "") return false;

    foreach GhostReader(pg16lmao)
    {
        if(!(pg16lmao.steamID ~= steamID)) continue;
        if(pg16lmao.SubID != Sender.SubID) continue;
        if(pg16lmao.PingCastMuteTime <= 0 || pg16lmao.MuteTime <= (FROSTBURN_CLIFFS_2.const.MUTE_TIME_MUTING_THRESHOLD)) return false;
        return true;
    }
    return false;
}

function TimeOutFailedConnection(Hat_GhostPartyPlayerStateBase playerState)
{
    local GhostTimeOut ghost;
    ghost.SteamID = playerState.GetNetworkingIDString();
    ghost.Duration = Class'SS_Ping_Helpers'.static.GetFailedConnectionTimeOutDuration();
    GhostsTimeOut.AddItem(ghost);
}

function PingFromEmoteRequest(Hat_PlayerController pc)
{
    SetTimer(0.01f, false, NameOf(DoPingFromEmote), self, pc);
}

function DoPingFromEmote(Hat_PlayerController pc)
{
    PingFromEmote = true;
    OnPingCast(pc, true);
}

function OpenOnlineChat(optional Controller c = None)
{
    if(!class'SS_CommunicationSettings'.default.ToggleOnlineChat) return;
    if(c == None) c = GetALocalPlayerController();
    OnlineChatHUD = SS_HUDElement_OnlinePartyChat(Hat_HUD(Hat_PlayerController(c).myHUD).OpenHUD(class'SS_HUDElement_OnlinePartyChat'));
    OnlineChatHUD.GameMod = self;
}

// For actors that are impossible to ping, add an invisible volume to be their ping radius.
function AttachPingSupport(Actor o)
{
    local SS_PingSupport pingSupport;

    pingSupport = Spawn(Class'SS_PingSupport',,,o.Location);
    pingSupport.AttachPingToActor(o);
}

function SS_HUDElement_Ping OpenPingHUD(optional Controller c = None)
{
    if(c == None) c = GetALocalPlayerController();
    return SS_HUDElement_Ping(Hat_HUD(Hat_PlayerController(c).myHUD).OpenHUD(class'SS_HUDElement_Ping'));
}

function bool OnRecievedChatLogCommand(string command, optional string section = "templates", optional string fileName = "onlinechat", optional Array<ConversationReplacement> keys)
{
    return OnlineChatHUD != None && OnlineChatHUD.OnRecievedChatLogCommand(command, section, keys, fileName);
}

function bool ReceivedNativeInputKey(int ControllerId, name Key, EInputEvent EventType, float AmountDepressed, bool bGamepad)
{
    local Hat_Player plyr;
    local Hat_PlayerController pc;
    local SS_HUDElement_Ping pingHUD;
    //local SS_HUDMenu_PingSystemConfig configHUD;
    
    if(EventType != IE_Pressed && EventType != IE_Released) return false;

    plyr = class'OnlineCommunication'.static.GetPlayer(class'UIInteraction'.static.GetPlayerIndex(ControllerId));
    pc = Hat_PlayerController(plyr.Controller);
    pingHUD = LocalReader[GetLocalReaderIndex(Hat_Player(pc.Pawn))].PingHUD;

    if(Class'OnlineCommunication'.static.IsGamePaused() || Key == 'Hat_Menu_Start' || Class'OnlineCommunication'.static.IsGamePaused() && Key == 'Hat_Menu_Cancel')
    {
        if(Key == 'Hat_Menu_Start' && pingHUD != None && pingHUD.bPingPreview)
        {
            pingHUD.bPingPreview = false;
            PingFromEmote = false;
            return true;
        }

        if(Key == 'Hat_Menu_Cancel' && EventType == IE_Pressed && Hat_HUD(pc.myHUD).GetHUD(Class'SS_HUDMenu_PingSystemConfig') != None) 
        {
            if(ActiveInputContentPanel != None)
            {
                ActiveInputContentPanel.DisableInputting(pc.myHUD);
                ActiveInputContentPanel = None;
                return true;
            }
            Hat_HUD(pc.myHUD).CloseHUD(Class'SS_HUDMenu_PingSystemConfig');
            return true;
        }
        return false;
    }

    if(EventType == IE_Pressed)
    {
        switch(Key)
        {
            case Class'SS_CommunicationSettings'.default.ExpandChatHotkey:
                if(OnlineChatHUD != None && !OnlineChatHUD.bCustomConfigMenu && !Hat_HUD(pc.myHUD).IsHUDClassEnabled(Class'SS_HUDMenu_PingSystemConfig'))
                    OnlineChatHUD.ExpandChat(pc.MyHUD);
                break;
            case 'Hat_Menu_Cancel':

                if(ActiveInputContentPanel != None)
                {
                    ActiveInputContentPanel.DisableInputting(pc.myHUD);
                    ActiveInputContentPanel = None;
                    return true;
                }
                Hat_HUD(pc.myHUD).CloseHUD(Class'SS_HUDMenu_PingSystemConfig');
                if(OnlineChatHUD != None && OnlineChatHUD.bCustomConfigMenu)
                {
                    OnlineChatHUD.bCustomConfigMenu = false;
                    OnlineChatHUD.bChatExpanded = true;
                    Hat_HUD(pc.myHUD).CloseHUD(Class'SS_HUDMenu_PingSystemConfig');
                    return true;
                }
                break;
            case 'Slash':
                // Class'SS_OCScript'.static.Test();
                break;
        }
    }
    
    if(ActiveInputContentPanel != None) return false;
    if(!Class'SS_CommunicationSettings'.default.TogglePingSystem || !Class'SS_CommunicationSettings'.default.TogglePingButton) return false;
    if(Class'SS_Ping_Helpers'.static.PingingForbidden(plyr)) return false;
    if((PingFromEmote || pingHUD != None && pingHUD.bPingPreview) && Key == 'Hat_Player_Attack' && EventType == IE_Pressed) return OnPingCast(pc, true);
    else if(!bGamepad && Key == Class'SS_CommunicationSettings'.default.PingHotKey) return OnPingCast(pc, EventType == IE_Released);
    
    return false;
}

function bool OnPingCast(Hat_PlayerController pc, bool released)
{
    local int pingType, playerIndex;
    local SS_HUDElement_Ping pingHUD;

    if(AnnouncerManager != None && !AnnouncerManager.OnPing(pc, released)) return false;

    playerIndex = GetLocalReaderIndex(Hat_Player(pc.Pawn));

    if(PlayerIndex == INDEX_NONE) return false;
    if(LocalIsMuted(pc, !pc.IsGamePad() && released)) return false;
    
    if(pc.IsGamepad() || PingFromEmote)
        pingType = 0;
    else
        pingType = Class'SS_Ping_Helpers'.static.GetPingCastingType();

    pingHUD = LocalReader[playerIndex].PingHUD;

    switch(pingType)
    {
        // Confirm
        case 0:
            if(!released) return false;
            pingHUD.bPingPreview = !pingHUD.bPingPreview;
            return !pingHUD.bPingPreview && TryPing(pc);
        // On Release
        case 1:
            if(!pingHUD.bPingPreview && released) return false;
            if(!pingHUD.bPingPreview && !released) pingHUD.bPingPreview = true;
            else if(pingHUD.bPingPreview && released) pingHUD.bPingPreview = false;
            return !pingHUD.bPingPreview && TryPing(pc);
        // Quick Cast
        case 2:
            pingHUD.bPingPreview = false;
            return !released && TryPing(pc);
        default:
            return false;
    }
}

static function Print(coerce string msg) 
{
    if(!Class'SS_CommunicationSettings'.default.ToggleDebugging) return; 
    class'OnlineCommunication'.static.Print("[" $ default.Class $ "] =>" @ msg); 
}

defaultproperties
{
    bAlwaysTick = true;
        
    ReferenceSounds.Add(SoundCue'SSExamplePath.ExampleSound');
    ReferenceSounds.Add(SoundCue'SS_PingSystem_Content.yippe_cue');
    ReferenceSounds.Add(SoundCue'SS_PingSystem_Content.gambling_cue');
    ReferenceSounds.Add(SoundCue'SS_PingSystem_Content.ah_dang_it_cue');
}