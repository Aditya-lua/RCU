--[[
  thread_manager.lua
  Thread management extracted from RCU_Main_Final_Fixed.lua.
  Provides a simple key-based thread registry with Add/Stop/StopAll.
]]

local ThreadManager = {}
ThreadManager.__index = ThreadManager

--- Creates a new ThreadManager instance.
function ThreadManager.new()
    local self = setmetatable({}, ThreadManager)
    self.threads = {}
    return self
end

--- Registers a thread under a key, stopping any previous thread with the same key.
function ThreadManager:Add(key, thread)
    self:Stop(key)
    self.threads[key] = thread
    return thread
end

--- Stops and removes a thread by key.
function ThreadManager:Stop(key)
    if self.threads[key] then
        self.threads[key] = nil
    end
end

--- Stops and removes all tracked threads.
function ThreadManager:StopAll()
    self.threads = {}
end

--- Returns the number of currently tracked threads.
function ThreadManager:Count()
    local n = 0
    for _ in pairs(self.threads) do n = n + 1 end
    return n
end

--- Returns whether a thread is tracked under the given key.
function ThreadManager:Has(key)
    return self.threads[key] ~= nil
end

return ThreadManager
