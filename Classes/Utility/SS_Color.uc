Class SS_Color extends Object;

//const COLOR_ENUM_LENGTH = 33; // 0 - 32
// USE "ColorName_MAX" instead, thank you Undrew!

enum ColorName
{
    White,
    Red,
    Green,
    Blue,
    Yellow,
    Magneta,
    Cyan,
    Aqua,
    Teal,
    Bright_Teal,
    Ruby,
    Grey,
    Gray,
    Light_Grey,
    Dark_Grey,
    Brown,
    Purple,
    Lavender,
    Crimson,
    Yellow_Lemon,
    Hot_Pink,
    Deep_Pink,
    Ghost_White,
    Azure_Blue,
    Neon_Blue,
    Lime,
    Violet,
    Royal_Purple,
    Orange,
    Tomato,
    Silver,
    Gold,
    Black
};

// Returns a color based on the text passed (note: hopefully not case sensitive, but it never hurts checking!)
// Returns White if it couldn't find anything.
static function Color GetColorByName(coerce optional String _name = "White")
{
    local ColorName _colorName;
    _colorName = ColorName(EnumFromString(enum'ColorName', _name));
    return GetColor(_ColorName);
}

static function bool IsValidColor(coerce string _name)
{
    local int i;

    // Hex Colors
    if(InStr(_name, "#") != INDEX_NONE) return _name ~= "#FFFFFF" || _name ~= "#FFFFFFFF" || Hex(_name) != GetColor(White);
    
    for(i = 0; i < ColorName_MAX; i++)
    {
        if(!(String(GetEnum(enum'ColorName', i)) ~= _name)) continue;
        return true;
    }
    return false;
}

// Credits: Starblaster Conversation Expander Mod
static function Color Hex(string HexCode)
{
	local Array<string> HexCodeArray;
	local int R, G, B, A;
	
	HexCode -= "#";
	if (Len(HexCode) < 6) return MakeColor(255, 255, 255, 255);
	if (Len(HexCode) > 8) HexCode = Left(HexCode, 8);
	
	
    HexCodeArray = Class'OnlineCommunication'.static.SplitStringToChars(HexCode);
	
	if (HexCodeArray.Length < 8)
	{
		HexCodeArray[6] = "F";
		HexCodeArray[7] = "F";
	}
	
	R = (GetHexDigit(HexCodeArray[0]) * 16) + GetHexDigit(HexCodeArray[1]);
	G = (GetHexDigit(HexCodeArray[2]) * 16) + GetHexDigit(HexCodeArray[3]);
	B = (GetHexDigit(HexCodeArray[4]) * 16) + GetHexDigit(HexCodeArray[5]);
	A = (GetHexDigit(HexCodeArray[6]) * 16) + GetHexDigit(HexCodeArray[7]);
	
	return MakeColor(R, G, B, A);
}

static function LinearColor HexToLinearColor(string HexCode)
{
    return ColorToLinearColor(Hex(HexCode));
}

static function int GetHexDigit(coerce string D)
{
	switch(caps(D))
	{
	    case "0": return 0;
	    case "1": return 1;
	    case "2": return 2;
	    case "3": return 3;
	    case "4": return 4;
	    case "5": return 5;
	    case "6": return 6;
	    case "7": return 7;
        case "8": return 8;
        case "9": return 9;
        case "A": return 10;
        case "B": return 11;
        case "C": return 12;
        case "D": return 13;
        case "E": return 14;
        case "F": return 15;
	}

	return -1;
}

static function string GetDigitFromHex(int digit)
{
	switch(digit)
	{
	    case 0: return "0";
	    case 1: return "1";
	    case 2: return "2";
	    case 3: return "3";
	    case 4: return "4";
	    case 5: return "5";
	    case 6: return "6";
	    case 7: return "7";
        case 8: return "8";
        case 9: return "9";
        case 10: return "A";
        case 11: return "B";
        case 12: return "C";
        case 13: return "D";
        case 14: return "E";
        case 15: return "F";
	}

	return "0";
}

static function string RandomHexColor(optional int min = 0, optional int max = 16)
{
    local int i;
    local string hexColor;
    for(i = 0; i < 6; i++) hexColor $= GetDigitFromHex(min + Rand(max-min));
    hexColor = "#" $ hexColor;
    return hexColor;
}

static function Color GetColorByBlindMode(Color NormalColor)
{
    local Vector R, G, B;
    local Vector NormalColorVector;
    local LinearColor lc;
    switch(Class'Hat_HUD'.default.PostProcessColorBlindness)
    {
        // Protanopia
        case 1:
            R = vect(0.20f, 0.99f, -0.19f);
            G = vect(0.16f, 0.79f, 0.04f);
            B = vect(0.01f, -0.01f, 1.00f);
            break;
        // Deuteranopia
        case 2:
            R = vect(0.43f, 0.72f, -0.15f);
            G = vect(0.34f, 0.57f, 0.09f);
            B = vect(-0.02f, 0.03f, 1.00f);
            break;
        // Tritanopia
        case 3:
            R = vect(0.97f, 0.11f, -0.08f);
            G = vect(0.02f, 0.82f,  0.16f);
            B = vect(-0.06f, 0.88f,  0.18f);
            break;
        default:
            return NormalColor;
    }
    lc = ColorToLinearColor(NormalColor);
    NormalColorVector.X = lc.R;
    NormalColorVector.Y = lc.G;
    NormalColorVector.Z = lc.B;
    lc = MakeLinearColor(NormalColorVector dot R, NormalColorVector dot G, NormalColorVector dot B, lc.A);
    return LinearColorToColor(lc);
}

// SetDrawColor but does a color blind check prior
static function SetDrawColor(HUD H, byte R, byte G, byte B, optional byte A = 255)
{
    local Color correctedColor;

    correctedColor.R = R;
    correctedColor.G = G;
    correctedColor.B = B;
    correctedColor.A = A;
    
    if(Class'Hat_HUD'.default.PostProcessColorBlindness > 0)
        correctedColor = GetColorByBlindMode(correctedColor);

    H.Canvas.SetDrawColor(correctedColor.R, correctedColor.G, correctedColor.B, correctedColor.A);
}

// Returns a color based on the enum name that was passed
// Returns White as default
static function Color GetColor(optional ColorName _colorName = White)
{
    switch(_colorName)
    {
        // Uniquly named colors
        case Ruby: return MakeColor(255,87,51); // https://sami.shakkour.dev/projects/color-reader?R=255&G=87&B=51
        case Yellow_Lemon: return MakeColor(250,250,51); // https://sami.shakkour.dev/projects/color-reader?R=250&G=250&B=51
        case Ghost_White: return MakeColor(248,248,255); // https://sami.shakkour.dev/projects/color-reader?R=248&G=248&B=255
        case Azure_Blue: return MakeColor(0,128,255); // https://sami.shakkour.dev/projects/color-reader?R=0&G=128&B=255
        case Neon_Blue: return MakeColor(70,102,255); // https://sami.shakkour.dev/projects/color-reader?R=70&G=102&B=255
        case Lime: return MakeColor(191,255,0); // https://sami.shakkour.dev/projects/color-reader?R=191&G=255&B=0
        case Royal_Purple: return MakeColor(120,81,169); // https://sami.shakkour.dev/projects/color-reader?R=120&G=81&B=169
        case Hot_Pink: return MakeColor(255,105,180); // https://sami.shakkour.dev/projects/color-reader?R=255&G=105&B=180
        case Deep_Pink: return MakeColor(255,20,147); // https://sami.shakkour.dev/projects/color-reader?R=255&G=20&B=147
        case Lavender: return MakeColor(230,230,250); // https://sami.shakkour.dev/projects/color-reader?R=230&G=230&B=250
        case Violet: return MakeColor(238,130,238); // https://sami.shakkour.dev/projects/color-reader?R=238&G=130&B=238
        case Tomato: return MakeColor(255,99,71); // https://sami.shakkour.dev/projects/color-reader?R=255&G=99&B=71
        case Silver: return MakeColor(192,192,192); // https://sami.shakkour.dev/projects/color-reader?R=192&G=192&B=192
        case Gold: return MakeColor(255,215,0); // https://sami.shakkour.dev/projects/color-reader?R=255&G=215&B=0
        case Crimson: return MakeColor(220,20,60); // https://sami.shakkour.dev/projects/color-reader?R=220&G=20&B=60
        case Teal: return MakeColor(0,128,128); // https://sami.shakkour.dev/projects/color-reader?R=0&G=128&B=128
        case Bright_Teal: return MakeColor(1, 249, 198); // https://sami.shakkour.dev/projects/color-reader?R=0&G=249&B=198
        case Light_Grey: return MakeColor(211,211,211); // https://sami.shakkour.dev/projects/color-reader?R=211&G=211&B=211
        case Dark_Grey: return MakeColor(169,169,169); // https://sami.shakkour.dev/projects/color-reader?R=169&G=169&B=169
        
        // General Colors
        case Red: return MakeColor(255,0,0); // https://sami.shakkour.dev/projects/color-reader?R=255&G=0&B=0
        case Green: return MakeColor(0,255,0); // https://sami.shakkour.dev/projects/color-reader?R=0&G=255&B=0
        case Blue: return MakeColor(0,0,255); // https://sami.shakkour.dev/projects/color-reader?R=0&G=0&B=255
        case Yellow: return MakeColor(255,255,0); // https://sami.shakkour.dev/projects/color-reader?R=255&G=255&B=0
        case Magneta: return MakeColor(255,0,255); // https://sami.shakkour.dev/projects/color-reader?R=255&G=0&B=255
        case Cyan: case Aqua: return MakeColor(0,255,255); // https://sami.shakkour.dev/projects/color-reader?R=0&G=255&B=255
        case Black: return MakeColor(0,0,0); // bro just add "local Color c;" and do nothing with it lmao

        // Basic Colors
        case Orange: return MakeColor(255,165,0); // https://sami.shakkour.dev/projects/color-reader?R=255&G=165&B=0
        case Brown: return MakeColor(165, 42, 42); // https://sami.shakkour.dev/projects/color-reader?R=165&G=42&B=42
        case Grey: case Gray: return MakeColor(128,128,128); // https://sami.shakkour.dev/projects/color-reader?R=128&G=128&B=128
        case Purple: return MakeColor(128,0,128); // https://sami.shakkour.dev/projects/color-reader?R=128&G=0&B=128

        case White: default: return MakeColor(255,255,255);
    }
    return MakeColor(255,255,255);
}