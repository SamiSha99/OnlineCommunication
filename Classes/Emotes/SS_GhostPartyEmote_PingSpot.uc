// Emote this to toggle pinging, aim then left click to ping.
// The only console support, for now. Heh...
Class SS_GhostPartyEmote_PingSpot extends Hat_GhostPartyEmote;

defaultproperties
{
	EmoteParticle = None;
	EmoteVoice = None;
	DisplayName = "SSPingSpot"
	EmoteIcon = Texture2D'SS_PingSystem_Content.ping_icon';
	WheelIndex = -1
}

event static Activate(Actor Player, bool bPlaySound)
{
	local SS_GameMod_OC gm;
	Class'WorldInfo'.static.GetWorldInfo().SetTimer(0.01f, false, 'PingFromEmoteRequest');
	gm = SS_GameMod_OC(Class'OnlineCommunication'.static.GetGameMod('SS_GameMod_OC'));
	gm.PingFromEmoteRequest(Hat_PlayerController(Hat_Player(Player).Controller));
}

static function bool ShouldDisplay(HUD H)
{
	return IsAllowed(H) && Super.ShouldDisplay(H);
}

static function bool IsAllowed(HUD H)
{
	local Hat_PlayerController pc;

	pc = Hat_PlayerController(H.PlayerOwner);
	
	switch(Class'SS_CommunicationSettings'.default.PingSpotFeature)
	{
		case 3: return true;
		case 2: return !pc.IsGamepad();
		case 1:	return pc.IsGamepad();
		case 0: return false;
	}
}