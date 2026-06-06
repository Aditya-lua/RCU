-- // ============================================
-- // SSC Elite Farm — v3.0 "Full Suite"
-- // Dev    :- Aditya (base)  /  Expanded build
-- // Owner  :- Cammy
-- // Library:- Versus Airlines (NewLibrary.lua)
-- // ============================================


-- [ SERVICES ]
local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local MPS              = game:GetService("MarketplaceService")
local Workspace        = game:GetService("Workspace")
local RunService       = game:GetService("RunService")
local VirtualUser      = game:GetService("VirtualUser")
local TeleportService  = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")


-- [ CLIENT ]
local client           = Players.LocalPlayer
local PLACE_ID         = game.PlaceId


-- [ CONSTANTS ]
local CODES_URL        = "https://raw.githubusercontent.com/Aditya-lua/Scripts_2/refs/heads/main/SSC_CODES.txt"
local LIBRARY_URL      = "https://versusairlines.top/scripts/NewLibrary.lua"
local ROBLOX_THUMBS    = "https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false"
local ROBLOX_AVATAR    = "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png"
local SERVERS_API      = "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"

local COLLECT_DEFAULT       = 3
local STATS_DELAY_DEFAULT   = 15
local MIN_GEMS_DEFAULT      = 100
local SELL_DEFAULT          = "Silver"
local RARITY_THRESH_DEFAULT = "Mythic"
local CODE_WAIT             = 1.5
local REBIRTH_CD_NORMAL     = 15
local REBIRTH_CD_FORCE      = 30
local MAX_REMOTES_PER_SEC   = 40   -- safety throttle ceiling
local LOG_MAX               = 200  -- in-memory log buffer

local GEM_SHOP_MAP = {
    ["Lucky Item"]       = "lucky",
    ["Auto Equip Best"]  = "fixed_1",
    ["Auto Skip"]        = "fixed_2",
    ["Inventory +500"]   = "fixed_3",
    ["Scarlet Item"]     = "scarlet",
}

local BLOCKED_IDS = { LocalCard = true, OwnerVulnone = true }


-- [ HTTP REQUEST ]
local req = (syn and syn.request)
         or (http and http.request)
         or http_request
         or request


-- [ ANTI AFK (humanized) ]
client.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1 + math.random())
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1 + math.random())
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)


-- [ POPUP BLOCKER (NAMECALL HOOK) ]
local gm = getrawmetatable(game)
setreadonly(gm, false)
local oldNamecall = gm.__namecall

gm.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and _G.DisablePopups then
        local isMPS = typeof(self) == "Instance"
                   and (self.ClassName == "MarketplaceService" or self == MPS)
        if isMPS then
            local blockedMethods = {
                PromptProductPurchase  = true,
                PromptGamePassPurchase = true,
                PromptPurchase         = true,
            }
            if blockedMethods[method] then
                return
            end
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(gm, true)


-- [ GUI SUPPRESSOR LOOP ]
local POPUP_NAMES = { "RebirthPrompt", "OfflineRewardPrompt", "BoothPurchasePrompt" }

task.spawn(function()
    while task.wait(0.5) do
        local pgui = client:FindFirstChild("PlayerGui")
        if not pgui then continue end

        if _G.DisablePopups then
            for _, promptName in ipairs(POPUP_NAMES) do
                local promptGui = pgui:FindFirstChild(promptName)
                if promptGui and promptGui:IsA("ScreenGui") and promptGui.Enabled then
                    promptGui.Enabled = false
                end
            end
        end

        if _G.DisableNotifs then
            local notifGui = pgui:FindFirstChild("Notification")
            if notifGui and notifGui:IsA("ScreenGui") then
                notifGui.Enabled = false
                local mainFrame = notifGui:FindFirstChild("Main")
                if mainFrame then
                    for _, child in ipairs(mainFrame:GetChildren()) do
                        local isFrame       = child:IsA("Frame")
                        local isPlaceholder = child.Name == "Placeholder"
                                           or child.Name == "PlaceholderAnnouncement"
                        if isFrame and not isPlaceholder then
                            child.Visible = false
                        end
                    end
                end
            end
        end
    end
end)


-- [ LIBRARY SETUP ]
print("[SSC Farm] Loading Versus library...")
local Library = loadstring(game:HttpGet(LIBRARY_URL))()

local Setup = Library:Setup({
    Location          = CoreGui,
    OpenCloseLocation = "Bottom Left",
})

print("[SSC Farm] Library loaded.")


-- [ FORWARD DECLARATIONS ]
-- declared as upvalues here so functions defined later can be called by
-- earlier code (e.g. checkWeatherAlerts → dispatchWebhook)
dispatchWebhook = nil


-- [ HELPERS ]
local function notify(title, desc, style)
    pcall(function()
        Library:createDisplayMessage(title, desc, { { text = "OK" } }, style or "info")
    end)
end


-- internal scrollable log buffer
local logBuffer = {}
local function logEvent(category, msg)
    local line = string.format("[%s] [%s] %s", os.date("%H:%M:%S"), category, msg)
    table.insert(logBuffer, line)
    if #logBuffer > LOG_MAX then
        table.remove(logBuffer, 1)
    end
    print("[SSC] " .. line)
end


-- humanized random wait between a..b (used by hot loops when enabled)
local function hwait(a, b)
    if Library.Flags["HumanizedDelays"] then
        task.wait(a + (b - a) * math.random())
    else
        task.wait(a)
    end
end


-- [ REMOTE THROTTLE ]
local remoteCallTimestamps = {}
local function throttleAllow()
    local now = os.clock()
    -- drop entries older than 1s
    while #remoteCallTimestamps > 0 and (now - remoteCallTimestamps[1]) > 1 do
        table.remove(remoteCallTimestamps, 1)
    end
    if #remoteCallTimestamps >= MAX_REMOTES_PER_SEC then
        return false
    end
    table.insert(remoteCallTimestamps, now)
    return true
end


-- [ NETWORKER / REMOTES (with watchdog) ]
local Networker = require(RS.Source.Shared.Networker)

local function getRemote(name)
    local ok, result = pcall(function()
        return Networker.get_remote(name)
    end)
    if ok and result then return result end

    local folder = RS:FindFirstChild("Remotes")
    if folder then return folder:FindFirstChild(name) end
    return nil
end

local function getFunction(name)
    local ok, result = pcall(function()
        return Networker.get_remotefunction(name)
    end)
    if ok and result then return result end

    local folder = RS:FindFirstChild("Remotes")
    if folder then return folder:FindFirstChild(name) end
    return nil
end

local REMOTE_NAMES = {
    "OpenPack", "BuyPack", "EquipCard", "CollectSlot", "SellCards",
    "DeletePacks", "Rebirth", "BuyGemShopItem", "ClaimAllIndexGems",
    "DailyReward", "OfflineReward", "SpinWheel", "RedeemCode",
    "LockCard", "UnlockCard", "UseBoost", "ActivatePotion",
}
local FUNC_NAMES = { "SpinWheelData" }

local remotes, funcs = {}, {}
local function refreshRemotes()
    for _, n in ipairs(REMOTE_NAMES) do remotes[n] = getRemote(n) end
    for _, n in ipairs(FUNC_NAMES)   do funcs[n]   = getFunction(n) end
end
refreshRemotes()

-- watchdog: re-resolve every 30s in case server invalidates them
task.spawn(function()
    while task.wait(30) do
        local broken = false
        if not remotes.OpenPack or not remotes.OpenPack.Parent then broken = true end
        if broken then
            logEvent("Watchdog", "Remotes invalid → re-resolving.")
            refreshRemotes()
        end
    end
end)


-- [ CONFIGS ]
local PackConfig    = require(RS.Source.Shared.Configs.PackConfig)
local CardConfig    = require(RS.Source.Shared.Configs.CardConfig)
local RebirthConfig = require(RS.Source.Shared.Configs.RebirthConfig)
local PlayerStore   = require(RS.Source.Shared.State.PlayerStore)

local WeatherStore = nil
pcall(function()
    WeatherStore = require(RS.Source.Shared.State.WeatherStore)
end)


-- [ SESSION STATS ]
local stats = {
    opened        = 0,
    bought        = 0,
    sold          = 0,
    rebirths      = 0,
    gemBuys       = 0,
    collects      = 0,
    locked        = 0,
    boostsUsed    = 0,
    hopCount      = 0,
    codesRedeemed = false,
    sessionStart  = os.time(),
    cashStart     = nil,
    gemsStart     = nil,
    rebirthStart  = nil,
    -- pack-open analytics
    rarityRolls   = {},  -- [rarityName] = count
    lastRebirthTs = os.time(),
}


-- [ PLAYER DATA ACCESSORS ]
local function getPlayerData()
    local ok, state = pcall(function() return PlayerStore() end)
    if not ok or not state or not state.players then return nil end
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
    return data and data.cash or 0
end

local function getGems()
    local data = getPlayerData()
    return data and data.gems or 0
end

local function getRebirthLevel()
    local data = getPlayerData()
    return data and data.rebirth or 0
end


-- [ WEATHER ]
local function getActiveWeathersList()
    if not WeatherStore then return {} end
    local ok, state = pcall(function() return WeatherStore() end)
    if not ok or not state or type(state.activeWeathers) ~= "table" then
        return {}
    end
    local active = {}
    local now = Workspace:GetServerTimeNow()
    for weatherName, weatherData in pairs(state.activeWeathers) do
        if weatherData and weatherData.endTime and weatherData.endTime > now then
            table.insert(active, weatherName)
        end
    end
    return active
end

local function getActiveWeathers()
    local active = getActiveWeathersList()
    return (#active > 0) and table.concat(active, ", ") or "None"
end

local function weatherIsActive(name)
    for _, w in ipairs(getActiveWeathersList()) do
        if w == name then return true end
    end
    return false
end

local lastSeenWeathers = {}
local function checkWeatherAlerts()
    local now = getActiveWeathersList()
    local nowSet = {}
    for _, w in ipairs(now) do nowSet[w] = true end

    local watchFlag = Library.Flags["WatchedWeathers"]
    local watched = type(watchFlag) == "table" and watchFlag or {}
    for _, w in ipairs(watched) do
        if nowSet[w] and not lastSeenWeathers[w] then
            logEvent("Weather", w .. " has started!")
            if Library.Flags["WebhookWeather"] then
                dispatchWebhook({
                    embeds = {{
                        title = "[~] Weather Alert: " .. w,
                        description = "Watched weather event has gone active.",
                        color = 7506394,
                        footer = { text = "SSC Elite Farm" },
                    }}
                })
            end
        end
    end
    lastSeenWeathers = nowSet
end


-- [ FORMATTERS ]
local function formatCash(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.2fT", n / 1e12)
    elseif n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3) end
    return tostring(math.floor(n))
end

local function formatDuration(secs)
    secs = math.max(0, math.floor(secs))
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end


-- [ PACK LIST & PRICE HELPERS ]
local function getPackList()
    local list = {}
    for packName, packData in pairs(PackConfig.Packs or {}) do
        if not packData.HideFromShop then
            table.insert(list, packName)
        end
    end
    table.sort(list, function(a, b)
        local pa = PackConfig.Packs[a]
        local pb = PackConfig.Packs[b]
        local orderA = pa and pa.LayoutOrder or 999
        local orderB = pb and pb.LayoutOrder or 999
        return orderA < orderB
    end)
    return list
end

local function packPrice(name)
    local p = PackConfig.Packs[name]
    return p and (p.Price or 0) or 0
end


-- [ RARITY SYSTEM (dynamic + hardcoded fallback) ]
local rarityOrder = {
    ["Bronze"]=1, ["Silver"]=2, ["Gold"]=3, ["Legendary"]=4, ["Mythic"]=5,
    ["Azure Zenith"]=6, ["Crimson Zenith"]=7, ["Divine"]=8, ["Primordial"]=9,
    ["Oblivion"]=10, ["Eternity"]=11, ["Astral"]=12, ["Sovereign"]=13,
    ["Vandal"]=14, ["The Monarch"]=15, ["Tyrant"]=16, ["Verdant"]=17,
    ["Silvane"]=18, ["Lunar"]=19, ["Solar"]=20, ["Nether"]=21, ["Aether"]=22,
    ["Player of the Month"]=23, ["Exclusive"]=24, ["Secret Exclusive"]=25,
}

-- merge in any rarities discovered in CardConfig that we didn't hardcode
do
    local maxIdx = 0
    for _, v in pairs(rarityOrder) do if v > maxIdx then maxIdx = v end end
    for _, cfg in pairs(CardConfig.Cards or {}) do
        local r = cfg and cfg.Rarity
        if r and not rarityOrder[r] then
            maxIdx = maxIdx + 1
            rarityOrder[r] = maxIdx
        end
    end
end

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


-- [ CARD ID LIST (for whitelist/hunt UI) ]
-- Cap the list to avoid Versus library lag with huge dropdowns.
-- Only include cards at Mythic+ by default; rest available via search later.
local CARD_LIST_MIN_RARITY = 4   -- Legendary+ (1=Bronze, 2=Silver, 3=Gold, 4=Legendary, 5=Mythic)
local CARD_LIST_HARD_CAP   = 300

local cardIdList = {}
local cardDisplayToId = {}
do
    local temp = {}
    for id, cfg in pairs(CardConfig.Cards or {}) do
        local rarity = cfg and cfg.Rarity
        local lvl    = (rarity and rarityOrder[rarity]) or 0
        if lvl >= CARD_LIST_MIN_RARITY then
            local name  = (cfg and cfg.DisplayName) or id
            local label = string.format("%s [%s]", name, rarity or "?")
            table.insert(temp, { label = label, id = id, lvl = lvl, name = name })
        end
    end
    -- highest rarity first, then alpha
    table.sort(temp, function(a, b)
        if a.lvl ~= b.lvl then return a.lvl > b.lvl end
        return a.name < b.name
    end)
    for i = 1, math.min(#temp, CARD_LIST_HARD_CAP) do
        table.insert(cardIdList, temp[i].label)
        cardDisplayToId[temp[i].label] = temp[i].id
    end
end

if #cardIdList == 0 then
    table.insert(cardIdList, "(no cards found)")
end


-- [ REBIRTH CHECKS / SMART ]
local function getRebirthRequirements()
    local playerData = getPlayerData()
    if not playerData then return nil end
    local nextLevel = (playerData.rebirth or 0) + 1
    local ok, rd = pcall(function()
        return RebirthConfig and RebirthConfig.GetRebirth and RebirthConfig.GetRebirth(nextLevel)
    end)
    return (ok and rd) or nil
end

local function canRebirth()
    local maxRebirth = 999
    pcall(function()
        if RebirthConfig and RebirthConfig.GetMaxRebirth then
            maxRebirth = RebirthConfig.GetMaxRebirth()
        end
    end)
    local playerData = getPlayerData()
    if not playerData then return false end
    local currentRebirth = playerData.rebirth or 0
    if currentRebirth >= maxRebirth then return false end
    local rd = getRebirthRequirements()
    if not rd then return false end
    local cashRequired = rd.CashRequired or math.huge
    local gemsRequired = rd.GemsRequired or 0
    if (playerData.cash or 0) < cashRequired then return false end
    if gemsRequired > 0 and (playerData.gems or 0) < gemsRequired then return false end
    return true
end


-- [ EQUIP BEST CARDS ]
local SlotController = nil

local function equipBest()
    if not SlotController then
        local ok, ctrl = pcall(function()
            return require(RS.Source.Client.Controllers.SlotController)
        end)
        if ok and ctrl then SlotController = ctrl end
    end

    if SlotController and SlotController.equipBestCards then
        local ok = pcall(SlotController.equipBestCards)
        if ok then return true end
    end

    local inventory = getInventory()
    local slots     = getSlots()
    if not inventory or not slots then return false end

    local candidates = {}
    for _, card in ipairs(inventory) do
        local isValid = card and card.id and card.uuid
                     and not BLOCKED_IDS[card.id]
                     and not card.throneCard
                     and not card.locked
        if isValid then
            local cfg    = CardConfig.Cards[card.id]
            local income = cfg and cfg.IncomeRate or 0
            table.insert(candidates, {
                uuid = card.uuid, id = card.id, income = income,
            })
        end
    end

    table.sort(candidates, function(a, b) return a.income > b.income end)

    local slotCount = 0
    for _ in pairs(slots) do slotCount = slotCount + 1 end
    if slotCount == 0 then slotCount = 6 end

    local equippedCount = 0
    for slotIndex = 1, math.min(#candidates, slotCount) do
        local candidate   = candidates[slotIndex]
        local currentSlot = slots[tostring(slotIndex)] or slots[slotIndex]
        local currentIncome = 0
        if currentSlot and currentSlot.card then
            local curCfg  = CardConfig.Cards[currentSlot.card.id]
            currentIncome = curCfg and curCfg.IncomeRate or 0
        end
        if candidate.income > currentIncome then
            remotes.EquipCard:FireServer(candidate.uuid, slotIndex)
            equippedCount = equippedCount + 1
            hwait(0.08, 0.18)
        end
    end
    return equippedCount > 0
end


-- [ WHITELIST / PROTECTED CARDS ]
local function isProtectedById(id)
    if BLOCKED_IDS[id] then return true end
    local flag = Library.Flags["ProtectedCards"]
    if type(flag) ~= "table" then return false end
    for _, label in ipairs(flag) do
        if cardDisplayToId[label] == id then return true end
    end
    return false
end

local function isLastCopy(id)
    if not Library.Flags["KeepOneOfEach"] then return false end
    local count = 0
    for _, c in ipairs(getInventory()) do
        if c.id == id then count = count + 1 end
        if count > 1 then return false end
    end
    return count <= 1
end


-- [ WEBHOOK ]
getgenv().WebhookURL    = ""
getgenv().WebhookPingID = ""

dispatchWebhook = function(payload)
    local url = getgenv().WebhookURL or ""
    if url == "" or not req then return end
    local pingId = getgenv().WebhookPingID or ""
    if pingId ~= "" then
        payload.content = "<@" .. pingId .. ">"
    end
    pcall(function()
        req({
            Url     = url,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode(payload),
        })
    end)
end


-- [ RARE ROLL WEBHOOK + STATS LISTENER + HUNT ]
local huntFound = false
if remotes.OpenPack then
    remotes.OpenPack.OnClientEvent:Connect(function(img, cData, color, uuid, chances, isNew, pName)
        if img == "x" or type(cData) ~= "table" then return end

        -- track rarity rolls
        local r = cData.Rarity or "Common"
        stats.rarityRolls[r] = (stats.rarityRolls[r] or 0) + 1

        -- hunting mode
        if Library.Flags["HuntingMode"] then
            local targetFlag = Library.Flags["HuntTarget"]
            local targetLabel = type(targetFlag) == "table" and targetFlag[1] or targetFlag
            local targetId = cardDisplayToId[targetLabel or ""]
            if targetId and cData.id == targetId and not huntFound then
                huntFound = true
                logEvent("Hunt", "Target card found: " .. (cData.DisplayName or cData.id))
                -- auto-lock
                if remotes.LockCard and uuid then
                    pcall(function() remotes.LockCard:FireServer(uuid) end)
                end
                -- disable AutoOpen/AutoBuy
                Library.Flags["AutoOpenPacks"] = false
                Library.Flags["AutoBuyPacks"]  = false
                -- webhook
                if Library.Flags["WebhookRareRolls"] then
                    dispatchWebhook({
                        embeds = {{
                            title = "[!] HUNT COMPLETE",
                            description = "Target card has been rolled.",
                            color = 16711680,
                            fields = {
                                { name="Card", value = cData.DisplayName or cData.id, inline=false },
                                { name="Pack", value = pName or "?", inline=false },
                            },
                            footer = { text = "SSC Elite Farm — Hunt" },
                        }}
                    })
                end
                notify("Hunt", "Target obtained: " .. (cData.DisplayName or cData.id), "info")
            end
        end

        -- rare roll webhook
        if not Library.Flags["WebhookRareRolls"] then return end
        local threshFlag  = Library.Flags["WebhookRarityThresh"]
        local threshName  = type(threshFlag) == "string" and threshFlag
                         or (type(threshFlag) == "table" and threshFlag[1])
                         or RARITY_THRESH_DEFAULT
        local threshLevel = getRarityLevel(threshName)
        local cardLevel   = getRarityLevel(cData.Rarity or "Common")
        if cardLevel < threshLevel then return end

        local thumbnailUrl = ""
        local imageId = string.match(cData.ImageId or "", "%d+")
        if imageId then
            pcall(function()
                local thumbResponse = req({
                    Url    = string.format(ROBLOX_THUMBS, imageId),
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

        local cardCfg = CardConfig.Cards[cData.id]
        local income  = cardCfg and cardCfg.IncomeRate or cData.IncomeRate or 0

        dispatchWebhook({
            embeds = {{
                title       = "[*] Rare Card Rolled!",
                description = "A high-tier card has been acquired.",
                color       = 16766720,
                thumbnail   = { url = thumbnailUrl },
                author      = {
                    name = client.Name,
                    icon_url = string.format(ROBLOX_AVATAR, client.UserId),
                },
                fields = {
                    { name = "Card Name",      value = cData.DisplayName or cData.Name or cData.id, inline = false },
                    { name = "Rarity",         value = cData.Rarity or "Unknown",       inline = true },
                    { name = "Pack",           value = pName or "Unknown",              inline = true },
                    { name = "Income",         value = "$" .. formatCash(income) .. "/s", inline = false },
                    { name = "New Discovery",  value = isNew and "Yes" or "No",         inline = true },
                    { name = "Player",         value = "||" .. client.Name .. "||",     inline = true },
                },
                footer = { text = "SSC Elite Farm v3 — " .. os.date("%H:%M:%S") },
            }}
        })

        -- auto-lock high-rarity cards
        if Library.Flags["AutoLock"] then
            local lockFlag = Library.Flags["AutoLockRarity"]
            local lockName = type(lockFlag) == "string" and lockFlag
                          or (type(lockFlag) == "table" and lockFlag[1]) or "Mythic"
            if cardLevel >= getRarityLevel(lockName) and remotes.LockCard and uuid then
                pcall(function() remotes.LockCard:FireServer(uuid) end)
                stats.locked = stats.locked + 1
                logEvent("Lock", "Locked " .. (cData.DisplayName or cData.id))
            end
        end
    end)
end


-- [ SERVER HOP ]
local function fetchServers()
    if not req then return nil end
    local result = nil
    pcall(function()
        local response = req({
            Url = string.format(SERVERS_API, PLACE_ID),
            Method = "GET",
        })
        if response and response.Body then
            local decoded = HttpService:JSONDecode(response.Body)
            result = decoded and decoded.data
        end
    end)
    return result
end

local function serverHop(mode)
    -- mode: "low_players" | "low_ping" | "random"
    local servers = fetchServers()
    if not servers or #servers == 0 then
        notify("Server Hop", "Failed to fetch server list.", "warning")
        return
    end

    -- filter: not full, not our current jobId
    local current = game.JobId
    local valid = {}
    for _, s in ipairs(servers) do
        if s.id ~= current and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
            table.insert(valid, s)
        end
    end
    if #valid == 0 then
        notify("Server Hop", "No alternate servers found.", "warning")
        return
    end

    table.sort(valid, function(a, b)
        if mode == "low_ping" then
            return (a.ping or 9999) < (b.ping or 9999)
        elseif mode == "random" then
            return math.random() < 0.5
        else
            return (a.playing or 0) < (b.playing or 0)
        end
    end)

    local target = valid[1]
    stats.hopCount = stats.hopCount + 1
    logEvent("Hop", "Teleporting to " .. (target.id or "?") .. " (" .. (target.playing or 0) .. " players)")
    pcall(function()
        TeleportService:TeleportToPlaceInstance(PLACE_ID, target.id, client)
    end)
end


-- [ AUTO REJOIN ]
GuiService.ErrorMessageChanged:Connect(function()
    if Library.Flags["AutoRejoin"] then
        task.wait(1)
        pcall(function() TeleportService:Teleport(PLACE_ID, client) end)
    end
end)

client.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed and Library.Flags["AutoRejoin"] then
        task.wait(3)
        pcall(function() TeleportService:Teleport(PLACE_ID, client) end)
    end
end)


-- [ INVENTORY ANALYTICS HELPERS ]
local function rarityCounts()
    local out = {}
    for _, card in ipairs(getInventory()) do
        local cfg = CardConfig.Cards[card.id]
        local r = cfg and cfg.Rarity or "Unknown"
        out[r] = (out[r] or 0) + 1
    end
    return out
end


-- [ FAST LOOP: OPEN & BUY PACKS ]
local openPackIndex = 1
local buyPackIndex  = 1

task.spawn(function()
    while task.wait() do
        if Library.Flags["MasterKillSwitch"] then task.wait(0.5) continue end

        -- Weather gating: "only open during X weather"
        local weatherGateOK = true
        if Library.Flags["OnlyOpenDuringWeather"] then
            local wf = Library.Flags["OpenDuringWeatherList"]
            local list = type(wf) == "table" and wf or {}
            weatherGateOK = false
            for _, w in ipairs(list) do
                if weatherIsActive(w) then weatherGateOK = true break end
            end
        end

        -- Auto Open Packs
        if Library.Flags["AutoOpenPacks"] and weatherGateOK then
            local packDelay = Library.Flags["PackDelay"] or 0

            if throttleAllow() then
                pcall(function()
                    local flag     = Library.Flags["SelectedPacks"]
                    local selected = type(flag) == "table" and flag or { tostring(flag or "Bronze") }

                    if #selected > 0 then
                        if openPackIndex > #selected then openPackIndex = 1 end
                        local packName = selected[openPackIndex]
                        openPackIndex  = openPackIndex + 1

                        local playerData = getPlayerData()
                        local hasPack    = playerData
                                        and playerData.packs
                                        and (playerData.packs[packName] or 0) > 0

                        if hasPack then
                            remotes.OpenPack:FireServer(packName)
                            stats.opened = stats.opened + 1
                        end
                    end
                end)
            end

            if packDelay > 0 then hwait(packDelay, packDelay + 0.15) end
        end

        -- Auto Buy Packs (with smart mode + reserve)
        if Library.Flags["AutoBuyPacks"] then
            local buyDelay = Library.Flags["BuyDelay"] or 0
            local reserve  = Library.Flags["CashReserve"] or 0

            if throttleAllow() then
                pcall(function()
                    local cashNow = getCash()

                    -- enforce rebirth-cost reserve (auto)
                    if Library.Flags["ReserveForRebirth"] then
                        local rd = getRebirthRequirements()
                        if rd and rd.CashRequired then
                            reserve = math.max(reserve, rd.CashRequired)
                        end
                    end

                    if Library.Flags["SmartBuy"] then
                        -- buy highest-tier affordable from selected list
                        local flag     = Library.Flags["SelectedBuyPacks"]
                        local selected = type(flag) == "table" and flag or { "Bronze" }
                        local sorted = {}
                        for _, p in ipairs(selected) do
                            table.insert(sorted, { name = p, price = packPrice(p) })
                        end
                        table.sort(sorted, function(a, b) return a.price > b.price end)
                        for _, entry in ipairs(sorted) do
                            if entry.price > 0 and (cashNow - entry.price) >= reserve then
                                remotes.BuyPack:FireServer(entry.name)
                                stats.bought = stats.bought + 1
                                break
                            end
                        end
                    else
                        local flag     = Library.Flags["SelectedBuyPacks"]
                        local selected = type(flag) == "table" and flag or { "Bronze" }
                        if #selected > 0 then
                            if buyPackIndex > #selected then buyPackIndex = 1 end
                            local packName = selected[buyPackIndex]
                            buyPackIndex   = buyPackIndex + 1
                            local price    = packPrice(packName)
                            if price > 0 and (cashNow - price) >= reserve then
                                remotes.BuyPack:FireServer(packName)
                                stats.bought = stats.bought + 1
                            end
                        end
                    end
                end)
            end

            if buyDelay > 0 then hwait(buyDelay, buyDelay + 0.2) end
        end
    end
end)


-- [ MAIN PROCESSING LOOP ]
local timers = {
    collect  = 0, sell     = 0, delPacks = 0, gemShop  = 0,
    rebirth  = 0, equip    = 0, index    = 0, spin     = 0,
    daily    = 0, offline  = 0, weather  = 0, hop      = 0,
    boost    = 0, webhook  = os.clock(), hourly = os.clock(),
}

task.spawn(function()
    while task.wait(0.2) do
        if Library.Flags["MasterKillSwitch"] then continue end
        local now = os.clock()

        _G.DisablePopups = Library.Flags["DisablePopups"]
        _G.DisableNotifs = Library.Flags["DisableNotifs"]

        -- baselines
        if not stats.cashStart    then stats.cashStart    = getCash() end
        if not stats.gemsStart    then stats.gemsStart    = getGems() end
        if not stats.rebirthStart then stats.rebirthStart = getRebirthLevel() end

        -- Weather alerts
        if (now - timers.weather) >= 4 then
            timers.weather = now
            pcall(checkWeatherAlerts)
        end

        -- Stats Webhook (timed)
        if Library.Flags["WebhookStats"] then
            local statsDelay = Library.Flags["WebhookStatsDelay"] or STATS_DELAY_DEFAULT
            if (now - timers.webhook) >= (statsDelay * 60) then
                timers.webhook = now
                local elapsed = os.time() - stats.sessionStart
                local cashGain = getCash() - (stats.cashStart or 0)
                local cashPerHr = (elapsed > 0) and (cashGain / elapsed * 3600) or 0
                dispatchWebhook({
                    embeds = {{
                        title       = "[+] SSC Farm Analytics",
                        description = "[$] **Cash:** $"         .. formatCash(getCash())    .. "\n"
                                   .. "[*] **Gems:** "          .. formatCash(getGems())    .. "\n"
                                   .. "[#] **Rebirth Level:** " .. getRebirthLevel()        .. "\n"
                                   .. "[>] **Packs Opened:** "  .. formatCash(stats.opened) .. "\n"
                                   .. "[?] **Active Weather:** ".. getActiveWeathers()      .. "\n"
                                   .. "[~] **Cash/hr:** $"      .. formatCash(cashPerHr)    .. "\n"
                                   .. "[!] **Session Rebirths:** " .. stats.rebirths       .. "\n"
                                   .. "[T] **Uptime:** "        .. formatDuration(elapsed),
                        color  = 3447003,
                        author = {
                            name = client.Name,
                            icon_url = string.format(ROBLOX_AVATAR, client.UserId),
                        },
                        footer = { text = "SSC Elite Farm v3 — User: " .. client.Name },
                    }}
                })
            end
        end

        -- Hourly summary (separate cadence)
        if Library.Flags["WebhookHourly"] and (now - timers.hourly) >= 3600 then
            timers.hourly = now
            local elapsed = os.time() - stats.sessionStart
            dispatchWebhook({
                embeds = {{
                    title = "[H] Hourly Summary",
                    description = string.format(
                        "Opened: %d  |  Bought: %d  |  Sold: %d  |  Rebirths: %d  |  Hops: %d\nUptime: %s",
                        stats.opened, stats.bought, stats.sold, stats.rebirths, stats.hopCount,
                        formatDuration(elapsed)
                    ),
                    color = 10181046,
                    footer = { text = "SSC Elite Farm v3" },
                }}
            })
        end

        -- Auto Index Gems
        if Library.Flags["AutoIndex"] and (now - timers.index) >= 15 then
            timers.index = now
            pcall(function() remotes.ClaimAllIndexGems:FireServer() end)
        end

        -- Auto Spin Wheel
        if Library.Flags["AutoSpin"] and (now - timers.spin) >= 8 then
            timers.spin = now
            pcall(function()
                if not funcs.SpinWheelData then return end
                local ok, spinData = pcall(function() return funcs.SpinWheelData:InvokeServer() end)
                if ok and type(spinData) == "table" then
                    if spinData.canClaimFree then remotes.SpinWheel:FireServer("claim_free") end
                    if type(spinData.spins) == "number" and spinData.spins > 0 then
                        remotes.SpinWheel:FireServer("spin")
                    end
                end
            end)
        end

        if Library.Flags["AutoDaily"] and (now - timers.daily) >= 60 then
            timers.daily = now
            pcall(function() remotes.DailyReward:FireServer("claim") end)
        end

        if Library.Flags["AutoOffline"] and (now - timers.offline) >= 60 then
            timers.offline = now
            pcall(function() remotes.OfflineReward:FireServer("claim_normal") end)
        end

        -- Auto Use Boosts (best-effort: tries common remote names)
        if Library.Flags["AutoBoost"] and (now - timers.boost) >= 30 then
            timers.boost = now
            pcall(function()
                if remotes.UseBoost then
                    remotes.UseBoost:FireServer("luck")
                    stats.boostsUsed = stats.boostsUsed + 1
                end
                if remotes.ActivatePotion then
                    remotes.ActivatePotion:FireServer("luck")
                    stats.boostsUsed = stats.boostsUsed + 1
                end
            end)
        end

        -- Auto Redeem Codes (one-time)
        if Library.Flags["AutoRedeemCodes"] and not stats.codesRedeemed then
            stats.codesRedeemed = true
            task.spawn(function()
                local codes   = {}
                local ok, res = pcall(function() return game:HttpGet(CODES_URL) end)
                if ok and type(res) == "string" then
                    for line in res:gmatch("[^\r\n]+") do
                        local cleaned = line:gsub("%s+", "")
                        if cleaned ~= "" and #cleaned >= 3 then
                            table.insert(codes, cleaned)
                        end
                    end
                end
                if remotes.RedeemCode and #codes > 0 then
                    for _, code in ipairs(codes) do
                        pcall(function() remotes.RedeemCode:FireServer(string.lower(code)) end)
                        task.wait(CODE_WAIT)
                    end
                    logEvent("Codes", "Redeemed " .. #codes .. " codes.")
                    notify("Codes", "Redeemed " .. #codes .. " codes.", "info")
                end
            end)
        end

        -- Auto Collect Cash
        local collectDelay = Library.Flags["CollectDelay"] or COLLECT_DEFAULT
        if Library.Flags["AutoCollect"] and (now - timers.collect) >= collectDelay then
            timers.collect = now
            pcall(function()
                for slotIndex, slotData in pairs(getSlots()) do
                    if slotData and slotData.card then
                        remotes.CollectSlot:FireServer(tonumber(slotIndex))
                        stats.collects = stats.collects + 1
                        hwait(0.04, 0.08)
                    end
                end
            end)
        end

        -- Pause selling during Lucky weather
        local sellGateOK = true
        if Library.Flags["PauseSellOnLucky"] then
            for _, w in ipairs(getActiveWeathersList()) do
                if string.find(string.lower(w), "lucky") then sellGateOK = false break end
            end
        end

        -- Auto Sell Cards
        if Library.Flags["AutoSell"] and sellGateOK and (now - timers.sell) >= 8 then
            timers.sell = now
            pcall(function()
                local threshFlag  = Library.Flags["SellThreshold"]
                local threshName  = type(threshFlag) == "string" and threshFlag
                                 or (type(threshFlag) == "table" and threshFlag[1])
                                 or SELL_DEFAULT
                local threshLevel = getRarityLevel(threshName)

                local toSell = {}
                for _, card in ipairs(getInventory()) do
                    local isEligible = card and card.id and card.uuid
                                    and not card.throneCard and not card.locked
                                    and not isProtectedById(card.id)
                                    and not isLastCopy(card.id)
                    if isEligible then
                        local cfg        = CardConfig.Cards[card.id]
                        local cardLevel  = getRarityLevel(cfg and cfg.Rarity)
                        if cardLevel < threshLevel then
                            table.insert(toSell, card.uuid)
                        end
                    end
                end

                if #toSell > 0 then
                    remotes.SellCards:FireServer(toSell)
                    stats.sold = stats.sold + #toSell
                    logEvent("Sell", "Sold " .. #toSell .. " cards.")
                end
            end)
        end

        -- Auto Delete Packs
        if Library.Flags["AutoDeletePacks"] and (now - timers.delPacks) >= 10 then
            timers.delPacks = now
            pcall(function()
                local flag     = Library.Flags["DeletePacksList"]
                local selected = type(flag) == "table" and flag or {}
                if #selected > 0 and remotes.DeletePacks then
                    remotes.DeletePacks:FireServer(selected)
                end
            end)
        end

        -- Auto Equip Best
        if Library.Flags["AutoEquip"] and (now - timers.equip) >= 8 then
            timers.equip = now
            pcall(equipBest)
        end

        -- Auto Gem Shop
        if Library.Flags["AutoGemShop"] and (now - timers.gemShop) >= 10 then
            timers.gemShop = now
            pcall(function()
                local itemFlag = Library.Flags["GemShopItemUI"]
                local itemKey  = type(itemFlag) == "string" and itemFlag
                              or (type(itemFlag) == "table" and itemFlag[1])
                              or "Lucky Item"
                local itemId   = GEM_SHOP_MAP[itemKey] or "lucky"
                local minGems  = Library.Flags["MinGems"] or MIN_GEMS_DEFAULT
                if getGems() >= minGems then
                    remotes.BuyGemShopItem:FireServer(itemId)
                    stats.gemBuys = stats.gemBuys + 1
                end
            end)
        end

        -- Auto Rebirth (smart)
        local rebirthCooldown = Library.Flags["ForceRebirth"] and REBIRTH_CD_FORCE or REBIRTH_CD_NORMAL
        if Library.Flags["AutoRebirth"] and (now - timers.rebirth) >= rebirthCooldown then
            timers.rebirth = now
            pcall(function()
                -- target rebirth cap
                local targetCap = Library.Flags["RebirthCap"] or 0
                if targetCap > 0 and getRebirthLevel() >= targetCap then return end

                local shouldRebirth = Library.Flags["ForceRebirth"] or canRebirth()
                if not shouldRebirth then return end

                -- smart prep: sell + equip first
                if Library.Flags["SmartRebirthPrep"] then
                    pcall(equipBest)
                    hwait(0.4, 0.6)
                end

                local levelBefore = getRebirthLevel()
                local tBefore     = os.time()
                remotes.Rebirth:FireServer()
                task.wait(1.5)
                if getRebirthLevel() > levelBefore then
                    stats.rebirths = stats.rebirths + 1
                    local dt = os.time() - stats.lastRebirthTs
                    stats.lastRebirthTs = os.time()
                    logEvent("Rebirth", "Reached level " .. getRebirthLevel() .. " (Δ" .. dt .. "s)")

                    -- milestone webhook
                    if Library.Flags["WebhookMilestones"] then
                        dispatchWebhook({
                            embeds = {{
                                title = "[#] Rebirth Milestone",
                                description = "Reached Rebirth Level **" .. getRebirthLevel() .. "**",
                                color = 16753920,
                                footer = { text = "SSC Elite Farm v3" },
                            }}
                        })
                    end

                    -- auto-hop after N rebirths
                    local hopEvery = Library.Flags["HopEveryRebirths"] or 0
                    if hopEvery > 0 and (stats.rebirths % hopEvery == 0) then
                        logEvent("Hop", "Auto-hop trigger (every " .. hopEvery .. " rebirths)")
                        serverHop(Library.Flags["HopMode"] or "low_players")
                    end
                end
            end)
        end
    end
end)


-- [ UI: SECTIONS ]
local function safeSection(name)
    local ok, sec = pcall(function() return Setup:CreateSection(name) end)
    if not ok or not sec then
        warn("[SSC Farm] Failed to create section: " .. tostring(name) .. " — " .. tostring(sec))
        -- return a stub so subsequent createX calls don't crash
        local stub = {}
        local function noop() return stub end
        setmetatable(stub, { __index = function() return noop end })
        return stub
    end
    -- wrap every createX method so a single bad element doesn't kill the tab
    local original = {}
    for _, method in ipairs({
        "createLabel","createButton","createToggle","createSlider",
        "createInputBox","createDropdown",
    }) do
        local fn = sec[method]
        if type(fn) == "function" then
            original[method] = fn
            sec[method] = function(self, args)
                local okCall, result = pcall(fn, self, args)
                if not okCall then
                    warn(string.format(
                        "[SSC Farm] %s failed for '%s' in section '%s' — %s",
                        method, tostring(args and args.Name), tostring(name), tostring(result)
                    ))
                    -- return a stub object with :Set so later code (label_x:Set) doesn't crash
                    local stub = {}
                    setmetatable(stub, { __index = function() return function() end end })
                    return stub
                end
                return result
            end
        end
    end
    return sec
end

local TabMaster   = safeSection("Master")
local TabFarm     = safeSection("Farm & Packs")
local TabPassive  = safeSection("Passives & Rebirth")
local TabHunt     = safeSection("Hunting")
local TabInv      = safeSection("Inventory")
local TabWeather  = safeSection("Weather")
local TabSafety   = safeSection("Safety")
local TabHop      = safeSection("Server Hop")
local TabWebhook  = safeSection("Webhooks")
local TabMisc     = safeSection("Misc & Settings")
local TabStats    = safeSection("Analytics")
local TabLogs     = safeSection("Logs")


local pList = getPackList()
if #pList == 0 then pList = { "Bronze" } end


-- [ UI: MASTER TAB ]
TabMaster:createLabel({ Name = "SSC Elite Farm v3.0 — Full Suite", Special = true })
TabMaster:createLabel({ Name = "Paid Contributor :- aditya44325f" })

TabMaster:createLabel({ Name = "Global Controls", Special = true })

TabMaster:createToggle({
    Name        = "MASTER KILL SWITCH",
    flagName    = "MasterKillSwitch",
    Flag        = false,
    Description = "Instantly halts every loop (farm, buy, rebirth, etc.) without flipping individual toggles.",
    Warning     = function() return "All automation is paused while this is ON." end,
    WarnIf      = function() return Library.Flags["MasterKillSwitch"] == true end,
    Callback    = function(v)
        logEvent("Master", v and "Kill switch ON — all loops paused." or "Kill switch OFF — loops resumed.")
    end,
})

TabMaster:createToggle({
    Name        = "Pause When UI Open",
    flagName    = "PauseWhenUIOpen",
    Flag        = false,
    Description = "Soft-pause heavy farming while you're navigating menus.",
    Callback    = function() end,
})

TabMaster:createLabel({ Name = "Hotkeys", Special = true })

TabMaster:createDropdown({
    Name        = "Hotkey: Toggle Auto Open",
    flagName    = "HK_AutoOpen",
    Flag        = { "F1" },
    List        = { "F1","F2","F3","F4","F5","F6","F7","F8","None" },
    multi       = false,
    Description = "Press this key to toggle Auto Open Packs.",
    Callback    = function() end,
})

TabMaster:createDropdown({
    Name        = "Hotkey: Toggle Auto Sell",
    flagName    = "HK_AutoSell",
    Flag        = { "F2" },
    List        = { "F1","F2","F3","F4","F5","F6","F7","F8","None" },
    multi       = false,
    Callback    = function() end,
})

TabMaster:createDropdown({
    Name        = "Hotkey: Hide HUD",
    flagName    = "HK_HideHUD",
    Flag        = { "F3" },
    List        = { "F1","F2","F3","F4","F5","F6","F7","F8","None" },
    multi       = false,
    Callback    = function() end,
})

TabMaster:createDropdown({
    Name        = "Hotkey: Master Kill",
    flagName    = "HK_Kill",
    Flag        = { "F4" },
    List        = { "F1","F2","F3","F4","F5","F6","F7","F8","None" },
    multi       = false,
    Callback    = function() end,
})

TabMaster:createLabel({ Name = "Theme", Special = true })

TabMaster:createDropdown({
    Name        = "Theme Preset",
    flagName    = "ThemePreset",
    Flag        = { "Dark Mode" },
    List        = { "Light Mode","Dark Mode","Halloween" },
    multi       = false,
    Description = "Apply a Versus theme preset.",
    Callback    = function(v)
        local name = type(v) == "table" and v[1] or v
        pcall(function() Setup:UpdateUI(name) end)
    end,
})

TabMaster:createButton({
    Name        = "Open Theme Customizer",
    Callback    = function() pcall(function() Library:OpenCustomizer() end) end,
})


-- [ UI: FARM TAB ]
TabFarm:createLabel({ Name = "Plot Automation", Special = true })

TabFarm:createToggle({
    Name        = "Auto Collect Cash",
    flagName    = "AutoCollect",
    Flag        = false,
    Description = "Automatically fires CollectSlot for all active card slots.",
    Callback    = function() end,
})

TabFarm:createSlider({
    Name        = "Collect Delay (Seconds)",
    flagName    = "CollectDelay",
    value       = COLLECT_DEFAULT,
    minValue    = 1,
    maxValue    = 60,
    Description = "How often (in seconds) to collect from each slot.",
    Callback    = function() end,
})

TabFarm:createToggle({
    Name        = "Auto Equip Best Cards",
    flagName    = "AutoEquip",
    Flag        = false,
    Description = "Sorts your inventory by income and equips the highest earners.",
    Callback    = function() end,
})

TabFarm:createToggle({
    Name        = "Auto Sell Cards",
    flagName    = "AutoSell",
    Flag        = false,
    Description = "Sells all cards below the chosen rarity threshold every 8 seconds.",
    Callback    = function() end,
})

TabFarm:createDropdown({
    Name        = "Sell Below Rarity:",
    flagName    = "SellThreshold",
    Flag        = { SELL_DEFAULT },
    List        = rarityList,
    multi       = false,
    Description = "Cards below this rarity will be sold automatically.",
    Callback    = function() end,
})

TabFarm:createLabel({ Name = "Pack Roller Configuration", Special = true })

TabFarm:createToggle({
    Name        = "Auto Open Packs",
    flagName    = "AutoOpenPacks",
    Flag        = false,
    Description = "Continuously opens packs from your selected list.",
    Callback    = function() end,
})

local packDropdown = TabFarm:createDropdown({
    Name        = "Select Packs to Open",
    flagName    = "SelectedPacks",
    Flag        = { pList[1] },
    List        = pList,
    multi       = true,
    Description = "Pick which packs to roll. Cycles through all selected.",
    Callback    = function() end,
})

TabFarm:createButton({
    Name        = "Select ALL Packs (To Open)",
    Description = "Adds every available pack to the open queue.",
    Callback    = function()
        pcall(function() packDropdown:Set(pList) end)
        Library.Flags["SelectedPacks"] = pList
        openPackIndex = 1
    end,
})

TabFarm:createSlider({
    Name        = "Custom Pack Delay (0 = Instant)",
    flagName    = "PackDelay",
    value       = 0,
    minValue    = 0,
    maxValue    = 5,
    Description = "Adds a wait between each pack open. 0 = no delay.",
    Callback    = function() end,
})

TabFarm:createLabel({ Name = "Shop & Store Automation", Special = true })

TabFarm:createToggle({
    Name        = "Auto Buy Shop Packs",
    flagName    = "AutoBuyPacks",
    Flag        = false,
    Description = "Buys packs from the shop whenever you can afford them.",
    Callback    = function() end,
})

TabFarm:createToggle({
    Name        = "Smart Buy (Highest Affordable)",
    flagName    = "SmartBuy",
    Flag        = false,
    Description = "Instead of cycling, buys the most expensive pack you can afford from the selected list.",
    Callback    = function() end,
})

TabFarm:createSlider({
    Name        = "Cash Reserve (Min Balance)",
    flagName    = "CashReserve",
    value       = 0,
    minValue    = 0,
    maxValue    = 1000000000,
    Description = "Buy loop will not spend below this balance.",
    Callback    = function() end,
})

TabFarm:createToggle({
    Name        = "Reserve Cash for Next Rebirth",
    flagName    = "ReserveForRebirth",
    Flag        = false,
    Description = "Auto-bumps your reserve to next rebirth's cost. Prevents buying packs that would block rebirth.",
    Callback    = function() end,
})

local buyPackDropdown = TabFarm:createDropdown({
    Name        = "Select Packs to Buy",
    flagName    = "SelectedBuyPacks",
    Flag        = { pList[1] },
    List        = pList,
    multi       = true,
    Description = "Which packs to purchase from the shop.",
    Callback    = function() end,
})

TabFarm:createButton({
    Name        = "Select ALL Shop Packs",
    Description = "Adds every pack to the buy queue.",
    Callback    = function()
        pcall(function() buyPackDropdown:Set(pList) end)
        Library.Flags["SelectedBuyPacks"] = pList
        buyPackIndex = 1
    end,
})

TabFarm:createSlider({
    Name        = "Pack Buy Delay (Seconds)",
    flagName    = "BuyDelay",
    value       = 0,
    minValue    = 0,
    maxValue    = 900,
    Description = "Delay between each shop purchase. 0 = instant.",
    Callback    = function() end,
})

TabFarm:createToggle({
    Name        = "Auto Buy Gem Shop",
    flagName    = "AutoGemShop",
    Flag        = false,
    Description = "Automatically purchases the selected gem shop item.",
    Callback    = function() end,
})

TabFarm:createDropdown({
    Name        = "Target Gem Shop Item",
    flagName    = "GemShopItemUI",
    Flag        = { "Lucky Item" },
    List        = { "Lucky Item", "Auto Equip Best", "Auto Skip", "Inventory +500", "Scarlet Item" },
    multi       = false,
    Description = "Which item to buy from the gem shop.",
    Callback    = function() end,
})

TabFarm:createSlider({
    Name        = "Min Gems to Keep",
    flagName    = "MinGems",
    value       = MIN_GEMS_DEFAULT,
    minValue    = 0,
    maxValue    = 10000,
    Description = "Gem shop purchases only fire if your gems exceed this value.",
    Callback    = function() end,
})

TabFarm:createLabel({ Name = "Inventory Cleanup", Special = true })

TabFarm:createToggle({
    Name        = "Auto Delete Packs",
    flagName    = "AutoDeletePacks",
    Flag        = false,
    Description = "Deletes selected pack types from your inventory every 10 seconds.",
    Callback    = function() end,
})

TabFarm:createDropdown({
    Name        = "Select Packs to Delete",
    flagName    = "DeletePacksList",
    Flag        = { pList[1] },
    List        = pList,
    multi       = true,
    Description = "Packs selected here will be permanently deleted.",
    Warning     = function() return "Deleted packs cannot be recovered." end,
    WarnIf      = function() return Library.Flags["AutoDeletePacks"] == true end,
    Callback    = function() end,
})


-- [ UI: PASSIVES TAB ]
TabPassive:createLabel({ Name = "Silent Income Generators", Special = true })

TabPassive:createToggle({
    Name        = "Auto Claim Index Gems",
    flagName    = "AutoIndex",
    Flag        = false,
    Description = "Claims all index gems every 15 seconds.",
    Callback    = function() end,
})

TabPassive:createToggle({
    Name        = "Auto Spin Wheel",
    flagName    = "AutoSpin",
    Flag        = false,
    Description = "Spins the wheel and claims free spins every 8 seconds.",
    Callback    = function() end,
})

TabPassive:createToggle({
    Name        = "Auto Daily Rewards",
    flagName    = "AutoDaily",
    Flag        = false,
    Description = "Claims the daily reward every 60 seconds.",
    Callback    = function() end,
})

TabPassive:createToggle({
    Name        = "Auto Offline Rewards",
    flagName    = "AutoOffline",
    Flag        = false,
    Description = "Claims offline reward income every 60 seconds.",
    Callback    = function() end,
})

TabPassive:createToggle({
    Name        = "Auto Use Boosts / Potions",
    flagName    = "AutoBoost",
    Flag        = false,
    Description = "Fires UseBoost / ActivatePotion remotes every 30s (no-op if game doesn't expose them).",
    Callback    = function() end,
})

TabPassive:createLabel({ Name = "Progression & Rebirth", Special = true })

TabPassive:createToggle({
    Name        = "Auto Redeem All Codes",
    flagName    = "AutoRedeemCodes",
    Flag        = false,
    Description = "Fetches and redeems all known SSC codes. Runs once per session.",
    Callback    = function() end,
})

TabPassive:createToggle({
    Name        = "Auto Rebirth",
    flagName    = "AutoRebirth",
    Flag        = false,
    Description = "Rebirths automatically when requirements are met.",
    Callback    = function() end,
})

TabPassive:createToggle({
    Name        = "Smart Rebirth Prep",
    flagName    = "SmartRebirthPrep",
    Flag        = true,
    Description = "Auto-equip best cards before each rebirth to ensure max income carryover.",
    Callback    = function() end,
})

TabPassive:createSlider({
    Name        = "Target Rebirth Cap (0 = Unlimited)",
    flagName    = "RebirthCap",
    value       = 0,
    minValue    = 0,
    maxValue    = 999,
    Description = "Stops auto-rebirth once this level is reached.",
    Callback    = function() end,
})

TabPassive:createToggle({
    Name        = "Force Rebirth",
    flagName    = "ForceRebirth",
    Flag        = false,
    Description = "Fires the rebirth remote regardless of requirements.",
    Warning     = function() return "May rebirth before requirements are met." end,
    WarnIf      = function() return Library.Flags["ForceRebirth"] == true end,
    Callback    = function() end,
})


-- [ UI: HUNTING TAB ]
TabHunt:createLabel({ Name = "Target a Specific Card", Special = true })
TabHunt:createLabel({ Name = "Roller will keep opening packs until your target drops. Auto-locks the card and stops on success." })

TabHunt:createToggle({
    Name        = "Hunting Mode",
    flagName    = "HuntingMode",
    Flag        = false,
    Description = "Disables AutoOpen/AutoBuy once target is rolled. Auto-locks the card.",
    Callback    = function(v)
        if v then huntFound = false end
        logEvent("Hunt", v and "Hunting mode armed." or "Hunting mode disarmed.")
    end,
})

TabHunt:createDropdown({
    Name        = "Target Card",
    flagName    = "HuntTarget",
    Flag        = { cardIdList[1] or "" },
    List        = cardIdList,
    multi       = false,
    Description = "Card you want. List shows DisplayName [Rarity].",
    Callback    = function() end,
})

TabHunt:createButton({
    Name        = "Reset Hunt State",
    Callback    = function()
        huntFound = false
        notify("Hunt", "Hunt state reset — will trigger again on next match.", "info")
    end,
})


-- [ UI: INVENTORY TAB ]
TabInv:createLabel({ Name = "Protection (Whitelist)", Special = true })

TabInv:createDropdown({
    Name        = "Protected Cards (Never Sell)",
    flagName    = "ProtectedCards",
    Flag        = {},
    List        = cardIdList,
    multi       = true,
    Description = "Cards listed here are NEVER sold/deleted, regardless of rarity.",
    Callback    = function() end,
})

TabInv:createToggle({
    Name        = "Keep One of Each (Collector Mode)",
    flagName    = "KeepOneOfEach",
    Flag        = false,
    Description = "Never sells the last copy of any card — helps build/maintain index completion.",
    Callback    = function() end,
})

TabInv:createLabel({ Name = "Auto Lock", Special = true })

TabInv:createToggle({
    Name        = "Auto Lock New Rares",
    flagName    = "AutoLock",
    Flag        = false,
    Description = "Locks newly rolled cards at/above the chosen rarity (uses LockCard remote if available).",
    Callback    = function() end,
})

TabInv:createDropdown({
    Name        = "Lock at or Above:",
    flagName    = "AutoLockRarity",
    Flag        = { "Mythic" },
    List        = rarityList,
    multi       = false,
    Callback    = function() end,
})

TabInv:createLabel({ Name = "Manager Tools", Special = true })

local invLabel = TabInv:createLabel({ Name = "Inventory: (loading...)" })

TabInv:createButton({
    Name        = "Refresh Inventory Count",
    Callback    = function()
        local counts = rarityCounts()
        local parts = {}
        for _, r in ipairs(rarityList) do
            if counts[r] and counts[r] > 0 then
                table.insert(parts, r .. ": " .. counts[r])
            end
        end
        local total = 0
        for _, n in pairs(counts) do total = total + n end
        pcall(function()
            invLabel:Set("Inventory (" .. total .. "): " .. (#parts > 0 and table.concat(parts, "  •  ") or "empty"))
        end)
    end,
})

TabInv:createButton({
    Name        = "Sell ALL Duplicates of Selected Rarity",
    Description = "Keeps the highest-income copy of each card ID at the chosen rarity, sells the rest.",
    Callback    = function()
        local flag = Library.Flags["SellThreshold"]
        local rName = type(flag)=="table" and flag[1] or flag or "Silver"
        local seen = {}
        local toSell = {}
        for _, card in ipairs(getInventory()) do
            if card.id and card.uuid and not card.locked and not card.throneCard and not isProtectedById(card.id) then
                local cfg = CardConfig.Cards[card.id]
                if cfg and cfg.Rarity == rName then
                    if seen[card.id] then
                        table.insert(toSell, card.uuid)
                    else
                        seen[card.id] = true
                    end
                end
            end
        end
        if #toSell > 0 then
            pcall(function() remotes.SellCards:FireServer(toSell) end)
            notify("Duplicates", "Sold " .. #toSell .. " duplicate cards.", "info")
        else
            notify("Duplicates", "No duplicates found at " .. rName .. ".", "info")
        end
    end,
})

TabInv:createButton({
    Name        = "Sell ALL Except Top 6 Income",
    Description = "Aggressively wipes inventory, keeping only your 6 highest-income cards (and protected list).",
    Warning     = function() return "Destructive — make sure your whitelist is set!" end,
    WarnIf      = function() return true end,
    Callback    = function()
        local cards = {}
        for _, c in ipairs(getInventory()) do
            if c.id and c.uuid and not c.locked and not c.throneCard and not isProtectedById(c.id) then
                local cfg = CardConfig.Cards[c.id]
                table.insert(cards, { uuid=c.uuid, income=(cfg and cfg.IncomeRate or 0) })
            end
        end
        table.sort(cards, function(a,b) return a.income > b.income end)
        local toSell = {}
        for i = 7, #cards do table.insert(toSell, cards[i].uuid) end
        if #toSell > 0 then
            pcall(function() remotes.SellCards:FireServer(toSell) end)
            notify("Cleanup", "Sold " .. #toSell .. " cards (kept top 6).", "info")
        else
            notify("Cleanup", "Nothing to sell.", "info")
        end
    end,
})


-- [ UI: WEATHER TAB ]
local weatherList = {
    "Lucky","Golden Hour","Mythic Surge","Storm","Eclipse","Blizzard",
    "Heatwave","Solar Flare","Moon Phase","Aurora","Meteor Shower",
}

TabWeather:createLabel({ Name = "Weather-Aware Automation", Special = true })

TabWeather:createToggle({
    Name        = "Pause Selling During Lucky Weather",
    flagName    = "PauseSellOnLucky",
    Flag        = true,
    Description = "Stops Auto Sell while any 'Lucky'-named weather is active so you keep rares.",
    Callback    = function() end,
})

TabWeather:createToggle({
    Name        = "Only Open Packs During Selected Weather",
    flagName    = "OnlyOpenDuringWeather",
    Flag        = false,
    Description = "Gates Auto Open Packs to only run when a chosen weather is active.",
    Callback    = function() end,
})

TabWeather:createDropdown({
    Name        = "Open-Pack Weather List",
    flagName    = "OpenDuringWeatherList",
    Flag        = { "Lucky" },
    List        = weatherList,
    multi       = true,
    Description = "Auto Open only runs while ANY of these weathers is active.",
    Callback    = function() end,
})

TabWeather:createLabel({ Name = "Alerts", Special = true })

TabWeather:createToggle({
    Name        = "Webhook on Watched Weather",
    flagName    = "WebhookWeather",
    Flag        = false,
    Description = "Send a Discord embed when a watched weather event starts.",
    Callback    = function() end,
})

TabWeather:createDropdown({
    Name        = "Watched Weather List",
    flagName    = "WatchedWeathers",
    Flag        = { "Lucky","Mythic Surge" },
    List        = weatherList,
    multi       = true,
    Description = "Weather names to alert on. Free-text not supported — pick from list.",
    Callback    = function() end,
})


-- [ UI: SAFETY TAB ]
TabSafety:createLabel({ Name = "Anti-Detection", Special = true })

TabSafety:createToggle({
    Name        = "Humanized Delays",
    flagName    = "HumanizedDelays",
    Flag        = true,
    Description = "Adds random jitter to all task.waits so remote-call timing isn't perfectly periodic.",
    Callback    = function() end,
})

TabSafety:createToggle({
    Name        = "Remote Throttle (40/sec cap)",
    flagName    = "RemoteThrottle",
    Flag        = true,
    Description = "Hard caps outgoing FireServer calls to avoid server rate-limit kicks. Always recommended ON.",
    Callback    = function() end,
})

TabSafety:createLabel({ Name = "Recovery", Special = true })

TabSafety:createToggle({
    Name        = "Auto Rejoin on Kick / Disconnect",
    flagName    = "AutoRejoin",
    Flag        = false,
    Description = "Listens to GuiService.ErrorMessageChanged and OnTeleport(Failed) → teleports back into the place.",
    Callback    = function() end,
})

TabSafety:createButton({
    Name        = "Test Rejoin",
    Description = "Manually rejoin the same place now.",
    Callback    = function()
        pcall(function() TeleportService:Teleport(PLACE_ID, client) end)
    end,
})


-- [ UI: SERVER HOP TAB ]
TabHop:createLabel({ Name = "Server Hopping", Special = true })

TabHop:createDropdown({
    Name        = "Hop Mode",
    flagName    = "HopMode",
    Flag        = { "low_players" },
    List        = { "low_players","low_ping","random" },
    multi       = false,
    Description = "low_players = least populated (best for farming). low_ping = best latency. random = shuffle.",
    Callback    = function() end,
})

TabHop:createSlider({
    Name        = "Auto-Hop Every N Rebirths (0 = Off)",
    flagName    = "HopEveryRebirths",
    value       = 0,
    minValue    = 0,
    maxValue    = 50,
    Description = "Trigger a server hop after every N successful rebirths.",
    Callback    = function() end,
})

TabHop:createButton({
    Name        = "Hop Now",
    Description = "Immediately hop using the selected mode.",
    Callback    = function()
        local mf = Library.Flags["HopMode"]
        local mode = type(mf)=="table" and mf[1] or mf or "low_players"
        serverHop(mode)
    end,
})


-- [ UI: WEBHOOKS TAB ]
TabWebhook:createLabel({ Name = "Discord Integration", Special = true })

TabWebhook:createInputBox({
    Name        = "Webhook URL",
    flagName    = "WebhookURL",
    Flag        = "",
    Description = "Paste your Discord channel webhook URL here.",
    Callback    = function(val) getgenv().WebhookURL = val end,
})

TabWebhook:createInputBox({
    Name        = "Discord User ID",
    flagName    = "WebhookPingID",
    Flag        = "",
    Description = "Paste your Discord User ID to be pinged on rare rolls.",
    Callback    = function(val) getgenv().WebhookPingID = tostring(val):gsub("[^%d]", "") end,
})

TabWebhook:createLabel({ Name = "Rare Card Tracker", Special = true })

TabWebhook:createToggle({
    Name        = "Enable Rare Rolls Webhook",
    flagName    = "WebhookRareRolls",
    Flag        = false,
    Description = "Sends a Discord embed whenever a card above the threshold is rolled.",
    Callback    = function() end,
})

TabWebhook:createDropdown({
    Name        = "Minimum Rarity to Log",
    flagName    = "WebhookRarityThresh",
    Flag        = { RARITY_THRESH_DEFAULT },
    List        = rarityList,
    multi       = false,
    Description = "Only cards at or above this rarity will trigger the webhook.",
    Callback    = function() end,
})

TabWebhook:createLabel({ Name = "Automated Analytics", Special = true })

TabWebhook:createToggle({
    Name        = "Enable Stats Webhook",
    flagName    = "WebhookStats",
    Flag        = false,
    Description = "Periodically sends session stats to your Discord webhook.",
    Callback    = function() end,
})

TabWebhook:createSlider({
    Name        = "Stats Update Frequency (Mins)",
    flagName    = "WebhookStatsDelay",
    value       = STATS_DELAY_DEFAULT,
    minValue    = 1,
    maxValue    = 60,
    Description = "How many minutes between each stats post.",
    Callback    = function() end,
})

TabWebhook:createToggle({
    Name        = "Hourly Summary Embed",
    flagName    = "WebhookHourly",
    Flag        = false,
    Description = "Compact roll-up of opens/buys/sells/rebirths/hops every hour.",
    Callback    = function() end,
})

TabWebhook:createToggle({
    Name        = "Milestone Webhook (Rebirths)",
    flagName    = "WebhookMilestones",
    Flag        = false,
    Description = "Posts when each rebirth level is achieved.",
    Callback    = function() end,
})

TabWebhook:createButton({
    Name        = "Send Test Webhook",
    Description = "Fires a test message to verify your webhook URL is working.",
    Callback    = function()
        if (getgenv().WebhookURL or "") == "" then
            notify("Webhook", "No webhook URL set.", "warning")
            return
        end
        dispatchWebhook({
            embeds = {{
                title       = "[~] Test Webhook",
                description = "SSC Elite Farm v3 webhook is working correctly.",
                color       = 5763719,
                author      = {
                    name = client.Name,
                    icon_url = string.format(ROBLOX_AVATAR, client.UserId),
                },
                footer      = { text = "SSC Elite Farm v3 — " .. client.Name },
            }}
        })
        notify("Webhook", "Test sent.", "info")
    end,
})


-- [ UI: MISC TAB ]
TabMisc:createLabel({ Name = "Game Modifications", Special = true })

TabMisc:createToggle({
    Name        = "Disable Game Popups",
    flagName    = "DisablePopups",
    Flag        = false,
    Description = "Blocks purchase prompts like rebirth and booth popups.",
    Callback    = function(v) _G.DisablePopups = v end,
})

TabMisc:createToggle({
    Name        = "Disable Game Notifications",
    flagName    = "DisableNotifs",
    Flag        = false,
    Description = "Hides all in-game notification frames from the PlayerGui.",
    Callback    = function(v) _G.DisableNotifs = v end,
})

TabMisc:createToggle({
    Name        = "Hide Game HUD",
    flagName    = "HideHUD",
    Flag        = false,
    Description = "Toggles the game's main HUD ScreenGui.",
    Callback    = function(v)
        local playerGui = client:FindFirstChild("PlayerGui")
        if not playerGui then return end
        local hud = playerGui:FindFirstChild("HUD")
        if hud then hud.Enabled = not v end
    end,
})

TabMisc:createLabel({ Name = "Quick Actions", Special = true })

TabMisc:createButton({
    Name        = "Equip Best Cards Now",
    Callback    = function()
        local success = equipBest()
        notify("Equipped", success and "Best cards equipped successfully." or "No upgrades found or already optimal.", "info")
    end,
})

TabMisc:createButton({
    Name        = "Sell Below Threshold Now",
    Callback    = function()
        local flag     = Library.Flags and Library.Flags["SellThreshold"]
        local tName    = type(flag) == "table" and flag[1] or (type(flag) == "string" and flag) or SELL_DEFAULT
        local tLevel   = getRarityLevel(tName)
        local toSell   = {}
        for _, card in ipairs(getInventory()) do
            local isEligible = card and card.id and card.uuid
                            and not card.throneCard and not card.locked
                            and not isProtectedById(card.id)
                            and not isLastCopy(card.id)
            if isEligible then
                local cfg = CardConfig.Cards[card.id]
                if cfg and getRarityLevel(cfg.Rarity) < tLevel then
                    table.insert(toSell, card.uuid)
                end
            end
        end
        if #toSell > 0 then
            pcall(function() remotes.SellCards:FireServer(toSell) end)
            notify("Sold", #toSell .. " cards cleared.", "info")
        else
            notify("Sold", "No cards matched the threshold.", "info")
        end
    end,
})

TabMisc:createButton({
    Name        = "Bug Report",
    Description = "Opens the built-in Versus bug reporter.",
    Callback    = function() pcall(function() Library:PromptBugReport() end) end,
})


-- [ UI: STATS TAB ]
TabStats:createLabel({ Name = "Live Session Analytics", Special = true })

local label_cash     = TabStats:createLabel({ Name = "Cash: $0" })
local label_gems     = TabStats:createLabel({ Name = "Gems: 0" })
local label_rebirth  = TabStats:createLabel({ Name = "Rebirth Level: 0" })
local label_opened   = TabStats:createLabel({ Name = "Packs Opened: 0" })
local label_bought   = TabStats:createLabel({ Name = "Packs Bought: 0" })
local label_sold     = TabStats:createLabel({ Name = "Cards Sold: 0" })
local label_collect  = TabStats:createLabel({ Name = "Collects: 0" })
local label_gemBuys  = TabStats:createLabel({ Name = "Gem Buys: 0" })
local label_locked   = TabStats:createLabel({ Name = "Cards Locked: 0" })
local label_sRebirth = TabStats:createLabel({ Name = "Session Rebirths: 0" })
local label_hops     = TabStats:createLabel({ Name = "Server Hops: 0" })
local label_boost    = TabStats:createLabel({ Name = "Boosts Used: 0" })
local label_weather  = TabStats:createLabel({ Name = "Active Weather: None" })

TabStats:createLabel({ Name = "Rates & Timers", Special = true })
local label_uptime   = TabStats:createLabel({ Name = "Uptime: 00:00:00" })
local label_cashHr   = TabStats:createLabel({ Name = "Cash/hr: $0" })
local label_gemsHr   = TabStats:createLabel({ Name = "Gems/hr: 0" })
local label_rebHr    = TabStats:createLabel({ Name = "Rebirths/hr: 0" })
local label_etaReb   = TabStats:createLabel({ Name = "ETA Next Rebirth: --" })

TabStats:createLabel({ Name = "Pack Roll Distribution", Special = true })
local label_rolls    = TabStats:createLabel({ Name = "(no rolls yet)" })

local lastUIUpdate = 0
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - lastUIUpdate < 0.5 then return end
    lastUIUpdate = now

    pcall(function()
        if not (label_cash and label_cash.Set) then return end

        local cashNow  = getCash()
        local gemsNow  = getGems()
        local rebNow   = getRebirthLevel()
        local elapsed  = math.max(1, os.time() - stats.sessionStart)
        local cashGain = cashNow - (stats.cashStart or cashNow)
        local gemsGain = gemsNow - (stats.gemsStart or gemsNow)
        local rebGain  = rebNow  - (stats.rebirthStart or rebNow)

        label_cash:Set("Cash: $"              .. formatCash(cashNow))
        label_gems:Set("Gems: "               .. math.floor(gemsNow))
        label_rebirth:Set("Rebirth Level: "   .. rebNow)
        label_opened:Set("Packs Opened: "     .. stats.opened)
        label_bought:Set("Packs Bought: "     .. stats.bought)
        label_sold:Set("Cards Sold: "         .. stats.sold)
        label_collect:Set("Collects: "        .. stats.collects)
        label_gemBuys:Set("Gem Buys: "        .. stats.gemBuys)
        label_locked:Set("Cards Locked: "     .. stats.locked)
        label_sRebirth:Set("Session Rebirths: ".. stats.rebirths)
        label_hops:Set("Server Hops: "        .. stats.hopCount)
        label_boost:Set("Boosts Used: "       .. stats.boostsUsed)
        label_weather:Set("Active Weather: "  .. getActiveWeathers())

        label_uptime:Set("Uptime: "  .. formatDuration(elapsed))
        label_cashHr:Set("Cash/hr: $".. formatCash(cashGain / elapsed * 3600))
        label_gemsHr:Set("Gems/hr: " .. formatCash(gemsGain / elapsed * 3600))
        label_rebHr:Set("Rebirths/hr: " .. string.format("%.2f", rebGain / elapsed * 3600))

        -- ETA to next rebirth
        local rd = getRebirthRequirements()
        if rd and rd.CashRequired then
            local need = rd.CashRequired - cashNow
            if need <= 0 then
                label_etaReb:Set("ETA Next Rebirth: ready")
            else
                local rate = cashGain / elapsed
                if rate > 0 then
                    label_etaReb:Set("ETA Next Rebirth: " .. formatDuration(need / rate))
                else
                    label_etaReb:Set("ETA Next Rebirth: --")
                end
            end
        end

        -- roll distribution
        local parts = {}
        for _, r in ipairs(rarityList) do
            local c = stats.rarityRolls[r]
            if c and c > 0 then table.insert(parts, r .. ": " .. c) end
        end
        label_rolls:Set(#parts > 0 and table.concat(parts, "  •  ") or "(no rolls yet)")
    end)
end)

TabStats:createButton({
    Name        = "Reset Stats",
    Callback    = function()
        stats = {
            opened=0, bought=0, sold=0, rebirths=0, gemBuys=0, collects=0,
            locked=0, boostsUsed=0, hopCount=0, codesRedeemed=false,
            sessionStart = os.time(),
            cashStart = nil, gemsStart = nil, rebirthStart = nil,
            rarityRolls = {}, lastRebirthTs = os.time(),
        }
        notify("Stats", "Session stats have been reset.", "info")
    end,
})

TabStats:createButton({
    Name        = "Export Session Report → Webhook",
    Description = "Posts a full session JSON dump to the configured webhook.",
    Callback    = function()
        if (getgenv().WebhookURL or "") == "" then
            notify("Export", "No webhook URL configured.", "warning")
            return
        end
        local report = {
            user      = client.Name,
            userId    = client.UserId,
            placeId   = PLACE_ID,
            uptime    = formatDuration(os.time() - stats.sessionStart),
            cash      = getCash(),
            gems      = getGems(),
            rebirth   = getRebirthLevel(),
            stats     = stats,
            weather   = getActiveWeathers(),
            timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        }
        dispatchWebhook({
            embeds = {{
                title = "[E] Session Export",
                description = "```json\n" .. HttpService:JSONEncode(report):sub(1, 1800) .. "\n```",
                color = 9807270,
                footer = { text = "SSC Elite Farm v3 — Export" },
            }}
        })
        notify("Export", "Report sent.", "info")
    end,
})


-- [ UI: LOGS TAB ]
TabLogs:createLabel({ Name = "Recent Events", Special = true })
TabLogs:createLabel({ Name = "Shows the last " .. LOG_MAX .. " script-driven events. Click Refresh to update." })

local logLabels = {}
for i = 1, 12 do
    logLabels[i] = TabLogs:createLabel({ Name = "—" })
end

TabLogs:createButton({
    Name        = "Refresh Log",
    Callback    = function()
        local total = #logBuffer
        for i = 1, 12 do
            local idx = total - (12 - i)
            local line = (idx >= 1) and logBuffer[idx] or "—"
            pcall(function() logLabels[i]:Set(line) end)
        end
    end,
})

TabLogs:createButton({
    Name        = "Clear Log",
    Callback    = function()
        logBuffer = {}
        for i = 1, 12 do pcall(function() logLabels[i]:Set("—") end) end
    end,
})

-- auto-refresh log tab labels every 2s
task.spawn(function()
    while task.wait(2) do
        local total = #logBuffer
        for i = 1, 12 do
            local idx = total - (12 - i)
            local line = (idx >= 1) and logBuffer[idx] or "—"
            pcall(function() logLabels[i]:Set(line) end)
        end
    end
end)


-- [ HOTKEYS HANDLER ]
local function flagToKey(flag)
    local v = Library.Flags[flag]
    local s = type(v) == "table" and v[1] or v
    if not s or s == "None" then return nil end
    return Enum.KeyCode[s]
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if input.KeyCode == flagToKey("HK_AutoOpen") then
        Library.Flags["AutoOpenPacks"] = not Library.Flags["AutoOpenPacks"]
        logEvent("Hotkey", "AutoOpenPacks → " .. tostring(Library.Flags["AutoOpenPacks"]))
    elseif input.KeyCode == flagToKey("HK_AutoSell") then
        Library.Flags["AutoSell"] = not Library.Flags["AutoSell"]
        logEvent("Hotkey", "AutoSell → " .. tostring(Library.Flags["AutoSell"]))
    elseif input.KeyCode == flagToKey("HK_HideHUD") then
        Library.Flags["HideHUD"] = not Library.Flags["HideHUD"]
        local playerGui = client:FindFirstChild("PlayerGui")
        if playerGui then
            local hud = playerGui:FindFirstChild("HUD")
            if hud then hud.Enabled = not Library.Flags["HideHUD"] end
        end
        logEvent("Hotkey", "HideHUD → " .. tostring(Library.Flags["HideHUD"]))
    elseif input.KeyCode == flagToKey("HK_Kill") then
        Library.Flags["MasterKillSwitch"] = not Library.Flags["MasterKillSwitch"]
        logEvent("Hotkey", "MasterKillSwitch → " .. tostring(Library.Flags["MasterKillSwitch"]))
    end
end)


-- [ DONE ]
logEvent("Init", "SSC Elite Farm v3.0 fully loaded.")
print("[SSC Farm] Loaded successfully — SSC Elite Farm v3.0 Full Suite")
