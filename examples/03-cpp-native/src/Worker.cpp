#include "Worker.h"

#include <condition_variable>
#include <deque>
#include <thread>

namespace Worker
{
    namespace
    {
        struct Queue
        {
            std::mutex                        mutex;
            std::condition_variable           ready;
            std::deque<std::function<void()>> tasks;
        };

        // The thread owns a reference to the queue and is detached, so neither is ever torn down.
        // That is deliberate: the game ends the process without unloading plugins, and joining a thread
        // from a static destructor during shutdown can hang.
        std::shared_ptr<Queue> Start()
        {
            auto queue = std::make_shared<Queue>();
            std::thread([queue] {
                for (;;) {
                    std::function<void()> task;
                    {
                        std::unique_lock lock(queue->mutex);
                        queue->ready.wait(lock, [&] { return !queue->tasks.empty(); });
                        task = std::move(queue->tasks.front());
                        queue->tasks.pop_front();
                    }
                    try {
                        task();
                    } catch (const std::exception& e) {
                        logger::error("Worker task failed: {}", e.what());
                    }
                }
            }).detach();
            return queue;
        }
    }

    void Post(std::function<void()> task)
    {
        static const auto queue = Start();
        {
            std::lock_guard lock(queue->mutex);
            queue->tasks.push_back(std::move(task));
        }
        queue->ready.notify_one();
    }
}
