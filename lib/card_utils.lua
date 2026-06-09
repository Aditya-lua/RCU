--[[
  card_utils.lua
  Card/mutation scoring utilities extracted from SSC_Elite_Farm_v3.lua.
]]

local M = {}

--- Rarity ordering used for sell thresholds and sorting.
-- Extracted from SSC_Elite_Farm_v3.lua (rarityOrder table ~line 455-489)
M.rarityOrder = {
    Common     = 1,
    Bronze     = 2,
    Silver     = 3,
    Gold       = 4,
    Platinum   = 5,
    Legendary  = 6,
    Mythic     = 7,
    Mythical   = 7,
    Divine     = 8,
    Primordial = 9,
    ["Azure Zenith"]   = 10,
    ["Crimson Zenith"] = 11,
    Oblivion   = 12,
    Eternity   = 13,
    Astral     = 14,
    Sovereign  = 15,
    Vandal     = 16,
    ["The Monarch"]    = 17,
    Tyrant     = 18,
    Verdant    = 19,
    Silvane    = 20,
    Lunar      = 21,
    Solar      = 22,
    Nether     = 23,
    Aether     = 24,
    ["Player of the Month"] = 25,
    Exclusive  = 26,
    ["Secret Exclusive"]    = 27,
}

--- Returns the numeric ordering level for a rarity name.
-- Extracted from SSC_Elite_Farm_v3.lua:499
function M.getRarityLevel(rarity)
    return M.rarityOrder[rarity] or 0
end

--- Extracts the mutation list from a card table.
-- Extracted from SSC_Elite_Farm_v3.lua:553
function M.getCardMutations(card)
    if type(card) ~= "table" then return {} end
    if type(card.mutations) == "table" then return card.mutations end
    if type(card.Mutations) == "table" then return card.Mutations end
    if type(card.mutation) == "string" then return { card.mutation } end
    return {}
end

--- Computes the income multiplier from mutations.
-- Extracted from SSC_Elite_Farm_v3.lua:562
-- @param card         table   card data
-- @param featureOn    bool    whether MutationAwareEquip is enabled
-- @param configMult   number  optional per-mutation multiplier from MutationConfig
function M.getMutationMultiplier(card, featureOn, configMult)
    if not featureOn then return 1 end
    local muts = M.getCardMutations(card)
    local count = #muts
    if count == 0 then return 1 end
    local per = configMult or 1.75
    local mult = 1
    for _ = 1, count do mult = mult * per end
    return mult
end

--- Scores a card by base income * mutation multiplier.
-- Extracted from SSC_Elite_Farm_v3.lua:577
-- @param card         table   { id = "...", mutations = {...} }
-- @param cardConfigs  table   CardConfig.Cards map: { [id] = { IncomeRate = N } }
-- @param featureOn    bool    whether MutationAwareEquip is enabled
-- @param configMult   number  optional per-mutation multiplier
function M.getCardScore(card, cardConfigs, featureOn, configMult)
    if type(card) ~= "table" or not card.id then return 0 end
    local cfg = cardConfigs and cardConfigs[card.id]
    local baseIncome = (type(cfg) == "table" and tonumber(cfg.IncomeRate)) or 0
    return baseIncome * M.getMutationMultiplier(card, featureOn, configMult)
end

--- Computes live card income from slot data.
-- Extracted from SSC_Elite_Farm_v3.lua:1919
function M.getLiveCardIncome(slotData, cardConfigs)
    if type(slotData) ~= "table" then return 0 end

    local fromSlot = tonumber(slotData.income) or tonumber(slotData.IncomeRate)
        or tonumber(slotData.totalIncome) or tonumber(slotData.eps)
    if fromSlot and fromSlot > 0 then return fromSlot end

    local card = slotData.card
    if type(card) == "table" then
        local fromCard = tonumber(card.income) or tonumber(card.IncomeRate)
            or tonumber(card.totalIncome) or tonumber(card.eps)
        if fromCard and fromCard > 0 then return fromCard end

        local cfg = cardConfigs and cardConfigs[card.id]
        if type(cfg) == "table" then
            return tonumber(cfg.IncomeRate) or 0
        end
    end
    return 0
end

return M
