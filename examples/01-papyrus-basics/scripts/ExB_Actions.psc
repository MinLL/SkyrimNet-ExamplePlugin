Scriptname ExB_Actions extends Quest
{The functions behind this mod's SkyrimNet actions.

 Each function is named by one file in layer/example.papyrus-basics/actions/:
     questEditorId: ExB_Quest          the quest this script is attached to
     scriptName: ExB_Actions           this script
     executionFunctionName: BuyRound   the function below

 Arguments arrive in the order of that file's parameterMapping. SkyrimNet only calls a function
 after the action's eligibilityRules passed, but check your arguments anyway: the LLM picks the
 dynamic ones, and it can name someone who has since walked away.

 These run on the Papyrus VM, so keep them short. There is no SkyrimNet version check here:
 SkyrimNet is the only caller, so if one of these runs, SkyrimNet is loaded.}

MiscObject Property Gold001 Auto
{Skyrim.esm Gold001, filled in the plugin.}

Potion Property Ale Auto
{Skyrim.esm Ale, filled in the plugin.}

; BuyRound.yaml: speaker, then a static cost.
; The speaker pays and the player gets a drink. The YAML's eventString records what happened, so
; this function only changes the game.
Function BuyRound(Actor akSpeaker, int aiCost)
    if !akSpeaker || aiCost <= 0
        return
    endif
    akSpeaker.RemoveItem(Gold001, aiCost, true)
    Game.GetPlayer().AddItem(Ale, 1)
EndFunction

; ShareDrink.yaml: speaker, then a target the LLM chose from the actors nearby.
Function ShareDrink(Actor akSpeaker, Actor akTarget)
    if !akSpeaker || !akTarget || akTarget == akSpeaker
        return
    endif
    if akSpeaker.GetItemCount(Ale) > 0
        akSpeaker.RemoveItem(Ale, 1, true, akTarget)
    else
        akTarget.AddItem(Ale, 1, true)
    endif
EndFunction

; TellTale.yaml: speaker, then a topic the LLM wrote.
; A narrative-only action: nothing changes in the game. Its whole effect is the event the YAML
; records ("Hulda told a tale about the dragon at Whiterun"), which NPCs then remember.
Function TellTale(Actor akSpeaker, string asTopic)
    Debug.Trace("[ExampleBasics] " + akSpeaker.GetDisplayName() + " tells a tale about " + asTopic)
EndFunction
