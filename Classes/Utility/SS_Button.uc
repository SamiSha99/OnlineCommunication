Class SS_Button extends Object;

struct OCButton
{
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
    
    structdefaultproperties
    {
        CanBeHovered = true;
        AvoidStretch = true;
        Shine = false;
        uvSizeParameter = "uvSize";
        offsetParameter = "offset";
        Size = (X = 48, Y = 48);
    }
};


static function Array<OCButton> BuildButtons(Array<OCButton> buttons)
{
    local int i;

    for(i = 0; i < buttons.length; i++) buttons[i] = BuildButton(buttons[i]);
    
    return buttons;
}

static function OCButton BuildButton(OCButton b)
{
    local LinearColor cl;
    local Vector2d uvSize;

    b.MatInstance = Class'OnlineCommunication'.static.InitMaterial(b.Material);

    uvSize = vect2d(1.0f, 1.0f);
    if(b.MatInstance.IsValidParameter(b.uvSizeParameter))
    {
        uvSize = CalculateButtonUVSize(b.Size.X, b.Size.Y);
        cl = MakeLinearColor(uvSize.X, uvSize.Y, 0, 0);
        b.MatInstance.SetVectorParameterValue(b.uvSizeParameter, cl);
    }

    if(b.MatInstance.IsValidParameter(b.offsetParameter))
    {    
        cl.R = b.Offset.X;
        cl.G = b.Offset.Y;
        b.MatInstance.SetVectorParameterValue(b.offsetParameter, cl);
    }

    if(b.MatInstance.IsValidParameter('Shine'))
        b.MatInstance.SetScalarParameterValue('Shine',  b.Shine ? 1 : 0);

    return b;
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