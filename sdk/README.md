# SkyrimNet SDK

**Generated. Do not edit.** SkyrimNet's release CI overwrites this folder on every release; a local
edit is lost and hides an API mismatch from you.

| Path | What it is |
|---|---|
| `VERSION` | The SkyrimNet release these files came from |
| `cpp/PublicAPI.h` | The C++ API. Include it from exactly one `.cpp` (see `examples/03-cpp-native/src/SkyrimNetBridge.cpp`) |
| `cpp/PublicAPIMemoryQuery.h`, `cpp/PublicAPIDiaryQuery.h` | Query structs used by `PublicAPI.h` |
| `papyrus/SkyrimNetApi.psc` | The Papyrus API. Compile against it; never ship it (SkyrimNet ships the real one) |

How the sync works: [docs/sdk-sync.md](../docs/sdk-sync.md).
