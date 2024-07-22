class SS_GhostPartyEmote_GG extends Hat_GhostPartyEmote;

defaultproperties
{
	EmoteParticle = ParticleSystem'HatinTime_GhostParty.ParticleSystems.PingHere'
	EmoteVoice = SoundCue'SS_PingSystem_Content.yeah'
	DisplayName = "SSGG"
	WheelIndex = 5
}

event static Activate(Actor Player, bool bPlaySound)
{
	Super.Activate(Player, bPlaySound);
	if (Player.IsA('Hat_Player')) Hat_Player(Player).SetExpression(EExpressionType_Happy, 3.0f);
}

static function bool ShouldDisplay(HUD H)
{
	return Class'SS_CommunicationSettings'.default.ToggleAdditionalEmotes && Super.ShouldDisplay(H);
}