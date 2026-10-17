# SDK sync

`sdk/` is owned by SkyrimNet's release CI. This page is the contract between the two repos.

## What gets synced

| Here | From SkyrimNet-Core / GamePlugin |
|---|---|
| `sdk/VERSION` | The release version |
| `sdk/cpp/PublicAPI.h`, `PublicAPIMemoryQuery.h`, `PublicAPIDiaryQuery.h` | Core `include/` |
| `sdk/papyrus/SkyrimNetApi.psc` | GamePlugin `Source/Scripts/` |
| Release assets: `content-convert.exe`, `content-validate.exe` | Core's build |

Nothing else in this repo is touched by the sync. `docs/`, `.claude/` and `examples/` are edited
here by hand.

## How it runs

On a SkyrimNet release, Core's `selfhosted-build.yml`:

1. Runs `utilities/sync_sdk.py`, which writes the files above into a checkout of this repo.
2. Commits them to a branch `sdk/v<version>` and opens a pull request. This repo's CI builds all
   three examples against the new SDK; a breaking API change turns the PR red.
3. After the merge, tags `v<version>` and attaches the tools to that tag's GitHub Release, where
   `scripts/fetch-tools.ps1` finds them.

## Running it by hand

```powershell
# from SkyrimNet-Core
python utilities/sync_sdk.py --dest D:\repos\skyrimnet-plugin-examples --gameplugin D:\repos\skyrimnet-gameplugin
```

## When an example breaks

Fix the example in the sync PR before merging. If the break is in SkyrimNet's API rather than in the
example, the API change needs a version bump and a compatibility note in Core.
