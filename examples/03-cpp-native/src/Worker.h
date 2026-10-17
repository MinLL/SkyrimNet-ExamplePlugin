#pragma once

// One background thread for work that must stay off the game thread: database queries, file I/O,
// anything that could take more than a moment. Tasks run one at a time, in the order posted.
//
// Capture form ids, not RE::Actor*: by the time a task runs, the actor may have unloaded.
namespace Worker
{
    void Post(std::function<void()> task);
}
