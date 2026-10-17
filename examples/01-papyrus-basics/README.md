# 01: Papyrus basics

The smallest useful SkyrimNet plugin: NPC actions defined in YAML that call Papyrus, a SkyrimNet
version check, and game events pushed to SkyrimNet. No C++, no PapyrusUtil.

Theme: tavern manners. NPCs can buy a round, share a drink or tell a tale, and SkyrimNet hears about
the player's evenings at the inn.

## What is where

| File | What it shows |
|---|---|
| `layer/example.papyrus-basics/manifest.json` | The external layer's identity. The folder name must equal `id` |
| `layer/.../actions/TavernManners.yaml` | A **category**: `customCategory` and no `executionFunctionName` |
| `layer/.../actions/BuyRound.yaml` | `speaker` + `static` parameters; a decorator eligibility rule with a form id |
| `layer/.../actions/ShareDrink.yaml` | A `dynamic` Actor parameter the LLM fills from nearby actors |
| `layer/.../actions/TellTale.yaml` | A narrative action: the recorded event is the effect; `isShortLived` |
| `scripts/ExB_Actions.psc` | The quest script the YAML calls. One function per action |
| `scripts/ExB_Compat.psc` | "Is SkyrimNet loaded, and new enough?" Copy this file into your mod |
| `scripts/ExB_PlayerAlias.psc` | Short-lived, normal and persistent events, and when to use each |
| `spriggit/ExampleBasics/` | The plugin: one start-game-enabled quest with a player alias |

## How an action flows

1. SkyrimNet loads `BuyRound.yaml` from the layer and registers the action.
2. When an NPC could act, SkyrimNet checks `eligibilityRules`. Here: the NPC has 10 gold and is not
   fighting.
3. The LLM sees the `TavernManners` category. If it picks it, it then sees the three actions inside.
4. If it picks `BuyRound`, SkyrimNet calls `ExB_Actions.BuyRound(speaker, 10)` on quest `ExB_Quest`,
   with arguments in `parameterMapping` order.
5. On success it records `eventString` as an event, so NPCs remember who paid.

## Which event call to use

| Call | Stored? | NPCs react? | Use for |
|---|---|---|---|
| `RegisterShortLivedEvent` | No, expires after its TTL | Context only | What is happening right now. Re-registering an id replaces it |
| `RegisterEvent("custom", text, ...)` | Yes | They may | Something that happened, worth remembering |
| `RegisterPersistentEvent` | Yes | No | Background facts that should not interrupt the scene |
| `DirectNarration` | Yes | Yes, one responds | Something that demands a reaction ("a wolf howls") |

`RegisterEvent` takes plain text only with type `"custom"`. Your own event type needs a schema
first, which example 02 shows.

## Try it

```powershell
./build.ps1                         # from the repo root
./build.ps1 -DeployDir "D:\MO2\mods"   # and install into MO2
```

Enable `ExampleBasics.esp`, walk into an inn and have a drink. SkyrimNet's event history shows the
events; ask an NPC to buy you a round.
