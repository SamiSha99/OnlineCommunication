// Holds all ~None-ModInfo~ ALL Config Settings
// Heavy Version Control Stuff and also fixes ModInfo not setting correct defaults
Class SS_CommunicationSettings extends Object
    dependsOn(SS_GameMod_OC, SS_CommunicationSettings_Types)
    Config(SSPing);

const SETTINGS_VERSION = 2;
const SETTINGS_VERSION_SOFT = 0; // Soft change for some configs into their original defaults.
const CHAT_SETTINGS_SAVE_PATH_NAME = "OnlineCommunication/settings_v$.hat";
const ERROR_COLOR = "#ED2939";

var config int FileVersion;
var config int FileSoftVersion;

var SS_GameMod_OC GameMod;

// Ping
var config int PingLifeTime;
var config int PingSoundType;
var config int PingCastType;
var config int PingSpotFeature;

// Safety
var config int FilterType;
var config int AntiSpam;
var config int ChannelType; // 0 = All Chat | 1 = Friends Only | 2 = Custom Channel
var config string PrivateChannelName; // Only valid when channel set to private.

// Toggles
var config bool TogglePingSystem;
var config bool TogglePingButton;
var config bool ToggleOnlineChat;
var config bool ToggleAdditionalEmotes;
var config bool ToggleDebugging;

// Chat
var float ChatLifeTime;
var float ChatClippedXLimit;
var Vector2D ChatPosClipped;
var config float GlobalScale;
var config string ChatEmoteTextColor; //Lime color, can be changed

var config bool EnableEmotes;
var config bool ShowWhoHasMod;

// Colors in Hexdecimals (Alpha always 100%)
var config string PlayerColor; // Defaults to White unless specified.
var config string EnemyColor;
var config string NonePlayableColor;
var config string ObjectColor;
var config string ImportantColor;
var config string LocationColor;

const DEFAULT_PLAYER_COLOR = "#FFFFFF";
const DEFAULT_ENEMY_COLOR = "#FF3A3C";
const DEFAULT_NPC_COLOR = "#459DF5";
const DEFAULT_OBJECT_COLOR = "#FDFD30";
const DEFAULT_IMPORTANT_COLOR = "#FF8C2E";
const DEFAULT_LOCATION_COLOR = "#4ECC27";

// Link to a SoundCue from ANY loaded package for personal usage or literally pin point to any mod package installed.
var config string CustomSoundPackage;

var config float PingCrossHairAlpha;
var config float PingCrossHairSize;
var config string PingCrossHairColor;

var config float PingNotificationMasterVolume;
var config float PingNotificationRange; // 25 meters range where volume is maximum and loud and clear
var config float PingNotificationDecayingRange; // Default is 75 meters, this adds an extra check where after reaching the maximum range in the previous, this range decays volume to 0.
var config bool DontSendIfOutOfRange; // Won't send the notification if its too far
var config bool AllowHatHelperToAttract;

// Announcements
var config bool EnableVanessaCurse; // Toggle Vanessa Curse Announcements, unreliable in some cases.
var config bool EnableDeathWish; // Toggle Death Wish Announcements
var config bool EnableTimePiece; // Toggle Time Piece collected Announcement
var config bool EnableJoin; // Show players who recently joined.
var config bool EnableConnectionFailed; // Show players who failed to connect
var config bool EnableLeave; // Show players who recently failed.

// Hotkeys
var config name PingHotKey;
var config name ExpandChatHotkey;

var config int StartingLineType;

function Init()
{
    UpdateMetaStates();
}

// When settings are set, this handles post change and saving this config.
function OnConfigChanged(coerce string ConfigName) 
{
    Class'SS_GameMod_OC'.static.Print("ConfigName changed:" @ ConfigName);
    SaveConfig();
    switch(ConfigName)
    {
        case "PlayerColor":
            UpdateMetaStates();
            break;
        case "ChatClippedXLimit":
            if(GameMod.OnlineChatHUD != None) 
                GameMod.OnlineChatHUD.ChatClippedXLimit = default.ChatClippedXLimit; 
            break;
        case "ToggleOnlineChat":
            if(Class'SS_CommunicationSettings'.default.ToggleOnlineChat)
                GameMod.OpenOnlineChat();
            else
                Hat_HUD(GameMod.GetALocalPlayerController().myHUD).CloseHUD(Class'SS_HUDElement_OnlinePartyChat');
            break;
        case "OpenExpandedConfigMenu":
            GameMod.OpenConfigMenuViaLoadout(GameMod.GetALocalPlayerController().myHUD);
            break;
    }
}

function UpdateMetaStates()
{
    if(Class'Engine'.static.IsEditor()) return;
    Class'Hat_GhostPartyPlayerStateBase'.static.GetLocalPlayerState(0).SetPlayerStateMeta(NameOf(PlayerColor), Class'SS_CommunicationSettings'.default.PlayerColor);
}

function bool GetColorBySteamID(string SteamID_Index, out string HexColor, out string SteamName)
{
    local EmoteChatInfo eci;
    local string steamID, index;
    local Array<string> split;
    split = SplitString(SteamID_Index, "_");
    steamID = split[0];
    index = split[1];

    if(GameMod == None || !Class'Engine'.static.IsEditor() && (SteamID ~= "" || index ~= ""))
    {
        HexColor = ERROR_COLOR;
        SteamName = "BAD ARGUMENTS";
        return false;
    } 

    if(Class'OnlineCommunication'.static.GetLocalSteamID() ~= SteamID)
    {
        HexColor = Class'Engine'.static.IsEditor() ? "#FFFFFF" : Class'SS_CommunicationSettings'.default.PlayerColor;
        SteamName = Class'SS_Ping_Helpers'.static.GetLocalNameCheap(int(index), GameMod.StreamerMode);
        return true;
    }

    foreach GameMod.GhostReader(eci)
    {
        if(!(eci.SteamID ~= SteamID)) continue;
        HexColor = eci.PlayerState.GetPlayerStateMeta(NameOf(Class'SS_CommunicationSettings'.default.PlayerColor), Class'SS_CommunicationSettings'.default.ShowWhoHasMod ? "#A8A8A8" : "#FFFFFF");
        if(HexColor == "") HexColor = Class'SS_CommunicationSettings'.default.ShowWhoHasMod ? "#A8A8A8" : "#FFFFFF";
        SteamName = Class'SS_Ping_Helpers'.static.GetGhostName(eci, INDEX_NONE, GameMod.StreamerMode);
        return true;
    }
    HexColor = ERROR_COLOR;
    SteamName = "INVALID STEAM ID";
    return false;
}

//#########//
// Getters //
//#########//

// Getter for all settings should be in String until a better solution?
function string GetSettingString(coerce string SettingName, optional bool GetDefault = false)
{
    switch(SettingName)
    {
        case "PlayerColor":           case "PC":    return GetDefault ? DEFAULT_PLAYER_COLOR : PlayerColor;
        case "EnemyColor":            case "EC":    return GetDefault ? DEFAULT_ENEMY_COLOR : EnemyColor;
        case "NonePlayableColor":     case "NPC":   return GetDefault ? DEFAULT_NPC_COLOR : NonePlayableColor;
        case "ObjectColor":           case "OC":    return GetDefault ? DEFAULT_OBJECT_COLOR : ObjectColor;
        case "ImportantColor":        case "IC":    return GetDefault ? DEFAULT_IMPORTANT_COLOR : ImportantColor;
        case "LocationColor":         case "LC":    return GetDefault ? DEFAULT_LOCATION_COLOR : LocationColor;
        case "CustomSoundPackage":    case "CSP":   return GetDefault ? ""        : CustomSoundPackage;
        case "GlobalScale":           case "GS":    return GetDefault ? "1.0"     : string(GlobalScale);
        case "PingCrossHairColor":    case "PCHC":  return GetDefault ? "#FFFFFF" : PingCrossHairColor;
        case "PingHotKey":            case "PHK":   return GetDefault ? "R"       : String(PingHotKey);
        case "ExpandChatHotkey":      case "ECHK":  return GetDefault ? "T"       : String(ExpandChatHotkey);
        case "ChatEmoteTextColor":    case "CETC":  return GetDefault ? "#FFFFFF" : ChatEmoteTextColor;
        case "PrivateChannelName":    case "PCN":   return GetDefault ? ""        : PrivateChannelName;
    }
    return "";
}

function name GetSettingName(coerce string SettingName, optional bool GetDefault = false)
{
    switch(SettingName)
    {
        case "PingHotKey":              return GetDefault ? 'R'       : PingHotKey;
        case "ExpandChatHotkey":        return GetDefault ? 'T'       : ExpandChatHotkey;
    }
    return '';
}

function int GetSettingInt(coerce string SettingName, optional bool GetDefault = false)
{
    switch(SettingName)
    {
        // Bools
        case "EnableVanessaCurse":      return (GetDefault ? 1 : (EnableVanessaCurse ? 1 : 0));
        case "EnableDeathWish":         return (GetDefault ? 1 : (EnableDeathWish ? 1 : 0));
        case "EnableTimePiece":         return (GetDefault ? 1 : (EnableTimePiece ? 1 : 0));
        case "EnableJoin":              return (GetDefault ? 1 : (EnableJoin ? 1 : 0));
        case "EnableConnectionFailed":  return (GetDefault ? 1 : (EnableConnectionFailed ? 1 : 0));
        case "EnableLeave":             return (GetDefault ? 1 : (EnableLeave ? 1 : 0));
        case "DontSendIfOutOfRange":    return (GetDefault ? 0 : (DontSendIfOutOfRange ? 1 : 0));
        case "AllowHatHelperToAttract": return (GetDefault ? 0 : (AllowHatHelperToAttract ? 1 : 0));
        case "EnableEmotes":            return (GetDefault ? 1 : (EnableEmotes ? 1 : 0));
        case "ShowWhoHasMod":           return (GetDefault ? 1 : (ShowWhoHasMod ? 1 : 0));
        
        case "TogglePingSystem":        return (GetDefault ? 1 : (TogglePingSystem ? 1 : 0));
        case "TogglePingButton":        return (GetDefault ? 1 : (TogglePingButton ? 1 : 0));
        case "ToggleOnlineChat":        return (GetDefault ? 1 : (ToggleOnlineChat ? 1 : 0));
        case "ToggleAdditionalEmotes":  return (GetDefault ? 1 : (ToggleAdditionalEmotes ? 1 : 0));
        case "ToggleDebugging":         return (GetDefault ? 0 : (ToggleDebugging ? 1 : 0));


        // Ints
        case "ChannelType":             return (GetDefault ? 0 :                    ChannelType);
        case "StartingLineType":        return (GetDefault ? 0 :                    StartingLineType);
        case "FilterType":              return (GetDefault ? FT_Peck :              FilterType);
        case "AntiSpam":                return (GetDefault ? AST_LastMessage :      AntiSpam);

        case "PingLifeTime":            return (GetDefault ? 10 :                   PingLifeTime);
        case "PingSoundType":           return (GetDefault ? 0 :                    PingSoundType);
        case "PingCastType":            return (GetDefault ? PCT_Confirm :          PingCastType);
        case "PingSpotFeature":         return (GetDefault ? PSF_All :              PingSpotFeature);
    }
    return -1;
}

function float GetSettingFloat(coerce string SettingName, optional bool GetDefault = false)
{
    switch(SettingName)
    {
        case "GlobalScale":                     return GetDefault ? 1.0f : GlobalScale;
        case "ChatClippedXLimit":               return GetDefault ? default.ChatClippedXLimit : ChatClippedXLimit;
        case "PingCrossHairAlpha":              return GetDefault ? 0.7f : PingCrossHairAlpha;
        case "PingCrossHairSize":               return GetDefault ? 1.0f : PingCrossHairSize;
        case "ChatLifeTime":                    return GetDefault ? 10.0f : ChatLifeTime;

        case "PingNotificationMasterVolume":    return GetDefault ? 1.0f : PingNotificationMasterVolume;
        case "PingNotificationRange":           return GetDefault ? 25.0f : PingNotificationRange;
        case "PingNotificationDecayingRange":   return GetDefault ? 75.0f : PingNotificationDecayingRange;
    }
    return 0;
}

//#########//
// Setters //
//#########//

function bool SetSettingString(coerce string SettingName, string Value)
{
    switch(SettingName)
    {
        case "PlayerColor":         PlayerColor = Value;                         break;
        case "EnemyColor":          EnemyColor = Value;                          break;
        case "NonePlayableColor":   NonePlayableColor = Value;                   break;
        case "ObjectColor":         ObjectColor = Value;                         break;
        case "ImportantColor":      ImportantColor = Value;                      break;
        case "LocationColor":       LocationColor = Value;                       break;
        case "CustomSoundPackage":  CustomSoundPackage = Value;                  break;
        case "PingCrossHairColor":  PingCrossHairColor = Value;                  break;
        case "ChatEmoteTextColor":  ChatEmoteTextColor = Value;                  break;
        case "PrivateChannelName":  PrivateChannelName = Value;                  break;
        default: return false;
    }
    OnConfigChanged(SettingName);
    return true;
}

function bool SetSettingName(coerce string SettingName, name Value)
{
    switch(SettingName)
    {
        case "PingHotKey":          PingHotKey = Value;                          break;
        case "ExpandChatHotkey":    ExpandChatHotkey = Value;                    break;
        default: return false;
    }
    OnConfigChanged(SettingName);
    return true;
}

function bool SetSettingInt(coerce string SettingName, int value)
{
    local bool b;
    b = value >= 1;

    switch(SettingName)
    {
        // Bools
        case "EnableVanessaCurse":          EnableVanessaCurse = b;             break;
        case "EnableDeathWish":             EnableDeathWish = b;                break;
        case "EnableTimePiece":             EnableTimePiece = b;                break;
        case "EnableJoin":                  EnableJoin = b;                     break;
        case "EnableConnectionFailed":      EnableConnectionFailed = b;         break;
        case "EnableLeave":                 EnableLeave = b;                    break;
        case "DontSendIfOutOfRange":        DontSendIfOutOfRange = b;           break;
        case "AllowHatHelperToAttract":     AllowHatHelperToAttract = b;        break;
        case "EnableEmotes":                EnableEmotes = b;                   break;
        case "ShowWhoHasMod":               ShowWhoHasMod = b;                  break;

        case "TogglePingSystem":            TogglePingSystem = b;               break;
        case "TogglePingButton":            TogglePingButton = b;               break;
        case "ToggleOnlineChat":            ToggleOnlineChat = b;               break;
        case "ToggleAdditionalEmotes":      ToggleAdditionalEmotes = b;         break;
        case "ToggleDebugging":             ToggleDebugging = b;                break;

        // Ints 
        case "ChannelType":                 ChannelType = value;                break;
        case "StartingLineType":            StartingLineType = value;           break;
        case "FilterType":                  FilterType = value;                 break;
        case "AntiSpam":                    AntiSpam = value;                   break;

        case "PingLifeTime":                PingLifeTime = value;               break;
        case "PingSoundType":               PingSoundType = value;              break;
        case "PingCastType":                PingCastType = value;               break;
        case "PingSpotFeature":             PingSpotFeature = value;            break;
        default: return false;
    }
    OnConfigChanged(SettingName);
    return true;
}

function bool SetSettingFloat(coerce string SettingName, float value)
{
    switch(SettingName)
    {
        case "GlobalScale":         GlobalScale = value;            break;
        case "ChatClippedXLimit":   ChatClippedXLimit = value;      break;
        case "PingCrossHairAlpha":  PingCrossHairAlpha = value;     break;
        case "PingCrossHairSize":   PingCrossHairSize = value;      break;
        case "ChatLifeTime":        ChatLifeTime = value;           break;
        case "PingNotificationMasterVolume":    PingNotificationMasterVolume = value; break;
        case "PingNotificationRange":           PingNotificationRange = value; break;
        case "PingNotificationDecayingRange":   PingNotificationDecayingRange = value; break;
        default: return false;
    }
    OnConfigChanged(SettingName);
    return true;
}

function ResetToDefault()
{
    // local GameModInfo gmi;
    // local int i;

    // This should be incremented
    FileVersion = SETTINGS_VERSION;
    FileSoftVersion = SETTINGS_VERSION_SOFT;

    PlayerColor = DEFAULT_PLAYER_COLOR;
    EnemyColor = DEFAULT_ENEMY_COLOR;
    NonePlayableColor = DEFAULT_NPC_COLOR;
    ObjectColor = DEFAULT_OBJECT_COLOR;
    ImportantColor = DEFAULT_IMPORTANT_COLOR;
    LocationColor = DEFAULT_LOCATION_COLOR;

    PingLifeTime = 10;
    PingSoundType = 0;
    PingCastType = PCT_Confirm;
    PingSpotFeature = PSF_All;

    FilterType = FT_Peck;
    AntiSpam = AST_LastMessage;

    TogglePingSystem = true;
    TogglePingButton = true;
    ToggleOnlineChat = true;
    ToggleAdditionalEmotes = true;
    ToggleDebugging = false;

    EnableVanessaCurse = true;
    EnableDeathWish = true;
    EnableTimePiece = true;
    EnableJoin = true;
    EnableConnectionFailed = true;
    EnableLeave = true;
    
    EnableEmotes = true;
    ShowWhoHasMod = true;

    GlobalScale = 1.0f;
    ChatLifeTime = 10.0f;
    ChatClippedXLimit = default.ChatClippedXLimit;
    ChatEmoteTextColor = "#FFFFFF"; // #BFFF00

    PingCrossHairAlpha = 0.7f;
    PingCrossHairSize = 1.0f;
    PingCrossHairColor = "#FFFFFF";

    PingNotificationMasterVolume = 1;
    PingNotificationRange = 30;
    PingNotificationDecayingRange = 70;
    DontSendIfOutOfRange = false;
    AllowHatHelperToAttract = false;

    PingHotKey = 'R';
    ExpandChatHotkey = 'T';

    CustomSoundPackage = "ssexamplepath.examplesound";
    
    ChannelType = 0;
    PrivateChannelName = "";

    StartingLineType = 0;

    // Class'GameMod'.static.GetClassMod(Class'SS_GameMod_OC', gmi);
    // for(i = 0; i < gmi.configs.Length; i++)
        // Class'GameMod'.static.SaveConfigValue(Class'SS_GameMod_OC', Name(gmi.configs[i].ID), gmi.configs[i].Default);
    
    SaveConfig();
}

function SoftVersionApply()
{
    FileSoftVersion = SETTINGS_VERSION_SOFT;
    Class'SS_GameMod_OC'.static.Print("Soft Version Mismatch, updating some settings to their new/current defaults.");
    /*
      ~But nobody came... yet~ 
    */
    SaveConfig();
}

static function bool LoadChatSettings(out SS_CommunicationSettings ChatSettings) 
{

    if(ChatSettings == None)
    {
        ChatSettings = new class'SS_CommunicationSettings';
    }

    if(!class'Engine'.static.BasicLoadObject(ChatSettings, GetSettingsPath(), false, class'SS_CommunicationSettings'.const.SETTINGS_VERSION))
    {
        Class'SS_GameMod_OC'.static.Print("Reseting everything to defaults due first time initialization OR older version OR couldn't be found.");
        ChatSettings.ResetToDefault();
        return false;
    }

    if(ChatSettings.FileSoftVersion != SETTINGS_VERSION_SOFT) ChatSettings.SoftVersionApply();

    Class'SS_GameMod_OC'.static.Print("Settings loaded successfully!");
    return true;
}

static function bool SaveChatSettings(out SS_CommunicationSettings ChatSettings)
{
    return class'Engine'.static.BasicSaveObject(ChatSettings, GetSettingsPath(), false, class'SS_CommunicationSettings'.const.SETTINGS_VERSION);
}

static function string GetSettingsPath()
{
    return Repl(CHAT_SETTINGS_SAVE_PATH_NAME, "$", SETTINGS_VERSION, false);
}

defaultproperties
{
    ChatClippedXLimit = 0.3f;
    ChatPosClipped = (X = 0.0125f, Y = 0.666f);
}