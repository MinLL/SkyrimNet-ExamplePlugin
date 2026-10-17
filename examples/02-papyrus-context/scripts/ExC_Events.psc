Scriptname ExC_Events Hidden
{This mod's own SkyrimNet event type, "example_favor". Global functions only.

 Example 01 sends plain text as type "custom". A type of your own gives events structure: named
 fields, and a format per place the event is shown. SkyrimNet keeps schemas in memory only, so
 register yours on every game load, before sending the first event of that type.}

string Function FavorType() global
    return "example_favor"
EndFunction

Function RegisterSchema() global
    ; Field types: 0 string, 1 integer, 2 boolean, 3 double, 4 object, 5 array.
    string fields = "[" \
        + "{\"name\":\"giver\",\"type\":0,\"required\":true,\"description\":\"Who did the favor\"}," \
        + "{\"name\":\"receiver\",\"type\":0,\"required\":true,\"description\":\"Who received it\"}," \
        + "{\"name\":\"deed\",\"type\":0,\"required\":true,\"description\":\"What was done\"}," \
        + "{\"name\":\"favors_owed\",\"type\":1,\"required\":false,\"description\":\"Favors the receiver now owes\",\"defaultValue\":1}" \
        + "]"

    ; One template per place SkyrimNet shows the event. {{time_desc}} is added by SkyrimNet.
    ;   recent_events  scene context (the one NPCs see most)
    ;   raw            event history
    ;   compact        memories
    ;   verbose        diagnostics
    string formats = "{" \
        + "\"recent_events\":\"**{{giver}}** did {{receiver}} a favor: {{deed}} ({{time_desc}})\"," \
        + "\"raw\":\"{{giver}} did {{receiver}} a favor: {{deed}}\"," \
        + "\"compact\":\"{{giver}} helped {{receiver}} ({{deed}})\"," \
        + "\"verbose\":\"{{giver}} did {{receiver}} a favor ({{deed}}); {{receiver}} now owes {{favors_owed}}\"" \
        + "}"

    ; Not ephemeral: favors are worth remembering. Short-lived copies on, interrupting off.
    if SkyrimNetApi.RegisterEventSchema(FavorType(), "Favor", "Someone did someone else a favor", \
            fields, formats, false, 0, true, false) != 0
        Debug.Trace("[ExampleContext] RegisterEventSchema failed for " + FavorType())
    endif
EndFunction

; Sends one example_favor event. The content is JSON with the schema's fields.
Function RecordFavor(Actor akGiver, Actor akReceiver, string asDeed, int aiFavorsOwed) global
    string data = "{" \
        + "\"giver\":\"" + JsonEscape(akGiver.GetDisplayName()) + "\"," \
        + "\"receiver\":\"" + JsonEscape(akReceiver.GetDisplayName()) + "\"," \
        + "\"deed\":\"" + JsonEscape(asDeed) + "\"," \
        + "\"favors_owed\":" + aiFavorsOwed \
        + "}"

    ; ValidateEventData checks the JSON against the schema. Cheap, and it turns a typo in a field
    ; name into a log line instead of an event that silently formats wrong.
    if !SkyrimNetApi.ValidateEventData(FavorType(), data)
        Debug.Trace("[ExampleContext] Invalid " + FavorType() + " event: " + data)
        return
    endif
    SkyrimNetApi.RegisterEvent(FavorType(), data, akGiver, akReceiver)
EndFunction

; Escapes quotes and backslashes so names and item names can go inside a JSON string.
string Function JsonEscape(string s) global
    string out = ""
    int i = 0
    int n = StringUtil.GetLength(s)
    while i < n
        string c = StringUtil.GetNthChar(s, i)
        if c == "\"" || c == "\\"
            out += "\\" + c
        else
            out += c
        endif
        i += 1
    endwhile
    return out
EndFunction
