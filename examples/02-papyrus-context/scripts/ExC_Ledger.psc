Scriptname ExC_Ledger Hidden
{The favor ledger, stored with PapyrusUtil's StorageUtil. Global functions only.

 StorageUtil is the simplest way to share Papyrus state with SkyrimNet: values live in the save's
 co-save, and prompts read them directly with the papyrus_util decorator, for example
     papyrus_util("GetIntValue", actorUUID, "ExC_FavorsOwed", 0)
 so there is no decorator to register and no Papyrus call while a prompt renders.

 Every key this mod uses is written below and nowhere else in Papyrus. The prompt and action files
 under layer/ use the same strings: rename a key here and you must rename it there too.

     ExC_FavorsOwed   int, on an NPC        favors that NPC owes the player
     ExC_LastFavor    string, on an NPC     the most recent favor, e.g. "a gift of 2 Ale"
     ExC_RecentDeeds  string list, global   the player's last few good deeds, for gossip}

; How many deeds the gossip list keeps.
int Function MaxRecentDeeds() global
    return 5
EndFunction

int Function GetFavorsOwed(Actor akNpc) global
    return StorageUtil.GetIntValue(akNpc, "ExC_FavorsOwed", 0)
EndFunction

; Records a favor the player did for akNpc. Returns how many favors akNpc now owes.
int Function AddFavor(Actor akNpc, string asDeed) global
    int owed = StorageUtil.AdjustIntValue(akNpc, "ExC_FavorsOwed", 1)
    StorageUtil.SetStringValue(akNpc, "ExC_LastFavor", asDeed)

    ; None is StorageUtil's global scope; prompts read it with papyrus_util(..., "none", ...).
    StorageUtil.StringListAdd(None, "ExC_RecentDeeds", akNpc.GetDisplayName() + ": " + asDeed)
    while StorageUtil.StringListCount(None, "ExC_RecentDeeds") > MaxRecentDeeds()
        StorageUtil.StringListRemoveAt(None, "ExC_RecentDeeds", 0)
    endwhile
    return owed
EndFunction

; akNpc repays one favor. Returns false if they owed none.
bool Function SpendFavor(Actor akNpc) global
    if GetFavorsOwed(akNpc) <= 0
        return false
    endif
    if StorageUtil.AdjustIntValue(akNpc, "ExC_FavorsOwed", -1) <= 0
        ; Unset instead of keeping a zero, so the save does not collect empty entries.
        StorageUtil.UnsetIntValue(akNpc, "ExC_FavorsOwed")
        StorageUtil.UnsetStringValue(akNpc, "ExC_LastFavor")
    endif
    return true
EndFunction
