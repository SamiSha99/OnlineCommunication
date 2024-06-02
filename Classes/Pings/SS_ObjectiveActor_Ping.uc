/**
 *
 * Copyright 2018 Gears for Breakfast ApS. All Rights Reserved.
 */

class SS_ObjectiveActor_Ping extends Hat_ObjectiveActor;

var float CollapseDistance;

var ParticleSystem AppearParticle;
var Surface DirectionArrow;
var Surface PressureArrow;

var transient ParticleSystemComponent AppearParticleSystemComponent;
var Color PlayerColor;

var int OverlapIndex;

var bool Invisible;

var string UserName;

defaultproperties
{
	LifeSpan = 10.0f
	
	ClampToView = true
	MinCullDistance = 100
	MaxCullDistance = 50000; // 500 meters
	CollapseDistance = 1500 // 15 meters
	CullDistanceFade = 500;
	PulseScale = 1
	IconScale = 1.0;
	AppearParticle = ParticleSystem'SS_PingSystem_Content.PingAppear'
	DirectionArrow = Texture2D'HatInTime_HUD_Cruise.Textures.room_UI_arrow'
	LifeTimeMat = MaterialInstanceTimeVarying'HatInTime_HUD_Cruise.Materials.taskmaster_objective_timer'
	PressureArrow = Texture2D'HatInTime_HUD_Cruise.Textures.pressure_arrow'

	PlayerColor = (R=255, G=255, B=255, A=255);

	UserName = "%ERROR%";
	InheritLocationFromBase = false;
	bStatic = false;
	bMovable = true;
	Physics = PHYS_Interpolating;
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	LifeSpan = Class'SS_Ping_Helpers'.static.GetLifeTime(); // to-do set up based on what it was specified by the player
	AttractHelperHat = Class'SS_CommunicationSettings'.default.AllowHatHelperToAttract;
}

function bool OnDraw(HUD H, Hat_HUDElement hel, float pulse, optional bool InView = true, optional float fadein = 1.f)
{
	if (Invisible) return true;

	IconScale = ShouldCollapse(H) ? 0.4 : 0.8;

	return Super.OnDraw(H, hel, 0, InView, fadein);
}

function SetTimerColor()
{
	local LinearColor lc;

	if (LifeTimeMatInst == None) return;

	lc = GetTimerColor(self);
	LifeTimeMatInst.SetVectorParameterValue('PositiveColor', lc);
}

static function LinearColor GetTimerColor(Hat_ObjectiveActor ob)
{
	return MakeLinearColor(1,0.89,0.11,1);
}

function bool OnDrawSub(HUD H, Hat_HUDElement hel, float pulse, Vector ViewLoc, float size, float alpha, float fadein, bool InView)
{
	local float dist;
	local bool NearEdge;
	local Vector CenterAngle;
	
	Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, alpha);

	CenterAngle = Normal(vect(0.5,0,0)*H.Canvas.ClipX + vect(0,0.5,0)*H.Canvas.ClipY - ViewLoc);
	NearEdge = NearScreenEdge(H, ViewLoc, 50);

	if (NearEdge)
	{
		ViewLoc += CenterAngle*size*0.3;
		hel.DrawCenter(H, ViewLoc.X - CenterAngle.X*size*0.6, ViewLoc.Y - CenterAngle.Y*size*0.6, size*0.8, size*0.56*0.8, DirectionArrow, Atan2(CenterAngle.Y,CenterAngle.X)/(PI*2)-0.25);
	}
	
	// Draw particle
	if (AppearParticleSystemComponent != None)
	{
		H.Canvas.SetPos(ViewLoc.X, ViewLoc.Y);
		AppearParticleSystemComponent.RenderToCanvas(H.Canvas);
	}
	
	// Make it appear a bit larger initially, to catch attention
	size *= Lerp(4, 1, 1-((1-fclamp(fadein/1.5f,0,1))**8));

	// expand if overlapping
	size *= 1 + OverlapIndex*0.2;

	if (LifeTimeMatInst != None && LifeTimeActor != None && LifeTimeActor.LifeSpan > 0 && LifeTimeActor.IsTicking() && LifeTimeActor.TickIsDisabledBit <= 0)
	{
		SetTimerColor();
		hel.DrawCenterMat(H, ViewLoc.X, ViewLoc.Y, size*1.26, size*1.26, LifeTimeMatInst);
	}

	// only draw timer if overlapping
	if (OverlapIndex > 0) return true;

	H.Canvas.Font = class'Hat_FontInfo'.static.GetDefaultFont("abcdefghijkmnlopqrstuvwxyzABCDEFGHIJKMNLOPQRSTUVWXYZ1234567890!@#$%^&*()_+-=");

	if (!ShouldCollapse(H))
	{
		dist = VSize(Location - H.PlayerOwner.Pawn.Location)/class'Hat_MiniMissionTaskMaster'.const.MeterToUU;
		
		hel.DrawCenter(H, ViewLoc.X, ViewLoc.Y, size*1.1, size*1.1, HUDIcon);
		class'Hat_HUDMenu'.static.RenderBorderedText(H, hel, UserName, ViewLoc.X, ViewLoc.Y + size*0.45, size*0.0055, TextAlign_Center,,,,, 0.125);

		if (NearEdge)
			ViewLoc += CenterAngle*size*0.75;
		else
			ViewLoc.Y += size*0.75;

		class'Hat_HUDMenu'.static.RenderBorderedText(H, hel, Round(dist)$"m", ViewLoc.X, ViewLoc.Y, size*0.005, TextAlign_Center,,,,, 0.125);
	}
	else
	{
		hel.DrawCenter(H, ViewLoc.X, ViewLoc.Y, size, size, HUDIcon);
		class'Hat_HUDMenu'.static.RenderBorderedText(H, hel, UserName, ViewLoc.X, ViewLoc.Y + size*0.225, size*0.0055, TextAlign_Center,,,,, 0.125);
	}
	
	return true;
}

function bool ShouldCollapse(HUD H)
{
	return VSize(Location - H.PlayerOwner.Pawn.Location) <= CollapseDistance;
}

function bool NearScreenEdge(HUD H, Vector ViewLoc, float buffer)
{
	if (ViewLoc.X > H.Canvas.ClipX - buffer) return true;
	if (ViewLoc.X < buffer) return true;
	if (ViewLoc.Y > H.Canvas.ClipY - buffer) return true;
	if (ViewLoc.Y < buffer) return true;

	return false;
}

function CreateAppearParticle()
{
	local ParticleSystemComponent pc;
	if (AppearParticleSystemComponent != None) return;
	if (AppearParticle == None) return;
	pc = new class'ParticleSystemComponent';
	pc.SetTemplate(AppearParticle);
	pc.KillParticlesForced();
	pc.SetColorParameter('Color', PlayerColor);
	AttachComponent(pc);
	pc.CanvasExclusive();
	pc.SecondsBeforeInactive = 0;
	pc.SetScale(3);
	pc.ActivateSystem(true);
	AppearParticleSystemComponent = pc;
}

event Destroyed()
{
	if (AppearParticleSystemComponent != None)
	{
		AppearParticleSystemComponent.DetachFromAny();
		AppearParticleSystemComponent = None;
	}
	Super.Destroyed();
}