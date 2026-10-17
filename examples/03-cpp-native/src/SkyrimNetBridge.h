#pragma once

#include "PublicAPIMemoryQuery.h"

// The plugin's only door into SkyrimNet.
//
// Only SkyrimNetBridge.cpp includes SkyrimNet's PublicAPI.h. Everything else calls the functions
// below, so every version check lives in one place. (It also keeps older copies of the header
// working: before SkyrimNet 0.28 they defined the function pointers as globals, and a second
// include failed to link.)
//
// Each function is safe to call whatever SkyrimNet is installed: it does nothing (and returns
// false, 0 or "") when the feature it needs is missing.
namespace SkyrimNetBridge
{
    // What the installed SkyrimNet supports. Decided once, in Connect().
    struct Features
    {
        int  apiVersion = 0;
        bool actions = false;         // API v2
        bool decorators = false;      // API v5
        bool eventCallbacks = false;  // API v5
        bool memoryQueries = false;   // API v10
        bool audienceEvents = false;  // API v11
    };

    // Resolves SkyrimNet's API. Call once, at kDataLoaded. Returns false when SkyrimNet is missing or
    // older than this plugin supports; the plugin should then stay idle.
    bool Connect();
    const Features& GetFeatures();

    struct Action
    {
        std::string name;
        std::string description;               // what the LLM reads when choosing
        std::string category;                  // the category this sits in; empty = top level
        std::string parameterSchema = "{}";    // JSON Schema for the parameters the LLM fills in
        int         priority = 50;
        // Called on a SkyrimNet worker thread, often. Read game state only, and quickly.
        std::function<bool(RE::Actor*)> isEligible;
        // Called on the game thread with the LLM's parameters as a JSON string. May change the game.
        std::function<bool(RE::Actor*, const std::string& params)> execute;
    };

    bool RegisterCategory(const std::string& name, const std::string& description,
        std::function<bool(RE::Actor*)> isEligible, int priority = 50);
    bool RegisterAction(const Action& action);

    // Called on a worker thread while a prompt renders. Return "" for actors you know nothing about.
    bool RegisterDecorator(const std::string& name, const std::string& description,
        std::function<std::string(RE::Actor*)> decorator);

    // Called on a SkyrimNet worker thread with the event as JSON. Do not call RE:: functions in it.
    std::uint64_t OnEvent(const std::string& eventType, std::function<void(const std::string& eventJson)> callback);

    // Memory queries read SkyrimNet's database: call them from a worker, never the game thread.
    bool        IsMemorySystemReady();
    std::string QueryMemories(RE::FormID actor, const MemoryQuery& query);  // JSON array, "[]" if none

    // Registers an event that only the audience (plus originator and target) perceives.
    // Returns the stored event's id, or 0 if nothing was stored.
    int RegisterEvent(const std::string& eventType, const std::string& content, RE::FormID originator,
        RE::FormID target, std::span<const RE::FormID> audience);
}
