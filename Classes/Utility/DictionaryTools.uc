Class DictionaryTools extends Object;
/*
* Example:
*   rawData = "name=sami&age=25&height=1.82&Collected_Super_Awesome_Green_Time_Piece=true"
* 
* Pass into: BuildDictionaryArray();

    local Array<Dictionary> myDictionary;
    myDictionary = Class'DictionaryTools'.static.BuildDictionaryArray(rawData);
*
* result in:
*
    Dictionary(0)=(key="name", value="sami");
    Dictionary(1)=(key="age", value="25");
    Dictionary(2)=(key="height", value="1.82");
    Dictionary(3)=(key="Collected_Super_Awesome_Green_Time_Piece", value="true");
*   
* To extract data from the Dictionary structure call GetValue to get the value as a string, 
* or GetValueT where T represents a type, currently supported: int, float, bool, vector and rotator, see down below for their function names
* Example:
*
    local string myName;
    local int myAge;
    local float myHeight;

    Class'DictionaryTools'.static.GetValue("name", myDictionary, myName);
    Class'DictionaryTools'.static.GetValueInt("age", myDictionary, myAge);
    Class'DictionaryTools'.static.GetValueFloat("height", myDictionary, myHeight);
    `broadcast("Name:" @ myName @ "| Age:" @ myAge @ "| Height:" @ myHeight);
*
* Pro tip:
* All GetValue functions return a true/false, GetValueBool doesn't have an out (not allowed in UnrealScript) so they will return true if valid:
*
    local string extractedValue;
    if(Class'DictionaryTools'.static.GetValue("name", myDictionary, extractedValue))
    {
        // This code here will run ONLY if this value is defined!
        // do stuff...
    }

    // Returns true if: 1) Defined 2) Value ~= "true" 3) Value is larger than 0 (if == 0 then false)
    if(Class'DictionaryTools'.static.GetValueBool("Collected_Super_Awesome_Green_Time_Piece", myDictionary))
    {
        // It passed! Do stuff...
    }
* 
*/

// You can change these to fit your set up.
const AND_PARAMETER = "&";
const KEY_EQUAL = "=";

struct Dictionary
{
    var string key;
    var string value;
};

static function Dictionary Dict(string key, string value)
{
    local Dictionary d;
    d.key = key;
    d.value = value;
    return d; 
}

static function Array<Dictionary> BuildDictionaryArray(string rawData)
{
    local Array<String> dictionaryEntries, dictionaryRes;
    local Array<Dictionary> dictionaries, empty;
    local string de;
    
    empty.Length = 0;
    if(InStr(rawData, AND_PARAMETER) == INDEX_NONE) return empty;
    if(InStr(RawData, KEY_EQUAL) == INDEX_NONE) return empty;
    
    dictionaryEntries = SplitString(rawData, AND_PARAMETER);

    foreach dictionaryEntries(de)
    {
        dictionaryRes = SplitString(de, KEY_EQUAL);
        dictionaries.AddItem(Dict(dictionaryRes[0], dictionaryRes[1]));
    }
    return dictionaries;
}

static function Array<ConversationReplacement> BuildKeyReplacements(Array<Dictionary> map, optional string avoid = "")
{
    local Array<ConversationReplacement> keys;
    local Dictionary d;

    foreach map(d)
        if(avoid == "" || InStr(avoid, d.key, false, true) == INDEX_NONE) 
            Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, d.key, d.value);
            
    return keys;
}

static function bool Empty(Array<Dictionary> d)
{
    return d.Length <= 0;
}

// Returns the string value
static function bool GetValue(out string strRes, Array<Dictionary> d, string key)
{
    local int i;
    i = d.Find('key', key);
    if(i == INDEX_NONE)
    {
        strRes = "";
        return false;
    }
    strRes = d[i].value;
    return true;
}

// Returns the value as a float
static function bool GetValueFloat(out float floatRes, Array<Dictionary> d, string key)
{
    local string res;
    if(!GetValue(res, d, key)) return false;
    floatRes = float(res);
    return true;
}

// Returns the value as an integer
static function bool GetValueInt(out int intRes, Array<Dictionary> d, string key)
{
    local string res;
    if(!GetValue(res, d, key)) return false;
    intRes = int(res);
    return true;
}

// Returns the value as a Vector
static function bool GetValueVector(out Vector vectorRes, Array<Dictionary> d, string xKey, string yKey, string zKey)
{
    local bool x, y, z;
    local float res;

    x = GetValueFloat(res, d, xKey);
    if(x) vectorRes.X = res;
    y = GetValueFloat(res, d, yKey);
    if(y) vectorRes.Y = res;
    z = GetValueFloat(res, d, zKey);
    if(z) vectorRes.Z = res;

    return x || y || z;
}

// Returns the value as a Rotator
static function bool GetValueRotator(out Rotator rotatorRes, Array<Dictionary> d, string pitchKey, string yawKey, string rollKey)
{
    local bool p, y, r;
    local int res;

    p = GetValueInt(res, d, pitchKey);
    if(p) rotatorRes.pitch = res;
    y = GetValueInt(res, d, yawKey);
    if(y) rotatorRes.yaw = res;
    r = GetValueInt(res, d, rollKey);
    if(r) rotatorRes.roll = res;

    return p || y || r;
}

// Returns true if key is defined and has one of the values:
// 1) True
// 2) Bigger than 0
static function bool GetValueBool(Array<Dictionary> d, string key)
{
    local string res;
    if(!GetValue(res, d, key)) return false;
    return (res ~= "true" || float(res) > 0);
}

static function string KeysToDictionaryCommand(Array<ConversationReplacement> keys)
{
    local string s;
    local int i;

    s = "";
    for(i = 0; i < keys.Length; i++) s $= keys[i].Keyword $ KEY_EQUAL $ keys[i].Value $ ( i + 1 >= keys.Length ? "" : AND_PARAMETER);
    return s;
}