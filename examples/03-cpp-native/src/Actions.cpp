#include "Plugin.h"
#include "SkyrimNetBridge.h"
#include "Worker.h"

namespace Actions
{
    namespace
    {
        constexpr auto       kCategory = "NativeSenses";
        constexpr RE::FormID kGold = 0x0000000F;   // Skyrim.esm Gold001
        constexpr RE::FormID kPlayer = 0x00000014;
        constexpr int        kMaxCoins = 50;

        // Eligibility runs on a worker thread, for many NPCs, often. Read-only engine calls only.
        bool CanAct(RE::Actor* actor)
        {
            return actor && !actor->IsPlayerRef() && !actor->IsInCombat();
        }

        // Execute callbacks run on the game thread, so this may change the game directly. Keep it short:
        // the frame waits for it. Parameters come from the LLM: parse defensively, clamp, and return false
        // rather than guess.
        bool TossCoins(RE::Actor* actor, const std::string& params)
        {
            const auto json = nlohmann::json::parse(params, nullptr, false);
            if (!actor || !json.is_object() || !json.contains("amount") || !json["amount"].is_number_integer()) {
                return false;
            }
            auto* gold = RE::TESForm::LookupByID<RE::TESBoundObject>(kGold);
            auto* player = RE::PlayerCharacter::GetSingleton();
            const int amount = std::min({ json["amount"].get<int>(), kMaxCoins, actor->GetGoldAmount() });
            if (!gold || !player || amount <= 0) {
                return false;
            }
            actor->RemoveItem(gold, amount, RE::ITEM_REMOVE_REASON::kStoreInContainer, nullptr, player);
            return true;
        }

        // A database query would stall the game thread, so the execute callback only copies what the work
        // needs (form ids and names, never the Actor*) and hands it to the worker.
        bool Reminisce(RE::Actor* actor, const std::string&)
        {
            if (!actor) {
                return false;
            }
            const RE::FormID npc = actor->GetFormID();
            const std::string npcName = actor->GetDisplayFullName();
            const std::string playerName = RE::PlayerCharacter::GetSingleton()->GetName();

            Worker::Post([npc, npcName, playerName] {
                if (!SkyrimNetBridge::IsMemorySystemReady()) {
                    return;
                }
                MemoryQuery query;
                query.maxCount = 1;
                query.contextQuery = playerName;   // the memory most about the player
                query.orderBy = MemoryOrder::Relevance;
                const auto memories = nlohmann::json::parse(SkyrimNetBridge::QueryMemories(npc, query), nullptr, false);
                if (!memories.is_array() || memories.empty() || !memories[0].contains("text")) {
                    return;
                }

                // direct_narration makes the originator react out loud. The audience limits who perceives
                // it: a private moment between the two, not news for everyone in the room.
                const RE::FormID audience[] = { npc, kPlayer };
                SkyrimNetBridge::RegisterEvent("direct_narration",
                    npcName + " is reminded of something and tells " + playerName + ": " +
                        memories[0]["text"].get<std::string>(),
                    npc, kPlayer, audience);
            });
            return true;
        }
    }

    void Register()
    {
        const auto& features = SkyrimNetBridge::GetFeatures();
        if (!features.actions) {
            return;
        }

        SkyrimNetBridge::RegisterCategory(kCategory,
            "Small gestures that come naturally: a tip, a shared memory. Choose this to open them.", CanAct);

        SkyrimNetBridge::RegisterAction({
            .name = "TossCoins",
            .description = "Toss the player a few coins: a tip, a bribe, or charity.",
            .category = kCategory,
            .parameterSchema = R"({"type":"object","properties":{"amount":{"type":"integer","minimum":1,"maximum":50,)"
                               R"("description":"How many coins to toss"}},"required":["amount"]})",
            .isEligible = [](RE::Actor* actor) { return CanAct(actor) && actor->GetGoldAmount() > 0; },
            .execute = TossCoins,
        });

        // Optional features are offered only when the installed SkyrimNet has them.
        if (features.memoryQueries && features.audienceEvents) {
            SkyrimNetBridge::RegisterAction({
                .name = "ReminisceWithPlayer",
                .description = "Recall a memory you share with the player and tell them about it.",
                .category = kCategory,
                .isEligible = CanAct,
                .execute = Reminisce,
            });
        }
    }
}
