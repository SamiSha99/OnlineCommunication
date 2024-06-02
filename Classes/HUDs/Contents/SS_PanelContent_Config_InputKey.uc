Class SS_PanelContent_Config_InputKey extends SS_PanelContent_Config_Input;

var bool isListening;

var Color badInputColor;

var float ErrorTime;

function OnInputRecieved(HUD H, string s)
{
    if(!isListening) return;
    InputText = "";

    if(ErrorTime > 0) return;

    if(BlackListed(Name(s)))
    {
        DoError();
        return;
    }
    InputText $= s;
    isListening = false;
    H.SetTimer(0.01f, false, NameOf(DisableInputting), self, H);
}

function EnableInputting(HUD H)
{
    Super.EnableInputting(H);
    InputInstance.ListenToKeyOnly = true;
    InputText = "";
    H.SetTimer(0.01f, false, NameOf(StartListening), self);
}

function StartListening()
{
    isListening = true;
}

function TickContent(HUD H, float d)
{
    Super.TickContent(H, d);

    if(ErrorTime > 0)
    {
        ErrorTime = FMax(ErrorTime - d, 0.0f);
        if(ErrorTime <= 0) ResetFillers();
    }
}

function DoError()
{
    FillerText = "IllegalKey";
    ErrorTime = 1;
    TextColor = default.BadInputColor;
    FillerOpacity = 255;
}

function ResetFillers()
{
    FillerText = default.FillerText;
    TextColor = default.TextColor;
    FillerOpacity = default.FillerOpacity;
}

function SetDefault()
{
    InputText = "" $ GetGameMod().ChatSettings.GetSettingName(ContentName, true);
}

function SetSettingValue()
{
    InputText = "" $ GetGameMod().ChatSettings.GetSettingName(ContentName);
}

function bool BlackListed(Name key)
{
    if(Class'OnlineCommunication'.static.IsPlayerKey(key, true)) return true;
    
    switch(key)
    {
        case 'W':
        case 'A':
        case 'S':
        case 'D':
        case 'Up':
        case 'Down':
        case 'Left':
        case 'Right':
        case 'Q':
        case 'E':
        case 'F':
        case 'SpaceBar':
        case 'LeftShift':
        case 'LeftControl':
        case 'Pause':
        case 'LeftMouseButton':
        case 'RightMouseButton':
        case 'MouseScrollUp':
        case 'MouseScrollDown':
        case 'MiddleMouseButton':
            return true;
        default:
            return false;
    }

}

defaultproperties
{
    SaveTypeName = true
    TextSize = 0.6f
    InputLimit = 256;
    FillerOpacity = 232;
    FocusSize = (X = 250, Y = 50)
    Buttons(0) = {(
        Argument = "input",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Key',
        Size = (X = 250, Y = 50)
    )};
    InputText = "";
    FillerText = "ListeningFiller"
    DONT_PUT_UNDER_SCORE_IDIOT = true;
    CenterText = true;
    textColor = (R=255, G=255, B=255);
    badInputColor = (R=255, G=0, B=0)
}