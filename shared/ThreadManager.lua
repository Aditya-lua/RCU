--[[
    shared/ThreadManager.lua
    A simple thread lifecycle manager — start, stop, and bulk-cancel named threads.

    Usage:
        local ThreadManager = loadstring(game:HttpGet("...shared/ThreadManager.lua"))()
        local tm = ThreadManager.new()

        tm:Add("autoFarm", task.spawn(function() ... end))
        tm:Stop("autoFarm")
        tm:StopAll()
]]

local ThreadManager = {}
ThreadManager.__index = ThreadManager

function ThreadManager.new()
    return setmetatable({ threads = {} }, ThreadManager)
end

function ThreadManager:Add(key, thread)
    self:Stop(key)
    self.threads[key] = thread
    return thread
end

function ThreadManager:Stop(key)
    if self.threads[key] then
        pcall(function() task.cancel(self.threads[key]) end)
        self.threads[key] = nil
    end
end

function ThreadManager:StopAll()
    for key, thread in pairs(self.threads) do
        pcall(function() task.cancel(thread) end)
    end
    self.threads = {}
end

return ThreadManager
