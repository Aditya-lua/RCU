--[[
  Tests for lib/safe_utils.lua
  Covers: SafeGetHumanoid, SafeHumanoidHealth, SafeHumanoidMaxHealth,
          SafeSetWalkSpeed, SafeSetJumpPower, SafeSetHumanoidProp,
          SafeGetHRP, round, isnil
]]
package.path = package.path .. ";../lib/?.lua;../tests/?.lua"
local lu = require("luaunit")
local safe = require("safe_utils")

-- Helper: build a mock model with a Humanoid child
local function mockModel(opts)
    opts = opts or {}
    local hum = {
        Health = opts.health or 100,
        MaxHealth = opts.maxHealth or 100,
        WalkSpeed = opts.walkSpeed or 16,
        JumpPower = opts.jumpPower or 50,
    }
    local model = { Humanoid = hum }
    if opts.hrp then
        model.HumanoidRootPart = opts.hrp
    end
    return model
end

-- =============================================================================
-- SafeGetHumanoid
-- =============================================================================
TestSafeGetHumanoid = {}

function TestSafeGetHumanoid:test_returns_humanoid()
    local m = mockModel()
    lu.assertNotNil(safe.SafeGetHumanoid(m))
    lu.assertEquals(safe.SafeGetHumanoid(m).Health, 100)
end

function TestSafeGetHumanoid:test_nil_model()
    lu.assertNil(safe.SafeGetHumanoid(nil))
end

function TestSafeGetHumanoid:test_model_without_humanoid()
    lu.assertNil(safe.SafeGetHumanoid({}))
end

-- =============================================================================
-- SafeHumanoidHealth
-- =============================================================================
TestSafeHumanoidHealth = {}

function TestSafeHumanoidHealth:test_returns_health()
    local m = mockModel({ health = 75 })
    lu.assertEquals(safe.SafeHumanoidHealth(m), 75)
end

function TestSafeHumanoidHealth:test_nil_model_returns_zero()
    lu.assertEquals(safe.SafeHumanoidHealth(nil), 0)
end

function TestSafeHumanoidHealth:test_no_humanoid_returns_zero()
    lu.assertEquals(safe.SafeHumanoidHealth({}), 0)
end

-- =============================================================================
-- SafeHumanoidMaxHealth
-- =============================================================================
TestSafeHumanoidMaxHealth = {}

function TestSafeHumanoidMaxHealth:test_returns_max_health()
    local m = mockModel({ maxHealth = 200 })
    lu.assertEquals(safe.SafeHumanoidMaxHealth(m), 200)
end

function TestSafeHumanoidMaxHealth:test_nil_model_returns_one()
    lu.assertEquals(safe.SafeHumanoidMaxHealth(nil), 1)
end

function TestSafeHumanoidMaxHealth:test_no_humanoid_returns_one()
    lu.assertEquals(safe.SafeHumanoidMaxHealth({}), 1)
end

-- =============================================================================
-- SafeSetWalkSpeed
-- =============================================================================
TestSafeSetWalkSpeed = {}

function TestSafeSetWalkSpeed:test_sets_speed()
    local m = mockModel()
    safe.SafeSetWalkSpeed(m, 32)
    lu.assertEquals(m.Humanoid.WalkSpeed, 32)
end

function TestSafeSetWalkSpeed:test_nil_model_no_error()
    safe.SafeSetWalkSpeed(nil, 32) -- should not throw
end

function TestSafeSetWalkSpeed:test_no_humanoid_no_error()
    safe.SafeSetWalkSpeed({}, 32) -- should not throw
end

-- =============================================================================
-- SafeSetJumpPower
-- =============================================================================
TestSafeSetJumpPower = {}

function TestSafeSetJumpPower:test_sets_power()
    local m = mockModel()
    safe.SafeSetJumpPower(m, 100)
    lu.assertEquals(m.Humanoid.JumpPower, 100)
end

function TestSafeSetJumpPower:test_nil_model_no_error()
    safe.SafeSetJumpPower(nil, 100)
end

-- =============================================================================
-- SafeSetHumanoidProp
-- =============================================================================
TestSafeSetHumanoidProp = {}

function TestSafeSetHumanoidProp:test_sets_arbitrary_prop()
    local m = mockModel()
    safe.SafeSetHumanoidProp(m, "WalkSpeed", 64)
    lu.assertEquals(m.Humanoid.WalkSpeed, 64)
end

function TestSafeSetHumanoidProp:test_sets_custom_prop()
    local m = mockModel()
    safe.SafeSetHumanoidProp(m, "CustomField", "value")
    lu.assertEquals(m.Humanoid.CustomField, "value")
end

function TestSafeSetHumanoidProp:test_nil_model_no_error()
    safe.SafeSetHumanoidProp(nil, "WalkSpeed", 64)
end

-- =============================================================================
-- SafeGetHRP
-- =============================================================================
TestSafeGetHRP = {}

function TestSafeGetHRP:test_returns_hrp()
    local hrp = { Position = {0, 0, 0} }
    local m = mockModel({ hrp = hrp })
    lu.assertEquals(safe.SafeGetHRP(m), hrp)
end

function TestSafeGetHRP:test_nil_model()
    lu.assertNil(safe.SafeGetHRP(nil))
end

function TestSafeGetHRP:test_no_hrp()
    lu.assertNil(safe.SafeGetHRP(mockModel()))
end

-- =============================================================================
-- round
-- =============================================================================
TestRound = {}

function TestRound:test_round_down()
    lu.assertEquals(safe.round(1.3), 1)
end

function TestRound:test_round_up()
    lu.assertEquals(safe.round(1.7), 2)
end

function TestRound:test_round_half()
    lu.assertEquals(safe.round(1.5), 2)
end

function TestRound:test_zero()
    lu.assertEquals(safe.round(0), 0)
end

function TestRound:test_negative()
    lu.assertEquals(safe.round(-1.7), -2)
end

function TestRound:test_large()
    lu.assertEquals(safe.round(999999.4), 999999)
end

function TestRound:test_string_number()
    lu.assertEquals(safe.round("3.6"), 4)
end

-- =============================================================================
-- isnil
-- =============================================================================
TestIsnil = {}

function TestIsnil:test_nil_is_true()
    lu.assertTrue(safe.isnil(nil))
end

function TestIsnil:test_false_is_not_nil()
    lu.assertFalse(safe.isnil(false))
end

function TestIsnil:test_zero_is_not_nil()
    lu.assertFalse(safe.isnil(0))
end

function TestIsnil:test_empty_string_is_not_nil()
    lu.assertFalse(safe.isnil(""))
end

function TestIsnil:test_table_is_not_nil()
    lu.assertFalse(safe.isnil({}))
end

os.exit(lu.LuaUnit.run())
