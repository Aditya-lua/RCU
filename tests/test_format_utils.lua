--[[
  Tests for lib/format_utils.lua
  Covers: formatCash, formatDuration, rarityColor, wh_formatNumber, prettyPrint
]]
package.path = package.path .. ";../lib/?.lua;../tests/?.lua"
local lu = require("luaunit")
local fmt = require("format_utils")

-- =============================================================================
-- formatCash
-- =============================================================================
TestFormatCash = {}

function TestFormatCash:test_zero()
    lu.assertEquals(fmt.formatCash(0), "0")
end

function TestFormatCash:test_small_integer()
    lu.assertEquals(fmt.formatCash(42), "42")
end

function TestFormatCash:test_below_thousand()
    lu.assertEquals(fmt.formatCash(999), "999")
end

function TestFormatCash:test_exactly_thousand()
    lu.assertEquals(fmt.formatCash(1000), "1.0K")
end

function TestFormatCash:test_thousands()
    lu.assertEquals(fmt.formatCash(1500), "1.5K")
    lu.assertEquals(fmt.formatCash(99999), "100.0K")
end

function TestFormatCash:test_millions()
    lu.assertEquals(fmt.formatCash(1e6), "1.00M")
    lu.assertEquals(fmt.formatCash(2.5e6), "2.50M")
    lu.assertEquals(fmt.formatCash(999999999), "1000.00M")
end

function TestFormatCash:test_billions()
    lu.assertEquals(fmt.formatCash(1e9), "1.00B")
    lu.assertEquals(fmt.formatCash(7.89e9), "7.89B")
end

function TestFormatCash:test_trillions()
    lu.assertEquals(fmt.formatCash(1e12), "1.00T")
    lu.assertEquals(fmt.formatCash(3.14159e12), "3.14T")
end

function TestFormatCash:test_nil_input()
    lu.assertEquals(fmt.formatCash(nil), "0")
end

function TestFormatCash:test_string_input()
    lu.assertEquals(fmt.formatCash("5000"), "5.0K")
end

function TestFormatCash:test_non_numeric_string()
    lu.assertEquals(fmt.formatCash("abc"), "0")
end

function TestFormatCash:test_negative()
    lu.assertEquals(fmt.formatCash(-100), "-100")
end

function TestFormatCash:test_float_below_thousand()
    lu.assertEquals(fmt.formatCash(99.7), "99")
end

-- =============================================================================
-- formatDuration
-- =============================================================================
TestFormatDuration = {}

function TestFormatDuration:test_zero_seconds()
    lu.assertEquals(fmt.formatDuration(0), "00:00:00")
end

function TestFormatDuration:test_one_second()
    lu.assertEquals(fmt.formatDuration(1), "00:00:01")
end

function TestFormatDuration:test_one_minute()
    lu.assertEquals(fmt.formatDuration(60), "00:01:00")
end

function TestFormatDuration:test_one_hour()
    lu.assertEquals(fmt.formatDuration(3600), "01:00:00")
end

function TestFormatDuration:test_complex()
    lu.assertEquals(fmt.formatDuration(3661), "01:01:01")
end

function TestFormatDuration:test_large_value()
    lu.assertEquals(fmt.formatDuration(86399), "23:59:59")
end

function TestFormatDuration:test_over_24h()
    lu.assertEquals(fmt.formatDuration(90000), "25:00:00")
end

function TestFormatDuration:test_negative_clamped()
    lu.assertEquals(fmt.formatDuration(-10), "00:00:00")
end

function TestFormatDuration:test_fractional_seconds()
    lu.assertEquals(fmt.formatDuration(90.7), "00:01:30")
end

-- =============================================================================
-- rarityColor
-- =============================================================================
TestRarityColor = {}

function TestRarityColor:test_known_rarity()
    lu.assertEquals(fmt.rarityColor("Common"), 9807270)
    lu.assertEquals(fmt.rarityColor("Legendary"), 16753920)
    lu.assertEquals(fmt.rarityColor("Divine"), 4233727)
end

function TestRarityColor:test_spaced_rarity()
    lu.assertEquals(fmt.rarityColor("Azure Zenith"), 3447003)
    lu.assertEquals(fmt.rarityColor("Secret Exclusive"), 5505024)
end

function TestRarityColor:test_unknown_rarity()
    lu.assertEquals(fmt.rarityColor("Nonexistent"), fmt.DEFAULT_EMBED_COLOR)
end

function TestRarityColor:test_nil_rarity()
    lu.assertEquals(fmt.rarityColor(nil), fmt.DEFAULT_EMBED_COLOR)
end

function TestRarityColor:test_number_input()
    lu.assertEquals(fmt.rarityColor(123), fmt.DEFAULT_EMBED_COLOR)
end

function TestRarityColor:test_mythic_and_mythical_same()
    lu.assertEquals(fmt.rarityColor("Mythic"), fmt.rarityColor("Mythical"))
end

-- =============================================================================
-- wh_formatNumber
-- =============================================================================
TestWhFormatNumber = {}

function TestWhFormatNumber:test_small_number()
    lu.assertEquals(fmt.wh_formatNumber(42), "42")
end

function TestWhFormatNumber:test_zero()
    lu.assertEquals(fmt.wh_formatNumber(0), "0")
end

function TestWhFormatNumber:test_thousands()
    lu.assertEquals(fmt.wh_formatNumber(1000), "1K")
    lu.assertEquals(fmt.wh_formatNumber(1500), "1.50K")
end

function TestWhFormatNumber:test_millions()
    lu.assertEquals(fmt.wh_formatNumber(1e6), "1M")
    lu.assertEquals(fmt.wh_formatNumber(2.5e6), "2.50M")
end

function TestWhFormatNumber:test_billions()
    lu.assertEquals(fmt.wh_formatNumber(1e9), "1B")
end

function TestWhFormatNumber:test_trillions()
    lu.assertEquals(fmt.wh_formatNumber(1e12), "1T")
end

function TestWhFormatNumber:test_quadrillions()
    lu.assertEquals(fmt.wh_formatNumber(1e15), "1Qd")
end

function TestWhFormatNumber:test_below_thousand()
    lu.assertEquals(fmt.wh_formatNumber(999), "999")
end

function TestWhFormatNumber:test_exact_boundary()
    lu.assertEquals(fmt.wh_formatNumber(1e6), "1M")
end

function TestWhFormatNumber:test_fractional_stripped()
    -- ".00" should be stripped
    lu.assertEquals(fmt.wh_formatNumber(2000), "2K")
end

function TestWhFormatNumber:test_fractional_kept()
    lu.assertEquals(fmt.wh_formatNumber(1234), "1.23K")
end

-- =============================================================================
-- prettyPrint
-- =============================================================================
TestPrettyPrint = {}

function TestPrettyPrint:test_simple_value()
    lu.assertEquals(fmt.prettyPrint(42), "42")
end

function TestPrettyPrint:test_string_value()
    lu.assertEquals(fmt.prettyPrint("hello"), "hello")
end

function TestPrettyPrint:test_nil_value()
    lu.assertEquals(fmt.prettyPrint(nil), "nil")
end

function TestPrettyPrint:test_boolean()
    lu.assertEquals(fmt.prettyPrint(true), "true")
end

function TestPrettyPrint:test_flat_table()
    -- Just verify it contains key=value pairs (order may vary)
    local result = fmt.prettyPrint({a = 1})
    lu.assertStrContains(result, "a = 1")
end

function TestPrettyPrint:test_nested_table()
    local result = fmt.prettyPrint({outer = {inner = 5}})
    lu.assertStrContains(result, "outer = {")
    lu.assertStrContains(result, "inner = 5")
    lu.assertStrContains(result, "}")
end

function TestPrettyPrint:test_indentation()
    local result = fmt.prettyPrint({x = {y = 1}}, 0)
    -- nested value should have 4-space indent
    lu.assertStrContains(result, "    y = 1")
end

function TestPrettyPrint:test_custom_indent()
    local result = fmt.prettyPrint(42, 2)
    lu.assertEquals(result, "        42")
end

os.exit(lu.LuaUnit.run())
