Scriptname ExC_Actions extends Quest
{The function behind the RepayFavor action (layer/example.papyrus-context/actions/RepayFavor.yaml).}

; Function RepayFavor(Actor akSpeaker, string asHow): speaker, then how they repay, in the LLM's words.
; The repayment itself is narrative (the YAML's eventString records it); the game state that
; changes is the ledger.
Function RepayFavor(Actor akSpeaker, string asHow)
    if !akSpeaker
        return
    endif
    if !ExC_Ledger.SpendFavor(akSpeaker)
        ; The eligibility rule checked this, but the count can change between the check and the call.
        Debug.Trace("[ExampleContext] " + akSpeaker.GetDisplayName() + " tried to repay a favor they did not owe")
    endif
EndFunction
