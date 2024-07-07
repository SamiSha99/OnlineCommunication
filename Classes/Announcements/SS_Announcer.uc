Class SS_Announcer extends Object;

var SS_GameMod_PingSystem GameMod;
const LOCALIZATION_FILE = "announcements";

function WorldInfo GetWorldInfo()
{
    return Class'WorldInfo'.static.GetWorldInfo();
}

function Init();
function Tick(float d);
function GhostTick(float d);
function OnCollectibleSpawned(Object InCollectible);
function OnPreOpenHUD(HUD H, out class<Object> InHUDElement);
function OnRemoteEvent(Name EventName);
function OnAnnouncementRecieved();
function bool OnPing(Hat_PlayerController pc, optional bool released = false){ return true; }

static function bool ShouldCreate() { return true; }

function Announce(string localization, string section, Array<ConversationReplacement> keys, optional string primarycommand = "announce")
{
    if(GameMod == None) return;
    
    GameMod.PrepareOnlinePartyCommand(primarycommand$"?localization="$localization$"&section="$section$"&"
    $Class'DictionaryTools'.static.KeysToDictionaryCommand(keys), 
    GetWorldInfo().GetALocalPlayerController().Pawn);

    Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "owner", Class'OnlineCommunication'.static.GetLocalSteamID() $ "_0");
    Gamemod.OnRecievedChatLogCommand(localization, section, LOCALIZATION_FILE, keys);
}

function Print(coerce string msg)
{
    Class'SS_GameMod_PingSystem'.static.Print(msg);
}