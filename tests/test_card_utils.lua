--[[
  Tests for lib/card_utils.lua
  Covers: getRarityLevel, getCardMutations, getMutationMultiplier,
          getCardScore, getLiveCardIncome
]]
package.path = package.path .. ";../lib/?.lua;../tests/?.lua"
local lu = require("luaunit")
local card = require("card_utils")

-- =============================================================================
-- getRarityLevel
-- =============================================================================
TestGetRarityLevel = {}

function TestGetRarityLevel:test_known_rarities()
    lu.assertEquals(card.getRarityLevel("Common"), 1)
    lu.assertEquals(card.getRarityLevel("Legendary"), 6)
    lu.assertEquals(card.getRarityLevel("Secret Exclusive"), 27)
end

function TestGetRarityLevel:test_mythic_and_mythical_same()
    lu.assertEquals(card.getRarityLevel("Mythic"), card.getRarityLevel("Mythical"))
end

function TestGetRarityLevel:test_unknown_rarity()
    lu.assertEquals(card.getRarityLevel("FakeRarity"), 0)
end

function TestGetRarityLevel:test_nil_rarity()
    lu.assertEquals(card.getRarityLevel(nil), 0)
end

function TestGetRarityLevel:test_ordering()
    lu.assertTrue(card.getRarityLevel("Common") < card.getRarityLevel("Bronze"))
    lu.assertTrue(card.getRarityLevel("Gold") < card.getRarityLevel("Legendary"))
    lu.assertTrue(card.getRarityLevel("Divine") < card.getRarityLevel("Exclusive"))
end

-- =============================================================================
-- getCardMutations
-- =============================================================================
TestGetCardMutations = {}

function TestGetCardMutations:test_non_table()
    lu.assertEquals(card.getCardMutations("string"), {})
    lu.assertEquals(card.getCardMutations(nil), {})
    lu.assertEquals(card.getCardMutations(42), {})
end

function TestGetCardMutations:test_lowercase_mutations()
    local c = { mutations = {"fire", "ice"} }
    lu.assertEquals(card.getCardMutations(c), {"fire", "ice"})
end

function TestGetCardMutations:test_capitalized_mutations()
    local c = { Mutations = {"Speed"} }
    lu.assertEquals(card.getCardMutations(c), {"Speed"})
end

function TestGetCardMutations:test_single_mutation_string()
    local c = { mutation = "Strength" }
    lu.assertEquals(card.getCardMutations(c), {"Strength"})
end

function TestGetCardMutations:test_empty_table()
    lu.assertEquals(card.getCardMutations({}), {})
end

function TestGetCardMutations:test_priority_lowercase_first()
    -- lowercase "mutations" takes priority over "Mutations"
    local c = { mutations = {"a"}, Mutations = {"b"} }
    lu.assertEquals(card.getCardMutations(c), {"a"})
end

-- =============================================================================
-- getMutationMultiplier
-- =============================================================================
TestGetMutationMultiplier = {}

function TestGetMutationMultiplier:test_feature_off()
    local c = { mutations = {"fire"} }
    lu.assertEquals(card.getMutationMultiplier(c, false), 1)
end

function TestGetMutationMultiplier:test_no_mutations()
    lu.assertEquals(card.getMutationMultiplier({}, true), 1)
end

function TestGetMutationMultiplier:test_one_mutation_default()
    local c = { mutations = {"fire"} }
    lu.assertAlmostEquals(card.getMutationMultiplier(c, true), 1.75, 0.001)
end

function TestGetMutationMultiplier:test_two_mutations_default()
    local c = { mutations = {"fire", "ice"} }
    lu.assertAlmostEquals(card.getMutationMultiplier(c, true), 1.75 * 1.75, 0.001)
end

function TestGetMutationMultiplier:test_custom_multiplier()
    local c = { mutations = {"fire", "ice"} }
    lu.assertAlmostEquals(card.getMutationMultiplier(c, true, 2.0), 4.0, 0.001)
end

function TestGetMutationMultiplier:test_three_mutations()
    local c = { mutations = {"a", "b", "c"} }
    lu.assertAlmostEquals(card.getMutationMultiplier(c, true), 1.75^3, 0.001)
end

-- =============================================================================
-- getCardScore
-- =============================================================================
TestGetCardScore = {}

function TestGetCardScore:test_nil_card()
    lu.assertEquals(card.getCardScore(nil, {}, true), 0)
end

function TestGetCardScore:test_card_without_id()
    lu.assertEquals(card.getCardScore({}, {}, true), 0)
end

function TestGetCardScore:test_card_not_in_config()
    local c = { id = "unknown" }
    lu.assertEquals(card.getCardScore(c, {}, true), 0)
end

function TestGetCardScore:test_basic_score()
    local configs = { messi = { IncomeRate = 100 } }
    local c = { id = "messi" }
    lu.assertEquals(card.getCardScore(c, configs, false), 100)
end

function TestGetCardScore:test_score_with_mutations()
    local configs = { ronaldo = { IncomeRate = 200 } }
    local c = { id = "ronaldo", mutations = {"speed"} }
    lu.assertAlmostEquals(card.getCardScore(c, configs, true), 200 * 1.75, 0.001)
end

function TestGetCardScore:test_score_feature_off_ignores_mutations()
    local configs = { neymar = { IncomeRate = 150 } }
    local c = { id = "neymar", mutations = {"a", "b"} }
    lu.assertEquals(card.getCardScore(c, configs, false), 150)
end

-- =============================================================================
-- getLiveCardIncome
-- =============================================================================
TestGetLiveCardIncome = {}

function TestGetLiveCardIncome:test_nil_slot()
    lu.assertEquals(card.getLiveCardIncome(nil, {}), 0)
end

function TestGetLiveCardIncome:test_non_table_slot()
    lu.assertEquals(card.getLiveCardIncome("bad", {}), 0)
end

function TestGetLiveCardIncome:test_slot_income()
    lu.assertEquals(card.getLiveCardIncome({ income = 500 }, {}), 500)
end

function TestGetLiveCardIncome:test_slot_IncomeRate()
    lu.assertEquals(card.getLiveCardIncome({ IncomeRate = 300 }, {}), 300)
end

function TestGetLiveCardIncome:test_slot_totalIncome()
    lu.assertEquals(card.getLiveCardIncome({ totalIncome = 750 }, {}), 750)
end

function TestGetLiveCardIncome:test_slot_eps()
    lu.assertEquals(card.getLiveCardIncome({ eps = 42 }, {}), 42)
end

function TestGetLiveCardIncome:test_card_income()
    local slot = { card = { income = 200 } }
    lu.assertEquals(card.getLiveCardIncome(slot, {}), 200)
end

function TestGetLiveCardIncome:test_card_IncomeRate()
    local slot = { card = { IncomeRate = 180 } }
    lu.assertEquals(card.getLiveCardIncome(slot, {}), 180)
end

function TestGetLiveCardIncome:test_fallback_to_config()
    local configs = { messi = { IncomeRate = 999 } }
    local slot = { card = { id = "messi" } }
    lu.assertEquals(card.getLiveCardIncome(slot, configs), 999)
end

function TestGetLiveCardIncome:test_card_not_in_config()
    local slot = { card = { id = "unknown" } }
    lu.assertEquals(card.getLiveCardIncome(slot, {}), 0)
end

function TestGetLiveCardIncome:test_priority_slot_over_card()
    -- slot.income should take priority over card.income
    local slot = { income = 100, card = { income = 200 } }
    lu.assertEquals(card.getLiveCardIncome(slot, {}), 100)
end

function TestGetLiveCardIncome:test_zero_slot_falls_through()
    -- zero income at slot level should fall through to card
    local slot = { income = 0, card = { income = 50 } }
    lu.assertEquals(card.getLiveCardIncome(slot, {}), 50)
end

os.exit(lu.LuaUnit.run())
