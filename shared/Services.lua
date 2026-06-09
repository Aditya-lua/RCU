--[[
    shared/Services.lua
    Centralized Roblox service access and HTTP request shim.

    Usage:
        local Services = loadstring(game:HttpGet("https://raw.githubusercontent.com/Aditya-lua/RCU/main/shared/Services.lua"))()
        local Players   = Services.Players
        local request   = Services.request
]]

local Services = {}

-- Lazy-cache: services are fetched once on first access and reused thereafter
local cache = {}

local SERVICE_NAMES = {
    "Players",
    "Workspace",
    "ReplicatedStorage",
    "TweenService",
    "HttpService",
    "RunService",
    "UserInputService",
    "Lighting",
    "VirtualUser",
    "CoreGui",
    "MarketplaceService",
    "CollectionService",
    "PathfindingService",
    "TeleportService",
}

for _, name in ipairs(SERVICE_NAMES) do
    Services[name] = game:GetService(name)
end

-- Camera shortcut
Services.Camera = Services.Workspace.Camera

-- Local player shortcut
Services.LocalPlayer = Services.Players.LocalPlayer

-- Cross-executor HTTP request shim
Services.request = (syn and syn.request)
    or (http and http.request)
    or http_request
    or request

return Services
