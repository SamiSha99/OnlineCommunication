Class SS_ChatFormatter extends Object
    dependsOn(SS_Color);
    
struct ChatLogSegment
{
    var string Text;
    var Surface Icon;
    var Color Color;
    var bool AddSpace;
    var Array<Dictionary> Formats; // List of formats to flavor text!
    structdefaultproperties
    {
        AddSpace = true;
    }
};

struct IconData
{
    var name iconName;
    var Surface icon;
};

var Array<IconData> IconList;

struct OnlineChatLogInfo
{
    var String RawText;
    var Color Color; // Main color
    var Array<ChatLogSegment> Segments;
    var float lifetime;
    var float shake; // When the message is updated or merged with a duplicate
    var bool isNewLine; // Only true when this log is required to linebreak due to limits
    var int Combo; // How many times this message was casted by the **same** exact user (stops chat log spam)
    structdefaultproperties
    {
        Color = (R=255, G=255, B=255);
        lifetime = 5;
        Combo = 1;
    }
};

struct ChatSettings
{
    var Vector2D ChatPosClipped;
    var Font f;
    var bool forceVisiblity; // When mini Editor is enabled
    var bool topToBottomRender;
    var float clippedLimit;
    var int ChatLimitRender;
    structdefaultproperties
    {
        forceVisiblity = true;
    }
};

const CHAT_ICON_SIZE = 100;
// close enough range but still slightly off, sometimes???
const CHAR_SIZE = 6.0f;
const SPACE_SIZE = 12.0f;

var Array<string> punctuations;

static function OnlineChatLogInfo BuildChatLog(string msg)
{
    local OnlineChatLogInfo l;
    local Array<ChatLogSegment> parseResult; 
    local int i, u;

    l.RawText = msg;
    l.Segments[0] = CreateSegment(l.RawText);
    
    for(i = 0; i < l.Segments.Length; i++)
    {
        if(!Parse(l.Segments[i], parseResult)) continue;
        l.Segments.Remove(i, 1);
        for(u = parseResult.Length - 1; u >= 0; u--) l.Segments.InsertItem(i, parseResult[u]);
        i--;
    }
    return l;
}

static function bool GetLocalizationLog(coerce string key, coerce string section, coerce string filename, out coerce string scriptResult)
{
    scriptResult = Localize(section, key, filename);
    return Class'Engine'.static.IsEditor() || Class'SS_GameMod_PingSystem'.default.ToggleDebugging == 1 || scriptResult != "" && !Class'Hat_Localizer'.static.ContainsErrorString(scriptResult);
}

static function AddKeywordReplacement(out Array<ConversationReplacement> Keywords, coerce string keyword, coerce string value, optional bool PreTranslation)
{
	local ConversationReplacement cr;
	local int i;
	
	for (i = Keywords.Length-1; i >= 0; i--)
	{
		if (Keywords[i].Keyword != keyword) continue;
		Keywords.Remove(i,1);
	}
	
	cr.Keyword = keyword;
	cr.Value = value;
	cr.PreTranslation = PreTranslation;
	Keywords.AddItem(cr);
}

static function string ReplaceKeys(string src, Array<ConversationReplacement> keys, optional int startingPos = 0)
{   
    local ConversationReplacement k;
    foreach keys(k) src = ReplaceKey(src, k, startingPos); //Repl(src, "["$k.keyword$"]", k.value, false);
    return src;
}

// starting pos to skip some replacement, just in case
static function string ReplaceKey(string src, ConversationReplacement k, optional int startingPos = 0)
{
    local int keywordPos, closingBracketPos, keywordLength;
    local string delimiter;
    local string extra;
    local string dynamicArg;
    
    delimiter = "";
    extra = "";
    // keys with $ or @ have extras added, @ adds an extra space, supports only one!!!
    keywordPos = InStr(src, k.keyword);
    keywordLength = Len(k.keyword);

    if(Class'OnlineCommunication'.static.GetCharAtPos(src, keywordPos - 1) ~= "[")
        delimiter = Class'OnlineCommunication'.static.GetCharAtPos(src, keywordPos + keywordLength);
    
    if(delimiter != "" && (delimiter ~= "$" || delimiter ~= "@") && InStrPeek(src, closingBracketPos, "]", keywordPos + keywordLength))
    {
        extra = Mid(src, keywordPos + keywordLength + 1, closingBracketPos-(keywordPos + keywordLength) - 1);
        if(delimiter ~= "@") extra = "" @ extra;
    }
    else
        delimiter = "";

    if(k.keyword ~= "owner" || k.keyword ~= "other")
    {
        dynamicArg = "@{#"$k.value$"|"$extra$"}";
        src = Repl(src, "["$k.keyword$delimiter$extra$"]", dynamicArg, true);
        return src;
    }

    src = Repl(src, "["$k.keyword$delimiter$extra$"]", k.value $ extra, true);
    return src;
}

static function bool Parse(ChatLogSegment segment, out Array<ChatLogSegment> segments)
{
    local int start, end, i;
    local string msg, tag;

    msg = segment.Text;
    segments.Length = 0;

    while(i < 50)
    {
        tag = GetTag(msg, start);
        if(!FindSegmentCutPoints(msg, start, end, tag))
        {
            i++;
            continue;
        }
        segments = CutSegments(segment, start, end, tag);
        break;
    }
    
    return Segments.length > 0;
}

static function bool FindSegmentCutPoints(string msg, out int start, out int end, string compare)
{
    local string compareBreak, rawTag;

    rawTag = compare;
    compare = "["$compare$"]";
    start = -1;
    end = -1;

    InStrPeek(msg, start, compare, start);

    if(InStr(rawTag, "color=", false, true) != INDEX_NONE && class'SS_Color'.static.IsValidColor(Repl(rawTag, "color=", "")))
    {
        compareBreak = "[/color]";
    }
    else if(InStr(rawTag, "icon=", false, true) != INDEX_NONE)
    {
        if(GetIconByName(Repl(rawTag, "icon=", "", false)) == None) return false;
        end = start + Len(compare);
        return true;
    }

    if(start == INDEX_NONE)
    {
        end = INDEX_NONE;
        return false;
    }
    
    end = GetCorrectBreakPointPos(msg, start+1, "[color=", compareBreak);
    
    if(!IsValidTag(rawTag))
    {
        start += Len(compare) + 1;
        return false;
    }
    return true;
}

static function Array<ChatLogSegment> CutSegments(ChatLogSegment segment, int cutpoint1, int cutpoint2, string compare, optional bool noclose = false)
{
    local Array<ChatLogSegment> segs;
    local ChatLogSegment midSeg;
    local string leftMsg, midMsg, rightMsg, msg, parameterIcon, parameterText;
    local int i;

    msg = segment.text;

    // if cutpoint is 0, its left leaning
    if(cutpoint1 != 0)
    {
        leftMsg = Left(msg, cutpoint1);
        if(leftMsg != "")
            segs.AddItem(CreateSegment(leftMsg,,segment.Color));
    }

    if(InStrPeek(compare, i, "icon="))
    {
        noclose = true;
        parameterIcon = Repl(compare, "icon=", "", false);
        if(InStrPeek(parameterIcon, i, "|"))
        {
            parameterText = Repl(parameterIcon, Left(parameterIcon, i+1), "", false);
            parameterIcon = Left(parameterIcon, i);
        }
        midSeg = CreateSegment(parameterText, GetIconByName(parameterIcon));
    }
    else
    {
        midMsg = Mid(msg, cutpoint1 + Len("["$compare$"]"), cutpoint2 - cutpoint1 - Len("["$compare$"]"));
        midSeg = CreateSegment(midMsg, None, GetColorByName(Repl(compare, "color=", "", false)));
    }

    segs.AddItem(midSeg);

    // if cutpoint2 is -1 its right leaning
    // Only supports two formats, hardcoding "[/color]"
    if(cutpoint2 != INDEX_NONE)
    {
        rightMsg = Right(msg, Len(msg) - cutpoint2 - (noclose ? 0 : Len("[/color]")));
        if(rightMsg != "")
            segs.AddItem(CreateSegment(rightMsg,,segment.Color));
    }

    return segs;
}

static function ChatLogSegment CreateSegment(string text, optional Surface icon, optional Color c = MakeColor(255,255,255))
{
    local ChatLogSegment dummy;
    dummy.Text = text;
    dummy.Icon = icon;
    dummy.Color = c;
    dummy.AddSpace = false;
    return dummy;
}

// Push to position via pos
// pos = -1 cannot find, also returns false if so
static function bool InStrPeek(string msg, out int pos, const string compare, optional int startpos = 0)
{
    pos = InStr(msg, compare, false, true, Max(startpos, 0));
    return pos != INDEX_NONE;
}

// iterates each hit for a start and end tag
// finding a start tag results in increasing the stackstate by 1
// finding an end tag results in decreasing the stackstate by 1
// If we reach 0, we found our end tag position under "formatEndPoint"
// Returns postion of the matching closing tag, returns -1 if it couldn't find it
static function int GetCorrectBreakPointPos(string msg, int startpos, string formatstart, string formatend)
{
    local int stackstate, retries, formatStartPoint, formatEndPoint;
    const MAX_RETRIES = 200;
    
    stackstate = 1;

    while(stackState > 0 && retries < MAX_RETRIES)
    {
        InStrPeek(msg, formatStartPoint, formatstart, startpos);
        InStrPeek(msg, formatEndPoint, formatend,   startpos);

        if(formatEndPoint == INDEX_NONE) break;
        
        if(formatEndPoint < formatStartPoint || formatStartPoint == INDEX_NONE)
        {
            stackState--;
            startPos = formatEndPoint+1;
        }
        else if(formatStartPoint < formatEndPoint && formatStartPoint != INDEX_NONE)
        {
            stackState++;
            startPos = formatStartPoint+1;
        }
        else
            retries++;
    }

    if(retries >= MAX_RETRIES)
    {
        Print("[CHAT FORMATTER] THE CHAT FORMATER FAILED!!! PLEASE REPORT TO THE MOD CREATOR IMMEDIATELY!!");
        Print("[CHAT FORMATTER] FAILURE OCCURED ON THIS:" @ msg);
    }
    return stackState > 0 ? INDEX_NONE : formatEndPoint;
}

static function Color GetColorByName(optional string n = "White") 
{
    if(InStr(n, "#") != INDEX_NONE) return Class'SS_Color'.static.Hex(n);
    return Class'SS_Color'.static.GetColorByName(n); 
}

static function Surface GetIconByName(coerce string n)
{
    local int i;
    local Surface s;
    i = default.IconList.Find('iconName', Name(n));
    if(i != INDEX_NONE) return default.IconList[i].icon;
    s = Surface(DynamicLoadObject(n, Class'Surface', true));
    return s;
}

static function bool IsValidTag(coerce string tag)
{
    if(InStr(tag, "icon=", false, true) != INDEX_NONE) return true;
    if(InStr(tag, "color=", false, true) != INDEX_NONE) return true;
    return false;
}

static function string GetTag(coerce string msg, out int start)
{
    local int tagbegin, tagend;
    InStrPeek(msg, tagbegin, "[", start);
    InStrPeek(msg, tagend, "]", start);
    return Mid(msg, tagbegin + 1, tagend - tagbegin - 1);
}
// #################
// # CHAT RENDERER #
// #################
static function DrawChat(HUD H, Array<OnlineChatLogInfo> chatRender, float scale, ChatSettings settings)
{
    local float x, clipX, clipY, textSize, iconSize, textPosY;
    local String msg;
    local int chatOpacity, i, u;
    local float SegmentXLength, SegmentYLength, lineOffsetMultiplier;
    local ChatLogSegment currentSegment;
    local Array<OnlineChatLogInfo> chatRenderReversed;
    local bool hasImage;
    local Font extractedFont;
    clipX = H.Canvas.ClipX;
    clipY = H.Canvas.ClipY;
    
    iconSize = CHAT_ICON_SIZE * scale;
    
    extractedFont = GetFontByLanguageCode();
    
    H.Canvas.Font = extractedFont;

    chatRender = AdjustChatLog(H, chatRender, scale, settings);
    
    if(settings.topToBottomRender)
    {
        for(i = chatRender.Length - 1; i >= 0; i--) chatRenderReversed.AddItem(chatRender[i]);
        chatRender = chatRenderReversed;
    }

    textPosY = clipY * settings.ChatPosClipped.Y;
    
    for(i = 0; i < Min(settings.ChatLimitRender, chatRender.Length); i++) 
    {
        chatOpacity = GetChatOpacity(chatRender[i], settings.forceVisiblity);
        Class'SS_Color'.static.SetDrawColor(H, chatRender[i].Color.R, chatRender[i].Color.G, chatRender[i].Color.B, chatOpacity);
        textSize =  0.75f * scale * GetCorrectFontScale(chatRender[i].RawText, settings.f);
        x = 0;
        SegmentXLength = 0;
        hasImage = false;
        for(u = 0; u < chatRender[i].Segments.Length; u++)
        {
            currentSegment = chatRender[i].Segments[u];
            msg = currentSegment.Text;
            if(SegmentIsEmpty(currentSegment)) continue;

            Class'SS_Color'.static.SetDrawColor(H, currentSegment.Color.R, currentSegment.Color.G, currentSegment.Color.B, chatOpacity);

            //H.Canvas.Font = GetChatFont(msg);
            if(currentSegment.Icon != None)
            {
                hasImage = true;
                if(chatOpacity > 0)
                    Class'Hat_HUDElement'.static.DrawCenter(H, chatRender[i].shake * RandRange(-1,1) + iconSize/2 + x + clipX * settings.ChatPosClipped.X + 6 * scale, textPosY + chatRender[i].shake * RandRange(-1,1) - 1*iconSize/8, iconSize, iconSize, currentSegment.Icon);
                if(!(currentSegment.Text ~= "")) Class'Hat_HUDElement'.static.DrawBorderedText(H.Canvas, currentSegment.Text, chatRender[i].shake * RandRange(-1,1) + clipX * settings.ChatPosClipped.X + iconSize/2 + x + (currentSegment.AddSpace ? SPACE_SIZE : CHAR_SIZE) * scale, textPosY + 2*iconSize/8 + chatRender[i].shake * RandRange(-1,1), textSize * 0.6f, false, TextAlign_Center, 0.5f, 4.0f/GetCorrectFontScale(msg, settings.f));
                x += iconSize + 6 * scale * 2;
            }
            else
            {
                H.Canvas.TextSize(msg, SegmentXLength, SegmentYLength, textSize, textSize);
                if(extractedFont == None)
                    H.Canvas.Font = Class'Hat_FontInfo'.static.GetDefaultFont(msg);
                Class'Hat_HUDElement'.static.DrawBorderedText(H.Canvas, msg, chatRender[i].shake * RandRange(-1,1) + clipX * settings.ChatPosClipped.X + x, textPosY + chatRender[i].shake * RandRange(-1,1), textSize, false, TextAlign_Left, 0.5f, 4.0f/GetCorrectFontScale(msg, settings.f));
                x += SegmentXLength + (currentSegment.AddSpace ? SPACE_SIZE : CHAR_SIZE) * scale;
            }
        }
        if(chatRender[i].Combo > 1)
        {
            msg = " (x"$chatRender[i].Combo$ (chatRender[i].Combo >= 10 ? "..." : "") $")";
            if(extractedFont == None)
                H.Canvas.Font = Class'Hat_FontInfo'.static.GetDefaultFont(msg);
            Class'Hat_HUDElement'.static.DrawBorderedText(H.Canvas, msg, chatRender[i].shake * RandRange(-1,1) + clipX * settings.ChatPosClipped.X + x, textPosY + chatRender[i].shake * RandRange(-1,1), textSize, false, TextAlign_Left, 0.5f, 4.0f/GetCorrectFontScale(msg, settings.f));
        }
        lineOffsetMultiplier = 1.0f;
        if(chatRender[i].isNewLine && !hasImage && !settings.topToBottomRender) lineOffsetMultiplier = 0.7f;
        if(settings.topToBottomRender)
            textPosY += hasImage ? FMax(clipY * 0.0625f * scale * lineOffsetMultiplier, iconSize) : (clipY * 0.06f * scale * lineOffsetMultiplier);
        else
            textPosY -= hasImage ? FMax(clipY * 0.0625f * scale * lineOffsetMultiplier, iconSize) : (clipY * 0.06f * scale * lineOffsetMultiplier);
    }
}

static function Array<OnlineChatLogInfo> AdjustChatLog(HUD H, Array<OnlineChatLogInfo> chatRender, float scale, optional ChatSettings settings)
{
    local int i, u, j;
    local ChatLogSegment newSegment, currentSegment, empty;
    local Array<ChatLogSegment> movedSegments;
    local OnlineChatLogInfo newChatLog;
    local float SegmentXLength, SegmentYLength, TotalRowXLength;
    local float textSize, iconSize;
    local bool currentSegmentEmpty;

    iconSize = CHAT_ICON_SIZE * scale;
    
    for(i = chatRender.Length - 1; i >= 0 ; i--)
    {
        newSegment = empty;
        currentSegment = empty;
        textSize =  0.75f * scale * GetCorrectFontScale(chatRender[i].RawText,settings.f);
        movedSegments.Length = 0;
        TotalRowXLength = 0;
        SegmentXLength = 0;
        for(u = 0; u < chatRender[i].Segments.Length; u++)
        {
            currentSegment = chatRender[i].Segments[u];
            // get the segment length
            if(currentSegment.Icon != None)
                SegmentXLength = iconSize + (currentSegment.AddSpace ? SPACE_SIZE : CHAR_SIZE) * scale;
            else
                H.Canvas.TextSize(currentSegment.Text, SegmentXLength, SegmentYLength, textSize, textSize);
            
            // Break text, else force a new line
            // If true, we prepare a chat log and push it to this exact chatRender position
            if(!ShouldBreakLine(H, TotalRowXLength, SegmentXLength, settings.clippedLimit))
            {
                TotalRowXLength += SegmentXLength + (currentSegment.AddSpace ? SPACE_SIZE : CHAR_SIZE) * scale;
                continue;
            }

            // Try breaking this segment if possible (icons are ignored and moved to the next line)
            if(currentSegment.Icon == None)
            {
                newSegment = BreakSegment(H, TotalRowXLength, textSize, currentSegment, settings.clippedLimit, scale);
                if(!SegmentIsEmpty(newSegment)) movedSegments.AddItem(newSegment);
            }

            for(j = u + 1; j < chatRender[i].Segments.Length; j++) movedSegments.AddItem(chatRender[i].Segments[j]);
            
            // Adjust old segments
            currentSegmentEmpty = SegmentIsEmpty(currentSegment);
            if(!currentSegmentEmpty) chatRender[i].Segments[u].Text = currentSegment.Text;
            chatRender[i].Segments.Length = (currentSegmentEmpty ? u : (u + 1));
            if(movedSegments.Length > 0)
            {
                newChatLog = CreateNewLineChatLog(chatRender[i], movedSegments);
                chatRender[i].Combo = 0; // so it doesn't render on this line, render on the lowest one!
                chatRender.InsertItem(i, newChatLog);
                i++; // move to the new chat log 
            }
            break;    
        }
    }
    return chatRender;
}

// reinstate the segment accordingly
static function ChatLogSegment BreakSegment(HUD H, float TotalRowLength, float textSize, out ChatLogSegment segment, float clippedLimit, optional float scale)
{
    local Array<String> words, chars;
    local string textMerge, newSegmentText, wordMerge;
    local float SegmentXLength, SegmentYLength;
    local ChatLogSegment newSegment;
    
    words = SplitString(segment.Text, " ", false);
    
    // French support for " ?" and " !"
    if(words[0] ~= "" && words.Length > 1 && "FRA" ~= Class'Object'.static.GetLanguage())
    {
        words.Remove(0,1);
        words[0] = " " $ words[0];
    }
    
    textMerge $= words[0];
    
    // Limit this action for 4 or less for now
    if(words.Length <= 1 && Len(textMerge) <= 4 && IsPunctuationChar(textMerge)) return newSegment;

    H.Canvas.TextSize(textMerge, SegmentXLength, SegmentYLength, textSize, textSize);
    
    // cut words that are longer than the limit!
    if(words.Length <= 1 && ShouldBreakLine(H, TotalRowLength, SegmentXLength, clippedLimit)) 
    {
        chars = Class'OnlineCommunication'.static.SplitStringToChars(words[0]);
        wordMerge = "";
        while(chars.Length > 0)
        {
            H.Canvas.TextSize(wordMerge $ chars[0], SegmentXLength, SegmentYLength, textSize, textSize);
            if((chars.Length <= 0 || ShouldBreakLine(H, TotalRowLength, SegmentXLength, clippedLimit))) break;
            wordMerge $= chars[0];
            chars.Remove(0, 1);
        }
        
        JoinArray(chars, newSegmentText, "", false);
        newSegment.Color = segment.Color;
        newSegment.Text = newSegmentText;
        segment.Text = wordMerge; // maybe a "-"?
        return newSegment;
    }

    words.Remove(0, 1);

    if(words.Length <= 0) if(IsPunctuationChar(textMerge)) return newSegment;
    
    // i = 1;
    while(words.Length > 0)
    {
        H.Canvas.TextSize(textMerge @ words[0], SegmentXLength, SegmentYLength, textSize, textSize);
        if((words.Length <= 0 || ShouldBreakLine(H, TotalRowLength, SegmentXLength, clippedLimit))) break; // we found our new break
        textMerge @= words[0];
        // i++;
        words.Remove(0, 1);
    }

    JoinArray(words, newSegmentText, " ", false);
    newSegment.Color = segment.Color;
    newSegment.Text = newSegmentText;
    if(!segment.AddSpace)
    {
        newSegment.AddSpace = segment.AddSpace;
        segment.AddSpace = true;
    }
    segment.Text = textMerge;
    return newSegment;
}

static function OnlineChatLogInfo CreateNewLineChatLog(OnlineChatLogInfo oldLog, Array<ChatLogSegment> Segments)
{
    local OnlineChatLogInfo log;
    log = oldLog;
    log.Color = oldLog.Color;
    log.Segments = Segments;
    log.isNewLine = true;
    log.shake = oldlog.shake;
    return log;
}

static function bool ShouldBreakLine(HUD H, float totalLength, float segmentlength, optional float setLimit = 0.25f)
{
    return totalLength + segmentlength >= setLimit * H.Canvas.ClipX;
}

static function bool SegmentIsEmpty(ChatLogSegment segment)
{
    return segment.Icon == None && Len(segment.Text) <= 0;
}

static function AddStartOfLogIndicator(out OnlineChatLogInfo loginfo, optional Hat_GhostPartyPlayerStateBase Sender = None)
{
    local ChatLogSegment startingLine;
    switch(Class'SS_CommunicationSettings'.default.StartingLineType)
    {
        case 1:
            break;
        case 0:
            startingLine.Text = "*";
            startingLine.Color = loginfo.Segments[0].Color;
            loginfo.Segments.InsertItem(0, startingLine);
            break;
        default:
            break;
    }

    if(Class'SS_CommunicationSettings'.default.StartingLineType != 0) return;

    // Adds the * at the beginning to help the player know where each log starts at!
    
}

static function bool IsPunctuationChar(string check)
{   
    local string s;

    foreach default.punctuations(s)
    {
        if(InStr(check, s) != INDEX_NONE) return true;
    }
    return false;
}

static function int GetChatOpacity(OnlineChatLogInfo log, bool forceVisiblity)
{
    local float maxOpacity;
    if(forceVisiblity) return 255;
    maxOpacity = 1.0f;
    return Round(255.0f * Lerp(0.0f, maxOpacity, FMin(log.lifetime, 1.0f)));
}

static function float GetCorrectFontScale(string msg, Font f)
{
    if(f == None) return 1.0f;
    return Class'Hat_FontInfo'.static.GetDefaultFont(msg).GetMaxCharHeight()/f.GetMaxCharHeight();
}

static function Font GetFontByLanguageCode()
{
    local string code;
    code = Class'Object'.static.GetLanguage();
    switch(caps(code))
    {
        case "KOR": return Font'HatInTime_Fonts.Unicode.DefaultFontKO';
        case "JPN": return Font'HatInTime_Fonts.Unicode.DefaultFontJP';
        case "CHN": return Font'HatInTime_Fonts.Unicode.DefaultFontCHN';
        case "RUS": return Font'HatInTime_Fonts.Unicode.DefaultFontRU';
        case "INT": case"ENG": return Font'HatInTime_Fonts.CurseCasual.CurseCasualBig';
        default:    return None; //Font'HatInTime_Fonts.CurseCasual.CurseCasualBig';
    }
}

static function Print(coerce string msg)
{
    Class'OnlineCommunication'.static.Print(msg);
}

defaultproperties
{
    IconList(0) = (iconName = "timepiece", icon = Texture2D'HatInTime_Hud.Textures.Collectibles.collectible_timepiece');
    IconList(1) = (iconName = "rift", icon = Texture2D'HatInTime_HUB_Decorations.DreamBubble.Textures.DreamBubble');

    IconList(2) = (iconName = "ticket_gold", icon = Texture2D'HatInTime_Hud_Loadout.Item_Icons.itemicon_mafia_code_yellow');
    IconList(3) = (iconName = "ticket_red", icon = Texture2D'HatInTime_Hud_Loadout.Item_Icons.itemicon_mafia_code_red');
    IconList(4) = (iconName = "ticket_green", icon = Texture2D'HatInTime_Hud_Loadout.Item_Icons.itemicon_mafia_code_green');
    IconList(5) = (iconName = "ticket_blue", icon = Texture2D'HatInTime_Hud_Loadout.Item_Icons.itemicon_mafia_code_blue');
    
    IconList(6) = (iconName = "fire", icon = Texture2D'HatInTime_Hud.Textures.flame');
    IconList(7) = (iconName = "water", icon = Texture2D'HatInTime_Hud_DeathWish.Waterdrop_Icon');

    IconList(8) = (iconName = "token_conductor", icon = Texture2D'HatinTime_SFX_Highscore.Textures.token_conductor');
    IconList(9) = (iconName = "token_dj", icon = Texture2D'HatinTime_SFX_Highscore.Textures.token_dj');

    IconList(10) = (iconName = "key", icon = Texture2D'HatInTime_Hud.ObjectIcons.Textures.golden_key');
    IconList(11) = (iconName = "coin", icon = Texture2D'HatInTime_Hud_ItemIcons.Misc.token_icon');
    IconList(12) = (iconName = "cannon", icon = Texture2D'hatintime_hud_objectiveactors.Textures.cannon_icon');

    IconList(13) = (iconName = "yarn", icon = Texture2D'HatInTime_Hud_Loadout.Overview.cloth_points');
    IconList(14) = (iconName = "yarn_sprint", icon = Texture2D'HatInTime_Hud_ItemIcons.yarn.yarn_ui_sprint');
    IconList(15) = (iconName = "yarn_brew", icon = Texture2D'HatInTime_Hud_ItemIcons.yarn.yarn_ui_brew');
    IconList(16) = (iconName = "yarn_ice", icon = Texture2D'HatInTime_Hud_ItemIcons.yarn.yarn_ui_ice');
    IconList(17) = (iconName = "yarn_dweller", icon = Texture2D'HatInTime_Hud_ItemIcons.yarn.yarn_ui_foxmask');
    IconList(18) = (iconName = "yarn_timestop", icon = Texture2D'HatInTime_Hud_ItemIcons.yarn.yarn_ui_timestop');

    IconList(19) = (iconName = "pon", icon = Texture2D'HatInTime_Hud.Textures.EnergyBit');
    IconList(20) = (iconName = "treasure_pon", icon = Texture2D'HatInTime_Hud2.Textures.treasurebit');
    IconList(21) = (iconName = "health_pon", icon = Texture2D'HatInTime_Hud2.Textures.health_pon');
    IconList(22) = (iconName = "power_pon", icon = Texture2D'SS_PingSystem_Content.powerpon'); // Credits: Habijob for the awesome power pon icon!

    IconList(23) = (iconName = "heart", icon = Texture2D'HatInTime_PlayerAssets.Textures.Heart');
    IconList(24) = (iconName = "connection_failed", icon = Texture2D'HatInTime_PlayerAssets.Textures.Heart');
    
    IconList(25) = (iconName = "dw", icon = Texture2D'HatInTime_Hud_DeathWish.UI_Deathwish_Activated2');
    IconList(26) = (iconName = "dw_gold", icon = Texture2D'HatInTime_Hud_DeathWish.UI_Deathwish_Gold');
    IconList(27) = (iconName = "dw_empty", icon = Texture2D'HatInTime_Hud_DeathWish.UI_Deathwish_Full2');
    IconList(28) = (iconName = "dw_passive", icon = Texture2D'HatInTime_Hud_DeathWish.Textures.DW_Passive_Complete');
    IconList(29) = (iconName = "dw_passive_gold", icon = Texture2D'HatInTime_Hud_DeathWish.Textures.DW_Passive_gold');
    
    IconList(30) = (iconName = "crown", icon = Texture2D'Vanessa_Tag_Content.Textures.crown');
    IconList(31) = (iconName = "soul", icon = Texture2D'Vanessa_Tag_Content.Textures.soul');
    
    IconList(32) = (iconName = "metro_yellow", icon = Texture2D'HatInTime_Hud_ItemIcons3.MetroTicket_Yellow');
    IconList(33) = (iconName = "metro_green", icon = Texture2D'HatInTime_Hud_ItemIcons3.MetroTicket_Green');
    IconList(34) = (iconName = "metro_blue", icon = Texture2D'HatInTime_Hud_ItemIcons3.MetroTicket_Blue');
    IconList(35) = (iconName = "metro_pink", icon = Texture2D'HatInTime_Hud_ItemIcons3.MetroTicket_Red');

    IconList(36) = (iconName = "shard", icon = Texture2D'HatInTime_Hud_ItemIcons2.Timeshard');
    IconList(37) = (iconName = "storybook", icon = Texture2D'HatInTime_Hud2.Textures.riftbook_color_ui');

    punctuations.Add("\"");
    punctuations.Add("'");
    punctuations.Add(".");
    punctuations.Add(",");
    punctuations.Add("?");
    punctuations.Add("!");
    punctuations.Add(":");
    punctuations.Add(";");
    punctuations.Add("。");
    punctuations.Add("、");
    punctuations.Add("？");
    punctuations.Add("！");
    punctuations.Add("ー");
    punctuations.Add("』");
    // French punctuations has a space
    punctuations.Add(" ?");
    punctuations.Add(" !");
    punctuations.Add(" :");
    punctuations.Add(" ;");
}