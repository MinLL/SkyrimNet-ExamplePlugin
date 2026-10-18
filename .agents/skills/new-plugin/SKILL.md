---
name: new-plugin
description: Start a new SkyrimNet plugin in examples/ from one of the reference examples, renaming prefixes, IDs, CMake targets, and Spriggit records.
---

# New plugin

Create a new plugin in `examples/` by copying the example closest to what the author wants and
renaming everything that identifies it. Renaming by hand is where authors go wrong: a missed prefix
means two mods fighting over one script name.

## 1. Ask

Ask for anything not already given:

- **What the mod should do.** Pick the starting example from the table in `AGENTS.md` and say why.
- **Mod name** in PascalCase (`TavernTales`). Used for the `.esp`, the quest, the folder in `dist/`.
- **Prefix**, 2-4 letters plus `_` (`TT_`). Suggest one from the name.
- **Layer id**, `<author>.<slug>`: lowercase `[a-z0-9_-]`, author not `skyrimnet` (`bob.tavern-tales`).

## 2. Copy and rename

Copy `examples/<source>` to `examples/<mod-name-kebab>`. Then, in the copy only:

| What | Example 01 value | Becomes |
|---|---|---|
| Script prefix, in file names and inside every `.psc`, `.yaml`, `.prompt` | `ExB_` | the prefix |
| Mod name in `CMakeLists.txt`, `spriggit/<Name>/`, `ModKey` and `FormKey`s | `ExampleBasics` | the mod name |
| Quest editor id (`questEditorId` in YAML, `EditorID` in Spriggit) | `ExB_Quest` | `<prefix>Quest` |
| Layer folder and manifest `id`; manifest `author` | `example.papyrus-basics`, `example` | the layer id, its author |
| Manifest `title`, `tagline`, `description`, `mods[].file`, `version: 1.0.0` | | the new mod's |
| Spriggit file names (`<EditorID> - <FormID>_<ModKey>.json`) | | match the renamed records |
| C++ (03): target and `NAME` in `CMakeLists.txt`, decorator prefix, action names | `ExampleNative`, `native_senses_` | the new names |

Then grep the copy for every old name and prefix; there must be no hits left. Rename the example's
actions, decorators and event types to fit the new mod rather than keeping the example's.

Add `add_subdirectory(examples/<new>)` to the root `CMakeLists.txt`.

## 3. Build and validate

1. `./build.ps1` (or `-Preset full` for a C++ plugin). Fix every error and warning.
2. `external-tools/skyrimnet/content-validate.exe examples/<new>/layer/<id>`: 0 errors.
3. Show the author the new folder tree and what to edit first.

