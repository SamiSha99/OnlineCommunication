/*
* This Class manages the identity of all pings.
* When you ping they are iterated through class's name and their parents to find a matching localization key defined under pings.int
* When it finds a valid with no errors localization it will use that as the key to print into the chat
* Identities are hardcoded scripts that requires more complexity to get the ping correct
* These two are in "pings_options.int"
* IgnoreList ignores certain Actors from being pinged or some of their components.
* A MeshClass will use their hit location instead of the location of said mesh/actor, done to make pings reasonably accurate and center to the objects position (e.g pinging a wall in a certain point)
*/
Class SS_Ping_Identifier extends Object;

struct PingLocalizedResult
{
    var string Localization;
    var string section;
    var Actor Actor;
    var Vector PingLocation;
    var bool isHitLocation;
    var Surface IconReference;
    var Array<ConversationReplacement> Keys;
    
    structdefaultproperties
    {
        section = "default"    
    }
};

var Array< Class < SS_PingIdentity > > Identities; // to-do change to an instantiated class on run time to support moddable Identities?

const TRACE_RANGE = 150; // Probably will never make this customizable just in case of abuse
const UNREAL_METER_UNITS = 100;

static function PingLocalizedResult OnPingingTarget(Actor target, Vector pingLocation, optional string sections = "default")
{
    local Class<SS_PingIdentity> id;
    local PingLocalizedResult resultEmpty;
    local Array<ConversationReplacement> keys;
    local int priority, processPriority;
    local Object obj;
    local int i;
    local string localization, key, mainKey, sectionRes;

    if(target == None) return resultEmpty;

    // Ping Support, get the target instead
    if(target.IsA('SS_PingSupport'))
    {
        target = SS_PingSupport(target).PingReference;
    }
    
    // Literal key check with ID
    key = ""$target;
    if(TryToLocalizePing(key, sectionRes, sections)) return CreateLocalizedResult(key, sectionRes, target, pingLocation, keys);
    

    mainKey = Repl(target, "_" $ GetRightMost(target), "", false);
    key = mainKey;
    
    // Possible Hardcoded identity
    priority = -1;
    foreach default.Identities(id)
    {
        keys.Length = 0;
        if(!id.static.ProcessIdentity(target, localization, keys)) continue;
        processPriority = id.static.GetPriority();
        if(processPriority < priority) continue;
        key = localization;
        priority = processPriority;
        break; // eh, maybe better?
    }

    if(TryToLocalizePing(key, sectionRes, sections)) return CreateLocalizedResult(key, sectionRes, target, pingLocation, keys);

    // Maybe the key is defined?
    key = mainKey;
    // Check if it is already defined
    if(TryToLocalizePing(key, sectionRes, sections)) return CreateLocalizedResult(key, sectionRes, target, pingLocation, keys);
    
    // Iterate the ObjectArchetype, see if any is valid
    // maybe one of the key's parents are defined?
    obj = target;
    i = 0;
    do
    {   
        key = i == 0 ? String(obj.default.ObjectArchetype.Class.Name) : String(obj.ObjectArchetype.Class.Name);
        if(TryToLocalizePing(key, sectionRes, sections)) return CreateLocalizedResult(key, sectionRes, target, pingLocation, keys);
        obj = i == 0 ? obj.default.ObjectArchetype : obj.ObjectArchetype;
        i++;
    }
    until(obj.Class == Class'Object' || obj.Class == Class'Actor' || i >= 50); // to infinity™ and break
    
    key = mainKey;
    // no key = no input, in debugging ignore
    if(!TryToLocalizePing(key, sectionRes, sections) && !Class'Engine'.static.IsEditor() && Class'SS_GameMod_PingSystem'.default.ToggleDebugging != 1) key = "";

    return CreateLocalizedResult(key, sectionRes, target, pingLocation, keys);
}

static function bool TryToLocalizePing(string key, out string sectionRes, optional string sections = "default")
{
    return TryToLocalize(key, sectionRes, sections);
}

// Returns true if its a valid localization
// @out localizationRes - The string out result 
static function bool TryToLocalize(string key, out string sectionRes, optional string sections = "???")
{
    local string localizationRes, s;
    local Array<string> sectionArr;
    if(sections == "") return false;
    sectionArr = SplitString(sections, ",", true);
    foreach sectionArr(s)
    {
        Class'SS_ChatFormatter'.static.GetLocalizationLog(key, s, "pings", localizationRes);
        if(Class'Hat_Localizer'.static.ContainsErrorString(localizationRes)) continue;
        sectionRes = s;
        return true;
    }
    sectionRes = "default";
    return false;
}

static function bool TryPing(Hat_PlayerController pc, out PingLocalizedResult result, optional string sections = "default")
{
	local Vector cameraLocation, HitLoc, HitNormal, StartTraceLocation, EndTraceLocation, pingLoc;
	local Rotator cameraRotation;
    local Actor a;
 	local WorldInfo wi;
    local PingLocalizedResult emptyResult;
    local TraceHitInfo HitInfo;
    local Color red, blue, green, yellow;

    wi = Class'WorldInfo'.static.GetWorldInfo();
    red = Class'SS_Color'.static.GetColorByName("Red"); // anything in the red is ignored, happens when green/yellow hits something, also if everything red, we are pinging the air which is nothing
    green = Class'SS_Color'.static.GetColorByName("Green"); // collision trace until it hits a collider
    yellow = Class'SS_Color'.static.GetColorByName("Yellow"); // mesh trace until it hits a mesh
    blue = Class'SS_Color'.static.GetColorByName("azure_blue"); // successful hit point which is then traced to the position that was taken as final

    cameraLocation = pc.PlayerCamera.ViewTarget.POV.Location;
    cameraRotation = pc.PlayerCamera.ViewTarget.POV.Rotation;

    // Start the trace somewhere above the player's head
    // This means the ping won't hit anything between the player and the camera, this is good.
    StartTraceLocation = pc.InCamMode ? cameraLocation : Class'Hat_Math'.static.ClosestPointsOnTwoLines(cameraLocation, Vector(cameraRotation), pc.Pawn.Location, vect(0,0,1));
    EndTraceLocation =  StartTraceLocation + Normal(Vector(cameraRotation)) * TRACE_RANGE * UNREAL_METER_UNITS;
   
    wi.FlushPersistentDebugLines();
    Debug_DrawLines(0.1f, 0.7f, StartTraceLocation, EndTraceLocation, red);
    
    Class'SS_GameMod_PingSystem'.static.Print("Possible Sections:" @ sections);

    Class'SS_GameMod_PingSystem'.static.Print("=== TRACE 1 | INTERSECT BLOCKING MESH ===");
    // first trace hits polygons and line of sight
    foreach pc.Pawn.TraceActors(Class'Actor', a, HitLoc, HitNormal, EndTraceLocation, StartTraceLocation,, HitInfo, wi.TRACEFLAG_Blocking)
    {
        if(ShouldIgnore(a, HitInfo)) continue;
        result = OnPingingTarget(a, HitLoc, sections);
        pingLoc = result.PingLocation;
        EndTraceLocation = pingLoc + Normal(Vector(cameraRotation)) * 10;
        
        Debug_DrawLines(0.7f, 1.3f, StartTraceLocation, (IsZero(HitLoc) ? EndTraceLocation : (HitLoc + Normal(Vector(cameraRotation)) * 10)), yellow);
        break;
    }

    if(result != emptyResult && !result.isHitLocation)
    {
        Debug_DrawSphere(1.3f, 3.1f, HitLoc, blue);
        Debug_DrawLines(1.3f, 1.9f, HitLoc, pingLoc, blue);
        return true;
    }

    Class'SS_GameMod_PingSystem'.static.Print("=== TRACE 2 | INTERSECT BLOCKING/TOUCH COLLIDER ===");
    // second trace does a collision checks in the line to not casually ping meshes for accuracy
    foreach pc.Pawn.TraceActors(Class'Actor', a, HitLoc, HitNormal, EndTraceLocation, StartTraceLocation,, HitInfo)
    {
        if(ShouldIgnore(a, HitInfo)) continue;
        result = OnPingingTarget(a, HitLoc, sections);
        pingLoc = result.PingLocation;

        if(pingLoc == a.Location)
        {
            Debug_DrawSphere(1.3f, 3.1f, HitLoc, blue);
            Debug_DrawLines(1.3f, 1.9f, HitLoc, pingLoc, blue);
        }
        Debug_DrawLines(1.3f, 1.9f, StartTraceLocation, IsZero(HitLoc) ? pingLoc : HitLoc, green);
        break;
    }

    if(result != emptyResult && !result.isHitLocation)
    {
        Debug_DrawSphere(1.3f, 3.1f, HitLoc, blue);
        Debug_DrawLines(1.3f, 1.9f, HitLoc, pingLoc, blue);
        return true;
    }

    return result != emptyResult;
}

static function PingLocalizedResult CreateLocalizedResult(string localization, string section, Actor actor, Vector pingLocation, Array<ConversationReplacement> keys)
{
    local string key;
    local int i;
    local PingLocalizedResult inst;
    local Object obj;

    inst.Localization = localization;
    inst.section = section;
    inst.Actor = actor;
    
    inst.PingLocation = actor.Location;
    i = 0;
    obj = actor;
    key = Repl(actor, "_" $ GetRightMost(actor), "", false);
    Class'SS_GameMod_PingSystem'.static.Print("First MeshClass Check [" $ 0 $ "] | Key =>" @ key @ "| Object =>" @ obj);
    do
    {   
        if(PingHasOption("Mesh", key, localization)) 
        {
            if(localization ~= "none") break;
            inst.PingLocation = pingLocation;
            inst.isHitLocation = true;
            break;
        }
        key = i == 0 ? String(obj.default.ObjectArchetype.Class.Name) : String(obj.ObjectArchetype.Class.Name);
        obj = i == 0 ? obj.default.ObjectArchetype : obj.ObjectArchetype;
        i++;
        Class'SS_GameMod_PingSystem'.static.Print("Next MeshClass Check [" $ i $ "] | Key =>" @ key @ "| Object =>" @ obj);
    }
    until(obj.Class == Class'Object' || obj.Class == Class'Actor' || i >= 50); // to infinity™ and break
    
    inst.keys = keys;
    return inst;
}

static function bool ShouldIgnore(Actor a, TraceHitInfo hitinfo)
{
    local int i;
    local string key, localization;
    local Object obj;
    local Array<string> splits;
    local Array<string> ignoreComponents;

    if(a == None) return true;
    if(a.bHidden || a.bDeleteMe) return true;
    //to-do check this, maybe bug?
    if(a.IsA('SS_PingSupport') && !SS_PingSupport(a).IsValid()) return true;

    i = 0;
    obj = a;
    key = Repl(a, "_" $ GetRightMost(a), "", false);
    do
    { 
        if(PingHasOption("Ignore", key, localization))
        {
            if(localization ~= "none") return true;
            if(InStr(localization, "->") == INDEX_NONE) return true; // no specific compoenents being ignored

            splits = SplitString(localization, "->", true);
            
            if(InStr(splits[1], ",") != INDEX_NONE)
                ignoreComponents = SplitString(splits[1], ",");
            else
                ignoreComponents[0] = splits[1];
            // Check if its on the ignore list, then don't ping this part and keep going.
            return ignoreComponents.Find(""$hitinfo.HitComponent.TemplateName) != INDEX_NONE;
        }
        key = i == 0 ? String(obj.default.ObjectArchetype.Class.Name) : String(obj.ObjectArchetype.Class.Name);
        obj = i == 0 ? obj.default.ObjectArchetype : obj.ObjectArchetype;
        i++;
    }
    until(obj.Class == Class'Object' || obj.Class == Class'Actor' || i >= 50); // to infinity™ and break

    return false;
}

static function bool PingHasOption(string section, string key, optional out string result)
{
    result = Localize(section, key, "pings_options");
    return !Class'Hat_Localizer'.static.ContainsErrorString(result);
}

static function Debug_DrawSphere(float minRad, float maxRad, Vector center, Color c, optional float increaseRate = 0.1f)
{
    local WorldInfo wi;
    local float radius;
    if(Class'SS_GameMod_PingSystem'.default.ToggleDebugging == 0) return;
    wi = Class'WorldInfo'.static.GetWorldInfo();
    for(radius = minRad; radius < maxRad; radius += increaseRate)
        wi.DrawDebugSphere(center, radius, 8, c.R, c.G, c.B, true);
}

static function Debug_DrawLines(float minRad, float maxRad, Vector start, Vector end, Color c, optional float increaseRate = 0.1f)
{
    local WorldInfo wi;
    local float radius;
    if(Class'SS_GameMod_PingSystem'.default.ToggleDebugging == 0) return;
    wi = Class'WorldInfo'.static.GetWorldInfo();
    for(radius = minRad; radius < maxRad; radius += increaseRate)
        wi.DrawDebugCylinder(start, end, radius, 8, c.R, c.G, c.B, true);
}

static function Debug_DrawBox(float thickMin, float thickMax, Vector center, Vector extent, Color c, optional float increaseRate = 0.1f)
{
    local WorldInfo wi;
    local float radius;
    local Vector e;
    if(Class'SS_GameMod_PingSystem'.default.ToggleDebugging == 0) return;
    wi = Class'WorldInfo'.static.GetWorldInfo();
    e = extent;
    e /= 20.0f;
    for(radius = thickMin; radius < thickMax; radius += increaseRate)
    {
        wi.DrawDebugBox(center, extent + e*radius, c.R, c.G, c.B, true);
    }
}

defaultproperties
{
    Identities.Add(Class'SS_PingIdentity_GhostPlayer');
    Identities.Add(Class'SS_PingIdentity_Collectible_ConductorToken'); // Also for DJ Grooves
    Identities.Add(Class'SS_PingIdentity_ActSelector'); //This I am 100% sure it does support modded act selectors, hopefully
    Identities.Add(Class'SS_PingIdentity_RiftPortal'); // This I am 100% sure it doesn't support modded rifts
    Identities.Add(Class'SS_PingIdentity_SnatcherMinion_Mail'); // you got mail
    Identities.Add(Class'SS_PingIdentity_MetroGate'); // ticket pass
}
