Scriptname ExC_PlayerAlias extends ReferenceAlias
{Notices the player giving things to NPCs, records each gift as a favor in the ledger, and tells
 SkyrimNet with an example_favor event.}

Faction Property CurrentFollowerFaction Auto
{Skyrim.esm CurrentFollowerFaction. Handing items to a follower is storage, not a favor.}

bool skyrimNetReady = false

Event OnInit()
    OnGameLoaded()
EndEvent

Event OnPlayerLoadGame()
    OnGameLoaded()
EndEvent

Function OnGameLoaded()
    skyrimNetReady = ExC_Compat.IsSkyrimNetCompatible()
    if !skyrimNetReady
        Debug.Trace("[ExampleContext] SkyrimNet missing or older than " + ExC_Compat.MinimumVersion() + "; favors are not reported")
        return
    endif
    ; Schemas live in memory only, so register on every load before any event of this type.
    ExC_Events.RegisterSchema()
EndFunction

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    ; This event fires for every item that leaves the player's inventory, so the cheapest checks
    ; come first: most removals (crafting, dropping, eating) have no destination at all.
    Actor npc = akDestContainer as Actor
    if !npc || !skyrimNetReady
        return
    endif
    if UI.IsMenuOpen("BarterMenu") || npc.IsInFaction(CurrentFollowerFaction)
        return
    endif

    string deed = "a gift of " + aiItemCount + " " + akBaseItem.GetName()
    int owed = ExC_Ledger.AddFavor(npc, deed)
    ExC_Events.RecordFavor(GetActorReference(), npc, deed, owed)
EndEvent
