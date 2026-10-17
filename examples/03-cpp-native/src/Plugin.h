#pragma once

// The plugin's parts. main.cpp calls each Register() once SkyrimNet is connected.

namespace Events
{
    void Register();

    // Lines of dialogue this actor has spoken since the game started. Thread-safe.
    int LinesSpoken(RE::FormID actor);
}

namespace Decorators
{
    void Register();
}

namespace Actions
{
    void Register();
}
