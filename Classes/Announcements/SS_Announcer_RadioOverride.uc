// Some ghost party overrrides and detection
Class SS_Announcer_RadioOverride extends SS_Announcer;

var Array<Hat_ConversationTree> OnlineConversationRadios;

function Tick(float d)
{
    ManageOnlineConversationRadioPrompts();
}

function ManageOnlineConversationRadioPrompts()
{
    local Hat_BubbleTalker_PlayerRadio playerRadio;
    local Hat_ConversationTree convo;
    local Array<ConversationReplacement> keys;
    local int i;
    local WorldInfo wi;
    wi = GetWorldInfo();
    foreach wi.DynamicActors(Class'Hat_BubbleTalker_PlayerRadio', playerRadio)
        for(i = 0; i < playerRadio.Messages.Length; i++)
        {
            convo = playerRadio.Messages[i].ConversationTree.ConversationTree;
            if(OnlineConversationRadios.Find(convo) == INDEX_NONE) continue;
            
            Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "announcer", playerRadio.Messages[i].ConversationTree.KeywordReplacements[0].Value);
            
            switch(convo)
            {
                case Hat_ConversationTree'HatinTime_Conv_GhostParty.ConversationTrees.TimePieceGet':
                    if(!Class'SS_CommunicationSettings'.default.EnableTimePiece) break;
                    Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "act_name", playerRadio.Messages[i].ConversationTree.KeywordReplacements[1].Value);
                    GameMod.OnRecievedChatLogCommand("TimePieceGet", "general", LOCALIZATION_FILE, keys);  
                    break;
                case Hat_ConversationTree'HatinTime_Conv_GhostParty.LevelObjects.Faucet':
                    GameMod.OnRecievedChatLogCommand("FaucetClosed", "general", LOCALIZATION_FILE, keys);                        
                    break;
                case Hat_ConversationTree'HatinTime_Conv_GhostParty.LevelObjects.VaultCode':
                    GameMod.OnRecievedChatLogCommand("GoldenTicketGrabbed", "general", LOCALIZATION_FILE, keys);
                    break;
                default:
                    break;
            }

            if(i > 0 && playerRadio.Messages.Length > 0)
            {
                if (playerRadio.Messages[i].Sequence != None)
                    playerRadio.Messages[i].Sequence.ForceActivateOutput(class'Hat_SeqAct_Conversation'.const.TerminateOutputIndex);

                if (playerRadio.Messages[i].Sequence == None && playerRadio.Messages[i].ConversationTree != None)
                    playerRadio.Messages[i].ConversationTree.Destroy();

                playerRadio.Messages.Remove(i, 1);
            }
            else
                playerRadio.ProcessStack(); // force process since its has been processed to render and waiting for its lifetime, we cast now to remove        
        }
}


defaultproperties
{
    OnlineConversationRadios.Add(Hat_ConversationTree'HatinTime_Conv_GhostParty.ConversationTrees.TimePieceGet');
    OnlineConversationRadios.Add(Hat_ConversationTree'HatinTime_Conv_GhostParty.LevelObjects.VaultCode');
    OnlineConversationRadios.Add(Hat_ConversationTree'HatinTime_Conv_GhostParty.LevelObjects.Faucet');
    // Handled in GameMod, but maybe moved here?
    OnlineConversationRadios.Add(Hat_ConversationTree'HatinTime_Conv_GhostParty.ConversationTrees.PlayerJoin');
    OnlineConversationRadios.Add(Hat_ConversationTree'HatinTime_Conv_GhostParty.ConversationTrees.PlayerLeave');
}