# Version compatibility

A SkyrimNet plugin meets three different SkyrimNet versions: the one it was written for, the one a
user installs it on, and every one after. Check at each level your mod has.

## 1. The layer: `min_skyrimnet_version`

Every `manifest.json` carries the oldest SkyrimNet it works with:

```json
"min_skyrimnet_version": "0.25.0"
```

This is advisory. When a user installs a plugin through the Content Library and it asks for a newer
SkyrimNet, the plugin installs disabled with a message naming both versions. External layers are
always loaded, so the runtime checks below still matter.

A content root the running SkyrimNet does not know (say, a folder added in a later release) is
skipped with a warning in `SkyrimNet.log`. State the release your mod needs in its description.

## 2. Papyrus: the DLL, then the version

```papyrus
bool Function IsSkyrimNetCompatible() global
    if SKSE.GetPluginVersion("SkyrimNet") == -1
        return false            ; not installed: calling its natives would fail silently
    endif
    return CompareVersions(SkyrimNetApi.GetBuildVersion(), "0.25.0") >= 0
EndFunction
```

The full script, with a numeric comparison, is `examples/01-papyrus-basics/scripts/ExB_Compat.psc`.
Copy it under your own prefix. Run it on every load (`OnPlayerLoadGame`), since SkyrimNet can be
updated or removed between sessions, and keep its minimum in step with your manifest.

## 3. C++: the API version, then the pointers

`PublicGetVersion()` returns the C++ API version. `FindFunctions()` resolves only the functions that
version should have; the rest stay `nullptr`.

| API | Added |
|---|---|
| 2 | Action registration |
| 3 | Data queries, UUIDs, plugin config |
| 4 | Diary queries |
| 5 | Decorators, event callbacks, memory creation |
| 6 | Actor busy state |
| 7 | Save id, world knowledge |
| 8 | Custom prompts to the LLM |
| 9 | Per-actor world knowledge |
| 10 | Filtered memory queries |
| 11 | Timeline state, diary edits, actor search, events with an audience |
| 12 | Custom decisions |

The authoritative list is the comment on `PublicGetVersion` in `sdk/cpp/PublicAPI.h`.

Require the version your core features need, then decide optional features from whether their
pointer resolved. See `Connect()` in `examples/03-cpp-native/src/SkyrimNetBridge.cpp`.

## Updating the SDK

`sdk/` is synced from SkyrimNet on every release (see [sdk-sync.md](sdk-sync.md)). When you update
your copy, raise your minimum only if you start using something new.
