local request = (syn and syn.request) or (http and http.request) or http_request;

-- Essential services
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LightingService = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.Camera

local client = Players.LocalPlayer

-- Load UI
print("Loading Library...")

local Library = loadstring(game:HttpGet("https://versusairlines.top/scripts/NewLibrary.lua"))()

local Setup = Library:Setup({
    Location = CoreGui,
    OpenCloseLocation = "Bottom Left" -- Top Right, Bottom Left, Center Left, Etc
})

-- Prevent player from being idled out
client.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-----------------------------------------------------------------

-- interval: registers a heartbeat-driven loop ONCE at script load.
-- The loop is gated by the flag (or runs always if flag==nil), so toggling
-- the UI on/off instantly enables/disables the loop without needing the
-- Callback to re-register anything.
--
-- Signature:
--   interval(tag, flag, delayTime, callback, opts?)
--   interval(tag, flag, dynamicDelayFn, callback, opts?)   -- delay can be a function returning a number
--
-- `flag` may be nil → loop runs unconditionally (used for housekeeping).
-- `delayTime` may be a number OR a function returning a number (dynamic).
local function interval(tag, flag, delayTime, callback, opts)
    Library:CleanupConnectionsByTag(tag)

    local isDynamicDelay = type(delayTime) == "function"
    local function resolveDelay()
        local d
        if isDynamicDelay then
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

    local last = 0
    local running = false
    local slowWarnAt = 0

    local conn = RunService.Heartbeat:Connect(function()
        -- Gate by flag (nil flag = always run)
        if flag ~= nil and not Library.Flags[flag] then return end

        local current = os.clock()
        if running or current - last < resolveDelay() then
            return
        end

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
                warn(string.format("[SSC] slow interval %s took %.3fs", tostring(tag), elapsed))
            end

            running = false
        end)
    end)

    Library:TrackConnection(conn, tag)
end

local function notify(title, desc, style) -- style examples: "info" | "warning" | "danger"
    Library:createDisplayMessage(title, desc, {
        { text = "OK" },
    }, style or "info")
end

local function prettyPrint(data, indent)
    indent = indent or 0
    local prefix = string.rep("    ", indent)
    if type(data) ~= "table" then
        print(prefix .. tostring(data))
        return
    end
    for k, v in pairs(data) do
        if type(v) == "table" then
            print(prefix .. tostring(k) .. " = {")
            prettyPrint(v, indent + 1)
            print(prefix .. "}")
        else
            print(prefix .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

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
    if (tonumber(index) or 0) % INVENTORY_YIELD_EVERY == 0 then
        task.wait()
    end
end

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
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

local function resolvePath(root, ...)
    local current = root
    for _, name in ipairs({ ... }) do
        if not current then return nil end
        current = current:FindFirstChild(tostring(name))
    end
    return current
end

local function safeRequire(module, label, silent)
    if not module or not module:IsA("ModuleScript") then
        if not silent then warn("[Spin a Soccer Card] Not a module: " .. tostring(label)) end
        return nil
    end
    local ok, result = pcall(require, module)
    if not ok then
        if not silent then warn("[Spin a Soccer Card] require failed for " .. tostring(label) .. ": " .. tostring(result)) end
        return nil
    end
    return result
end

local function requirePath(label, ...)
    local module = resolvePath(RS, ...)
    if not module then
        warn("[Spin a Soccer Card] Missing module: " .. tostring(label))
        return nil
    end
    return safeRequire(module, label, true)
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

local function fireRemote(remote, ...)
    if not remote or type(remote.FireServer) ~= "function" then return false end
    local args = { ... }
    local argCount = select("#", ...)
    local ok = pcall(function()
        remote:FireServer(tableUnpack(args, 1, argCount))
    end)
    return ok
end

local function invokeRemote(remote, ...)
    if not remote or type(remote.InvokeServer) ~= "function" then return nil end
    local args = { ... }
    local argCount = select("#", ...)
    local ok, result = pcall(function()
        return remote:InvokeServer(tableUnpack(args, 1, argCount))
    end)
    if ok then return result end
    return nil
end

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

local function formatCash(n)
    n = tonumber(n) or 0
    if n >= 1e12 then
        return string.format("%.2fT", n / 1e12)
    elseif n >= 1e9 then
        return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.1fK", n / 1e3)
    end
    return tostring(math.floor(n))
end

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
-- ROLL UI NUKER — kills AutoSkip/AutoOpen buttons + pack reveal GUI
-- the INSTANT they spawn. Runs in three ways:
--   1. Continuous walker (every 0.05s) — fallback safety net
--   2. DescendantAdded listener on PlayerGui — catches anything new instantly
--   3. ChildAdded on each ScreenGui — catches reveal frames as they mount
-- =============================================

local BUTTON_NAMES_TO_KILL = {
    AutoSkip = true, AutoOpen = true,
    autoSkip = true, autoOpen = true,
    ["Auto Skip"] = true, ["Auto Open"] = true,
}

-- Aggressive list: any ScreenGui whose name contains any of these is killed
-- when Silent Open is on. Also handles the BlurEffect that the cutscene adds.
local REVEAL_GUI_NAME_PATTERNS = {
    "packopen", "openpack", "packreveal", "cardreveal", "revealpack",
    "reveal", "packopening", "openinganim", "packanim",
    "open_pack", "open-pack", "cardpopup", "rollscreen", "rollui",
    "rolling", "gachareveal", "boxopen", "cardresult",
}

-- Class names of effects we want gone during silent open (cutscene blur)
local CUTSCENE_EFFECT_CLASSES = {
    BlurEffect = true, ColorCorrectionEffect = true,
    DepthOfFieldEffect = true, BloomEffect = true,
}

local function nameLooksLikeRevealGui(name)
    if type(name) ~= "string" then return false end
    local lower = string.lower(name)
    for _, p in ipairs(REVEAL_GUI_NAME_PATTERNS) do
        if string.find(lower, p, 1, true) then return true end
    end
    return false
end

-- Kill cutscene post-process effects (the blur lingering after silent open)
local function nukeCutsceneEffects()
    pcall(function()
        local lighting = game:GetService("Lighting")
        for _, fx in ipairs(lighting:GetChildren()) do
            if CUTSCENE_EFFECT_CLASSES[fx.ClassName] and fx.Enabled then
                fx.Enabled = false
            end
        end
        -- Also check workspace.CurrentCamera (some games attach blur there)
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
    -- 1. Buttons we want gone
    if BUTTON_NAMES_TO_KILL[desc.Name] then
        pcall(function() desc:Destroy() end)
        return
    end
    -- 2. Reveal screen GUIs (silent open) — destroy entirely
    if Library.Flags["SilentOpenPacks"] and desc:IsA("ScreenGui") and nameLooksLikeRevealGui(desc.Name) then
        pcall(function() desc.Enabled = false end)
        pcall(function() desc:Destroy() end)
        return
    end
    -- 3. Frames whose name matches reveal patterns (some games nest the reveal in MainGui)
    if Library.Flags["SilentOpenPacks"] and (desc:IsA("Frame") or desc:IsA("ImageLabel"))
       and nameLooksLikeRevealGui(desc.Name) then
        pcall(function() desc.Visible = false end)
        return
    end
end

-- LIGHT version: only walks TOP-LEVEL ScreenGui children + their ButtonsContainer.
-- This is the safety-net loop — the heavy lifting is done by DescendantAdded.
-- Walking the full PlayerGui (often 3000+ descendants) was the #1 source of lag.
local function destroyRollUIs()
    pcall(function()
        local playerGui = client:FindFirstChild("PlayerGui")
        if not playerGui then return end
        for _, screenGui in ipairs(playerGui:GetChildren()) do
            -- Check the top-level GUI itself
            tryKillBadDescendant(screenGui)
            -- Only walk one level deep, looking for common "ButtonsContainer" patterns
            if screenGui:IsA("ScreenGui") then
                local frame = screenGui:FindFirstChild("Frame")
                if frame then
                    local buttons = frame:FindFirstChild("ButtonsContainer")
                    if buttons then
                        for _, btn in ipairs(buttons:GetChildren()) do
                            if BUTTON_NAMES_TO_KILL[btn.Name] then
                                pcall(function() btn:Destroy() end)
                            end
                        end
                    end
                end
            end
        end
    end)
    if Library.Flags["SilentOpenPacks"] then
        nukeCutsceneEffects()
    end
end

-- Hook DescendantAdded once for instant kills
local _rollUIHooked = false
local function installRollUIHook()
    if _rollUIHooked then return end
    _rollUIHooked = true
    local playerGui = client:WaitForChild("PlayerGui", 10)
    if not playerGui then return end
    playerGui.DescendantAdded:Connect(function(d)
        -- Defer one frame so name/parent are stable
        task.defer(tryKillBadDescendant, d)
    end)
    -- Also hook Lighting + Camera for blur effects added at runtime
    pcall(function()
        local lighting = game:GetService("Lighting")
        lighting.ChildAdded:Connect(function(fx)
            if Library.Flags["SilentOpenPacks"] and CUTSCENE_EFFECT_CLASSES[fx.ClassName] then
                task.defer(function() pcall(function() fx.Enabled = false end) end)
            end
        end)
    end)
    -- Also hammer everything that exists right now
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
local TabStats   = Setup:CreateSection("📊 Analytics")

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

TabExtras:createToggle({
    Name = "Auto Apply Trophies to Best Plots",
    flagName = "AutoApplyTrophy",
    Flag = false,
    Description = "Pairs highest-tier trophy with highest-EPS plot. ApplyTrophy(name, plot).",
    Callback = function() end,
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
TabStats:createLabel({ Name = "Live Session Analytics", Special = true })
local labelCash = TabStats:createLabel({ Name = "💰 Cash: $0" })
local labelGems = TabStats:createLabel({ Name = "💎 Gems: 0" })
local labelRebirth = TabStats:createLabel({ Name = "🌟 Rebirth Level: 0" })
local labelOpened = TabStats:createLabel({ Name = "📦 Packs Opened: 0" })
local labelBought = TabStats:createLabel({ Name = "🛒 Packs Bought: 0" })
local labelSold = TabStats:createLabel({ Name = "💸 Cards Sold: 0" })
local labelCollects = TabStats:createLabel({ Name = "💵 Collects: 0" })
local labelGemBuys = TabStats:createLabel({ Name = "💎 Gem Buys: 0" })
local labelSessionRebirths = TabStats:createLabel({ Name = "🔄 Session Rebirths: 0" })
local labelWishes = TabStats:createLabel({ Name = "✨ Wishes: 0" })
local labelTrophies = TabStats:createLabel({ Name = "🏆 Trophies Crafted: 0" })
local labelPotions = TabStats:createLabel({ Name = "🧪 Potions Used: 0" })
local labelUptime = TabStats:createLabel({ Name = "⏱️ Uptime: 00:00:00" })

TabStats:createButton({
    Name = "🔄 Reset Stats",
    Description = "Resets session counters.",
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
-- AUTO APPLY TROPHY — smart version
-- 1. Build a sorted list of plots by card EPS (best first)
-- 2. Build a sorted list of UNEQUIPPED trophies in inventory (best first)
-- 3. For each plot (best → worst):
--    a. If plot has no trophy → apply best unequipped trophy that's better than nothing
--    b. If plot already has a trophy → compare its tier to the best inventory trophy.
--       If inventory has something better → DestroyTrophy(plot) then ApplyTrophy(better, plot)
--       Otherwise skip this plot and move on to the next.
local function trophyTier(trophyName)
    local source = (TrophyConfig and TrophyConfig.Trophies) or TrophyConfig or {}
    local cfg = source[trophyName]
    if type(cfg) ~= "table" then return 0 end
    return rarityOrder[cfg.Rarity] or 0
end

interval("AutoApplyTrophy", "AutoApplyTrophy", 20, function()
    if not remotes.ApplyTrophy then return end
    local data = getPlayerData()
    if not data then return end
    local trophies = data.trophies or {}
    local slots = data.slots or {}

    -- 1. Plots sorted by card EPS desc (we want BEST card to get BEST trophy)
    local plotList = {}
    for slotIndex, sd in pairs(slots) do
        if type(sd) == "table" and sd.card then
            local plot = tonumber(slotIndex) or slotIndex
            if type(plot) == "number" then
                local existingTrophy = sd.trophy or sd.trophyName or sd.appliedTrophy
                local existingName = nil
                if type(existingTrophy) == "table" then
                    existingName = existingTrophy.name or existingTrophy.id
                elseif type(existingTrophy) == "string" then
                    existingName = existingTrophy
                end
                table.insert(plotList, {
                    plot = plot,
                    inc = getCardScore(sd.card),
                    existingTrophy = existingName,
                    existingTier = existingName and trophyTier(existingName) or -1,
                })
            end
        end
    end
    table.sort(plotList, function(a, b) return a.inc > b.inc end)
    if #plotList == 0 then return end

    -- 2. Build available trophy list ONCE (sorted by tier desc).
    -- We use a "consumed" tracker by index instead of re-querying after each action.
    local available = {}
    for k, tr in pairs(trophies) do
        if type(tr) == "table" then
            local trName = tr.name or tr.id or (type(k) == "string" and k or nil)
            local equipped = tr.equipped or tr.equippedTo or tr.plot
            if trName and not equipped then
                table.insert(available, { name = trName, tier = trophyTier(trName), used = false })
            end
        end
    end
    table.sort(available, function(a, b) return a.tier > b.tier end)
    if #available == 0 then return end

    -- 3. Walk plots; for each, take next-best unused trophy if it's an UPGRADE
    local cap = 6  -- max upgrades per tick to keep CPU light
    local done = 0
    for _, plotEntry in ipairs(plotList) do
        if done >= cap then break end

        -- find best unused trophy
        local bestIdx, best = nil, nil
        for i, t in ipairs(available) do
            if not t.used then bestIdx, best = i, t break end
        end
        if not best then break end

        if best.tier > plotEntry.existingTier then
            if plotEntry.existingTrophy and remotes.DestroyTrophy then
                fireRemote(remotes.DestroyTrophy, plotEntry.plot)
                task.wait(0.2)
            end
            if fireRemote(remotes.ApplyTrophy, best.name, plotEntry.plot) then
                stats.trophiesApplied += 1
                available[bestIdx].used = true
                done += 1
                task.wait(0.2)
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

-- Returns a list of currently equipped cards as { {name, rarity, mutations}, ... }
local function getEquippedCardsList()
    local cards = CardConfig and CardConfig.Cards or {}
    local out = {}
    for slotIndex, sd in pairs(getSlots()) do
        if type(sd) == "table" and type(sd.card) == "table" and sd.card.id then
            local cfg = cards[sd.card.id]
            local muts = getCardMutations(sd.card)
            table.insert(out, {
                slot = tonumber(slotIndex) or slotIndex,
                id = sd.card.id,
                name = (cfg and cfg.DisplayName) or sd.card.id,
                rarity = (cfg and cfg.Rarity) or "?",
                income = (cfg and tonumber(cfg.IncomeRate)) or 0,
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
        if c.mutationCount > 0 then
            mutText = " 🧬x" .. c.mutationCount
        end
        table.insert(lines, string.format("`#%s` ⚽ **%s** • _%s_ • 💵 $%s/s%s",
            tostring(c.slot), c.name, c.rarity, formatCash(c.income), mutText))
    end
    return table.concat(lines, "\n")
end

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
                { name = "📦 Packs Opened", value = formatCash(stats.opened), inline = true },
                { name = "🛒 Packs Bought", value = formatCash(stats.bought), inline = true },
                { name = "💸 Cards Sold",   value = formatCash(stats.sold),   inline = true },
                { name = "🔄 Rebirths",     value = tostring(stats.rebirths), inline = true },
                { name = "💎 Gem Buys",     value = tostring(stats.gemBuys),  inline = true },
                { name = "✨ Wishes",       value = tostring(stats.wishes or 0), inline = true },
                { name = "🏆 Trophies",     value = tostring(stats.trophiesCrafted or 0), inline = true },
                { name = "🧪 Potions",      value = tostring(stats.potionsUsed or 0), inline = true },
                { name = "🥇 Tournaments",  value = tostring(stats.tournamentJoins or 0), inline = true },
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

interval("SSC_GuiSuppressor", function()
    return Library.Flags["DisablePopups"] == true or Library.Flags["DisableNotifs"] == true
end, 1, function()
    local playerGui = client:FindFirstChild("PlayerGui")
    if not playerGui then return end

    if Library.Flags["DisablePopups"] then
        for _, promptName in ipairs({ "RebirthPrompt", "OfflineRewardPrompt", "BoothPurchasePrompt" }) do
            local promptGui = playerGui:FindFirstChild(promptName)
            if promptGui and promptGui:IsA("ScreenGui") then
                promptGui.Enabled = false
            end
        end
    end

    if Library.Flags["DisableNotifs"] then
        local notifGui = playerGui:FindFirstChild("Notification")
        if notifGui and notifGui:IsA("ScreenGui") then
            notifGui.Enabled = false
            local mainFrame = notifGui:FindFirstChild("Main")
            if mainFrame then
                for childIndex, child in ipairs(mainFrame:GetChildren()) do
                    if childIndex % 20 == 0 then
                        task.wait()
                    end

                    local isPlaceholder = child.Name == "Placeholder" or child.Name == "PlaceholderAnnouncement"
                    if child:IsA("Frame") and not isPlaceholder then
                        child.Visible = false
                    end
                end
            end
        end
    end
end, { persistent = true })

local function formatDuration(secs)
    secs = math.max(0, math.floor(secs))
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

interval("SSC_StatsUIUpdate", nil, 2, function()
    pcall(function()
        local playerData = getPlayerData() or {}
        local cash = tonumber(playerData.cash) or 0
        local gems = tonumber(playerData.gems) or 0
        local rebirth = tonumber(playerData.rebirth) or 0
        local uptime = os.time() - (stats.sessionStart or os.time())

        if labelCash and labelCash.Set then labelCash:Set("💰 Cash: $" .. formatCash(cash)) end
        if labelGems and labelGems.Set then labelGems:Set("💎 Gems: " .. math.floor(gems)) end
        if labelRebirth and labelRebirth.Set then labelRebirth:Set("🌟 Rebirth Level: " .. rebirth) end
        if labelOpened and labelOpened.Set then labelOpened:Set("📦 Packs Opened: " .. stats.opened) end
        if labelBought and labelBought.Set then labelBought:Set("🛒 Packs Bought: " .. stats.bought) end
        if labelSold and labelSold.Set then labelSold:Set("💸 Cards Sold: " .. stats.sold) end
        if labelCollects and labelCollects.Set then labelCollects:Set("💵 Collects: " .. stats.collects) end
        if labelGemBuys and labelGemBuys.Set then labelGemBuys:Set("💎 Gem Buys: " .. stats.gemBuys) end
        if labelSessionRebirths and labelSessionRebirths.Set then labelSessionRebirths:Set("🔄 Session Rebirths: " .. stats.rebirths) end
        if labelWishes and labelWishes.Set then labelWishes:Set("✨ Wishes: " .. (stats.wishes or 0)) end
        if labelTrophies and labelTrophies.Set then labelTrophies:Set("🏆 Trophies Crafted: " .. (stats.trophiesCrafted or 0)) end
        if labelPotions and labelPotions.Set then labelPotions:Set("🧪 Potions Used: " .. (stats.potionsUsed or 0)) end
        if labelUptime and labelUptime.Set then labelUptime:Set("⏱️ Uptime: " .. formatDuration(uptime)) end

        local tStatus = getTournamentStatus()
        local statusEmoji = tournamentState.inTournament and "🟢 in tournament"
            or (tStatus.isOpen and "🟡 open — joinable" or "⚪ idle")
        if labelTourneyState and labelTourneyState.Set then
            labelTourneyState:Set("Status: " .. statusEmoji)
        end
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
