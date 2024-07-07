Class SS_ButtonClass extends Object
    dependson(SS_Button);

var name ButtonID;
var name Argument;
var string tooltip;

var bool CanBeHovered;
var bool BeingHovered;
// Size in pixels
var Vector2D size; 
var bool AvoidStretch;
var name uvSizeParameter;

// Icon offset
var name offsetParameter;
var Vector2d offset;

// Shiny that is random
var bool Shine;
//var Vector2d ShineIntervalRange;

var MaterialInterface Material;
var MaterialInstanceTimeVarying MatInstance;

var transient Array< delegate<OnClick> > OnClickDelegates;
var transient Array< delegate<OnHover> > OnHoverDelegates;

delegate OnClick(name id, name arg);
delegate OnHover(name id, name arg);

function Init()
{ 
    local LinearColor cl;
    local Vector2d uvSize;

    MatInstance = Class'OnlineCommunication'.static.InitMaterial(Material);

    uvSize = vect2d(1.0f, 1.0f);
    if(MatInstance.IsValidParameter(uvSizeParameter))
    {
        uvSize = CalculateButtonUVSize(Size.X, Size.Y);
        cl = MakeLinearColor(uvSize.X, uvSize.Y, 0, 0);
        MatInstance.SetVectorParameterValue(uvSizeParameter, cl);
    }

    if(MatInstance.IsValidParameter(offsetParameter))
    {    
        cl.R = Offset.X;
        cl.G = Offset.Y;
        MatInstance.SetVectorParameterValue(offsetParameter, cl);
    }

    if(MatInstance.IsValidParameter('Shine'))
        MatInstance.SetScalarParameterValue('Shine',  Shine ? 1 : 0);
}

static function Vector2D CalculateButtonUVSize(float x, float y)
{
    local float smallest;
    local Vector2d uv;

    if(x == y) return vect2d(1,1);

    smallest = FMin(x, y);
    uv.X = smallest/x;
    uv.Y = smallest/y;
    
    return uv;
}

static function Print(coerce string msg)
{
    Class'OnlineCommunication'.static.Print(msg);
}

defaultproperties
{
    CanBeHovered = true;
    AvoidStretch = true;
    Shine = false;
    uvSizeParameter = "uvSize";
    offsetParameter = "offset";
    Size = (X = 48, Y = 48);
}
