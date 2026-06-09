--[[
    shared/UI.lua
    Versus Library loading, anti-idle, notify(), and interval() helpers.

    Usage:
        local Services = loadstring(game:HttpGet("...shared/Services.lua"))()
        local UI       = loadstring(game:HttpGet("...shared/UI.lua"))()

        local Library, Setup = UI.loadVersusLibrary(Services, {
            OpenCloseLocation = "Top Center",
        })
        UI.setupAntiIdle(Services)

        -- notify shortcut
        UI.notify(Library, "Title", "Message", "info")

        -- interval loop (SSC-style with dynamic delay support)
        UI.interval(Library, Services, "tag", "flagName", 1.0, function() ... end)
]]

local UI = {}

--- Load the Versus Airlines UI library and return Library + Setup.
-- @param Services  table from shared/Services.lua
-- @param opts      table  { OpenCloseLocation = "Top Center", ... }
-- @return Library, Setup
function UI.loadVersusLibrary(Services, opts)
    opts = opts or {}
    local Library = loadstring(game:HttpGet("https://versusairlines.top/scripts/NewLibrary.lua"))()
    local Setup = Library:Setup({
        Location = Services.CoreGui,
        OpenCloseLocation = opts.OpenCloseLocation or "Top Center",
    })
    return Library, Setup
end

--- Hook anti-idle so the player is never kicked for inactivity.
-- @param Services  table from shared/Services.lua
function UI.setupAntiIdle(Services)
    Services.LocalPlayer.Idled:Connect(function()
        Services.VirtualUser:Button2Down(Vector2.new(0, 0), Services.Workspace.CurrentCamera.CFrame)
        task.wait(1)
        Services.VirtualUser:Button2Up(Vector2.new(0, 0), Services.Workspace.CurrentCamera.CFrame)
    end)
end

--- Display a notification via the Versus Library.
-- @param Library  the loaded Versus Library instance
-- @param title    string
-- @param desc     string
-- @param style    string "info" | "warning" | "danger"  (default: "info")
function UI.notify(Library, title, desc, style)
    Library:createDisplayMessage(title, desc, { { text = "OK" } }, style or "info")
end

--- Heartbeat-driven interval loop.
-- Supports both static and dynamic (function) delay values.
-- The loop is gated by `flag`; pass nil to run unconditionally.
--
-- @param Library    the loaded Versus Library instance
-- @param Services   table from shared/Services.lua
-- @param tag        string   unique tag for cleanup
-- @param flag       string?  Library.Flags key (nil = always run)
-- @param delayTime  number | function  seconds between ticks (or fn returning seconds)
-- @param callback   function  work to perform each tick
-- @param opts       table?   { minDelay = number }
function UI.interval(Library, Services, tag, flag, delayTime, callback, opts)
    Library:CleanupConnectionsByTag(tag)

    local isDynamic = type(delayTime) == "function"

    local function resolveDelay()
        local d
        if isDynamic then
            local ok, v = pcall(delayTime)
            d = ok and tonumber(v) or 0.1
        else
            d = tonumber(delayTime) or 0.1
        end
        if opts and tonumber(opts.minDelay) then
            d = math.max(d, opts.minDelay)
        end
        return math.max(d, 0.03)
    end

    -- Early-exit when the flag is already off (static delay path)
    if not isDynamic then
        if flag ~= nil and not Library.Flags[flag] then return end
    end

    local last = 0
    local running = false
    local slowWarnAt = 0

    local conn = Services.RunService.Heartbeat:Connect(function()
        if flag ~= nil and not Library.Flags[flag] then
            Library:CleanupConnectionsByTag(tag)
            return
        end

        local current = os.clock()
        if running or current - last < resolveDelay() then return end

        last = current
        running = true

        task.spawn(function()
            local startedAt = os.clock()
            local ok, err = pcall(callback)
            local elapsed = os.clock() - startedAt

            if not ok then
                warn("[interval:" .. tostring(tag) .. "]", err)
            elseif elapsed > 10 and os.clock() - slowWarnAt > 5 then
                slowWarnAt = os.clock()
                warn(string.format("[Versus] slow interval %s took %.3fs", tostring(tag), elapsed))
            end

            task.wait()
            running = false
        end)
    end)

    Library:TrackConnection(conn, tag)
end

return UI
