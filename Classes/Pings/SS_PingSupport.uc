Class SS_PingSupport extends Actor
    placeable;

struct PingSupportReference
{
    var Class<Actor> classIdentifier;
	var name className;
	var string directory;
    var bool ignoreHidden;
    var Vector2D collisionHeight;
	var Array<String> IgnoredChildren;
    structdefaultproperties
    {
        ignoreHidden = true;
        // x = radius, y = height
        collisionHeight = (x = 75, y = 100);
    }
};

var Array<PingSupportReference> references;

var(Collision) CylinderComponent PingCylinder;
var(PingSupport) Actor PingReference;
var(PingSupport) bool IgnoreHidden;

function bool IsValid()
{
    if(PingReference == None) return false;
    if(!IgnoreHidden && PingReference.bHidden) return false;
	if(PingReference.IsA('Hat_HookPoint') && !Hat_HookPoint(PingReference).Enabled) return false;
    return true;
}

function AttachPingToActor(Actor o)
{
	local PingSupportReference r;
	PingReference = o;
    foreach default.references(r)
		if(
			(r.classIdentifier != None && o.IsA(r.classIdentifier.Name) || o.class.Name == r.className)
		&& (r.IgnoredChildren.Length == 0 || r.IgnoredChildren.Find(Caps(o.Class.Name)) == INDEX_NONE)
		)
			PingCylinder.SetCylinderSize(r.CollisionHeight.X, r.CollisionHeight.Y);
	Class'OnlineCommunication'.static.AttachToActor(o, self, Class'OnlineCommunication'.static.CreateAttachToActorAction());
}

function Tick(float d)
{
	if(PingReference == None) Destroy();
}

static function ApplyReferences(GameMod gm)
{
    local PingSupportReference r;
	
	foreach default.references(r)
	{
		if(r.classIdentifier ==	None)
		{
			gm.HookActorSpawn(Class'Hat_ClassHelper'.static.GetScriptClass(r.directory $ "." $ r.className), r.className);
		}
		else
			gm.HookActorSpawn(r.classIdentifier, r.classIdentifier.Name);
	}
}

static function bool HookedActorRequiresSupport(Object o)
{
	local int i;
	for(i = 0; i < default.references.Length; i++)
	{
		if(
			default.references[i].classIdentifier != None && o.IsA(default.references[i].classIdentifier.Name) 
			|| o.class.name == default.references[i].className
		)
			return true;
	}
	return false;
}

defaultproperties
{
    Begin Object Class=SpriteComponent Name=Sprite
		Sprite = Texture2D'HatInTime_Hud.Textures.flame'
		HiddenGame=true
		HiddenEditor=false
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		Scale = 0.25;
	End Object
	Components.Add(Sprite)

    Begin Object Class=CylinderComponent Name=ProximityCylinder0
		CollisionRadius=75
		CollisionHeight=100
		BlockActors=false
		CollideActors=true
        bAlwaysRenderIfSelected = true;
	End Object
	PingCylinder = ProximityCylinder0;
	Components.Add(ProximityCylinder0)

    bStatic = false;
    bNoDelete = false;
    bMovable = true;
    bCollideActors = true;
    bCollideWorld = false;
    bBlockActors = false;

	// References to apply the volumes
	references(0) = {(
		classIdentifier = Class'Hat_HookPoint',
		collisionHeight = {(x = 50, y = 75)},
		IgnoredChildren[0] = "SB64_HOOKPOINT_GHOSTPARTY"
	)};
	
	references(1) = {(
		classIdentifier = Class'Hat_BeachCrab',
		className = "Hat_BeachCrab",
		directory = "hatintimegamecontent",
		collisionHeight = {(x = 20, y = 20)}
	)};
    
    references(2) = {(
		classIdentifier = Class'Hat_NPC_Snatcher',
		className = "Hat_NPC_Snatcher",
		directory = "hatintimegamecontent",
		collisionHeight = {(x = 75, y = 200)}
	)};

	references(3) = {(
		classIdentifier = Class'Hat_SpaceshipPowerPanel',
		className = "Hat_SpaceshipPowerPanel",
		directory = "hatintimegamecontent",
		collisionHeight = {(x = 75, y = 60)}
	)}
}