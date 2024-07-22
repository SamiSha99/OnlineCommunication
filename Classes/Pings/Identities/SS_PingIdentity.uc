Class SS_PingIdentity extends Object
    abstract;

var Name IdentityName; // AlwaysLoaded will butcher Class.Name, apparently...

static function bool ProcessIdentity(Actor target, out string localizationString, out Array<ConversationReplacement> keys)
{
    if(default.IdentityName == '') return false;
    return target.IsA(default.IdentityName);
}

// This should be Super called and incremented!
static function int GetPriority() { return 0; }
static function Print(coerce string msg) { Class'SS_GameMod_OC'.static.Print(msg); }
static function WorldInfo GetWorldInfo() { return Class'WorldInfo'.static.GetWorldInfo(); }

defaultproperties
{
    IdentityName = "";
}