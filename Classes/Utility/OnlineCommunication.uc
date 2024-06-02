/*  
* =========================================================================
* A bunch of static functions I've made, utilized or modified through the
* years I've modded A Hat in Time, these represents in some way or form
* a useful utility class to do some of the tasks I've noticed to be done
* frequently, so instead of writing code again and again, this documents it
* all.
* All you need to do is to write the following:
* Class'SS_Utils'.static.NAME_OF_FUNCTION();
* Where NAME_OF_FUNCTION(); is the name of one of the functions below.
* File made by SamiSha, with credits to people who utilized/made some of
* these functions (If I remember).
* =========================================================================
*/ 
Class OnlineCommunication extends Object
    abstract;

struct Utils_Button
{
    var String Title; // Text on top of the button.
    var String Identifier; // Helps make it easier to find that button when searching it up.
    var Surface Surface; // Texture of the button. 
    var float X, Y; // Position of the button.
    var float Width, Height; // Sizes of the button.
};

/*  
* =========================================================================
* Returns a specified GameMod.
* Returns None if couldn't find it.
* If you wanna modify that GM, remember to cast the GameMod to the name!
* Important: External mod support are extremely weird jank, caution is
* advised! You can utilize SetTimers() to delay this call slightly so all GameMods load first.
* @param GameModName - Name of the GameMod we are looking for.
* =========================================================================
*/
static function GameMod GetGameMod(Name GameModName)
{
    local Actor a;

    foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'Actor', a)
    {
        if(!a.IsA(GameModName)) continue;
        return GameMod(a);
    }
    return None;
}

static function bool IsModInstalled(name modClassName, optional bool checkIfEnabled = false)
{
    local Array<GameModInfo> gmis;
    local GameModInfo gmi;
    gmis = Class'GameMod'.static.GetModList();
    foreach gmis(gmi)
    {
        if(gmi.ModClassName != modClassName) continue;
        return checkIfEnabled ? gmi.IsEnabled : true;
    }
    return false;
}

/*  
* =========================================================================
* An actor search function with an ID check. 
* Unknown how this behaves with streamed maps!
* Returns the specified values, return None if couldn't find it.
* @param ObjectName - Name of the Class we are looking for.
* @param ID - The identifier that we are looking for in the level.
* Example: Hat_TimeObject_7 | Class: Hat_TimeObject | ID: 7
* =========================================================================
*/
static function Actor SearchActor(Name ObjectName, int ID)
{
    local Actor a;
    
	foreach class'Worldinfo'.static.GetWorldInfo().AllActors(class'Actor', a)
	{
		if(!a.IsA(objectName)) continue;
		if(String(a.Name) ~= (String(objectName) $ "_" $ String(id))) return a;
	}
 
	return None;
}

/*  
* =========================================================================
* Prints directly to the console! Utilized for mostly debugging purposes.
* @param tag - Full caps tag name between brackets []
* @param msg - The message we want to print in the console.
* Credits: Starblaster64
* =========================================================================
*/
static final function Print(coerce string msg, optional coerce string tag = "")
{
    local WorldInfo wi;
    wi = class'WorldInfo'.static.GetWorldInfo();
    if (wi == None) return;
    if(!(tag ~= "")) msg = "[" @ tag @ "] " @ msg;
    if (wi.GetALocalPlayerController() != None)
        wi.GetALocalPlayerController().TeamMessage(None, msg, 'Event', 6);
    else
        wi.Game.Broadcast(wi, msg);
}

/*  
* =========================================================================
* Returns true if the map is the Space Ship.
* Not suitable for modded spaceships!
* =========================================================================
*/
static function bool InSpaceShip()
{
    return `GameManager.GetCurrentMapFileName() ~= `GameManager.HubMapName; 
}

/*  
* =========================================================================
* Returns true if the map is the Title Screen.
* Not suitable for modded title screens!
* =========================================================================
*/
static function bool InTitleScreen()
{
    return `GameManager.GetCurrentMapFileName() ~= `GameManager.TitleScreenMapName;
}

/*  
* =========================================================================
* ██████  ██       █████  ██    ██ ███████ ██████  
* ██   ██ ██      ██   ██  ██  ██  ██      ██   ██ 
* ██████  ██      ███████   ████   █████   ██████  
* ██      ██      ██   ██    ██    ██      ██   ██ 
* ██      ███████ ██   ██    ██    ███████ ██   ██ 
* =========================================================================
*/

/*  
* =========================================================================
* Returns a player based on the inputted index.
* Will return "None" if invalid index!
* -------------------------------------------------------------------------
* @param index - The index of the player we are looking for, normally
* 0 is "Player 1" and 1 is "Player 2" and so on.
* =========================================================================
*/
static function Hat_Player GetPlayer(optional int index = 0)
{
    local Array<Hat_Player> players;
    players = GetAllPlayers();
    return (index < players.Length ? players[index] : None);
}

/*  
* =========================================================================
* Return all players.
* =========================================================================
*/
static function Array<Hat_Player> GetAllPlayers()
{
    local LocalPlayer lp;
    local Array<Hat_Player> players;
    
    foreach class'Engine'.static.GetEngine().GamePlayers(lp) players.AddItem(Hat_Player(lp.Actor.Pawn));

    return players;
}

/*  
* =========================================================================
* Returns a player from ALL players (basically randomizer).
* Useful for Coop!
* =========================================================================
*/
static function Hat_Player GetPlayerRand()
{
    local Array<Hat_Player> players;

    players = GetAllPlayers();

    return players[Rand(players.Length)];
}

/*  
* =========================================================================
* Returns the nearest player to the specified spot
* @param spot - A location in 3D space
* =========================================================================
*/
static function Hat_Player GetPlayerNearest(Vector spot, optional out float nearestRange)
{
    local Array<Hat_Player> players;
    local Hat_Player p, nearestPlayer;

    players = GetAllPlayers();
    nearestRange = 9999999999999;
    foreach players(p)
    {
        if(nearestPlayer != None && VSize2D(spot - p.Location) < nearestRange) continue;
        nearestRange = VSize2D(spot - p.Location);
        nearestPlayer = p;
    }

    return nearestPlayer;
}

/*  
* =========================================================================
* A function that represents certain checks designed for being "forbidden",
* those are common states where the player "loses control" (like cinematics),
* extremly useful for certain things such as custom abilities.
* If you dislike something added to this list, I'd recommend copying and
* modifying this list to suit your needs! (and remove the static from it)
* -------------------------------------------------------------------------
* @Return true if the situation is forbidden.
* @param plyr - The player we are checking.
* Credits: Argle Bargle's mod "Chase Badge", 
* I've modified it a little bit to be relevant with current DLCs and so on!
* =========================================================================
*/
static function bool Forbidden(Hat_Player plyr)
{
	local Hat_PlayerController pc;
    local Hat_HUD hud;

    if(plyr == None) return false; // Uh... excuse me?
    
    if (InCinematicOrFrozen(plyr)) return true;
    if (plyr.IsTaunting("Level_Intro_Front")) return true;
    if (plyr.IsTaunting("Level_Intro_Back")) return true;
    if (plyr.IsTaunting("Bench_Sit")) return true;
	if (plyr.Health <= 0) return true;
	if (plyr.bWaitingForCaveRiftIntro) return true;
	if (plyr.IsTaunting("Died")) return true;
	if (plyr.IsNewItemState()) return true;
	
	pc = Hat_PlayerController(plyr.Controller);
    if (pc == None) return true;
    if (pc.IsTalking()) return true;

    hud = Hat_HUD(pc.myHUD);
    if(hud == None) return true;
    if (hud.IsHUDClassEnabled(class'Hat_HUDElementContract')) return true;
    if (hud.IsHUDClassEnabled(class'Hat_HUDMenu_ModLevelSelect')) return true;
    if (hud.IsHUDClassEnabled(class'Hat_HUDMenu_MetroFood')) return true;
    if (hud.IsHUDClassEnabled(class'Hat_HUDMenuShop')) return true;
    if (hud.IsHUDClassEnabled(class'Hat_HUDMenuDeathWish')) return true;
	if (hud.IsHUDClassEnabled(class'Hat_HUDElementActTitleCard')) return true;
	if (hud.IsHUDClassEnabled(class'Hat_HUDElementLoadingScreen')) return true;
	
	return false;
}

/*  
* =========================================================================
* Returns true if the player is in Cinematics or Frozen (not ticking).
* @param plyr - The player we are checking.
* =========================================================================
*/
static function bool InCinematicOrFrozen(Hat_Player plyr)
{
    if (plyr.Controller != None && plyr.Controller.IsA('PlayerController') && PlayerController(plyr.Controller).bCinematicMode) return true;
    if (!plyr.IsTicking()) return true;
    return false;
}

/*  
* =========================================================================
* Check if the specified player is using GamePad or not.
* -------------------------------------------------------------------------
* @Return true if the specified player is using a game pad.
* @param plyr - The player we are checking.
* =========================================================================
*/
static function bool IsGamePad(Hat_Player plyr)
{
    return Hat_PlayerController(plyr.Controller).IsGamePad();
}

/*  
* =========================================================================
* Enables Input listening to the specificed class (based on where this
* is called in the first place), allowing you to listen to inputs.
* To put this in the shortest way possible, you must read about delegates
* to fully understand how to utilize them, for more info about how delegates see this page:
* https://docs.unrealengine.com/udk/Three/UnrealScriptDelegates.html 
* or contact me on the workshop page!
* WHAT TO USE THIS FOR? This is mainly utilized to implement an ability
* under the Snap Camera Key which has been done in many mods!
* IMPORTANT: See UnregisterInputEvent() found below this function!
* -------------------------------------------------------------------------
* @param plyr - The player we want to listen from.
* @param out KeyCaptureInteraction - The variable that will manage the
* delegate functions. Note: You need to pass an Interaction variable here!
* @param ReceivedNativeInputKey - Adds delegate call for Key Presses.
* @param ReceivedNativeInputAxis - Adds delegate call for Mouses and Joysticks.
* @param ReceivedNativeInputChar - Adds delegate call for chars such as typing.
* NOTE: You can leave the optionals empty causing to never make a "delegate" 
* call back, so just use the ones you need!
* Credits: EpicYoshiMaster, they taught me this!
* =========================================================================
*/
static function RegisterInputEvent(Hat_Player plyr, out Interaction KeyCaptureInteraction,
    optional delegate<Interaction.OnReceivedNativeInputKey> ReceivedNativeInputKey = None,
    optional delegate<Interaction.OnReceivedNativeInputAxis> ReceivedNativeInputAxis = None,
    optional delegate<Interaction.OnReceivedNativeInputChar> ReceivedNativeInputChar = None)
{
	local int iInput;
	local Hat_PlayerController pc;

	pc = Hat_PlayerController(plyr.Controller);
 
	KeyCaptureInteraction = new(pc) class'Interaction';
	KeyCaptureInteraction.OnReceivedNativeInputKey = ReceivedNativeInputKey;
	KeyCaptureInteraction.OnReceivedNativeInputAxis = ReceivedNativeInputAxis;
    KeyCaptureInteraction.OnReceivedNativeInputChar = ReceivedNativeInputChar;
	iInput = pc.Interactions.Find(pc.PlayerInput);
	pc.Interactions.InsertItem(Max(iInput, 0), KeyCaptureInteraction);
}

/*  
* =========================================================================
* Unregisters Input Listeners to the class that called this function.
* This means the specified delegate function will stop working entirely!!!
* (Until RegisterKeyEvent() gets called again).
* NOTE: Not doing this call the moment you destory the class of this delegate
* will mass you with warnings and probably ton of bugs.
* IMPORTANT: See RegisterInputEvent() found above this function!
* -------------------------------------------------------------------------
* @param plyr - The player we want to stop listening from. (they are cringe)
* @param out KeyCaptureInteraction - The interaction key we want to
* unregister input listening.
* Credits: EpicYoshiMaster, they taught me this!
* =========================================================================
*/
static function UnregisterInputEvent(Hat_Player plyr, out Interaction KeyCaptureInteraction)
{
	local Hat_PlayerController pc;
    if(plyr == None) return; // coop disabled causes those input events to be garbage collected... right?
	pc = Hat_PlayerController(plyr.Controller);
	pc.Interactions.RemoveItem(KeyCaptureInteraction);
	KeyCaptureInteraction = None;
	pc = None;
}

/*  
* =========================================================================
* Check if the inputted key is a "Player" key, due to the amount of
* different controllers that exist, the below are the "universal" keys
* You can use this list as a reference sheet for all the keys that players
* can use.
* This is extremely viable for a delegate function found in Interaction class
* called "OnReceivedNativeInputKey" as it will pass the Key name when
* pressing and you can just use this to check and whether to "suppress" the
* key input by returning "true" in that delegate function.
* -------------------------------------------------------------------------
* @Returns true if the key is a valid "Player Key".  
* @param Key - Name of the Key we want to check.
* @paraam WithPauseMenu - If true, will check the pause menu, normally this
* should be false because we need to "respect" the player for pausing the
* game.
* =========================================================================
*/
static function bool IsPlayerKey(name Key, optional bool WithPauseMenu = false)
{
	switch(Key)
	{
		case 'Hat_Player_Attack':
		case 'Hat_Ability_Swap':
		case 'Hat_Player_CameraSnap':
		case 'Hat_Player_Jump':
		case 'Hat_Player_Crouch':
		case 'Hat_Player_Ability':
		case 'Hat_Player_Interact':
		case 'Hat_Hotkey_Up': // Taunt
		case 'Hat_Hotkey_Down': // Kiss
		case 'Hat_Hotkey_Left':
		case 'Hat_Hotkey_Right':
		case 'Hat_Player_Share':
		case 'Hat_Player_AbilitySwap':
		case 'Hat_Player_ZoomIn':
		case 'Hat_Player_ZoomOut':
			return true;
		// The pause key (P or Esc or [Insert Console Key here]), I would highly recommend to never override this unless for a specific check!
		case 'Hat_Menu_Start':
			return WithPauseMenu;
		default:
			return false;
	}
}

/*  
* =========================================================================
* Allows you to hide only the components of the body, unlike
* plyr.SetHidden(...); call this ONLY hides the body, this means attachments
* like particles and such aren't affected when doing so.
* -------------------------------------------------------------------------
* @param Hide - Whether to hide the body or not.
* @param plyr - The player we want to do this task on.
* Credits: Shararamosh for "SetOcclusionHidden()"
* =========================================================================
*/
static function SetBodyHidden(bool Hide, Hat_Player plyr)
{
	local Array<MeshComponent> MeshComponents;
	local int i;
	
	MeshComponents = plyr.GetMyMaterialMeshComponents();
	for (i = 0; i < MeshComponents.Length; i++)
		MeshComponents[i].SetHidden(Hide);
    plyr.SetOcclusionHidden(Hide);
}

/*
* =========================================================================
* Returns the local player's Steam ID
* =========================================================================
*/
static function string GetLocalSteamID()
{
	local OnlineSubsystem OnlineSubsystem;
	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if (OnlineSubsystem == None) return "";
	return OnlineSubsystemCommonImpl(OnlineSubsystem).GetUserCommunityID();
}

/*
* =========================================================================
* Returns the local player's Steam Name
* Note: Coop share the same locality name regardless of index
* =========================================================================
*/
static function string GetLocalSteamName()
{
    local OnlineSubsystem OnlineSubsystem;
	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if (OnlineSubsystem == None) return "";
	return OnlineSubsystemCommonImpl(OnlineSubsystem).GetPlayerNicknameFromIndex(0);
}

/*
* =========================================================================
* Returns true if game paused
* =========================================================================
*/
static function bool IsGamePaused()
{
    return Class'WorldInfo'.static.GetWorldInfo().WorldInfo.Pauser != None;
}

/*  
* =========================================================================
* ██   ██ ███████ ███████ ███    ███ ██ ████████ 
* ██  ██  ██      ██      ████  ████ ██    ██    
* █████   █████   ███████ ██ ████ ██ ██    ██    
* ██  ██  ██           ██ ██  ██  ██ ██    ██    
* ██   ██ ███████ ███████ ██      ██ ██    ██    
* =========================================================================
*/

/*  
* =========================================================================
* Do Attach to Actor but in script, this is useful nonetheless due its
* fluidity in comparison to a basic SetBase() call!
* -------------------------------------------------------------------------
* @param Base - The base of the Attachment (such as the player).
* @param Attachment - The attachment (such as a hat).
* @param Action - Additional variables for the Attachment.
* IMPORTANT: SEE CreateAttachToActorAction() IN THIS FILE!!!
* =========================================================================
*/
static function AttachToActor(Actor Base, Actor Attachment, SeqAct_AttachToActor Action)
{
    Base.DoKismetAttachment(Attachment, Action);
}

/*  
* =========================================================================
* Create an action for AttachToActor() to be utilized and passed with
* AttachToActor() that can be found in this script.
* IMPORTANT: See the above function!
* -------------------------------------------------------------------------
* @Returns an Action instance to be utilized and passed into AttachToActor(...)
* @param bDetach - To detach instead of Attaching.
* @param bHardAttach - To hard attach the attachment.
* @param BoneName - Name of the bone when hard attaching, causes the attachment
* to move more specifically to the current bone position and rotation.
* @param bUseRelativeOffset - Enable positional offset when attaching
* @param RelativeOffset - The positional offset.
* @param bUseRelativeRotation - Enable rotational offset when attaching.
* @param RelativeRotation - The rotational offset.
* =========================================================================
*/
static function SeqAct_AttachToActor CreateAttachToActorAction(
    optional bool bDetach = false, 
    optional bool bHardAttach = true, 
    optional Name BoneName,
    optional bool bUseRelativeOffset,
    optional Vector RelativeOffset,
    optional bool bUseRelativeRotation,
    optional Rotator RelativeRotation)
{
    local SeqAct_AttachToActor action;

    action = new Class'SeqAct_AttachToActor';
    action.bDetach = bDetach;
    action.bHardAttach = bHardAttach;
    action.BoneName = BoneName;
    action.bUseRelativeOffset = bUseRelativeOffset;
    action.RelativeOffset = RelativeOffset;
    action.bUseRelativeRotation= bUseRelativeRotation;
    action.RelativeRotation = RelativeRotation;

    return action;
}

/*  
* =========================================================================
* Calls a Remote Event based on the passed name, allowing you to call
* custom based Kismet stuff when it comes to what the Event is linked to.
* -------------------------------------------------------------------------
* @param RemoteEventName - Name of the "Remote Event" in kismet.
* @param InOriginator - Where this call originated (Just pass self)
* @param InInstigator - Who instigated this action? (e.g player, enemy?)
* =========================================================================
*/
static function CallRemoteEvent(Name RemoteEventName, Actor InOriginator, optional Actor InInstigator)
{
    local int i;
    local Sequence GameSeq;
    local array<SequenceObject> AllSeqEvents;

	if(InInstigator == None) InInstigator = InOriginator;
    
    GameSeq = Class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
    if(GameSeq == None) return;

    GameSeq.FindSeqObjectsByClass(class'SeqEvent_RemoteEvent', true, AllSeqEvents);
    for(i=0; i < AllSeqEvents.Length; i++)
    {
        if(SeqEvent_RemoteEvent(AllSeqEvents[i]).EventName != RemoteEventName) continue;
        SequenceEvent(AllSeqEvents[i]).CheckActivate(InOriginator, InInstigator);
    }    
}

/*  
* =========================================================================
* Search all desired Kismet sequences and return them in an array.
* -------------------------------------------------------------------------
* @Returns all Sequences that were found.
* @param SequenceClass - The class of the SequenceObject we are looking for.
* =========================================================================
*/
static function Array<SequenceObject> SearchDesiredSequence(Class<SequenceObject> SequenceClass)
{
    local Array<SequenceObject> AllSeqObjects;

    class'Worldinfo'.static.GetWorldInfo().GetGameSequence().FindSeqObjectsByClass(SequenceClass, true, AllSeqObjects);
    return AllSeqObjects;
}

/*
* =========================================================================
*  ██████  ████████ ██   ██ ███████ ██████  
* ██    ██    ██    ██   ██ ██      ██   ██ 
* ██    ██    ██    ███████ █████   ██████  
* ██    ██    ██    ██   ██ ██      ██   ██ 
*  ██████     ██    ██   ██ ███████ ██   ██ 
* -------------------------------------------------------------------------
* In all honesty cannot figure out where to put these in a category, so I'll
* leave them here.
* =========================================================================
*/

/*  
* =========================================================================
* Transforms a string into a compare arugments
* -------------------------------------------------------------------------
* @Returns true if the comparison passes
* @param a - Argument one.
* @param b - Argument two.
* @param datatype - The datatype expected.
* @param rule - What we are comparing.
* =========================================================================
*/
static function bool CompareVolatile(string a, string b, string datatype, string rule)
{
    switch(rule)
    {
        case "<" :
            switch(datatype)
            {
                case "float": return float(a) < float(b);
                case "int": return int(a) < int(b);
            }
            break;
        case "<=":
            switch(datatype)
            {
                case "float": return float(a) <= float(b);
                case "int": return int(a) <= int(b);
            }
            break;
        case ">" :
            switch(datatype)
            {
                case "float": return float(a) > float(b);
                case "int": return int(a) > int(b);
            }
            break;
        case ">=":
            switch(datatype)
            {
                case "float": return float(a) >= float(b);
                case "int": return int(a) >= int(b);
            }
            break;
        case "!=":
            switch(datatype)
            {
                case "float": return float(a) != float(b);
                case "int": return int(a) != int(b);
                case "string": return a != b;
            }
            break;
        case "==":
            switch(datatype)
            {
                case "float": return float(a) == float(b);
                case "int": return int(a) == int(b);
                case "string": return a == b;
            }
            break;
        case "~=":
            switch(datatype)
            {
                case "string": return a ~= b;
            }
            break;
    }
    return false;
}

/*  
* =========================================================================
* Simplified Material initialization, all you have to do is a pass ANY
* MATERIAL TYPE! Only do this call if you want to do dynamic modification
* such as changing parameters values in the material that you specified.
* Useful for HUDs! Unnecessary if it's gonna be static the whole time!
* -------------------------------------------------------------------------
* @Returns an Instance of the Material to be modified.
* @param Parent - The material we want to initialize 
* =========================================================================
*/
static function MaterialInstanceTimeVarying InitMaterial(MaterialInterface parent)
{
    local MaterialInstanceTimeVarying mitv;
    
    mitv = new class'MaterialInstanceTimeVarying';
    mitv.SetParent(parent);
    
    return mitv;
}

/*  
* =========================================================================
* Create a Button to be utilized for HUD purposes, you need to reference 
* only the texture but you can also save locations and size if you want,
* See "Utils_Button" for more info, the button still needs to be handled
* with mouse positions though this makes it easier to make one.
* -------------------------------------------------------------------------
* @Returns a Struct of data sets for a Button to be used.
* @param Surface - The surface to be passed, can pass MaterialInterace and
* directly initialize for any sort of cool effects.
* @param X/Y - Position of the button on Screen Cords
* @param Width/Height - Vertical and Horizontal sizes respectively.
* @param Title - A Text to be used on top of the button.
* @param Identifier - ID reference used to make it easier to search for the
* button, useful for specific checks.
* =========================================================================
*/
static function Utils_Button 
CreateButton(
    Surface Surface, 
    optional float X = 0.0f, 
    optional float Y = 0.0f, 
    optional float Width = 0.0f, 
    optional float Height = 0.0f, 
    optional coerce String Title = "", 
    optional coerce String Identifier = "")
{
    local Utils_Button iButton;
    
    iButton.Surface = Surface.IsA('MaterialInterface') ? InitMaterial(MaterialInterface(Surface)): Surface;
    iButton.X = X;
    iButton.Y = Y;
    iButton.Width = Width;
    iButton.Height = Height;
    iButton.Title = Title;
    iButton.Identifier = Identifier;
    return iButton;
}
/*
* ======================================================
* Splits a string to serperate chars in a string array.
* ======================================================
*/
static function Array<String> SplitStringToChars(coerce String s)
{
    local int i;
    local Array<String> Chars;
    for (i = 0; i < Len(s); i++) Chars[i] = Mid(s, i, 1);
    return Chars;
}

static function string GetCharAtPos(coerce string s, int i)
{
    return Mid(s, i, 1);
}

/*
* ================================================================
* Similar to Object.Repl(); but replaces only the first occurence.
* ================================================================
*/
static function string ReplOnce(coerce string src, coerce string match, coerce string with, optional int startpos = 0, optional bool caseSensitive = false)
{
    local int pos;
    pos = InStr(src, match, false, !casesensitive, startpos);
    if(pos == INDEX_NONE) return src;
    return Left(src, pos) $ with $ Mid(src, pos + Len(match));
}

/*  
* =========================================================================
* ███    ███  █████  ████████ ██   ██ 
* ████  ████ ██   ██    ██    ██   ██ 
* ██ ████ ██ ███████    ██    ███████ 
* ██  ██  ██ ██   ██    ██    ██   ██ 
* ██      ██ ██   ██    ██    ██   ██ 
* =========================================================================
*/

/*  
* =========================================================================
* Returns a random point in a 2D circle.
* -------------------------------------------------------------------------
* @param Center - The center point of the circle.
* @param Radius - The radius of the circle.
* @param MinRadius - A range smaller than the radius meant to not avoid in
* below that point.
* @param UniformedDistribution - Whether should they be distributed equally
* good to avoid many points being clumped up when too close and very few
* when far away.
* =========================================================================
*/
static function Vector2D RandomPointOnCircle2D(Vector2D Center, float Radius, optional float MinRadius = 0.0f, optional bool UniformedDistribution = false)
{
    local float Theta, R;
    local Vector2D V;

    Theta = FRand() * 2 * Pi;
    // Uniform distrubtion so you don't get a ton of them "too close".
    R = Lerp(MinRadius, Radius, UniformedDistribution ? Sqrt(FRand()) : FRand());
    V.X = R * Sin(Theta);
    V.Y = R * Cos(Theta);
    return Center + V;
}

/*  
* =========================================================================
* Returns a random point in a tilted circle in 3D space.
* Normally (in literal sense) it will behave like a random point on a circle
* facing the ground.
* Useful for getting a random spawn coordination.  
* -------------------------------------------------------------------------
* @param Center - The center point of the circle.
* @param MaxRadius - The radius of the circle.
* @param MinRadius - A range smaller than the radius meant to avoid picking a point
* below this specified value, 0 if you want to fully check the circle.
* @param UniformedDistribution - Whether should they be distributed equally
* good to avoid many points being clumped up when too close and very few
* when far away.
* @param VNormal - The normal direction of the circle. Default is WORLD 
* SPACE X direction. If you want local direction just pass Vector(Rotation)
* where Rotation is the Rotation of the Actor.
* =========================================================================
*/
static function Vector RandomPointOnCircle(Vector Center, float MaxRadius, optional float MinRadius = 0.0f, optional bool UniformedDistribution = false, optional Vector VNormal = Vect(1,0,0))
{
    local float R;
    local Rotator CircleRot;

    // Uniform distrubtion so you don't get a ton of them "too close".
    R = Lerp(MinRadius, MaxRadius, UniformedDistribution ? Sqrt(FRand()) : FRand());
    // Rotation of the circle
    CircleRot = Rotator(VNormal);
    // Unreal specified rotation as 16-Bit value between [0 - 65535] which translates to [0 - 360] in degrees
    CircleRot.Yaw = FRand() * 65535;
    VNormal = Normal(Vector(CircleRot));

    return Center + VNormal * R;
}
/*
* Returns the intensity of the color (0 - 255)
* @param Normalized
*/
static function float GetColorIntensity(Color c, optional bool Normalized = false)
{
    local float tension;

    tension = c.R * 0.299f + c.G * 0.587f + c.B * 0.114f;
    if(Normalized) tension /= 255.0f;
    return tension;
}