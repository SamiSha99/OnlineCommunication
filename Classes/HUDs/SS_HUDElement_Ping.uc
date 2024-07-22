// Shows icon location on Preview
Class SS_HUDElement_Ping extends Hat_HUDElement;

var SS_GameMod_OC GameMod;

var bool bPingPreview;

var MaterialInterface Crosshair;
var MaterialInstanceTimeVarying CrosshairInstance;

const PARAM_COOLDOWN_NAME = 'Cooldown';

function OnOpenHUD(HUD H, optional String command)
{
    CrosshairInstance = Class'OnlineCommunication'.static.InitMaterial(Crosshair);
}


function bool Tick(HUD H, float d)
{
    if(!Super.Tick(H, d)) return false;

    return true;
}

function bool Render(HUD H)
{
    local float crossSize;
    if(!Super.Render(H)) return false;
    if(Class'SS_Ping_Helpers'.static.PingingForbidden(Hat_Player(H.PlayerOwner.Pawn))) return false;

    crossSize = H.Canvas.ClipY * 0.11875f * Class'SS_CommunicationSettings'.default.PingCrossHairSize;
    if(Class'SS_Ping_Helpers'.static.GetPingCastingType() >= 2 || bPingPreview)
        RenderCrossHair(H, crosssize, Class'SS_CommunicationSettings'.default.PingCrossHairAlpha);
    
    
    return true;
}

function RenderCrossHair(HUD H, float crossSize, optional float alpha = 1.0f)
{
    local LinearColor lc;
    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, 255);
    CrosshairInstance.SetScalarParameterValue('Alpha', alpha);
    
    lc = Class'SS_Color'.static.HexToLinearColor(Class'SS_CommunicationSettings'.default.PingCrossHairColor);
    CrosshairInstance.SetVectorParameterValue('Color', lc);
    
    DrawCenter(H, H.Canvas.ClipX * 0.5f, H.Canvas.ClipY * 0.5f, crossSize, crossSize, CrosshairInstance);
}

defaultproperties
{
    SharedInCoop = false;
    Crosshair = Material'SS_PingSystem_Content.Crosshair';
}