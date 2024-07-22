// Also includes selection values for custom ones, assuming this will ever happen
Class SS_PanelContent_ConfigGMCheckbox extends SS_PanelContent_ConfigGM;

function RenderContent(HUD H, SS_Panel panel, float x, float y)
{
    local Vector2D pos;
    local float opacity;

    Super(SS_PanelContent_Config_Base).RenderContent(H, panel, x, y);

    pos.Y = y;
    opacity = 255;    
    Class'SS_Color'.static.SetDrawColor(H, 255, 255, 255, opacity);

    // Checkbox position
    pos.X = x + GAP_CONFIG - GAP_OFFSET - GAP_RIGHT_SLIDER;
    RenderButton(H, panel, Clamp(SelectedOptionIndex, 0, 1), pos);
}

function OnClickContent(HUD H, SS_Panel panel, string arg)
{
    SelectedOptionIndex = 1 - SelectedOptionIndex;
    SaveGMConfig();
    Super(SS_PanelContent).OnClickContent(H, panel, arg);
}

defaultproperties
{
    Buttons(0) = {(
        Argument = "uncheck",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Exit',
        Size = (X = 48, Y = 48)
    )};
    Buttons(1) = {(
        Argument = "check",
        Material = MaterialInstanceConstant'SS_PingSystem_Content.UIButton_Checked',
        Size = (X = 48, Y = 48)
    )};
}

