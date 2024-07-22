Class SS_DynamicString extends Object;

enum DynamicResult
{
    DR_Normal,
    DR_Localize
};

var SS_GameMod_OC GameMod;

function DoDynamicArguments(out string script, optional Array<ConversationReplacement> keys, optional out int nestedLoop)
{
    local int atTag, openTag, endTag, loops;
    local Array<string> conditionals;
    local string argPart, dynamicPart, dynamicRes;
    local DynamicResult dynamicType;
    loops = 0;
    atTag = -1;

    if(nestedLoop >= 10) return; // what the fuck are you doing with localizations to do this?
    if(keys.Length > 0) script = Class'SS_ChatFormatter'.static.ReplaceKeys(script, keys);
    
    while(InStrPeek(script, atTag, "@", atTag) && loops < 25)
    {
        loops++;
        if(!InStrPeek(script, openTag, "{", atTag) || !InStrPeek(script, endTag, "}", openTag)) 
        {
            atTag++;
            continue;
        }
        dynamicPart = Mid(script, atTag, endTag - atTag + 1); // first occurence of @{...}
        argPart = Repl(Repl(dynamicPart, Right(dynamicPart, 1), ""), Left(dynamicPart, 2), ""); // the inside part of @{...}
        conditionals.Length = 0;
        conditionals = SplitString(argPart, "|");
        if(conditionals.Length == 0) conditionals.AddItem(argPart);
        dynamicRes = GetResultFromConditions(conditionals, dynamicType);
        if(dynamicRes == "")
        {
            atTag++;
            continue;
        }
        if(dynamicType == DR_Localize)
        {
            nestedLoop++;
            DoDynamicArguments(dynamicRes, keys, nestedLoop);
        }
        script = Class'OnlineCommunication'.static.ReplOnce(script, dynamicPart, dynamicRes, atTag); // Repl(); replaces all, why is this not a thing?
        atTag += Len(dynamicRes);
    }
}

function string GetResultFromConditions(Array<string> conditions, optional out DynamicResult result)
{
    local string res;
    local int iNum;
    local float fNum;

    res = "";
    result = DR_Normal;

    switch(Class'OnlineCommunication'.static.GetCharAtPos(conditions[0], 0))
    {
        // ~ = storage
        case "~":
            conditions[0] -= "~";
            res = GameMod.ChatSettings.GetSettingString(conditions[0]);
            conditions.Remove(0,1);
            if(conditions.Length <= 0) return res;
            if(!ConditionHas(res, "#"))
            {
                switch(Class'OnlineCommunication'.static.GetCharAtPos(conditions[0], 0))
                {
                    // transforms 0.0000 to 0.00, 0.0 or 0 based on the .X where X is the amount beyond the decinmal, 0 = int, anything else float
                    case ".":
                        conditions[0] -= ".";
                        iNum = int(conditions[0]);
                        if(iNum < 0) return res; // negative format?
                        if(iNum == 0) return string(int(float(res))); // clean up
                        fNum = float(res);
                        res = Left(fNum, InStr(fNum, ".") + 1 + iNum);
                        return res;
                    default:
                        return res;
                }
            }
            // result is a color, format it correctly
            if(ConditionHas(conditions[0], ">"))
            {
                res = "[color=" $ res $ "]" $ DoLocalizationArguments(conditions) $ "[/color]";
                result = DR_Localize;
            }
            else
                res = "[color=" $ res $ "]" $  conditions[0] $ "[/color]";
            return res;
        // # = Steam ID
        case "#":
            conditions[0] -= "#";
            return GetSteamNameWithPersonalColor(conditions[0], conditions[1]);
        // defined key
        case "?":
            break;
        // Return text, localized or not
        default:
            if(!ConditionHas(conditions[0], ">")) return conditions[0];
            res = DoLocalizationArguments(conditions);
            result = DR_Localize;
            return res;
    }    
}

function string GetSteamNameWithPersonalColor(string steamid_subid, optional string extraArgs = "")
{
    local string hexColor, steamName;
    GameMod.ChatSettings.GetColorBySteamID(steamid_subid, hexColor, steamName);
    if(steamName ~= "") return "";
    if(hexColor ~= "") return "";
    return "[color="$hexColor$"]"$steamName$extraArgs$"[/color]";
}

function string DoLocalizationArguments(Array<string> conditions)
{   
    local Array<string> localizationArgs;
    local string locRes;
    localizationArgs = SplitString(conditions[0], ">", true);
    if(localizationArgs.Length != 3) return conditions.Length < 2 ? "" : conditions[1]; // fallback string just in case
    locRes = Localize(localizationArgs[1], localizationArgs[2], localizationArgs[0]);
    if(Class'Hat_Localizer'.static.ContainsErrorString(locRes)) return conditions.Length < 2 ? "" : conditions[1];
    return locRes;
}

function bool ConditionHas(string condition, string startingChar)
{
    return Len(condition) > 0 && Len(startingChar) == 1 && Class'OnlineCommunication'.static.GetCharAtPos(condition, 0) ~= startingChar;
}

function bool InStrPeek(string msg, out int pos, const string compare, optional int startpos = 0)
{
   return Class'SS_ChatFormatter'.static.InStrPeek(msg, pos, compare, startpos);
}