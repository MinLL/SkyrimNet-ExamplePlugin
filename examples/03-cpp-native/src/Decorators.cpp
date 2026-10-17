#include "Plugin.h"
#include "SkyrimNetBridge.h"

// C++ decorators are the efficient way to give prompts data SkyrimNet does not have: they run in
// SkyrimNet's render thread, with no Papyrus VM round trip. Templates call them with an actor's UUID,
// {{ native_senses_purse(npc.UUID) }}, and SkyrimNet hands the callback the RE::Actor*.
//
// Rules for the callback: it runs on a worker thread, possibly many times per prompt. Read, never
// write. Be quick. Return "" for an actor you have nothing to say about.

namespace Decorators
{
    namespace
    {
        // Data only this plugin has: what its event callback counted.
        std::string LinesSpoken(RE::Actor* actor)
        {
            return actor ? std::to_string(Events::LinesSpoken(actor->GetFormID())) : "";
        }

        // Game data turned into words the LLM can use, instead of a raw number.
        std::string Purse(RE::Actor* actor)
        {
            if (!actor || actor->IsPlayerRef()) {
                return "";
            }
            const auto gold = actor->GetGoldAmount();
            if (gold < 10) {
                return "nearly empty";
            }
            if (gold < 100) {
                return "modest";
            }
            if (gold < 1000) {
                return "comfortable";
            }
            return "heavy";
        }
    }

    void Register()
    {
        // Prefix every name with your mod's: decorators share one namespace with SkyrimNet's own.
        SkyrimNetBridge::RegisterDecorator("native_senses_lines_spoken",
            "ExampleNative: lines of dialogue this actor has spoken this session", LinesSpoken);
        SkyrimNetBridge::RegisterDecorator("native_senses_purse",
            "ExampleNative: how full this actor's purse is (nearly empty, modest, comfortable, heavy)", Purse);
    }
}
