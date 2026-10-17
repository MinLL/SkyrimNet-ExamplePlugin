#include "Plugin.h"
#include "SkyrimNetBridge.h"

namespace Events
{
    namespace
    {
        std::mutex                             g_mutex;
        std::unordered_map<RE::FormID, int>    g_linesSpoken;

        // Runs on a SkyrimNet worker thread for every "dialogue" event. Keep it short: parse, count,
        // return. No RE:: calls here; everything needed is in the event JSON.
        void OnDialogue(const std::string& eventJson)
        {
            const auto event = nlohmann::json::parse(eventJson, nullptr, false);
            if (!event.is_object() || !event.contains("originatingActorFormId") ||
                !event["originatingActorFormId"].is_number_unsigned()) {
                return;
            }
            const auto speaker = event["originatingActorFormId"].get<RE::FormID>();
            if (speaker == 0) {
                return;
            }
            std::lock_guard lock(g_mutex);
            ++g_linesSpoken[speaker];
        }
    }

    void Register()
    {
        // A real mod would save these counts with SKSE serialization; this example keeps them per session.
        if (SkyrimNetBridge::OnEvent("dialogue", OnDialogue) == 0) {
            logger::warn("Could not listen for dialogue events");
        }
    }

    int LinesSpoken(RE::FormID actor)
    {
        std::lock_guard lock(g_mutex);
        const auto it = g_linesSpoken.find(actor);
        return it != g_linesSpoken.end() ? it->second : 0;
    }
}
