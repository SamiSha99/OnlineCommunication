Class SS_Tag extends Object
    abstract;

var string tag;
var Array<string> parameters;
var bool noClose;

static function ApplyToSegment(out OCSegment segment, array<string> parameterArray);
static function Array<string> GetParameters(string rawParameters);
static function bool IsValid(string rawTag) 
{
    return default.tag != "" && SneakPeek(rawTag, 0, default.tag $ default.parameters.Length > 0 ? "=" : "");
}

static function bool Peek(out string input, out int pos, const string expect)
{
    return Class'Hat_BubbleTalker_Compiler_Base'.static.Peek(input, pos, expect);
}

static function bool SneakPeek(out string input, const int pos, const string expect)
{
    return Class'Hat_BubbleTalker_Compiler_Base'.static.SneakPeek(input, pos, expect);
}

defaultproperties
{

}