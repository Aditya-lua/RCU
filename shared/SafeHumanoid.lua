--[[
    shared/SafeHumanoid.lua
    Safe accessor helpers for Humanoid, HumanoidRootPart, and character parts.

    Usage:
        local Safe = loadstring(game:HttpGet("...shared/SafeHumanoid.lua"))()
        local hum  = Safe.getHumanoid(model)
        Safe.setWalkSpeed(model, 100)
]]

local Safe = {}

--- Get the Humanoid from a character model, or nil.
function Safe.getHumanoid(model)
    if model and model:FindFirstChild("Humanoid") then
        return model.Humanoid
    end
    return nil
end

--- Get the HumanoidRootPart from a character model, or nil.
function Safe.getHRP(model)
    if model and model:FindFirstChild("HumanoidRootPart") then
        return model.HumanoidRootPart
    end
    return nil
end

--- Return current health, or 0.
function Safe.health(model)
    local hum = Safe.getHumanoid(model)
    return hum and hum.Health or 0
end

--- Return max health, or 1.
function Safe.maxHealth(model)
    local hum = Safe.getHumanoid(model)
    return hum and hum.MaxHealth or 1
end

--- Set walk speed on the character's humanoid.
function Safe.setWalkSpeed(model, speed)
    local hum = Safe.getHumanoid(model)
    if hum then hum.WalkSpeed = speed end
end

--- Set jump power on the character's humanoid.
function Safe.setJumpPower(model, power)
    local hum = Safe.getHumanoid(model)
    if hum then hum.JumpPower = power end
end

--- Destroy the Animator inside a character's humanoid.
function Safe.destroyAnimator(model)
    local hum = Safe.getHumanoid(model)
    if hum and hum:FindFirstChild("Animator") then
        hum.Animator:Destroy()
    end
end

--- Change humanoid state.
function Safe.changeState(model, state)
    local hum = Safe.getHumanoid(model)
    if hum then hum:ChangeState(state) end
end

--- Set an arbitrary property on the humanoid.
function Safe.setHumanoidProp(model, prop, value)
    local hum = Safe.getHumanoid(model)
    if hum then hum[prop] = value end
end

--- Set Head.CanCollide on a character model.
function Safe.setHeadCanCollide(model, val)
    if model and model:FindFirstChild("Head") then
        model.Head.CanCollide = val
    end
end

--- Get character, waiting for CharacterAdded if needed.
function Safe.getCharacter(player)
    return player.Character or player.CharacterAdded:Wait()
end

--- Get CombatFramework upvalues (Blox Fruits specific).
function Safe.getCombatFramework()
    local ok, result = pcall(function()
        return debug.getupvalues(require(
            game:GetService("Players").LocalPlayer.PlayerScripts.CombatFramework
        ))
    end)
    return ok and result or {}
end

return Safe
