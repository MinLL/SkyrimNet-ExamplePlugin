# Best practices

How to integrate with SkyrimNet so that your mod is fast, survives SkyrimNet updates, and plays well
with other mods. Each rule names the example that shows it.

## Choose your path

| You want | Use | Example |
|---|---|---|
| NPCs to perform an action your mod implements | A YAML action calling a quest-script function | 01 |
| Group related actions | A YAML category | 01 |
| Tell SkyrimNet something happened | `RegisterEvent` / `RegisterShortLivedEvent` / `RegisterPersistentEvent` | 01 |
| Structured events, picked out in prompts | `RegisterEventSchema` + JSON events | 02 |
| Your mod's state in NPC prompts (Papyrus mod) | StorageUtil + `papyrus_util(...)` in a prompt submodule | 02 |
| Your mod's state in NPC prompts (DLL) | A C++ decorator | 03 |
| Actions with real logic, or data from SkyrimNet's database | The C++ API | 03 |

## Deprecated: do not use

| Instead of | Use | Why |
|---|---|---|
| `SkyrimNetApi.RegisterAction` from Papyrus | A YAML file in your layer's `actions/` | YAML is visible and editable in the dashboard, users can override it, and it needs no script to run at load |
| `SkyrimNetApi.RegisterSubCategory` | A YAML category: `customCategory`, no `executionFunctionName` | Same |
| `SkyrimNetApi.RegisterDecorator` | `papyrus_util` (Papyrus mods) or `PublicRegisterDecorator` (DLLs) | A Papyrus decorator is a VM round trip on every prompt render, on the render's critical path |
| Loose files under `SKSE/Plugins/SkyrimNet/config/` or `prompts/` | An external layer | Loose files are no longer read |

## Ship content as an external layer

```
SKSE/Plugins/SkyrimNet/external/<author>.<slug>/
    manifest.json
    actions/  prompts/  triggers/  knowledge/ ...
```

- The folder name must equal the manifest `id`, and `author` must equal the id's author segment.
  `skyrimnet` and `skyrimnet-*` are reserved.
- Extensions are exact and case-sensitive: `.yaml`, `.prompt`. Paths are ASCII.
- An action or trigger file's name equals its `name` field: `BuyRound.yaml` holds `name: BuyRound`.
- SkyrimNet never writes inside `external/`. Users who edit your content get a copy in their
  overlay, and yours stays untouched.
- Run `content-validate` on your layer before you ship (`external-tools/skyrimnet/`), and fix every
  error. "Unresolved" lines about game variables are expected offline.

Full reference: [modding/CONTENT_ROOTS.md](modding/CONTENT_ROOTS.md).

## Names

- **Prefix everything your mod owns** with one short prefix: scripts, editor ids, StorageUtil keys,
  decorators, event types (`ExC_FavorsOwed`, `native_senses_purse`, `example_favor`).
- **Action names** are read by the LLM, so make them plain words that say what happens
  (`ShareDrink`), and specific enough that another mod is unlikely to use the same one.

## Papyrus

- **Check SkyrimNet before calling it**: `SKSE.GetPluginVersion("SkyrimNet") != -1`, then compare
  `GetBuildVersion()` with your minimum. A native call into a missing DLL fails silently. (01:
  `ExB_Compat`)
- **Action functions are short and defensive.** Validate every argument; the LLM chose the dynamic
  ones. The YAML's `eventString` records what happened, so the function only changes the game.
- **Event type `"custom"` takes plain text.** Any other type expects JSON matching a schema, and
  schemas live in memory: register yours on every game load. (02: `ExC_Events`)
- **Keep StorageUtil keys in one script.** Prompts and YAML use the same strings. (02: `ExC_Ledger`)
- **Filter hot events early.** `OnItemRemoved` and similar fire constantly; return on the cheapest
  check first.

## Prompts

- **Add submodule files; never replace SkyrimNet's.** A file at the same path as a base prompt
  replaces it for every user and goes stale when SkyrimNet updates its own.
- **Number files to place them** (`0650_` lands between `0600_relationships` and `0700_occupation`).
- **`character_bio` files test `render_mode` in an `{% if %}` within their first 5 lines.** The
  validator enforces it.
- **Render nothing when there is nothing to say.** An empty heading costs tokens and invites the LLM
  to make something up.
- **Calls to your own C++ decorators go in a folder rendered file by file**, such as
  `user_final_instructions`. `character_bio` files are joined into one template: if your DLL fails to
  load, an unknown function there breaks every NPC's bio. (03)

## C++

- **Include `PublicAPI.h` in exactly one `.cpp`.** It defines globals. Wrap it. (03: `SkyrimNetBridge`)
- **Decide features from resolved pointers**, not only from `PublicGetVersion()`, and register
  optional features only when present.
- **Respect the threads:**

  | Callback | Runs on | Rule |
  |---|---|---|
  | Action execute | Game thread | Change the game here, quickly. No I/O, no queries |
  | Eligibility, decorators | SkyrimNet workers | Read only, fast, thread-safe |
  | Event callbacks | SkyrimNet workers | No `RE::` calls; parse and update your own state |
  | Database queries, file I/O | Your worker thread | Never on the game thread |

- **Capture form ids, not `RE::Actor*`**, in anything that runs later.
- **Build with MSVC 2022 and the static CRT**, as SkyrimNet does. The API passes `std::string` and
  `std::function` across the DLL boundary.
- **Prefix decorator names.** SkyrimNet refuses a name that already exists.

## Test it

- In game, with SkyrimNet's MCP server enabled (port 8889), an agent can list the decorators your build
  really has, validate action YAML and prompts, and render a prompt for a real NPC. See `.mcp.json`.
- The dashboard shows registered actions, recent events and each prompt as sent.
