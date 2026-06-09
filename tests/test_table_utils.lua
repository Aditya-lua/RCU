--[[
  Tests for lib/table_utils.lua
  Covers: sortedKeys, filterKeys, getWorldList
]]
package.path = package.path .. ";../lib/?.lua;../tests/?.lua"
local lu = require("luaunit")
local tbl = require("table_utils")

-- =============================================================================
-- sortedKeys
-- =============================================================================
TestSortedKeys = {}

function TestSortedKeys:test_empty_table()
    lu.assertEquals(tbl.sortedKeys({}), {})
end

function TestSortedKeys:test_alphabetical_sort()
    local t = { banana = 1, apple = 2, cherry = 3 }
    lu.assertEquals(tbl.sortedKeys(t), {"apple", "banana", "cherry"})
end

function TestSortedKeys:test_numeric_keys_as_string()
    -- numeric keys are converted to string for comparison
    local t = { [3] = "c", [1] = "a", [2] = "b" }
    local result = tbl.sortedKeys(t)
    lu.assertEquals(result, {1, 2, 3})
end

function TestSortedKeys:test_order_field()
    local t = {
        Z = { Order = 1 },
        A = { Order = 3 },
        M = { Order = 2 },
    }
    lu.assertEquals(tbl.sortedKeys(t, "Order"), {"Z", "M", "A"})
end

function TestSortedKeys:test_order_field_with_missing_values()
    local t = {
        A = { Order = 2 },
        B = "not a table",
        C = { Order = 1 },
    }
    -- B has no Order field → gets math.huge, sorts last
    local result = tbl.sortedKeys(t, "Order")
    lu.assertEquals(result, {"C", "A", "B"})
end

function TestSortedKeys:test_equal_order_tiebreak_by_name()
    local t = {
        Bravo   = { Order = 1 },
        Alpha   = { Order = 1 },
        Charlie = { Order = 1 },
    }
    lu.assertEquals(tbl.sortedKeys(t, "Order"), {"Alpha", "Bravo", "Charlie"})
end

function TestSortedKeys:test_single_key()
    lu.assertEquals(tbl.sortedKeys({x = 10}), {"x"})
end

-- =============================================================================
-- filterKeys
-- =============================================================================
TestFilterKeys = {}

function TestFilterKeys:test_empty_table()
    lu.assertEquals(tbl.filterKeys({}, function() return true end), {})
end

function TestFilterKeys:test_filter_all()
    local t = { a = 1, b = 2, c = 3 }
    lu.assertEquals(tbl.filterKeys(t, function() return true end), {"a", "b", "c"})
end

function TestFilterKeys:test_filter_none()
    local t = { a = 1, b = 2 }
    lu.assertEquals(tbl.filterKeys(t, function() return false end), {})
end

function TestFilterKeys:test_filter_by_value()
    local t = { a = 10, b = 20, c = 5 }
    local result = tbl.filterKeys(t, function(_, v) return v > 8 end)
    lu.assertEquals(result, {"a", "b"})
end

function TestFilterKeys:test_filter_by_key()
    local t = { alpha = 1, beta = 2, gamma = 3 }
    local result = tbl.filterKeys(t, function(k) return k:sub(1,1) < "c" end)
    lu.assertEquals(result, {"alpha", "beta"})
end

function TestFilterKeys:test_filter_by_subtable_field()
    local t = {
        sword  = { Type = "Weapon" },
        shield = { Type = "Armor"  },
        potion = { Type = "Potion" },
    }
    local result = tbl.filterKeys(t, function(_, v) return type(v) == "table" and v.Type == "Weapon" end)
    lu.assertEquals(result, {"sword"})
end

function TestFilterKeys:test_results_sorted()
    local t = { z = 1, a = 2, m = 3 }
    local result = tbl.filterKeys(t, function() return true end)
    lu.assertEquals(result, {"a", "m", "z"})
end

-- =============================================================================
-- getWorldList
-- =============================================================================
TestGetWorldList = {}

function TestGetWorldList:test_empty_table()
    local names, idxMap = tbl.getWorldList({})
    lu.assertEquals(names, {})
    lu.assertEquals(idxMap, {})
end

function TestGetWorldList:test_basic_worlds()
    local worlds = {
        [1] = { WorldName = "Grasslands" },
        [2] = { WorldName = "Desert" },
        [3] = { WorldName = "Ice" },
    }
    local names, idxMap = tbl.getWorldList(worlds)
    lu.assertEquals(names, {"Grasslands", "Desert", "Ice"})
    lu.assertEquals(idxMap["Grasslands"], 1)
    lu.assertEquals(idxMap["Desert"], 2)
    lu.assertEquals(idxMap["Ice"], 3)
end

function TestGetWorldList:test_unordered_indices()
    local worlds = {
        [5] = { WorldName = "Lava" },
        [2] = { WorldName = "Forest" },
        [8] = { WorldName = "Sky" },
    }
    local names, _ = tbl.getWorldList(worlds)
    lu.assertEquals(names, {"Forest", "Lava", "Sky"})
end

function TestGetWorldList:test_skips_non_numeric_keys()
    local worlds = {
        [1] = { WorldName = "Ocean" },
        meta = { WorldName = "should be skipped" },
    }
    local names, idxMap = tbl.getWorldList(worlds)
    lu.assertEquals(names, {"Ocean"})
    lu.assertNil(idxMap["should be skipped"])
end

function TestGetWorldList:test_skips_entries_without_WorldName()
    local worlds = {
        [1] = { WorldName = "Valid" },
        [2] = { SomeOtherField = "no name" },
        [3] = "not a table",
    }
    local names, _ = tbl.getWorldList(worlds)
    lu.assertEquals(names, {"Valid"})
end

os.exit(lu.LuaUnit.run())
