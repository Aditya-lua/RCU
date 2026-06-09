-----------------------------------------------------------------
-- Shared utilities (see shared/ directory)
-----------------------------------------------------------------
local SHARED_ROOT = "https://raw.githubusercontent.com/Aditya-lua/RCU/main/shared/"
local Services   = loadstring(game:HttpGet(SHARED_ROOT .. "Services.lua"))()
local UIHelpers  = loadstring(game:HttpGet(SHARED_ROOT .. "UI.lua"))()
local TableUtils = loadstring(game:HttpGet(SHARED_ROOT .. "TableUtils.lua"))()
local NetUtils   = loadstring(game:HttpGet(SHARED_ROOT .. "Net.lua"))()

-- Re-export commonly used services for compatibility with the rest of this file
local request          = Services.request
local TweenService     = Services.TweenService
local HttpService      = Services.HttpService
local RunService       = Services.RunService
local UserInputService = Services.UserInputService
local LightingService  = Services.Lighting
local VirtualUser      = Services.VirtualUser
local CoreGui          = Services.CoreGui
local ReplicatedStorage= Services.ReplicatedStorage
local MarketplaceService=Services.MarketplaceService
local CollectionService= Services.CollectionService
local Players          = Services.Players
local PathfindingService=Services.PathfindingService
local Workspace        = Services.Workspace
local Camera           = Services.Camera

local client = Services.LocalPlayer

-- Load UI
print("Loading Library...")

local Library, Setup = UIHelpers.loadVersusLibrary(Services, {
    OpenCloseLocation = "Bottom Left",
})

-- Prevent player from being idled out
UIHelpers.setupAntiIdle(Services)

-----------------------------------------------------------------

-- interval / notify / prettyPrint — delegated to shared modules
local function interval(tag, flag, delayTime, callback, opts)
    UIHelpers.interval(Library, Services, tag, flag, delayTime, callback, opts)
end

local function notify(title, desc, style)
    UIHelpers.notify(Library, title, desc, style)
end

local prettyPrint = TableUtils.prettyPrint

----------------------------------------------------------------- https://versusairlines.top/developers.html

local RS = ReplicatedStorage
local CODES_URL = "https://raw.githubusercontent.com/Aditya-lua/Scripts_2/refs/heads/main/SSC_CODES.txt"
local ROBLOX_THUMBS = "https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false"

local COLLECT_DEFAULT = 3
local STATS_DELAY_DEFAULT = 15
local MIN_GEMS_DEFAULT = 100
local SELL_DEFAULT = "Silver"
local RARITY_THRESH_DEFAULT = "Mythic"
local CODE_WAIT = 1.5
local REBIRTH_CD_NORMAL = 15
local REBIRTH_CD_FORCE = 30

local PACK_OPEN_MIN_DELAY = 0.12
local PACK_BUY_MIN_DELAY = 0.18
local COLLECT_SLOT_WAIT = 0.1
local INVENTORY_YIELD_EVERY = 50

local function lightYield(index)
    TableUtils.lightYield(index, INVENTORY_YIELD_EVERY)
end

local httpRequest = Services.request
local tableUnpack = table.unpack or unpack
local webhookUrl = ""
local webhookPingId = ""

local GEM_SHOP_MAP = {
    ["Lucky Item"] = "lucky",
    ["Auto Equip Best"] = "fixed_1",
    ["Auto Skip"] = "fixed_2",
    ["Inventory +500"] = "fixed_3",
    ["Scarlet Item"] = "scarlet",
}

local resolvePath = NetUtils.resolvePath
local safeRequire = NetUtils.safeRequire

local function requirePath(label, ...)
    return NetUtils.requirePath(RS, label, ...)
end

local Networker = requirePath("Networker", "Source", "Shared", "Networker")

local function getRemote(name)
    if Networker and type(Networker.get_remote) == "function" then
        local ok, result = pcall(function()
            return Networker.get_remote(name)
        end)
        if ok and result then return result end
    end

    local remotesFolder = RS:FindFirstChild("Remotes")
    return remotesFolder and remotesFolder:FindFirstChild(name) or nil
end

local function getFunction(name)
    if Networker and type(Networker.get_remotefunction) == "function" then
        local ok, result = pcall(function()
            return Networker.get_remotefunction(name)
        end)
        if ok and result then return result end
    end

    local remotesFolder = RS:FindFirstChild("Remotes")
    return remotesFolder and remotesFolder:FindFirstChild(name) or nil
end

local remotes = {
    OpenPack = getRemote("OpenPack"),
    BuyPack = getRemote("BuyPack"),
    EquipCard = getRemote("EquipCard"),
    CollectSlot = getRemote("CollectSlot"),
    SellCards = getRemote("SellCards"),
    DeletePacks = getRemote("DeletePacks"),
    Rebirth = getRemote("Rebirth"),
    BuyGemShopItem = getRemote("BuyGemShopItem"),
    ClaimAllIndexGems = getRemote("ClaimAllIndexGems"),
    DailyReward = getRemote("DailyReward"),
    OfflineReward = getRemote("OfflineReward"),
    SpinWheel = getRemote("SpinWheel"),
    RedeemCode = getRemote("RedeemCode"),
    -- Confirmed real names from the RS dump:
    CraftTrophy = getRemote("CraftTrophy"),
    ApplyTrophy = getRemote("ApplyTrophy"),
    DestroyTrophy = getRemote("DestroyTrophy"),
    Tournament = getRemote("Tournament"),
    UsePotion = getRemote("UsePotion"),
    PackSettings = getRemote("PackSettings"),
    Wish = getRemote("Wish"),
}

local funcs = {
    SpinWheelData = getFunction("SpinWheelData"),
    -- PerformWish is a RemoteFunction in this game!
    PerformWish = getFunction("PerformWish"),
}

local PackConfig = requirePath("PackConfig", "Source", "Shared", "Configs", "PackConfig") or {}
local CardConfig = requirePath("CardConfig", "Source", "Shared", "Configs", "CardConfig") or {}
local RebirthConfig = requirePath("RebirthConfig", "Source", "Shared", "Configs", "RebirthConfig") or {}
local PlayerStore = requirePath("PlayerStore", "Source", "Shared", "State", "PlayerStore")

-- Optional configs for the new features (no-op if missing)
local TrophyConfig = requirePath("TrophyConfig", "Source", "Shared", "Configs", "TrophyConfig") or {}
local PotionConfig = requirePath("PotionConfig", "Source", "Shared", "Configs", "PotionConfig") or {}
local TournamentConfig = requirePath("TournamentConfig", "Source", "Shared", "Configs", "TournamentConfig") or {}
local MutationConfig = requirePath("MutationConfig", "Source", "Shared", "Configs", "MutationConfig") or {}
local TournamentClock = requirePath("TournamentClock", "Source", "Shared", "Helpers", "TournamentClock")
local WeatherStore = requirePath("WeatherStore", "Source", "Shared", "State", "WeatherStore")

local stats = {
    opened = 0,
    bought = 0,
    sold = 0,
    rebirths = 0,
    gemBuys = 0,
    collects = 0,
    codesRedeemed = false,
    wishes = 0,
    trophiesCrafted = 0,
    trophiesApplied = 0,
    tournamentJoins = 0,
    potionsUsed = 0,
    sessionStart = os.time(),
}

local tournamentState = {
    inTournament = false,
    placement = nil,
    joins = 0,
    wins = 0,
}

local fireRemote   = NetUtils.fireRemote
local invokeRemote = NetUtils.invokeRemote

local function getPlayerData()
    if type(PlayerStore) ~= "function" then return nil end
    local ok, state = pcall(function()
        return PlayerStore()
    end)
    if not ok or type(state) ~= "table" or type(state.players) ~= "table" then return nil end
    return state.players[tostring(client.UserId)]
end

local function getInventory()
    local data = getPlayerData()
    return data and data.inventory or {}
end

local function getSlots()
    local data = getPlayerData()
    return data and data.slots or {}
end

local function getCash()
    local data = getPlayerData()
    return tonumber(data and data.cash) or 0
end

local function getGems()
    local data = getPlayerData()
    return tonumber(data and data.gems) or 0
end

local function getRebirthLevel()
    local data = getPlayerData()
    return tonumber(data and data.rebirth) or 0
end

local formatCash = TableUtils.formatCash

-- Map a card rarity name to a Discord embed color (decimal int).
-- Matches Roblox/game color palette so embeds visually match the card.
local RARITY_COLORS = {
    Common              = 9807270,   -- gray
    Bronze              = 13467442,  -- bronze
    Silver              = 12500670,  -- silver
    Gold                = 16766720,  -- gold
    Platinum            = 11725548,  -- light teal
    Legendary           = 16753920,  -- orange
    Mythic              = 14684400,  -- pink/magenta
    Mythical            = 14684400,
    Divine              = 4233727,   -- cyan
    Primordial          = 9856770,   -- purple
    ["Azure Zenith"]    = 3447003,   -- blue
    ["Crimson Zenith"]  = 13632027,  -- red
    Oblivion            = 2829617,   -- dark blue
    Eternity            = 16767093,  -- light gold
    Astral              = 9510911,   -- light purple
    Sovereign           = 16776960,  -- yellow
    Vandal              = 16711935,  -- magenta
    ["The Monarch"]     = 16766720,
    Tyrant              = 11403055,
    Verdant             = 4915330,
    Silvane             = 12500670,
    Lunar               = 14079702,
    Solar               = 16762880,
    Nether              = 4194304,
    Aether              = 11192319,
    ["Player of the Month"] = 16766720,
    Exclusive           = 16711680,
    ["Secret Exclusive"] = 5505024,
}
local DEFAULT_EMBED_COLOR = 3447003

local function rarityColor(rarityName)
    return RARITY_COLORS[tostring(rarityName)] or DEFAULT_EMBED_COLOR
end

local function getSingleFlag(flagName, defaultValue)
    local value = Library.Flags[flagName]
    if type(value) == "table" then
        return value[1] or defaultValue
    end
    if value == nil or value == "" then
        return defaultValue
    end
    return value
end

local function getMultiFlag(flagName, defaultValue)
    local value = Library.Flags[flagName]
    if type(value) == "table" then
        local list = {}
        for _, item in ipairs(value) do
            table.insert(list, item)
        end
        return list
    end
    if type(value) == "string" and value ~= "" then
        return { value }
    end
    return defaultValue or {}
end

local function setDropdownValues(dropdown, flagName, values)
    values = values or {}
    Library.Flags[flagName] = values

    pcall(function()
        if dropdown and type(dropdown.Set) == "function" then
            dropdown:Set(values)
        elseif dropdown and type(dropdown.set) == "function" then
            dropdown:set(values)
        elseif dropdown and type(dropdown.Update) == "function" then
            dropdown:Update(values)
        end
    end)
end

local function getPackList()
    local list = {}
    local packs = PackConfig and PackConfig.Packs
    if type(packs) == "table" then
        for packName, packData in pairs(packs) do
            if type(packData) ~= "table" or not packData.HideFromShop then
                table.insert(list, packName)
            end
        end

        table.sort(list, function(a, b)
            local pa = packs[a]
            local pb = packs[b]
            local orderA = type(pa) == "table" and (pa.LayoutOrder or 999) or 999
            local orderB = type(pb) == "table" and (pb.LayoutOrder or 999) or 999
            return orderA < orderB
        end)
    end

    if #list == 0 then
        list = { "Bronze" }
    end
    return list
end

local rarityOrder = {
    ["Bronze"] = 1,
    ["Silver"] = 2,
    ["Gold"] = 3,
    ["Legendary"] = 4,
    ["Mythic"] = 5,
    ["Azure Zenith"] = 6,
    ["Crimson Zenith"] = 7,
    ["Divine"] = 8,
    ["Primordial"] = 9,
    ["Oblivion"] = 10,
    ["Eternity"] = 11,
    ["Astral"] = 12,
    ["Sovereign"] = 13,
    ["Vandal"] = 14,
    ["The Monarch"] = 15,
    ["Tyrant"] = 16,
    ["Verdant"] = 17,
    ["Silvane"] = 18,
    ["Lunar"] = 19,
    ["Solar"] = 20,
    ["Nether"] = 21,
    ["Aether"] = 22,
    ["Player of the Month"] = 23,
    ["Exclusive"] = 24,
    ["Secret Exclusive"] = 25,
}

local rarityList = {}
for rarityName in pairs(rarityOrder) do
    table.insert(rarityList, rarityName)
end
table.sort(rarityList, function(a, b)
    return (rarityOrder[a] or 99) < (rarityOrder[b] or 99)
end)

local function getRarityLevel(rarity)
    return rarityOrder[rarity] or 0
end

-- =============================================
-- TROPHY HELPERS
-- =============================================
local trophyDefs = {}      -- list of { name, rarity, lvl }
local trophyLabels = {}    -- "Golden Boot [Legendary]"
local trophyLabelToName = {}
do
    local source = (TrophyConfig and TrophyConfig.Trophies) or TrophyConfig or {}
    for name, data in pairs(source) do
        if type(data) == "table" and (data.DisplayName or data.Rarity or data.Requirements or data.Stars) then
            local rarity = data.Rarity or "?"
            table.insert(trophyDefs, { name = name, rarity = rarity, lvl = rarityOrder[rarity] or 0 })
        end
    end
    table.sort(trophyDefs, function(a, b)
        if a.lvl ~= b.lvl then return a.lvl > b.lvl end
        return a.name < b.name
    end)
    for _, t in ipairs(trophyDefs) do
        local label = t.name .. " [" .. t.rarity .. "]"
        table.insert(trophyLabels, label)
        trophyLabelToName[label] = t.name
    end
    if #trophyLabels == 0 then
        trophyLabels = { "Golden Boot", "Champions League", "Ballon d'Or", "Eternal Crown", "Immortal Chalice" }
        for _, n in ipairs(trophyLabels) do trophyLabelToName[n] = n end
    end
end

-- =============================================
-- POTION HELPERS
-- =============================================
local potionList = {}
do
    local source = (PotionConfig and PotionConfig.Potions) or {}
    for name in pairs(source) do
        table.insert(potionList, name)
    end
    table.sort(potionList)
    if #potionList == 0 then
        potionList = {
            "Snowstorm Potion", "Thunderstorm Potion",
            "Toxic Rain Potion", "Blood Moon Potion", "Solar Eclipse Potion",
        }
    end
end

-- =============================================
-- MUTATION HELPERS (mutation count → income multiplier)
-- =============================================
local function getCardMutations(card)
    if type(card) ~= "table" then return {} end
    -- Common shape variants we've seen
    if type(card.mutations) == "table" then return card.mutations end
    if type(card.Mutations) == "table" then return card.Mutations end
    if type(card.mutation) == "string" then return { card.mutation } end
    return {}
end

local function getMutationMultiplier(card)
    if not Library.Flags["MutationAwareEquip"] then return 1 end
    local muts = getCardMutations(card)
    local count = #muts
    if count == 0 then return 1 end
    -- Conservative: each mutation adds ~75% (configurable in MutationConfig if present)
    local per = 1.75
    if MutationConfig and type(MutationConfig.MultiplierPerMutation) == "number" then
        per = MutationConfig.MultiplierPerMutation
    end
    local mult = 1
    for _ = 1, count do mult = mult * per end
    return mult
end

local function getCardScore(card)
    if type(card) ~= "table" or not card.id then return 0 end
    local cfg = CardConfig and CardConfig.Cards and CardConfig.Cards[card.id]
    local baseIncome = (type(cfg) == "table" and tonumber(cfg.IncomeRate)) or 0
    return baseIncome * getMutationMultiplier(card)
end

local function canRebirth()
    local maxRebirth = 999
    if RebirthConfig and type(RebirthConfig.GetMaxRebirth) == "function" then
        local ok, result = pcall(function()
            return RebirthConfig.GetMaxRebirth()
        end)
        if ok and tonumber(result) then
            maxRebirth = tonumber(result)
        end
    end

    local playerData = getPlayerData()
    if type(playerData) ~= "table" then return false end

    local currentRebirth = tonumber(playerData.rebirth) or 0
    if currentRebirth >= maxRebirth then return false end

    local rebirthData = nil
    if RebirthConfig and type(RebirthConfig.GetRebirth) == "function" then
        local ok, result = pcall(function()
            return RebirthConfig.GetRebirth(currentRebirth + 1)
        end)
        if ok then rebirthData = result end
    end
    if type(rebirthData) ~= "table" then return false end

    local cashRequired = tonumber(rebirthData.CashRequired) or math.huge
    local gemsRequired = tonumber(rebirthData.GemsRequired) or 0
    return (tonumber(playerData.cash) or 0) >= cashRequired and (tonumber(playerData.gems) or 0) >= gemsRequired
end

local SlotController = nil
local function equipBest()
    if not SlotController then
        SlotController = requirePath("SlotController", "Source", "Client", "Controllers", "SlotController")
    end

    if SlotController and type(SlotController.equipBestCards) == "function" then
        local ok = pcall(SlotController.equipBestCards)
        if ok then return true end
    end

    if not remotes.EquipCard then return false end

    local inventory = getInventory()
    local slots = getSlots()
    if type(inventory) ~= "table" or type(slots) ~= "table" then return false end

    local blockedIds = { LocalCard = true, OwnerVulnone = true }
    local candidates = {}
    local cards = CardConfig and CardConfig.Cards or {}

    local scannedCards = 0
    for _, card in pairs(inventory) do
        scannedCards += 1
        lightYield(scannedCards)

        local isValid = type(card) == "table"
        and card.id
        and card.uuid
        and not blockedIds[card.id]
        and not card.throneCard
        and not card.locked

        if isValid then
            table.insert(candidates, {
                uuid = card.uuid,
                income = getCardScore(card),
            })
        end
    end

    table.sort(candidates, function(a, b)
        return a.income > b.income
    end)

    local slotCount = 0
    for _ in pairs(slots) do
        slotCount += 1
    end
    if slotCount == 0 then slotCount = 6 end

    local equippedCount = 0
    for slotIndex = 1, math.min(#candidates, slotCount) do
        local candidate = candidates[slotIndex]
        local currentSlot = slots[tostring(slotIndex)] or slots[slotIndex]
        local currentIncome = 0

        if type(currentSlot) == "table" and type(currentSlot.card) == "table" then
            currentIncome = getCardScore(currentSlot.card)
        end

        if candidate.income > currentIncome and fireRemote(remotes.EquipCard, candidate.uuid, slotIndex) then
            equippedCount += 1
            task.wait(0.15)
        end
    end

    return equippedCount > 0
end

-- =============================================
-- ROLL UI NUKER — narrowly scoped
-- Only kills the pack-opening REVEAL MODAL and any AutoSkip/AutoOpen buttons
-- that live INSIDE that modal. We never touch buttons that exist standalone in
-- the game HUD (those have the same names but belong to the regular plot UI).
-- =============================================

-- Exact ScreenGui names known to host the pack reveal modal.
-- (Pattern matching was too aggressive — e.g. "reveal" matched random HUD frames.)
local REVEAL_SCREENGUI_NAMES = {
    PackOpening = true,
    OpenPack = true,
    PackOpen = true,
    PackReveal = true,
    CardReveal = true,
    RevealPack = true,
    PackOpeningUI = true,
    OpenPackUI = true,
    CardResult = true,
    GachaReveal = true,
}

local BUTTON_NAMES_TO_KILL = {
    AutoSkip = true, AutoOpen = true,
    autoSkip = true, autoOpen = true,
    ["Auto Skip"] = true, ["Auto Open"] = true,
}

local CUTSCENE_EFFECT_CLASSES = {
    BlurEffect = true, ColorCorrectionEffect = true,
    DepthOfFieldEffect = true, BloomEffect = true,
}

-- Is `inst` inside a known reveal-modal ScreenGui?
local function isInsideRevealModal(inst)
    local cur = inst
    while cur and cur ~= game do
        if REVEAL_SCREENGUI_NAMES[cur.Name] then return true end
        cur = cur.Parent
    end
    return false
end

-- Kill cutscene post-process effects (the blur the game adds during reveals)
local function nukeCutsceneEffects()
    pcall(function()
        local lighting = game:GetService("Lighting")
        for _, fx in ipairs(lighting:GetChildren()) do
            if CUTSCENE_EFFECT_CLASSES[fx.ClassName] and fx.Enabled then
                fx.Enabled = false
            end
        end
        local cam = Workspace.CurrentCamera
        if cam then
            for _, fx in ipairs(cam:GetChildren()) do
                if CUTSCENE_EFFECT_CLASSES[fx.ClassName] and fx.Enabled then
                    fx.Enabled = false
                end
            end
        end
    end)
end

local function tryKillBadDescendant(desc)
    if not desc or not desc.Parent then return end
    if not Library.Flags["SilentOpenPacks"] then return end

    -- 1. Whole reveal-modal ScreenGui → destroy
    if desc:IsA("ScreenGui") and REVEAL_SCREENGUI_NAMES[desc.Name] then
        pcall(function() desc.Enabled = false end)
        pcall(function() desc:Destroy() end)
        return
    end

    -- 2. AutoSkip/AutoOpen buttons — ONLY if inside a reveal modal.
    -- We never touch standalone game-HUD buttons with these names.
    if BUTTON_NAMES_TO_KILL[desc.Name] and isInsideRevealModal(desc) then
        pcall(function() desc:Destroy() end)
        return
    end
end

-- Light safety-net walker: just checks top-level ScreenGuis by name.
-- No more "walk every descendant" — that was the lag source AND the bug source.
local function destroyRollUIs()
    if not Library.Flags["SilentOpenPacks"] then return end
    pcall(function()
        local playerGui = client:FindFirstChild("PlayerGui")
        if not playerGui then return end
        for _, screenGui in ipairs(playerGui:GetChildren()) do
            if screenGui:IsA("ScreenGui") and REVEAL_SCREENGUI_NAMES[screenGui.Name] then
                pcall(function() screenGui:Destroy() end)
            end
        end
    end)
    nukeCutsceneEffects()
end

-- DescendantAdded does the real-time work; this just bootstraps it.
local _rollUIHooked = false
local function installRollUIHook()
    if _rollUIHooked then return end
    _rollUIHooked = true
    local playerGui = client:WaitForChild("PlayerGui", 10)
    if not playerGui then return end

    playerGui.DescendantAdded:Connect(function(d)
        task.defer(tryKillBadDescendant, d)
    end)

    -- Lighting / Camera hooks for blur effects spawned mid-cutscene
    pcall(function()
        local lighting = game:GetService("Lighting")
        lighting.ChildAdded:Connect(function(fx)
            if Library.Flags["SilentOpenPacks"] and CUTSCENE_EFFECT_CLASSES[fx.ClassName] then
                task.defer(function() pcall(function() fx.Enabled = false end) end)
            end
        end)
    end)

    destroyRollUIs()
end
installRollUIHook()

local function dispatchWebhook(payload)
    if webhookUrl == "" or not httpRequest then return end

    if webhookPingId ~= "" then
        payload.content = "<@" .. webhookPingId .. ">"
    end

    pcall(function()
        httpRequest({
            Url = webhookUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload),
        })
    end)
end

local globals = (getgenv and getgenv()) or _G
globals.DisablePopups = globals.DisablePopups or false
local function syncUiSuppressFlags()
    globals.DisablePopups = Library.Flags["DisablePopups"] == true
end

local function installPopupBlocker()
    if type(globals) ~= "table" or globals.VersusSSC_PopupHooked then return end
    if not (getrawmetatable and setreadonly and newcclosure and getnamecallmethod and checkcaller) then return end

    local ok = pcall(function()
        local gameMeta = getrawmetatable(game)
        local oldNamecall = gameMeta.__namecall
        setreadonly(gameMeta, false)

        gameMeta.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local shouldBlock = globals.DisablePopups == true
            local isMarketplace = typeof(self) == "Instance" and (self == MarketplaceService or self.ClassName == "MarketplaceService")

            if shouldBlock and not checkcaller() and isMarketplace then
                if method == "PromptProductPurchase" or method == "PromptGamePassPurchase" or method == "PromptPurchase" then
                    return nil
                end
            end

            return oldNamecall(self, ...)
        end)

        setreadonly(gameMeta, true)
        globals.VersusSSC_PopupHooked = true
    end)

    if not ok then
        pcall(function()
            setreadonly(getrawmetatable(game), true)
        end)
    end
end

installPopupBlocker()

if remotes.OpenPack and remotes.OpenPack.OnClientEvent then
    local conn = remotes.OpenPack.OnClientEvent:Connect(function(img, cData, _color, _uuid, _chances, isNew, pName)
        destroyRollUIs()

        if img == "x" or type(cData) ~= "table" then return end
        if not Library.Flags["WebhookRareRolls"] then return end

        local threshName = getSingleFlag("WebhookRarityThresh", RARITY_THRESH_DEFAULT)
        local cardLevel = getRarityLevel(cData.Rarity or "Common")
        if cardLevel < getRarityLevel(threshName) then return end

        local thumbnailUrl = ""
        local imageId = string.match(tostring(cData.ImageId or ""), "%d+")
        if imageId and httpRequest then
            pcall(function()
                local thumbResponse = httpRequest({
                    Url = string.format(ROBLOX_THUMBS, imageId),
                    Method = "GET",
                })

                if thumbResponse and thumbResponse.Body then
                    local parsed = HttpService:JSONDecode(thumbResponse.Body)
                    if parsed.data and parsed.data[1] and parsed.data[1].imageUrl then
                        thumbnailUrl = parsed.data[1].imageUrl
                    end
                end
            end)
        end

        local cards = CardConfig and CardConfig.Cards or {}
        local cardCfg = cards[cData.id]
        local income = tonumber(cData.IncomeRate) or 0
        if type(cardCfg) == "table" then
            income = tonumber(cardCfg.IncomeRate) or income
        end

        dispatchWebhook({
            embeds = {{
                    title = "🎉 Rare Card Rolled!",
                    description = "You just unboxed a high-tier card!",
                    color = rarityColor(cData.Rarity),
                    thumbnail = { url = thumbnailUrl },
                    fields = {
                        { name = "🎴 Card Name", value = tostring(cData.DisplayName or cData.Name or "Unknown"), inline = false },
                        { name = "⭐ Rarity", value = tostring(cData.Rarity or "Unknown"), inline = false },
                        { name = "📦 Pack", value = tostring(pName or "Unknown"), inline = false },
                        { name = "💸 Income", value = "$" .. formatCash(income) .. "/s", inline = false },
                        { name = "✨ New Discovery", value = isNew and "Yes" or "No", inline = false },
                        { name = "🧑 Player", value = "||" .. client.Name .. "||", inline = false },
                    },
                    footer = { text = "SSC Elite Farm • " .. os.date("%H:%M:%S") },
                }}
        })
    end)

    if type(Library.TrackConnection) == "function" then
        pcall(function()
            Library:TrackConnection(conn, "SSC_RareRollWebhook")
        end)
    end
end

local packList = getPackList()
local openPackIndex = 1
local buyPackIndex = 1

-- =============================================
-- STOCK TRACKER (via Notification remote)
-- The game broadcasts "X is out of stock!" messages when we try to buy/craft
-- something that's depleted. We listen and skip that item for 30s.
-- =============================================
local stockState = {
    packCooldown   = {},   -- [packName]   = os.clock() until retry allowed
    trophyCooldown = {},   -- [trophyName] = os.clock() until retry allowed
    cooldownSecs   = 30,
}

local function markPackOutOfStock(packName)
    if not packName or packName == "" then return end
    stockState.packCooldown[packName] = os.clock() + stockState.cooldownSecs
end

local function markTrophyOutOfStock(trophyName)
    if not trophyName or trophyName == "" then return end
    stockState.trophyCooldown[trophyName] = os.clock() + stockState.cooldownSecs
end

local function isPackInStock(packName)
    local t = stockState.packCooldown[packName]
    return not t or os.clock() >= t
end

local function isTrophyInStock(trophyName)
    local t = stockState.trophyCooldown[trophyName]
    return not t or os.clock() >= t
end

-- Listen to game Notification remote for stock-out messages
do
    local notifRemote = getRemote("Notification")
    if notifRemote then
        local ok, cls = pcall(function() return notifRemote.ClassName end)
        if ok and cls == "RemoteEvent" and notifRemote.OnClientEvent then
            -- Track the last pack/trophy each interval tried, so we know what to mark
            notifRemote.OnClientEvent:Connect(function(data)
                pcall(function()
                    if type(data) ~= "table" then return end
                    local msg = tostring(data.Msg or data.message or "")
                    if msg == "" then return end
                    local low = string.lower(msg)
                    -- "This pack is out of stock!" / "Trophy is out of stock!"
                    if string.find(low, "pack is out of stock", 1, true)
                       or string.find(low, "pack is sold out", 1, true) then
                        local lastPack = stockState._lastPackTried
                        if lastPack then
                            markPackOutOfStock(lastPack)
                            stats._packsSkippedNoStock = (stats._packsSkippedNoStock or 0) + 1
                        end
                    elseif string.find(low, "trophy is out of stock", 1, true)
                           or string.find(low, "trophy is sold out", 1, true) then
                        local lastTrophy = stockState._lastTrophyTried
                        if lastTrophy then
                            markTrophyOutOfStock(lastTrophy)
                            stats._trophiesSkippedNoStock = (stats._trophiesSkippedNoStock or 0) + 1
                        end
                    end
                end)
            end)
        end
    end
end

local TabFarm    = Setup:CreateSection("⚔️ Farm & Packs")
local TabPassive = Setup:CreateSection("💎 Passives & Rebirth")
local TabExtras  = Setup:CreateSection("🏆 Trophies & Wish")
local TabTourney = Setup:CreateSection("🥇 Tournament")
local TabPotion  = Setup:CreateSection("🧪 Potions")
local TabWebhook = Setup:CreateSection("📡 Webhooks")
local TabMisc    = Setup:CreateSection("🔧 Misc & Settings")
-- (Analytics tab removed — all live stats are in Discord webhook embeds instead)

TabFarm:createLabel({ Name = "Paid Contributor: aditya44325f", Special = true })

TabFarm:createLabel({ Name = "Plot Automation", Special = true })
TabFarm:createToggle({
    Name = "Auto Collect Cash",
    flagName = "AutoCollect",
    Flag = false,
    Description = "Collects cash from every active card slot.",
    Callback = function() end,
})

TabFarm:createSlider({
    Name = "Collect Delay (Seconds)",
    flagName = "CollectDelay",
    value = COLLECT_DEFAULT,
    minValue = 1,
    maxValue = 60,
    Description = "How often to collect cash from slots.",
    Callback = function() end,
})

TabFarm:createToggle({
    Name = "Auto Equip Best Cards",
    flagName = "AutoEquip",
    Flag = false,
    Description = "Equips the highest income cards into your slots.",
    Callback = function() end,
})

TabFarm:createToggle({
    Name = "🧬 Mutation-Aware Equip",
    flagName = "MutationAwareEquip",
    Flag = true,
    Description = "Score cards by IncomeRate × mutation multiplier (a mutated Bronze can beat unmutated Mythical).",
    Callback = function() end,
})

TabFarm:createToggle({
    Name = "Auto Sell Cards",
    flagName = "AutoSell",
    Flag = false,
    Description = "Sells cards below the selected rarity threshold.",
    Callback = function() end,
})

TabFarm:createDropdown({
    Name = "Sell Below Rarity",
    flagName = "SellThreshold",
    Flag = { SELL_DEFAULT },
    List = rarityList,
    multi = true,
    Description = "Cards under this rarity will be sold.",
    Callback = function() end,
})

TabFarm:createToggle({
    Name = "🛡️ Never Sell Mutated",
    flagName = "NeverSellMutated",
    Flag = true,
    Description = "Protects ANY card with ≥1 mutation regardless of rarity threshold.",
    Callback = function() end,
})

TabFarm:createLabel({ Name = "Pack Automation", Special = true })
TabFarm:createToggle({
    Name = "Auto Open Packs",
    flagName = "AutoOpenPacks",
    Flag = false,
    Description = "Opens selected packs from your inventory.",
    Callback = function() end,
})

TabFarm:createToggle({
    Name = "🤫 Silent Open (No Cutscene)",
    flagName = "SilentOpenPacks",
    Flag = true,
    Description = "Destroys pack-reveal GUIs the instant they spawn. Packs open in background — no animation, no blur.",
    Callback = function() end,
})

local packDropdown = TabFarm:createDropdown({
    Name = "Select Packs to Open",
    flagName = "SelectedPacks",
    Flag = { packList[1] },
    List = packList,
    multi = true,
    Description = "Cycles through all selected packs.",
    Callback = function() end,
})

TabFarm:createButton({
    Name = "Select All Packs to Open",
    Description = "Adds every visible pack to the open list.",
    Callback = function()
        setDropdownValues(packDropdown, "SelectedPacks", packList)
        openPackIndex = 1
    end,
})

TabFarm:createSlider({
    Name = "Open Pack Delay",
    flagName = "PackDelay",
    value = PACK_OPEN_MIN_DELAY,
    minValue = 0.05,
    maxValue = 5,
    Description = "Delay between pack opens. Lower values are clamped slightly to protect FPS.",
    Callback = function() end,
})

TabFarm:createLabel({ Name = "Shop Automation", Special = true })
TabFarm:createToggle({
    Name = "Auto Buy Shop Packs",
    flagName = "AutoBuyPacks",
    Flag = false,
    Description = "Buys selected shop packs when affordable.",
    Callback = function() end,
})

local buyPackDropdown = TabFarm:createDropdown({
    Name = "Select Packs to Buy",
    flagName = "SelectedBuyPacks",
    Flag = { packList[1] },
    List = packList,
    multi = true,
    Description = "Cycles through all selected shop packs.",
    Callback = function() end,
})

TabFarm:createButton({
    Name = "Select All Shop Packs",
    Description = "Adds every visible pack to the buy list.",
    Callback = function()
        setDropdownValues(buyPackDropdown, "SelectedBuyPacks", packList)
        buyPackIndex = 1
    end,
})

TabFarm:createSlider({
    Name = "Buy Pack Delay",
    flagName = "BuyDelay",
    value = PACK_BUY_MIN_DELAY,
    minValue = 0.05,
    maxValue = 900,
    Description = "Delay between buy bursts. Lower = faster spending.",
    Callback = function() end,
})

TabFarm:createSlider({
    Name = "Buy Burst (per tick)",
    flagName = "BuyBurst",
    value = 5,
    minValue = 1,
    maxValue = 20,
    Description = "Max packs bought per tick. Higher = drains cash faster but uses more CPU. Default 5.",
    Callback = function() end,
})

TabFarm:createToggle({
    Name = "Auto Buy Gem Shop",
    flagName = "AutoGemShop",
    Flag = false,
    Description = "Buys the selected gem shop item when you have enough gems.",
    Callback = function() end,
})

TabFarm:createDropdown({
    Name = "Gem Shop Item",
    flagName = "GemShopItemUI",
    Flag = { "Lucky Item" },
    List = { "Lucky Item", "Auto Equip Best", "Auto Skip", "Inventory +500", "Scarlet Item" },
    multi = true,
    Description = "The gem shop item to buy.",
    Callback = function() end,
})

TabFarm:createSlider({
    Name = "Minimum Gems to Keep",
    flagName = "MinGems",
    value = MIN_GEMS_DEFAULT,
    minValue = 0,
    maxValue = 10000,
    Description = "Gem shop buys only run above this gem amount.",
    Callback = function() end,
})

TabFarm:createLabel({ Name = "Inventory Cleanup", Special = true })
TabFarm:createToggle({
    Name = "Auto Delete Packs",
    flagName = "AutoDeletePacks",
    Flag = false,
    Description = "Deletes selected pack types from your inventory.",
    Callback = function() end,
})

TabFarm:createDropdown({
    Name = "Packs to Delete",
    flagName = "DeletePacksList",
    Flag = { packList[1] },
    List = packList,
    multi = true,
    Description = "Selected packs are permanently deleted.",
    Warning = function() return "Deleted packs cannot be recovered." end,
    WarnIf = function() return Library.Flags["AutoDeletePacks"] == true end,
    Callback = function() end,
})

TabPassive:createLabel({ Name = "Rewards", Special = true })
TabPassive:createToggle({ Name = "Auto Claim Index Gems", flagName = "AutoIndex", Flag = false, Description = "Claims all index gems.", Callback = function() end })
TabPassive:createToggle({ Name = "Auto Spin Wheel", flagName = "AutoSpin", Flag = false, Description = "Claims free spins and spins available wheel spins.", Callback = function() end })
TabPassive:createToggle({ Name = "Auto Daily Rewards", flagName = "AutoDaily", Flag = false, Description = "Claims daily rewards.", Callback = function() end })
TabPassive:createToggle({ Name = "Auto Offline Rewards", flagName = "AutoOffline", Flag = false, Description = "Claims offline rewards.", Callback = function() end })

TabPassive:createLabel({ Name = "Progression", Special = true })
TabPassive:createToggle({ Name = "Auto Redeem All Codes", flagName = "AutoRedeemCodes", Flag = false, Description = "Fetches and redeems known codes once per session.", Callback = function() end })
TabPassive:createToggle({ Name = "Auto Rebirth", flagName = "AutoRebirth", Flag = false, Description = "Rebirths when the requirements are met.", Callback = function() end })
TabPassive:createToggle({
    Name = "Force Rebirth",
    flagName = "ForceRebirth",
    Flag = false,
    Description = "Fires the rebirth remote without the local requirement check.",
    Warning = function() return "This can fire before you meet the rebirth requirements." end,
    WarnIf = function() return Library.Flags["ForceRebirth"] == true end,
    Callback = function() end,
})

TabWebhook:createLabel({ Name = "Discord Integration", Special = true })
TabWebhook:createInputBox({
    Name = "Webhook URL",
    flagName = "WebhookURL",
    Flag = "",
    Description = "Discord webhook URL for rare rolls and stats.",
    Callback = function(value)
        webhookUrl = tostring(value or "")
    end,
})

TabWebhook:createInputBox({
    Name = "Discord User ID",
    flagName = "WebhookPingID",
    Flag = "",
    Description = "Optional user ID to ping on webhook posts.",
    Callback = function(value)
        webhookPingId = tostring(value or ""):gsub("[^%d]", "")
    end,
})

TabWebhook:createLabel({ Name = "🎴 Rare Cards", Special = true })
TabWebhook:createToggle({ Name = "Rare Roll Webhook", flagName = "WebhookRareRolls", Flag = false, Description = "Sends a webhook for cards at or above the selected rarity.", Callback = function() end })
TabWebhook:createDropdown({ Name = "Minimum Rarity to Log", flagName = "WebhookRarityThresh", Flag = { RARITY_THRESH_DEFAULT }, List = rarityList, multi = true, Description = "Minimum rarity (multi-select; first selected is used).", Callback = function() end })

TabWebhook:createLabel({ Name = "📊 Periodic Stats", Special = true })
TabWebhook:createToggle({ Name = "Periodic Stats Webhook", flagName = "WebhookStats", Flag = false, Description = "Sends session stats every N minutes.", Callback = function() end })
TabWebhook:createSlider({ Name = "Stats Frequency (Minutes)", flagName = "WebhookStatsDelay", value = STATS_DELAY_DEFAULT, minValue = 1, maxValue = 60, Description = "Minutes between stats posts.", Callback = function() end })
TabWebhook:createToggle({ Name = "Include Equipped Cards in Stats", flagName = "WebhookIncludeEquipped", Flag = true, Description = "List all equipped cards (with rarity) in the stats embed.", Callback = function() end })

TabWebhook:createLabel({ Name = "🥇 Tournament", Special = true })
TabWebhook:createToggle({ Name = "Tournament Finish Webhook", flagName = "WebhookTournament", Flag = false, Description = "Embed when a tournament you're in ends.", Callback = function() end })
TabWebhook:createToggle({ Name = "Tournament Join Webhook", flagName = "WebhookTournamentJoin", Flag = false, Description = "Embed every time auto-join fires.", Callback = function() end })

TabWebhook:createLabel({ Name = "🌟 Milestones", Special = true })
TabWebhook:createToggle({ Name = "Rebirth Milestone Webhook", flagName = "WebhookRebirth", Flag = false, Description = "Embed every time you rebirth.", Callback = function() end })
TabWebhook:createToggle({ Name = "Trophy Crafted Webhook", flagName = "WebhookTrophy", Flag = false, Description = "Embed every time a trophy is crafted.", Callback = function() end })
TabWebhook:createButton({
    Name = "Send Test Webhook",
    Description = "Checks if the webhook URL works.",
    Callback = function()
        if webhookUrl == "" then
            notify("Webhook", "No webhook URL set.", "warning")
            return
        end

        dispatchWebhook({
            embeds = {{
                    title = "🔔 Test Webhook",
                    description = "Spin a Soccer Card webhook is working correctly.",
                    color = 5763719,
                    footer = { text = "Spin a Soccer Card • " .. client.Name },
                }}
        })
        notify("Webhook", "Test sent.", "info")
    end,
})

TabMisc:createLabel({ Name = "Native Pack Settings", Special = true })
TabMisc:createToggle({
    Name = "🎬 Hide Pack Animation (Native)",
    flagName = "PackHideAnim",
    Flag = false,
    Description = "Fires PackSettings('packHideAnimation', true). Server-side — no client hacks, no blur.",
    Callback = function() end,
})

TabMisc:createLabel({ Name = "Game UI", Special = true })
TabMisc:createToggle({ Name = "Disable Game Popups", flagName = "DisablePopups", Flag = false, Description = "Blocks shop/rebirth prompts and hides known prompt GUIs.", Callback = function() end })
TabMisc:createToggle({ Name = "Disable Game Notifications", flagName = "DisableNotifs", Flag = false, Description = "Hides the in-game notification stack.", Callback = function() end })
TabMisc:createToggle({
    Name = "Hide Game HUD",
    flagName = "HideHUD",
    Flag = false,
    Description = "Toggles the game's HUD ScreenGui.",
    Callback = function(value)
        local playerGui = client:FindFirstChild("PlayerGui")
        local hud = playerGui and playerGui:FindFirstChild("HUD")
        if hud then
            hud.Enabled = not value
        end
    end,
})

TabMisc:createButton({
    Name = "Bug Report",
    Description = "Opens the Versus bug reporter.",
    Callback = function()
        pcall(function()
            Library:PromptBugReport()
        end)
    end,
})

-- =============================================
-- 🏆 EXTRAS — Wishing + Trophies
-- =============================================
TabExtras:createLabel({ Name = "✨ Wishing", Special = true })
TabExtras:createLabel({ Name = "PerformWish is a RemoteFunction — invokes every 5s." })

TabExtras:createToggle({
    Name = "Auto Perform Wish",
    flagName = "AutoWish",
    Flag = false,
    Description = "Invokes PerformWish every 5 seconds.",
    Callback = function() end,
})

TabExtras:createButton({
    Name = "✨ Perform Wish Now",
    Description = "One-shot wish.",
    Callback = function()
        if not funcs.PerformWish then notify("Wish", "PerformWish remote missing.", "warning") return end
        pcall(function() funcs.PerformWish:InvokeServer() end)
        stats.wishes += 1
        notify("Wish", "Wish fired.", "info")
    end,
})

TabExtras:createLabel({ Name = "🏆 Trophies", Special = true })
TabExtras:createLabel({ Name = "✓ Stock tracking: skips selected trophies for 30s after \"out of stock\" notification." })

TabExtras:createToggle({
    Name = "Auto Craft Selected Trophies",
    flagName = "AutoCraftTrophy",
    Flag = false,
    Description = "Crafts each in-stock selected trophy every 15s. Counter only ticks on confirmed craft.",
    Callback = function() end,
})

TabExtras:createDropdown({
    Name = "Trophies to Craft",
    flagName = "CraftTrophyList",
    Flag = { trophyLabels[1] },
    List = trophyLabels,
    multi = true,
    Description = "Sorted by rarity (highest first). Multi-select.",
    Callback = function() end,
})

TabExtras:createButton({
    Name = "🛠️ Craft Selected Now",
    Description = "One-shot craft for each selected trophy.",
    Callback = function()
        if not remotes.CraftTrophy then notify("Trophy", "CraftTrophy missing.", "warning") return end
        local selected = getMultiFlag("CraftTrophyList", {})
        if #selected == 0 then notify("Trophy", "No trophies selected.", "warning") return end
        for _, label in ipairs(selected) do
            local name = trophyLabelToName[label] or label
            fireRemote(remotes.CraftTrophy, name)
            stats.trophiesCrafted += 1
        end
        notify("Trophy", "Fired " .. #selected .. " craft attempts.", "info")
    end,
})

-- =============================================
-- 🥇 TOURNAMENT
-- =============================================
TabTourney:createLabel({ Name = "Auto Tournament", Special = true })
TabTourney:createLabel({ Name = "Uses Tournament('join') and Tournament('equip_best')." })

TabTourney:createToggle({
    Name = "Auto Join Tournament",
    flagName = "AutoJoinTournament",
    Flag = false,
    Description = "Joins every 15s when not already in a tournament.",
    Callback = function() end,
})

TabTourney:createToggle({
    Name = "Auto Equip Best Team",
    flagName = "AutoEquipBestTourney",
    Flag = false,
    Description = "Server-side: fires Tournament('equip_best') every 30s.",
    Callback = function() end,
})

TabTourney:createButton({
    Name = "🥇 Join Now",
    Callback = function()
        if not remotes.Tournament then notify("Tournament", "Remote missing.", "warning") return end
        fireRemote(remotes.Tournament, "join")
        tournamentState.joins += 1
        tournamentState.inTournament = true
        notify("Tournament", "Joined.", "info")
    end,
})

TabTourney:createButton({
    Name = "⚡ Equip Best Now",
    Callback = function()
        if not remotes.Tournament then notify("Tournament", "Remote missing.", "warning") return end
        fireRemote(remotes.Tournament, "equip_best")
        notify("Tournament", "Equip best fired.", "info")
    end,
})

local labelTourneyState  = TabTourney:createLabel({ Name = "Status: ⚪ idle" })
local labelTourneyJoins  = TabTourney:createLabel({ Name = "Joined: 0" })
local labelTourneyWins   = TabTourney:createLabel({ Name = "Top-3 finishes: 0" })
local labelTourneyNext   = TabTourney:createLabel({ Name = "Next: --" })


-- =============================================
-- 🧪 POTIONS
-- =============================================
TabPotion:createLabel({ Name = "Weather Potions", Special = true })
TabPotion:createLabel({ Name = "Forces a weather event for 300s. UsePotion(name)." })

TabPotion:createToggle({
    Name = "Auto Use Potion",
    flagName = "AutoUsePotion",
    Flag = false,
    Description = "Uses selected potion every 300s (matches in-game cooldown).",
    Callback = function() end,
})

TabPotion:createDropdown({
    Name = "Potion",
    flagName = "PotionType",
    Flag = { potionList[1] },
    List = potionList,
    multi = true,
    Callback = function() end,
})

TabPotion:createButton({
    Name = "🧪 Use Potion Now",
    Callback = function()
        if not remotes.UsePotion then notify("Potion", "UsePotion remote missing.", "warning") return end
        local p = getSingleFlag("PotionType", potionList[1])
        if not p or p == "" then notify("Potion", "No potion selected.", "warning") return end
        fireRemote(remotes.UsePotion, p)
        stats.potionsUsed += 1
        notify("Potion", "Used " .. tostring(p), "info")
    end,
})


-- =============================================
-- 📊 STATS
-- =============================================
-- (Analytics tab + labels removed; stats only surface in Discord webhooks now.)
-- A small "Reset Stats" button stays in Misc & Settings tab below.

TabMisc:createButton({
    Name = "🔄 Reset Session Stats",
    Description = "Resets all session counters (cards sold, packs opened, etc.).",
    Callback = function()
        stats = {
            opened = 0, bought = 0, sold = 0, rebirths = 0,
            gemBuys = 0, collects = 0, codesRedeemed = true,
            wishes = 0, trophiesCrafted = 0, trophiesApplied = 0,
            tournamentJoins = 0, potionsUsed = 0,
            sessionStart = os.time(),
        }
        tournamentState = { inTournament = false, placement = nil, joins = 0, wins = 0 }
        notify("Stats", "Session stats have been reset.", "info")
    end,
})

interval("AutoOpenPacks", "AutoOpenPacks", function()
    return math.max(tonumber(Library.Flags["PackDelay"]) or PACK_OPEN_MIN_DELAY, PACK_OPEN_MIN_DELAY)
end, function()
    if not remotes.OpenPack then return end

    local selected = getMultiFlag("SelectedPacks", { packList[1] })
    if #selected == 0 then return end
    if openPackIndex > #selected then openPackIndex = 1 end

    local packName = selected[openPackIndex]
    openPackIndex += 1

    local playerData = getPlayerData()
    local hasPack = type(playerData) == "table"
    and type(playerData.packs) == "table"
    and (tonumber(playerData.packs[packName]) or 0) > 0

    if hasPack and fireRemote(remotes.OpenPack, packName) then
        stats.opened += 1
        task.wait(PACK_OPEN_MIN_DELAY)
    else
        task.wait(0.03)
    end
end, { persistent = true, minDelay = PACK_OPEN_MIN_DELAY })

-- Auto Buy Packs: buys a SMALL burst per tick (instead of 200) so we don't
-- spam the network and freeze the client. Higher-tier packs are prioritized.
interval("AutoBuyPacks", "AutoBuyPacks", function()
    return math.max(tonumber(Library.Flags["BuyDelay"]) or PACK_BUY_MIN_DELAY, PACK_BUY_MIN_DELAY)
end, function()
    if not remotes.BuyPack then return end

    local selected = getMultiFlag("SelectedBuyPacks", { packList[1] })
    if #selected == 0 then return end

    local packs = PackConfig and PackConfig.Packs or {}

    -- Sort selected by price DESC so we burn cash on top-tier first
    local sorted = {}
    for _, packName in ipairs(selected) do
        local pd = packs[packName]
        local price = (type(pd) == "table" and tonumber(pd.Price)) or 0
        if price > 0 then
            table.insert(sorted, { name = packName, price = price })
        end
    end
    table.sort(sorted, function(a, b) return a.price > b.price end)

    -- Conservative: at most 5 buys per tick total (tunable via slider).
    -- This is still 5× faster than the old "one per tick" but doesn't melt the CPU.
    local burstCap = math.max(1, math.min(20, tonumber(Library.Flags["BuyBurst"]) or 5))
    local fired = 0
    for _, entry in ipairs(sorted) do
        if fired >= burstCap then break end
        if isPackInStock(entry.name) and getCash() >= entry.price then
            stockState._lastPackTried = entry.name
            if fireRemote(remotes.BuyPack, entry.name) then
                stats.bought += 1
                fired += 1
                task.wait(PACK_BUY_MIN_DELAY)
            else
                break
            end
        end
    end
end, { persistent = true, minDelay = PACK_BUY_MIN_DELAY })

interval("AutoCollect", "AutoCollect", function()
    return tonumber(Library.Flags["CollectDelay"]) or COLLECT_DEFAULT
end, function()
    if not remotes.CollectSlot then return end

    for slotIndex, slotData in pairs(getSlots()) do
        if type(slotData) == "table" and slotData.card then
            if fireRemote(remotes.CollectSlot, tonumber(slotIndex) or slotIndex) then
                stats.collects += 1
            end
            task.wait(COLLECT_SLOT_WAIT)
        end
    end
end, { persistent = true })

interval("AutoSell", "AutoSell", 8, function()
    if not remotes.SellCards then return end

    local thresholdName = getSingleFlag("SellThreshold", SELL_DEFAULT)
    local thresholdLevel = getRarityLevel(thresholdName)
    local blockedIds = { LocalCard = true, OwnerVulnone = true }
    local cards = CardConfig and CardConfig.Cards or {}
    local toSell = {}

    local scannedCards = 0
    for _, card in pairs(getInventory()) do
        scannedCards += 1
        lightYield(scannedCards)

        local isEligible = type(card) == "table"
        and card.id
        and card.uuid
        and not card.throneCard
        and not card.locked
        and not blockedIds[card.id]

        if isEligible then
            -- Protect mutated cards if the toggle is on
            local mutCount = #getCardMutations(card)
            local isMutated = mutCount > 0
            if Library.Flags["NeverSellMutated"] and isMutated then
                -- skip
            else
                local cfg = cards[card.id]
                local cardLevel = getRarityLevel(type(cfg) == "table" and cfg.Rarity or nil)
                if cardLevel < thresholdLevel then
                    table.insert(toSell, card.uuid)
                end
            end
        end
    end

    if #toSell > 0 and fireRemote(remotes.SellCards, toSell) then
        stats.sold += #toSell
        task.wait(0.2)
    end
end, { persistent = true })

interval("AutoDeletePacks", "AutoDeletePacks", 10, function()
    local selected = getMultiFlag("DeletePacksList", {})
    if #selected > 0 then
        fireRemote(remotes.DeletePacks, selected)
    end
end, { persistent = true })

interval("AutoEquip", "AutoEquip", 8, function()
    equipBest()
end, { persistent = true })

interval("AutoGemShop", "AutoGemShop", 10, function()
    if not remotes.BuyGemShopItem then return end

    local itemName = getSingleFlag("GemShopItemUI", "Lucky Item")
    local itemId = GEM_SHOP_MAP[itemName] or "lucky"
    local minGems = tonumber(Library.Flags["MinGems"]) or MIN_GEMS_DEFAULT

    if getGems() >= minGems and fireRemote(remotes.BuyGemShopItem, itemId) then
        stats.gemBuys += 1
    end
end, { persistent = true })

interval("AutoIndex", "AutoIndex", 15, function()
    fireRemote(remotes.ClaimAllIndexGems)
end, { persistent = true })

interval("AutoSpin", "AutoSpin", 8, function()
    local spinData = invokeRemote(funcs.SpinWheelData)
    if type(spinData) ~= "table" then return end

    if spinData.canClaimFree then
        fireRemote(remotes.SpinWheel, "claim_free")
    end
    if type(spinData.spins) == "number" and spinData.spins > 0 then
        fireRemote(remotes.SpinWheel, "spin")
    end
end, { persistent = true })

interval("AutoDaily", "AutoDaily", 60, function()
    fireRemote(remotes.DailyReward, "claim")
end, { persistent = true })

interval("AutoOffline", "AutoOffline", 60, function()
    fireRemote(remotes.OfflineReward, "claim_normal")
end, { persistent = true })

-- =============================================
-- AUTO WISH (PerformWish is a RemoteFunction!)
-- =============================================
interval("AutoWish", "AutoWish", 5, function()
    if not funcs.PerformWish then return end
    local ok = pcall(function() funcs.PerformWish:InvokeServer() end)
    if ok then stats.wishes += 1 end
end, { persistent = true })

-- =============================================
-- AUTO CRAFT TROPHY (multi-select; needs trophy NAME arg)
-- =============================================
-- AUTO CRAFT TROPHY
-- Only fires for trophies that are IN STOCK. Counter only increments after
-- we confirm via PlayerData that the trophy actually appeared in inventory.
-- Helper: count how many of a trophy the player owns (single PlayerData read)
local function countTrophy(playerData, name)
    if not playerData then return 0 end
    local t = playerData.trophies or {}
    local n = 0
    for k, tr in pairs(t) do
        local trName = (type(tr) == "table" and (tr.name or tr.id)) or (type(k) == "string" and k or nil)
        if trName == name then n += 1 end
    end
    return n
end

interval("AutoCraftTrophy", "AutoCraftTrophy", 15, function()
    if not remotes.CraftTrophy then return end
    local selected = getMultiFlag("CraftTrophyList", {})
    if #selected == 0 then return end

    -- Single snapshot of "before" counts for all selected trophies
    local before = {}
    local snapBefore = getPlayerData()
    for _, label in ipairs(selected) do
        local name = trophyLabelToName[label] or label
        before[name] = countTrophy(snapBefore, name)
    end

    -- Fire crafts in a small burst (cap 3 per tick)
    local cap, fired = 3, 0
    for _, label in ipairs(selected) do
        if fired >= cap then break end
        local name = trophyLabelToName[label] or label
        if isTrophyInStock(name) then
            stockState._lastTrophyTried = name
            if fireRemote(remotes.CraftTrophy, name) then
                fired += 1
                task.wait(0.25)
            end
        end
    end
    if fired == 0 then return end

    -- Wait for server to apply, then ONE delta-snapshot
    task.wait(0.4)
    local snapAfter = getPlayerData()
    for name, beforeCount in pairs(before) do
        local afterCount = countTrophy(snapAfter, name)
        if afterCount > beforeCount then
            stats.trophiesCrafted += (afterCount - beforeCount)
            if Library.Flags["WebhookTrophy"] then
                dispatchWebhook({ embeds = {{
                    title = "🏆 Trophy Crafted",
                    description = "Crafted **" .. tostring(name) .. "** (+" .. (afterCount - beforeCount) .. ")",
                    color = 16766720,
                    footer = { text = "Spin a Soccer Card" },
                }}})
            end
        end
    end
end, { persistent = true })

-- =============================================
-- TOURNAMENT TRACKER + SMART JOIN
-- Tracks the active tournament window via TournamentClock helper
-- (or its derivatives). Only fires "join" while a tournament is OPEN
-- and the player isn't already in it.
-- =============================================
local function getTournamentStatus()
    -- Returns a table: { isOpen=bool, secondsUntilOpen=number?, secondsUntilClose=number? }
    -- Best-effort: tries several common APIs on TournamentClock + falls back to attribute scans.
    local out = { isOpen = false, secondsUntilOpen = nil, secondsUntilClose = nil }

    if type(TournamentClock) == "table" then
        for _, fn in ipairs({ "GetState", "getState", "GetCurrent", "GetWindow", "getStatus" }) do
            if type(TournamentClock[fn]) == "function" then
                local ok, info = pcall(TournamentClock[fn])
                if ok and type(info) == "table" then
                    if info.isOpen ~= nil then out.isOpen = info.isOpen
                    elseif info.active ~= nil then out.isOpen = info.active
                    elseif info.running ~= nil then out.isOpen = info.running end
                    out.secondsUntilOpen  = info.secondsUntilOpen  or info.untilStart or info.startsIn
                    out.secondsUntilClose = info.secondsUntilClose or info.untilEnd   or info.endsIn
                    return out
                end
            end
        end
        -- Some games expose: GetSecondsUntilStart() / IsActive()
        if type(TournamentClock.IsActive) == "function" then
            local ok, v = pcall(TournamentClock.IsActive)
            if ok then out.isOpen = v == true end
        end
        if type(TournamentClock.GetSecondsUntilStart) == "function" then
            local ok, v = pcall(TournamentClock.GetSecondsUntilStart)
            if ok then out.secondsUntilOpen = tonumber(v) end
        end
        if type(TournamentClock.GetSecondsUntilEnd) == "function" then
            local ok, v = pcall(TournamentClock.GetSecondsUntilEnd)
            if ok then out.secondsUntilClose = tonumber(v) end
        end
    end

    -- Fallback: scan workspace for a "TournamentSessionActive" / "TournamentPrompt" attribute or sign
    if not out.isOpen then
        pcall(function()
            local sign = Workspace:FindFirstChild("TournamentSign", true)
                       or Workspace:FindFirstChild("TournamentPrompt", true)
            if sign then
                local active = sign:GetAttribute("Active") or sign:GetAttribute("IsOpen")
                if active ~= nil then out.isOpen = active == true end
                local sUntil = sign:GetAttribute("StartsIn") or sign:GetAttribute("SecondsUntilOpen")
                if sUntil then out.secondsUntilOpen = tonumber(sUntil) end
            end
        end)
    end

    return out
end

interval("AutoJoinTournament", "AutoJoinTournament", 5, function()
    if not remotes.Tournament then return end
    if tournamentState.inTournament then return end

    local status = getTournamentStatus()
    tournamentState.lastStatus = status

    -- Only join when tournament is actually OPEN
    if not status.isOpen then return end

    if fireRemote(remotes.Tournament, "join") then
        tournamentState.joins += 1
        stats.tournamentJoins += 1
        tournamentState.inTournament = true
        notify("Tournament", "Auto-joined tournament", "info")
        if Library.Flags["WebhookTournamentJoin"] then
            dispatchWebhook({ embeds = {{
                title = "🥇 Tournament Joined",
                description = "Auto-joined an open tournament.",
                color = 5763719,
                footer = { text = "Spin a Soccer Card" },
            }}})
        end
    end
end, { persistent = true })

interval("AutoEquipBestTourney", "AutoEquipBestTourney", 30, function()
    if not remotes.Tournament then return end
    -- Only equip best while in a tournament (avoids wasted fires)
    if not tournamentState.inTournament then return end
    fireRemote(remotes.Tournament, "equip_best")
end, { persistent = true })

-- =============================================
-- AUTO USE POTION (force weather event, 300s cooldown)
-- =============================================
interval("AutoUsePotion", "AutoUsePotion", 300, function()
    if not remotes.UsePotion then return end
    local potion = getSingleFlag("PotionType", potionList[1])
    if not potion or potion == "" then return end
    if fireRemote(remotes.UsePotion, potion) then
        stats.potionsUsed += 1
    end
end, { persistent = true })

-- =============================================
-- NATIVE PACK SETTINGS SYNC (hide-animation toggle, server-side)
-- =============================================
local _lastPackHide = nil
interval("PackSettingsSync", nil, 1, function()
    if not remotes.PackSettings then return end
    local desired = Library.Flags["PackHideAnim"] == true
    if desired ~= _lastPackHide then
        _lastPackHide = desired
        fireRemote(remotes.PackSettings, "packHideAnimation", desired)
    end
end, { persistent = true })

interval("AutoRedeemCodes", "AutoRedeemCodes", 1, function()
    if stats.codesRedeemed then return end
    stats.codesRedeemed = true

    local codes = {}
    local ok, result = pcall(function()
        return game:HttpGet(CODES_URL)
    end)

    if ok and type(result) == "string" then
        for line in result:gmatch("[^\r\n]+") do
            local cleaned = line:gsub("%s+", "")
            if cleaned ~= "" and #cleaned >= 3 then
                table.insert(codes, cleaned)
            end
        end
    end

    if #codes == 0 then
        notify("Codes", "No codes were found.", "warning")
        return
    end

    for _, code in ipairs(codes) do
        fireRemote(remotes.RedeemCode, string.lower(code))
        task.wait(CODE_WAIT)
    end

    notify("Codes", "Redeemed " .. #codes .. " codes.", "info")
end, { persistent = true })

interval("AutoRebirth", "AutoRebirth", function()
    return Library.Flags["ForceRebirth"] and REBIRTH_CD_FORCE or REBIRTH_CD_NORMAL
end, function()
    local shouldRebirth = Library.Flags["ForceRebirth"] == true or canRebirth()
    if not shouldRebirth then return end

    local before = getRebirthLevel()
    fireRemote(remotes.Rebirth)
    task.wait(1.5)

    if getRebirthLevel() > before then
        stats.rebirths += 1
        if Library.Flags["WebhookRebirth"] then
            dispatchWebhook({ embeds = {{
                title = "🌟 Rebirth!",
                description = "Reached **Rebirth Level " .. getRebirthLevel() .. "**",
                color = 15844367,
                footer = { text = "Spin a Soccer Card • " .. client.Name },
            }}})
        end
    end
end, { persistent = true })

-- Computes the actual displayed income of an equipped card.
-- Priority order:
--   1. slot.income (server-computed live income — includes mutations + boosts)
--   2. slot.card.income  (same, alternate location)
--   3. card.IncomeRate   (per-card override stamped at roll-time)
--   4. CardConfig.Cards[id].IncomeRate (base, last resort)
-- This is why Wirtz showed $0/s before — Exclusive cards are missing from CardConfig
-- so the lookup returned nil → 0. We now read the live computed value first.
local function getLiveCardIncome(slotData)
    if type(slotData) ~= "table" then return 0 end

    local fromSlot = tonumber(slotData.income) or tonumber(slotData.IncomeRate)
        or tonumber(slotData.totalIncome) or tonumber(slotData.eps)
    if fromSlot and fromSlot > 0 then return fromSlot end

    local card = slotData.card
    if type(card) == "table" then
        local fromCard = tonumber(card.income) or tonumber(card.IncomeRate)
            or tonumber(card.totalIncome) or tonumber(card.eps)
        if fromCard and fromCard > 0 then return fromCard end

        local cfg = CardConfig and CardConfig.Cards and CardConfig.Cards[card.id]
        if type(cfg) == "table" then
            return tonumber(cfg.IncomeRate) or 0
        end
    end
    return 0
end

-- Returns a list of currently equipped cards
local function getEquippedCardsList()
    local cards = CardConfig and CardConfig.Cards or {}
    local out = {}
    for slotIndex, sd in pairs(getSlots()) do
        if type(sd) == "table" and type(sd.card) == "table" and sd.card.id then
            local cfg = cards[sd.card.id]
            local muts = getCardMutations(sd.card)
            -- Try card-level rarity overrides for exclusives
            local rarity = (sd.card.rarity or sd.card.Rarity)
                or (cfg and cfg.Rarity) or "?"
            local name = (sd.card.name or sd.card.displayName or sd.card.DisplayName)
                or (cfg and cfg.DisplayName) or sd.card.id
            table.insert(out, {
                slot = tonumber(slotIndex) or slotIndex,
                id = sd.card.id,
                name = name,
                rarity = rarity,
                income = getLiveCardIncome(sd),
                mutationCount = #muts,
                mutations = muts,
            })
        end
    end
    table.sort(out, function(a, b)
        if type(a.slot) == "number" and type(b.slot) == "number" then return a.slot < b.slot end
        return tostring(a.slot) < tostring(b.slot)
    end)
    return out
end

local function formatEquippedForWebhook()
    local list = getEquippedCardsList()
    if #list == 0 then return "_(no cards equipped)_" end
    local lines = {}
    for _, c in ipairs(list) do
        local mutText = ""
        if c.mutationCount > 0 then mutText = " 🧬x" .. c.mutationCount end
        table.insert(lines, string.format("`#%s` ⚽ **%s** • _%s_ • 💵 $%s/s%s",
            tostring(c.slot), c.name, c.rarity, formatCash(c.income), mutText))
    end
    return table.concat(lines, "\n")
end

-- Slim stats webhook — only the top summary block + equipped cards list.
-- (Removed Cards Sold / Rebirths / Gem Buys / Wishes / Trophies / Potions / Tournaments
-- as requested.)
interval("WebhookStats", "WebhookStats", function()
    return math.max((tonumber(Library.Flags["WebhookStatsDelay"]) or STATS_DELAY_DEFAULT) * 60, 60)
end, function()
    local uptime = os.time() - (stats.sessionStart or os.time())
    local equippedText = Library.Flags["WebhookIncludeEquipped"] ~= false
        and formatEquippedForWebhook()
        or "_(disabled in Webhooks tab)_"

    local description = table.concat({
        "💰 **Cash:** $" .. formatCash(getCash()),
        "💎 **Gems:** " .. formatCash(getGems()),
        "🌟 **Rebirth Level:** " .. getRebirthLevel(),
        "📦 **Packs Opened:** " .. formatCash(stats.opened),
        "🛒 **Packs Bought:** " .. formatCash(stats.bought),
        "⏱️ **Uptime:** " .. string.format("%02d:%02d:%02d",
            math.floor(uptime / 3600),
            math.floor((uptime % 3600) / 60),
            uptime % 60),
    }, "\n")

    dispatchWebhook({
        embeds = {{
            title = "📊 Spin a Soccer Card • Session Stats",
            description = description,
            color = 3447003,
            fields = {
                { name = "⚽ Equipped Cards", value = equippedText, inline = false },
            },
            footer = { text = "Spin a Soccer Card • " .. client.Name .. " • " .. os.date("%H:%M:%S") },
        }}
    })
end, { persistent = true })

interval("SSC_SuppressFlagSync", nil, 1, function()
    syncUiSuppressFlags()
end)

-- Safety-net loop. Runs every 2 seconds (instead of 0.1s) because the
-- DescendantAdded listener catches 99% of cases instantly — this is just a
-- backup for anything that slipped through. 0.1s was hammering the CPU.
interval("SSC_RollUINuker", nil, 2, function()
    destroyRollUIs()
end)

-- Suppressor: runs once per second; bails internally if both flags are off.
-- (Previous version passed a function as the flag arg, which our interval helper
-- treats as the flag's name — the loop never actually ran.)
interval("SSC_GuiSuppressor", nil, 1, function()
    local wantPopups = Library.Flags["DisablePopups"] == true
    local wantNotifs = Library.Flags["DisableNotifs"] == true
    if not wantPopups and not wantNotifs then return end

    local playerGui = client:FindFirstChild("PlayerGui")
    if not playerGui then return end

    if wantPopups then
        for _, promptName in ipairs({
            "RebirthPrompt", "OfflineRewardPrompt", "BoothPurchasePrompt",
            "PurchasePrompt", "ConfirmPurchase", "GamepassPrompt", "ProductPrompt",
        }) do
            local promptGui = playerGui:FindFirstChild(promptName)
            if promptGui and promptGui:IsA("ScreenGui") and promptGui.Enabled then
                promptGui.Enabled = false
            end
        end
    end

    if wantNotifs then
        local notifGui = playerGui:FindFirstChild("Notification")
        if notifGui and notifGui:IsA("ScreenGui") then
            -- Disable the whole ScreenGui (visible toggle)
            if notifGui.Enabled then notifGui.Enabled = false end
            -- AND empty out the active notification stack so it doesn't accumulate
            local mainFrame = notifGui:FindFirstChild("Main")
            if mainFrame then
                for _, child in ipairs(mainFrame:GetChildren()) do
                    local isPlaceholder = child.Name == "Placeholder"
                        or child.Name == "PlaceholderAnnouncement"
                    if child:IsA("Frame") and not isPlaceholder and child.Visible then
                        child.Visible = false
                    end
                end
            end
        end
    end
end)

-- Also kill notifications + popups the INSTANT they spawn via DescendantAdded.
-- This catches the ones the 1-second poller would otherwise miss.
do
    local playerGui = client:WaitForChild("PlayerGui", 5)
    if playerGui then
        playerGui.ChildAdded:Connect(function(child)
            task.defer(function()
                pcall(function()
                    if not child or not child.Parent then return end
                    local nm = child.Name
                    if Library.Flags["DisableNotifs"] and nm == "Notification" and child:IsA("ScreenGui") then
                        child.Enabled = false
                    end
                    if Library.Flags["DisablePopups"]
                       and (nm == "RebirthPrompt" or nm == "OfflineRewardPrompt"
                            or nm == "BoothPurchasePrompt" or nm == "PurchasePrompt"
                            or nm == "ConfirmPurchase" or nm == "GamepassPrompt"
                            or nm == "ProductPrompt")
                       and child:IsA("ScreenGui") then
                        child.Enabled = false
                    end
                end)
            end)
        end)
    end
end

local function formatDuration(secs)
    secs = math.max(0, math.floor(secs))
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- Slim UI updater: only refreshes the tournament tracker labels (Analytics tab removed).
interval("SSC_TourneyUIUpdate", nil, 3, function()
    pcall(function()
        local tStatus = getTournamentStatus()
        local statusEmoji = tournamentState.inTournament and "🟢 in tournament"
            or (tStatus.isOpen and "🟡 open — joinable" or "⚪ idle")
        if labelTourneyState and labelTourneyState.Set then labelTourneyState:Set("Status: " .. statusEmoji) end
        if labelTourneyJoins and labelTourneyJoins.Set then labelTourneyJoins:Set("Joined: " .. tournamentState.joins) end
        if labelTourneyWins  and labelTourneyWins.Set  then labelTourneyWins:Set("Top-3 finishes: " .. tournamentState.wins) end
        if labelTourneyNext  and labelTourneyNext.Set  then
            local nextText = "--"
            if tStatus.isOpen and tStatus.secondsUntilClose then
                nextText = "ends in " .. formatDuration(tStatus.secondsUntilClose)
            elseif tStatus.secondsUntilOpen then
                nextText = "starts in " .. formatDuration(tStatus.secondsUntilOpen)
            end
            labelTourneyNext:Set("Next: " .. nextText)
        end
    end)
end)

-- =============================================
-- TOURNAMENT LISTENER (safely connects only if RemoteEvent)
-- =============================================
do
    local r = remotes.Tournament
    if r then
        local ok, cls = pcall(function() return r.ClassName end)
        if ok and cls == "RemoteEvent" and r.OnClientEvent then
            r.OnClientEvent:Connect(function(data)
                pcall(function()
                    if type(data) ~= "table" then return end
                    if data.placement then tournamentState.placement = data.placement end
                    if data.active == false or data.ended or data.finished then
                        if tournamentState.inTournament then
                            tournamentState.inTournament = false
                            if (tournamentState.placement or 999) <= 3 then
                                tournamentState.wins += 1
                            end
                            if Library.Flags["WebhookTournament"] then
                                dispatchWebhook({ embeds = {{
                                    title = "🏆 Tournament Finished",
                                    description = "Placement: **" .. tostring(tournamentState.placement or "?") .. "**",
                                    color = (tournamentState.placement or 999) <= 3 and 16766720 or 7506394,
                                    footer = { text = "Spin a Soccer Card" },
                                }}})
                            end
                        end
                    elseif data.active == true then
                        tournamentState.inTournament = true
                    end
                end)
            end)
        end
    end
end


-- =============================================
-- STARTUP DIAGNOSTIC
-- =============================================
do
    local report = { "[SSC] Remote resolution:" }
    local function chk(name, t)
        local r = (t or remotes)[name]
        local cls = "nil"
        if r then pcall(function() cls = r.ClassName end) end
        table.insert(report, "  " .. name .. " = " .. tostring(r ~= nil) .. " (" .. cls .. ")")
    end
    for _, n in ipairs({
        "OpenPack","BuyPack","SellCards","CollectSlot","EquipCard","DeletePacks",
        "Rebirth","BuyGemShopItem","ClaimAllIndexGems","DailyReward","OfflineReward",
        "SpinWheel","RedeemCode",
        "CraftTrophy","ApplyTrophy","DestroyTrophy",
        "Tournament","UsePotion","PackSettings","Wish",
    }) do chk(n) end
    chk("PerformWish", funcs)
    chk("SpinWheelData", funcs)
    print(table.concat(report, "\n"))
    print(string.format("[SSC] Loaded successfully. %d trophies, %d potions, %d packs available.",
        #trophyLabels, #potionList, #packList))
    notify("Spin a Soccer Card", "Script loaded — all auto loops armed.", "info")
end
