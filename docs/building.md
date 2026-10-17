# Building

## Prerequisites

| For | Install |
|---|---|
| Everything | CMake 3.25+ and Ninja: Visual Studio 2022, or `winget install Kitware.CMake Ninja-build.Ninja` |
| The `.esp` files | .NET SDK: `winget install Microsoft.DotNet.SDK.9`. Spriggit uses it to fetch its serializer on first run, so the first build needs the internet |
| The C++ example | Visual Studio 2022 with "Desktop development with C++", and `VCPKG_ROOT` set to a clone of https://github.com/microsoft/vcpkg |

Then fetch the pinned tools once:

```powershell
./scripts/fetch-tools.ps1
```

It downloads the Papyrus compiler and Spriggit into `external-tools/`, checking each SHA-256 against
`tools.json`.

## Presets

| Preset | Builds | Needs |
|---|---|---|
| `papyrus` (default) | 01, 02 | CMake, Ninja, .NET SDK |
| `full` | 01, 02, 03 | Plus Visual Studio 2022 and vcpkg |

```powershell
./build.ps1                                  # papyrus
./build.ps1 -Preset full
./build.ps1 -DeployDir "D:\MO2\mods"         # also copy each example into your mods folder
```

`build.ps1` enters a Visual Studio developer shell when one is installed, then runs
`cmake --preset` and `cmake --build --preset`. From a shell that already has the tools, those two
commands are all it does.

The first `full` build compiles CommonLibSSE through vcpkg, which takes several minutes. vcpkg
caches it for later builds.

## What a build produces

```
dist/
    ExampleBasics/       ExampleBasics.zip      the mod folder, and the same zipped
    ExampleContext/      ExampleContext.zip
    ExampleNative/       ExampleNative.zip
```

Each folder is exactly what a user installs: the `.esp`, `Scripts/*.pex`, `Source/Scripts/*.psc`, the
DLL in `SKSE/Plugins/`, and the layer under `SKSE/Plugins/SkyrimNet/external/`.

## The plugin file: Spriggit

Each Papyrus example keeps its `.esp` as Spriggit JSON under `spriggit/<Name>/`, so changes show up in
a diff. The build turns it into an ESL-flagged `.esp`.

To change the plugin:

1. Build and install the example.
2. Edit the installed `.esp` in xEdit or the Creation Kit.
3. Write it back to the source:
   ```powershell
   ./scripts/spriggit-sync.ps1 "D:\MO2\mods\ExampleBasics\ExampleBasics.esp"
   ```
4. Review `git diff` and commit.

The serializer is pinned in each `spriggit-meta.json` (`Spriggit.Json.Skyrim` 0.40.1). Keep it there:
the 0.41.0 package on NuGet does not install.

## Adding your own plugin

Put it in `examples/<yours>/` with a `CMakeLists.txt` like the examples':

```cmake
skyrimnet_example(
    NAME         MyMod                      # the .esp and the mod folder name
    SPRIGGIT_DIR spriggit/MyMod             # optional
    SCRIPTS_DIR  scripts                    # optional
    LAYER_DIR    layer/myname.my-mod        # required; must contain manifest.json
    DLL_TARGET   MyModDll)                  # optional, for a C++ plugin
```

then add `add_subdirectory(examples/<yours>)` to the root `CMakeLists.txt`. The build fails early
if the layer folder and the manifest id disagree.

## Continuous integration

`.github/workflows/build.yml` builds the `full` preset on every push and pull request and uploads
the zips. It also runs when SkyrimNet's release CI updates `sdk/`, so an API change that breaks an
example is caught before it is merged.
