/*
* Censorship? On my Owl Express? It's more than you think!
* This is an optional thing to toggle in the config. Calm down.
* Either switches bad words with "PECK" or "****" or "!#@?!".
* Also there's a version where it changes it with nice words because you are an attractive living soul, or human or alien? idk my lizard overlord.
*/
Class SS_1984 extends Object;

// Removes any offensive or racial slur from the string, just in case situation if people are edgy mod abusers.
static function string Literally1984(string s)
{
    local string stinky, wl;
    local Array<string> wordList;
    local int i;

    if(!HasTextFilter()) return s;

    wordList = SplitString(s, " ", false);
    for(i = 0; i < wordList.Length; i++)
    {
        wl = wordList[i];
        if(wl ~= "" || wl ~= " ") continue;
        // The brave soldier who wrote these, I thank you.
        foreach Class'SS_OffensiveWords'.default.FoulWords(stinky)
        {
            if(InStr(wl, stinky, false, true) == INDEX_NONE) continue;
            if(MergeWord(wl, stinky)) continue;
            wordList[i] = DoThe1984(wordList[i], stinky);
        }       
    }
    s = "";
    JoinArray(wordList, s, " ");
    // foreach wordList(wl) s = (Len(s) > 0 ? (s @ wl) : (s $ wl));
    return s;
}

static function bool HasTextFilter()
{
    return Class'SS_CommunicationSettings'.default.FilterType != 0;
}

static function string DoThe1984(string word, string stinkyWord)
{
    local int i;
    local int wordLength;
    local string s;
    
    if(word == "" || word == " ") return word;
    
    wordLength = Len(stinkyWord);

    switch(class'SS_CommunicationSettings'.default.FilterType)
    {
        case 1:
            s = "PECK";
            break;
        case 2:
            while(i < wordLength)
            {
                i++;
                s $= "*";
            }
            break;
        case 3:
            while(i < wordLength)
            {
                switch(i % Len("!@#?$%^&*"))
                {
                    case 0: s $= "!"; break;
                    case 1: s $= "@"; break;
                    case 2: s $= "#"; break;
                    case 3: s $= "?"; break;
                    case 4: s $= "$"; break;
                    case 5: s $= "%"; break;
                    case 6: s $= "^"; break;
                    case 7: s $= "&"; break;
                    case 8: s $= "*"; break;
                }
                i++;
            }
            break;
        case 4:
            s = Class'SS_Adjectives'.static.GetAdjectiveRand();
            break;
    }
    word = Repl(word, stinkyWord, s);
    return word;
}

static function bool MergeWord(string word, string badWord)
{
    local int i;
    local string char;
    i = InStr(word, badWord, false, true);
    char = Mid(word, i - 1, 1);
    if(i != 0 && (char ~= "" || char ~= " " || IsLetter(char))) return true; // letter on the left of the bad word
    char = Mid(word, i + Len(BadWord), 1);
    if(i + Len(BadWord) < Len(word) && (char ~= "" || char ~= " " || IsLetter(char))) return true; // letter on the right of the bad word
    return false;
}

// The modder who wrote this is clueless about ASCII tricks, shit talking is allowed.
static function bool IsLetter(string letter)
{
    switch(Caps(letter))
    {
        case "A": case "B": case "C": case "D":
        case "E": case "F": case "G": case "H":
        case "I": case "J": case "K": case "M":
        case "N": case "L": case "O": case "P":
        case "Q": case "R": case "S": case "T":
        case "U": case "V": case "W": case "X":
        case "Y": case "Z":
            return true;
        default:
            return false;
    }
    return false;
}

// 0 = Show both
// 1 = Show name only
// 2 = Show avatar only
// 3 = Show neither
static function bool ShouldHideName()
{
    return class'Hat_GhostPartyPlayer'.default.DisplayNameAndAvatars > 1;
}

static function bool ShouldCensorAvatars()
{
    return class'Hat_GhostPartyPlayer'.static.ShouldCensorAvatars();
}