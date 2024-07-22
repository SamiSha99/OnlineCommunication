class SS_GhostPartyEmote_Help extends Hat_GhostPartyEmote;
	
defaultproperties
{
	EmoteParticle = ParticleSystem'HatinTime_GhostParty.ParticleSystems.PingHere'
	EmoteSound = SoundCue'HatinTime_Voice_HatKidApphia4.SoundCues.VA_Hatkid_Combined_Startled'
	DisplayName = "SSHelpName"
	WheelIndex = 6
}

event static Activate(Actor Player, bool bPlaySound)
{
	Super.Activate(Player, bPlaySound);
	if (Player.IsA('Hat_Player')) Hat_Player(Player).SetExpression(EExpressionType_Scared, 3.0f);
}

static function bool ShouldDisplay(HUD H)
{
	return Class'SS_CommunicationSettings'.default.ToggleAdditionalEmotes && Super.ShouldDisplay(H);
}