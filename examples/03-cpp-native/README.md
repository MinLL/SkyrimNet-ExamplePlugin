# 03: C++ SKSE plugin

An SKSE plugin that talks to SkyrimNet through its C++ API: decorators, a category of actions, a
dialogue event callback, a memory query and an event with a chosen audience. Built on CommonLibSSE-NG
(the [MinLL/CommonLibVR](https://github.com/MinLL/CommonLibVR) `ng` branch, MIT), one DLL for SE,
AE and VR.

Theme: native senses. NPCs know how full their purse is, remember who has been chatty, can toss
the player a few coins, and can bring up a memory they share with the player.

## What is where

| File | What it shows |
|---|---|
| `src/SkyrimNetBridge.h/.cpp` | The one file that includes `PublicAPI.h`. `Connect()`, a `Features` struct, typed wrappers |
| `src/main.cpp` | SKSE entry point; connects and registers at `kDataLoaded` |
| `src/Decorators.cpp` | Two decorators: plugin state (`native_senses_lines_spoken`) and game data (`native_senses_purse`) |
| `src/Actions.cpp` | A category with two actions; JSON parameters; game-thread vs worker work |
| `src/Events.cpp` | A `dialogue` event callback that counts lines per speaker |
| `src/Worker.h/.cpp` | One background thread for database queries and other slow work |
| `layer/.../user_final_instructions/0670_example_native_senses.prompt` | The decorators used in a prompt |

## Threads: where each callback runs

| Callback | Thread | May |
|---|---|---|
| Action `execute` | **Game thread** | Change the game directly (items, AI). Must return quickly; no I/O, no queries |
| Action `isEligible`, category eligibility | SkyrimNet worker | Read game state. Called often, for many NPCs |
| Decorator | SkyrimNet worker (prompt render) | Read game state or your own state. Return `""` when unsure |
| Event callback | SkyrimNet worker | Parse the JSON, update your state. No `RE::` calls |
| `Worker::Post` task | This plugin's worker | Memory queries, `RegisterEvent`, file I/O |

`ReminisceWithPlayer` shows the hand-off: its `execute` runs on the game thread, copies form ids and
names, and posts the memory query to the worker. It never captures the `RE::Actor*`.

## Version checks

`Connect()` requires API v5 (decorators and event callbacks) and then decides each feature from
whether its function pointer resolved. `ReminisceWithPlayer` is registered only when memory queries
(v10) and audience events (v11) are both there, so the plugin still works on an older SkyrimNet,
with one action fewer. The log says which features are on.

## Things that are easy to get wrong

- **Keep `PublicAPI.h` behind one bridge file.** Version checks then live in one place, and it works
  with older copies of the header (before SkyrimNet 0.28), which define globals and fail to link when
  a second `.cpp` includes them.
- **Action categories:** a category is `PublicRegisterCPPSubCategory` with its own name as
  `customCategory`. An action joins it with type `CPP_NESTED_ACTION` and the same `customCategory`.
  Top-level actions use `CPP`. Other values are treated as `CPP`.
- **Decorator names are global.** Prefix them. The bridge refuses a name that already exists.
- **Prompts that call your decorators** go in a folder rendered file by file, like
  `user_final_instructions`. `character_bio` files are joined into one template, so if your DLL failed
  to load, an unknown function there would break every NPC's bio.
- **Same compiler and CRT as SkyrimNet.** The API passes `std::string` and `std::function` across the
  DLL boundary. Build with MSVC 2022 and the static CRT (`/MT`), as the `full` preset does.

## Build

```powershell
./build.ps1 -Preset full    # needs Visual Studio 2022 (C++ workload) and VCPKG_ROOT
```

The first build compiles CommonLibSSE through vcpkg and takes several minutes; later builds reuse it.
