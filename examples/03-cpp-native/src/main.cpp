#include "Plugin.h"
#include "SkyrimNetBridge.h"

namespace
{
    void OnSkseMessage(SKSE::MessagingInterface::Message* message)
    {
        // kDataLoaded: every SKSE plugin (SkyrimNet included) is loaded and the game's forms exist.
        // SkyrimNet accepts actions, decorators and callbacks from here on, before any save is loaded.
        if (message->type != SKSE::MessagingInterface::kDataLoaded) {
            return;
        }
        if (!SkyrimNetBridge::Connect()) {
            return;
        }
        Events::Register();  // first: the decorators read what the event callback counts
        Decorators::Register();
        Actions::Register();
    }
}

SKSEPluginLoad(const SKSE::LoadInterface* skse)
{
    // Also opens the log: Documents/My Games/Skyrim Special Edition/SKSE/ExampleNative.log
    SKSE::Init(skse);
    logger::info("ExampleNative loaded");

    SKSE::GetMessagingInterface()->RegisterListener(OnSkseMessage);
    return true;
}
