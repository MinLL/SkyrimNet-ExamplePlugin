# Third-party Papyrus headers

`papyrus-headers/` holds the script sources the examples compile against but do not own: vanilla
Skyrim, SKSE, PapyrusUtil (`StorageUtil`, `ActorUtil`) and powerofthree's Papyrus Extender. They are
the same files the SkyrimNet GamePlugin compiles against, and they belong to their authors.

Never ship them in your mod. Each comes with the game or with the mod that provides it; the examples'
packaging copies only their own scripts.

Need a header that is not here (another mod's API)? Add its `.psc` to this folder.
