-- // ============================================
-- // Spin a Soccer Card
-- // Library: Versus Airlines (NewLibrary.lua)
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

local client   = Players.LocalPlayer
local PLACE_ID = game.PlaceId


-- [ CONSTANTS ]
local LIBRARY_URL      = "https://versusairlines.top/scripts/NewLibrary.lua"
local ROBLOX_THUMBS    = "https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false"
local ROBLOX_AVATAR    = "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png"
local SERVERS_API      = "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"

local COLLECT_DEFAULT       = 3
local STATS_DELAY_DEFAULT   = 15
local MIN_GEMS_DEFAULT      = 100
local SELL_DEFAULT          = "Silver"
local RARITY_THRESH_DEFAULT = "Mythic"
local REBIRTH_CD_NORMAL     = 15
local REBIRTH_CD_FORCE      = 30
local LOG_MAX               = 200

local GEM_SHOP_MAP = {
    ["Lucky Item"]      = "lucky",
    ["Auto Equip Best"] = "fixed_1",
    ["Auto Skip"]       = "fixed_2",
    ["Inventory +500"]  = "fixed_3",
    ["Scarlet Item"]    = "scarlet",
}

local BLOCKED_IDS = { LocalCard = true, OwnerVulnone = true }


-- [ HTTP REQUEST ]
local req = (syn and syn.request) or (http and http.request)
         or http_request or request


-- [ ANTI AFK ]
client.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1 + math.random())
end)


-- [ POPUP BLOCKER HOOK ]
local gm = getrawmetatable(game)
setreadonly(gm, false)
local oldNamecall = gm.__namecall

gm.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and _G.SSC_DisablePopups then
        local isMPS = typeof(self) == "Instance"
                   and (self.ClassName == "MarketplaceService" or self == MPS)
        if isMPS then
            if method == "PromptProductPurchase"
            or method == "PromptGamePassPurchase"
            or method == "PromptPurchase" then
                return
            end
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(gm, true)


-- [ LIBRARY ]
print("[SSC] Loading library...")
local Library = loadstring(game:HttpGet(LIBRARY_URL))()
local Setup   = Library:Setup({
    Location          = CoreGui,
    OpenCloseLocation = "Bottom Left",
})
print("[SSC] Library OK")


-- [ HELPERS ]
local function notify(title, desc, style)
    pcall(function()
        Library:createDisplayMessage(title, desc, { { text = "OK" } }, style or "info")
    end)
end

local logBuffer = {}
local function logEvent(category, msg)
    local line = string.format("[%s] [%s] %s", os.date("%H:%M:%S"), category, msg)
    table.insert(logBuffer, line)
    if #logBuffer > LOG_MAX then table.remove(logBuffer, 1) end
    print("[SSC] " .. line)
end

local function hwait(a, b)
    if Library.Flags["HumanizedDelays"] then
        task.wait(a + (b - a) * math.random())
    else
        task.wait(a)
    end
end

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


-- [ NETWORKER + REMOTES ]
print("[SSC] Resolving Networker...")
local Networker = require(RS.Source.Shared.Networker)

-- Fast path: try RS.Remotes folder first (instant), then Networker (slow w/ WaitForChild)
local function getRemote(name)
    local folder = RS:FindFirstChild("Remotes")
    if folder then
        local r = folder:FindFirstChild(name)
        if r then return r end
    end
    local result, done = nil, false
    task.spawn(function()
        local ok, r = pcall(function() return Networker.get_remote(name) end)
        if ok and r then result = r end
        done = true
    end)
    local t = 0
    while not done and t < 1.5 do task.wait(0.05) t = t + 0.05 end
    return result
end

local function getFunction(name)
    local folder = RS:FindFirstChild("Remotes")
    if folder then
        local r = folder:FindFirstChild(name)
        if r then return r end
    end
    local result, done = nil, false
    task.spawn(function()
        local ok, r = pcall(function() return Networker.get_remotefunction(name) end)
        if ok and r then result = r end
        done = true
    end)
    local t = 0
    while not done and t < 1.5 do task.wait(0.05) t = t + 0.05 end
    return result
end

-- Core remotes (must exist). Fetched in parallel; loop blocks until OpenPack is ready.
local CORE_REMOTES = {
    "OpenPack","BuyPack","EquipCard","CollectSlot","SellCards","DeletePacks",
    "Rebirth","BuyGemShopItem","ClaimAllIndexGems","DailyReward",
    "OfflineReward","SpinWheel","RedeemCode",
    -- Native game features (confirmed via dump):
    "PackSettings",       -- server-side auto-open + hide animation
    "Tournament",         -- join + equip_best
    "UsePotion",          -- weather potions
    "Notification",       -- listen for game notifications
}
-- Optional remotes (real names from dump). Lazy-loaded.
local OPTIONAL_REMOTES = {
    "PerformWish","Wish",
    "ApplyTrophy","DestroyTrophy","ApplyWorldCupTrophy","CraftTrophy",
    "TournamentState","TournamentTick","TournamentServer",
    "RequestFriendsLeaderboard",
    "LockCard","UnlockCard",
}
local FUNCS = { "SpinWheelData" }

local remotes, funcs = {}, {}

-- parallel core fetch
do
    print("[SSC] Fetching " .. #CORE_REMOTES .. " core remotes...")
    local pending = #CORE_REMOTES + #FUNCS
    for _, n in ipairs(CORE_REMOTES) do
        task.spawn(function()
            remotes[n] = getRemote(n)
            pending = pending - 1
        end)
    end
    for _, n in ipairs(FUNCS) do
        task.spawn(function()
            funcs[n] = getFunction(n)
            pending = pending - 1
        end)
    end
    local t = 0
    while pending > 0 and t < 5 do task.wait(0.05) t = t + 0.05 end

    -- Block specifically until OpenPack is ready (critical for auto-roll)
    t = 0
    while not remotes.OpenPack and t < 5 do
        remotes.OpenPack = getRemote("OpenPack")
        task.wait(0.1)
        t = t + 0.1
    end
    print("[SSC] Core remotes ready. OpenPack: " .. tostring(remotes.OpenPack ~= nil))
end

-- lazy resolver for optional remotes
local lazyResolved = {}
setmetatable(remotes, { __index = function(t, k)
    for _, n in ipairs(OPTIONAL_REMOTES) do
        if n == k then
            if lazyResolved[k] then return rawget(t, k) end
            lazyResolved[k] = true
            local r = getRemote(k)
            rawset(t, k, r)
            return r
        end
    end
    return nil
end })


-- [ CONFIGS ]
print("[SSC] Loading configs...")
local PackConfig    = require(RS.Source.Shared.Configs.PackConfig)
local CardConfig    = require(RS.Source.Shared.Configs.CardConfig)
local RebirthConfig = require(RS.Source.Shared.Configs.RebirthConfig)
local PlayerStore   = require(RS.Source.Shared.State.PlayerStore)
local WeatherStore  = nil
pcall(function() WeatherStore = require(RS.Source.Shared.State.WeatherStore) end)

-- Optional configs (exist per dump)
local TournamentConfig, TrophyConfig, PotionConfig = nil, nil, nil
pcall(function() TournamentConfig = require(RS.Source.Shared.Configs.TournamentConfig) end)
pcall(function() TrophyConfig     = require(RS.Source.Shared.Configs.TrophyConfig) end)
pcall(function() PotionConfig     = require(RS.Source.Shared.Configs.PotionConfig) end)

-- Build potion list from config
local potionList = {}
if PotionConfig and PotionConfig.Potions then
    for name in pairs(PotionConfig.Potions) do
        table.insert(potionList, name)
    end
    table.sort(potionList)
end
if #potionList == 0 then
    potionList = { "Snowstorm Potion", "Thunderstorm Potion", "Toxic Rain Potion", "Blood Moon Potion", "Solar Eclipse Potion" }
end


-- [ SESSION STATS ]
local stats = {
    opened=0, bought=0, sold=0, rebirths=0, gemBuys=0, collects=0,
    locked=0, wishes=0, trophiesCrafted=0, hopCount=0,
    sessionStart=os.time(),
    cashStart=nil, gemsStart=nil, rebirthStart=nil,
    rarityRolls={}, lastRebirthTs=os.time(),
}

local tournamentState = {
    inTournament=false, placement=nil, startedAt=nil,
    joins=0, wins=0, lastTick=0,
}


-- [ PLAYER DATA ]
local function getPlayerData()
    local ok, state = pcall(function() return PlayerStore() end)
    if not ok or not state or not state.players then return nil end
    return state.players[tostring(client.UserId)]
end

local function getInventory()  local d = getPlayerData() return d and d.inventory or {} end
local function getSlots()      local d = getPlayerData() return d and d.slots     or {} end
local function getCash()       local d = getPlayerData() return d and d.cash      or 0  end
local function getGems()       local d = getPlayerData() return d and d.gems      or 0  end
local function getRebirthLevel() local d = getPlayerData() return d and d.rebirth or 0 end


-- [ WEATHER ]
local function getActiveWeathersList()
    if not WeatherStore then return {} end
    local ok, state = pcall(function() return WeatherStore() end)
    if not ok or not state or type(state.activeWeathers) ~= "table" then return {} end
    local active = {}
    local now = Workspace:GetServerTimeNow()
    for w, data in pairs(state.activeWeathers) do
        if data and data.endTime and data.endTime > now then
            table.insert(active, w)
        end
    end
    return active
end

local function getActiveWeathers()
    local a = getActiveWeathersList()
    return (#a > 0) and table.concat(a, ", ") or "None"
end

local function weatherIsActive(name)
    for _, w in ipairs(getActiveWeathersList()) do if w == name then return true end end
    return false
end


-- [ PACK LIST ]
local function getPackList()
    local list = {}
    for packName, packData in pairs(PackConfig.Packs or {}) do
        if not packData.HideFromShop then table.insert(list, packName) end
    end
    table.sort(list, function(a, b)
        local pa, pb = PackConfig.Packs[a], PackConfig.Packs[b]
        return (pa and pa.LayoutOrder or 999) < (pb and pb.LayoutOrder or 999)
    end)
    return list
end

local function packPrice(name)
    local p = PackConfig.Packs[name]
    return p and (p.Price or 0) or 0
end


-- [ RARITY SYSTEM ]
local rarityOrder = {
    ["Bronze"]=1,["Silver"]=2,["Gold"]=3,["Legendary"]=4,["Mythic"]=5,
    ["Azure Zenith"]=6,["Crimson Zenith"]=7,["Divine"]=8,["Primordial"]=9,
    ["Oblivion"]=10,["Eternity"]=11,["Astral"]=12,["Sovereign"]=13,
    ["Vandal"]=14,["The Monarch"]=15,["Tyrant"]=16,["Verdant"]=17,
    ["Silvane"]=18,["Lunar"]=19,["Solar"]=20,["Nether"]=21,["Aether"]=22,
    ["Player of the Month"]=23,["Exclusive"]=24,["Secret Exclusive"]=25,
}
do
    local maxIdx = 0
    for _, v in pairs(rarityOrder) do if v > maxIdx then maxIdx = v end end
    for _, cfg in pairs(CardConfig.Cards or {}) do
        local r = cfg and cfg.Rarity
        if r and not rarityOrder[r] then maxIdx = maxIdx + 1 rarityOrder[r] = maxIdx end
    end
end
local rarityList = {}
for n in pairs(rarityOrder) do table.insert(rarityList, n) end
table.sort(rarityList, function(a, b) return rarityOrder[a] < rarityOrder[b] end)

local function getRarityLevel(r) return rarityOrder[r] or 0 end


-- [ CARD ID LIST (Legendary+, capped) ]
local CARD_LIST_MIN_RARITY = 4
local CARD_LIST_HARD_CAP   = 300
local cardIdList, cardDisplayToId = {}, {}
do
    local temp = {}
    for id, cfg in pairs(CardConfig.Cards or {}) do
        local lvl = (cfg and rarityOrder[cfg.Rarity]) or 0
        if lvl >= CARD_LIST_MIN_RARITY then
            local label = string.format("%s [%s]", (cfg.DisplayName or id), cfg.Rarity or "?")
            table.insert(temp, { label=label, id=id, lvl=lvl, name=cfg.DisplayName or id })
        end
    end
    table.sort(temp, function(a, b)
        if a.lvl ~= b.lvl then return a.lvl > b.lvl end
        return a.name < b.name
    end)
    for i = 1, math.min(#temp, CARD_LIST_HARD_CAP) do
        table.insert(cardIdList, temp[i].label)
        cardDisplayToId[temp[i].label] = temp[i].id
    end
end
if #cardIdList == 0 then table.insert(cardIdList, "(no cards found)") end


-- [ REBIRTH ]
local function getRebirthRequirements()
    local d = getPlayerData()
    if not d then return nil end
    local nl = (d.rebirth or 0) + 1
    local ok, rd = pcall(function()
        return RebirthConfig and RebirthConfig.GetRebirth and RebirthConfig.GetRebirth(nl)
    end)
    return (ok and rd) or nil
end

local function canRebirth()
    local maxR = 999
    pcall(function()
        if RebirthConfig and RebirthConfig.GetMaxRebirth then
            maxR = RebirthConfig.GetMaxRebirth()
        end
    end)
    local d = getPlayerData()
    if not d or (d.rebirth or 0) >= maxR then return false end
    local rd = getRebirthRequirements()
    if not rd then return false end
    if (d.cash or 0) < (rd.CashRequired or math.huge) then return false end
    if (rd.GemsRequired or 0) > 0 and (d.gems or 0) < rd.GemsRequired then return false end
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
    local candidates = {}
    for _, card in ipairs(inventory) do
        if card and card.id and card.uuid and not BLOCKED_IDS[card.id]
           and not card.throneCard and not card.locked then
            local cfg = CardConfig.Cards[card.id]
            table.insert(candidates, {
                uuid=card.uuid, id=card.id, income=(cfg and cfg.IncomeRate or 0),
            })
        end
    end
    table.sort(candidates, function(a, b) return a.income > b.income end)

    local slotCount = 0
    for _ in pairs(slots) do slotCount = slotCount + 1 end
    if slotCount == 0 then slotCount = 6 end

    local equipped = 0
    for i = 1, math.min(#candidates, slotCount) do
        local cand = candidates[i]
        local sl   = slots[tostring(i)] or slots[i]
        local curIncome = 0
        if sl and sl.card then
            local cfg = CardConfig.Cards[sl.card.id]
            curIncome = cfg and cfg.IncomeRate or 0
        end
        if cand.income > curIncome then
            remotes.EquipCard:FireServer(cand.uuid, i)
            equipped = equipped + 1
            hwait(0.08, 0.18)
        end
    end
    return equipped > 0
end


-- [ WHITELIST / PROTECTED ]
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

local function dispatchWebhook(payload)
    local url = getgenv().WebhookURL or ""
    if url == "" or not req then return end
    local pingId = getgenv().WebhookPingID or ""
    if pingId ~= "" then payload.content = "<@" .. pingId .. ">" end
    pcall(function()
        req({
            Url     = url,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode(payload),
        })
    end)
end


-- [ OPENPACK LISTENER (rare rolls + hunt + auto-lock + tracking) ]
local huntFound = false
if remotes.OpenPack then
    remotes.OpenPack.OnClientEvent:Connect(function(img, cData, color, uuid, chances, isNew, pName)
        if img == "x" or type(cData) ~= "table" then return end

        local r = cData.Rarity or "Common"
        stats.rarityRolls[r] = (stats.rarityRolls[r] or 0) + 1

        -- Hunting
        if Library.Flags["HuntingMode"] then
            local tf = Library.Flags["HuntTarget"]
            local tl = type(tf) == "table" and tf[1] or tf
            local tid = cardDisplayToId[tl or ""]
            if tid and cData.id == tid and not huntFound then
                huntFound = true
                logEvent("Hunt", "Target found: " .. (cData.DisplayName or cData.id))
                Library.Flags["AutoOpenPacks"] = false
                Library.Flags["AutoBuyPacks"]  = false
                if remotes.LockCard and uuid then
                    pcall(function() remotes.LockCard:FireServer(uuid) end)
                end
                if Library.Flags["WebhookRareRolls"] then
                    dispatchWebhook({ embeds = {{
                        title = "🎯 Hunt Complete!",
                        description = "Target card rolled.",
                        color = 16711680,
                        fields = {
                            { name="Card", value=cData.DisplayName or cData.id, inline=false },
                            { name="Pack", value=pName or "?", inline=true },
                        },
                        footer = { text = "Spin a Soccer Card" },
                    }}})
                end
                notify("Hunt", "Target obtained!", "info")
            end
        end

        -- Rare-roll webhook
        if Library.Flags["WebhookRareRolls"] then
            local tf = Library.Flags["WebhookRarityThresh"]
            local tn = (type(tf)=="string" and tf) or (type(tf)=="table" and tf[1]) or RARITY_THRESH_DEFAULT
            if getRarityLevel(r) >= getRarityLevel(tn) then
                local thumbUrl = ""
                local imageId = string.match(cData.ImageId or "", "%d+")
                if imageId then
                    pcall(function()
                        local rs = req({ Url=string.format(ROBLOX_THUMBS, imageId), Method="GET" })
                        if rs and rs.Body then
                            local d = HttpService:JSONDecode(rs.Body)
                            if d.data and d.data[1] then thumbUrl = d.data[1].imageUrl or "" end
                        end
                    end)
                end
                local cfg = CardConfig.Cards[cData.id]
                local inc = cfg and cfg.IncomeRate or cData.IncomeRate or 0
                dispatchWebhook({ embeds = {{
                    title = "✨ Rare Card Rolled!",
                    color = 16766720,
                    thumbnail = { url = thumbUrl },
                    author = { name = client.Name, icon_url = string.format(ROBLOX_AVATAR, client.UserId) },
                    fields = {
                        { name="Card",   value = cData.DisplayName or cData.id, inline=true },
                        { name="Rarity", value = r, inline=true },
                        { name="Pack",   value = pName or "?", inline=true },
                        { name="Income", value = "$" .. formatCash(inc) .. "/s", inline=true },
                        { name="New?",   value = isNew and "Yes" or "No", inline=true },
                    },
                    footer = { text = "Spin a Soccer Card • " .. os.date("%H:%M:%S") },
                }}})
            end
        end

        -- Auto-lock rares
        if Library.Flags["AutoLock"] then
            local lf = Library.Flags["AutoLockRarity"]
            local ln = (type(lf)=="string" and lf) or (type(lf)=="table" and lf[1]) or "Mythic"
            if getRarityLevel(r) >= getRarityLevel(ln) and remotes.LockCard and uuid then
                pcall(function() remotes.LockCard:FireServer(uuid) end)
                stats.locked = stats.locked + 1
            end
        end
    end)
end


-- [ SAFE EVENT-LISTENER HELPER ]
-- Only RemoteEvents have OnClientEvent. Trying to access it on a RemoteFunction
-- THROWS (not nil) — so we must check ClassName before connecting.
local function safeConnectClientEvent(remote, handler, tag)
    if not remote then return end
    local ok, cls = pcall(function() return remote.ClassName end)
    if not ok or cls ~= "RemoteEvent" then
        logEvent("Listener", (tag or "remote") .. ": not a RemoteEvent (got " .. tostring(cls) .. "), skipped.")
        return
    end
    pcall(function()
        remote.OnClientEvent:Connect(function(...) pcall(handler, ...) end)
    end)
end


-- [ GAME NOTIFICATION LISTENER ]
safeConnectClientEvent(remotes.Notification, function(data)
    if type(data) ~= "table" then return end
    local msg = tostring(data.Msg or data.msg or "")
    if msg == "" then return end
    if Library.Flags["WebhookGameNotifs"] then
        local success = (data.Success ~= false)
        dispatchWebhook({ embeds = {{
            title = success and "🟢 Game Notification" or "🔴 Game Notification",
            description = msg,
            color = success and 3066993 or 15158332,
            footer = { text = "Spin a Soccer Card • " .. os.date("%H:%M:%S") },
        }}})
    end
    logEvent("GameNotif", msg)
end, "Notification")


-- [ TOURNAMENT STATE LISTENER ]
-- TournamentState may be a RemoteFunction in some versions of the game — guard for that.
safeConnectClientEvent(remotes.TournamentState or remotes.Tournament, function(data)
    if type(data) ~= "table" then return end
    if data.placement then tournamentState.placement = data.placement end
    if data.active ~= nil then
        if data.active and not tournamentState.inTournament then
            tournamentState.inTournament = true
            tournamentState.startedAt    = os.time()
            logEvent("Tournament", "Joined")
        elseif not data.active and tournamentState.inTournament then
            tournamentState.inTournament = false
            if (tournamentState.placement or 999) <= 3 then
                tournamentState.wins = tournamentState.wins + 1
            end
            logEvent("Tournament", "Ended — placement " .. tostring(tournamentState.placement))
            if Library.Flags["WebhookTournament"] then
                dispatchWebhook({ embeds = {{
                    title = "🏆 Tournament Finished",
                    description = "Placement: **" .. tostring(tournamentState.placement or "?") .. "**",
                    color = (tournamentState.placement or 999) <= 3 and 16766720 or 7506394,
                    footer = { text = "Spin a Soccer Card" },
                }}})
            end
        end
    end
end, "TournamentState")

safeConnectClientEvent(remotes.TournamentTick, function()
    tournamentState.lastTick = os.clock()
end, "TournamentTick")


-- [ SERVER HOP ]
local function fetchServers()
    if not req then return nil end
    local result = nil
    pcall(function()
        local r = req({ Url = string.format(SERVERS_API, PLACE_ID), Method = "GET" })
        if r and r.Body then
            local d = HttpService:JSONDecode(r.Body)
            result = d and d.data
        end
    end)
    return result
end

local function serverHop(mode)
    local servers = fetchServers()
    if not servers or #servers == 0 then
        notify("Hop", "Failed to fetch server list.", "warning") return
    end
    local current, valid = game.JobId, {}
    for _, s in ipairs(servers) do
        if s.id ~= current and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
            table.insert(valid, s)
        end
    end
    if #valid == 0 then notify("Hop", "No alternate servers.", "warning") return end
    table.sort(valid, function(a, b)
        if mode == "low_ping" then return (a.ping or 9999) < (b.ping or 9999)
        elseif mode == "random" then return math.random() < 0.5
        else return (a.playing or 0) < (b.playing or 0) end
    end)
    stats.hopCount = stats.hopCount + 1
    pcall(function() TeleportService:TeleportToPlaceInstance(PLACE_ID, valid[1].id, client) end)
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


-- [ INVENTORY HELPERS ]
local function rarityCounts()
    local out = {}
    for _, card in ipairs(getInventory()) do
        local cfg = CardConfig.Cards[card.id]
        local r = (cfg and cfg.Rarity) or "Unknown"
        out[r] = (out[r] or 0) + 1
    end
    return out
end


-- [ NOTIFICATION SUPPRESSOR (gentle - only kills floating earnings, NOT camera) ]
task.spawn(function()
    while task.wait(0.4) do
        if not Library.Flags["HideEarningsFloats"] then else end
        local pgui = client:FindFirstChild("PlayerGui")
        if pgui then
            if Library.Flags["HideEarningsFloats"] then
                -- Only target the "+$58.50M" floating cash labels stacking up.
                local notif = pgui:FindFirstChild("Notification")
                if notif then
                    for _, d in ipairs(notif:GetDescendants()) do
                        if d:IsA("TextLabel") then
                            local t = d.Text or ""
                            if t:find("^%+%$") or t:find("^%-%$") or t:find("^%+%d") then
                                pcall(function() d.Visible = false end)
                            end
                        end
                    end
                end
            end

            if Library.Flags["DisableNotifs"] then
                local n = pgui:FindFirstChild("Notification")
                if n and n:IsA("ScreenGui") then n.Enabled = false end
            end

            if Library.Flags["DisablePopups"] then
                for _, name in ipairs({ "RebirthPrompt","OfflineRewardPrompt","BoothPurchasePrompt" }) do
                    local g = pgui:FindFirstChild(name)
                    if g and g:IsA("ScreenGui") and g.Enabled then g.Enabled = false end
                end
            end
        end
    end
end)


-- [ NATIVE PACK SETTINGS (server-side hideAnimation toggle) ]
-- The script's own AutoOpenPacks loop in the Packs tab is faster than
-- the game's native PackAutoOpen — so we only mirror the hideAnimation flag.
local lastPackHide = nil

local function syncPackSettings()
    if not remotes.PackSettings then return end
    local hide = Library.Flags["PackHideAnim"] == true
    if hide ~= lastPackHide then
        lastPackHide = hide
        pcall(function() remotes.PackSettings:FireServer("packHideAnimation", hide) end)
        logEvent("PackSettings", "hideAnimation = " .. tostring(hide))
    end
end

task.spawn(function()
    while task.wait(1) do pcall(syncPackSettings) end
end)


-- [ MAIN LOOP ]
local timers = {
    collect=0, sell=0, delPacks=0, gemShop=0, rebirth=0, equip=0,
    index=0, spin=0, daily=0, offline=0, webhook=os.clock(),
    hourly=os.clock(), wish=0, trophy=0, hop=0,
    tourneyJoin=0, tourneyEquip=0, potion=0,
}

task.spawn(function()
    while task.wait(0.2) do
        if Library.Flags["MasterKillSwitch"] then else
        local now = os.clock()
        _G.SSC_DisablePopups = Library.Flags["DisablePopups"]

        if not stats.cashStart    then stats.cashStart    = getCash() end
        if not stats.gemsStart    then stats.gemsStart    = getGems() end
        if not stats.rebirthStart then stats.rebirthStart = getRebirthLevel() end

        -- Stats webhook
        if Library.Flags["WebhookStats"] then
            local sd = Library.Flags["WebhookStatsDelay"] or STATS_DELAY_DEFAULT
            if (now - timers.webhook) >= (sd * 60) then
                timers.webhook = now
                local elapsed   = os.time() - stats.sessionStart
                local cashGain  = getCash() - (stats.cashStart or 0)
                local cashPerHr = elapsed > 0 and (cashGain/elapsed*3600) or 0
                local packsPerHr = elapsed > 0 and (stats.opened/elapsed*3600) or 0
                local reb = getRebirthLevel()
                local color = 3447003
                if reb >= 50 then color = 16766720
                elseif reb >= 25 then color = 10181046
                elseif reb >= 10 then color = 3066993 end
                local topR, topC = "—", 0
                for k, v in pairs(stats.rarityRolls) do if v > topC then topR, topC = k, v end end

                dispatchWebhook({ embeds = {{
                    title = "📊 Spin a Soccer Card — Session",
                    color = color,
                    author = { name = client.Name, icon_url = string.format(ROBLOX_AVATAR, client.UserId) },
                    thumbnail = { url = string.format(ROBLOX_AVATAR, client.UserId) },
                    fields = {
                        { name="💰 Cash",       value="$" .. formatCash(getCash()), inline=true },
                        { name="💎 Gems",       value=formatCash(getGems()),        inline=true },
                        { name="🌟 Rebirth",    value=tostring(reb),                inline=true },
                        { name="📦 Packs Open", value=formatCash(stats.opened),     inline=true },
                        { name="📦 Per Hour",   value=formatCash(packsPerHr),       inline=true },
                        { name="💵 Cash / hr",  value="$" .. formatCash(cashPerHr), inline=true },
                        { name="🎯 Top Rarity", value=topR .. " (" .. topC .. ")",  inline=true },
                        { name="🏆 Tourneys",   value=tournamentState.joins .. " / " .. tournamentState.wins .. " 🥉+", inline=true },
                        { name="⏱️ Uptime",     value=formatDuration(elapsed),      inline=true },
                        { name="🌦️ Weather",    value=getActiveWeathers(),          inline=false },
                    },
                    footer = { text = "Spin a Soccer Card • " .. os.date("%Y-%m-%d %H:%M:%S") },
                }}})
            end
        end

        -- Hourly summary
        if Library.Flags["WebhookHourly"] and (now - timers.hourly) >= 3600 then
            timers.hourly = now
            local elapsed = os.time() - stats.sessionStart
            dispatchWebhook({ embeds = {{
                title = "⏰ Hourly Summary",
                description = string.format(
                    "**Packs:** %d opened, %d bought\n**Sold:** %d cards\n**Rebirths:** %d\n**Wishes:** %d • **Trophies:** %d\n**Hops:** %d • **Tourneys:** %d (top-3: %d)\n**Uptime:** %s",
                    stats.opened, stats.bought, stats.sold, stats.rebirths,
                    stats.wishes, stats.trophiesCrafted, stats.hopCount,
                    tournamentState.joins, tournamentState.wins, formatDuration(elapsed)
                ),
                color = 10181046,
                footer = { text = "Spin a Soccer Card" },
            }}})
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
                local ok, sd = pcall(function() return funcs.SpinWheelData:InvokeServer() end)
                if ok and type(sd) == "table" then
                    if sd.canClaimFree then remotes.SpinWheel:FireServer("claim_free") end
                    if type(sd.spins) == "number" and sd.spins > 0 then remotes.SpinWheel:FireServer("spin") end
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

        -- Auto Wish (uses real remote: PerformWish)
        if Library.Flags["AutoWish"] and (now - timers.wish) >= 12 then
            timers.wish = now
            pcall(function()
                if remotes.PerformWish then
                    remotes.PerformWish:FireServer()
                    stats.wishes = stats.wishes + 1
                end
            end)
        end

        -- Auto Craft Trophy (uses real remote: CraftTrophy)
        if Library.Flags["AutoCraftTrophy"] and (now - timers.trophy) >= 20 then
            timers.trophy = now
            pcall(function()
                if remotes.CraftTrophy then
                    remotes.CraftTrophy:FireServer()
                    stats.trophiesCrafted = stats.trophiesCrafted + 1
                end
            end)
        end

        -- Auto Apply Trophies to best cards (uses real remote: ApplyTrophy)
        if Library.Flags["AutoApplyTrophies"] and (now - timers.trophy) >= 25 then
            pcall(function()
                if not remotes.ApplyTrophy then return end
                local data = getPlayerData()
                if not data then return end
                local trophies = data.trophies or {}
                local slots    = data.slots    or {}

                local trophyList = {}
                for _, tr in pairs(trophies) do
                    if type(tr) == "table" and tr.uuid and not tr.equipped then
                        table.insert(trophyList, { uuid=tr.uuid, val=(tr.value or tr.tier or 0) })
                    end
                end
                table.sort(trophyList, function(a, b) return a.val > b.val end)

                local slotList = {}
                for _, sd in pairs(slots) do
                    if sd and sd.card and sd.card.uuid then
                        local cfg = CardConfig.Cards[sd.card.id]
                        table.insert(slotList, { uuid=sd.card.uuid, inc=(cfg and cfg.IncomeRate or 0) })
                    end
                end
                table.sort(slotList, function(a, b) return a.inc > b.inc end)

                for i = 1, math.min(#trophyList, #slotList) do
                    remotes.ApplyTrophy:FireServer(trophyList[i].uuid, slotList[i].uuid)
                    hwait(0.08, 0.15)
                end
            end)
        end

        -- Auto Join Tournament (native remote: Tournament('join'))
        if Library.Flags["AutoJoinTournament"] and (now - timers.tourneyJoin) >= 15 then
            timers.tourneyJoin = now
            pcall(function()
                if not remotes.Tournament then return end
                if tournamentState.inTournament then return end
                remotes.Tournament:FireServer("join")
                tournamentState.joins = tournamentState.joins + 1
                logEvent("Tournament", "Auto-joined")
            end)
        end

        -- Auto Equip Best Tournament Team (native: Tournament('equip_best'))
        if Library.Flags["AutoEquipBestTourney"] and (now - timers.tourneyEquip) >= 30 then
            timers.tourneyEquip = now
            pcall(function()
                if remotes.Tournament then
                    remotes.Tournament:FireServer("equip_best")
                end
            end)
        end

        -- Auto Use Potion (native: UsePotion('Snowstorm Potion' etc))
        if Library.Flags["AutoUsePotion"] and (now - timers.potion) >= 300 then
            timers.potion = now
            pcall(function()
                if not remotes.UsePotion then return end
                local f = Library.Flags["PotionType"]
                local p = (type(f)=="table" and f[1]) or f or potionList[1]
                if p and p ~= "" then
                    remotes.UsePotion:FireServer(p)
                    logEvent("Potion", "Used " .. p)
                end
            end)
        end

        -- Auto Collect
        local collectDelay = Library.Flags["CollectDelay"] or COLLECT_DEFAULT
        if Library.Flags["AutoCollect"] and (now - timers.collect) >= collectDelay then
            timers.collect = now
            pcall(function()
                for slotIndex, sd in pairs(getSlots()) do
                    if sd and sd.card then
                        remotes.CollectSlot:FireServer(tonumber(slotIndex))
                        stats.collects = stats.collects + 1
                        hwait(0.04, 0.08)
                    end
                end
            end)
        end

        -- Auto Sell (with weather gate)
        local sellOK = true
        if Library.Flags["PauseSellOnLucky"] then
            for _, w in ipairs(getActiveWeathersList()) do
                if string.lower(w):find("lucky") then sellOK = false break end
            end
        end
        if Library.Flags["AutoSell"] and sellOK and (now - timers.sell) >= 8 then
            timers.sell = now
            pcall(function()
                local tf = Library.Flags["SellThreshold"]
                local tn = (type(tf)=="string" and tf) or (type(tf)=="table" and tf[1]) or SELL_DEFAULT
                local tl = getRarityLevel(tn)
                local toSell = {}
                for _, card in ipairs(getInventory()) do
                    if card and card.id and card.uuid
                       and not card.throneCard and not card.locked
                       and not isProtectedById(card.id) and not isLastCopy(card.id) then
                        local cfg = CardConfig.Cards[card.id]
                        if cfg and getRarityLevel(cfg.Rarity) < tl then
                            table.insert(toSell, card.uuid)
                        end
                    end
                end
                if #toSell > 0 then
                    remotes.SellCards:FireServer(toSell)
                    stats.sold = stats.sold + #toSell
                end
            end)
        end

        -- Auto Delete Packs
        if Library.Flags["AutoDeletePacks"] and (now - timers.delPacks) >= 10 then
            timers.delPacks = now
            pcall(function()
                local f = Library.Flags["DeletePacksList"]
                local sel = type(f) == "table" and f or {}
                if #sel > 0 and remotes.DeletePacks then remotes.DeletePacks:FireServer(sel) end
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
                local f = Library.Flags["GemShopItem"]
                local k = (type(f)=="string" and f) or (type(f)=="table" and f[1]) or "Lucky Item"
                local minG = Library.Flags["MinGems"] or MIN_GEMS_DEFAULT
                if getGems() >= minG then
                    remotes.BuyGemShopItem:FireServer(GEM_SHOP_MAP[k] or "lucky")
                    stats.gemBuys = stats.gemBuys + 1
                end
            end)
        end

        -- Auto Rebirth
        local rebCD = Library.Flags["ForceRebirth"] and REBIRTH_CD_FORCE or REBIRTH_CD_NORMAL
        if Library.Flags["AutoRebirth"] and (now - timers.rebirth) >= rebCD then
            timers.rebirth = now
            pcall(function()
                local cap = Library.Flags["RebirthCap"] or 0
                if cap > 0 and getRebirthLevel() >= cap then return end
                local should = Library.Flags["ForceRebirth"] or canRebirth()
                if not should then return end
                if Library.Flags["SmartRebirthPrep"] then pcall(equipBest) hwait(0.4, 0.6) end
                local before = getRebirthLevel()
                remotes.Rebirth:FireServer()
                task.wait(1.5)
                if getRebirthLevel() > before then
                    stats.rebirths = stats.rebirths + 1
                    local dt = os.time() - stats.lastRebirthTs
                    stats.lastRebirthTs = os.time()
                    logEvent("Rebirth", "Level " .. getRebirthLevel() .. " (Δ" .. dt .. "s)")
                    if Library.Flags["WebhookMilestones"] then
                        dispatchWebhook({ embeds = {{
                            title = "🌟 Rebirth Milestone",
                            description = "Reached Rebirth Level **" .. getRebirthLevel() .. "**",
                            color = 16753920,
                            footer = { text = "Spin a Soccer Card" },
                        }}})
                    end
                    local hopEvery = Library.Flags["HopEveryRebirths"] or 0
                    if hopEvery > 0 and (stats.rebirths % hopEvery == 0) then
                        serverHop(Library.Flags["HopMode"] or "low_players")
                    end
                end
            end)
        end
        end -- end MasterKillSwitch
    end
end)


-- [ FAST LOOP: OPEN / BUY PACKS ]
local openIdx, buyIdx = 1, 1
task.spawn(function()
    while task.wait() do
        if Library.Flags["MasterKillSwitch"] then task.wait(0.3) else

        -- weather gate
        local wOK = true
        if Library.Flags["OnlyOpenDuringWeather"] then
            local f = Library.Flags["OpenDuringWeatherList"]
            local list = type(f) == "table" and f or {}
            wOK = false
            for _, w in ipairs(list) do if weatherIsActive(w) then wOK = true break end end
        end

        -- Auto Open Packs
        if Library.Flags["AutoOpenPacks"] and wOK and remotes.OpenPack then
            local delay = Library.Flags["PackDelay"] or 0
            pcall(function()
                local f = Library.Flags["SelectedPacks"]
                local sel = type(f) == "table" and f or { tostring(f or "Bronze") }
                if #sel > 0 then
                    if openIdx > #sel then openIdx = 1 end
                    local pack = sel[openIdx]
                    openIdx = openIdx + 1
                    local pd = getPlayerData()
                    if pd and pd.packs and (pd.packs[pack] or 0) > 0 then
                        remotes.OpenPack:FireServer(pack)
                        stats.opened = stats.opened + 1
                    end
                end
            end)
            if delay > 0 then hwait(delay, delay + 0.1) end
        end

        -- Auto Buy Packs
        if Library.Flags["AutoBuyPacks"] and remotes.BuyPack then
            local delay = Library.Flags["BuyDelay"] or 0
            local reserve = Library.Flags["CashReserve"] or 0
            pcall(function()
                local cash = getCash()
                if Library.Flags["ReserveForRebirth"] then
                    local rd = getRebirthRequirements()
                    if rd and rd.CashRequired then reserve = math.max(reserve, rd.CashRequired) end
                end
                local f = Library.Flags["SelectedBuyPacks"]
                local sel = type(f) == "table" and f or { "Bronze" }
                if #sel == 0 then return end
                if Library.Flags["SmartBuy"] then
                    local sorted = {}
                    for _, p in ipairs(sel) do table.insert(sorted, { n=p, p=packPrice(p) }) end
                    table.sort(sorted, function(a, b) return a.p > b.p end)
                    for _, e in ipairs(sorted) do
                        if e.p > 0 and (cash - e.p) >= reserve then
                            remotes.BuyPack:FireServer(e.n)
                            stats.bought = stats.bought + 1
                            break
                        end
                    end
                else
                    if buyIdx > #sel then buyIdx = 1 end
                    local pn = sel[buyIdx] buyIdx = buyIdx + 1
                    local pr = packPrice(pn)
                    if pr > 0 and (cash - pr) >= reserve then
                        remotes.BuyPack:FireServer(pn)
                        stats.bought = stats.bought + 1
                    end
                end
            end)
            if delay > 0 then hwait(delay, delay + 0.15) end
        end
        end -- end MasterKillSwitch
    end
end)


-- =============================================
-- UI SECTIONS — 7 clean tabs with emojis
-- =============================================

print("[SSC] Building UI...")

local function safeSection(name)
    local ok, sec = pcall(function() return Setup:CreateSection(name) end)
    if ok and sec then return sec end
    warn("[SSC] Section failed: " .. tostring(name))
    local stub = {} setmetatable(stub, { __index = function() return function() return stub end end })
    return stub
end

local TabMain    = safeSection("🏠 Main")
local TabPacks   = safeSection("📦 Packs")
local TabAuto    = safeSection("⚡ Auto")
local TabExtra   = safeSection("🏆 Extras")
local TabClean   = safeSection("🧹 Cleanup")
local TabHooks   = safeSection("📡 Webhooks")
local TabStats   = safeSection("📊 Stats")


local pList = getPackList()
if #pList == 0 then pList = { "Bronze" } end


-- =============================================
-- 🏠 MAIN — high level controls + rebirth + safety
-- =============================================

TabMain:createLabel({ Name = "Spin a Soccer Card", Special = true })
TabMain:createLabel({ Name = "Paid Contributor :- aditya44325f" })

TabMain:createLabel({ Name = "⚠️ Global", Special = true })

TabMain:createToggle({
    Name        = "🛑 Master Kill Switch",
    flagName    = "MasterKillSwitch",
    Flag        = false,
    Description = "Pauses every auto loop instantly.",
    Callback    = function(v) logEvent("Main", v and "Killed all loops" or "Resumed loops") end,
})

TabMain:createToggle({
    Name        = "🛡️ Humanized Delays",
    flagName    = "HumanizedDelays",
    Flag        = true,
    Description = "Adds jitter to timings so remote calls aren't perfectly periodic.",
    Callback    = function() end,
})

TabMain:createToggle({
    Name        = "🔁 Auto Rejoin on Kick",
    flagName    = "AutoRejoin",
    Flag        = false,
    Description = "Auto-rejoins same place if you get kicked/disconnected.",
    Callback    = function() end,
})

TabMain:createLabel({ Name = "💰 Cash & Rebirth", Special = true })

TabMain:createToggle({
    Name        = "💵 Auto Collect Cash",
    flagName    = "AutoCollect",
    Flag        = false,
    Callback    = function() end,
})

TabMain:createSlider({
    Name        = "Collect Delay (s)",
    flagName    = "CollectDelay",
    value       = COLLECT_DEFAULT,
    minValue    = 1, maxValue = 60,
    Callback    = function() end,
})

TabMain:createToggle({
    Name        = "🌟 Auto Rebirth",
    flagName    = "AutoRebirth",
    Flag        = false,
    Callback    = function() end,
})

TabMain:createToggle({
    Name        = "🧠 Smart Rebirth Prep",
    flagName    = "SmartRebirthPrep",
    Flag        = true,
    Description = "Equips best cards before each rebirth.",
    Callback    = function() end,
})

TabMain:createSlider({
    Name        = "Stop at Rebirth Level (0=∞)",
    flagName    = "RebirthCap",
    value       = 0, minValue = 0, maxValue = 999,
    Callback    = function() end,
})

TabMain:createToggle({
    Name        = "💥 Force Rebirth",
    flagName    = "ForceRebirth",
    Flag        = false,
    Description = "Fires rebirth regardless of requirements.",
    Warning     = function() return "May rebirth before requirements are met." end,
    WarnIf      = function() return Library.Flags["ForceRebirth"] == true end,
    Callback    = function() end,
})

TabMain:createLabel({ Name = "🌐 Server Hop", Special = true })

TabMain:createDropdown({
    Name        = "Hop Mode",
    flagName    = "HopMode",
    Flag        = { "low_players" },
    List        = { "low_players","low_ping","random" },
    multi       = false,
    Callback    = function() end,
})

TabMain:createSlider({
    Name        = "Auto-Hop Every N Rebirths (0=off)",
    flagName    = "HopEveryRebirths",
    value       = 0, minValue = 0, maxValue = 50,
    Callback    = function() end,
})

TabMain:createButton({
    Name        = "🚀 Hop Now",
    Callback    = function()
        local f = Library.Flags["HopMode"]
        serverHop(type(f)=="table" and f[1] or f or "low_players")
    end,
})


-- =============================================
-- 📦 PACKS — open / buy / sell / equip / delete
-- =============================================

TabPacks:createLabel({ Name = "📤 Auto Open", Special = true })

TabPacks:createToggle({
    Name        = "Auto Open Packs",
    flagName    = "AutoOpenPacks",
    Flag        = false,
    Callback    = function() end,
})

local packDD = TabPacks:createDropdown({
    Name        = "Select Packs to Open",
    flagName    = "SelectedPacks",
    Flag        = { pList[1] },
    List        = pList,
    multi       = true,
    Callback    = function() end,
})

TabPacks:createButton({
    Name        = "Select ALL Packs",
    Callback    = function()
        pcall(function() packDD:Set(pList) end)
        Library.Flags["SelectedPacks"] = pList
        openIdx = 1
    end,
})

TabPacks:createSlider({
    Name        = "Open Delay (s, 0=instant)",
    flagName    = "PackDelay",
    value       = 0, minValue = 0, maxValue = 5,
    Callback    = function() end,
})

TabPacks:createLabel({ Name = "🛒 Auto Buy", Special = true })

TabPacks:createToggle({
    Name        = "Auto Buy Packs",
    flagName    = "AutoBuyPacks",
    Flag        = false,
    Callback    = function() end,
})

TabPacks:createToggle({
    Name        = "Smart Buy (Highest Affordable)",
    flagName    = "SmartBuy",
    Flag        = false,
    Description = "Buys the most expensive pack you can afford from the list.",
    Callback    = function() end,
})

TabPacks:createSlider({
    Name        = "Cash Reserve",
    flagName    = "CashReserve",
    value       = 0, minValue = 0, maxValue = 1000000000,
    Description = "Never spend below this balance.",
    Callback    = function() end,
})

TabPacks:createToggle({
    Name        = "Reserve Cash for Next Rebirth",
    flagName    = "ReserveForRebirth",
    Flag        = false,
    Callback    = function() end,
})

local buyDD = TabPacks:createDropdown({
    Name        = "Select Packs to Buy",
    flagName    = "SelectedBuyPacks",
    Flag        = { pList[1] },
    List        = pList,
    multi       = true,
    Callback    = function() end,
})

TabPacks:createButton({
    Name        = "Select ALL Buy Packs",
    Callback    = function()
        pcall(function() buyDD:Set(pList) end)
        Library.Flags["SelectedBuyPacks"] = pList
        buyIdx = 1
    end,
})

TabPacks:createSlider({
    Name        = "Buy Delay (s)",
    flagName    = "BuyDelay",
    value       = 0, minValue = 0, maxValue = 900,
    Callback    = function() end,
})

TabPacks:createLabel({ Name = "💸 Sell & Equip", Special = true })

TabPacks:createToggle({
    Name        = "Auto Sell Below Rarity",
    flagName    = "AutoSell",
    Flag        = false,
    Callback    = function() end,
})

TabPacks:createDropdown({
    Name        = "Sell Below:",
    flagName    = "SellThreshold",
    Flag        = { SELL_DEFAULT },
    List        = rarityList,
    multi       = false,
    Callback    = function() end,
})

TabPacks:createDropdown({
    Name        = "Protected Cards (Never Sell)",
    flagName    = "ProtectedCards",
    Flag        = {},
    List        = cardIdList,
    multi       = true,
    Description = "Whitelisted cards (Legendary+ shown, capped at 300).",
    Callback    = function() end,
})

TabPacks:createToggle({
    Name        = "Keep One of Each (Collector)",
    flagName    = "KeepOneOfEach",
    Flag        = false,
    Callback    = function() end,
})

TabPacks:createToggle({
    Name        = "Auto Equip Best Cards",
    flagName    = "AutoEquip",
    Flag        = false,
    Callback    = function() end,
})

TabPacks:createToggle({
    Name        = "Auto Lock New Rares",
    flagName    = "AutoLock",
    Flag        = false,
    Callback    = function() end,
})

TabPacks:createDropdown({
    Name        = "Lock at or Above:",
    flagName    = "AutoLockRarity",
    Flag        = { "Mythic" },
    List        = rarityList,
    multi       = false,
    Callback    = function() end,
})

TabPacks:createLabel({ Name = "🗑️ Cleanup", Special = true })

TabPacks:createToggle({
    Name        = "Auto Delete Selected Packs",
    flagName    = "AutoDeletePacks",
    Flag        = false,
    Warning     = function() return "Deleted packs cannot be recovered." end,
    WarnIf      = function() return Library.Flags["AutoDeletePacks"] == true end,
    Callback    = function() end,
})

TabPacks:createDropdown({
    Name        = "Packs to Delete",
    flagName    = "DeletePacksList",
    Flag        = {},
    List        = pList,
    multi       = true,
    Callback    = function() end,
})


-- =============================================
-- ⚡ AUTO — daily / spin / index / gems / codes / hunt
-- =============================================

TabAuto:createLabel({ Name = "🎁 Rewards", Special = true })

TabAuto:createToggle({
    Name        = "📅 Auto Daily Reward",
    flagName    = "AutoDaily",
    Flag        = false,
    Callback    = function() end,
})

TabAuto:createToggle({
    Name        = "💤 Auto Offline Reward",
    flagName    = "AutoOffline",
    Flag        = false,
    Callback    = function() end,
})

TabAuto:createToggle({
    Name        = "🎡 Auto Spin Wheel",
    flagName    = "AutoSpin",
    Flag        = false,
    Callback    = function() end,
})

TabAuto:createToggle({
    Name        = "📖 Auto Index Gems",
    flagName    = "AutoIndex",
    Flag        = false,
    Callback    = function() end,
})

TabAuto:createLabel({ Name = "💎 Gem Shop", Special = true })

TabAuto:createToggle({
    Name        = "Auto Buy Gem Item",
    flagName    = "AutoGemShop",
    Flag        = false,
    Callback    = function() end,
})

TabAuto:createDropdown({
    Name        = "Item",
    flagName    = "GemShopItem",
    Flag        = { "Lucky Item" },
    List        = { "Lucky Item","Auto Equip Best","Auto Skip","Inventory +500","Scarlet Item" },
    multi       = false,
    Callback    = function() end,
})

TabAuto:createSlider({
    Name        = "Keep Min Gems",
    flagName    = "MinGems",
    value       = MIN_GEMS_DEFAULT, minValue = 0, maxValue = 10000,
    Callback    = function() end,
})

TabAuto:createLabel({ Name = "🎯 Hunting Mode", Special = true })
TabAuto:createLabel({ Name = "Opens packs until target drops, then auto-locks and stops." })

TabAuto:createToggle({
    Name        = "Hunting Mode",
    flagName    = "HuntingMode",
    Flag        = false,
    Callback    = function(v) if v then huntFound = false end end,
})

TabAuto:createDropdown({
    Name        = "Target Card",
    flagName    = "HuntTarget",
    Flag        = { cardIdList[1] or "" },
    List        = cardIdList,
    multi       = false,
    Callback    = function() end,
})

TabAuto:createButton({
    Name        = "Reset Hunt",
    Callback    = function() huntFound = false notify("Hunt", "Reset.", "info") end,
})

TabAuto:createLabel({ Name = "🌦️ Weather Gating", Special = true })

TabAuto:createToggle({
    Name        = "Pause Selling on Lucky Weather",
    flagName    = "PauseSellOnLucky",
    Flag        = true,
    Callback    = function() end,
})

TabAuto:createToggle({
    Name        = "Only Open Packs During Weather",
    flagName    = "OnlyOpenDuringWeather",
    Flag        = false,
    Callback    = function() end,
})

TabAuto:createDropdown({
    Name        = "Open During",
    flagName    = "OpenDuringWeatherList",
    Flag        = { "Lucky" },
    List        = { "Lucky","Golden Hour","Mythic Surge","Storm","Eclipse","Blizzard","Heatwave","Solar Flare","Aurora","Meteor Shower" },
    multi       = true,
    Callback    = function() end,
})


-- =============================================
-- 🏆 EXTRAS — wishing + trophies + tournament
-- =============================================

TabExtra:createLabel({ Name = "✨ Wishing", Special = true })

TabExtra:createToggle({
    Name        = "Auto Perform Wish",
    flagName    = "AutoWish",
    Flag        = false,
    Description = "Calls PerformWish remote every ~12s.",
    Callback    = function() end,
})

TabExtra:createLabel({ Name = "🏆 Trophies", Special = true })

TabExtra:createToggle({
    Name        = "Auto Craft Trophy",
    flagName    = "AutoCraftTrophy",
    Flag        = false,
    Description = "Fires CraftTrophy remote every 20s.",
    Callback    = function() end,
})

TabExtra:createToggle({
    Name        = "Auto Apply Trophies to Best Cards",
    flagName    = "AutoApplyTrophies",
    Flag        = false,
    Description = "Pairs highest-tier trophies with your highest-income equipped cards.",
    Callback    = function() end,
})

TabExtra:createLabel({ Name = "🥇 Tournament (Native)", Special = true })
TabExtra:createLabel({ Name = "Uses real Tournament remote: 'join' and 'equip_best' actions." })

TabExtra:createToggle({
    Name        = "Auto Join Tournament",
    flagName    = "AutoJoinTournament",
    Flag        = false,
    Description = "Fires Tournament('join') every 15s when not already in one.",
    Callback    = function() end,
})

TabExtra:createToggle({
    Name        = "Auto Equip Best Tournament Team",
    flagName    = "AutoEquipBestTourney",
    Flag        = false,
    Description = "Fires Tournament('equip_best') every 30s — game auto-picks your strongest team.",
    Callback    = function() end,
})

TabExtra:createToggle({
    Name        = "Webhook on Tournament Finish",
    flagName    = "WebhookTournament",
    Flag        = false,
    Callback    = function() end,
})

local lbl_t_state = TabExtra:createLabel({ Name = "Status: idle" })
local lbl_t_join  = TabExtra:createLabel({ Name = "Joined: 0" })
local lbl_t_win   = TabExtra:createLabel({ Name = "Top-3 finishes: 0" })
local lbl_t_place = TabExtra:createLabel({ Name = "Last placement: --" })

TabExtra:createLabel({ Name = "🧪 Weather Potions", Special = true })
TabExtra:createLabel({ Name = "Uses UsePotion remote to force a weather event (300s duration)." })

TabExtra:createToggle({
    Name        = "Auto Use Selected Potion",
    flagName    = "AutoUsePotion",
    Flag        = false,
    Description = "Fires UsePotion every 300s (matches the in-game cooldown).",
    Callback    = function() end,
})

TabExtra:createDropdown({
    Name        = "Potion to Use",
    flagName    = "PotionType",
    Flag        = { potionList[1] },
    List        = potionList,
    multi       = false,
    Callback    = function() end,
})

TabExtra:createButton({
    Name        = "🧪 Use Potion Now",
    Callback    = function()
        if not remotes.UsePotion then notify("Potion", "UsePotion remote missing.", "warning") return end
        local f = Library.Flags["PotionType"]
        local p = (type(f)=="table" and f[1]) or f or potionList[1]
        pcall(function() remotes.UsePotion:FireServer(p) end)
        logEvent("Potion", "Used " .. tostring(p))
    end,
})


-- =============================================
-- 🧹 CLEANUP — native pack settings + UI suppression
-- =============================================

TabClean:createLabel({ Name = "🎬 Native Pack Animation", Special = true })
TabClean:createLabel({ Name = "Server-side toggle — no client hacks, no blur, no UI damage." })

TabClean:createToggle({
    Name        = "Hide Pack Animation (Native)",
    flagName    = "PackHideAnim",
    Flag        = false,
    Description = "Fires PackSettings('packHideAnimation', true). The game itself skips the reveal animation.",
    Callback    = function() syncPackSettings() end,
})

-- NOTE: The native PackAutoOpen toggle is intentionally NOT exposed here.
-- It's much slower than the script's own AutoOpenPacks loop (Packs tab),
-- because the game waits for each reveal cycle before queuing the next pack.

TabClean:createLabel({ Name = "💰 Earnings Floats", Special = true })

TabClean:createToggle({
    Name        = "Hide Floating +$ Toasts",
    flagName    = "HideEarningsFloats",
    Flag        = false,
    Description = "Hides only the '+$58.50M' floating labels inside the Notification GUI.",
    Callback    = function() end,
})

TabClean:createLabel({ Name = "🔕 General Suppression", Special = true })

TabClean:createToggle({
    Name        = "Disable All Notifications",
    flagName    = "DisableNotifs",
    Flag        = false,
    Callback    = function() end,
})

TabClean:createToggle({
    Name        = "Block Purchase Popups",
    flagName    = "DisablePopups",
    Flag        = false,
    Description = "Blocks Robux/gamepass/booth prompts.",
    Callback    = function(v) _G.SSC_DisablePopups = v end,
})

TabClean:createToggle({
    Name        = "Hide HUD",
    flagName    = "HideHUD",
    Flag        = false,
    Callback    = function(v)
        local pgui = client:FindFirstChild("PlayerGui")
        if pgui then local hud = pgui:FindFirstChild("HUD") if hud then hud.Enabled = not v end end
    end,
})


-- =============================================
-- 📡 WEBHOOKS
-- =============================================

TabHooks:createLabel({ Name = "Discord Integration", Special = true })

TabHooks:createInputBox({
    Name = "Webhook URL", flagName = "WebhookURL", Flag = "",
    Callback = function(v) getgenv().WebhookURL = v end,
})

TabHooks:createInputBox({
    Name = "Discord User ID (for ping)", flagName = "WebhookPingID", Flag = "",
    Callback = function(v) getgenv().WebhookPingID = tostring(v):gsub("[^%d]", "") end,
})

TabHooks:createLabel({ Name = "What to Send", Special = true })

TabHooks:createToggle({
    Name = "✨ Rare Card Rolls", flagName = "WebhookRareRolls", Flag = false,
    Callback = function() end,
})

TabHooks:createDropdown({
    Name = "Minimum Rarity", flagName = "WebhookRarityThresh",
    Flag = { RARITY_THRESH_DEFAULT }, List = rarityList, multi = false,
    Callback = function() end,
})

TabHooks:createToggle({
    Name = "📊 Periodic Stats", flagName = "WebhookStats", Flag = false,
    Callback = function() end,
})

TabHooks:createSlider({
    Name = "Stats Frequency (min)", flagName = "WebhookStatsDelay",
    value = STATS_DELAY_DEFAULT, minValue = 1, maxValue = 60,
    Callback = function() end,
})

TabHooks:createToggle({
    Name = "⏰ Hourly Summary", flagName = "WebhookHourly", Flag = false,
    Callback = function() end,
})

TabHooks:createToggle({
    Name = "🌟 Rebirth Milestones", flagName = "WebhookMilestones", Flag = false,
    Callback = function() end,
})

TabHooks:createToggle({
    Name = "🔔 In-Game Notifications (weather/events/admin)",
    flagName = "WebhookGameNotifs", Flag = false,
    Description = "Mirrors every Notification toast (Solar Eclipse, admin msgs, etc.) to Discord.",
    Callback = function() end,
})

TabHooks:createButton({
    Name = "🧪 Send Test Webhook",
    Callback = function()
        if (getgenv().WebhookURL or "") == "" then notify("Webhook", "No URL set.", "warning") return end
        dispatchWebhook({ embeds = {{
            title = "🧪 Test", description = "Spin a Soccer Card webhook is working.",
            color = 5763719,
            author = { name = client.Name, icon_url = string.format(ROBLOX_AVATAR, client.UserId) },
            footer = { text = "Spin a Soccer Card" },
        }}})
        notify("Webhook", "Sent.", "info")
    end,
})


-- =============================================
-- 📊 STATS
-- =============================================

TabStats:createLabel({ Name = "Live Session", Special = true })
local lbl_cash    = TabStats:createLabel({ Name = "💰 Cash: $0" })
local lbl_gems    = TabStats:createLabel({ Name = "💎 Gems: 0" })
local lbl_reb     = TabStats:createLabel({ Name = "🌟 Rebirth: 0" })
local lbl_open    = TabStats:createLabel({ Name = "📦 Opened: 0" })
local lbl_bought  = TabStats:createLabel({ Name = "🛒 Bought: 0" })
local lbl_sold    = TabStats:createLabel({ Name = "💸 Sold: 0" })
local lbl_lock    = TabStats:createLabel({ Name = "🔒 Locked: 0" })
local lbl_wish    = TabStats:createLabel({ Name = "✨ Wishes: 0" })
local lbl_troph   = TabStats:createLabel({ Name = "🏆 Trophies: 0" })
local lbl_hop     = TabStats:createLabel({ Name = "🌐 Hops: 0" })
local lbl_weather = TabStats:createLabel({ Name = "🌦️ Weather: None" })

TabStats:createLabel({ Name = "Rates", Special = true })
local lbl_uptime  = TabStats:createLabel({ Name = "⏱️ Uptime: 00:00:00" })
local lbl_cashHr  = TabStats:createLabel({ Name = "Cash/hr: $0" })
local lbl_gemsHr  = TabStats:createLabel({ Name = "Gems/hr: 0" })
local lbl_eta     = TabStats:createLabel({ Name = "ETA Next Rebirth: --" })

TabStats:createLabel({ Name = "Rarity Distribution", Special = true })
local lbl_rolls   = TabStats:createLabel({ Name = "(no rolls yet)" })

TabStats:createButton({
    Name = "🔄 Reset Stats",
    Callback = function()
        stats = {
            opened=0,bought=0,sold=0,rebirths=0,gemBuys=0,collects=0,
            locked=0,wishes=0,trophiesCrafted=0,hopCount=0,
            sessionStart=os.time(),cashStart=nil,gemsStart=nil,rebirthStart=nil,
            rarityRolls={},lastRebirthTs=os.time(),
        }
        tournamentState = { inTournament=false,placement=nil,startedAt=nil,joins=0,wins=0,lastTick=0 }
        notify("Stats", "Reset.", "info")
    end,
})

local lastUI = 0
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - lastUI < 0.5 then return end
    lastUI = now
    pcall(function()
        if not (lbl_cash and lbl_cash.Set) then return end
        local elapsed = math.max(1, os.time() - stats.sessionStart)
        local cashNow = getCash()
        local gemsNow = getGems()
        local cashGain = cashNow - (stats.cashStart or cashNow)
        local gemsGain = gemsNow - (stats.gemsStart or gemsNow)

        lbl_cash:Set("💰 Cash: $" .. formatCash(cashNow))
        lbl_gems:Set("💎 Gems: " .. math.floor(gemsNow))
        lbl_reb:Set("🌟 Rebirth: " .. getRebirthLevel())
        lbl_open:Set("📦 Opened: " .. stats.opened)
        lbl_bought:Set("🛒 Bought: " .. stats.bought)
        lbl_sold:Set("💸 Sold: " .. stats.sold)
        lbl_lock:Set("🔒 Locked: " .. stats.locked)
        lbl_wish:Set("✨ Wishes: " .. stats.wishes)
        lbl_troph:Set("🏆 Trophies: " .. stats.trophiesCrafted)
        lbl_hop:Set("🌐 Hops: " .. stats.hopCount)
        lbl_weather:Set("🌦️ Weather: " .. getActiveWeathers())
        lbl_uptime:Set("⏱️ Uptime: " .. formatDuration(elapsed))
        lbl_cashHr:Set("Cash/hr: $" .. formatCash(cashGain/elapsed*3600))
        lbl_gemsHr:Set("Gems/hr: " .. formatCash(gemsGain/elapsed*3600))

        local rd = getRebirthRequirements()
        if rd and rd.CashRequired then
            local need = rd.CashRequired - cashNow
            if need <= 0 then lbl_eta:Set("ETA Next Rebirth: ✅ ready")
            else
                local rate = cashGain / elapsed
                if rate > 0 then lbl_eta:Set("ETA Next Rebirth: " .. formatDuration(need/rate))
                else lbl_eta:Set("ETA Next Rebirth: --") end
            end
        end

        local parts = {}
        for _, r in ipairs(rarityList) do
            local c = stats.rarityRolls[r]
            if c and c > 0 then table.insert(parts, r .. ": " .. c) end
        end
        lbl_rolls:Set(#parts > 0 and table.concat(parts, "  •  ") or "(no rolls yet)")

        -- tournament
        if lbl_t_state and lbl_t_state.Set then
            lbl_t_state:Set("Status: " .. (tournamentState.inTournament and "🟢 in tournament" or "⚪ idle"))
            lbl_t_join:Set("Joined: " .. tournamentState.joins)
            lbl_t_win:Set("Top-3 finishes: " .. tournamentState.wins)
            lbl_t_place:Set("Last placement: " .. tostring(tournamentState.placement or "--"))
        end
    end)
end)


-- [ DONE ]
-- Push initial pack settings to server so the UI state matches the game
task.delay(2, function() pcall(syncPackSettings) end)

print("[SSC] Loaded. " .. #CORE_REMOTES .. " core remotes, " .. #cardIdList .. " cards in dropdowns.")
logEvent("Init", "Spin a Soccer Card loaded.")
