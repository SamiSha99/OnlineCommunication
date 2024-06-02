Class SS_Announcer_DeathWish extends SS_Announcer;

var float nextValidationTime;
const UPDATE_TIME_INTERVAL = 0.5f;

struct ContractListener
{
    var Class < Hat_SnatcherContract_DeathWish >  ActiveContract;
    var bool AlreadyPerfect;
    var Array < bool > ObjectiveStatus; // flagged bools to show if complete
};

var Array<ContractListener> ContractListeners;

function Init()
{
    ValidateContracts();
}

function OnPreOpenHUD(HUD InHUD, out class<Object> InHUDElement)
{
    
}

function Tick(float d)
{
    ValidateContracts();
}

function ValidateContracts()
{
    local Array< Class<Hat_SnatcherContract_DeathWish> > contracts;
    local Class<Hat_SnatcherContract_DeathWish> c;
    local int i;
    local Array<ConversationReplacement> keys;
    local string l;
    
    if(GetWorldInfo().TimeSeconds <= nextValidationTime) return;
    
    nextValidationTime += UPDATE_TIME_INTERVAL;
    
    if(!Class'SS_CommunicationSettings'.default.EnableDeathWish) return;

    contracts = Class'Hat_SnatcherContract_DeathWish'.static.GetActiveDeathWishes();

    // No actives? hmm
    if(contracts.Length == 0)
    {
        ContractListeners.Length = 0;
        return;
    }

    if(ContractListeners.Length == 0)
    {
        foreach contracts(c) 
        {
            if(c.default.Objectives.Length <= 0) continue;
            if(ContractListeners.Find('ActiveContract', c) != INDEX_NONE) continue;
            AddContractListener(c);
        }
        return;
    }

    for(i = 0; i < ContractListeners.Length; i++)
    {
        if(ContractHasBeenPerfected(ContractListeners[i]))
        {
            Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "contract_name", GetContractSection(ContractListeners[i]));
            l = ContractListeners[i].ActiveContract.default.IsPassive ? "PassivePerfected" : "ContractPerfected";
            Announce(l, "contracts", keys, "deathwish");
            ContractListeners.Remove(i, 1);
            i--;
            continue;
        }
        
        if(!ContractListeners[i].ObjectiveStatus[0] && ContractListeners[i].ActiveContract.static.IsObjectiveCompleted(0))
        {
            Class'SS_ChatFormatter'.static.AddKeywordReplacement(keys, "contract_name", GetContractSection(ContractListeners[i]));
            l = ContractListeners[i].ActiveContract.default.IsPassive ? "MainObjectivePassiveComplete" : "MainObjectiveComplete";
            Announce(l, "contracts", keys, "deathwish");
            ContractListeners.Remove(i, 1);
            i--;
            continue;
        }

        if(Contracts.Find(ContractListeners[i].ActiveContract) != INDEX_NONE) continue;
        ContractListeners.Remove(i, 1);
        i--;
    }
}

function AnnounceToLobby()
{
    
}

function AddContractListener(Class<Hat_SnatcherContract_DeathWish> contract)
{
    local ContractListener cl;
    local int i;

    cl.ActiveContract = contract;
    cl.ObjectiveStatus.Length = cl.ActiveContract.default.Objectives.Length;
    for(i = 0; i < cl.ActiveContract.default.Objectives.Length; i++)
        cl.ObjectiveStatus[i] = cl.ActiveContract.static.IsObjectiveCompleted(i);
    cl.AlreadyPerfect = AllTrue(cl.ObjectiveStatus);

    ContractListeners.AddItem(cl);
}

function string GetContractSection(ContractListener cl)
{
    return "contracts_deathwish>" $ cl.ActiveContract.Name $ ">Title";
}

static function bool ShouldCreate()
{
    return Class'OnlineCommunication'.static.InSpaceShip() || Class'Hat_SnatcherContract_DeathWish'.static.IsAnyActive(true, true);
}

function bool ContractHasBeenPerfected(ContractListener cl)
{
    if(cl.AlreadyPerfect) return false; // no prompt required
    if(AllTrue(cl.ObjectiveStatus)) return false;
    return cl.ActiveContract.static.IsContractPerfected();
}

function bool AllTrue(Array<bool> bees)
{
    local bool b;
    foreach bees(b) if(!b) return false;
    return true;
}

defaultproperties
{
    nextValidationTime = -1;
}