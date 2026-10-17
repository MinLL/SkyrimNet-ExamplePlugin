Scriptname ExB_PlayerAlias extends ReferenceAlias
{Tells SkyrimNet about the player's tavern life: walking into an inn, having a drink there, and
 becoming a regular. Each uses a different SkyrimNet call; the comments say why.}

Keyword Property LocTypeInn Auto
{Skyrim.esm LocTypeInn: the keyword on every inn location. Filled in the plugin.}

int Property DrinksToBecomeRegular = 5 AutoReadOnly

; Set by the version check on every load. Nothing below talks to SkyrimNet while it is false.
bool skyrimNetReady = false
int drinksAtInns = 0

Event OnInit()
    CheckSkyrimNet()
EndEvent

Event OnPlayerLoadGame()
    ; Check on every load: SkyrimNet may have been updated, removed or installed since the save.
    CheckSkyrimNet()
EndEvent

Function CheckSkyrimNet()
    skyrimNetReady = ExB_Compat.IsSkyrimNetCompatible()
    if skyrimNetReady
        Debug.Trace("[ExampleBasics] SkyrimNet " + SkyrimNetApi.GetBuildVersion() + " found")
    elseif ExB_Compat.IsSkyrimNetLoaded()
        Debug.Notification("Example Basics needs SkyrimNet " + ExB_Compat.MinimumVersion() + " or newer.")
    else
        Debug.Trace("[ExampleBasics] SkyrimNet is not installed; tavern events are off")
    endif
EndFunction

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
    if !skyrimNetReady || !akNewLoc || !akNewLoc.HasKeyword(LocTypeInn)
        return
    endif
    Actor player = GetActorReference()

    ; RegisterShortLivedEvent: scene context that expires (here after two minutes) and is never
    ; stored. Use it for "what is happening right now". The event id is a key: registering the same
    ; id again replaces the old entry, so walking between inns never piles up lines.
    SkyrimNetApi.RegisterShortLivedEvent("exb_entered_inn", "exb_entered_inn", \
        player.GetDisplayName() + " walked into " + akNewLoc.GetName() + ".", "", 120000, player, None)
EndEvent

Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
    Potion drink = akBaseObject as Potion
    if !skyrimNetReady || !drink || !drink.IsFood() || !IsInInn()
        return
    endif
    Actor player = GetActorReference()

    ; RegisterEvent: goes into event history, so NPCs who saw it remember it and may react.
    ; Type "custom" takes plain text. Any other type expects JSON matching a schema you
    ; registered first (see example 02).
    SkyrimNetApi.RegisterEvent("custom", player.GetDisplayName() + " had " + drink.GetName() + " at the bar.", player, None)

    drinksAtInns += 1
    if drinksAtInns == DrinksToBecomeRegular
        ; RegisterPersistentEvent: a fact NPCs know from now on, without reacting to it now.
        ; Use it for background changes that should not interrupt whatever scene is playing.
        SkyrimNetApi.RegisterPersistentEvent(player.GetDisplayName() + " has become a familiar face in Skyrim's taverns.", None, player)
    endif
EndEvent

bool Function IsInInn()
    Location here = GetActorReference().GetCurrentLocation()
    return here && here.HasKeyword(LocTypeInn)
EndFunction
