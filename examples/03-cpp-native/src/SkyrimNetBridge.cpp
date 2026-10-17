#include "SkyrimNetBridge.h"

// Defines the API's function pointers. Include it in this file and no other.
#include "PublicAPI.h"

namespace SkyrimNetBridge
{
    namespace
    {
        // Decorators and event callbacks arrived in API v5. Below that, this plugin has nothing to do.
        constexpr int kMinimumApiVersion = 5;

        // CPP_SUB_CATEGORY, CPP_NESTED_ACTION and CPP are how SkyrimNet files C++ actions: a
        // category, an action inside one, and a top-level action.
        constexpr auto kCategoryType = "CPP_SUB_CATEGORY";
        constexpr auto kNestedActionType = "CPP_NESTED_ACTION";
        constexpr auto kTopLevelActionType = "CPP";

        Features g_features;
    }

    bool Connect()
    {
        if (!FindFunctions() || !PublicGetVersion) {
            logger::warn("SkyrimNet is not installed; staying idle");
            return false;
        }

        g_features.apiVersion = PublicGetVersion();
        if (g_features.apiVersion < kMinimumApiVersion) {
            logger::warn("SkyrimNet API v{} is older than v{}; staying idle", g_features.apiVersion, kMinimumApiVersion);
            return false;
        }

        // FindFunctions only resolves what the reported version should have, and a pointer can still be
        // null if an export is missing. Deciding features from the pointers covers both.
        g_features.actions = PublicRegisterCPPAction && PublicRegisterCPPSubCategory;
        g_features.decorators = PublicRegisterDecorator != nullptr;
        g_features.eventCallbacks = PublicRegisterEventCallback != nullptr;
        g_features.memoryQueries = PublicQueryMemoriesForActor && PublicIsMemorySystemReady;
        g_features.audienceEvents = PublicRegisterEvent != nullptr;

        logger::info("SkyrimNet API v{}: actions {}, decorators {}, event callbacks {}, memory queries {}, audience events {}",
            g_features.apiVersion, g_features.actions, g_features.decorators, g_features.eventCallbacks,
            g_features.memoryQueries, g_features.audienceEvents);
        return true;
    }

    const Features& GetFeatures()
    {
        return g_features;
    }

    bool RegisterCategory(const std::string& name, const std::string& description,
        std::function<bool(RE::Actor*)> isEligible, int priority)
    {
        if (!g_features.actions) {
            return false;
        }
        // A category's own key is its name: actions join it by naming it as their category.
        return PublicRegisterCPPSubCategory(name, description, std::move(isEligible), "", priority, "{}", name, "", "");
    }

    bool RegisterAction(const Action& action)
    {
        if (!g_features.actions) {
            return false;
        }
        const auto* type = action.category.empty() ? kTopLevelActionType : kNestedActionType;
        auto execute = [fn = action.execute](RE::Actor* actor, std::string params) { return fn(actor, params); };
        return PublicRegisterCPPAction(action.name, action.description, action.isEligible, execute, "", type,
            action.priority, action.parameterSchema, action.category, "", "");
    }

    bool RegisterDecorator(const std::string& name, const std::string& description,
        std::function<std::string(RE::Actor*)> decorator)
    {
        if (!g_features.decorators) {
            return false;
        }
        if (PublicHasDecorator && PublicHasDecorator(name.c_str())) {
            logger::error("Decorator {} already exists; pick a name with your mod's prefix", name);
            return false;
        }
        return PublicRegisterDecorator(name.c_str(), description.c_str(), std::move(decorator));
    }

    std::uint64_t OnEvent(const std::string& eventType, std::function<void(const std::string& eventJson)> callback)
    {
        if (!g_features.eventCallbacks) {
            return 0;
        }
        // The const char* SkyrimNet passes is only valid during the call; copying it into a std::string
        // here means callbacks never have to think about that.
        return PublicRegisterEventCallback(eventType.c_str(), [fn = std::move(callback)](const char* json) {
            fn(json ? std::string(json) : std::string());
        });
    }

    bool IsMemorySystemReady()
    {
        return g_features.memoryQueries && PublicIsMemorySystemReady();
    }

    std::string QueryMemories(RE::FormID actor, const MemoryQuery& query)
    {
        return g_features.memoryQueries ? QueryMemoriesForActor(actor, query) : "[]";
    }

    int RegisterEvent(const std::string& eventType, const std::string& content, RE::FormID originator,
        RE::FormID target, std::span<const RE::FormID> audience)
    {
        if (!g_features.audienceEvents) {
            return 0;
        }
        return PublicRegisterEvent(eventType.c_str(), content.c_str(), originator, target, audience.data(),
            static_cast<std::uint32_t>(audience.size()));
    }
}
