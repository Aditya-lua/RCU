--[[
  Tests for lib/thread_manager.lua
  Covers: new, Add, Stop, StopAll, Count, Has
]]
package.path = package.path .. ";../lib/?.lua;../tests/?.lua"
local lu = require("luaunit")
local ThreadManager = require("thread_manager")

TestThreadManager = {}

function TestThreadManager:setUp()
    self.tm = ThreadManager.new()
end

function TestThreadManager:test_new_is_empty()
    lu.assertEquals(self.tm:Count(), 0)
end

function TestThreadManager:test_add_thread()
    local t = { name = "thread1" }
    local returned = self.tm:Add("key1", t)
    lu.assertEquals(returned, t)
    lu.assertTrue(self.tm:Has("key1"))
    lu.assertEquals(self.tm:Count(), 1)
end

function TestThreadManager:test_add_replaces_existing()
    self.tm:Add("key1", "old")
    self.tm:Add("key1", "new")
    lu.assertEquals(self.tm:Count(), 1)
    lu.assertTrue(self.tm:Has("key1"))
end

function TestThreadManager:test_stop_removes()
    self.tm:Add("key1", "t1")
    self.tm:Stop("key1")
    lu.assertFalse(self.tm:Has("key1"))
    lu.assertEquals(self.tm:Count(), 0)
end

function TestThreadManager:test_stop_nonexistent()
    -- should not error
    self.tm:Stop("nonexistent")
    lu.assertEquals(self.tm:Count(), 0)
end

function TestThreadManager:test_stop_all()
    self.tm:Add("a", 1)
    self.tm:Add("b", 2)
    self.tm:Add("c", 3)
    lu.assertEquals(self.tm:Count(), 3)
    self.tm:StopAll()
    lu.assertEquals(self.tm:Count(), 0)
end

function TestThreadManager:test_has_false_for_missing()
    lu.assertFalse(self.tm:Has("anything"))
end

function TestThreadManager:test_multiple_keys()
    self.tm:Add("a", 1)
    self.tm:Add("b", 2)
    lu.assertTrue(self.tm:Has("a"))
    lu.assertTrue(self.tm:Has("b"))
    lu.assertFalse(self.tm:Has("c"))
    lu.assertEquals(self.tm:Count(), 2)
end

function TestThreadManager:test_stop_one_keeps_others()
    self.tm:Add("a", 1)
    self.tm:Add("b", 2)
    self.tm:Stop("a")
    lu.assertFalse(self.tm:Has("a"))
    lu.assertTrue(self.tm:Has("b"))
    lu.assertEquals(self.tm:Count(), 1)
end

function TestThreadManager:test_add_returns_thread()
    local t = { id = 42 }
    lu.assertEquals(self.tm:Add("x", t), t)
end

os.exit(lu.LuaUnit.run())
