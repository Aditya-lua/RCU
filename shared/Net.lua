--[[
    shared/Net.lua
    Networking helpers: safe remote invocation, module resolution, etc.

    Usage:
        local Net = loadstring(game:HttpGet("...shared/Net.lua"))()
        Net.fireRemote(someRemoteEvent, arg1, arg2)
        local result = Net.invokeRemote(someRemoteFunction, arg1)
        local mod    = Net.resolvePath(RS, "Source", "Shared", "Configs", "Foo")
        local data   = Net.safeRequire(mod, "Foo")
]]

local Net = {}

local tableUnpack = table.unpack or unpack

--- FireServer on a RemoteEvent with pcall protection.
-- @return boolean  true if the call succeeded
function Net.fireRemote(remote, ...)
    if not remote or type(remote.FireServer) ~= "function" then return false end
    local args = { ... }
    local argCount = select("#", ...)
    local ok = pcall(function()
        remote:FireServer(tableUnpack(args, 1, argCount))
    end)
    return ok
end

--- InvokeServer on a RemoteFunction with pcall protection.
-- @return any  the server's return value, or nil on failure
function Net.invokeRemote(remote, ...)
    if not remote or type(remote.InvokeServer) ~= "function" then return nil end
    local args = { ... }
    local argCount = select("#", ...)
    local ok, result = pcall(function()
        return remote:InvokeServer(tableUnpack(args, 1, argCount))
    end)
    return ok and result or nil
end

--- Walk an Instance tree from `root` through successive child names.
-- @return Instance?  the final child, or nil if any step is missing
function Net.resolvePath(root, ...)
    local current = root
    for _, name in ipairs({ ... }) do
        if not current then return nil end
        current = current:FindFirstChild(tostring(name))
    end
    return current
end

--- pcall-protected require() with optional warning.
-- @param module  ModuleScript instance
-- @param label   string   human-readable name for warnings
-- @param silent  boolean? suppress warnings (default false)
-- @return any  the required module value, or nil on failure
function Net.safeRequire(module, label, silent)
    if not module or not module:IsA("ModuleScript") then
        if not silent then warn("[RCU] Not a module: " .. tostring(label)) end
        return nil
    end
    local ok, result = pcall(require, module)
    if not ok then
        if not silent then warn("[RCU] require failed for " .. tostring(label) .. ": " .. tostring(result)) end
        return nil
    end
    return result
end

--- Convenience: resolve a path under ReplicatedStorage and require it.
-- @param RS     ReplicatedStorage instance
-- @param label  string  human-readable name
-- @param ...    string  child path segments
-- @return any  the required module value, or nil
function Net.requirePath(RS, label, ...)
    local module = Net.resolvePath(RS, ...)
    if not module then
        warn("[RCU] Missing module: " .. tostring(label))
        return nil
    end
    return Net.safeRequire(module, label, true)
end

return Net
