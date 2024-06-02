class SS_GhostPartyEmote_Yeah extends Hat_GhostPartyEmote;

defaultproperties
{
	EmoteParticle = ParticleSystem'HatinTime_GhostParty.ParticleSystems.PingHere'
	EmoteVoice = SoundCue'SS_PingSystem_Content.yeah'
	DisplayName = "SSYeahName"
	WheelIndex = 3
}

event static Activate(Actor Player, bool bPlaySound)
{
	Super.Activate(Player, bPlaySound);
	if (Player.IsA('Hat_Player')) Hat_Player(Player).SetExpression(EExpressionType_Happy, 3.0f);
}

static function bool ShouldDisplay(HUD H)
{
	if(Class'SS_GameMod_PingSystem'.default.ToggleAdditionalEmotes != 1) return false;
	return Super.ShouldDisplay(H);
}