Class SS_PingSpot extends Actor
    placeable;

var() MeshComponent PingSphere;
var() MeshComponent ProfileAvatar;
var SS_ObjectiveActor_Ping PingSpot;

var MaterialInterface AvatarMat;

// to-do animate appearance
var float ScaleTime, ScaleAmount;

const SIZE_OFFSET = 0.0025f;

function PostBeginPlay()
{
	local Vector scale;
    Super.PostBeginPlay();
	LifeSpan = Class'SS_Ping_Helpers'.static.GetLifeTime(); // to-do set up based on what it was specified by the player
    scale.X = RandRange(0.2 - SIZE_OFFSET, 0.2 + SIZE_OFFSET);
    scale.Y = RandRange(0.2 - SIZE_OFFSET, 0.2 + SIZE_OFFSET);
    scale.Z = RandRange(0.2 - SIZE_OFFSET, 0.2 + SIZE_OFFSET);
    PingSphere.SetScale3D(scale);
    PingSphere.SetTranslation(vect(0,0,1)*RandRange(-0.05,0.05));
}

function SetPing(EmoteChatInfo_LocalPlayers lr, optional Actor target = None)
{
    local SS_ObjectiveActor_Ping ping;
    
    // Ping point
    ping = `GameManager.Spawn(class'SS_ObjectiveActor_Ping');
    ping.PlayerColor = Class'SS_Color'.static.Hex(Class'SS_CommunicationSettings'.default.PlayerColor);
    ping.CreateAppearParticle();
    
    if(Class'Engine'.static.IsEditor())
        ping.HUDIcon = CreateAvatarBubble(None, Class'SS_CommunicationSettings'.default.PlayerColor);
    else
        ping.HUDIcon = CreateAvatarBubble(Hat_GhostPartyPlayerState(class'Hat_GhostPartyPlayerStateBase'.static.GetLocalPlayerState(0)), Class'SS_CommunicationSettings'.default.PlayerColor);
    ping.SetEnabled(true);
    ping.SetLocation(Location);

    ping.UserName = Class'Engine'.static.IsEditor() ? "PLAYER_NAME" : Class'SS_1984'.static.Literally1984(lr.SteamName);
    ping.Invisible = false;
    PingSpot = ping;

    PingSphere.SetMaterial(0, CreatePingSpotMaterial(Class'SS_CommunicationSettings'.default.PlayerColor));
    
    if(target != None && CanAttach(target))
    {
        
        Class'OnlineCommunication'.static.AttachToActor(target, self, Class'OnlineCommunication'.static.CreateAttachToActorAction());
        Class'OnlineCommunication'.static.AttachToActor(target, ping, Class'OnlineCommunication'.static.CreateAttachToActorAction());
    }
}

function SetPingGhost(EmoteChatInfo gr, optional Actor target = None)
{
    local SS_ObjectiveActor_Ping ping;
    local string hexColor;

    hexColor = gr.PlayerState.GetPlayerStateMeta(NameOf(Class'SS_CommunicationSettings'.default.PlayerColor), "#FFFFFF");
    
    // Ping point
    ping = `GameManager.Spawn(class'SS_ObjectiveActor_Ping');
    ping.PlayerColor = Class'SS_Color'.static.Hex(hexColor);
    ping.CreateAppearParticle();

    
    if(Class'Engine'.static.IsEditor())
        ping.HUDIcon = CreateAvatarBubble(None, hexColor);
    else
        ping.HUDIcon = CreateAvatarBubble(gr.PlayerState, hexColor);
    ping.SetEnabled(true);
    ping.SetLocation(Location);

    ping.UserName = Class'Engine'.static.IsEditor() ? "PLAYER_NAME" : Class'SS_1984'.static.Literally1984(gr.SteamName);
    ping.Invisible = false;
    PingSpot = ping;

    PingSphere.SetMaterial(0, CreatePingSpotMaterial(hexColor));

    if(target != None && CanAttach(target))
    {
        Class'OnlineCommunication'.static.AttachToActor(target, self, Class'OnlineCommunication'.static.CreateAttachToActorAction());
        Class'OnlineCommunication'.static.AttachToActor(target, ping, Class'OnlineCommunication'.static.CreateAttachToActorAction());
    }
}

static function MaterialInterface CreateAvatarBubble(Hat_GhostPartyPlayerStateBase PlayerState, string colorHex = "FFFFFF")
{
	local MaterialInstanceTimeVarying mitv;
    local LinearColor lc;
    local Texture2D InAvatar;

    if(PlayerState == None || Class'Engine'.static.IsEditor())
        InAvatar = Texture2D'HatinTime_GhostParty.Textures.noavatar';
    else if(Class'SS_1984'.static.ShouldCensorAvatars())
        InAvatar = class'Hat_HUDElementPlayerList'.static.GetCensoredAvatar(PlayerState);
    else
        InAvatar = PlayerState.Avatar;

	mitv = Class'OnlineCommunication'.static.InitMaterial(default.AvatarMat);
	mitv.SetTextureParameterValue('Avatar', InAvatar);
    

    lc = Class'SS_Color'.static.HexToLinearColor(colorHex);
    mitv.SetLinearColorParameterValue('Color', lc);

	return mitv;
}

function MaterialInterface CreatePingSpotMaterial(string colorHex = "FFFFFF")
{
	local MaterialInstanceTimeVarying mitv;
    local LinearColor lc;
	mitv = Class'OnlineCommunication'.static.InitMaterial(PingSphere.Materials[0]);
    lc = Class'SS_Color'.static.HexToLinearColor(colorHex);
    mitv.SetLinearColorParameterValue('Color', lc);

	return mitv;
}

function bool CanAttach(Actor a)
{
    local int i;
    local Object obj;
    local string key, localization;

    i = 0;
    obj = a;
    key = Repl(a, "_" $ GetRightMost(a), "", false);
    do
    { 
        if(Class'SS_Ping_Identifier'.static.PingHasOption("DontAttach", key, localization)) return localization ~= "none";
        
        key = i == 0 ? String(obj.default.ObjectArchetype.Class.Name) : String(obj.ObjectArchetype.Class.Name);
        obj = i == 0 ? obj.default.ObjectArchetype : obj.ObjectArchetype;
        i++;
    }
    until(obj.Class == Class'Object' || obj.Class == Class'Actor' || i >= 50); // to infinity™ and break

    return true;
}

function Destroyed()
{
    if(PingSpot != None)
    {
        PingSpot.SetEnabled(false);
        PingSpot.Destroy();
    }
}

function Tick(float d)
{
    MaterialInstanceTimeVarying(PingSphere.Materials[0]).SetScalarParameterValue('GammaCorrection', Class'Engine'.static.GetDisplayGamma());
}

defaultproperties
{
    Begin Object Class=StaticMeshComponent Name=Mesh0
		StaticMesh = StaticMesh'HatinTime_PrimitiveShapes.TexPropSphere'
		Materials(0) = Material'SS_PingSystem_Content.PingSpotNew'
        Scale3D=(X=0.2, Y=0.2, Z=0.2)
		MaxDrawDistance = 3000;
		CastShadow=false
		bAcceptsLights=false
		bAllowCullDistanceVolume = false;
	End Object
	PingSphere = Mesh0
	Components.Add(Mesh0)
    
    AvatarMat = Material'SS_PingSystem_Content.AvatarPing';

    LifeSpan = 10.0f;
}