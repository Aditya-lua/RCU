--[[
  safe_utils.lua
  Safe accessor utilities extracted from versus_airlines_blox_fruits.lua.
  These provide nil-safe access to Humanoid properties and game model components.
]]

local M = {}

--- Returns the Humanoid child from a model, or nil.
-- Extracted from versus_airlines_blox_fruits.lua:76
function M.SafeGetHumanoid(model)
    if model and model.Humanoid then
        return model.Humanoid
    end
    return nil
end

--- Returns the health of a model's Humanoid, or 0.
-- Extracted from versus_airlines_blox_fruits.lua:83
function M.SafeHumanoidHealth(model)
    local hum = M.SafeGetHumanoid(model)
    return hum and hum.Health or 0
end

--- Returns the max health of a model's Humanoid, or 1.
-- Extracted from versus_airlines_blox_fruits.lua:88
function M.SafeHumanoidMaxHealth(model)
    local hum = M.SafeGetHumanoid(model)
    return hum and hum.MaxHealth or 1
end

--- Sets the WalkSpeed on a model's Humanoid if present.
-- Extracted from versus_airlines_blox_fruits.lua:93
function M.SafeSetWalkSpeed(model, speed)
    local hum = M.SafeGetHumanoid(model)
    if hum then
        hum.WalkSpeed = speed
    end
end

--- Sets the JumpPower on a model's Humanoid if present.
-- Extracted from versus_airlines_blox_fruits.lua:100
function M.SafeSetJumpPower(model, power)
    local hum = M.SafeGetHumanoid(model)
    if hum then
        hum.JumpPower = power
    end
end

--- Sets an arbitrary property on a model's Humanoid.
-- Extracted from versus_airlines_blox_fruits.lua:121
function M.SafeSetHumanoidProp(model, prop, value)
    local hum = M.SafeGetHumanoid(model)
    if hum then
        hum[prop] = value
    end
end

--- Returns the HumanoidRootPart from a model, or nil.
-- Extracted from versus_airlines_blox_fruits.lua:158
function M.SafeGetHRP(model)
    if model and model.HumanoidRootPart then
        return model.HumanoidRootPart
    end
    return nil
end

--- Rounds a number to the nearest integer.
-- Extracted from versus_airlines_blox_fruits.lua:26
function M.round(n)
    return math.floor(tonumber(n) + 0.5)
end

--- Returns true when the argument is nil.
-- Extracted from versus_airlines_blox_fruits.lua:898
function M.isnil(thing)
    return (thing == nil)
end

return M
