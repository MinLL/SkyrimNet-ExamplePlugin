# 02: Papyrus + prompts

Getting your mod's data into NPC prompts without registering a single decorator. Papyrus stores
state with PapyrusUtil's StorageUtil; prompts and action rules read it with `papyrus_util(...)`
alongside SkyrimNet's built-in decorators. The mod also registers its own event type.

Theme: a favor ledger. Give an NPC something and they owe you a favor. They know it, the people
around them hear about it, and they can repay it.

Requires PapyrusUtil, which SkyrimNet already depends on.

## What is where

| File | What it shows |
|---|---|
| `scripts/ExC_Ledger.psc` | Every StorageUtil key in one place: per-NPC int and string, a global list |
| `scripts/ExC_Events.psc` | `RegisterEventSchema` for `example_favor`, JSON event content, `ValidateEventData` |
| `scripts/ExC_PlayerAlias.psc` | Registers the schema on every load; turns gifts into favors |
| `scripts/ExC_Actions.psc` | The `RepayFavor` action |
| `scripts/ExC_Compat.psc` | The version check from example 01, under this mod's prefix |
| `layer/.../actions/RepayFavor.yaml` | An eligibility rule on `papyrus_util` |
| `layer/.../prompts/submodules/character_bio/0650_example_favor_ledger.prompt` | `papyrus_util`, `decnpc`, `get_relationship_rank`, `get_recent_events` + `format_event` |
| `layer/.../prompts/submodules/user_final_instructions/0660_example_favor_gossip.prompt` | Reading a global StorageUtil list |

## The data flow

```
Player gives an NPC 2 Ale
  -> ExC_PlayerAlias.OnItemRemoved
       ExC_Ledger.AddFavor        StorageUtil: ExC_FavorsOwed +1, ExC_LastFavor, ExC_RecentDeeds
       ExC_Events.RecordFavor     SkyrimNet event "example_favor" {giver, receiver, deed, favors_owed}

The NPC's next prompt
  -> character_bio/0650...        papyrus_util("GetIntValue", actorUUID, "ExC_FavorsOwed", 0) ...
  -> user_final_instructions/...  papyrus_util("GetStringList", "none", "ExC_RecentDeeds")

The LLM considers actions
  -> RepayFavor.yaml              offered only if papyrus_util(...) > 0
  -> ExC_Actions.RepayFavor       ExC_Ledger.SpendFavor
```

Reading state at render time means the prompt is always current, and nothing runs in Papyrus while
SkyrimNet builds a prompt. That is why `papyrus_util` beats a Papyrus-registered decorator, which
calls into the Papyrus VM on every render.

## Prompt submodules

SkyrimNet builds prompts from numbered submodule files, and a layer adds files to those folders.
Pick a number that places yours where it reads naturally (0650 sits between relationships at 0600
and occupation at 0700). Do not ship a file with the same path as one of SkyrimNet's: that replaces
it for every user, and your copy goes stale when SkyrimNet updates its own.

Rules the validator enforces: a `character_bio` file tests `render_mode` in an `{% if %}` within
its first 5 lines. Render nothing when there is nothing to say.

## Custom event types

`RegisterEvent("custom", text, ...)` is fine for one-off text. Your own type gives events fields
and a format for each place they appear, and lets prompts pick them out (`event.type ==
"example_favor"`). Register the schema on every game load: SkyrimNet keeps schemas in memory.
