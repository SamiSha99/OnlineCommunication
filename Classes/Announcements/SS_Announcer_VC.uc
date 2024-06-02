// Extremely unreliable with a lot of guessing, do not count on it!
// 20 = crown
// 50 = tagged
Class SS_Announcer_VC extends SS_Announcer;

var int PromptCount;

struct VanessaScores
{
    var Hat_GhostPartyPlayerStateBase PlayerState;
    var int CurrentScore;
};


var Array<VanessaScores> ScoreRefs;

struct LastVanessaAction
{
    var string PlayerWhoDidAction; // SteamID_SubID
    var float TimeOfAction;
};

var LastVanessaAction LastPlayerCrown, LastPlayerCurse, LastPlayerAny;

var Array<string> TeamWinHUDs;

const LOCALIZATION_SECTION = "VanessasCurse";
const VANESSA_CURSE_MAP = "1VCMansion";

function Init()
{
    UpdateScoreList();
}

function OnPreOpenHUD(HUD InHUD, out class<Object> InHUDElement)
{
    local Array<ConversationReplacement> keys;
    local WorldInfo wi;
    
    if(!Class'SS_CommunicationSettings'.default.EnableVanessaCurse) return;
    if(TeamWinHUDs.Find(Caps(InHUDElement)) == INDEX_NONE) return;

    wi = GetWorldInfo();
    switch(Caps(InHUDElement))
    {
        case "TAG_HUDELEMENT_SWIN":
            // delayed hard by latency ehhh
            if(LastPlayerCrown.TimeOfAction + 10.0f > wi.TimeSeconds)
            {
                Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "owner", LastPlayerCrown.PlayerWhoDidAction);
                GameMod.OnRecievedChatLogCommand("SnatcherWin_" $ Rand(3), LOCALIZATION_SECTION, LOCALIZATION_FILE, keys);
            }
            else
            {
                GameMod.OnRecievedChatLogCommand("SnatcherTimeUpWin_" $ Rand(2), LOCALIZATION_SECTION, LOCALIZATION_FILE, keys);
            }
            break;
        case "TAG_HUDELEMENT_VWIN":
            
            if(LastPlayerCurse.TimeOfAction + 6.0f > wi.TimeSeconds)
            {
                Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "owner", LastPlayerCurse.PlayerWhoDidAction);
                GameMod.OnRecievedChatLogCommand("VanessaWin_" $ Rand(3), LOCALIZATION_SECTION, LOCALIZATION_FILE, keys);
            }
            // perhaps crown collector just kinda gave up? died? disconnected? unsure
            else
            {
                Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "owner", LastPlayerCrown.PlayerWhoDidAction);
                GameMod.OnRecievedChatLogCommand("VanessaClumsyWin_" $ Rand(2), LOCALIZATION_SECTION, LOCALIZATION_FILE, keys);
            }
            break;
    }
}

function GhostTick(float d) {ScoreChangeWatchDog();}


function UpdateScoreList()
{
    local int i;
    
    for(i = 0; i < GameMod.GhostReader.Length; i++)
    {
        if(!(GameMod.GhostReader[i].PlayerState.CurrentMapName ~= VANESSA_CURSE_MAP)) continue;
        if(ScoreRefs.Find('PlayerState', GameMod.GhostReader[i].PlayerState) != INDEX_NONE) continue;
        AddScoreRef(GameMod.GhostReader[i].PlayerState);
    }

    for(i = 0; i < GameMod.LocalReader.Length; i++)
    {
        if(ScoreRefs.Find('PlayerState', GameMod.LocalReader[i].PlayerState) != INDEX_NONE) continue;
        AddScoreRef(GameMod.LocalReader[i].PlayerState);
    }
}

function AddScoreRef(Hat_GhostPartyPlayerStateBase ps)
{
    local VanessaScores vs;
    vs.PlayerState = ps;
    vs.CurrentScore = ps.CurrentScore;
    scoreRefs.AddItem(vs);
}

function ScoreChangeWatchDog()
{
    local int i;
    local WorldInfo wi;
    local Hat_GhostPartyPlayerState you;
    you = Hat_GhostPartyPlayerState(class'Hat_GhostPartyPlayerState'.static.GetLocalPlayerState(0));
    
    Print("VC_GameState =>" @ you.GetPlayerStateMeta(Name('VC_GameState' $ "_" $ "VanessaCurse")));
    Print("VC_NumPlayersInGame =>" @ you.GetPlayerStateMeta(Name('VC_NumPlayersInGame' $ "_" $ "VanessaCurse")));
    Print("VC_CursedPlayersInGame =>" @ you.GetPlayerStateMeta(Name('VC_CursedPlayersInGame' $ "_" $ "VanessaCurse")));
    Print("VC_PlayerId =>" @ you.GetPlayerStateMeta(Name('VC_PlayerId' $ "_" $ "VanessaCurse")));

    UpdateScoreList();
    
    for(i = 0; i < scoreRefs.Length; i++)
    {
        if(scoreRefs[i].PlayerState == None || !(scoreRefs[i].PlayerState.CurrentMapName ~= VANESSA_CURSE_MAP))
        {
            scoreRefs.Remove(i, 1);
            i--;
            continue;
        }
        if(scoreRefs[i].CurrentScore == scoreRefs[i].PlayerState.CurrentScore) continue;
        if(scoreRefs[i].PlayerState.CurrentScore <= 0) 
        {
            scoreRefs[i].CurrentScore = 0;
            continue;
        }
        wi = GetWorldInfo();
        switch(scoreRefs[i].PlayerState.CurrentScore - scoreRefs[i].CurrentScore)
        {
            case 20:
                LastPlayerCrown.PlayerWhoDidAction = scoreRefs[i].PlayerState.GetNetworkingIDString()$"_"$scoreRefs[i].PlayerState.SubID; 
                LastPlayerCrown.TimeOfAction = wi.TimeSeconds;
                
                LastplayerAny.PlayerWhoDidAction = LastPlayerCrown.PlayerWhoDidAction;
                LastplayerAny.TimeOfAction = LastPlayerCrown.TimeOfAction;

                if(!Class'SS_CommunicationSettings'.default.EnableVanessaCurse) break;

                GameMod.OnRecievedChatLogCommand("CrownCollected", LOCALIZATION_SECTION, LOCALIZATION_FILE); 
                break;
            case 50:
                LastPlayerCurse.PlayerWhoDidAction = scoreRefs[i].PlayerState.GetNetworkingIDString()$"_"$scoreRefs[i].PlayerState.SubID; 
                LastPlayerCurse.TimeOfAction = wi.TimeSeconds;
                
                LastplayerAny.PlayerWhoDidAction = LastPlayerCurse.PlayerWhoDidAction;
                LastplayerAny.TimeOfAction = LastPlayerCurse.TimeOfAction;

                if(!Class'SS_CommunicationSettings'.default.EnableVanessaCurse) break;
                
                GameMod.OnRecievedChatLogCommand("PlayerTagged", LOCALIZATION_SECTION, LOCALIZATION_FILE); 
                break;
        }
        scoreRefs[i].CurrentScore = scoreRefs[i].PlayerState.CurrentScore;
    }
}

function bool OnPing(Hat_PlayerController pc, optional bool released = false)
{
    if(!released)
    {
        if(PromptCount > 4) return false;
        PromptCount++;
        pc.Pawn.PlaySound(SoundCue'HatinTime_SFX_UI2.SoundCues.DeathWishFail');
        GameMod.OnRecievedChatLogCommand("PLAYER_PING_DISABLED_VC", "default", "pings");
    }
    return false;
}

static function bool ShouldCreate()
{
    return `GameManager.GetCurrentMapFileName() ~= VANESSA_CURSE_MAP;
}

defaultproperties
{
    TeamWinHUDs.Add("TAG_HUDELEMENT_SWIN");
    TeamWinHUDs.Add("TAG_HUDELEMENT_VWIN");
}