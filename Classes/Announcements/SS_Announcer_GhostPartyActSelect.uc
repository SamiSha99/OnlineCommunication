Class SS_Announcer_GhostPartyActSelect extends SS_Announcer;

function Init()
{

}

function OnPreOpenHUD(HUD InHUD, out class<Object> InHUDElement)
{
    // local string l;
    // local Array<ConversationReplacement> keys;
    // return;
    // l = "JoinActPopUp";
    // Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "act_name", playerRadio.Messages[i].ConversationTree.KeywordReplacements[1].Value);
    // Announce(l, "ghostparty", keys);
}

static function bool ShouldCreate() 
{ 
    return false; //Class'OnlineCommunication'.static.InSpaceShip(); 
}