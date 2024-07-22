class SS_GhostPartyEmote_Darling extends Hat_GhostPartyEmote;
	
defaultproperties
{
	EmoteParticle = ParticleSystem'HatinTime_GhostParty.ParticleSystems.PingHere'
	EmoteVoice = SoundCue'HatinTime_Voice_HatKidApphia4.SoundCues.VA_Hatkid_OnlineEmotes_Darling'
	DisplayName = "SSDarlingName"
	WheelIndex = 7
}

event static Activate(Actor Player, bool bPlaySound)
{
	Super.Activate(Player, bPlaySound);
	if (Player.IsA('Hat_Player')) Hat_Player(Player).SetExpression(EExpressionType_Smug, 3.0f);
}

static function bool ShouldDisplay(HUD H)
{
	return Class'SS_CommunicationSettings'.default.ToggleAdditionalEmotes && Super.ShouldDisplay(H);
}