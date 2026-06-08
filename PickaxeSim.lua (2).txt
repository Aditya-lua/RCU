--==============================================================================
--   PICKAXE SIMULATOR  ::  All-In-One   |   Versus UI   |   v3 (template-aligned)
--   Game: Pickaxe Simulator (PlaceId 82013336390273)
--
--   100% UPDATE-PROOF — every list (eggs/upgrades/enchants/plants/pickaxes/
--   auras/tags/chests/worlds/potions/merchant items/training stones) is read
--   at runtime from RS.Tables.* and RS.Stats.<player>.*
--==============================================================================

--------------------------------------------------------------------------------
-- Standard services (per the template)
--------------------------------------------------------------------------------
local request = (syn and syn.request) or (http and http.request) or http_request
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LightingService  = game:GetService("Lighting")
local VirtualUser      = game:GetService("VirtualUser")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local MarketplaceService=game:GetService("MarketplaceService")
local CollectionService= game:GetService("CollectionService")
local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local Camera           = Workspace.Camera

local client = Players.LocalPlayer

--------------------------------------------------------------------------------
-- Load UI
--------------------------------------------------------------------------------
print("[Pickaxe Sim] Loading Versus Lib…")
local Library = loadstring(game:HttpGet("https://versusairlines.top/scripts/NewLibrary.lua"))()
local Setup = Library:Setup({
    Location = CoreGui,
    OpenCloseLocation = "Top Center",
})

-- Anti-idle
client.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

--==============================================================================
-- Template helpers (interval + notify)
--==============================================================================
local function interval(tag, flag, delayTime, callback)
    Library:CleanupConnectionsByTag(tag)
    delayTime = math.max(tonumber(delayTime) or 0.1, 0.05)
    if not Library.Flags[flag] then return end

    local last = 0
    local running = false
    local slowWarnAt = 0
    local conn = RunService.Heartbeat:Connect(function()
        if not Library.Flags[flag] then
            Library:CleanupConnectionsByTag(tag)
            return
        end
        local current = os.clock()
        if running or current - last < delayTime then return end
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
                warn(string.format("[Versus] slow interval %s took %.3fs", tostring(tag), elapsed))
            end
            task.wait()
            running = false
        end)
    end)
    Library:TrackConnection(conn, tag)
end

local function notify(title, desc, style)
    Library:createDisplayMessage(title, desc, { { text = "OK" } }, style or "info")
end

--==============================================================================
-- Networking shim
--==============================================================================
local PaperRemotes = ReplicatedStorage:WaitForChild("Paper"):WaitForChild("Remotes")
local RE_event     = PaperRemotes:WaitForChild("__remoteevent")
local RF_function  = PaperRemotes:WaitForChild("__remotefunction")

local function fire(keyword, ...)
    return RE_event:FireServer(keyword, ...)
end

local function invoke(keyword, ...)
    local args = table.pack(...)
    local ok, a, b, c = pcall(function()
        return RF_function:InvokeServer(keyword, table.unpack(args, 1, args.n))
    end)
    if not ok then return false, nil, tostring(a) end
    return a, b, c
end

--==============================================================================
-- Update-proof game-table readers
--==============================================================================
local Tables = ReplicatedStorage:WaitForChild("Tables")

local function safeRequire(name)
    local mod = Tables:FindFirstChild(name)
    if not mod then return {} end
    local ok, val = pcall(require, mod)
    if not ok or type(val) ~= "table" then return {} end
    return val
end

local function sortedKeys(tbl, orderField)
    local keys = {}
    for k in pairs(tbl) do table.insert(keys, k) end
    if orderField then
        table.sort(keys, function(a, b)
            local oa = (type(tbl[a]) == "table" and tbl[a][orderField]) or math.huge
            local ob = (type(tbl[b]) == "table" and tbl[b][orderField]) or math.huge
            if oa == ob then return tostring(a) < tostring(b) end
            return oa < ob
        end)
    else
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    end
    return keys
end

local function filterKeys(tbl, predicate)
    local out = {}
    for k, v in pairs(tbl) do
        if predicate(k, v) then table.insert(out, k) end
    end
    table.sort(out)
    return out
end

local function getEggList()       return sortedKeys(safeRequire("Eggs")) end
local function getEnchantList(withNone)
    local list = sortedKeys(safeRequire("PickaxeEnchants"), "Order")
    if withNone then table.insert(list, 1, "(none)") end
    return list
end
local function getUpgradeList()
    return filterKeys(safeRequire("Upgrades"),
        function(_, v) return type(v) == "table" and v.StatName ~= nil end)
end
local function getPlantList()
    return filterKeys(safeRequire("Farm"),
        function(_, v) return type(v) == "table" end)
end
local function getAuraList()    return sortedKeys(safeRequire("Auras"), "Order") end
local function getTagList()     return sortedKeys(safeRequire("Tags"), "Order") end
local function getPickaxeList() return sortedKeys(safeRequire("Pickaxes"), "Order") end
local function getChestList()   return sortedKeys(safeRequire("Chests")) end

local function getWorldList()
    local t = safeRequire("Worlds")
    local indexed = {}
    for k, v in pairs(t) do
        if type(k) == "number" and type(v) == "table" and v.WorldName then
            table.insert(indexed, { idx = k, name = v.WorldName })
        end
    end
    table.sort(indexed, function(a, b) return a.idx < b.idx end)
    local names, idxMap = {}, {}
    for _, e in ipairs(indexed) do
        table.insert(names, e.name)
        idxMap[e.name] = e.idx
    end
    return names, idxMap
end

local function getItemsBy(field, value)
    local t = safeRequire("Items")
    return filterKeys(t, function(_, v) return type(v) == "table" and v[field] == value end)
end
local function getPotionList() return getItemsBy("Type", "Potion") end

local function getTrainingTable() return safeRequire("Training") end

--==============================================================================
-- Stats helpers
--==============================================================================
local StatsFolder = ReplicatedStorage:WaitForChild("Stats")

local function getStatInstance(name)
    local plrFolder = StatsFolder:FindFirstChild(client.Name)
    if not plrFolder then return nil end
    local direct = plrFolder:FindFirstChild(name)
    if direct then return direct end
    for _, sub in ipairs(plrFolder:GetChildren()) do
        if sub:IsA("Folder") then
            local f = sub:FindFirstChild(name)
            if f then return f end
        end
    end
end
local function getStat(name, default)
    local i = getStatInstance(name)
    if not i then return default end
    return i.Value
end
local function getJsonStat(name, default)
    local raw = getStat(name, nil)
    if not raw or raw == "" then return default end
    local ok, v = pcall(HttpService.JSONDecode, HttpService, raw)
    return ok and v or default
end

local function getChar()
    return client.Character or client.CharacterAdded:Wait()
end

--==============================================================================
-- ⛏️ MINING (packet protocol)
--==============================================================================
local Packet = {}
Packet.__index = Packet
function Packet:LogHit(d, hp) self.Ores[d] = hp end
function Packet:Send()
    local count = 0
    for _ in pairs(self.Ores) do count = count + 1 end
    if count == 0 then return end
    local list = {}
    for d, hp in pairs(self.Ores) do table.insert(list, { d, hp }) end
    table.sort(list, function(a, b) return a[1] < b[1] end)
    local buf = buffer.create(1 + count * 10)
    buffer.writeu8(buf, 0, count)
    local off = 1
    for _, p in ipairs(list) do
        buffer.writeu16(buf, off, p[1]); off = off + 2
        buffer.writef64(buf, off, p[2]); off = off + 8
    end
    self.Ores = {}
    fire("Mine", "MP", buf)
end
local function newPacket() return setmetatable({ Ores = {} }, Packet) end

local AutoMine = { packet = newPacket(), lastFlush = 0 }

local function getCurrentDepth()
    local hrp = client.Character and client.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return math.floor(-(hrp.Position.Y - 3) / 25) + 1
end

local function doMaxMine()
    local depth = getCurrentDepth()
    if not depth or depth < 1 or depth > 1000 then return end
    AutoMine.packet:LogHit(depth, 0)
    local power = getStat("Power", 1) or 1
    local burst = math.clamp(math.floor(power / 50), 0, 25)
    for i = 1, burst do
        local d = depth + i
        if d <= 1000 then AutoMine.packet:LogHit(d, 0) end
    end
    if os.clock() - AutoMine.lastFlush >= 0.05 then
        AutoMine.packet:Send()
        AutoMine.lastFlush = os.clock()
    end
end
local function doSafeMine()
    local depth = getCurrentDepth()
    if not depth or depth < 1 or depth > 1000 then return end
    AutoMine.packet:LogHit(depth, 0)
    AutoMine.packet:Send()
end

--==============================================================================
-- ✨ ENCHANT
--==============================================================================
local function getEnchantSlots()
    local data = getJsonStat("PickaxeEnchants", {}) or {}
    local equipped = getStat("EquippedPickaxe", "")
    local pe = data[equipped] or {}
    return { pe[1] or pe["1"], pe[2] or pe["2"], pe[3] or pe["3"] }
end

local function getLockMask()
    local i = getStatInstance("LockedPickaxeEnchants")
    if not i then return 0 end
    local equipped = getStat("EquippedPickaxe", "")
    local v = i.Value
    if type(v) == "table" then return v[equipped] or 0 end
    return i:GetAttribute(equipped) or 0
end

local function isSlotLocked(slot)
    return bit32.btest(getLockMask(), bit32.lshift(1, slot - 1))
end
local function setSlotLockTo(slot, wantLocked)
    if isSlotLocked(slot) ~= wantLocked then
        fire("Lock Pickaxe Enchant", slot)
        task.wait(0.05)
    end
end

local lastEnchWarn = 0
local function autoEnchantTick()
    local t = {
        Library.Flags["EnchSlot1Target"],
        Library.Flags["EnchSlot2Target"],
        Library.Flags["EnchSlot3Target"],
    }
    local cur = getEnchantSlots()
    local done = { false, false, false }
    for i = 1, 3 do
        if (not t[i]) or t[i] == "(none)" or cur[i] == t[i] then done[i] = true end
    end
    if done[1] and done[2] and done[3] then return end
    for s = 1, 3 do
        local matched = t[s] and t[s] ~= "(none)" and cur[s] == t[s]
        setSlotLockTo(s, matched and true or false)
    end
    local ok, success, payload = invoke("Enchant Pickaxe")
    if not ok or not success then
        if type(payload) == "string" and (os.clock() - lastEnchWarn) > 5 then
            lastEnchWarn = os.clock()
            warn("[Auto Enchant]", payload)
        end
    end
end

--==============================================================================
-- 🥚 EGGS
--==============================================================================
local function findEggSpawner(eggName)
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d.Name == eggName and (d:IsA("Model") or d:IsA("BasePart")) then
            return d
        end
    end
end

local function doAutoHatch()
    local egg = Library.Flags["AutoHatchEgg"]
    if not egg or egg == "" then return end
    local count = tonumber(Library.Flags["AutoHatchCount"]) or 1
    if Library.Flags["AutoHatchTP"] then
        local m = findEggSpawner(egg)
        if m then
            local pivot = m:IsA("Model") and m:GetPivot() or CFrame.new(m.Position)
            local c = getChar()
            if c then c:PivotTo(pivot * CFrame.new(0, 5, 0)) end
            task.wait(0.05)
        end
    end
    invoke("Hatch Egg", egg, count)
end

--==============================================================================
-- 🎁 CLAIMS
--==============================================================================
local function doClaimSelectedChests()
    local list = Library.Flags["ClaimChestList"] or {}
    for chest, on in pairs(list) do
        if on then invoke("Claim Chest", chest); task.wait(0.1) end
    end
end
local function doClaimDaily() invoke("Claim Daily") end
local function doClaimTimeReward() invoke("Claim Time Reward") end
local function doClaimIndex() invoke("Claim Index Reward") end
local function doClaimDrill() fire("Claim Drill") end
local function doClaimLuckyBlocks()
    local area
    pcall(function()
        area = Workspace.Worlds.Spawn:FindFirstChild("LuckyBlocks")
        area = area and area:FindFirstChild("Area")
    end)
    if not area then
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d.Name == "LuckyBlock" or (d:IsA("Model") and d:GetAttribute("LuckyBlock")) then
                invoke("Claim LuckyBlock", d.Name)
            end
        end
        return
    end
    for _, d in ipairs(area:GetChildren()) do
        if d:IsA("Model") or d:IsA("BasePart") then
            invoke("Claim LuckyBlock", d.Name)
        end
    end
end
local function doClaimAchievements()
    local ach = safeRequire("Achievements")
    for category, _ in pairs(ach) do
        for idx = 1, 50 do
            local ok = invoke("Claim Achievement", category, idx)
            if ok ~= true then break end
            task.wait(0.05)
        end
    end
end

--==============================================================================
-- 🐾 PETS
--==============================================================================
local function listMyPets()
    local folder = getStatInstance("Pets")
    if not folder then return {} end
    local out = {}
    for _, pet in ipairs(folder:GetChildren()) do
        table.insert(out, {
            name = pet.Name,
            petName = pet:GetAttribute("PetName"),
            tier = pet:GetAttribute("Tier") or 1,
            size = pet:GetAttribute("Size") or 1,
            locked = pet:GetAttribute("Locked") or false,
        })
    end
    return out
end

local function bucketPets(tierFilter)
    local buckets = {}
    for _, p in ipairs(listMyPets()) do
        if (not p.locked) and p.tier == tierFilter then
            local k = (p.petName or "?") .. "|s" .. tostring(p.size)
            buckets[k] = buckets[k] or {}
            table.insert(buckets[k], p.name)
        end
    end
    return buckets
end
local function doCraftGold()
    for _, names in pairs(bucketPets(1)) do
        if #names >= 3 then
            invoke("Pet", { Action = "CraftAllGolden", Pets = names })
            task.wait(0.1)
        end
    end
end
local function doCraftRainbow()
    for _, names in pairs(bucketPets(2)) do
        if #names >= 3 then
            invoke("Pet", { Action = "CraftAllRainbow", Pets = names })
            task.wait(0.1)
        end
    end
end
local function doCraftSize()
    local buckets = {}
    for _, p in ipairs(listMyPets()) do
        if (not p.locked) and (p.size or 1) < 4 then
            local k = (p.petName or "?").."|t"..tostring(p.tier).."|s"..tostring(p.size)
            buckets[k] = buckets[k] or {}
            table.insert(buckets[k], p)
        end
    end
    for _, group in pairs(buckets) do
        if #group >= 3 then
            invoke("Pet", { Action = "CraftSize", Pet = group[1].name })
            task.wait(0.1)
        end
    end
end
local function doDeleteJunk()
    local counts = {}
    for _, p in ipairs(listMyPets()) do
        if (not p.locked) and p.tier == 1 and p.size == 1 then
            counts[p.petName or "?"] = counts[p.petName or "?"] or {}
            table.insert(counts[p.petName or "?"], p.name)
        end
    end
    local toDelete = {}
    for _, names in pairs(counts) do
        for i = 4, #names do table.insert(toDelete, names[i]) end
    end
    if #toDelete > 0 then
        invoke("Pet", { Action = "Delete", Pets = toDelete })
    end
end
local function doEquipBest() invoke("Pet", { Action = "EquipBest" }) end
local function doUnequipAll() invoke("Pet", { Action = "UnequipAll" }) end

--==============================================================================
-- 🛒 MERCHANTS (live stock)
--==============================================================================
local function buyByItemName(data, itemName, key)
    for slot, entry in pairs(data) do
        if slot ~= "RestockOn" and type(entry) == "table" and entry.Item == itemName then
            if (entry.Stock or 0) > 0 then
                invoke(key, slot)
                task.wait(0.1)
            end
            return
        end
    end
end
local function doBuyMineMerchant()
    local picks = Library.Flags["MerchantPicks"] or {}
    local buyAll = Library.Flags["MerchantBuyAll"]
    if not buyAll and next(picks) == nil then return end
    local data = getJsonStat("MerchantData", {}) or {}
    if buyAll then
        for slot, entry in pairs(data) do
            if slot ~= "RestockOn" and type(entry) == "table" and (entry.Stock or 0) > 0 then
                invoke("Buy Merchant", slot); task.wait(0.1)
            end
        end
    else
        for itemName, on in pairs(picks) do
            if on then buyByItemName(data, itemName, "Buy Merchant") end
        end
    end
end
local function doBuyFarmMerchant()
    local picks = Library.Flags["FarmMerchantPicks"] or {}
    local buyAll = Library.Flags["FarmMerchantBuyAll"]
    if not buyAll and next(picks) == nil then return end
    local data = getJsonStat("FarmMerchantData", {}) or {}
    if buyAll then
        for slot, entry in pairs(data) do
            if slot ~= "RestockOn" and type(entry) == "table" and (entry.Stock or 0) > 0 then
                invoke("Buy Farm Merchant", slot); task.wait(0.1)
            end
        end
    else
        for itemName, on in pairs(picks) do
            if on then buyByItemName(data, itemName, "Buy Farm Merchant") end
        end
    end
end

--==============================================================================
-- 💎 SHRINE / 🚀 BOOST / ⬆️ UPGRADES / 💫 REBIRTH / 💪 TRAIN / 🌱 FARM
--==============================================================================
local function shrineMinimumCost()
    local lvl = getStat("ShrineLevel", 1) or 1
    return math.floor((lvl > 1) and (1000 * (1 + lvl / 2)) or (1000 * lvl))
end
local function doActivateShrine()
    local amt = math.max(tonumber(Library.Flags["ShrineAmount"]) or 0, shrineMinimumCost())
    if (getStat("Gems", 0) or 0) < amt then return end
    fire("Activate Shrine", amt)
end
local function doDonateShrine()
    local amt = tonumber(Library.Flags["ShrineDonateAmt"]) or 0
    if amt <= 0 or (getStat("Gems", 0) or 0) < amt then return end
    invoke("Donate Shrine", amt)
end

local function doServerBoost() invoke("TierUp ServerBoost") end

local function doAutoUpgrade()
    local picks = Library.Flags["UpgradePicks"] or {}
    for upgradeName, on in pairs(picks) do
        if on then invoke("Upgrade", upgradeName); task.wait(0.05) end
    end
end

local function doRebirth()
    invoke("Rebirth", tonumber(Library.Flags["RebirthAmount"]) or 1)
end

local function getHighestTrainingStone()
    local trainingFolder = Workspace:FindFirstChild("Training")
    if not trainingFolder then return nil end
    local power = getStat("Power", 0) or 0
    local rebirths = getStat("Rebirths", 0) or 0
    local worldsUnlocked = getStat("WorldsUnlocked", 1) or 1
    local TRAIN = getTrainingTable()
    for idx = #TRAIN, 1, -1 do
        local t = TRAIN[idx]
        local stoneObj = trainingFolder:FindFirstChild(tostring(idx))
        if t and stoneObj then
            local stoneWorld = stoneObj:GetAttribute("World") or 1
            if (power >= (t.Requirement or 0) or rebirths >= (t.Rebirths or 0))
               and worldsUnlocked >= stoneWorld then
                return idx
            end
        end
    end
end
local function doAutoTrainOP()
    local stone = getHighestTrainingStone()
    if not stone then return end
    fire("Stop Training")
    fire("Start Training", stone)
end
local function doAutoTrainSafe()
    local stone = getHighestTrainingStone()
    if not stone then return end
    if client:GetAttribute("TrainingStone") ~= stone then
        fire("Start Training", stone)
    end
end

local function doAutoPlant()
    local c = Library.Flags["PlantChoice"]
    if c and c ~= "" then invoke("Plant", c) end
end
local function doHarvestAll() fire("Harvest All") end
local function doSellAll() invoke("Sell All Ores") end
local function doRejoin() fire("Rejoin") end
local function doRedeemCode()
    local code = Library.Flags["CodeText"]
    if code and code ~= "" then invoke("Redeem Code", code) end
end

--==============================================================================
-- ============================  UI BUILD  ====================================
-- Every element creation wrapped in pcall so one bad field never crashes load.
--==============================================================================
local function safeCreate(section, method, args, label)
    local ok, err = pcall(function() return section[method](section, args) end)
    if not ok then
        warn(("[Pickaxe Sim] %s '%s' failed: %s"):format(method, label or args.Name or "?", err))
    end
end

local function Toggle(section, name, flagName, default, callback)
    safeCreate(section, "createToggle", {
        Name = name, flagName = flagName, Flag = default or false, Callback = callback,
    }, name)
end
local function Button(section, name, callback)
    safeCreate(section, "createButton", { Name = name, Callback = callback }, name)
end
local function Label(section, name, special)
    safeCreate(section, "createLabel", { Name = name, Special = special, TransparentBackground = not special }, name)
end
local function Slider(section, name, flagName, lo, hi, def)
    safeCreate(section, "createSlider", {
        Name = name, flagName = flagName,
        minValue = lo, maxValue = hi, value = def,
    }, name)
end
local function Dropdown(section, name, flagName, list, default, callback)
    safeCreate(section, "createDropdown", {
        Name = name, flagName = flagName, List = list, Flag = default, Callback = callback,
    }, name)
end
local function InputBox(section, name, flagName, default, callback)
    safeCreate(section, "createInputBox", {
        Name = name, flagName = flagName, Flag = default or "", Callback = callback,
    }, name)
end

--------------------------------------------------------------------------------
-- Sections
--------------------------------------------------------------------------------
local Mining   = Setup:CreateSection("⛏️ Mining")
local Enchant  = Setup:CreateSection("✨ Enchanting")
local EggsSec  = Setup:CreateSection("🥚 Eggs")
local PetsSec  = Setup:CreateSection("🐾 Pets")
local Claims   = Setup:CreateSection("🎁 Auto-Claim")
local FarmSec  = Setup:CreateSection("🌱 Farm")
local MerchSec = Setup:CreateSection("🛒 Merchants")
local Shrine   = Setup:CreateSection("💎 Gem Shrine")
local Boost    = Setup:CreateSection("🚀 Server Boost")
local TrainSec = Setup:CreateSection("💪 Training")
local UpSec    = Setup:CreateSection("⬆️ Upgrades / Rebirth")
local EquipSec = Setup:CreateSection("⚔️ Equip / World")
local Misc     = Setup:CreateSection("🧰 Misc / Server")

--------------------------------------------------------------------------------
-- Startup warning
--------------------------------------------------------------------------------
task.delay(0.5, function()
    notify(
        "⚠️ Pickaxe Sim — Important Setup",
        "Turn OFF the game's built-in auto toggles before using this script:\n\n"..
        "   • Auto Mine\n   • Auto Train\n   • Auto Hatch\n   • Auto Rebirth\n\n"..
        "This script drives the same remotes directly. If the in-game toggles are "..
        "left ON, the game will fight against the script — wasting gems on doubled "..
        "rolls, skipping hatches, mis-mounting training stones.\n\n"..
        "All dropdowns are auto-built from live game data, so the script keeps "..
        "working through future updates.",
        "warning"
    )
end)

--------------------------------------------------------------------------------
-- ⛏️ MINING
--------------------------------------------------------------------------------
Label(Mining, "Auto Mine", true)

Dropdown(Mining, "Mining Mode", "MiningMode",
    { "Max Speed (packet spam)", "Balanced (~10/sec)" },
    "Max Speed (packet spam)")

Toggle(Mining, "Auto Mine", "AutoMine", false, function(on)
    if on then
        interval("AutoMine", "AutoMine", 0.05, function()
            if Library.Flags["MiningMode"] == "Balanced (~10/sec)" then
                doSafeMine()
            else
                doMaxMine()
            end
        end)
        interval("AutoMineChunk", "AutoMine", 5, function() fire("Mine", "Chunk") end)
    else
        Library:CleanupConnectionsByTag("AutoMine")
        Library:CleanupConnectionsByTag("AutoMineChunk")
    end
end)

Toggle(Mining, "Auto Sell All Ores (every 30s)", "AutoSell", false, function(on)
    if on then interval("AutoSell", "AutoSell", 30, doSellAll)
    else Library:CleanupConnectionsByTag("AutoSell") end
end)

Button(Mining, "🚚 Sell All Now", doSellAll)
Button(Mining, "🔄 Buy Mine-Reset Upgrade", function() invoke("Buy MineReset Upgrade") end)

--------------------------------------------------------------------------------
-- ✨ ENCHANT
--------------------------------------------------------------------------------
Label(Enchant, "Per-slot Enchant Targets", true)
Label(Enchant, "Pick an enchant for each slot. Slots matching their target are locked between rolls; the rest re-roll. You can target the SAME enchant in multiple slots.", false)

local enchOpts = getEnchantList(true)
Dropdown(Enchant, "Slot 1 Target", "EnchSlot1Target", enchOpts, "(none)")
Dropdown(Enchant, "Slot 2 Target", "EnchSlot2Target", enchOpts, "(none)")
Dropdown(Enchant, "Slot 3 Target", "EnchSlot3Target", enchOpts, "(none)")

Toggle(Enchant, "Auto Enchant (until all targets met)", "AutoEnch", false, function(on)
    if on then interval("AutoEnch", "AutoEnch", 0.3, autoEnchantTick)
    else Library:CleanupConnectionsByTag("AutoEnch") end
end)

Button(Enchant, "🎲 Roll Once", function() invoke("Enchant Pickaxe") end)
Button(Enchant, "🔒 Toggle Lock — Slot 1", function() fire("Lock Pickaxe Enchant", 1) end)
Button(Enchant, "🔒 Toggle Lock — Slot 2", function() fire("Lock Pickaxe Enchant", 2) end)
Button(Enchant, "🔒 Toggle Lock — Slot 3", function() fire("Lock Pickaxe Enchant", 3) end)

--------------------------------------------------------------------------------
-- 🥚 EGGS
--------------------------------------------------------------------------------
Label(EggsSec, "Auto Hatch", true)

local eggList = getEggList()
Dropdown(EggsSec, "Egg to Hatch", "AutoHatchEgg", eggList, eggList[1] or "Basic Egg")
Slider(EggsSec, "Eggs per Hatch", "AutoHatchCount", 1, 8, 1)
Toggle(EggsSec, "Teleport to Egg first (bypass range check)", "AutoHatchTP", true)
Toggle(EggsSec, "Auto Hatch", "AutoHatch", false, function(on)
    if on then interval("AutoHatch", "AutoHatch", 1.0, doAutoHatch)
    else Library:CleanupConnectionsByTag("AutoHatch") end
end)
Button(EggsSec, "🥚 Hatch Once", doAutoHatch)

--------------------------------------------------------------------------------
-- 🐾 PETS
--------------------------------------------------------------------------------
Label(PetsSec, "Auto Craft & Maintain", true)

Toggle(PetsSec, "Auto Craft Golden (every 10s)", "AutoGold", false, function(on)
    if on then interval("AutoGold", "AutoGold", 10, doCraftGold)
    else Library:CleanupConnectionsByTag("AutoGold") end
end)
Toggle(PetsSec, "Auto Craft Rainbow (every 10s)", "AutoRainbow", false, function(on)
    if on then interval("AutoRainbow", "AutoRainbow", 10, doCraftRainbow)
    else Library:CleanupConnectionsByTag("AutoRainbow") end
end)
Toggle(PetsSec, "Auto Craft Size (Baby→Giga, every 10s)", "AutoSize", false, function(on)
    if on then interval("AutoSize", "AutoSize", 10, doCraftSize)
    else Library:CleanupConnectionsByTag("AutoSize") end
end)
Toggle(PetsSec, "Auto Delete Junk (keep 3 of each)", "AutoDelJunk", false, function(on)
    if on then interval("AutoDelJunk", "AutoDelJunk", 30, doDeleteJunk)
    else Library:CleanupConnectionsByTag("AutoDelJunk") end
end)
Button(PetsSec, "🏆 Equip Best Pets", doEquipBest)
Button(PetsSec, "🚮 Unequip All Pets", doUnequipAll)

--------------------------------------------------------------------------------
-- 🎁 CLAIMS
--------------------------------------------------------------------------------
Label(Claims, "Chests (auto-claim every 60s when toggle below is on)", true)

Library.Flags.ClaimChestList = Library.Flags.ClaimChestList or {}
for _, chestName in ipairs(getChestList()) do
    Toggle(Claims, "Claim " .. chestName, "Claim_" .. chestName, false, function(on)
        Library.Flags.ClaimChestList[chestName] = on
    end)
end

Toggle(Claims, "▶ Auto-Claim Selected Chests (every 60s)", "AutoClaimChests", false, function(on)
    if on then interval("AutoClaimChests", "AutoClaimChests", 60, doClaimSelectedChests)
    else Library:CleanupConnectionsByTag("AutoClaimChests") end
end)

Label(Claims, "Rewards", true)
Toggle(Claims, "Auto Claim Daily Reward (calendar)", "AutoDaily", false, function(on)
    if on then interval("AutoDaily", "AutoDaily", 30, doClaimDaily)
    else Library:CleanupConnectionsByTag("AutoDaily") end
end)
Toggle(Claims, "Auto Claim Time Reward (free egg)", "AutoTimeReward", false, function(on)
    if on then interval("AutoTimeReward", "AutoTimeReward", 15, function()
        if (getStat("RewardTimer", 1) or 1) == 0 then doClaimTimeReward() end
    end)
    else Library:CleanupConnectionsByTag("AutoTimeReward") end
end)
Toggle(Claims, "Auto Claim Lucky Blocks", "AutoLB", false, function(on)
    if on then interval("AutoLB", "AutoLB", 20, doClaimLuckyBlocks)
    else Library:CleanupConnectionsByTag("AutoLB") end
end)
Toggle(Claims, "Auto Claim Drill Output", "AutoDrill", false, function(on)
    if on then interval("AutoDrill", "AutoDrill", 30, doClaimDrill)
    else Library:CleanupConnectionsByTag("AutoDrill") end
end)
Button(Claims, "🏆 Claim Index Reward", doClaimIndex)
Button(Claims, "📜 Claim ALL Achievements", doClaimAchievements)

--------------------------------------------------------------------------------
-- 🌱 FARM
--------------------------------------------------------------------------------
Label(FarmSec, "Plant & Harvest", true)

local plantList = getPlantList()
Dropdown(FarmSec, "Plant to Auto-Plant", "PlantChoice", plantList, plantList[1] or "Strawberry")

Toggle(FarmSec, "Auto Plant (every 2s)", "AutoPlant", false, function(on)
    if on then interval("AutoPlant", "AutoPlant", 2, doAutoPlant)
    else Library:CleanupConnectionsByTag("AutoPlant") end
end)
Toggle(FarmSec, "Auto Harvest All (every 5s, needs gamepass)", "AutoHarvest", false, function(on)
    if on then interval("AutoHarvest", "AutoHarvest", 5, doHarvestAll)
    else Library:CleanupConnectionsByTag("AutoHarvest") end
end)
Button(FarmSec, "⬆️ Upgrade Farm", function() invoke("Upgrade Farm") end)

--------------------------------------------------------------------------------
-- 🛒 MERCHANTS
--------------------------------------------------------------------------------
Label(MerchSec, "Mine Merchant", true)
Label(MerchSec, "Toggles cover EVERY item this merchant ever sells. Auto-buy scans your live stock and buys whichever toggled items are in stock right now.", false)

local merchantItems = filterKeys(safeRequire("Merchant"), function(_, v) return type(v) == "table" end)
Library.Flags.MerchantPicks = Library.Flags.MerchantPicks or {}
for _, item in ipairs(merchantItems) do
    Toggle(MerchSec, "Buy " .. item, "M_" .. item, false, function(on)
        Library.Flags.MerchantPicks[item] = on
    end)
end
Toggle(MerchSec, "🟢 BUY-ALL Mode (drain everything in stock)", "MerchantBuyAll", false)
Toggle(MerchSec, "▶ Auto Buy Mine Merchant (every 30s)", "AutoMerchant", false, function(on)
    if on then interval("AutoMerchant", "AutoMerchant", 30, doBuyMineMerchant)
    else Library:CleanupConnectionsByTag("AutoMerchant") end
end)
Button(MerchSec, "🛒 Buy Now", doBuyMineMerchant)

Label(MerchSec, "Farm Merchant", true)
local farmMerchantItems = filterKeys(safeRequire("FarmMerchant"), function(_, v) return type(v) == "table" end)
Library.Flags.FarmMerchantPicks = Library.Flags.FarmMerchantPicks or {}
for _, item in ipairs(farmMerchantItems) do
    Toggle(MerchSec, "Buy " .. item, "FM_" .. item, false, function(on)
        Library.Flags.FarmMerchantPicks[item] = on
    end)
end
Toggle(MerchSec, "🟢 BUY-ALL Mode (Farm)", "FarmMerchantBuyAll", false)
Toggle(MerchSec, "▶ Auto Buy Farm Merchant (every 30s)", "AutoFarmMerchant", false, function(on)
    if on then interval("AutoFarmMerchant", "AutoFarmMerchant", 30, doBuyFarmMerchant)
    else Library:CleanupConnectionsByTag("AutoFarmMerchant") end
end)
Button(MerchSec, "🛒 Farm Buy Now", doBuyFarmMerchant)

--------------------------------------------------------------------------------
-- 💎 SHRINE
--------------------------------------------------------------------------------
Label(Shrine, "Gem Shrine", true)
Label(Shrine, "Min cost = floor((lvl>1 ? 1000·(1+lvl/2) : 1000·lvl)). Slider auto-clamps to that minimum.", false)

Slider(Shrine, "Activate Amount (gems)", "ShrineAmount", 1000, 10000000, 1000)
Button(Shrine, "🔥 Activate Shrine Now", doActivateShrine)
Toggle(Shrine, "Auto Re-Activate (when expired)", "AutoShrine", false, function(on)
    if on then interval("AutoShrine", "AutoShrine", 60, function()
        if (getStat("ShrineActive", 0) or 0) == 0 then doActivateShrine() end
    end)
    else Library:CleanupConnectionsByTag("AutoShrine") end
end)

Slider(Shrine, "Donate Amount (gems)", "ShrineDonateAmt", 1000, 10000000, 1000)
Button(Shrine, "🙏 Donate Now", doDonateShrine)
Toggle(Shrine, "Auto Donate (every 30s)", "AutoDonate", false, function(on)
    if on then interval("AutoDonate", "AutoDonate", 30, doDonateShrine)
    else Library:CleanupConnectionsByTag("AutoDonate") end
end)

--------------------------------------------------------------------------------
-- 🚀 BOOST
--------------------------------------------------------------------------------
Label(Boost, "Server Boost", true)
Button(Boost, "⚡ Tier-Up Server Boost Now", doServerBoost)
Toggle(Boost, "Auto Tier-Up (every 60s)", "AutoBoost", false, function(on)
    if on then interval("AutoBoost", "AutoBoost", 60, doServerBoost)
    else Library:CleanupConnectionsByTag("AutoBoost") end
end)

--------------------------------------------------------------------------------
-- 💪 TRAINING
--------------------------------------------------------------------------------
Label(TrainSec, "Auto Train", true)
Label(TrainSec, "OP mode = Stop→Start spam on the highest unlocked stone (thousands of power/sec). Safe mode = mount best stone once.", false)

Dropdown(TrainSec, "Training Mode", "TrainMode",
    { "OP (Stop→Start spam)", "Safe (mount best stone)" },
    "OP (Stop→Start spam)")

Toggle(TrainSec, "Auto Train", "AutoTrain", false, function(on)
    if on then
        interval("AutoTrain", "AutoTrain", 0.1, function()
            if Library.Flags["TrainMode"] == "OP (Stop→Start spam)" then
                doAutoTrainOP()
            else
                doAutoTrainSafe()
            end
        end)
    else
        Library:CleanupConnectionsByTag("AutoTrain")
        fire("Stop Training")
    end
end)

--------------------------------------------------------------------------------
-- ⬆️ UPGRADES / REBIRTH
--------------------------------------------------------------------------------
Label(UpSec, "Auto Upgrade — pick which", true)
Library.Flags.UpgradePicks = Library.Flags.UpgradePicks or {}
for _, up in ipairs(getUpgradeList()) do
    Toggle(UpSec, "Buy '" .. up .. "'", "U_" .. up, false, function(on)
        Library.Flags.UpgradePicks[up] = on
    end)
end
Toggle(UpSec, "▶ Auto Buy Selected (every 10s)", "AutoUp", false, function(on)
    if on then interval("AutoUp", "AutoUp", 10, doAutoUpgrade)
    else Library:CleanupConnectionsByTag("AutoUp") end
end)
Button(UpSec, "🛒 Buy Selected Now", doAutoUpgrade)

Label(UpSec, "Rebirth", true)
Slider(UpSec, "Rebirths per Call", "RebirthAmount", 1, 1000, 1)
Button(UpSec, "💫 Rebirth Now", doRebirth)
Toggle(UpSec, "Auto Rebirth (every 10s)", "AutoRebirth", false, function(on)
    if on then interval("AutoRebirth", "AutoRebirth", 10, doRebirth)
    else Library:CleanupConnectionsByTag("AutoRebirth") end
end)

--------------------------------------------------------------------------------
-- ⚔️ EQUIP / WORLD
--------------------------------------------------------------------------------
Label(EquipSec, "Quick Equip", true)

local pickaxeList = getPickaxeList()
Dropdown(EquipSec, "Equip Pickaxe", "EquipPick", pickaxeList, pickaxeList[1] or "Wooden Pickaxe",
    function(name) invoke("Equip Pickaxe", name) end)

local auraList = getAuraList()
Dropdown(EquipSec, "Equip Aura", "EquipAura", auraList, auraList[1] or "Plasma",
    function(name) invoke("Equip Aura", name) end)

local tagList = getTagList()
Dropdown(EquipSec, "Equip Tag", "EquipTag", tagList, tagList[1] or "Newcomer",
    function(name) invoke("Equip Tag", name) end)

Label(EquipSec, "Worlds", true)
local worldNames, worldIdxMap = getWorldList()
Dropdown(EquipSec, "Set Current World", "SetWorld", worldNames, worldNames[2] or worldNames[1],
    function(name)
        local idx = worldIdxMap[name]
        if idx then invoke("Set Current World", idx) end
    end)
Button(EquipSec, "🌍 Unlock Next World", function() invoke("Unlock Next World") end)

Label(EquipSec, "Use Potions", true)
for _, pot in ipairs(getPotionList()) do
    Button(EquipSec, "Use 1× " .. pot, function() invoke("Use Item", pot, 1) end)
end

--------------------------------------------------------------------------------
-- 🧰 MISC
--------------------------------------------------------------------------------
Label(Misc, "Codes", true)
InputBox(Misc, "Code", "CodeText", "")
Button(Misc, "🎟️ Redeem Code", doRedeemCode)

Label(Misc, "Server", true)
Button(Misc, "♻️ Rejoin Server", doRejoin)
Button(Misc, "🌟 Mark Favorited (boost)", function() fire("Favorited The Game") end)

Label(Misc, "Live Stats (auto-refresh every 2s)", true)
local statsLabel
pcall(function()
    statsLabel = Misc:createLabel({ Name = "loading…", TransparentBackground = true })
end)
task.spawn(function()
    while task.wait(2) do
        local txt = string.format(
            "Coins: %s   Gems: %s   Tickets: %s\nPower: %s   Rebirths: %s   Shrine Lvl: %s\nWorld: %s   Reward Timer: %ss",
            tostring(getStat("Coins", 0)),
            tostring(getStat("Gems", 0)),
            tostring(getStat("Tickets", 0)),
            tostring(getStat("Power", 0)),
            tostring(getStat("Rebirths", 0)),
            tostring(getStat("ShrineLevel", 0)),
            tostring(getStat("CurrentWorld", "?")),
            tostring(getStat("RewardTimer", 0))
        )
        if statsLabel and statsLabel.Set then pcall(statsLabel.Set, statsLabel, txt) end
    end
end)

print(("[Pickaxe Sim v3] Loaded. %d eggs · %d upgrades · %d enchants · %d plants · %d pickaxes · %d auras · %d tags · %d chests · %d mine-items · %d farm-items"):format(
    #eggList, #getUpgradeList(), #enchOpts - 1, #plantList,
    #pickaxeList, #auraList, #tagList, #getChestList(),
    #merchantItems, #farmMerchantItems
))
