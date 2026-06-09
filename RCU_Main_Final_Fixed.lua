
local maxRetries = 3
local retryDelay = 3
local loadSuccess = false

for attempt = 1, maxRetries do
    local success, errorMsg = pcall(function()
        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")

        local requestFunc = (syn and syn.request) or (http and http.request) or request
        if not requestFunc then
            warn("Your executor does not support HTTP requests.")
            return
        end

        local player = Players.LocalPlayer
        local userid = player.UserId
        local username = player.Name

        -- Allowlisted domains for remote code loading (loadstring)
        local ALLOWED_LOAD_DOMAINS = {
            "raw.githubusercontent.com",
            "github.com",
            "versusairlines.top",
        }

        local function isAllowedLoadUrl(url)
            if type(url) ~= "string" then return false end
            for _, domain in ipairs(ALLOWED_LOAD_DOMAINS) do
                if url:match("^https://" .. domain:gsub("%.", "%%.") .. "/") then
                    return true
                end
            end
            return false
        end

        local function safeLoadUrl(url)
            if not isAllowedLoadUrl(url) then
                warn("[RCU] Blocked remote load from untrusted domain: " .. tostring(url))
                return function() end
            end
            local code = game:HttpGet(url)
            if not code or code == "" then
                warn("[RCU] Empty response from: " .. tostring(url))
                return function() end
            end
            return loadstring(code)
        end

        -- Thread Manager - Add this here
        local ThreadManager = {}
        ThreadManager.threads = {}

        function ThreadManager:Add(key, thread)
            self:Stop(key)
            self.threads[key] = thread
            return thread
        end

        function ThreadManager:Stop(key)
            if self.threads[key] then
                pcall(function() task.cancel(self.threads[key]) end)
                self.threads[key] = nil
            end
        end

        function ThreadManager:StopAll()
            for key, thread in pairs(self.threads) do
                pcall(function() task.cancel(thread) end)
            end
            self.threads = {}
        end


        local Library = safeLoadUrl("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau")()
        local SaveManager = safeLoadUrl("https://raw.githubusercontent.com/bigbeanscripts/Pet-Warriors/refs/heads/main/test")()
        local InterfaceManager = safeLoadUrl("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau")()
        safeLoadUrl("https://raw.githubusercontent.com/SenhorLDS/ProjectLDSHUB/refs/heads/main/Anti%20AFK")()

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local Workspace = game:GetService("Workspace")
        local CollectionService = game:GetService("CollectionService")
        local LocalPlayer = Players.LocalPlayer

        local Knit
        local ClickService, EggService, RebirthService, TreeService, AxeService, InventoryService,
            PetService, RewardService, UpgradeService, SeasonService, AuraService, EventService,
            OrbService, FarmService, BuildingService, ClanService, LumberjackService, DungeonService
        local DataController, EggController, TreeController, HatchingController, AuraController,
            MapController, OrbController, ItemController, SoundController, FarmController, BuildingController

        local Functions, Util, Values, seasonVariables, seasonUtils, seasonTiersList

        local Window, Tabs, EggDropdown, HatchAmount, LuckyEgg, AutoHatch, HideAnimationToggle,
            SelectTreesDropdown, AutoCutTreesToggle, lowercooldown, BypassStrength, AutoEquip, UpgradeAxe,
            explorerroom, ActivateLeversSection, ClaimSection, AncientWheel, ClanWheel, AncientMerchantSection, PassSection,
            Aura, EventSection, AutoCraftBuildings, autoCraftDropdown

        local selectedEgg, selectedAmount, useLuckyEggs, selectedTrees, autoBreakRunning, isAutoEquipAxeEnabled,
            isAutoUpgradeEnabled, originalSelectedObjects, originalAutoCutState, treeToggleThread, petDisplayToId,
            angelQuestToggle, allowedDiceDropdown, originalEggSelection, originalHatchAmount, originalTreeSelection,
            originalAutoCutState, originalAutoHatchState, angelQuestEnabled, isAutoCollectEnabled, autoClaimThread, pickupStarsThread,
            autoClaimAllChestsThread, originalIsInGroup, supplyDropThread, isAutoSpinEnabled, isAutoSpinEnabled1, isAutoBuyEnabled,
            autoSteampunkToggles, isAutoCraftEnabled, originalAutoCraftSettings, autoCraftDropdown, autoCraftBuildingMap,
            ResourceStatusParagraph, selectedDiceItems, autoRollThread, isAuraHidden, originalAuraFuncs, isAutoBreakingMeteors
        local autoRebirthThread = nil
        local autoClaimPlaytimeThread = nil
        local IndexHasBeenOn = false
        local HasBeenEnabled1 = false
        local PetDropdown = nil

        local BuildUI, getUnlockedRebirthOptions, GetBestRebirthOption, updateRebirthDropdown, performRebirth,
            TerminateThread, CreateThread, formatNumber, getLuckyIdForEggName, getTreeTypes, mapWoodToTreeWorld,
            getLumberId, getActiveTreesInGroup, updateAxeUpgradeStatus, manageTreeToggleCycle, getAllNonWoodRequirements,
            getAllFarms, getAllFarmsWithOptions, getAllFarmsForClaim, isFarmReady, getPlayerPetOptions,
            updatePetStatusParagraph, updateAngelQuestStatus, getAllAuraDice, getCurrentQuestType, findBestPotion,
            getAvailableAuraDice, setupForQuestType, storeOriginalSettings, restoreOriginalSettings, getAllSmoothies,
            getAllMagicPotItems, getAllWoods, canCraftToday, getAllMaps, getAllLumberjackItems, canAffordUpgrade,
            isLumberjackAtWork, getAllUpgradeItems, hasActiveBoost, getUnbuiltBuildings, canAffordBuilding,
            getPrerequisiteChain, getMissingResources, updateResourceStatus, mapWoodToTreeWorldForCraft, claimChestsInUnlockedMaps,
            createClaimToggle, getAllAncientMerchantItems, updateDiceStatus, storeAuraFuncs, hideAuraAnims, restoreAuraAnims

        spawn(function()
            while wait(30) do 
                pcall(function() collectgarbage("collect") end)
                gcinfo()
            end
        end)

        BuildUI = function()
            
            -- ============================================================
            -- BEE HIVE TAB — Full Implementation
            -- ============================================================
            do -- Scoped block to avoid exceeding 200 local register limit
            local HiveService = Knit.GetService("HiveService")
            local HiveUpgrades = require(ReplicatedStorage.Shared.List.Hive.HiveUpgrades)
            local HiveCapsules = require(ReplicatedStorage.Shared.List.Skylands.Capsules)
            local BeesList = require(ReplicatedStorage.Shared.List.Items.Bees)
            local MasteryUtils = require(ReplicatedStorage.Shared.Util.MasteryUtils)
            local UpgradeUtils = require(ReplicatedStorage.Shared.Util.UpgradeUtils)

            -- State variables
            local isAutoOpenCapsule = false
            local autoOpenCapsuleThread = nil
            local isAutoCollectHoney = false
            local autoCollectHoneyThread = nil
            local isAutoUpgradeHive = false
            local autoUpgradeHiveThread = nil
            local isAutoEquipBestBees = false
            local autoEquipBestBeesThread = nil
            local isAutoCraftBees = false
            local autoCraftBeesThread = nil
            local isAutoClaimBeedex = false
            local autoClaimBeedexThread = nil
            local isAutoBuyMerchant = false
            local autoBuyMerchantThread = nil
            local selectedCapsuleIndex = 1

            -- === STATUS DASHBOARD ===
            local BeeHiveSection = Tabs.BeeHive:AddSection("Bee Hive Dashboard")

            local BeeHiveStatusParagraph = BeeHiveSection:Paragraph("BeeHiveStatus", {
                Title = "Hive Status",
                Content = "Loading...",
                TitleAlignment = "Middle",
                ContentAlignment = Enum.TextXAlignment.Left
            })

            local function getHoneyAmount(playerData)
                local honeyItem = Util.itemUtils.getItemFromName(playerData, "honey")
                return honeyItem and honeyItem:getAmount() or 0
            end

            local function updateBeeHiveStatus()
                pcall(function()
                    local playerData = DataController:getData()
                    if not playerData then
                        BeeHiveStatusParagraph:SetValue("❌ Could not load player data")
                        return
                    end

                    local statusLines = {}
                    local honeyAmount = getHoneyAmount(playerData)
                    local honeyToCollect = playerData.honeyToCollect or 0
                    local hiveCapacity = Values.hiveCapacity(LocalPlayer, playerData)
                    local maxBees = Values.maxBees and Values.maxBees(LocalPlayer, playerData) or (3 + UpgradeUtils.getAllUpgradeMultipliers(playerData, "maxBees") + (playerData.hiveUpgrades and playerData.hiveUpgrades.maxBees and HiveUpgrades.maxBees.upgrades[playerData.hiveUpgrades.maxBees] and HiveUpgrades.maxBees.upgrades[playerData.hiveUpgrades.maxBees].value or 0))
                    local hiveMastery = MasteryUtils.getTier(playerData, "hiveMastery")

                    -- Count equipped bees
                    local equippedBees = 0
                    if playerData.equippedBees then
                        for _ in pairs(playerData.equippedBees) do equippedBees = equippedBees + 1 end
                    end

                    -- Count total bees owned
                    local totalBees = 0
                    if playerData.inventory and playerData.inventory.bee then
                        for _, beeData in pairs(playerData.inventory.bee) do
                            totalBees = totalBees + (beeData.am or 1)
                        end
                    end

                    table.insert(statusLines, "Honey: " .. Functions.suffixes(honeyAmount))
                    table.insert(statusLines, "Honey to Collect: " .. Functions.suffixes(honeyToCollect) .. " / " .. Functions.suffixes(hiveCapacity))
                    table.insert(statusLines, "Bees: " .. equippedBees .. " / " .. math.floor(maxBees) .. " equipped | " .. totalBees .. " total")
                    table.insert(statusLines, "Hive Mastery: " .. hiveMastery)
                    table.insert(statusLines, "")

                    -- Show upgrade levels
                    local upgLines = {}
                    if playerData.hiveUpgrades then
                        for upgradeId, level in pairs(playerData.hiveUpgrades) do
                            local upgradeData = HiveUpgrades[upgradeId]
                            local maxLevel = upgradeData and #upgradeData.upgrades or "?"
                            table.insert(upgLines, upgradeId .. ": " .. level .. "/" .. tostring(maxLevel))
                        end
                    end
                    if #upgLines > 0 then
                        table.sort(upgLines)
                        table.insert(statusLines, "Upgrades: " .. table.concat(upgLines, " | "))
                    end

                    BeeHiveStatusParagraph:SetValue(table.concat(statusLines, "\n"))
                end)
            end

            task.spawn(function()
                while true do
                    updateBeeHiveStatus()
                    task.wait(5)
                end
            end)

            -- === AUTO COLLECT HONEY ===
            local CollectSection = Tabs.BeeHive:AddSection("Honey Collection")
            local honeyCollectDelay = 5

            CollectSection:Slider("HoneyCollectDelay", {
                Title = "Collection Delay (seconds)",
                Description = "How often to check and collect honey from your hive",
                Default = 5,
                Min = 1,
                Max = 60,
                Rounding = 0,
                Callback = function(value) honeyCollectDelay = value end
            })

            CollectSection:Toggle("AutoCollectHoney", {
                Title = "Auto Collect Honey",
                Description = "Collects accumulated honey from your hive automatically. Fires the collectHoney remote whenever your hive has honey waiting.",
                Default = false,
                Callback = function(enabled)
                    isAutoCollectHoney = enabled
                    if autoCollectHoneyThread then task.cancel(autoCollectHoneyThread); autoCollectHoneyThread = nil end
                    if enabled then
                        autoCollectHoneyThread = task.spawn(function()
                            while isAutoCollectHoney do
                                pcall(function()
                                    local playerData = DataController:getData()
                                    if playerData then
                                        local honeyToCollect = playerData.honeyToCollect or 0
                                        if honeyToCollect > 0 then
                                            HiveService:collectHoney()
                                        end
                                    end
                                end)
                                task.wait(honeyCollectDelay)
                            end
                        end)
                    end
                end
            })

            -- === AUTO OPEN CAPSULES ===
            local CapsuleSection = Tabs.BeeHive:AddSection("Capsules")

            local capsuleNames = {}
            for i, capsule in ipairs(HiveCapsules) do
                local masteryReq = capsule.reqMastery and (" [Mastery " .. capsule.reqMastery .. "]") or ""
                table.insert(capsuleNames, capsule.name .. " - " .. Functions.comma(capsule.price) .. " Honey" .. masteryReq)
            end

            CapsuleSection:Dropdown("SelectCapsule", {
                Title = "Select Capsule",
                Values = capsuleNames,
                Default = capsuleNames[1],
                Multi = false,
                Searchable = true,
                Callback = function(value)
                    for i, name in ipairs(capsuleNames) do
                        if name == value then selectedCapsuleIndex = i; break end
                    end
                end
            })

            CapsuleSection:Toggle("AutoOpenCapsule", {
                Title = "Auto Open Capsules",
                Description = "Opens the selected capsule on repeat, spending as much honey as you can afford each time. Respects mastery requirements and capsule open limits.",
                Default = false,
                Callback = function(enabled)
                    isAutoOpenCapsule = enabled
                    if autoOpenCapsuleThread then task.cancel(autoOpenCapsuleThread); autoOpenCapsuleThread = nil end
                    if enabled then
                        autoOpenCapsuleThread = task.spawn(function()
                            while isAutoOpenCapsule do
                                pcall(function()
                                    local playerData = DataController:getData()
                                    if not playerData then return end

                                    local capsuleData = HiveCapsules[selectedCapsuleIndex]
                                    if not capsuleData then return end

                                    -- Check mastery requirement
                                    if capsuleData.reqMastery then
                                        local hiveMastery = MasteryUtils.getTier(playerData, "hiveMastery")
                                        if hiveMastery < capsuleData.reqMastery then return end
                                    end

                                    -- Calculate how many we can afford
                                    local honeyAmount = getHoneyAmount(playerData)
                                    local maxOpen = math.floor(honeyAmount / capsuleData.price)

                                    -- Clamp to max capsules open (3 + upgrade)
                                    local capsulesMaxOpen = 3 + (playerData.hiveUpgrades and playerData.hiveUpgrades.capsulesMaxOpen and HiveUpgrades.capsulesMaxOpen.upgrades[playerData.hiveUpgrades.capsulesMaxOpen] and HiveUpgrades.capsulesMaxOpen.upgrades[playerData.hiveUpgrades.capsulesMaxOpen].value or 0)
                                    maxOpen = math.clamp(maxOpen, 0, capsulesMaxOpen)

                                    if maxOpen >= 1 then
                                        HiveService:openCapsule(selectedCapsuleIndex, math.floor(maxOpen))
                                    end
                                end)
                                task.wait(0.5)
                            end
                        end)
                    end
                end
            })

            -- === AUTO UPGRADE HIVE ===
            local UpgradeSection = Tabs.BeeHive:AddSection("Hive Upgrades")

            local upgradeNames = {}
            local upgradeIdMap = {}
            for upgradeId, upgradeData in pairs(HiveUpgrades) do
                local displayName = upgradeId
                table.insert(upgradeNames, displayName)
                upgradeIdMap[displayName] = upgradeId
            end
            table.sort(upgradeNames)

            local selectedHiveUpgrades = {}

            local HiveUpgradeDropdown = UpgradeSection:Dropdown("SelectHiveUpgrades", {
                Title = "Select Upgrades to Auto-Buy",
                Description = "Choose which hive upgrades to automatically purchase",
                Values = upgradeNames,
                Multi = true,
                Searchable = true,
                Default = {},
                Callback = function(value) selectedHiveUpgrades = value end
            })

            UpgradeSection:Button({
                Title = "Select All Upgrades",
                Callback = function()
                    local all = {}
                    for _, name in ipairs(upgradeNames) do all[name] = true end
                    HiveUpgradeDropdown:SetValue(all)
                    selectedHiveUpgrades = all
                end
            })

            UpgradeSection:Toggle("AutoUpgradeHive", {
                Title = "Auto Upgrade Hive",
                Description = "Purchases the next level of each selected upgrade whenever you have enough honey. Select which upgrades to prioritize using the dropdown above.",
                Default = false,
                Callback = function(enabled)
                    isAutoUpgradeHive = enabled
                    if autoUpgradeHiveThread then task.cancel(autoUpgradeHiveThread); autoUpgradeHiveThread = nil end
                    if enabled then
                        autoUpgradeHiveThread = task.spawn(function()
                            while isAutoUpgradeHive do
                                pcall(function()
                                    local playerData = DataController:getData()
                                    if not playerData then return end
                                    local honeyAmount = getHoneyAmount(playerData)

                                    for displayName, isSelected in pairs(selectedHiveUpgrades) do
                                        if isSelected then
                                            local upgradeId = upgradeIdMap[displayName]
                                            local upgradeData = HiveUpgrades[upgradeId]
                                            if upgradeData and upgradeData.upgrades then
                                                local currentLevel = playerData.hiveUpgrades and playerData.hiveUpgrades[upgradeId] or 0
                                                local nextLevel = currentLevel + 1
                                                local nextUpgrade = upgradeData.upgrades[nextLevel]
                                                if nextUpgrade then
                                                    local cost = nextUpgrade.cost and nextUpgrade.cost:getAmount() or 0
                                                    if honeyAmount >= cost then
                                                        HiveService:buyHiveUpgrade(upgradeId)
                                                        task.wait(0.3)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end)
                                task.wait(3)
                            end
                        end)
                    end
                end
            })

            -- === AUTO EQUIP BEST BEES ===
            local BeeManageSection = Tabs.BeeHive:AddSection("Bee Management")

            BeeManageSection:Toggle("AutoEquipBestBees", {
                Title = "Auto Equip Best Bees",
                Description = "Sorts all your bees by power and equips the strongest ones to fill every slot. Accounts for stacked bees so duplicates fill multiple slots.",
                Default = false,
                Callback = function(enabled)
                    isAutoEquipBestBees = enabled
                    if autoEquipBestBeesThread then task.cancel(autoEquipBestBeesThread); autoEquipBestBeesThread = nil end
                    if enabled then
                        autoEquipBestBeesThread = task.spawn(function()
                            while isAutoEquipBestBees do
                                pcall(function()
                                    local playerData = DataController:getData()
                                    if not playerData or not playerData.inventory or not playerData.inventory.bee then return end

                                    local maxBees = 3
                                    pcall(function()
                                        maxBees = Values.maxBees(LocalPlayer, playerData)
                                    end)
                                    if not maxBees or maxBees < 3 then
                                        maxBees = 3 + UpgradeUtils.getAllUpgradeMultipliers(playerData, "maxBees") + (playerData.hiveUpgrades and playerData.hiveUpgrades.maxBees and HiveUpgrades.maxBees.upgrades[playerData.hiveUpgrades.maxBees] and HiveUpgrades.maxBees.upgrades[playerData.hiveUpgrades.maxBees].value or 0)
                                    end
                                    maxBees = math.floor(maxBees)

                                    -- Expand stacked bees into individual entries sorted by multiplier
                                    local expandedBees = {}
                                    for beeId, beeData in pairs(playerData.inventory.bee) do
                                        local beeObj = Util.itemUtils.createItemFromData(beeData)
                                        if beeObj then
                                            local amount = beeData.am or 1
                                            local mult = beeObj:getMultiplier()
                                            for copy = 1, amount do
                                                table.insert(expandedBees, {
                                                    id = beeId,
                                                    multiplier = mult,
                                                    copyIndex = copy
                                                })
                                            end
                                        end
                                    end
                                    table.sort(expandedBees, function(a, b) return a.multiplier > b.multiplier end)

                                    -- Determine which unique inventory IDs should be equipped
                                    local slotsToFill = maxBees
                                    local idsToEquip = {}
                                    for _, entry in ipairs(expandedBees) do
                                        if slotsToFill <= 0 then break end
                                        idsToEquip[entry.id] = true
                                        slotsToFill = slotsToFill - 1
                                    end

                                    local equipped = playerData.equippedBees or {}

                                    -- Unequip bees not in the top set
                                    for equippedId in pairs(equipped) do
                                        if not idsToEquip[equippedId] then
                                            HiveService:unequipBee(equippedId)
                                            task.wait(0.3)
                                        end
                                    end

                                    -- Equip bees that should be equipped but aren't
                                    for beeId in pairs(idsToEquip) do
                                        if not equipped[beeId] then
                                            HiveService:equipBee(beeId)
                                            task.wait(0.3)
                                        end
                                    end
                                end)
                                task.wait(10)
                            end
                        end)
                    end
                end
            })

            -- === AUTO CRAFT BEES (Shiny / Rainbow) ===
            local CraftBeeSection = Tabs.BeeHive:AddSection("Craft Bees")

            local craftTypeOptions = {"shiny", "rainbow"}
            local selectedCraftType = "shiny"

            CraftBeeSection:Dropdown("SelectCraftType", {
                Title = "Craft Type",
                Description = "Shiny = 150 normal bees → 1 Shiny\nRainbow = 10 shiny bees → 1 Rainbow",
                Values = craftTypeOptions,
                Default = "shiny",
                Multi = false,
                Callback = function(value) selectedCraftType = value end
            })

            CraftBeeSection:Toggle("AutoCraftBees", {
                Title = "Auto Craft Bees",
                Description = "Crafts bees into the selected variant when requirements are met.\n- Shiny: Requires 150 of the same normal bee\n- Rainbow: Requires 10 of the same shiny bee\nMake sure the corresponding crafting upgrade is unlocked first.",
                Default = false,
                Callback = function(enabled)
                    isAutoCraftBees = enabled
                    if autoCraftBeesThread then task.cancel(autoCraftBeesThread); autoCraftBeesThread = nil end
                    if enabled then
                        autoCraftBeesThread = task.spawn(function()
                            while isAutoCraftBees do
                                pcall(function()
                                    local playerData = DataController:getData()
                                    if not playerData or not playerData.inventory or not playerData.inventory.bee then return end

                                    -- Check if crafting is unlocked
                                    if selectedCraftType == "shiny" then
                                        if not (playerData.hiveUpgrades and playerData.hiveUpgrades.shinyBeesCrafting) then return end
                                    elseif selectedCraftType == "rainbow" then
                                        if not (playerData.hiveUpgrades and playerData.hiveUpgrades.rainbowBeesCrafting) then return end
                                    end

                                    for beeId, beeData in pairs(playerData.inventory.bee) do
                                        if not isAutoCraftBees then break end
                                        local beeObj = Util.itemUtils.createItemFromData(beeData)
                                        if beeObj then
                                            local amount = beeData.am or 1
                                            local isShiny = beeObj.isShiny and beeObj:isShiny() or false
                                            local isRainbow = beeObj.isRainbow and beeObj:isRainbow() or false

                                            if selectedCraftType == "shiny" and not isShiny and not isRainbow and amount >= 150 then
                                                HiveService:craftBee(beeId, "shiny")
                                                task.wait(1)
                                            elseif selectedCraftType == "rainbow" and isShiny and not isRainbow and amount >= 10 then
                                                HiveService:craftBee(beeId, "rainbow")
                                                task.wait(1)
                                            end
                                        end
                                    end
                                end)
                                task.wait(5)
                            end
                        end)
                    end
                end
            })

            -- === AUTO CLAIM BEEDEX REWARDS ===
            local BeedexSection = Tabs.BeeHive:AddSection("Beedex")

            local BeedexRewards = nil
            pcall(function()
                BeedexRewards = require(ReplicatedStorage.Shared.List.Hive.BeedexRewards)
            end)

            local BeedexStatusParagraph = BeedexSection:Paragraph("BeedexStatus", {
                Title = "Beedex Progress",
                Content = "Loading...",
                TitleAlignment = "Middle",
                ContentAlignment = Enum.TextXAlignment.Left
            })

            local function updateBeedexStatus()
                pcall(function()
                    local playerData = DataController:getData()
                    if not playerData then return end

                    local beedex = playerData.beedex or {}
                    local uniqueBees = 0
                    for _ in pairs(beedex) do uniqueBees = uniqueBees + 1 end
                    local totalBeeTypes = 0
                    for _ in pairs(BeesList) do totalBeeTypes = totalBeeTypes + 1 end

                    local lines = {}
                    table.insert(lines, "Beedex: " .. uniqueBees .. " / " .. totalBeeTypes .. " discovered")

                    if BeedexRewards then
                        local claimedRewards = playerData.claimedBeedexRewards or {}
                        local nextReward = nil
                        for _, reward in ipairs(BeedexRewards) do
                            if not claimedRewards[tostring(reward.required)] and uniqueBees >= reward.required then
                                nextReward = reward
                                break
                            end
                        end
                        if nextReward then
                            table.insert(lines, "🎁 Claimable reward at " .. nextReward.required .. " bees!")
                        end
                    end

                    BeedexStatusParagraph:SetValue(table.concat(lines, "\n"))
                end)
            end

            task.spawn(function() while true do updateBeedexStatus(); task.wait(10) end end)

            -- Find the Beedex claim remote (obfuscated name)
            local BeedexClaimRemote = nil
            pcall(function()
                local servicesFolder = ReplicatedStorage.Packages.Knit.Services
                local hiveServiceFolder = servicesFolder:GetChildren()[65]
                if hiveServiceFolder then
                    BeedexClaimRemote = hiveServiceFolder.RF:GetChildren()[2]
                end
            end)

            BeedexSection:Toggle("AutoClaimBeedex", {
                Title = "Auto Claim Beedex Rewards",
                Description = "Claims Beedex milestone rewards as soon as you discover enough unique bee types. Milestones at 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, and 63.",
                Default = false,
                Callback = function(enabled)
                    isAutoClaimBeedex = enabled
                    if autoClaimBeedexThread then task.cancel(autoClaimBeedexThread); autoClaimBeedexThread = nil end
                    if enabled then
                        autoClaimBeedexThread = task.spawn(function()
                            while isAutoClaimBeedex do
                                pcall(function()
                                    local playerData = DataController:getData()
                                    if not playerData then return end

                                    local beedex = playerData.beedex or {}
                                    local uniqueBees = 0
                                    for _ in pairs(beedex) do uniqueBees = uniqueBees + 1 end

                                    if BeedexRewards and BeedexClaimRemote then
                                        local claimedRewards = playerData.claimedBeedexRewards or {}
                                        for rewardIndex, reward in ipairs(BeedexRewards) do
                                            if uniqueBees >= reward.required and not claimedRewards[tostring(reward.required)] then
                                                pcall(function()
                                                    BeedexClaimRemote:InvokeServer(rewardIndex)
                                                end)
                                                task.wait(1)
                                            end
                                        end
                                    end
                                end)
                                task.wait(10)
                            end
                        end)
                    end
                end
            })

            BeedexSection:Button({
                Title = "Claim All Beedex Rewards (Bypass)",
                Description = "Attempts to claim EVERY beedex reward regardless of how many bees you've discovered. Fires every reward index directly to the server — if the server doesn't validate, you get free rewards.",
                Callback = function()
                    if not BeedexClaimRemote then
                        Library:Notify({Title = "Error", Content = "Beedex remote not found. Try rejoining.", Duration = 3})
                        return
                    end

                    local totalRewards = BeedexRewards and #BeedexRewards or 20
                    Library:Notify({Title = "Beedex Bypass", Content = "Firing " .. totalRewards .. " reward claims...", Duration = 3})

                    task.spawn(function()
                        local claimed = 0
                        -- Fire every possible reward index
                        for i = 1, totalRewards do
                            local success = pcall(function()
                                BeedexClaimRemote:InvokeServer(i)
                            end)
                            if success then claimed = claimed + 1 end
                            task.wait(0.3)
                        end
                        Library:Notify({Title = "Beedex Bypass", Content = "Done! Fired " .. claimed .. "/" .. totalRewards .. " claims.", Duration = 5})
                    end)
                end
            })

            -- === AUTO BUY HONEY MERCHANT ===
            local MerchantSection = Tabs.BeeHive:AddSection("Honey Merchant")

            MerchantSection:Toggle("AutoBuyHoneyMerchant", {
                Title = "Auto Buy Honey Merchant",
                Description = "Purchases all available slots from the rotating Honey Merchant every 30 seconds. Make sure you have enough honey.",
                Default = false,
                Callback = function(enabled)
                    isAutoBuyMerchant = enabled
                    if autoBuyMerchantThread then task.cancel(autoBuyMerchantThread); autoBuyMerchantThread = nil end
                    if enabled then
                        autoBuyMerchantThread = task.spawn(function()
                            while isAutoBuyMerchant do
                                pcall(function()
                                    -- Get current stock
                                    local stock = HiveService.honeyShopStock:Get()
                                    if stock and type(stock) == "table" then
                                        for slot = 1, #stock do
                                            if not isAutoBuyMerchant then break end
                                            pcall(function()
                                                HiveService:buyHoneyMerchant(slot)
                                            end)
                                            task.wait(0.5)
                                        end
                                    else
                                        -- Try buying slots 1-6 blindly
                                        for slot = 1, 6 do
                                            if not isAutoBuyMerchant then break end
                                            pcall(function() HiveService:buyHoneyMerchant(slot) end)
                                            task.wait(0.5)
                                        end
                                    end
                                end)
                                task.wait(30)
                            end
                        end)
                    end
                end
            })

            -- === AUTO BUY HONEY SHOP ===
            MerchantSection:Toggle("AutoBuyHoneyShop", {
                Title = "Auto Buy Honey Shop",
                Description = "Purchases items from the Honey Shop every 30 seconds. Tries all available slots.",
                Default = false,
                Callback = function(enabled)
                    _G.AutoBuyHoneyShopEnabled = enabled
                    if _G.AutoBuyHoneyShopThread then task.cancel(_G.AutoBuyHoneyShopThread); _G.AutoBuyHoneyShopThread = nil end
                    if enabled then
                        _G.AutoBuyHoneyShopThread = task.spawn(function()
                            while _G.AutoBuyHoneyShopEnabled do
                                pcall(function()
                                    for slot = 1, 10 do
                                        if not _G.AutoBuyHoneyShopEnabled then break end
                                        pcall(function() HiveService:buyHoneyShop(slot) end)
                                        task.wait(0.5)
                                    end
                                end)
                                task.wait(30)
                            end
                        end)
                    end
                end
            })

            end -- End of Bee Hive scoped block

            local TeleportService = game:GetService("TeleportService")

            -- Public Server Section
            local PublicServerSection = Tabs.Rejoin:AddSection("Public Server")

            local publicDelayInput = PublicServerSection:AddInput("PublicRejoinDelay", {
                Title = "Delay (Seconds)",
                Default = "3600",
                Numeric = true,
            })


            local AutoRejoinPublicToggle = PublicServerSection:Toggle("AutoRejoinPublic", {
                Title = "Auto Rejoin",
                Description = "Automatically rejoins a public server with the least players after the delay.",
                Default = false,
                Callback = function(enabled)
                    _G.AutoRejoinPublicEnabled = enabled
                    if _G.AutoRejoinPublicThread then
                        task.cancel(_G.AutoRejoinPublicThread)
                        _G.AutoRejoinPublicThread = nil
                    end
                    if enabled then
                        _G.AutoRejoinPublicThread = task.spawn(function()
                            while _G.AutoRejoinPublicEnabled do
                                local delay = tonumber(publicDelayInput.Value) or 10
                                task.wait(delay)
                                -- Join public server with least players
                                local placeId = game.PlaceId
                                local HttpService = game:GetService("HttpService")
                                local cursor = ""
                                local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
                                local servers = {}
                                while true do
                                    local reqUrl = url .. (cursor ~= "" and ("&cursor=" .. HttpService:UrlEncode(cursor)) or "")
                                    local success, response = pcall(function()
                                        return HttpService:JSONDecode(game:HttpGet(reqUrl))
                                    end)
                                    if not success or not response or not response.data then break end
                                    for _, server in ipairs(response.data) do
                                        if server.playing < server.maxPlayers then
                                            table.insert(servers, server)
                                        end
                                    end
                                    if not response.nextPageCursor then break end
                                    cursor = response.nextPageCursor
                                end
                                table.sort(servers, function(a, b) return a.playing < b.playing end)
                                for _, server in ipairs(servers) do
                                    if server.id ~= game.JobId then
                                        TeleportService:TeleportToPlaceInstance(placeId, server.id, Players.LocalPlayer)
                                        break
                                    end
                                end
                                task.wait(2)
                            end
                        end)
                    end
                end
            })

            local PrivateServerSection = Tabs.Rejoin:AddSection("Private Server")

            PrivateServerSection:Paragraph("PrivateServerInfo", {
                Title = "How to Get Private Server ID",
                Content = "To join a private server, copy the Roblox invite link and paste the ID below.\nExample: https://www.roblox.com/share?code=12345&type=Server\nThe ID is: 12345\nEnter 12345 in the 'Private Server ID' input. Or if your lazy, just paste the whole link in the input."
            })

            local privateServerIdInput = PrivateServerSection:AddInput("PrivateServerID", {
                Title = "Private Server ID",
                Default = "",
                Description = "Paste the private server ID here."
            })

            local privateDelayInput = PrivateServerSection:AddInput("PrivateRejoinDelay", {
                Title = "Rejoin Delay (Seconds)",
                Default = "3600",
                Numeric = true,
            })

            local function extractPrivateServerId(input)
                -- If input is a full URL, extract the code
                local code = tostring(input)
                local match = code:match("code=([%w]+)")
                if match then
                    return match
                end
                return code
            end

            local AutoRejoinPrivateToggle = PrivateServerSection:Toggle("AutoRejoinPrivate", {
                Title = "Auto Rejoin",
                Description = "Automatically rejoins the private server after the delay.",
                Default = false,
                Callback = function(enabled)
                    _G.AutoRejoinPrivateEnabled = enabled
                    if _G.AutoRejoinPrivateThread then
                        task.cancel(_G.AutoRejoinPrivateThread)
                        _G.AutoRejoinPrivateThread = nil
                    end
                    if enabled then
                        _G.AutoRejoinPrivateThread = task.spawn(function()
                            while _G.AutoRejoinPrivateEnabled do
                                local delay = tonumber(privateDelayInput.Value) or 10
                                local rawInput = tostring(privateServerIdInput.Value)
                                local accessCode = extractPrivateServerId(rawInput)
                                task.wait(delay)
                                if accessCode ~= "" then
                                    local teleportOptions = Instance.new("TeleportOptions")
                                    teleportOptions.ReservedServerAccessCode = accessCode
                                    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer, teleportOptions)
                                end
                                task.wait(2)
                            end
                        end)
                    end
                end
            })


            local ClickSection = Tabs.Main:AddSection("Auto Click")

            local ClickController = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Controllers.ClickController)
            local isMainAutoClicking = false 
            
            local AutoClick = ClickSection:Toggle("AutoClick", {
                Title = "Auto Click",
                Description = "This might be detected, so use this carefully!",
                Default = false,
                Callback = function(Value)
                    isMainAutoClicking = Value
                    if Value then
                        task.spawn(function()
                            while isMainAutoClicking do
                                ClickController:setLastClickType(2) 
                                ClickController:setDebounce()
                                ClickController:doClick()
                                task.wait(0.02)
                            end
                        end)
                    end
                end
            })

            local RebirthSection = Tabs.Main:AddSection("Rebirths")

            local selectedRebirthIndex = "Max Unlocked"
            local rebirthDropdown
            local rebirthOptions = {}
            local isMaxUnlockedSelected = true -- Default to true since "Max Unlocked" is the default
            local autoRebirthRunning = false

            -- This function gets ALL rebirths for the initial dropdown population.
            local function getAllRebirthOptions()
                local Rebirths = require(ReplicatedStorage.Shared.List.Rebirths)
                local options = {}
                for index, amount in pairs(Rebirths) do
                    table.insert(options, {index = index, amount = amount, display = Functions.suffixes(amount) .. " Rebirths"})
                end
                table.sort(options, function(a, b) return a.amount < b.amount end)
                return options
            end

            GetBestRebirthOption = function()
                local success, result = pcall(function()
                    local Rebirths = require(ReplicatedStorage.Shared.List.Rebirths)
                    local Vars = require(ReplicatedStorage.Shared.Variables)

                    DataController:waitForData()
                    local playerData = DataController:getData()
                    if not playerData then 
                        return nil 
                    end

                    local basePrice = Vars.rebirthPrice or 0
                    local multiplier = Vars.rebirthPriceMultiplier or 0
                    local currentRebirths = playerData.rebirths or 0
                    local clicks = playerData.clicks or 0

                    local bestIndex = nil
                    local bestAmount = 0

                    for index, amount in pairs(Rebirths) do
                        local price = (basePrice + currentRebirths * multiplier) * amount
                                    + multiplier * (amount * (amount - 1) / 2)

                        if clicks >= price and amount > bestAmount then
                            bestAmount = amount
                            bestIndex = index
                        end
                    end
                    return bestIndex
                end)

                if not success then
                end

                return success and result or nil
            end


            -- This function is now only called ONCE.
            updateRebirthDropdown = function()
                pcall(function()
                    local options = getAllRebirthOptions() 
                    rebirthOptions = options
                    local dropdownValues = {"Max Unlocked"}
                    for _, option in ipairs(options) do table.insert(dropdownValues, option.display) end
                    if rebirthDropdown then rebirthDropdown:SetValues(dropdownValues) end
                end)
            end

            performRebirth = function()
                local rebirthIndex
                if isMaxUnlockedSelected then
                    -- This is called repeatedly by the toggle, always getting the latest best option.
                    rebirthIndex = GetBestRebirthOption()
                elseif selectedRebirthIndex > 0 and selectedRebirthIndex <= #rebirthOptions then
                    rebirthIndex = rebirthOptions[selectedRebirthIndex].index
                end
                if rebirthIndex then
                    RebirthService:rebirth(rebirthIndex)
                    return true
                end
                return false
            end

            rebirthDropdown = RebirthSection:Dropdown("RebirthDropdown", {
                Title = "Select Rebirth Amount", Values = {}, Searchable = true, Default = "Max Unlocked", Multi = false,
                Callback = function(selectedValue)
                    if selectedValue == "Max Unlocked" then
                        isMaxUnlockedSelected = true
                    else
                        isMaxUnlockedSelected = false
                        for i, option in ipairs(rebirthOptions) do
                            if option.display == selectedValue then selectedRebirthIndex = i; break end
                        end
                    end
                end
            })



            local rebirthDelayInput = RebirthSection:AddInput("BestRebirthDelay", {
            Title = "Best Rebirth Delay (seconds)",
            Default = "",
            Numeric = true,
            Finished = false
            })

            local AutoRebirth = RebirthSection:Toggle("AutoRebirth", {
            Title = "Auto Rebirth", Default = false
            })


            pcall(updateRebirthDropdown)

            
            RebirthSection:Paragraph("RebirthInfo", {
            Title = "Rebirth Info",
            Content = "The dropdown lets you rebirth to any amount, even if it's not unlocked. The input above will automatically rebirth to the best option you can afford every X seconds (if set). Leave blank or 0 to use the dropdown value.",
            TitleAlignment = "Middle"
            })

            AutoRebirth:OnChanged(function(Value)
                autoRebirthRunning = Value
                if autoRebirthThread then
                    task.cancel(autoRebirthThread)
                    autoRebirthThread = nil
                end
                if Value then
                    autoRebirthThread = task.spawn(function()
                        while autoRebirthRunning do
                            local delay = tonumber(rebirthDelayInput.Value)
                            if not delay or delay == 0 then
                                -- Use the dropdown selection (calls performRebirth)
                                local result = pcall(performRebirth)
                                task.wait(0.2)
                            else
                                -- Use the "best option" logic with delay
                                task.wait(delay)
                                local bestOption = GetBestRebirthOption()
                                if bestOption then
                                    local result = pcall(function() RebirthService:rebirth(bestOption) end)
                                end
                                task.wait(0.1)
                            end
                        end
                    end)
                end
            end)
                


            local UpgradesSection = Tabs.Main:AddSection("Player Upgrades")
            local ActiveThreads = {}

            TerminateThread = function(index)
                if ActiveThreads[index] then
                    ActiveThreads[index].IsRunning = false
                    ActiveThreads[index] = nil
                end
            end

            CreateThread = function(index, fn)
                local thread = {IsRunning = true, Thread = fn}
                ActiveThreads[index] = thread
                task.spawn(function() thread.Thread(thread) end)
            end

            local upgradeValues = {}
            local UpgradesModule = require(ReplicatedStorage.Shared.List.Upgrades)
            for id, data in pairs(UpgradesModule) do
                table.insert(upgradeValues, {Name = id:sub(1,1):lower()..id:sub(2), Value = id})
            end

            local upgradesDropdown = UpgradesSection:Dropdown("UpgradesDropdown", {
                Title = "Select Upgrades", Values = upgradeValues, Multi = true, Searchable = true, Default = {},
                Displayer = function(item) return item.Name end
            })

            upgradesDropdown:OnChanged(function(value) end) -- Callback for potential future use

            UpgradesSection:Toggle("AutoBuyToggle", {
                Title = "Auto Buy Upgrades", Default = false,
                Callback = function(state)
                    if not state then TerminateThread("AutoBuyUpgrades"); return end
                    CreateThread("AutoBuyUpgrades", function(thread)
                        DataController:waitForData()
                        while thread.IsRunning and task.wait(0.5) do
                            local selected = upgradesDropdown.Value
                            for upgradeData, isSelected in pairs(selected) do
                                if isSelected then
                                    if not thread.IsRunning then break end
                                    local id = upgradeData.Value
                                    local def = UpgradesModule[id]
                                    if def and not (def.requiredMap and not DataController.data.maps[def.requiredMap]) then
                                        local level = (DataController.data.upgrades[id] or 0) + 1
                                        local costData = def.upgrades[level]
                                        if costData and costData.cost <= DataController.data.gems then
                                            if UpgradeService:upgrade(id) then task.wait(0.1) end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
            })

            local SkillTreeSection = Tabs.Main:AddSection("Skill Tree")

            local autoSkillTreeUpgradeEnabled = false

            SkillTreeSection:Toggle("AutoUpgradeSkills", {
                Title = "Auto Upgrade Skills",
                Description = "Automatically buys all affordable skill tree upgrades you don't own.",
                Default = false,
                Callback = function(enabled)
                    autoSkillTreeUpgradeEnabled = enabled
                    if enabled then
                        task.spawn(function()
                            local KnitClient = require(game:GetService("ReplicatedStorage").Packages.Knit.KnitClient)
                            local SkillTreeService = KnitClient.GetService("SkillTreeService")
                            local SkillTreeList = require(ReplicatedStorage.Shared.List.SkillTree)

                            while autoSkillTreeUpgradeEnabled do
                                pcall(function()
                                    DataController:waitForData()
                                    local playerData = DataController:getData()

                                    -- Build currency lookup table
                                    local playerCurrencies = {}
                                    if playerData.inventory and playerData.inventory.currency then
                                        for _, currencyData in pairs(playerData.inventory.currency) do
                                            playerCurrencies[currencyData.nm] = currencyData.am
                                        end
                                    end
                                    if playerData.dungeonCoins then
                                        playerCurrencies["dungeonCoins"] = playerData.dungeonCoins
                                    end
                                    if playerData.gems then
                                        playerCurrencies["gems"] = playerData.gems
                                    end
                                    if playerData.inventory and playerData.inventory.exclusive then
                                        for _, exclusiveData in pairs(playerData.inventory.exclusive) do
                                            if exclusiveData.am then
                                                playerCurrencies[exclusiveData.nm] = exclusiveData.am
                                            end
                                        end
                                    end

                                    -- Loop through each category
                                    for categoryId, categoryData in pairs(SkillTreeList) do
                                        local upgradesName = tostring(categoryId)
                                        for subcategoryName, subcategoryData in pairs(categoryData.list) do
                                            for index, upgradeData in ipairs(subcategoryData.list) do
                                                local upgradeKey = subcategoryName .. "_" .. index
                                                local isOwned = false
                                                if playerData.skillTree and playerData.skillTree[categoryId] then
                                                    isOwned = playerData.skillTree[categoryId][upgradeKey] == true
                                                end
                                                if not isOwned then
                                                    -- Get price and currency
                                                    local price = upgradeData.price or 0
                                                    local currencyName = "gems"
                                                    if upgradeData.currency then
                                                        if upgradeData.currency == "dungeonCoins" then
                                                            currencyName = "dungeonCoins"
                                                        elseif type(upgradeData.currency) == "table" then
                                                            if type(upgradeData.currency.nm) == "string" then
                                                                currencyName = upgradeData.currency.nm
                                                            elseif type(upgradeData.currency.getRealName) == "function" then
                                                                currencyName = upgradeData.currency:getRealName():lower():gsub(" ", "")
                                                            end
                                                        elseif type(upgradeData.currency) == "string" then
                                                            currencyName = upgradeData.currency
                                                        end
                                                    end
                                                    local playerCurrencyAmount = playerCurrencies[currencyName] or 0
                                                    if playerCurrencyAmount >= price then
                                                        -- Buy the upgrade
                                                        SkillTreeService:buySkillTree(upgradesName, subcategoryName, index)
                                                        task.wait(0.2)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end)
                                task.wait(5)
                            end
                        end)
                    end
                end
            })
                        
            local EggHatchingSection = Tabs.Eggs:AddSection("Auto Hatch")

            local EggsModule = require(ReplicatedStorage.Shared.List.Pets.Eggs)
            local EggUtils = require(ReplicatedStorage.Shared.Util.EggUtils)
            local SuffixToNumber = require(ReplicatedStorage.Shared.Functions.SuffixToNumber)

            local suffixes = {}
            for suffix, power in pairs(debug.getupvalue(SuffixToNumber, 1)) do
                suffixes[power] = suffix
            end

            local function formatNumber(num)
                if num < 1000 then return tostring(num) end
                local bestPower = 0
                for power, _ in pairs(suffixes) do
                    if num >= 10^(power * 3) and power > bestPower then
                        bestPower = power
                    end
                end
                if bestPower > 0 then
                    local value = num / (10 ^ (bestPower * 3))
                    local suffix = suffixes[bestPower]
                    return string.format("%.2f%s", value, suffix):gsub("%.00", "")
                end
                return tostring(num)
            end

            local eggsTable, displayToEggName = {}, {}
            for eggName, eggData in pairs(EggsModule) do
                if typeof(eggData) == "table" and eggData.cost then
                    table.insert(eggsTable, {name = eggName, cost = eggData.cost, currency = EggUtils.getCurrency(eggName) or "clicks"})
                end
            end
            table.sort(eggsTable, function(a, b) return a.cost < b.cost end)

            local eggOptions = {}
            for _, eggInfo in ipairs(eggsTable) do
                local displayName = eggInfo.name .. " - " .. formatNumber(eggInfo.cost) .. " " .. eggInfo.currency
                table.insert(eggOptions, displayName)
                displayToEggName[displayName] = eggInfo.name
            end

            local isSecretEggModeActive = false
            local secretEggNameToHatch = "Basic"
            local selectedEgg = eggsTable[1] and eggsTable[1].name or "Basic"
            local defaultEgg = eggOptions[1] or "Basic"

            table.insert(eggOptions, "Best Egg (Clicks)")
            table.insert(eggOptions, "Secret Egg (15 Space Coins)")

            EggDropdown = EggHatchingSection:Dropdown("SelectEgg", {
                Title = "Select Egg",
                Values = eggOptions,
                Default = defaultEgg,
                Multi = false,
                Searchable = true,
                Callback = function(Value)
                    if Value == "Secret Egg (15 Space Coins)" then
                        isSecretEggModeActive = true
                        task.spawn(function()
                            pcall(function()
                                local data = DataController:getData()
                                if data then secretEggNameToHatch = Util.eggUtils.getBestEgg(data) end
                            end)
                        end)
                    else
                        isSecretEggModeActive = false
                        if Value == "Best Egg (Clicks)" then
                            DataController:waitForData()
                            local playerData = DataController:getData()
                            local highestMap = 0
                            if playerData and playerData.maps then
                                for mapNumber, _ in pairs(playerData.maps) do
                                    if tonumber(mapNumber) and tonumber(mapNumber) > highestMap then
                                        highestMap = tonumber(mapNumber)
                                    end
                                end
                            end
                            local bestEggName = nil
                            for eggName, eggData in pairs(EggsModule) do
                                if eggData.requiredMap == highestMap and (eggData.currency == "clicks" or not eggData.currency) then
                                    bestEggName = eggName
                                    break
                                end
                            end
                            selectedEgg = bestEggName or selectedEgg
                        else
                            selectedEgg = displayToEggName[Value] or (Value:match("^(.-) %-") or Value)
                        end
                    end
                end
            })

            local hatchAmounts = {["1x"]=1, ["3x"]=3, ["Max"]=99}
            HatchAmount = EggHatchingSection:Dropdown("SelectHatchAmount", {
                Title = "Select Hatch Amount", Values = {"1x", "3x", "Max"}, Multi = false, Default = "Max",
                Callback = function(Value) end
            })

            local useLuckyEggs = false
            LuckyEgg = EggHatchingSection:Toggle("HatchLuckyEggs", {
                Title = "Use Lucky Eggs", Default = false,
                Callback = function(enabled) useLuckyEggs = enabled end
            })

            _G.SmartHatchDelay = 4.11
            task.spawn(function()
                local hatchTimeLabel = LocalPlayer.PlayerGui.MainUI.Menus.SettingsFrame.Main.List.Multipliers.HatchingSpeed.Main.Amount
                while true do
                    local success, labelText = pcall(function() return hatchTimeLabel.Text end)
                    if success and labelText then
                        local numberString = string.match(labelText, "%d+%.?%d*")
                        if numberString then _G.SmartHatchDelay = (tonumber(numberString) or 4.01) + 0.1 end
                    end
                    task.wait(5)
                end
            end)

            task.spawn(function()
                while true do
                    if _G.AutoHatchEnabled and not HatchingController._isHatching then
                        pcall(function()
                            local currentHatchAmount = hatchAmounts[HatchAmount.Value] or 99
                            
                            if isSecretEggModeActive then
                                EggService.openEgg._re:FireServer(secretEggNameToHatch, currentHatchAmount, {isBestEgg=true})
                            else
                                local args = {selectedEgg, currentHatchAmount}
                                if useLuckyEggs then
                                    local bestLuckyEggId, highestMultiplier = nil, 0
                                    for luckyEggId, _ in pairs(EggController._luckyEggs or {}) do
                                        local multiplier = (EggController._globalLuckEventAmount or 0) * 1000
                                        if multiplier > highestMultiplier then
                                            highestMultiplier, bestLuckyEggId = multiplier, luckyEggId
                                        end
                                    end
                                    if bestLuckyEggId then table.insert(args, {luckyEggId = bestLuckyEggId}) end
                                end
                                EggService.openEgg._re:FireServer(unpack(args))
                            end
                        end)
                    end
                    task.wait(0.17)
                end
            end)

            local AutoHatch = EggHatchingSection:Toggle("AutoHatch", {
                Title = "Auto Hatch Eggs",
                Default = false,
                Callback = function(Value)
                    _G.AutoHatchEnabled = Value
                end
            })

            local HatchingController = require(LocalPlayer.PlayerScripts.Client.Controllers.HatchingController)

            -- Save the original function once
            if not HatchingController._realPlayEggAnimation then
                HatchingController._realPlayEggAnimation = HatchingController.playEggAnimation
            end

            -- State variable
            local isHatchHidden = false

            -- Overwrite the function
            HatchingController.playEggAnimation = function(self, ...)
                if isHatchHidden then
                    return nil 
                else
                    return HatchingController._realPlayEggAnimation(self, ...)
                end
            end

            -- Your UI Toggle Code
            HideAnimationToggle = EggHatchingSection:Toggle("HideHatchAnimation", {
                Title = "Hide Hatch Animation", 
                Default = false,
                Callback = function(Value)
                    isHatchHidden = Value
                end
            })
                    
            local AutoIndexSection = Tabs.Eggs:AddSection("Index")

            local InstructionsParagraph = AutoIndexSection:Paragraph("AutoIndexInstructions", {
                Title = "Instructions",
                Content = "Select pet variants to index. Eggs must be unlocked to work, so don't select an egg you haven't unlocked yet. Eggs that require being built WILL work, even without building them.",
                TitleAlignment = "Middle"
            })

            -- --- State Variables for the Auto Indexer ---
            local autoIndexRunning = false
            local autoIndexThread = nil
            local selectedVariants = {}
            local selectedEggsForIndex = {}
            local originalSettings = {}

            -- --- Data for the Variants Dropdown ---
            local VARIANT_OPTIONS = {}
            local TIER_NAMES = { "Normal", "Golden", "Toxic", "Galaxy" }
            for tierIndex, tierName in ipairs(TIER_NAMES) do
                table.insert(VARIANT_OPTIONS, { Name = tierName, Tier = tierIndex, Shiny = false, RarityGroup = "STANDARD" })
            end
            for _, rarityGroup in ipairs({"Eternal", "Secret"}) do
                for tierIndex, tierName in ipairs(TIER_NAMES) do
                    table.insert(VARIANT_OPTIONS, { Name = tierName .. " " .. rarityGroup, Tier = tierIndex, Shiny = false, RarityGroup = rarityGroup })
                end
            end
            local variantDisplayNames = {}
            for _, v in ipairs(VARIANT_OPTIONS) do table.insert(variantDisplayNames, v.Name) end

            -- --- UI Elements ---
            local VariantsDropdown = AutoIndexSection:Dropdown("SelectVariants", {
                Title = "Select Variants to Index",
                Values = variantDisplayNames, Multi = true, Searchable = true, Default = {},
                Callback = function(value) selectedVariants = value end
            })

            local allEggNamesForDropdown = {}
            for name, data in pairs(EggsModule) do if data.pets and not name:find("Exclusive") then table.insert(allEggNamesForDropdown, name) end end
            table.sort(allEggNamesForDropdown)

            local IndexEggDropdown = AutoIndexSection:Dropdown("SelectEggsToIndex", {
                Title = "Select Eggs (leave empty for all)",
                Values = allEggNamesForDropdown, Multi = true, Searchable = true, Default = {},
                Callback = function(value) selectedEggsForIndex = value end
            })

            local AutoIndexStatusParagraph = AutoIndexSection:Paragraph("AutoIndexStatus", {
                Title = "Current Status", Content = "Idle.", TitleAlignment = "Middle"
            })

            local AutoIndexToggle = AutoIndexSection:Toggle("AutoIndexToggle", {
                Title = "Auto Index",
                Description = "Automatically works to complete your index based on the selected variants.",
                Default = false,
                Callback = function(enabled)
                    autoIndexRunning = enabled
                    if autoIndexThread then task.cancel(autoIndexThread); autoIndexThread = nil end

                    if enabled then
                        originalSettings = { egg = EggDropdown.Value, amount = HatchAmount.Value, autoHatch = AutoHatch.Value }
                        IndexHasBeenOn = true
                        
                        autoIndexThread = task.spawn(function()
                            local EggsModule = require(ReplicatedStorage.Shared.List.Pets.Eggs)
                            local Pets = require(ReplicatedStorage.Shared.List.Pets.Pets)
                            local Tiers = require(ReplicatedStorage.Shared.List.Pets.Tiers)
                            
                            -- === NEW: Main persistent loop ===
                            while autoIndexRunning do
                                local allEggs = {}
                                if not next(selectedEggsForIndex) then
                                    for name, data in pairs(EggsModule) do 
                                        if data.pets and not name:find("Exclusive") then 
                                            table.insert(allEggs, { Name = name, Data = data }) 
                                        end 
                                    end
                                else
                                    for eggName, isSelected in pairs(selectedEggsForIndex) do
                                        if isSelected and EggsModule[eggName] then 
                                            table.insert(allEggs, { Name = eggName, Data = EggsModule[eggName] }) 
                                        end
                                    end
                                end
                                table.sort(allEggs, function(a, b) return (a.Data.requiredMap or 0) < (b.Data.requiredMap or 0) end)

                                for _, eggInfo in ipairs(allEggs) do
                                    if not autoIndexRunning then break end
                                    local currentEggName, currentEggData = eggInfo.Name, eggInfo.Data
                                    
                                    while autoIndexRunning do
                                        local playerData = DataController:getData()
                                        if not playerData then task.wait(1); continue end

                                        local highestMap = 0
                                        if playerData.maps then 
                                            for mapId, _ in pairs(playerData.maps) do 
                                                local numId = tonumber(mapId); 
                                                if numId and numId > highestMap then highestMap = numId end 
                                            end 
                                        end
                                        local requiredMap = currentEggData.requiredMap or 0
                                        local isUnlocked = highestMap >= requiredMap
                                        if not isUnlocked then break end

                                        local playerIndex = playerData.index or {}
                                        local shouldCraftNow = false
                                        local goals, needsToCraft, ownedForCrafting = {}, {}, {}

                                        for petName, _ in pairs(currentEggData.pets) do
                                            if type(petName) ~= "string" or not Pets[petName] then continue end
                                            local petDef = Pets[petName]
                                            if petDef.rarity == "Divine" or petDef.rarity == "Supreme" or petDef.rarity == "Ultimate" then continue end

                                            for _, variant in ipairs(VARIANT_OPTIONS) do
                                                if selectedVariants[variant.Name] then
                                                    -- Skip Galaxy variants for World 1 pets
                                                    if variant.Name:find("Galaxy") then
                                                        local MapsModule = require(ReplicatedStorage.Shared.List.Maps)
                                                        local requiredMap = currentEggData.requiredMap or 0
                                                        local worldNum = 1
                                                        if requiredMap and MapsModule[requiredMap] and MapsModule[requiredMap].world then
                                                            worldNum = MapsModule[requiredMap].world
                                                        end
                                                        if worldNum < 2 then
                                                            continue -- skip Galaxy for World 1 pets
                                                        end
                                                    end

                                                    local rarityMatch = (variant.RarityGroup == "STANDARD" and petDef.rarity ~= "Eternal" and petDef.rarity ~= "Secret") or (variant.RarityGroup == petDef.rarity)
                                                    if rarityMatch then
                                                        local isMissing = true
                                                        local descriptor = petName:lower():gsub(" ","") .. ":" .. variant.Tier .. (variant.Shiny and ":s" or "")
                                                        if playerIndex[descriptor] then isMissing = false end
                                                        if isMissing then
                                                            table.insert(goals, variant.Name .. " " .. petName)
                                                            if variant.Tier and variant.Tier > 1 then 
                                                                needsToCraft[petName .. ":" .. (variant.Tier - 1) .. (variant.Shiny and ":s" or "")] = true 
                                                            end
                                                        end
                                                    end
                                                end
                                            end 
                                        end

                                        if #goals == 0 then
                                            AutoIndexStatusParagraph:SetValue(string.format("Egg '%s' complete! Moving to next...", currentEggName))
                                            task.wait(2); break
                                        end
                                        
                                        AutoIndexStatusParagraph:SetValue(string.format("Working on Egg: %s\nIndexing: %s", currentEggName, table.concat(goals, ", ")))
                                        
                                        local petOptions = getPlayerPetOptions(); task.wait(2)

                                        for petName, _ in pairs(currentEggData.pets) do
                                            for displayName, petId in pairs(petDisplayToId) do
                                                if displayName:find(petName) then
                                                    local petRawData = petId and playerData.inventory.pet[petId]
                                                    if petRawData and (petRawData.am or 0) >= 5 then
                                                        ownedForCrafting[displayName] = true
                                                        shouldCraftNow = true
                                                    end
                                                end
                                            end
                                        end

                                        if shouldCraftNow then
                                            local validCrafts = {}
                                            for dn, _ in pairs(ownedForCrafting) do
                                                validCrafts[dn] = true 
                                            end
                                            if PetDropdown and PetDropdown.SetValue then
                                                PetDropdown:SetValues(getPlayerPetOptions()) 
                                                PetDropdown:SetValue(validCrafts)
                                                for displayName, _ in pairs(validCrafts) do
                                                    if not autoIndexRunning then break end
                                                    local petId = petDisplayToId[displayName]
                                                    if petId then
                                                        local success, err = pcall(function() PetService:craft({[1]=petId}, false, 1) end)
                                                        if not success then
                                                        end
                                                        task.wait(0.5)
                                                    else
                                                    end
                                                end
                                            else
                                            end
                                        end
                            
                                        local currency = EggUtils.getCurrency(currentEggName) or "clicks"
                                        local balance = EggUtils.getDataCurrency(playerData, currency) or 0
                                        local isAffordable = balance >= (currentEggData.cost or 0)

                                        if isAffordable then
                                            if EggDropdown.Value ~= currentEggName or not AutoHatch.Value then
                                                for _, eggOption in ipairs(eggOptions) do 
                                                    if displayToEggName[eggOption] == currentEggName then 
                                                        EggDropdown:SetValue(eggOption, false); 
                                                        break 
                                                    end 
                                                end
                                                HatchAmount:SetValue("Max", false)
                                                AutoHatch:SetValue(true, false)
                                            end
                                        else
                                            if AutoHatch.Value then AutoHatch:SetValue(false, false) end
                                            AutoIndexStatusParagraph:SetValue(string.format("Not enough %s for '%s'. Skipping...", currency, currentEggName))
                                            task.wait(2); break
                                        end
                                        
                                        task.wait(5)
                                    end
                                end
                                
                                if not autoIndexRunning then break end
                                AutoIndexStatusParagraph:SetValue("Cycle complete. Re-checking in 5 seconds...")
                                task.wait(5)
                            end
                        end)
                    elseif IndexHasBeenOn == true then
                        if originalSettings.egg then EggDropdown:SetValue(originalSettings.egg, false) end
                        if originalSettings.amount then HatchAmount:SetValue(originalSettings.amount, false) end
                        AutoHatch:SetValue(originalSettings.autoHatch, false)
                        AutoIndexStatusParagraph:SetValue("Idle.")
                    end
                end
            })

            local TreeSection = Tabs.Tree:AddSection("Auto Break Trees")

            TreeSection:Paragraph("Tree",{
                Title = "Note",
                Content = "If you have auto hatch enabled, the speed in which you can break trees will massively decline. For best results, disable auto hatch while using the auto cut trees toggle.",
                TitleAlignment = "Middle",
                ContentAlignment = Enum.TextXAlignment.Left
            })

            getTreeTypes = function()
                local treeList = {}
                local Trees = require(ReplicatedStorage.Shared.List.Trees)

                for zoneName, zoneData in pairs(Trees) do
                    if zoneName:lower() ~= "fall" and zoneData.trees and #zoneData.trees > 0 then
                        local treeInfo = zoneData.trees[1]
                        local hp = treeInfo.hp or 0
                        local itemName = "Wood"
                        
                        if treeInfo and treeInfo.item then
                            local item = treeInfo.item
                            itemName = item.id or item.Name or item.name or (typeof(item.getId) == "function" and item:getId()) or (typeof(item.getName) == "function" and item:getName()) or (zoneName .. "Wood")
                            itemName = itemName:sub(1,1):upper() .. itemName:sub(2)
                        end

                        local displayName = zoneName:sub(1,1):upper() .. zoneName:sub(2) .. " (" .. itemName .. ")"
                        table.insert(treeList, {
                            Name = displayName,
                            Value = zoneName,
                            HP = hp,
                            Wood = itemName
                        })
                    end
                end

                table.sort(treeList, function(a, b) return a.HP < b.HP end)
                return treeList
            end

            mapWoodToTreeWorld = function(woodName)
                if woodName:lower() == "wood" then
                    return "spawn"
                end
                
                local Trees = require(ReplicatedStorage.Shared.List.Trees)
                
                for zoneName, zoneData in pairs(Trees) do
                    if zoneData.trees and #zoneData.trees > 0 then
                        local treeInfo = zoneData.trees[1]
                        if treeInfo and treeInfo.item then
                            local item = treeInfo.item
                            local itemName = item.id or item.Name or item.name or (typeof(item.getId) == "function" and item:getId()) or (typeof(item.getName) == "function" and item:getName())
                            if itemName and itemName:lower() == woodName:lower() then return zoneName end
                        end
                    end
                end
                
                local woodMappings = {
                    ["wood"] = "spawn",
                }
                return woodMappings[woodName:lower()] or "spawn"
            end

            getLumberId = function()
                local success, lumberId = pcall(debug.getupvalue, TreeController.autoDamageTree, 4)
                if success and type(lumberId) == "string" and #lumberId >= 32 then return lumberId end
                if TreeController._v_u_22 then return TreeController._v_u_22 end
                TreeController:getLumberId()
                task.wait(0.2)
                success, lumberId = pcall(debug.getupvalue, TreeController.autoDamageTree, 4)
                return (success and type(lumberId) == "string" and #lumberId >= 32) and lumberId or "70c6c87e76cd49409ce604d9cc0616ac"
            end

            selectedTrees = {}
            autoBreakRunning = false

            SelectTreesDropdown = TreeSection:Dropdown("SelectTrees", {
                Title = "Select Tree(s)",
                Description = "Choose which trees to automatically cut",
                Values = getTreeTypes(),
                Multi = true,
                Searchable = true,
                Default = {},
                Displayer = function(item) return item.Name end,
                Callback = function(value)
                    selectedTrees = {}
                    for treeType, isSelected in pairs(value) do
                        if isSelected then table.insert(selectedTrees, treeType.Value) end
                    end
                end
            })

            do
                local spawnTreeObject = nil
                for _, treeObject in ipairs(SelectTreesDropdown.Values) do
                    if treeObject.Value == "spawn" then
                        spawnTreeObject = treeObject
                        break
                    end
                end
                if spawnTreeObject then
                    SelectTreesDropdown:SetValue({[spawnTreeObject] = true})
                end
            end

            getActiveTreesInGroup = function(groupId, data)
                local treesWithHealth = {}
                local mapsFolder = Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Maps")
                if not mapsFolder then return treesWithHealth end

                local mapName
                for _, map in pairs(mapsFolder:GetChildren()) do
                    if map.Name:lower() == groupId:lower() then
                        mapName = map.Name
                        break
                    end
                end

                if not mapName then return treesWithHealth end
                local treesFolder = mapsFolder[mapName]:FindFirstChild("Trees")
                if not treesFolder then return treesWithHealth end

                for _, tree in pairs(treesFolder:GetChildren()) do
                    local treeId = tree:GetAttribute("treeId")
                    local hasModel = tree:FindFirstChildWhichIsA("Model") ~= nil

                    if treeId and hasModel and 
                    data.trees[groupId] and data.trees[groupId][treeId] and 
                    data.trees[groupId][treeId].hp > 0 and 
                    not data.trees[groupId][treeId].respawn then

                        table.insert(treesWithHealth, {
                            treeId = treeId,
                            hp = data.trees[groupId][treeId].hp,
                            instance = tree,
                            groupId = groupId
                        })
                    end
                end

                table.sort(treesWithHealth, function(a, b) return a.hp < b.hp end)
                return treesWithHealth
            end

            AutoCutTreesToggle = TreeSection:Toggle("AutoCutTrees", {
                Title = "Auto Cut Trees",
                Description = "Self explanatory. Requires an axe to be equipped.",
                Default = false,
                Callback = function(Value)
                    autoBreakRunning = Value

                    if Value then
                        local treeControllerThread = task.spawn(function()
                            if not game:IsLoaded() then game.Loaded:Wait() end

                            local function simulateClickOnClosestTree()
                                pcall(function()
                                    local originalGetRay = TreeController.getRay
                                    TreeController.getRay = function(self, _, _) return true end

                                    local originalGetTreeFromRayResult = TreeController.getTreeFromRayResult
                                    local targetTree = nil

                                    TreeController.getTreeFromRayResult = function(_, _) return targetTree end

                                    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                        TreeController.getRay = originalGetRay
                                        TreeController.getTreeFromRayResult = originalGetTreeFromRayResult
                                        return
                                    end

                                    local data = DataController:getData()
                                    if not data or not data.trees then
                                        TreeController.getRay = originalGetRay
                                        TreeController.getTreeFromRayResult = originalGetTreeFromRayResult
                                        return
                                    end

                                    local closestDistance = math.huge
                                    local playerPosition = LocalPlayer.Character.HumanoidRootPart.Position

                                    for _, groupId in ipairs(selectedTrees) do
                                        if data.trees[groupId] then
                                            for _, tree in pairs(CollectionService:GetTagged("Tree")) do
                                                local model = tree:FindFirstChildWhichIsA("Model")
                                                if not model then continue end

                                                local treeGroupId = tree:GetAttribute("groupId")
                                                local treeId = tree:GetAttribute("treeId")

                                                if treeGroupId == groupId and treeId and 
                                                data.trees[groupId][treeId] and 
                                                data.trees[groupId][treeId].hp > 0 and
                                                not data.trees[groupId][treeId].respawn then

                                                    local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                                                    if primaryPart then
                                                        local distance = (primaryPart.Position - playerPosition).Magnitude
                                                        if distance < closestDistance then
                                                            closestDistance = distance
                                                            targetTree = tree
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end

                                    if not targetTree then
                                        TreeController.getRay = originalGetRay
                                        TreeController.getTreeFromRayResult = originalGetTreeFromRayResult
                                        return
                                    end

                                    TreeController:sendRayFromInput(0, 0)
                                    TreeController.getRay = originalGetRay
                                    TreeController.getTreeFromRayResult = originalGetTreeFromRayResult
                                end)
                            end

                            while autoBreakRunning do
                                simulateClickOnClosestTree()
                                task.wait(1)
                            end
                        end)

                        local teleportThread = task.spawn(function()
                            if not game:IsLoaded() then game.Loaded:Wait() end

                            local lumberId = getLumberId()
                            local currentGroup, currentId, lastTeleportTime = nil, nil, 0
                            math.randomseed(os.time() + os.clock() * 1000)

                            local data = DataController:getData()
                            while not data or not data.trees do
                                task.wait(0.5)
                                data = DataController:getData()
                            end

                            local function selectRandomTreeGroup()
                                data = DataController:getData()
                                if not data or not data.trees then return nil end

                                local validGroups = {}
                                for _, groupId in ipairs(selectedTrees) do
                                    if data.trees[groupId] then
                                        local hasActiveTrees = false
                                        for treeId, treeData in pairs(data.trees[groupId]) do
                                            if treeData.hp > 0 and not treeData.respawn then
                                                hasActiveTrees = true
                                                break
                                            end
                                        end
                                        if hasActiveTrees then table.insert(validGroups, groupId) end
                                    end
                                end

                                return #validGroups > 0 and validGroups[math.random(1, #validGroups)] or nil
                            end

                            local function findAndTeleportToRandomTree()
                                currentGroup = selectRandomTreeGroup()
                                if not currentGroup then return false end

                                if data.trees[currentGroup] then
                                    local activeTrees = getActiveTreesInGroup(currentGroup, data)
                                    if #activeTrees > 0 then
                                        local randomTreeIndex = math.random(1, #activeTrees)
                                        currentId = activeTrees[randomTreeIndex].treeId

                                        local teleportSuccess = pcall(function()
                                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                                local mapsFolder = Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Maps")
                                                if mapsFolder then
                                                    local mapName = nil
                                                    for _, map in pairs(mapsFolder:GetChildren()) do
                                                        if map.Name:lower() == currentGroup:lower() then
                                                            mapName = map.Name
                                                            break
                                                        end
                                                    end

                                                    if mapName then
                                                        local treesFolder = mapsFolder[mapName]:FindFirstChild("Trees")
                                                        if treesFolder then
                                                            for _, tree in pairs(treesFolder:GetChildren()) do
                                                                if tree:GetAttribute("treeId") == currentId then
                                                                    local model = tree:FindFirstChildWhichIsA("Model")
                                                                    if model then
                                                                        LocalPlayer.Character.HumanoidRootPart.CFrame = model:GetPivot() + Vector3.new(0, 5, 0)
                                                                        lastTeleportTime = os.time()
                                                                        return true
                                                                    end
                                                                    break
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            return false
                                        end)

                                        if teleportSuccess then
                                            return true
                                        else
                                            currentGroup, currentId = nil, nil
                                            return false
                                        end
                                    end
                                end

                                currentGroup, currentId = nil, nil
                                return false
                            end

                            while autoBreakRunning do
                                local shouldFindNewTree = not currentGroup or not currentId
                                
                                if not shouldFindNewTree then
                                    data = DataController:getData()
                                    if not data or not data.trees or 
                                    not data.trees[currentGroup] or 
                                    not data.trees[currentGroup][currentId] or
                                    data.trees[currentGroup][currentId].hp <= 0 or 
                                    data.trees[currentGroup][currentId].respawn then
                                        shouldFindNewTree = true
                                    end
                                end

                                if shouldFindNewTree then
                                    findAndTeleportToRandomTree()
                                else
                                    local currentTime = os.time()
                                    if (currentTime - lastTeleportTime >= 3) then
                                        pcall(function()
                                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                                local mapsFolder = Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Maps")
                                                if mapsFolder then
                                                    local mapName = nil
                                                    for _, map in pairs(mapsFolder:GetChildren()) do
                                                        if map.Name:lower() == currentGroup:lower() then
                                                            mapName = map.Name
                                                            break
                                                        end
                                                    end

                                                    if mapName then
                                                        local treesFolder = mapsFolder[mapName]:FindFirstChild("Trees")
                                                        if treesFolder then
                                                            for _, tree in pairs(treesFolder:GetChildren()) do
                                                                if tree:GetAttribute("treeId") == currentId then
                                                                    local model = tree:FindFirstChildWhichIsA("Model")
                                                                    if model then
                                                                        LocalPlayer.Character.HumanoidRootPart.CFrame = model:GetPivot() + Vector3.new(0, 5, 0)
                                                                        lastTeleportTime = currentTime
                                                                        return
                                                                    end
                                                                    break
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end)
                                    end
                                end

                                if currentGroup and currentId and 
                                data.trees[currentGroup] and 
                                data.trees[currentGroup][currentId] and
                                data.trees[currentGroup][currentId].hp > 0 and 
                                not data.trees[currentGroup][currentId].respawn then
                                    TreeService.damage2:Fire(currentGroup, currentId, lumberId)
                                end

                                task.wait(0.1)
                            end
                        end)

                        _G.TreeCuttingThreads = {
                            treeControllerThread = treeControllerThread,
                            teleportThread = teleportThread
                        }

                    else
                        if _G.TreeCuttingThreads then
                            for name, thread in pairs(_G.TreeCuttingThreads) do
                                if thread then task.cancel(thread) end
                            end
                            _G.TreeCuttingThreads = nil
                        end

                        if TreeController._currentTree then
                            TreeController:cancelAutoDamageTree()
                        end
                    end
                end
            })

            lowercooldown = TreeSection:Toggle("RemoveCooldown", {
                Title = "Reduce Cutting Cooldown",
                Description = "Reduces the cooldown between tree hits (about 1.5x faster). Already built in with the auto trees toggle.",
                Default = false,
                Callback = function(Value)
                    if Value then
                        TreeController._debounce = {}
                        TreeController._debounce = setmetatable({}, {
                            __index = function() return false end,
                            __newindex = function() end
                        })
                    else
                        TreeController._debounce = {}
                    end
                end
            })

            BypassStrength = TreeSection:Toggle("BypassTreeStrength", {
                Title = "Axe Strength Bypass",
                Description = "Allows you to cut any tree regardless of your current axe strength",
                Default = false,
                Callback = function(Value)
                    if Value then
                        if not TreeController._originalIsStrongEnough then
                            TreeController._originalIsStrongEnough = TreeController.isStrongEnough
                        end
                        TreeController.isStrongEnough = function() return true end
                    else
                        if TreeController._originalIsStrongEnough then
                            TreeController.isStrongEnough = TreeController._originalIsStrongEnough
                        end
                    end
                end
            })

            isAutoEquipAxeEnabled = false
            AutoEquip = TreeSection:Toggle("AutoEquipBestAxe", {
                Title = "Auto Equip Best Axe",
                Description = "Automatically equips the best axe you own.",
                Default = false,
                Callback = function(Value)
                    isAutoEquipAxeEnabled = Value
                    if Value then
                        task.spawn(function()
                            while isAutoEquipAxeEnabled do
                                pcall(function()
                                    DataController:waitForData()
                                    local playerData = DataController:getData()

                                    local axeInventoryIndex = nil
                                    for inventoryIndex, itemData in pairs(playerData.inventory.exclusive) do
                                        local itemObj = Util.itemUtils.createItemFromData(itemData)
                                        local itemName = itemObj:getName()

                                        -- Check if it's an axe (has "axe" but not "pickaxe")
                                        if itemName:lower():find("axe") and not itemName:lower():find("pickaxe") then
                                            axeInventoryIndex = inventoryIndex
                                            break
                                        end
                                    end

                                    if not axeInventoryIndex then return end

                                    local isAxeEquipped = playerData.isAxeEquipped

                                    if not isAxeEquipped then
                                        -- Find and unequip currently equipped item first
                                        local currentEquippedIndex = nil
                                        
                                        -- Check if pickaxe is equipped
                                        if playerData.isPickaxeEquipped then
                                            for inventoryIndex, itemData in pairs(playerData.inventory.exclusive) do
                                                local itemObj = Util.itemUtils.createItemFromData(itemData)
                                                local itemName = itemObj:getName()
                                                if itemName:lower():find("pickaxe") then
                                                    currentEquippedIndex = inventoryIndex
                                                    break
                                                end
                                            end
                                        end
                                        
                                        -- Check if fishing rod is equipped
                                        if playerData.isFishingRodEquipped and not currentEquippedIndex then
                                            for inventoryIndex, itemData in pairs(playerData.inventory.exclusive) do
                                                local itemObj = Util.itemUtils.createItemFromData(itemData)
                                                local itemName = itemObj:getName()
                                                if itemName:lower():find("fishingrod") or itemName:lower():find("rod") then
                                                    currentEquippedIndex = inventoryIndex
                                                    break
                                                end
                                            end
                                        end
                                        
                                        -- Unequip current item if found
                                        if currentEquippedIndex then
                                            InventoryService:useItem(currentEquippedIndex)
                                            task.wait(1)
                                        end
                                        
                                        -- Equip the axe
                                        InventoryService:useItem(axeInventoryIndex)
                                    end
                                end)

                                for i = 1, 50 do
                                    if not isAutoEquipAxeEnabled then break end
                                    task.wait(0.1)
                                end
                            end
                        end)
                    end
                end
            })

            task.spawn(function()
                while true do
                    if AutoCutTreesToggle.Value == false then
                        AutoEquip:SetValue(false)
                    elseif AutoCutTreesToggle.Value == true then
                        AutoEquip:SetValue(true)
                    end
                    task.wait(5)
                end
            end)


            UpgradeAxe = Tabs.Tree:AddSection("Upgrade Axe")
            
            UpgradeAxe:Button({
            Title = "Enable Recommended Settings",
            Description = "Automatically enables: Auto Equip Best Axe, Reduce Cutting Cooldown, and Axe Strength Bypass",
            Callback = function()
                AutoEquip:SetValue(true)
                lowercooldown:SetValue(true) 
                BypassStrength:SetValue(true)
            end})

            local UpgradeStatusParagraph = UpgradeAxe:Paragraph("AxeUpgradeStatus", {
                Title = "Axe Upgrade",
                Content = "Loading upgrade info...",
                TitleAlignment = "Middle",
                ContentAlignment = Enum.TextXAlignment.Left
            })

            updateAxeUpgradeStatus = function()
                pcall(function()
                    local ExclusiveItems = require(ReplicatedStorage.Shared.List.Items.Exclusive)
                    local Items = require(ReplicatedStorage.Shared.Items)
                    local AxesList = require(ReplicatedStorage.Shared.List.Axes)

                    DataController:waitForData()
                    local playerData = DataController:getData()

                    local currentAxeIndex = 0
                    for inventoryIndex, itemData in pairs(playerData.inventory.exclusive) do
                        local itemObj = Util.itemUtils.createItemFromData(itemData)
                        if itemObj:getName():lower():find("axe") and not itemObj:getName():lower():find("pickaxe") then
                            currentAxeIndex = itemObj:directory()[itemObj:getName()].index
                            break
                        end
                    end

                    if currentAxeIndex == 0 then
                        UpgradeStatusParagraph:SetValue("❌ No axe found in inventory!")
                        return
                    end

                    local nextAxeIndex = currentAxeIndex + 1
                    local nextAxe, nextAxeName = nil, nil

                    for itemName, itemData in pairs(ExclusiveItems) do
                        if itemName:lower():find("axe") and not itemName:lower():find("pickaxe") then
                            if itemData.index == nextAxeIndex then
                                nextAxe = Items.exclusive(itemName)
                                nextAxeName = itemName
                                break
                            end
                        end
                    end

                    if not nextAxe then
                        UpgradeStatusParagraph:SetValue("🎉 You have the maximum axe!")
                        return
                    end

                    local axeRequirements = AxesList[nextAxeName]
                    if not axeRequirements or not axeRequirements.required then
                        UpgradeStatusParagraph:SetValue("❌ No requirements found for next axe!")
                        return
                    end

                    local statusLines = {}
                    table.insert(statusLines, "🎯 Next: " .. nextAxe:getRealName())
                    table.insert(statusLines, "")
                    table.insert(statusLines, "📋 Materials Needed:")

                    local canUpgrade = true

                    for i, requiredItem in ipairs(axeRequirements.required) do
                        local itemName = requiredItem:getName()
                        local requiredAmount = requiredItem:getAmount()

                        local currentItem = Util.itemUtils.getItemFromName(playerData, itemName)
                        local currentAmount = currentItem and currentItem:getAmount() or 0

                        local hasEnough = requiredAmount <= currentAmount
                        if not hasEnough then canUpgrade = false end

                        local status = hasEnough and "✅" or "❌"
                        local progress = string.format("%s/%s", 
                            Functions.comma(currentAmount), 
                            Functions.comma(requiredAmount))

                        table.insert(statusLines, string.format("%s %s: %s", status, itemName, progress))
                    end

                    table.insert(statusLines, "")
                    table.insert(statusLines, "🔨 Status: " .. (canUpgrade and "Ready to upgrade!" or "Need more materials"))

                    UpgradeStatusParagraph:SetValue(table.concat(statusLines, "\n"))
                end)
            end
            
            task.spawn(function()
                while true do
                    updateAxeUpgradeStatus()
                    task.wait(5)
                end
            end)
            
            originalSelectedObjects = {}
            originalAutoCutState = false
            isAutoUpgradeEnabled = false
            treeToggleThread = nil

            manageTreeToggleCycle = function()
                while isAutoUpgradeEnabled do
                    if autoBreakRunning then
                        AutoCutTreesToggle:SetValue(false)
                    end
                    task.wait(1)
                    
                    if not autoBreakRunning then
                        AutoCutTreesToggle:SetValue(true)
                    end
                    task.wait(0.5)
                    
                    if autoBreakRunning then
                        AutoCutTreesToggle:SetValue(true)
                    end
                    task.wait(1)
                    
                    if not autoBreakRunning then
                        AutoCutTreesToggle:SetValue(true)
                    end
                    
                    task.wait(20)
                end
            end

            UpgradeAxe:Toggle("AutoUpgradeAxe", {
                Title = "Auto Upgrade Axe",
                Description = "Automatically upgrades your axe when materials are available\n\n⚠️ Recommended to enable:\n• Axe Strength Bypass\n• Auto Equip Best Axe",
                Default = false,
                Callback = function(enabled)
                    if enabled then
                        HasBeenEnabled1 = true
                        isAutoUpgradeEnabled = true
                        AutoEquip:SetValue(true)

                        originalSelectedObjects = {}
                        for treeObject, isSelected in pairs(SelectTreesDropdown.Value) do
                            originalSelectedObjects[treeObject] = isSelected
                        end

                        originalAutoCutState = autoBreakRunning

                        if treeToggleThread then task.cancel(treeToggleThread) end
                        treeToggleThread = task.spawn(manageTreeToggleCycle)

                        task.spawn(function()
                            while isAutoUpgradeEnabled do
                                pcall(function()
                                    local ExclusiveItems = require(ReplicatedStorage.Shared.List.Items.Exclusive)
                                    local Items = require(ReplicatedStorage.Shared.Items)
                                    local AxesList = require(ReplicatedStorage.Shared.List.Axes)

                                    DataController:waitForData()
                                    local playerData = DataController:getData()

                                    local currentAxeIndex = 0
                                    for inventoryIndex, itemData in pairs(playerData.inventory.exclusive) do
                                        local itemObj = Util.itemUtils.createItemFromData(itemData)
                                        if itemObj:getName():lower():find("axe") and not itemObj:getName():lower():find("pickaxe") then
                                            currentAxeIndex = itemObj:directory()[itemObj:getName()].index
                                            break
                                        end
                                    end

                                    if currentAxeIndex == 0 then return end

                                    local nextAxeIndex = currentAxeIndex + 1
                                    local nextAxeName = nil

                                    for itemName, itemData in pairs(ExclusiveItems) do
                                        if itemName:lower():find("axe") and not itemName:lower():find("pickaxe") then
                                            if itemData.index == nextAxeIndex then
                                                nextAxeName = itemName
                                                break
                                            end
                                        end
                                    end

                                    if not nextAxeName then
                                        isAutoUpgradeEnabled = false
                                        return
                                    end

                                    local nextAxe = Items.exclusive(nextAxeName)
                                    local axeRequirements = AxesList[nextAxeName]
                                    if not axeRequirements or not axeRequirements.required then return end

                                    local neededWoods = {}
                                    local canUpgrade = true

                                    for _, requiredItem in ipairs(axeRequirements.required) do
                                        local itemName = requiredItem:getName()
                                        local requiredAmount = requiredItem:getAmount()

                                        local currentItem = Util.itemUtils.getItemFromName(playerData, itemName)
                                        local currentAmount = currentItem and currentItem:getAmount() or 0

                                        if currentAmount < requiredAmount then
                                            canUpgrade = false
                                            if itemName:lower():find("wood") then
                                                table.insert(neededWoods, itemName)
                                            end
                                        end
                                    end

                                    if canUpgrade then
                                        AxeService:upgradeAxe()
                                        task.wait(2)
                                    else
                                        local neededTreeObjects = {}
                                        for _, woodName in ipairs(neededWoods) do
                                            local treeWorld = mapWoodToTreeWorld(woodName)
                                            for _, treeObject in ipairs(SelectTreesDropdown.Values) do
                                                if treeObject.Value == treeWorld then
                                                    neededTreeObjects[treeObject] = true
                                                    break
                                                end
                                            end
                                        end

                                        SelectTreesDropdown:SetValue(neededTreeObjects)
                                    end
                                end)
                                task.wait(5)
                            end
                        end)
                    elseif HasBeenEnabled1 == true then
                        isAutoUpgradeEnabled = false
                        
                        if treeToggleThread then
                            task.cancel(treeToggleThread)
                            treeToggleThread = nil
                        end
                        
                        SelectTreesDropdown:SetValue(originalSelectedObjects)

                        if autoBreakRunning ~= originalAutoCutState then
                            AutoCutTreesToggle:SetValue(originalAutoCutState)
                        end
                    end
                end
            })

            getAllNonWoodRequirements = function()
                local AxesModule = require(ReplicatedStorage.Shared.List.Axes)
                local allRequirements = {}
                local requirementMap = {}
                
                for axeName, axeData in pairs(AxesModule) do
                    if axeData.required then
                        for _, item in ipairs(axeData.required) do
                            local amount = (item.getAmount and item:getAmount()) or item.Amount or 1
                            local itemName = (item.getName and item:getName()) or item.Name or "Unknown"

                            if not itemName:lower():find("wood") then
                                if axeName:lower():find("dungeon") and itemName:lower():find("pickaxe") then
                                    itemName = "dungeonPotion"
                                elseif itemName:lower() == "dungeon" then
                                    itemName = "dungeonPotions"
                                end
                                
                                if not requirementMap[itemName] or amount > requirementMap[itemName] then
                                    requirementMap[itemName] = amount
                                end
                            end
                        end
                    end
                end
                
                for itemName, maxAmount in pairs(requirementMap) do
                    table.insert(allRequirements, maxAmount .. "x " .. itemName)
                end
                
                if #allRequirements > 0 then
                    return "Note you will need to own at least:\n" .. table.concat(allRequirements, ", ")
                else
                    return "Note: Only wood is required for axe upgrades!"
                end
            end

            UpgradeAxe:Paragraph("NonWoodNote", {
                Title = "Additional Items",
                Content = getAllNonWoodRequirements(),
                TitleAlignment = "Middle",
                ContentAlignment = Enum.TextXAlignment.Left
            })

            local BuyFarmSection = Tabs.Farm:AddSection("Buy Farms")


            getAllFarms = function()
                local options, map = {}, {}
                pcall(function()
                    local FarmsList = require(ReplicatedStorage.Shared.List.Farms)
                    for farmId, farmInfo in pairs(FarmsList) do
                        -- Exclude farmer and other non-purchasable items
                        if not farmId:lower():find("1234") and 
                        not farmInfo.isNotFarm and 
                        farmInfo.price and 
                        farmId ~= "farmer" then  -- Exclude farmer from auto-buy
                            local name = farmInfo.name or farmId
                            table.insert(options, name)
                            map[name] = farmId
                        end
                    end
                    
                    -- Don't add farmer to the options at all
                end)
                table.sort(options)
                return options, map
            end

            local farmOptions, farmIdMap = getAllFarms()

            local farmDropdown = BuyFarmSection:Dropdown("SelectFarms", {
                Title = "Select Farms to Buy",
                Values = farmOptions,
                Multi = true,
                Default = {}
            })

            local BuyFarm = BuyFarmSection:Toggle("AutoBuyFarms", {
                Title = "Auto Buy Selected Farms",
                Description = "Buy farms when you can afford them",
                Default = false,
                Callback = function(s) _G.AutoBuyFarms = s end
            })

            task.spawn(function()
                while task.wait(5) do -- Check every 5 seconds
                    if not _G.AutoBuyFarms then continue end
                    pcall(function()
                        local playerData, FarmsList = DataController:getData(), require(ReplicatedStorage.Shared.List.Farms)
                        if not playerData then return end
                        
                        -- Get selected farms, or use all farms if none selected
                        local farmsToCheck = farmDropdown.Value or {}
                        if not next(farmsToCheck) then
                            -- If no farms selected, check all available farms (excluding farmer)
                            for _, farmName in ipairs(farmOptions) do
                                farmsToCheck[farmName] = true
                            end
                        end
                        
                        for farmName, selected in pairs(farmsToCheck) do
                            if selected then
                                local farmId = farmIdMap[farmName]
                                local farmInfo = FarmsList[farmId]
                                if farmId and farmInfo and 
                                (playerData.gems or 0) >= (farmInfo.price or 0) and 
                                not (playerData.farms and playerData.farms[farmId]) then
                                    FarmService:buy(farmId)
                                    task.wait(1) -- Wait 1 second after each purchase
                                end
                            end
                        end
                    end)
                end
            end)

        local AutoUpgradeFarmSection = Tabs.Farm:AddSection("Auto Upgrade Farms")

            getAllFarmsWithOptions = function()
                local options, farmMap = {}, {}
                pcall(function()
                    local FarmsList = require(ReplicatedStorage.Shared.List.Farms)
                    local tempFarms = {}
                    for id, info in pairs(FarmsList) do
                        if not id:lower():find("1234") and not info.isNotFarm and info.upgrades then
                            local name = info.name or id
                            table.insert(tempFarms, { id = id, name = name })
                        end
                    end
                    if FarmsList.farmer and FarmsList.farmer.upgrades then
                        table.insert(tempFarms, { id = "farmer", name = "farmer" })
                    end
                    table.sort(tempFarms, function(a, b) return a.name < b.name end)
                    for _, data in ipairs(tempFarms) do
                        table.insert(options, data.name)
                        farmMap[data.name] = data.id
                    end
                end)
                return options, farmMap
            end

            local allFarmOptions, allFarmIdMap = getAllFarmsWithOptions()

            local upgradeDropdown = AutoUpgradeFarmSection:Dropdown("SelectFarmsToUpgrade", {
                Title = "Select Farms to Upgrade",
                Values = allFarmOptions,
                Multi = true,
                Searchable = true,
                Default = {}
            })

            AutoUpgradeFarmSection:Toggle("AutoUpgradeFarms", {
                Title = "Auto Upgrade Selected Farms",
                Description = "Auto buys upgrades for the selected farms (must own).",
                Default = false,
                Callback = function(s) _G.AutoUpgradeFarms = s end
            })

            -- NEW: "Buy Burst" loop logic
            task.spawn(function()
                while true do -- This is the main loop with the 5-second wait at the end.
                    if _G.AutoUpgradeFarms and next(upgradeDropdown.Value or {}) then
                        pcall(function()
                            -- This inner loop is the "buy burst". It will run rapidly until no more upgrades can be afforded.
                            while true do 
                                local selected = upgradeDropdown.Value
                                local FarmsList = require(ReplicatedStorage.Shared.List.Farms)
                                local playerData = DataController:getData()
                                if not playerData then break end -- Exit burst if data is lost

                                local affordableUpgrades = {}

                                -- Step 1: Find ALL currently affordable upgrades
                                for farmName, isSelected in pairs(selected) do
                                    if isSelected then
                                        local farmId = allFarmIdMap[farmName]
                                        local farmConfig = FarmsList[farmId]
                                        if farmId and farmConfig and farmConfig.upgrades and (playerData.farms and playerData.farms[farmId]) then
                                            local currentLevel = playerData.farms[farmId].stage or 0
                                            local nextLevel = currentLevel + 1
                                            local nextUpgradeInfo = farmConfig.upgrades[nextLevel]
                                            if nextUpgradeInfo then
                                                local upgradeCost = nextUpgradeInfo.price or 0
                                                if (playerData.gems or 0) >= upgradeCost then
                                                    table.insert(affordableUpgrades, {id = farmId, cost = upgradeCost})
                                                end
                                            end
                                        end
                                    end
                                end

                                -- Step 2: If there's nothing to buy, exit the burst loop.
                                if #affordableUpgrades == 0 then
                                    break 
                                end

                                -- Step 3: Sort to find the CHEAPEST affordable upgrade
                                table.sort(affordableUpgrades, function(a, b)
                                    return a.cost < b.cost
                                end)
                                
                                local cheapestUpgrade = affordableUpgrades[1]

                                FarmService:upgrade(cheapestUpgrade.id)
                                task.wait(0.3) 
                            end
                        end)
                    end 
                    task.wait(5) 
                end
            end)

            local AutoClaimSection = Tabs.Farm:AddSection("Auto Claim")

            getAllFarmsForClaim = function()
                local options, farmMap = {}, {}
                pcall(function()
                    local FarmsList = require(ReplicatedStorage.Shared.List.Farms)
                    for farmId, farmInfo in pairs(FarmsList) do
                        if not farmId:lower():find("farmer") and not farmInfo.isNotFarm then
                            local name = farmInfo.name or farmId
                            table.insert(options, name)
                            farmMap[name] = farmId
                        end
                    end
                end)
                table.sort(options)
                return options, farmMap
            end

            local claimFarmOptions, claimFarmIdMap = getAllFarmsForClaim()

            local claimDropdown = AutoClaimSection:Dropdown("SelectFarmsToClaim", {Title = "Select Farms to Auto-Claim", Values = claimFarmOptions, Multi = true, Default = {}})
            local AutoClaimFarm = AutoClaimSection:Toggle("AutoClaimFarms", {Title = "Auto Claim Farms" , Description = "Automatically claims fruits from selected farms.", Default = false, Callback = function(s) _G.AutoClaimFarms = s end})

            -- This function is no longer needed but kept to avoid breaking other references if any.
            isFarmReady = function() return false end

            -- CORRECTED: The main loop is now properly structured.
            task.spawn(function()
                while true do
                    -- Only run if the toggle is on and at least one farm is selected.
                    if _G.AutoClaimFarms and next(claimDropdown.Value or {}) then
                        pcall(function()
                            
                            local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
                            local FarmService = Knit.GetService("FarmService")
                            
                            -- Loop through every farm the user has selected in the UI.
                            for farmName, selected in pairs(claimDropdown.Value) do
                                if selected then
                                    local farmId = claimFarmIdMap[farmName]
                                    
                                    if farmId then
                                        FarmService:claim(farmId)
                                        task.wait(0.2) -- Small wait between each remote fire
                                    end
                                end
                            end
                        end)
                    end

                    task.wait(10) 
                end
            end)
            
            local CraftPetSection = Tabs.Pet:AddSection("Craft Pets")
            petDisplayToId = {}
            local PetStatusParagraph = CraftPetSection:AddParagraph("PetCraftStatus", { Title = "Selected Pets", Content = "No pets selected." })
                
            getPlayerPetOptions = function()
                petDisplayToId = {}
                local petOptions, addedNames = {}, {}

                pcall(function()
                    local Tiers = require(ReplicatedStorage.Shared.List.Pets.Tiers)
                    local playerData = DataController:getData()
                    if not (playerData and playerData.inventory and playerData.inventory.pet) then return end

                    for petId, petRawData in pairs(playerData.inventory.pet) do
                        local petObject = Util.itemUtils.createItemFromData(petRawData)
                        if petObject then
                            local s, name = pcall(function() return petObject:getName() end)
                            if s then
                                local tierNum
                                local isShiny = (petRawData.sh == true)
                                pcall(function() tierNum = petObject:getTier() end)

                                local tierData = tierNum and Tiers[tierNum]
                                local tierName = tierData and tierData.name or ""

                                -- ✅ Skip Galaxy pets entirely
                                if tierName ~= "Galaxy" then
                                    if tierName == "Normal" then tierName = "" end

                                    local nameParts = {}
                                    if tierName ~= "" then table.insert(nameParts, tierName) end
                                    if isShiny then table.insert(nameParts, "Shiny") end
                                    table.insert(nameParts, name)

                                    local displayName = table.concat(nameParts, " ")
                                    if not addedNames[displayName] then
                                        table.insert(petOptions, displayName)
                                        petDisplayToId[displayName] = petId
                                        addedNames[displayName] = true
                                    end
                                end
                            end
                        end
                    end
                end)

                if #petOptions == 0 then
                    return { "No pets found" }
                end

                table.sort(petOptions)
                return petOptions
            end

            updatePetStatusParagraph = function(selectedPets)
                local contentLines = {}
                if selectedPets and next(selectedPets) then
                    for displayName, isSelected in pairs(selectedPets) do
                        if isSelected then
                            table.insert(contentLines, displayName)
                        end
                    end
                end

                if #contentLines == 0 then
                    PetStatusParagraph:SetContent("No pets selected.")
                else
                    PetStatusParagraph:SetContent(table.concat(contentLines, ", "))
                end
            end

            PetDropdown = CraftPetSection:AddDropdown("SelectPetToCraft", {
                Title = "Select Pet(s) to Craft", Values = getPlayerPetOptions(), Multi = true, Searchable = true, Default = {},
                Callback = function(value) updatePetStatusParagraph(value) end
            })

            CraftPetSection:AddButton({
            Title = "Select All Pets",
            Callback = function()
                local allPets = {}
                for _, petName in ipairs(PetDropdown.Values) do
                    allPets[petName] = true
                end
                PetDropdown:SetValue(allPets)
                updatePetStatusParagraph(allPets)
            end})

            CraftPetSection:AddButton({ Title = "Refresh Pet List", Callback = function() PetDropdown:SetValues(getPlayerPetOptions()); PetDropdown:SetValue({}); updatePetStatusParagraph({}) end })
            CraftPetSection:AddParagraph("CraftingNote", { Title = "Note", Content = "Crafting requires at least 5 of the same pet to create 1 of the next tier. You might need to rejoin after trying to craft a galaxy pet, and be aware that the pet needs to be released after the space update in order to craft to galaxy." })
            local CraftAmountInput = CraftPetSection:AddInput("CraftAmountInput", { Title = "Craft Amount", Default = "1", Numeric = true })

            CraftPetSection:AddButton({ Title = "Craft Specific Amount",
                Callback = function()
                    local selectedPets, amount = PetDropdown.Value, tonumber(CraftAmountInput.Value) or 1
                    if not next(selectedPets) then return end
                    for displayName, isSelected in pairs(selectedPets) do
                        if isSelected then
                            local petId = petDisplayToId[displayName]
                            if petId then pcall(function() PetService:craft({[1]=petId}, false, amount) end); task.wait(0.2) end
                        end
                    end
                    task.wait(1); PetDropdown:SetValues(getPlayerPetOptions()); updatePetStatusParagraph(PetDropdown.Value)
                end
            })

            local CraftAllToggle = CraftPetSection:AddToggle("CraftAllToggle", { Title = "Craft All (Selected)", Default = false })

            local craftAllThread = nil

            CraftAllToggle:OnChanged(function()
                -- Cancel any existing thread if it's running.
                if craftAllThread then
                    task.cancel(craftAllThread)
                    craftAllThread = nil
                end

                if CraftAllToggle.Value then
                    craftAllThread = task.spawn(function()
                        while CraftAllToggle.Value do
                            local petsToCraft = {}
                            local selectedPets = PetDropdown.Value
                            local playerData = DataController:getData()
                            
                            if selectedPets and next(selectedPets) and playerData and playerData.inventory.pet then
                                for displayName, isSelected in pairs(selectedPets) do
                                    if isSelected then
                                        local petId = petDisplayToId[displayName]
                                        if petId and playerData.inventory.pet[petId] and (playerData.inventory.pet[petId].am or 0) >= 5 then
                                            table.insert(petsToCraft, { id = petId, name = displayName })
                                        end
                                    end
                                end
                            end

                            if #petsToCraft > 0 then                        
                                for _, petInfo in ipairs(petsToCraft) do
                                    if not CraftAllToggle.Value then 
                                        break 
                                    end
                                    
                                    pcall(function() 
                                        PetService:craft({[1] = petInfo.id}, true, 1) 
                                    end)
                                    task.wait(0.2)
                                end
                                task.wait(1)
                                PetDropdown:SetValues(getPlayerPetOptions()) 
                            end

                            task.wait(3) 
                        end
                        craftAllThread = nil 
                    end)
                end
            end)

            task.spawn(function() while task.wait(3) do if PetDropdown and PetDropdown.Value and next(PetDropdown.Value) then pcall(updatePetStatusParagraph, PetDropdown.Value) end end end)





            local machines = Tabs.MineFish:AddSection("Machine Script")
            
            machines:Button({
                Title = "Load Script",
                Description = "Sorry for the separate loadstring! Having such a large script was causing me to run out of local uses and creating lag issues.",
                Callback = function()
                    safeLoadUrl("https://raw.githubusercontent.com/BigBeanLUA/RCU/refs/heads/main/Machine")()
                end
            })


            machines:Toggle("AutoLoadMachine", {
            Title = "Auto Load Machine Script",
            Description = "Automatically loads the machine script when you load this script. Use this if you have auto load config on.",
            Default = false,
            Callback = function(enabled)
                AutoLoadSeasonQuest1 = enabled
                if enabled then
                    safeLoadUrl("https://raw.githubusercontent.com/BigBeanLUA/RCU/refs/heads/main/Machine")()
                end
            end})

            -- ============================================================

            -- ============================================================
            -- DUNGEON TAB (Inline)
            -- ============================================================
            do
            local DungeonController = Knit.GetController("DungeonController")

            -- Apply dungeon crash fixes
            pcall(function()
                if DungeonController and not DungeonController._fixedPowerups then
                    local oldGetPowerupPos = DungeonController.getPowerupPosition
                    DungeonController.getPowerupPosition = function(self)
                        local spawns = CollectionService:GetTagged("DungeonPowerupSpawn")
                        if #spawns == 0 then return CFrame.new(0, -1000, 0) end
                        return oldGetPowerupPos(self)
                    end
                    DungeonController._fixedPowerups = true
                end
                if DungeonController and not DungeonController._fixedBossSpawn then
                    local oldSpawnBoss = DungeonController.spawnBoss
                    DungeonController.spawnBoss = function(self)
                        local room = self:getDungeonRoom()
                        if room and room:FindFirstChild("BossSpawn") then return oldSpawnBoss(self) end
                    end
                    DungeonController._fixedBossSpawn = true
                end
            end)

            local function isInDungeon()
                local s, r = pcall(function() return DungeonController:isInDungeon() end)
                return s and r or false
            end

            local AutoCritSection = Tabs.Dungeon:AddSection("Auto Crit/Damage")
            local autoCritEnabled = false
            local inDungeon = false

            task.spawn(function() while true do if autoCritEnabled then inDungeon = isInDungeon() end; task.wait(5) end end)

            AutoCritSection:Toggle("AutoCriticalTap", {
                Title = "Auto Critical Tap",
                Description = "Fires damage and critical tap remotes while in a dungeon. Runs every 0.15 seconds.",
                Default = false,
                Callback = function(v)
                    autoCritEnabled = v
                    if v then
                        inDungeon = isInDungeon()
                        task.spawn(function()
                            while autoCritEnabled do
                                if inDungeon then
                                    if #CollectionService:GetTagged("dungeonBoss") > 0 then
                                        pcall(function()
                                            DungeonService.damage._re:FireServer()
                                            DungeonService.criticalTap._re:FireServer()
                                        end)
                                    end
                                end
                                task.wait(0.15)
                            end
                        end)
                    end
                end
            })

            local PowerupSection = Tabs.Dungeon:AddSection("Auto Powerups")
            local autoPickupEnabled = false

            PowerupSection:Toggle("AutoPickupPowerups", {
                Title = "Auto Pickup Powerups",
                Description = "Picks up dungeon powerups automatically by firing touch interest on them.",
                Default = false,
                Callback = function(v)
                    autoPickupEnabled = v
                    if v then
                        task.spawn(function()
                            local Powerups = require(ReplicatedStorage.Shared.List.Dungeon.Powerups)
                            local moduleKeys = {}
                            for key in pairs(Powerups) do moduleKeys[key:lower()] = key end
                            while autoPickupEnabled do
                                if isInDungeon() then
                                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    local debris = Workspace:FindFirstChild("Debris")
                                    if hrp and debris then
                                        for _, child in ipairs(debris:GetChildren()) do
                                            if moduleKeys[child.Name:gsub("%s",""):lower()] then
                                                for _, part in ipairs(child:GetChildren()) do
                                                    if part:FindFirstChild("TouchInterest") then
                                                        pcall(firetouchinterest, hrp, part, 0)
                                                        pcall(firetouchinterest, hrp, part, 1)
                                                        task.wait(0.25)
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                task.wait(3)
                            end
                        end)
                    end
                end
            })

            local DungeonEquipSection = Tabs.Dungeon:AddSection("Equip Best Dungeon Pets")

            DungeonEquipSection:Toggle("EquipBestDungeonPets", {
                Title = "Equip Best Dungeon Pets",
                Description = "Finds your strongest dungeon-damage pets and equips them, removing weaker ones. Checks every 5 seconds.",
                Default = false,
                Callback = function(v)
                    _G.EquipBestDungeonPets = v
                    if v then
                        task.spawn(function()
                            while _G.EquipBestDungeonPets do
                                pcall(function()
                                    local itemUtils = Util.itemUtils
                                    local data = DataController:getData()
                                    if not data then return end
                                    local label = LocalPlayer.PlayerGui.MainUI.Menus.DungeonJoinFrame.Main.Default.YourTeamLabel
                                    local maxEq = tonumber(string.match(label.Text, "/(%d+)")) or 10
                                    local dungeonPets = {}
                                    if data.inventory.pet then
                                        for petId in pairs(data.inventory.pet) do
                                            local pet = itemUtils.getItemFromId(data, petId)
                                            if pet and pet:getSpecialMultiplierName() == "dungeonDamage" then
                                                table.insert(dungeonPets, {id=petId, multiplier=pet:getSpecialMultiplierAmount(), amount=pet:getAmount()})
                                            end
                                        end
                                    end
                                    table.sort(dungeonPets, function(a,b) return a.multiplier > b.multiplier end)
                                    local bestPets = {}
                                    local total = 0
                                    for _, pd in ipairs(dungeonPets) do
                                        if total < maxEq then
                                            local eq = math.min(pd.amount, maxEq - total)
                                            if eq > 0 then bestPets[pd.id] = eq; total = total + eq end
                                        end
                                    end
                                    if data.dungeonTeam then
                                        for eqId, eqAm in pairs(data.dungeonTeam) do
                                            local correct = bestPets[eqId] or 0
                                            if eqAm > correct then
                                                for i = 1, eqAm - correct do DungeonService:removePetFromTeam(eqId); task.wait(0.1) end
                                            end
                                        end
                                    end
                                    for petId, target in pairs(bestPets) do
                                        local cur = (data.dungeonTeam and data.dungeonTeam[petId]) or 0
                                        for i = 1, target - cur do DungeonService:addPetToTeam(petId); task.wait(0.1) end
                                    end
                                end)
                                task.wait(5)
                            end
                        end)
                    end
                end
            })

            local DungeonJoinSection = Tabs.Dungeon:AddSection("Auto Join")

            local ticketStatus = DungeonJoinSection:AddParagraph("DungeonTickets", {Title="Dungeon Tickets", Content="Checking..."})
            task.spawn(function()
                while true do
                    pcall(function()
                        local data = DataController:getData()
                        local t = Util.itemUtils.getItemFromName(data, "dungeonTicket")
                        ticketStatus:SetValue(t and t:getAmount() > 0 and ("Tickets: "..t:getAmount()) or "No Tickets")
                    end)
                    task.wait(5)
                end
            end)

            local DungeonGamemodes = require(ReplicatedStorage.Shared.List.Dungeon.DungeonGamemodes)
            local gmOptions = {}
            for i, gm in ipairs(DungeonGamemodes) do
                table.insert(gmOptions, string.format("%d. %s (%d tickets)", i, gm.name, gm.price))
            end
            local selectedGM = 1

            DungeonJoinSection:Dropdown("GamemodeSelect", {
                Title = "Select Dungeon Mode", Values = gmOptions, Multi = false, Default = gmOptions[1],
                Callback = function(v) selectedGM = tonumber(string.match(v, "^(%d+)")) or 1 end
            })

            DungeonJoinSection:Toggle("AutoJoinDungeon", {
                Title = "Auto Join Dungeon",
                Description = "Joins the selected dungeon mode automatically when not in a dungeon. Retries every 3 seconds.",
                Default = false,
                Callback = function(v)
                    _G.AutoJoinDungeon = v
                    if v then
                        task.spawn(function()
                            while _G.AutoJoinDungeon do
                                if not isInDungeon() then pcall(function() DungeonService:startDungeon(selectedGM) end) end
                                task.wait(3)
                            end
                        end)
                    end
                end
            })

            local DungeonMiscSection = Tabs.Dungeon:AddSection("Dungeon Misc")

            DungeonMiscSection:Toggle("KeepHUDVisible", {
                Title = "Keep HUD Visible",
                Description = "Prevents the dungeon from hiding your HUD. Enable before entering.",
                Default = false,
                Callback = function(v)
                    local UICtrl = Knit.GetController("UIController")
                    if v then
                        _G._origHideHUD = _G._origHideHUD or UICtrl.hideHUD
                        UICtrl.hideHUD = function(self, hide, ex) _G._origHideHUD(self, false, {["bottom"]=true}) end
                    elseif _G._origHideHUD then UICtrl.hideHUD = _G._origHideHUD end
                end
            })

            DungeonMiscSection:Toggle("StopScreenShakes", {
                Title = "Stop Screen Shakes",
                Description = "Disables dungeon screen shake and critical tap visual effects.",
                Default = false,
                Callback = function(v)
                    if v then
                        _G._origShake = _G._origShake or DungeonController.shakeScreen
                        _G._origCritTap = _G._origCritTap or DungeonController.criticalTap
                        DungeonController.shakeScreen = function() end
                        DungeonController.criticalTap = function() end
                    else
                        if _G._origShake then DungeonController.shakeScreen = _G._origShake end
                        if _G._origCritTap then DungeonController.criticalTap = _G._origCritTap end
                    end
                end
            })

            DungeonMiscSection:Toggle("PreventTeleport", {
                Title = "Prevent End Teleport",
                Description = "Stops the teleport when a dungeon ends. Only use with Auto Join or you will be stuck.",
                Default = false,
                Callback = function(v)
                    if v then
                        _G._origTpRoom = _G._origTpRoom or DungeonController.teleportFromRoom
                        DungeonController.teleportFromRoom = function() end
                    elseif _G._origTpRoom then DungeonController.teleportFromRoom = _G._origTpRoom end
                end
            })

            DungeonMiscSection:Toggle("NoDungeonPets", {
                Title = "Hide Dungeon Pets (FPS Boost)",
                Description = "Prevents pets from visually spawning in dungeons. Enable before entering.",
                Default = false,
                Callback = function(v)
                    if v then
                        _G._origCreatePets = _G._origCreatePets or DungeonController.createPets
                        DungeonController.createPets = function() return nil end
                    elseif _G._origCreatePets then DungeonController.createPets = _G._origCreatePets; _G._origCreatePets = nil end
                end
            })

            -- Dungeon Shop
            local DungeonShopSection = Tabs.Dungeon:AddSection("Dungeon Shop")
            local DungeonShop = require(ReplicatedStorage.Shared.List.Dungeon.Shop)
            local dShopOptions, dShopMap = {}, {}
            for i, si in ipairs(DungeonShop) do
                local n, a = "Unknown", 1
                pcall(function() n = si.item:getName(); a = si.item:getAmount() end)
                local dn = (a > 1 and (a.."x "..n) or n) .. " - " .. Functions.suffixes(si.price) .. " coins"
                table.insert(dShopOptions, dn)
                dShopMap[dn] = {item=si.item, price=si.price, index=i, amount=a, itemName=n}
            end
            local selectedDShopItems = {}
            local dShopDropdown = DungeonShopSection:Dropdown("DungeonShopItems", {
                Title = "Items to Auto Buy", Values = dShopOptions, Multi = true, Searchable = true, Default = {},
                Callback = function(v) selectedDShopItems = v end
            })
            DungeonShopSection:Button({Title = "Select All", Callback = function()
                local all = {}; for _, o in ipairs(dShopOptions) do all[o] = true end
                dShopDropdown:SetValue(all); selectedDShopItems = all
            end})
            DungeonShopSection:Toggle("AutoBuyDungeonShop", {
                Title = "Auto Buy Selected", Description = "Buys selected dungeon shop items when they appear and you can afford them.",
                Default = false,
                Callback = function(v)
                    _G.AutoBuyDShop = v
                    if v then
                        task.spawn(function()
                            while _G.AutoBuyDShop do
                                if next(selectedDShopItems) then
                                    pcall(function()
                                        local pd = DataController:getData()
                                        if not pd then return end
                                        local coins = pd.dungeonCoins or 0
                                        local td = DateTime.fromUnixTimestamp(Knit.serverTimeNow + 3600):ToUniversalTime()
                                        for slot = 1, 3 do
                                            local seed = td.Year*222 + td.Month*333 + td.Day*444444 + td.Hour*33333 + LocalPlayer.UserId + slot
                                            local si = DungeonShop[Functions.getRandom(DungeonShop, seed)]
                                            if si then
                                                local n, a = "Unknown", 1
                                                pcall(function() n = si.item:getName(); a = si.item:getAmount() end)
                                                local bk = string.format("%d", seed)
                                                if not (pd.dungeonShopBought[bk]) and coins >= si.price then
                                                    for dn, sel in pairs(selectedDShopItems) do
                                                        if sel and dShopMap[dn] and n == dShopMap[dn].itemName and a == dShopMap[dn].amount and si.price == dShopMap[dn].price then
                                                            DungeonService:buyShop(slot); task.wait(1); break
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end)
                                end
                                task.wait(5)
                            end
                        end)
                    end
                end
            })

            -- Dungeon Upgrades
            local DungeonUpgSection = Tabs.Dungeon:AddSection("Dungeon Upgrades")
            local DungeonUpgradesModule = require(ReplicatedStorage.Shared.List.Dungeon.Upgrades)
            local dUpgOptions, dUpgMap = {}, {}
            for uid in pairs(DungeonUpgradesModule) do
                local dn = Functions.toPascal(uid)
                table.insert(dUpgOptions, dn); dUpgMap[dn] = uid
            end
            table.sort(dUpgOptions)
            local selectedDUpg = {}
            DungeonUpgSection:Dropdown("DungeonUpgrades", {
                Title = "Upgrades to Auto Buy", Values = dUpgOptions, Multi = true, Searchable = true, Default = {},
                Callback = function(v) selectedDUpg = v end
            })
            DungeonUpgSection:Toggle("AutoDungeonUpgrade", {
                Title = "Auto Upgrade", Description = "Buys selected dungeon upgrades when affordable.",
                Default = false,
                Callback = function(v)
                    _G.AutoDUpgrade = v
                    if v then
                        task.spawn(function()
                            while _G.AutoDUpgrade do
                                if next(selectedDUpg) then
                                    pcall(function()
                                        local pd = DataController:getData()
                                        if not pd then return end
                                        local coins = pd.dungeonCoins or 0
                                        for dn, sel in pairs(selectedDUpg) do
                                            if sel and dUpgMap[dn] then
                                                local uid = dUpgMap[dn]
                                                local ud = DungeonUpgradesModule[uid]
                                                if ud then
                                                    local cur = pd.dungeonUpgrades[uid] or 0
                                                    local nxt = ud.upgrades[cur + 1]
                                                    if nxt and coins >= (nxt.cost or 0) then
                                                        DungeonService:upgrade(uid:sub(1,1):lower()..uid:sub(2))
                                                        task.wait(0.25)
                                                        pd = DataController:getData()
                                                        if pd then coins = pd.dungeonCoins or 0 end
                                                    end
                                                end
                                            end
                                        end
                                    end)
                                end
                                task.wait(3)
                            end
                        end)
                    end
                end
            })
            end -- End Dungeon scope

            local AutoCraftSection = Tabs.Craft:AddSection("Auto Craft")

            AutoCraftSection:Paragraph("AutoCraftSectionParagraph", {
                Title = "Note",
                Content = "You will not visually get a message that you have crafted something, but it will have been built. This will also use items that might be rare, so be careful with what you select. If something still appears as unbuilt, rejoin.",
                TitleAlignment = "Middle",
                ContentAlignment = Enum.TextXAlignment.Left
            })

            ResourceStatusParagraph = AutoCraftSection:Paragraph("ResourceStatus", {
                Title = "Resource Status",
                Content = "Select buildings to see resource requirements",
                TitleAlignment = "Middle",
                ContentAlignment = Enum.TextXAlignment.Left
            })

            local isAutoCraftEnabled = false
            local originalAutoCraftSettings = {}
            local autoCraftBuildingMap -- This one can stay local as it's not used elsewhere

            local function getUnbuiltBuildings()
                local options, buildingMap = {}, {}
                pcall(function()
                    local Buildings = require(ReplicatedStorage.Shared.List.Buildings)
                    local playerData = DataController:getData()
                    if not playerData then return end

                    for buildingId, buildingData in pairs(Buildings) do
                        local isBuilt = playerData.buildings and playerData.buildings[buildingId] or false
                        if not isBuilt and buildingData.name and buildingData.required then
                            local displayName = buildingData.name
                            table.insert(options, displayName)
                            buildingMap[displayName] = buildingId
                        end
                    end
                end)
                table.sort(options)
                return options, buildingMap
            end

            local function canAffordBuilding(buildingId)
                local Buildings = require(ReplicatedStorage.Shared.List.Buildings)
                local buildingData = Buildings[buildingId]
                if not buildingData or not buildingData.required then return false end
                
                local playerData = DataController:getData()
                if not playerData then return false end
                
                for _, requiredItem in ipairs(buildingData.required) do
                    local itemName = requiredItem:getName()
                    local requiredAmount = requiredItem:getAmount()
                    
                    local currentItem = Util.itemUtils.getItemFromName(playerData, itemName)
                    local currentAmount = currentItem and currentItem:getAmount() or 0
                    
                    if currentAmount < requiredAmount then
                        return false
                    end
                end
                return true
            end

            local function getPrerequisiteChain(buildingId, visited)
                visited = visited or {}
                if visited[buildingId] then return {} end
                visited[buildingId] = true
                
                local Buildings = require(ReplicatedStorage.Shared.List.Buildings)
                local buildingData = Buildings[buildingId]
                if not buildingData then return {} end
                
                local chain = {}
                if buildingData.previousBuilding then
                    local prereqChain = getPrerequisiteChain(buildingData.previousBuilding, visited)
                    for _, prereq in ipairs(prereqChain) do
                        table.insert(chain, prereq)
                    end
                    table.insert(chain, buildingData.previousBuilding)
                end
                
                return chain
            end

            local function getMissingResources()
                local Buildings = require(ReplicatedStorage.Shared.List.Buildings)
                local playerData = DataController:getData()
                if not playerData then return {} end
                
                local missingResources = {}
                
                if autoCraftDropdown and autoCraftDropdown.Value then
                    for buildingName, isSelected in pairs(autoCraftDropdown.Value) do
                        if isSelected then
                            local buildingId = autoCraftBuildingMap[buildingName]
                            local buildingData = Buildings[buildingId]
                            
                            if buildingData and buildingData.required then
                                for _, requiredItem in ipairs(buildingData.required) do
                                    local itemName = requiredItem:getName()
                                    local requiredAmount = requiredItem:getAmount()
                                    
                                    local currentItem = Util.itemUtils.getItemFromName(playerData, itemName)
                                    local currentAmount = currentItem and currentItem:getAmount() or 0
                                    
                                    if currentAmount < requiredAmount then
                                        local needed = requiredAmount - currentAmount
                                        missingResources[itemName] = (missingResources[itemName] or 0) + needed
                                    end
                                end
                            end
                        end
                    end
                end
                
                return missingResources
            end

            local function updateResourceStatus()
                local missingResources = getMissingResources()
                
                if not next(missingResources) then
                    if ResourceStatusParagraph then
                        ResourceStatusParagraph:SetValue("✅ All selected buildings can be crafted!")
                    end
                    return
                end
                
                local statusLines = {"📋 Missing Resources:"}
                for itemName, amount in pairs(missingResources) do
                    table.insert(statusLines, string.format("  • %s: %s", itemName, Functions.comma(amount)))
                end
                
                if ResourceStatusParagraph then
                    ResourceStatusParagraph:SetValue(table.concat(statusLines, "\n"))
                end
            end

            local function mapWoodToTreeWorldForCraft(woodName)
                if woodName:lower() == "wood" then return "spawn" end
                
                local Trees = require(ReplicatedStorage.Shared.List.Trees)
                for zoneName, zoneData in pairs(Trees) do
                    if zoneData.trees and #zoneData.trees > 0 then
                        local treeInfo = zoneData.trees[1]
                        if treeInfo and treeInfo.item then
                            local item = treeInfo.item
                            local itemName = item.id or item.Name or item.name or (item.getId and item:getId()) or (item.getName and item:getName())
                            if itemName and itemName:lower() == woodName:lower() then return zoneName end
                        end
                    end
                end
                return "spawn"
            end

            local autoCraftOptions, initialBuildingMap = getUnbuiltBuildings()
            autoCraftBuildingMap = initialBuildingMap

            AutoCraftSection:Button({
                Title = "Enable Recommended Settings",
                Description = "Automatically enables: Auto Equip Best Axe, Reduce Cutting Cooldown, and Axe Strength Bypass",
                Callback = function()
                    AutoEquip:SetValue(true)
                    lowercooldown:SetValue(true) 
                    BypassStrength:SetValue(true)
                end
            })

            autoCraftDropdown = AutoCraftSection:Dropdown("SelectBuildingsToCraft", {
                Title = "Select Buildings to Auto Craft",
                Description = "Crafts all selected buildings that you can afford and farms trees for needed wood.",
                Values = autoCraftOptions,
                Multi = true,
                Searchable = true,
                Default = {}
            })

            autoCraftDropdown:OnChanged(function(value)
                updateResourceStatus()
            end)

        AutoCraftBuildings = AutoCraftSection:Toggle("AutoCraft", {
                Title = "Auto Craft Selected Buildings",
                Description = "Automatically crafts selected buildings and farms trees for wood resources.",
                Default = false,
                Callback = function(enabled)
                    isAutoCraftEnabled = enabled
                    if enabled then
                        HasBeenEnabled = true
                        originalAutoCraftSettings.selectedTrees = {}
                        for treeObject, isSelected in pairs(SelectTreesDropdown.Value) do
                            originalAutoCraftSettings.selectedTrees[treeObject] = isSelected
                        end
                        originalAutoCraftSettings.autoCutState = autoBreakRunning
                        task.spawn(function()
                            while isAutoCraftEnabled do
                                pcall(function()
                                    local playerData = DataController:getData()
                                    if not playerData then return end
                                    local Buildings = require(ReplicatedStorage.Shared.List.Buildings)
                                    local selectedBuildings = autoCraftDropdown.Value or {}
                                    local neededWoods = {}
                                    local canCraftSomething = false
                                    for buildingName, isSelected in pairs(selectedBuildings) do
                                        if isSelected then
                                            local buildingId = autoCraftBuildingMap[buildingName]
                                            local buildingData = Buildings[buildingId]
                                            if buildingData then
                                                for _, prereqId in ipairs(getPrerequisiteChain(buildingId)) do
                                                    if not (playerData.buildings and playerData.buildings[prereqId]) and canAffordBuilding(prereqId) then
                                                        BuildingService:build(prereqId)
                                                        task.wait(1)
                                                        canCraftSomething = true
                                                    end
                                                end
                                                if not (playerData.buildings and playerData.buildings[buildingId]) then
                                                    if canAffordBuilding(buildingId) then
                                                        BuildingService:build(buildingId)
                                                        task.wait(2)
                                                        canCraftSomething = true
                                                    elseif buildingData.required then
                                                        for _, requiredItem in ipairs(buildingData.required) do
                                                            local itemName = requiredItem:getName()
                                                            local currentItem = Util.itemUtils.getItemFromName(playerData, itemName)
                                                            if (currentItem and currentItem:getAmount() or 0) < requiredItem:getAmount() and itemName:lower():find("wood") then
                                                                table.insert(neededWoods, itemName)
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    if #neededWoods > 0 and HasBeenEnabled == true then
                                        local neededTreeObjects = {}
                                        for _, woodName in ipairs(neededWoods) do
                                            local treeWorld = mapWoodToTreeWorldForCraft(woodName)
                                            for _, treeObject in ipairs(SelectTreesDropdown.Values) do
                                                if treeObject.Value == treeWorld then neededTreeObjects[treeObject] = true; break end
                                            end
                                        end
                                        SelectTreesDropdown:SetValue(neededTreeObjects)
                                        if not autoBreakRunning then AutoCutTreesToggle:SetValue(true) end
                                    elseif HasBeenEnabled == true and canCraftSomething and autoBreakRunning then
                                        AutoCutTreesToggle:SetValue(false)
                                    end
                                end)
                                task.wait(3)
                            end
                        end)
                    elseif HasBeenEnabled == true and next(originalAutoCraftSettings) then
                        SelectTreesDropdown:SetValue(originalAutoCraftSettings.selectedTrees)
                        if autoBreakRunning ~= originalAutoCraftSettings.autoCutState then
                            AutoCutTreesToggle:SetValue(originalAutoCraftSettings.autoCutState)
                        end
                    end
                end
            })

            AutoCraftSection:Button({
                Title = "Refresh Building List",
                Description = "Updates the list of available buildings to craft",
                Callback = function()
                    local newOptions, newBuildingMap = getUnbuiltBuildings()
                    autoCraftOptions = newOptions
                    autoCraftBuildingMap = newBuildingMap
                    autoCraftDropdown:SetValues(newOptions)
                    autoCraftDropdown:SetValue({})
                    updateResourceStatus()
                end
            })

            task.spawn(function()
                while true do
                    local newOptions, newBuildingMap = getUnbuiltBuildings()
                    autoCraftOptions = newOptions
                    autoCraftBuildingMap = newBuildingMap

                    pcall(function()
                        autoCraftDropdown:SetValues(newOptions)
                    end)
                    updateResourceStatus()
                    task.wait(5)
                end
            end)


            explorerroom = Tabs.Craft:AddSection("Scattered Items")

            explorerroom:Paragraph("WorldMap", {
                Title = "World Map",
                Content = "To get the world map, you will need to follow these steps. Teleport to Desert (don't move), then teleport to Tech City (don't move), then teleport to Volcano (don't move). Next, teleport to spawn, and manually go through every world without teleporting, up to spaceship. Finally teleport to Heaven, and you will unlock it.",
                TitleAlignment = "Middle",
                ContentAlignment = Enum.TextXAlignment.Left
            })

            explorerroom:Button({
                Title = "Claim Hints",
                Description = "Automatically claims all available explorer hints",
                Callback = function()
                    pcall(function()
                        local Knit = require(ReplicatedStorage.Packages.Knit)
                        local ExplorerService = Knit.GetService("ExplorerService")
                        local UIController = Knit.GetController("UIController")
                        
                        DataController:waitForData()
                        local playerData = DataController:getData()

                        local hintsCollected = 0
                        
                        -- Try to collect hint 1
                        if not playerData.explorerHints.hint1 then
                            local result = ExplorerService:collectHint(1)
                            if result == "success" then
                                hintsCollected = hintsCollected + 1
                                task.wait(1)
                            end
                        end
                        
                        -- Try to collect hint 2 (requires hint 1 to be collected first)
                        playerData = DataController:getData() -- Refresh data
                        if playerData.explorerHints.hint1 and not playerData.explorerHints.hint2 then
                            local result = ExplorerService:collectHint(2)
                            if result == "success" then
                                hintsCollected = hintsCollected + 1
                            end
                        end
                        
                        if hintsCollected > 0 then
                        else
                        end
                    end)
                end
            })

            explorerroom:Button({
                Title = "Get all Scattered Explorer Items",
                Description = "Like the title says, you will get the scattered items - e.g globe",
                Callback = function()
                    pcall(function()
                        local explorerRoom = workspace.Game.Maps.Spaceship:FindFirstChild("extra explorer room")
                        if not explorerRoom then
                            warn("Extra explorer room not found!")
                            return
                        end
                        
                        local activatedCount = 0
                        local totalItems = 0
                        
                        for _, item in pairs(explorerRoom:GetChildren()) do
                            totalItems = totalItems + 1
                            local proximityPrompt = item:FindFirstChildOfClass("ProximityPrompt")
                            
                            if proximityPrompt then
                                pcall(function()
                                    fireproximityprompt(proximityPrompt)
                                    activatedCount = activatedCount + 1
                                end)
                                task.wait(1) 
                            end
                        end
                    end)
                end
            })


            ActivateLeversSection = Tabs.Craft:AddSection("Activate Levers")

            ActivateLeversSection:Toggle("AutoActivateLevers", {
                Title = "Activate Light Switches",
                Description = "Automatically activates built light switches that haven't been activated yet",
                Default = false,
                Callback = function(Value)
                    local autoActivateEnabled = Value
                    if Value then
                        task.spawn(function()
                            while autoActivateEnabled do
                                pcall(function()
                                    local Buildings = require(ReplicatedStorage.Shared.List.Buildings)
                                    local playerData = DataController:getData()
                                    if not playerData then return end
                                    
                                    for buildingId, buildingData in pairs(Buildings) do
                                        if buildingId:lower():find("lightswitch") then
                                            local isBuilt = playerData.buildings and playerData.buildings[buildingId] or false
                                            
                                            if isBuilt then
                                                local switchNumber = buildingId:match("lightSwitch(%d+)")
                                                if switchNumber then
                                                    local switchId = tonumber(switchNumber)
                                                    
                                                    local isActivated = table.find(playerData.lightSwitches or {}, switchId) ~= nil
                                                    
                                                    if not isActivated then
                                                        local Knit = require(ReplicatedStorage.Packages.Knit)
                                                        Knit.GetService("RewardService").activateLightSwitch._re:FireServer(switchId)
                                                        task.wait(1)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end)
                                
                                task.wait(3)
                            end
                        end)
                    else
                        autoActivateEnabled = false
                    end
                end
            })

            local SeasonQuest = Tabs.Quest:AddSection("Season Quests")

            SeasonQuest:Button({
                Title = "Season Quests Script",
                Description = "Sorry for the separate loadstring! Having such a large script was causing me to run out of local uses and creating lag issues.",
                Callback = function()
                    safeLoadUrl("https://raw.githubusercontent.com/BigBeanLUA/RCU/refs/heads/main/Quest")()
                end
            })


            SeasonQuest:Toggle("AutoLoadSeasonQuest", {
            Title = "Auto Load Season Quest",
            Description = "Automatically loads the Season Quest script when you load this script. Use this if you have auto load config on.",
            Default = false,
            Callback = function(enabled)
                AutoLoadSeasonQuest = enabled
                if enabled then
                    safeLoadUrl("https://raw.githubusercontent.com/BigBeanLUA/RCU/refs/heads/main/Quest")()
                end
            end})

                
            local MapQuestSection = Tabs.Quest:AddSection("Map Quests")

            local MapQuestStatusParagraph = MapQuestSection:Paragraph("MapQuestStatus", {
                Title = "Map Quest Progress",
                Content = "Loading map quest status...",
                TitleAlignment = "Middle",
                ContentAlignment = Enum.TextXAlignment.Left
            })

            local updateMapQuestStatus = function()
                pcall(function()
                    local Maps = require(ReplicatedStorage.Shared.List.Maps)
                    DataController:waitForData()
                    local playerData = DataController:getData()
                    
                    if not playerData then
                        MapQuestStatusParagraph:SetValue("❌ Could not get player data")
                        return
                    end
                    
                    -- Find highest map number
                    local highestMap = 0
                    if playerData.maps then
                        for mapNumber, _ in pairs(playerData.maps) do
                            if tonumber(mapNumber) and tonumber(mapNumber) > highestMap then
                                highestMap = tonumber(mapNumber)
                            end
                        end
                    end
                    
                    -- Next map to unlock
                    local nextMapNumber = highestMap + 1
                    local nextMap = Maps[nextMapNumber]
                    
                    local statusLines = {}
                    table.insert(statusLines, string.format("🏆 Best Map Owned: %d", highestMap))
                    
                    if nextMap then
                        table.insert(statusLines, string.format("🎯 Next Map: Map %d - %s", nextMapNumber, nextMap.name))
                        table.insert(statusLines, "")
                        
                        if nextMap.quests then
                            table.insert(statusLines, "📋 Quest Progress:")
                            
                            for questIndex, questData in pairs(nextMap.quests) do
                                local questType = questData.quest
                                local required = questData.amount
                                local questName = questData.name
                                
                                -- Get progress from mapQuests
                                local currentProgress = playerData.mapQuests[questIndex] or 0
                                
                                -- Cap progress at required amount for display
                                local displayProgress = math.min(currentProgress, required)
                                
                                local isCompleted = currentProgress >= required
                                local status = isCompleted and "✅" or "❌"
                                local percentage = math.floor((displayProgress / required) * 100)
                                
                                -- Show quest info
                                local displayText = questType
                                if questName then
                                    displayText = questType .. " (" .. questName .. ")"
                                end
                                
                                table.insert(statusLines, string.format("%s %s", status, displayText))
                                table.insert(statusLines, string.format("   %s/%s (%d%%)", 
                                    Functions.suffixes(displayProgress),
                                    Functions.suffixes(required),
                                    percentage
                                ))
                            end
                        end
                    else
                        table.insert(statusLines, "🎉 ALL MAPS UNLOCKED!")
                    end
                    
                    MapQuestStatusParagraph:SetValue(table.concat(statusLines, "\n"))
                end)
            end

        
            -- Update map quest status every 5 seconds
            task.spawn(function()
                while true do
                    updateMapQuestStatus()
                    task.wait(5)
                end
            end)

            -- Toggle in GUI
            local MapQuestToggle = MapQuestSection:Toggle("AutoCompleteMapQuest", {
                Title = "Auto Complete Map Quest",
                Description = "Automatically completes map quests and unlocks walls sequentially.",
                Default = false,
                Callback = function(enabled)
                    task.spawn(function()
                        _G.MapQuestEnabled = enabled
                        
                        -- Store original states when enabling
                        local originalStates = {
                            autoClickEnabled = AutoClick.Value,
                            autoRebirthEnabled = AutoRebirth.Value,
                            selectedRebirthValue = rebirthDropdown.Value,
                            selectedEggValue = EggDropdown.Value,
                            selectedAmountValue = HatchAmount.Value,
                            autoHatchEnabled = AutoHatch.Value,
                            craftAllToggleState = CraftAllToggle.Value,
                            selectedFarmsForClaim = claimDropdown.Value or {},
                            autoClaimFarmsEnabled = AutoClaimFarm.Value,
                            selectedTreesValue = SelectTreesDropdown.Value,
                            autoCutTreesEnabled = AutoCutTreesToggle.Value,
                            selectedPetsValue = PetDropdown.Value,
                            autoBuyFarmsEnabled = BuyFarm.Value,
                            selectedFarmsToBuy = farmDropdown.Value or {},
                            AutoCraftBuildings = AutoCraftBuildings.Value,
                            autoCraftDropdown = autoCraftDropdown.Value
                        }
                        
                        local function restoreOriginalStates()
                            pcall(function()
                                AutoClick:SetValue(originalStates.autoClickEnabled)
                                AutoRebirth:SetValue(originalStates.autoRebirthEnabled)
                                rebirthDropdown:SetValue(originalStates.selectedRebirthValue)
                                EggDropdown:SetValue(originalStates.selectedEggValue)
                                farmDropdown:SetValue(originalStates.selectedFarmsToBuy)
                                HatchAmount:SetValue(originalStates.selectedAmountValue)
                                AutoHatch:SetValue(originalStates.autoHatchEnabled)
                                CraftAllToggle:SetValue(originalStates.craftAllToggleState)
                                claimDropdown:SetValue(originalStates.selectedFarmsForClaim)
                                AutoClaimFarm:SetValue(originalStates.autoClaimFarmsEnabled)
                                SelectTreesDropdown:SetValue(originalStates.selectedTreesValue)
                                AutoCutTreesToggle:SetValue(originalStates.autoCutTreesEnabled)
                                BuyFarm:SetValue(originalStates.autoBuyFarmsEnabled)
                                PetDropdown:SetValue(originalStates.selectedPetsValue)
                                AutoCraftBuildings:SetValue(originalStates.AutoCraftBuildings)
                                autoCraftDropdown:SetValue(originalStates.autoCraftDropdown)
                            end)
                        end
                        
                        if enabled then
                            
                            if AutoClick and not AutoClick.Value then
                                AutoClick:SetValue(true)
                            end

                            task.spawn(function()
                                while _G.MapQuestEnabled do
                                    task.wait(10)
                                    if _G.MapQuestEnabled then
                                        _G.MapQuestEnabled = false
                                        task.wait(0.5)
                                        _G.MapQuestEnabled = true
                                    end
                                end
                            end)

                            -- Track active quest handlers
                            local activeQuestHandlers = {}
                            local spaceWorldPurchaseActive = false

                            task.spawn(function()
                                while _G.MapQuestEnabled do
                                    local success = pcall(function()
                                        if not _G.MapQuestEnabled then return end
                                        
                                        local Maps = require(ReplicatedStorage.Shared.List.Maps)
                                        local playerData = DataController:getData()
                                        
                                        if not playerData then 
                                            return 
                                        end

                                        local highestMap = 0
                                        if playerData.maps then
                                            for mapNumber, _ in pairs(playerData.maps) do
                                                if tonumber(mapNumber) and tonumber(mapNumber) > highestMap then
                                                    highestMap = tonumber(mapNumber)
                                                end
                                            end
                                        end
                                        
                                        local nextMapNumber = highestMap + 1
                                        local nextMap = Maps[nextMapNumber]

                                        
                                        local incompleteQuests = {}
                                        local allQuestsCompleted = true
                                        
                                        if nextMap and nextMap.quests then
                                            
                                            for questIndex, questData in pairs(nextMap.quests) do
                                                if not _G.MapQuestEnabled then return end
                                                
                                                local currentProgress = playerData.mapQuests[questIndex] or 0
                                                local questType = questData.quest
                                                local required = questData.amount
                                                local questName = questData.name
                                                
                                                if currentProgress >= required then
                                                    continue
                                                else
                                                    allQuestsCompleted = false
                                                    table.insert(incompleteQuests, {
                                                        index = questIndex,
                                                        type = questType,
                                                        name = questName,
                                                        required = required,
                                                        current = currentProgress
                                                    })
                                                end
                                            end
                                        else
                                            allQuestsCompleted = true
                                        end
                                        
                                        if allQuestsCompleted then
                                            restoreOriginalStates()
                                            _G.MapQuestEnabled = false
                                            return
                                        end
                                        
                                        
                                        -- Track which systems should be active
                                        local shouldAutoRebirth = false
                                        local shouldAutoHatch = false
                                        local shouldCraftAll = false
                                        local shouldAutoClaimFarm = false
                                        local shouldBuyFarm = false
                                        local shouldAutoCraftBuildings = false
                                        
                                        local eggToHatch = nil
                                        local rebirthAmount = nil
                                        local petsToSelect = {}
                                        local farmsToSelect = {}
                                        local claimFarmsToSelect = {}
                                        local buildingsToSelect = {}
                                        
                                        for _, quest in ipairs(incompleteQuests) do
                                            local questType = quest.type
                                            local questName = quest.name
                                            local required = quest.required
                                            local currentProgress = quest.current
                                            
                                            
                                            if questType == "rebirths" then
                                                local currentRebirths = playerData.rebirths or 0
                                                local rebirthsNeeded = required - currentRebirths

                                                if rebirthsNeeded > 1e98 then
                                                    for _, option in ipairs(rebirthOptions) do
                                                        if option.amount == 1e12 then
                                                            rebirthAmount = option.display
                                                            break
                                                        end
                                                    end
                                                    shouldAutoRebirth = true

                                                    if not spaceWorldPurchaseActive then
                                                        spaceWorldPurchaseActive = true
                                                        task.spawn(function()
                                                            local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
                                                            local MapService = Knit.GetService("MapService")
                                                            while _G.MapQuestEnabled and spaceWorldPurchaseActive do
                                                                pcall(function()
                                                                    MapService:purchaseSpaceWorld()
                                                                end)
                                                                task.wait(3)
                                                            end
                                                        end)
                                                    end
                                                else
                                                    local bestOptionDisplay = nil
                                                    if rebirthsNeeded > 0 then
                                                        for _, option in ipairs(rebirthOptions) do
                                                            if option.amount >= rebirthsNeeded then
                                                                bestOptionDisplay = option.display
                                                                break
                                                            end
                                                        end
                                                    end
                                                    rebirthAmount = bestOptionDisplay or "Max Unlocked"
                                                    shouldAutoRebirth = true
                                                    spaceWorldPurchaseActive = false
                                                end

                                            elseif questType == "openEgg" and questName then
                                                for _, eggOption in ipairs(eggOptions) do
                                                    if eggOption:lower():find(questName:lower()) then
                                                        eggToHatch = eggOption
                                                        shouldAutoHatch = true
                                                        break
                                                    end
                                                end

                                            elseif questType == "craftAnyGalaxyPets" then
                                                local previousMapNumber = nextMapNumber - 1
                                                local previousMap = Maps[previousMapNumber]
                                                local previousWorldEggName = (previousMap and previousMap.name) or nextMap.name
                                                
                                                for _, eggOption in ipairs(eggOptions) do
                                                    if eggOption:lower():find(previousWorldEggName:lower()) then
                                                        eggToHatch = eggOption
                                                        shouldAutoHatch = true
                                                        break
                                                    end
                                                end
                                                
                                                PetDropdown:SetValues(getPlayerPetOptions())
                                                local playerPetOptions = getPlayerPetOptions()
                                                local galaxyCraftablePets = {}
                                                
                                                local Eggs = require(ReplicatedStorage.Shared.List.Pets.Eggs)
                                                local previousEggData = Eggs[previousWorldEggName]
                                                local previousWorldPetNames = {}
                                                if previousEggData and previousEggData.pets then
                                                    for petName, _ in pairs(previousEggData.pets) do 
                                                        table.insert(previousWorldPetNames, petName) 
                                                    end
                                                end
                                                
                                                for _, displayName in ipairs(playerPetOptions) do
                                                    for _, worldPetName in ipairs(previousWorldPetNames) do
                                                        if displayName:find(worldPetName) then
                                                            galaxyCraftablePets[displayName] = true
                                                            petsToSelect[displayName] = true
                                                            break
                                                        end
                                                    end
                                                end

                                                local toxicPetNames = {}
                                                if playerData.maps then
                                                    for mapNumber, _ in pairs(playerData.maps) do
                                                        local mapNum = tonumber(mapNumber)
                                                        if mapNum and mapNum >= 17 then
                                                            local mapData = Maps[mapNum]
                                                            if mapData and mapData.name then
                                                                local worldEggData = Eggs[mapData.name]
                                                                if worldEggData and worldEggData.pets then
                                                                    for petName, chance in pairs(worldEggData.pets) do
                                                                        if chance > 0.01 then 
                                                                            table.insert(toxicPetNames, petName) 
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end

                                                for _, displayName in ipairs(playerPetOptions) do
                                                    for _, toxicPetName in ipairs(toxicPetNames) do
                                                        if displayName:find("Toxic") and displayName:find(toxicPetName) then
                                                            galaxyCraftablePets[displayName] = true
                                                            petsToSelect[displayName] = true
                                                            break
                                                        end
                                                    end
                                                end
                                                
                                                if next(petsToSelect) then
                                                    shouldCraftAll = true
                                                end
                                                
                                            elseif questType == "hatchPet" and questName then
                                                local previousMapNumber = nextMapNumber - 1
                                                local previousMap = Maps[previousMapNumber]
                                                local worldName = (previousMap and previousMap.name) or "Spawn"
                                                
                                                for _, eggOption in ipairs(eggOptions) do
                                                    if eggOption:lower():find(worldName:lower()) then
                                                        eggToHatch = eggOption
                                                        shouldAutoHatch = true
                                                        break
                                                    end
                                                end
                    
                                            elseif questType == "useAuraDice" then
                                                local bestDiceId, maxAmount = nil, 0
                                                if playerData.inventory and playerData.inventory.auraDice then
                                                    for itemId, itemData in pairs(playerData.inventory.auraDice) do
                                                        if (itemData.am or 0) > maxAmount then
                                                            maxAmount = itemData.am
                                                            bestDiceId = itemData.nm or itemId
                                                        end
                                                    end
                                                end
                                                if bestDiceId and maxAmount > 0 then
                                                    pcall(function() AuraService:roll(bestDiceId) end)
                                                end
                                                
                                            elseif questType == "collectFruits" then
                                                rebirthAmount = "Max Unlocked"
                                                shouldAutoRebirth = true
                                                
                                                for _, farmName in ipairs(farmOptions) do 
                                                    farmsToSelect[farmName] = true 
                                                end
                                                shouldBuyFarm = true
                                                
                                                for _, farmName in ipairs(claimFarmOptions) do 
                                                    claimFarmsToSelect[farmName] = true 
                                                end
                                                shouldAutoClaimFarm = true
                                            
                                            elseif questType == "building" and questName and (questName:lower():find("bridge") or questName:lower():find("wooden")) then
                                                local bridgeOptionName = "Wooden Bridge"
                                                local foundOption = false
                                                for _, option in ipairs(autoCraftDropdown.Values) do
                                                    if option == bridgeOptionName then
                                                        foundOption = true
                                                        break
                                                    end
                                                end

                                                if foundOption then
                                                    buildingsToSelect[bridgeOptionName] = true
                                                    shouldAutoCraftBuildings = true
                                                end
                                                
                                            elseif questType == "usePotions" then
                                                local bestPotionId, maxAmount = nil, 0
                                                if playerData.inventory and playerData.inventory.potion then
                                                    for itemId, itemData in pairs(playerData.inventory.potion) do
                                                        if (itemData.am or 0) > maxAmount and not (itemData.nm or ""):lower():find("mega") then
                                                            maxAmount = itemData.am
                                                            bestPotionId = itemId
                                                        end
                                                    end
                                                end
                                                if bestPotionId and maxAmount > 0 then
                                                    local potionsNeeded = math.min(required - currentProgress, maxAmount)
                                                    if potionsNeeded > 0 then
                                                        pcall(function() 
                                                            Knit.GetService("InventoryService"):useItem(bestPotionId, {use = potionsNeeded}) 
                                                        end)
                                                    end
                                                end
                                                
                                            elseif questType == "useMegaPotions" then
                                                local bestMegaPotionId, maxAmount = nil, 0
                                                if playerData.inventory and playerData.inventory.potion then
                                                    for itemId, itemData in pairs(playerData.inventory.potion) do
                                                        if (itemData.am or 0) > maxAmount and (itemData.nm or ""):lower():find("mega") then
                                                            maxAmount = itemData.am
                                                            bestMegaPotionId = itemId
                                                        end
                                                    end
                                                end
                                                if bestMegaPotionId and maxAmount > 0 then
                                                    local megaPotionsNeeded = math.min(required - currentProgress, maxAmount)
                                                    if megaPotionsNeeded > 0 then
                                                        pcall(function() 
                                                            Knit.GetService("InventoryService"):useItem(bestMegaPotionId, {use = megaPotionsNeeded}) 
                                                        end)
                                                    end
                                                end
                                            end
                                        end

                                        
                                        if shouldAutoRebirth and rebirthAmount then
                                            rebirthDropdown:SetValue(rebirthAmount)
                                            AutoRebirth:SetValue(true)
                                        else
                                            AutoRebirth:SetValue(false)
                                        end
                                        
                                        if shouldAutoHatch and eggToHatch then
                                            EggDropdown:SetValue(eggToHatch)
                                            HatchAmount:SetValue("Max")
                                            AutoHatch:SetValue(true)
                                        else
                                            AutoHatch:SetValue(false)
                                        end
                                        
                                        if shouldCraftAll and next(petsToSelect) then
                                            PetDropdown:SetValue(petsToSelect)
                                            CraftAllToggle:SetValue(true)
                                        else
                                            CraftAllToggle:SetValue(false)
                                        end
                                        
                                        if shouldAutoClaimFarm and next(claimFarmsToSelect) then
                                            claimDropdown:SetValue(claimFarmsToSelect)
                                            AutoClaimFarm:SetValue(true)
                                        else
                                            AutoClaimFarm:SetValue(false)
                                        end
                                        
                                        if shouldBuyFarm and next(farmsToSelect) then
                                            farmDropdown:SetValue(farmsToSelect)
                                            BuyFarm:SetValue(true)
                                        else
                                            BuyFarm:SetValue(false)
                                        end
                                        
                                        if shouldAutoCraftBuildings and next(buildingsToSelect) then
                                            autoCraftDropdown:SetValue(buildingsToSelect)
                                            AutoCraftBuildings:SetValue(true)
                                        else
                                            AutoCraftBuildings:SetValue(false)
                                        end
                                        
                                        -- Disable unused systems
                                        AutoCutTreesToggle:SetValue(false)
                                    end)
                                    
                                    if not success then 
                                    end
                                    if not _G.MapQuestEnabled then break end
                                    
                                    task.wait(5)
                                end
                                restoreOriginalStates()
                            end)
                        else
                            _G.MapQuestEnabled = false
                            restoreOriginalStates()
                        end
                    end)
                end
            })
            
            task.spawn(function()
            while true do
                if MapQuestToggle.Value then
                    MapQuestToggle:SetValue(false)
                    task.wait(0.2)
                    MapQuestToggle:SetValue(true)
                    task.wait(0.2)
                    MapQuestToggle:SetValue(true)
                end
                task.wait(10)
            end
        end)

            local MapQuestNone = MapQuestSection:Paragraph("MapQuestNone", {
                Title = "Note",
                Content = "For the build quest in the kingdom world, the bridge will be built, but this script won't source the resources. Make sure you have at least 3 ancient ticks, 3 fire aura dice, 5 grapes, and 5 apples.",
                TitleAlignment = "Middle",
                ContentAlignment = Enum.TextXAlignment.Left
            })

            local AngelQuestSection = Tabs.Quest:AddSection("Angel Quests")

            angelQuestEnabled = false

            local AngelQuestStatusParagraph = AngelQuestSection:Paragraph("AngelQuestStatus", {
                Title = "Angel Quest Status",
                Content = "Loading quest status...",
                TitleAlignment = "Middle",
                ContentAlignment = Enum.TextXAlignment.Left
            })

            updateAngelQuestStatus = function()
                pcall(function()
                    local AngelQuestsList = require(ReplicatedStorage.Shared.List.AngelQuests)
                    DataController:waitForData()
                    local playerData = DataController:getData()
                    
                    local currentTier = playerData.angelQuestTier or 1
                    local currentProgress = playerData.angelQuestProgress or 0
                    local totalTiers = #AngelQuestsList
                    
                    if currentTier > totalTiers then
                        AngelQuestStatusParagraph:SetValue(string.format("🎉 Completed all %d Angel Quests!", totalTiers))
                    else
                        local questInfo = AngelQuestsList[currentTier]
                        if questInfo then
                            local requiredAmount = questInfo.quest.amount
                            local formattedQuestText = questInfo.text:format(requiredAmount)
                            
                            local statusText = string.format(
                                "📋 Tier: %d/%d\n🎯 Quest: %s\n📊 Progress: %d/%d",
                                currentTier, totalTiers, formattedQuestText, currentProgress, requiredAmount
                            )
                            AngelQuestStatusParagraph:SetValue(statusText)
                        else
                            AngelQuestStatusParagraph:SetValue(string.format("❌ Unable to read quest for Tier %d", currentTier))
                        end
                    end
                end)
            end

            getAllAuraDice = function()
                local options, diceMap = {}, {}
                pcall(function()
                    local AuraDices = require(ReplicatedStorage.Shared.List.Items.AuraDices)
                    for diceId, diceData in pairs(AuraDices) do
                        local displayName = diceData.name
                        table.insert(options, displayName)
                        diceMap[displayName] = diceId
                    end
                end)
                table.sort(options)
                return options, diceMap
            end

            local diceOptions, diceIdMap = getAllAuraDice()

            allowedDiceDropdown = AngelQuestSection:Dropdown("AllowedDice", {
                Title = "Allowed Dice",
                Description = "Select which dice to use for aura quests (if none selected, uses any owned dice)",
                Values = diceOptions,
                Multi = true,
                Searchable = true,
                Default = {}
            })


            getCurrentQuestType = function()
                local success, result = pcall(function()
                    local AngelQuestsList = require(ReplicatedStorage.Shared.List.AngelQuests)
                    DataController:waitForData()
                    local playerData = DataController:getData()
                    
                    if not playerData then 
                        return nil 
                    end
                    
                    local currentTier = playerData.angelQuestTier or 1
                    
                    if currentTier <= #AngelQuestsList then
                        local questData = AngelQuestsList[currentTier]
                        return questData and questData.quest or nil
                    else
                        return nil
                    end
                end)
                
                if success then
                    return result
                else
                    return nil
                end
            end


            findBestPotion = function()
                local playerData = DataController:getData()
                if not playerData or not playerData.inventory or not playerData.inventory.potion then
                    return nil
                end
                
                local bestPotion = nil
                local highestAmount = 0
                
                for itemId, itemData in pairs(playerData.inventory.potion) do
                    if itemData.am and itemData.am > highestAmount then
                        highestAmount = itemData.am
                        bestPotion = itemId
                    end
                end
                
                return bestPotion
            end

            getAvailableAuraDice = function()
                local playerData = DataController:getData()
                if not playerData then
                    return {}
                end
                
                local selectedDice = allowedDiceDropdown.Value or {}
                local availableDice = {}
                
                if next(selectedDice) == nil then
                    local AuraDices = require(ReplicatedStorage.Shared.List.Items.AuraDices)
                    
                    for diceId, diceData in pairs(AuraDices) do
                        local item = Util.itemUtils.getItemFromName(playerData, diceId)
                        if item and item:getAmount() > 0 then
                            table.insert(availableDice, diceId)
                        end
                    end
                else
                    for diceName, isSelected in pairs(selectedDice) do
                        if isSelected then
                            local diceId = diceIdMap[diceName]
                            local item = Util.itemUtils.getItemFromName(playerData, diceId)
                            if item and item:getAmount() > 0 then
                                table.insert(availableDice, diceId)
                            end
                        end
                    end
                end
                
                return availableDice
            end

            setupForQuestType = function(questType)
                if not questType then 
                    return 
                end
                
                local questName = questType.quest
                
                if questName:lower():find("egg") or questName:lower():find("hatch") then
                    
                    local heavenEggFound = false
                    
                    for i, eggOption in ipairs(eggOptions) do
                        if eggOption:lower():find("heaven") then
                            EggDropdown:SetValue(eggOption)
                            selectedEgg = displayToEggName[eggOption] or "Heaven"
                            heavenEggFound = true
                            break
                        end
                    end
                    
                    if not heavenEggFound then
                    end
                    
                    HatchAmount:SetValue("Max")
                    selectedAmount = hatchAmounts["Max"]
                    
                    if not _G.AutoHatchEnabled then
                        AutoHatch:SetValue(true)
                    else
                    end
                end
                
                if questName == "destroyTree" then
                    AutoEquip:SetValue(true)
                    local neededTrees = {}
                    for _, treeObject in ipairs(SelectTreesDropdown.Values) do
                        local treeName = treeObject.Value:lower()
                        if treeName == "spawn" or treeName == "desert" or treeName == "nuclear" then
                            neededTrees[treeObject] = true
                        end
                    end
                    SelectTreesDropdown:SetValue(neededTrees)
                    selectedTrees = {}
                    for treeType, isSelected in pairs(neededTrees) do
                        if isSelected then table.insert(selectedTrees, treeType.Value) end
                    end
                    if not autoBreakRunning then
                        AutoCutTreesToggle:SetValue(true)
                    else
                    end
                end
                
                if questName == "craftRing" then
                    task.spawn(function()
                        while angelQuestEnabled do
                            pcall(function()
                                local Knit = require(ReplicatedStorage.Packages.Knit)
                                Knit.GetService("RingService"):craftRing("basicRing", 1)
                            end)
                            task.wait(5)
                        end
                    end)
                end
                
                if questName == "usePotions" then
                    task.spawn(function()
                        while angelQuestEnabled do
                            local potionId = findBestPotion()
                            if potionId then
                                pcall(function()
                                    local Knit = require(ReplicatedStorage.Packages.Knit)
                                    Knit.GetService("InventoryService"):useItem(potionId, {use = 1})
                                end)
                            else
                            end
                            task.wait(2)
                        end
                    end)
                end

                if questName == "useAuraDice" or questName == "rollOneInAura" then
                    task.spawn(function()
                        while angelQuestEnabled do
                            local currentQuest = getCurrentQuestType()
                            if not currentQuest or (currentQuest.quest ~= "useAuraDice" and currentQuest.quest ~= "rollOneInAura") then
                                break 
                            end
                            
                            local availableDice = getAvailableAuraDice()
                            if #availableDice > 0 then
                                local randomDice = availableDice[math.random(1, #availableDice)]
                                pcall(function()
                                    AuraService:roll(randomDice)
                                end)
                            else
                            end
                            task.wait(2)
                        end
                    end)
                end
            end

            storeOriginalSettings = function()
                originalEggSelection = selectedEgg
                originalHatchAmount = selectedAmount
                
                originalAutoHatchState = AutoHatch.Value

                originalTreeSelection = {}
                for treeObject, isSelected in pairs(SelectTreesDropdown.Value) do
                    originalTreeSelection[treeObject] = isSelected
                end
                originalAutoCutState = autoBreakRunning
            end

            restoreOriginalSettings = function()
                if originalEggSelection then
                    for _, eggOption in ipairs(eggOptions) do
                        if eggOption:find(originalEggSelection) then
                            EggDropdown:SetValue(eggOption)
                            selectedEgg = displayToEggName[eggOption] or originalEggSelection
                            break
                        end
                    end
                end
                
                if originalHatchAmount then
                    local amountText = originalHatchAmount == 1 and "1x" or originalHatchAmount == 3 and "3x" or "Max"
                    HatchAmount:SetValue(amountText)
                    selectedAmount = originalHatchAmount
                end
                
                if not originalAutoHatchState and _G.AutoHatchEnabled then
                    AutoHatch:SetValue(false)
                end
                
                if originalTreeSelection then
                    SelectTreesDropdown:SetValue(originalTreeSelection)
                    
                    selectedTrees = {}
                    for treeType, isSelected in pairs(originalTreeSelection) do
                        if isSelected then table.insert(selectedTrees, treeType.Value) end
                    end
                end
                
                if autoBreakRunning ~= originalAutoCutState then
                    AutoCutTreesToggle:SetValue(originalAutoCutState)
                end
            end

            angelQuestToggle = AngelQuestSection:Toggle("AutoCompleteAngelQuest", {
                Title = "Auto Complete Angel Quest",
                Description = "Automatically completes the angel quests.",
                Default = false,
                Callback = function(enabled)
                    task.spawn(function()
                        angelQuestEnabled = enabled
                        
                        if enabled then
                            storeOriginalSettings()
                            HasBeenOn = true
                            
                            task.spawn(function()
                                task.wait(2)
                                
                                while angelQuestEnabled do
                                    local currentQuest = getCurrentQuestType()
                                    
                                    if currentQuest then
                                        setupForQuestType(currentQuest)
                                    else
                                    end
                                    
                                    pcall(function()
                                        local AngelQuestsList = require(ReplicatedStorage.Shared.List.AngelQuests)
                                        DataController:waitForData()
                                        local playerData = DataController:getData()
                                        
                                        local currentTier = playerData.angelQuestTier or 1
                                        local currentProgress = playerData.angelQuestProgress or 0
                                        
                                        if currentTier <= #AngelQuestsList then
                                            local questInfo = AngelQuestsList[currentTier]
                                            if questInfo then
                                                local requiredAmount = questInfo.quest.amount
                                                
                                                if currentProgress >= requiredAmount then
                                                    local Knit = require(ReplicatedStorage.Packages.Knit)
                                                    Knit.GetService("QuestService"):claimAngelQuest()
                                                    restoreOriginalSettings()
                                                    task.wait(2)
                                                end
                                            end
                                        end
                                    end)
                                    
                                    updateAngelQuestStatus()
                                    task.wait(1)
                                end
                            end)
                        elseif HasBeenOn == true then 
                            restoreOriginalSettings()
                        end
                    end)
                end})


            task.spawn(function()
                while true do
                    updateAngelQuestStatus()
                    task.wait(5)
                end
            end)

            -- ============================================================

            -- ============================================================
            -- FISHING (External Loadstring)
            -- ============================================================
            local FishSection = Tabs.MineFish:AddSection("Fishing Script")

            FishSection:Button({
                Title = "Load Fishing Script",
                Description = "Loads the full fishing automation script with auto fish, auto sell, rod upgrades, and more.",
                Callback = function()
                    safeLoadUrl("https://raw.githubusercontent.com/BigBeanLUA/RCU/refs/heads/main/Fish")()
                end
            })

            FishSection:Toggle("AutoLoadFish", {
                Title = "Auto Load Fishing Script",
                Description = "Loads the fishing script automatically when the main script starts. Enable this if you use auto-load config.",
                Default = false,
                Callback = function(enabled)
                    _G.AutoLoadFish = enabled
                    if enabled then
                        safeLoadUrl("https://raw.githubusercontent.com/BigBeanLUA/RCU/refs/heads/main/Fish")()
                    end
                end
            })

            -- ============================================================
            -- MINING (External Loadstring)
            -- ============================================================
            local MineSection = Tabs.MineFish:AddSection("Mining Script")

            MineSection:Button({
                Title = "Load Mining Script",
                Description = "Loads the full mining automation script with auto mine, ore processing, pickaxe upgrades, and more.",
                Callback = function()
                    safeLoadUrl("https://raw.githubusercontent.com/BigBeanLUA/RCU/refs/heads/main/Mine")()
                end
            })

            MineSection:Toggle("AutoLoadMine", {
                Title = "Auto Load Mining Script",
                Description = "Loads the mining script automatically when the main script starts. Enable this if you use auto-load config.",
                Default = false,
                Callback = function(enabled)
                    _G.AutoLoadMine = enabled
                    if enabled then
                        safeLoadUrl("https://raw.githubusercontent.com/BigBeanLUA/RCU/refs/heads/main/Mine")()
                    end
                end
            })

            ClaimSection = Tabs.Claim:AddSection("Claim/Collect")

            local isAutoCollectEnabled = false
            local autoCollectThread = nil
            local selectedZones = {}

            local function claimChestsInUnlockedMaps()
                if not game:IsLoaded() then game.Loaded:Wait() end
                task.wait(1)

                local Knit = require(ReplicatedStorage.Packages.Knit)
                local Maps = require(ReplicatedStorage.Shared.List.Maps)

                local DataController
                repeat
                    DataController = Knit.GetController("DataController")
                    task.wait()
                until DataController

                local function getUnlockedZones()
                    local playerData = DataController:getData()
                    if not playerData or not playerData.maps then return {} end
                    local unlockedMapIds = playerData.maps
                    local unlockedZones = {}
                    for mapId, mapData in pairs(Maps) do
                        if mapData.alwaysUnlocked or table.find(unlockedMapIds, mapId) then
                            mapData.id = mapId
                            table.insert(unlockedZones, mapData)
                        end
                    end
                    table.sort(unlockedZones, function(a, b) return a.id < b.id end)
                    return unlockedZones
                end

                local function formatZoneName(name)
                    return (name:gsub("%s+", ""))
                end

                local function firePrompt(prompt)
                    if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
                        fireproximityprompt(prompt, math.huge)
                    end
                end

                local function getZonePrompts(zoneFolder)
                    local prompts = {}
                    for _, obj in ipairs(zoneFolder:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and obj.Enabled then
                            local parent = obj.Parent
                            if parent and parent.Name == "Touch" then
                                table.insert(prompts, obj)
                            end
                        end
                    end
                    return prompts
                end

                local function beginChestCollection()
                    local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
                    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
                    local originalCFrame = humanoidRootPart.CFrame

                    local unlockedZones = getUnlockedZones()
                    if #unlockedZones == 0 then return end

                    -- Filter zones based on selection
                    local zonesToCollect = {}
                    if next(selectedZones) then
                        -- If zones are selected, only collect from those
                        for _, zoneData in ipairs(unlockedZones) do
                            if selectedZones[zoneData.name] then
                                table.insert(zonesToCollect, zoneData)
                            end
                        end
                    else
                        -- If no zones selected, collect from all unlocked zones
                        zonesToCollect = unlockedZones
                    end

                    for _, zoneData in ipairs(zonesToCollect) do
                        if not isAutoCollectEnabled then break end 
                        if not zoneData.cframe then continue end

                        local zoneName = formatZoneName(zoneData.name)
                        local mapFolder = Workspace:FindFirstChild("Game") and Workspace.Game.Maps:FindFirstChild(zoneName)
                        if not mapFolder then continue end

                        humanoidRootPart:PivotTo(zoneData.cframe)
                        task.wait(2)

                        local lastCount = 0
                        local sameCountDuration = 0
                        local noPromptCount = 0

                        while isAutoCollectEnabled do
                            local prompts = getZonePrompts(mapFolder)
                            local currentCount = #prompts

                            if currentCount == lastCount then
                                sameCountDuration += 1
                            else
                                sameCountDuration = 0
                            end
                            lastCount = currentCount

                            if sameCountDuration >= 10 then
                                break
                            end

                            if #prompts == 0 then
                                noPromptCount += 1
                                if noPromptCount >= 3 then
                                    break
                                end
                            else
                                noPromptCount = 0
                                for _, prompt in ipairs(prompts) do
                                    if not isAutoCollectEnabled then break end
                                    firePrompt(prompt)
                                    task.wait(0.25)
                                end
                            end
                            task.wait(1)
                        end

                        task.wait(1)
                    end
                end

                pcall(beginChestCollection)
            end

            -- Get all available zones for dropdown
            local function getAllZones()
                local zoneOptions = {}
                pcall(function()
                    local Maps = require(ReplicatedStorage.Shared.List.Maps)
                    local zoneList = {}
                    
                    for mapId, mapData in pairs(Maps) do
                        if mapData.name then
                            table.insert(zoneList, {
                                id = tonumber(mapId) or 0,
                                name = mapData.name
                            })
                        end
                    end
                    
                    table.sort(zoneList, function(a, b) return a.id < b.id end)
                    
                    for _, zone in ipairs(zoneList) do
                        table.insert(zoneOptions, zone.name)
                    end
                end)
                
                return zoneOptions
            end

            -- Zone selection dropdown
            local ZoneDropdown = ClaimSection:Dropdown("SelectZonesToCollect", {
                Title = "Mini Chest Zones",
                Values = getAllZones(),
                Multi = true,
                Searchable = true,
                Default = {},
                Callback = function(value)
                    selectedZones = value
                end
            })

            -- Toggle for Auto Chest Collection
            ClaimSection:Toggle("AutoCollectMiniChests", {
                Title = "Auto Collect Mini-Chests",
                Default = false,
                Callback = function(enabled)
                    isAutoCollectEnabled = enabled

                    if enabled then
                        autoCollectThread = task.spawn(function()
                            while isAutoCollectEnabled do
                                claimChestsInUnlockedMaps()
                                task.wait(5)
                            end
                        end)
                    else
                        if autoCollectThread then
                            task.cancel(autoCollectThread)
                            autoCollectThread = nil
                        end
                    end
                end
            })

            ClaimSection:Toggle("AutoPickUp", { Title = "Auto Pick Up", Default = false,
                Callback = function(enabled)
                    _G.AutoPickUpEnabled = enabled
                    if _G.AutoPickUpThread then task.cancel(_G.AutoPickUpThread); _G.AutoPickUpThread = nil end
                    if enabled then
                        _G.AutoPickUpThread = task.spawn(function()
                            local orbsFolder = Workspace:FindFirstChild("Debris") and Workspace.Debris:FindFirstChild("Orbs")
                            if not orbsFolder then return end
                            while _G.AutoPickUpEnabled and task.wait(0.2) do
                                local character, hrp = LocalPlayer.Character, nil
                                if character and character:FindFirstChild("HumanoidRootPart") then hrp = character.HumanoidRootPart else continue end
                                local orbsToCollect = {}
                                for _, orb in ipairs(orbsFolder:GetChildren()) do
                                    if orb:IsA("BasePart") then
                                        orb:SetAttribute("canCollect", true); orb.Anchored = true
                                        if (orb.Position - hrp.Position).Magnitude <= math.huge then
                                            table.insert(orbsToCollect, orb.Name)
                                            local attachment = hrp:FindFirstChild("_orbAttachment" .. orb.Name); if attachment then attachment:Destroy() end
                                        end
                                    end
                                end
                                if #orbsToCollect > 0 then
                                    pcall(function() OrbService.collectOrbs:Fire(orbsToCollect) end)
                                    for _, orbName in ipairs(orbsToCollect) do local orb = orbsFolder:FindFirstChild(orbName); if orb then orb:Destroy() end end
                                end
                            end
                        end)
                    end
                end
            })

            pickupStarsThread = nil
            ClaimSection:Toggle("PickupStars", { Title = "Pickup Stars",
                Callback = function(enabled)
                    if pickupStarsThread then task.cancel(pickupStarsThread); pickupStarsThread = nil end
                    if enabled then
                        pickupStarsThread = task.spawn(function()
                            while enabled do
                                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                local debris = Workspace:FindFirstChild("Debris")
                                if hrp and debris then
                                    for _, starModel in ipairs(debris:GetChildren()) do
                                        if starModel.Name == "FallingStar" then
                                            local starCore = starModel.PrimaryPart
                                            local hideFolder = starCore and starCore:FindFirstChild("hideAfterLanding")
                                            if hideFolder then
                                                local isStillFalling = false
                                                for _, particle in ipairs(hideFolder:GetChildren()) do
                                                    if particle:IsA("ParticleEmitter") and particle.Enabled == true then
                                                        isStillFalling = true
                                                        break
                                                    end
                                                end
                                                if not isStillFalling then
                                                    pcall(firetouchinterest, hrp, starCore, 0)
                                                    pcall(firetouchinterest, hrp, starCore, 1)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                task.wait(0.1)
                            end
                        end)
                    end
                end
            })


            local autoClaimThreads = {}
            createClaimToggle = function(id, title, claimFunc)
                ClaimSection:Toggle("AutoClaim"..id, { Title = title, Default = false,
                    Callback = function(enabled)
                        if autoClaimThreads[id] then task.cancel(autoClaimThreads[id]); autoClaimThreads[id]=nil end
                        if enabled then autoClaimThreads[id] = task.spawn(function() while enabled do pcall(claimFunc); task.wait(5) end end) end
                    end
                })
            end

            createClaimToggle("Achievements", "Auto Claim Achievements", function()
                local Achievements = require(ReplicatedStorage.Shared.List.Achievements)
                DataController:waitForData()
                local playerData = DataController:getData()
                for achievementKey, achievementData in pairs(Achievements) do
                    local currentLevel = 1
                    for claimedId, _ in pairs(playerData.claimedAchievements) do if claimedId:find(achievementKey) then currentLevel = currentLevel + 1 end end
                    if #achievementData.list >= currentLevel and achievementData.list[currentLevel].amount <= achievementData.getValue(playerData) then
                        RewardService:claimAchievement(achievementKey); task.wait(1)
                    end
                end
            end)

            local autoClaimPlaytimeEnabled = false
            ClaimSection:Toggle("AutoClaimPlaytime", {
                Title = "Auto Claim Playtime Rewards",
                Default = false,
                Callback = function(enabled)
                    autoClaimPlaytimeEnabled = enabled

                    if autoClaimPlaytimeThread then
                        task.cancel(autoClaimPlaytimeThread)
                        autoClaimPlaytimeThread = nil
                    end

                    if enabled then
                        autoClaimPlaytimeThread = task.spawn(function()
                            local Holder = LocalPlayer.PlayerGui.MainUI.Menus.RewardsFrame.Main.Displays.Playtime.Holder

                            while autoClaimPlaytimeEnabled do
                                local success, err = pcall(function()
                                    for _, rewardFrame in ipairs(Holder:GetChildren()) do
                                        if rewardFrame:IsA("Frame") then
                                            local rewardId = tonumber(rewardFrame.Name)
                                            local timerLabel = rewardFrame:FindFirstChild("Main", true) and rewardFrame.Main:FindFirstChild("Timer")

                                            if timerLabel and timerLabel.Text == "Claim" then
                                                RewardService:claimPlaytimeReward(rewardId)
                                                task.wait(1)
                                            end
                                        end
                                    end
                                end)

                                if not success then
                                end

                                task.wait(10)
                            end
                        end)
                    end
                end
            })

            createClaimToggle("Daily", "Auto Claim Daily Reward", function()
                DataController:waitForData()
                local playerData = DataController:getData()
                if workspace:GetServerTimeNow() - playerData.dayReset >= 86400 and math.max(0, 600 - (playerData.dailyRewardRequiredTime or 0)) <= 0 then
                    RewardService:claimDailyReward(); task.wait(1)
                end
            end)

            createClaimToggle("Prestige", "Auto Prestige", function()
                local PrestigeService = Knit.GetService("PrestigeService")
                local Prestiges = require(ReplicatedStorage.Shared.List.Prestige.Prestiges)
                DataController:waitForData()
                local playerData = DataController:getData()
                
                if playerData then
                    local currentPrestige = playerData.prestige
                    local currentPrestigeXP = playerData.prestigeXp
                    local nextPrestige = Prestiges[currentPrestige + 1]
                    
                    if nextPrestige and currentPrestigeXP >= nextPrestige.required then
                        PrestigeService:claim()
                        task.wait(1)
                    end
                end
            end)

            local IndexService = Knit.GetService("IndexService")
            local PetController = Knit.GetController("PetController")

            local IndexRewards = require(ReplicatedStorage.Shared.List.IndexRewards)

            ClaimSection:Toggle("AutoClaimIndexRewards", {
                Title = "Auto Claim Index Rewards",
                Default = false,
                Callback = function(enabled)
                    autoClaimIndexRewardsEnabled = enabled
                    if enabled then
                        task.spawn(function()
                            DataController:waitForData()
                            while autoClaimIndexRewardsEnabled do
                                local playerData = DataController:getData()
                                if playerData then
                                    local claimed = playerData.claimedIndexRewards or {}
                                    local existTable = PetController:getExistTable()
                                    local indexedCount = Util.indexUtils.countIndex(playerData, existTable)

                                    for rewardId, rewardData in pairs(IndexRewards) do
                                        local required = rewardData.required or 0
                                        local alreadyClaimed = table.find(claimed, rewardId)


                                        if indexedCount >= required and not alreadyClaimed then
                                            -- Claim reward every second until successful
                                            task.spawn(function()
                                                while autoClaimIndexRewardsEnabled and not table.find((DataController:getData().claimedIndexRewards or {}), rewardId) do
                                                    local success, err = pcall(function()
                                                        IndexService:claimIndexReward(rewardId)
                                                    end)
                                                    if success then
                                                    else
                                                    end
                                                    task.wait(1)
                                                end
                                            end)
                                        end
                                    end
                                else
                                end
                                task.wait(5)
                            end
                        end)
                    else
                    end
                end
            })


            local isAutoClaimAllChestsEnabled = false

            local AutoClaimAllChests = ClaimSection:Toggle("AutoClaimAllChests", { 
                Title = "Auto Claim All Chests", 
                Default = false,
                Callback = function(enabled)
                    isAutoClaimAllChestsEnabled = enabled
                end
            })

            task.spawn(function()
                DataController:waitForData()
                local Chests = require(ReplicatedStorage.Shared.List.Chests)

                while true do
                    if isAutoClaimAllChestsEnabled then
                        pcall(function()
                            for chestId, chestData in pairs(Chests) do
                                RewardService:claimChest(chestId)
                                task.wait(0.2)
                            end
                        end)
                    end
                    task.wait(10)
                end
            end)
            
            supplyDropThread = nil
            ClaimSection:Toggle("OpenSupplyDrops", { Title = "Open Supply Drops", Default = false,
                Callback = function(enabled)
                    if supplyDropThread then task.cancel(supplyDropThread); supplyDropThread = nil end
                    if enabled then
                        supplyDropThread = task.spawn(function()
                            while enabled do
                                local debris = Workspace:FindFirstChild("Debris")
                                if debris then
                                    for _, dropEvent in ipairs(debris:GetChildren()) do
                                        if dropEvent.Name:find("SupplyDropEvent") then
                                            for _, obj in ipairs(dropEvent:GetChildren()) do
                                                local prompt = obj:FindFirstChild("ProximityPrompt"); if prompt then pcall(fireproximityprompt, prompt) end
                                            end
                                        end
                                    end
                                end
                                task.wait(1)
                            end
                        end)
                    end
                end
            })

            local TutorialSection = Tabs.MineFish:AddSection("Tutorial")

            TutorialSection:AddButton({
                Title = "Complete Tutorial",
                Callback = function()
                    local success, err = pcall(function()
                        local TutorialList = require(ReplicatedStorage.Shared.List.Tutorial)
                        local function forceCompleteCheck()
                            return true
                        end

                        local hookedCount = 0
                        for i, stageData in ipairs(TutorialList) do
                            if type(stageData) == "table" and type(stageData.stageIsCompleted) == "function" then
                                stageData.stageIsCompleted = forceCompleteCheck
                                hookedCount = hookedCount + 1
                            end
                        end
                    end)
                end
            })

            AncientWheel = Tabs.MineFish:AddSection("Ancient Wheel")
            isAutoSpinEnabled = false
            AncientWheel:Toggle("AutoSpin", { Title = "Auto Spin Ancient Wheel", Default = false,
                Callback = function(enabled)
                    isAutoSpinEnabled = enabled
                    task.spawn(function()
                        while isAutoSpinEnabled do
                            pcall(function() RewardService:ancientWheelSpin() end)
                            task.wait(0.01)
                        end
                    end)
                end
            })

            
            ClanWheel = Tabs.MineFish:AddSection("Clan Wheel")
            isAutoSpinEnabled1 = false
            ClanWheel:Toggle("AutoSpin1", { Title = "Auto Spin Clan Wheel", Default = false,
                Callback = function(enabled)
                    isAutoSpinEnabled1 = enabled
                    task.spawn(function()
                        while isAutoSpinEnabled1 do
                            pcall(function() ClanService:clanWheelSpin() end)
                            task.wait(60)
                        end
                    end)
                end
            })

            BoostWheel = Tabs.MineFish:AddSection("Boost Wheel")
            isAutoSpinEnabled12 = false
            BoostWheel:Toggle("AutoSpin12", { Title = "Auto Spin Boost Wheel", Default = false,
                Callback = function(enabled)
                    isAutoSpinEnabled12 = enabled
                    task.spawn(function()
                        while isAutoSpinEnabled12 do
                            pcall(function() RewardService:boostWheelSpin() end)
                            task.wait(60)
                        end
                    end)
                end
            })

            AdminWheelSection = Tabs.MineFish:AddSection("Admin Wheel")

            isAutoAdminWheelSpinEnabled = false
            AdminWheelSection:Toggle("AutoAdminWheelSpin", {
                Title = "Auto Spin Admin Wheel",
                Default = false,
                Callback = function(enabled)
                    isAutoAdminWheelSpinEnabled = enabled
                    task.spawn(function()
                        while isAutoAdminWheelSpinEnabled do
                            pcall(function() Knit.GetService("AdminAbuseService"):adminWheelSpin() end)
                            task.wait(5)
                        end
                    end)
                end
            })
            
            AncientMerchantSection = Tabs.MineFish:AddSection("Ancient Merchant")

            getAllAncientMerchantItems = function()
                local options, itemMap = {}, {}
                pcall(function()
                    local AncientMerchant = require(ReplicatedStorage.Shared.List.AncientMerchant)
                    for i, offer in ipairs(AncientMerchant) do
                        local name, amount, price = offer.item.nm or "Unknown Item", offer.item.am or 1, offer.price or 0
                        local displayName = string.format("%s - %d Ancient Tickets", (amount > 1 and (amount .. "x " .. name)) or name, price)
                        table.insert(options, displayName)
                        itemMap[displayName] = {name = name, amount = amount, price = price}
                    end
                end)
                return options, itemMap
            end

            local merchantOptions, merchantItemMap = getAllAncientMerchantItems()
            local selectedMerchantItems = {}

            AncientMerchantSection:Dropdown("SelectItems", {Title = "Select Items", Values = merchantOptions, Multi = true, Searchable = true, Default = {}, Callback = function(value) selectedMerchantItems = value end})

            isAutoBuyEnabled = false
            AncientMerchantSection:Toggle("AutoBuy", {Title = "Auto Buy", Description = "Automatically buys selected items when they appear in the merchant", Default = false, Callback = function(enabled)
                isAutoBuyEnabled = enabled
                if enabled then
                    task.spawn(function()
                        while isAutoBuyEnabled do
                            if next(selectedMerchantItems) then
                                pcall(function()
                                    local AncientMerchantList = require(ReplicatedStorage.Shared.List.AncientMerchant)
                                    DataController:waitForData()
                                    local data, boughtData, serverTimeNow = DataController:getData(), (DataController:getData()).ancientMerchantBought or {}, Knit.serverTimeNow or os.time()
                                    for slot = 1, Values.ancientMerchantSlots(LocalPlayer, data) do
                                        local ts = DateTime.fromUnixTimestamp(serverTimeNow + 3600):ToUniversalTime()
                                        local seed = ts.Year * 222 + ts.Month * 333 + ts.Day * 444444 + ts.Hour * 33333 + LocalPlayer.UserId + slot
                                        local itemData = AncientMerchantList[Functions.getRandom(AncientMerchantList, seed)]
                                        if itemData then
                                            local merchantItem = itemData.item
                                            local merchantName = merchantItem.nm or "Unknown"
                                            local merchantAmount = merchantItem.am or 1
                                            
                                            for displayName, isSelected in pairs(selectedMerchantItems) do
                                                if isSelected and merchantItemMap[displayName] then
                                                    local selectedItem = merchantItemMap[displayName]
                                                    if merchantName == selectedItem.name and merchantAmount == selectedItem.amount then
                                                        local key = string.format("%*", seed)
                                                        if not boughtData[key] then
                                                            local ancientTickets = 0
                                                            if data.inventory and data.inventory.exclusive then 
                                                                for itemId, item in pairs(data.inventory.exclusive) do 
                                                                    if item.nm == "ancientTicket" then 
                                                                        ancientTickets = item.am or 0
                                                                        break 
                                                                    end 
                                                                end 
                                                            end
                                                            if ancientTickets >= selectedItem.price then 
                                                                RewardService:buyAncientMerchant(slot)
                                                                task.wait(2) 
                                                            end
                                                        end
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end)
                            end
                            task.wait(5)
                        end
                    end)
                end
            end})

            local SeedsList = require(game:GetService("ReplicatedStorage").Shared.List.Skylands.Seeds)
            local seedTypes = {}
            for seedType, seeds in pairs(SeedsList) do
                table.insert(seedTypes, seedType)
            end

            local selectedSeedTypes = {} -- Store selected seed types
            local autoPlantClaimEnabled = false
            local autoPlantClaimThread = nil

            local function getSeedTypeAmount(selectedSeedType)
                DataController:waitForData()
                local data = DataController:getData()
                local mapItems = data.inventory and data.inventory.mapItem or {}
                
                -- Count total amount for this seed type
                local total = 0
                for _, item in pairs(mapItems) do
                    if item.nm == selectedSeedType then
                        total = total + (item.am or 0)
                    end
                end
                return total
            end
                
            local GardenSection = Tabs.MineFish:AddSection("Garden")

            GardenSection:Dropdown("SelectSeedTypes", {
                Title = "Select Seed Type(s)",
                Values = seedTypes,
                Multi = true,
                Default = {},
                Callback = function(selected)
                    selectedSeedTypes = {}
                    for seedType, isSelected in pairs(selected) do
                        if isSelected then
                            selectedSeedTypes[seedType] = true
                            local total = getSeedTypeAmount(seedType)
                        end
                    end
                end
            })

            GardenSection:Toggle("AutoPlantClaim", {
                Title = "Auto Plant/Claim",
                Default = false,
                Callback = function(enabled)
                    autoPlantClaimEnabled = enabled

                    if autoPlantClaimThread then
                        task.cancel(autoPlantClaimThread)
                        autoPlantClaimThread = nil
                    end

                    if enabled then
                        autoPlantClaimThread = task.spawn(function()
                            Knit.OnStart():await()

                            local GardenService = Knit.GetService("GardenService")
                            local PlantsList = require(ReplicatedStorage.Shared.List.Skylands.Plants)
                            local MapsList = require(ReplicatedStorage.Shared.List.Maps)
                            
                            local startCFrame = nil

                            local function barebonesTeleport(targetCFrame)
                                local hrp = Functions.getHRP(LocalPlayer)
                                if not hrp then return end
                                LocalPlayer:RequestStreamAroundAsync(targetCFrame.p, 5)
                                task.wait(0.2)
                                hrp:PivotTo(targetCFrame)
                            end

                            while autoPlantClaimEnabled do
                                local serverTimeNow = require(ReplicatedStorage.Packages.Knit).serverTimeNow
                                local readyPlots = {}
                                local unoccupiedPlots = {}
                                
                                pcall(function()
                                    local gardenData = DataController:getData().gardenPlants
                                    if not gardenData then return end
                                    for i = 1, 5 do
                                        local plantData = gardenData[tostring(i)]
                                        if plantData and plantData.plantName then
                                            local info = PlantsList[plantData.plantName]
                                            if info and (plantData.plantedAt + info.duration) - serverTimeNow <= 0 then
                                                table.insert(readyPlots, { plotId = i, plantName = info.name })
                                            end
                                        else
                                            table.insert(unoccupiedPlots, i)
                                        end
                                    end
                                end)
                                
                                if #readyPlots > 0 then
                                    if not startCFrame then startCFrame = Functions.getHRP(LocalPlayer):GetPivot() end
                                    
                                    local gardenCFrame = MapsList[31] and MapsList[31].cframe
                                    if gardenCFrame then
                                        barebonesTeleport(gardenCFrame)
                                        
                                        local readyPlotsSet = {}
                                        for _, data in ipairs(readyPlots) do readyPlotsSet[data.plotId] = true end
                                        
                                        -- Patiently wait for all models to load
                                        local waitStartTime = tick()
                                        repeat task.wait(0.2)
                                            local foundCount = 0
                                            for _, model in pairs(CollectionService:GetTagged("gardenPlant")) do
                                                if model:GetAttribute("gardenId") and readyPlotsSet[model:GetAttribute("gardenId")] then
                                                    foundCount = foundCount + 1
                                                end
                                            end
                                        until foundCount >= #readyPlots or tick() - waitStartTime > 5
                                        local promptsFired = 0
                                        local claimStartTime = tick()
                                        repeat
                                            for _, model in pairs(CollectionService:GetTagged("gardenPlant")) do
                                                local gardenId = model:GetAttribute("gardenId")
                                                if gardenId and readyPlotsSet[gardenId] then
                                                    local prompt = model:FindFirstChildOfClass("ProximityPrompt")
                                                    if prompt and prompt.Enabled then
                                                        fireproximityprompt(prompt)
                                                        promptsFired = promptsFired + 1
                                                        readyPlotsSet[gardenId] = nil 
                                                        task.wait(0.5)
                                                    end
                                                end
                                            end
                                            task.wait(0.1)
                                        until promptsFired >= #readyPlots or tick() - claimStartTime > 10

                                        task.wait(3)
                                        barebonesTeleport(startCFrame)
                                        startCFrame = nil
                                    end
                                    
                                elseif #unoccupiedPlots > 0 and next(selectedSeedTypes or {}) then
                                    for _, slotId in ipairs(unoccupiedPlots) do
                                        for seedName, isSelected in pairs(selectedSeedTypes) do
                                            if isSelected and getSeedTypeAmount(seedName) > 0 then
                                                GardenService:plantSeed(seedName, slotId)
                                                task.wait(0.3)
                                                break
                                            end
                                        end
                                    end
                                end

                                task.wait(5)
                            end
                        end)
                    end
                end
            })
            
            local BoxesSection = Tabs.MineFish:AddSection("Boxes")

            local Boxes = require(game:GetService("ReplicatedStorage").Shared.List.Items.Boxes)
            local boxNames = {} 
            local boxNameToId = {} 
            local idToBoxName = {}
            local selectedBoxes = {} 

            for key, value in pairs(Boxes) do
                if value.name then
                    table.insert(boxNames, value.name)
                    boxNameToId[value.name] = key
                    idToBoxName[key] = value.name
                end
            end

            local BoxDropdown = BoxesSection:Dropdown("SelectBox", {
                Title = "Select Box",
                Values = boxNames,
                Default = {},
                Multi = true,
                Searchable = true,
                Callback = function(selected)
                    selectedBoxes = {}
                    for displayName, isSelected in pairs(selected) do
                        if isSelected then
                            local id = boxNameToId[displayName]
                            if id then
                                selectedBoxes[id] = true 
                            end
                        end
                    end
                end
            })

            BoxesSection:Button({
                Title = "Select All Boxes",
                Callback = function()
                    local allSelected = {}
                    for _, name in ipairs(boxNames) do
                        local id = boxNameToId[name]
                        if id then
                            allSelected[id] = true
                        end
                    end
                    -- Set dropdown values using display names
                    local allDisplayNames = {}
                    for _, name in ipairs(boxNames) do
                        allDisplayNames[name] = true
                    end
                    BoxDropdown:SetValue(allDisplayNames)
                    selectedBoxes = allSelected
                    for id, _ in pairs(selectedBoxes) do
                    end
                end
            })


            BoxesSection:Toggle("AutoUseSelectedBoxes", {
                Title = "Auto Use (All)",
                Default = false,
                Callback = function(Value)
                    AutoUseBox = Value
                    AutoUseSelectedBoxesEnabled = Value

                    -- Stop previous thread if it exists
                    if AutoUseSelectedBoxesThread and coroutine.status(AutoUseSelectedBoxesThread) == "running" then
                        AutoUseSelectedBoxesEnabled = false
                        task.wait(0.1) 
                    end

                    if Value then
                        local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit.KnitClient)
                        local InventoryService = Knit.GetService("InventoryService")
                        
                        AutoUseSelectedBoxesEnabled = true
                        AutoUseSelectedBoxesThread = task.spawn(function()
                            while AutoUseSelectedBoxesEnabled do
                                DataController:waitForData()
                                local playerData = DataController:getData()
                                if playerData and playerData.inventory and playerData.inventory.box then
                                    local inventory = playerData.inventory.box
                                    for boxId, isSelected in pairs(selectedBoxes) do
                                        if isSelected then
                                            for itemId, itemData in pairs(inventory) do
                                                if itemData.nm == boxId or itemId == boxId then
                                                    local owned = itemData.am or 0
                                                    if owned > 0 then
                                                        pcall(function()
                                                            InventoryService:useItem(itemId, {use = owned})
                                                        end)
                                                        task.wait(0.5) 
                                                    end
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                task.wait(3) 
                            end
                        end)
                    end
                end
            })

            

            
            local UseItemsSection = Tabs.MineFish:AddSection("Use Items")

            local autoUseThreads = {}

            local function createItemUsageUI(parentSection, moduleName)
                -- Configuration map
                local config = {
                    Potions = { invKey = "potion", displayName = "Potions" },
                    Fruits = { invKey = "fruit", displayName = "Fruits" },
                    Smoothies = { invKey = "smoothie", displayName = "Smoothies" },
                    ActiveEvents = { invKey = "activeEvent", displayName = "Stars" }
                }
                
                local moduleConfig = config[moduleName]
                if not moduleConfig then return end

                local itemsFolder = ReplicatedStorage:FindFirstChild("Shared", true):FindFirstChild("List", true):FindFirstChild("Items", true)
                if not itemsFolder then return end

                local itemModule = itemsFolder:FindFirstChild(moduleName)
                if not itemModule then return end

                local success, rawItemData = pcall(require, itemModule)
                if not success or type(rawItemData) ~= "table" then
                    warn("Could not load or parse item module:", moduleName)
                    return
                end

                -- Create comprehensive lookup tables
                local itemNames, idToData = {}, {}
                for id, data in pairs(rawItemData) do
                    if data and data.name then
                        table.insert(itemNames, data.name)
                        idToData[id] = data
                    end
                end
                table.sort(itemNames)

                local dropdown = parentSection:Dropdown("AutoUseDropdown_" .. moduleName, {
                    Title = "Select " .. moduleConfig.displayName,
                    Values = itemNames,
                    Multi = true, Searchable = true, Default = {}
                })

                parentSection:Toggle("AutoUseToggle_" .. moduleName, {
                    Title = "Auto Use " .. moduleConfig.displayName,
                    Description = "Automatically uses the next selected item from the list above once the current one's effect expires.",
                    Default = false,
                    Callback = function(enabled)
                        local thread = autoUseThreads[moduleName]

                        if not enabled and thread then
                            task.cancel(thread)
                            autoUseThreads[moduleName] = nil
                            return
                        end

                        if enabled and not thread then                    
                            local function checkAndUseItems()
                                local success, err = pcall(function()
                                    local playerData = DataController:getData()
                                    if not (playerData and playerData.inventory and playerData.inventory[moduleConfig.invKey] and playerData.activeBoosts) then return end

                                    local selectedItemNames = dropdown.Value or {}
                                    if not next(selectedItemNames) then return end

                                    -- == GATHER PHASE: Find all inactive items we need to use ==
                                    local itemsToUse = {}
                                    for itemName, isSelected in pairs(selectedItemNames) do
                                        if isSelected then
                                            local internalId = nil
                                            for id, data in pairs(idToData) do
                                                if data.name == itemName then
                                                    internalId = id
                                                    break
                                                end
                                            end

                                            if internalId then
                                                local isActive = playerData.activeBoosts[internalId] and tonumber(playerData.activeBoosts[internalId]) > 0
                                                
                                                if not isActive then
                                                    -- This item is inactive and selected. Find it in inventory.
                                                    for invId, itemData in pairs(playerData.inventory[moduleConfig.invKey]) do
                                                        if itemData.nm == internalId and (itemData.am or 0) > 0 then
                                                            table.insert(itemsToUse, { name = itemName, invId = invId })
                                                            break -- Found it, move to the next selected item
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end

                                    if #itemsToUse > 0 then
                                        for _, itemInfo in ipairs(itemsToUse) do
                                            InventoryService:useItem(itemInfo.invId, "1")
                                            task.wait(0.2) -- Delay between each firing
                                        end
                                    else
                                    end
                                end)
                                if not success then warn("ERROR in Auto-Use check for "..moduleConfig.displayName..": "..tostring(err)) end
                            end

                            -- INSTANT CHECK when toggled on
                            checkAndUseItems()

                            -- Start the main loop
                            autoUseThreads[moduleName] = task.spawn(function()
                                while task.wait(5) do
                                    checkAndUseItems()
                                end
                                autoUseThreads[moduleName] = nil
                            end)
                        end
                    end
                })
            end

            createItemUsageUI(UseItemsSection, "Potions")
            createItemUsageUI(UseItemsSection, "Fruits")
            createItemUsageUI(UseItemsSection, "Smoothies")
            createItemUsageUI(UseItemsSection, "ActiveEvents")

            local TotemsSection = Tabs.MineFish:AddSection("Auto Use Totems")

            local mapNames, mapNameToId = {}, {}
            pcall(function()
                local MapsModule = require(ReplicatedStorage.Shared.List.Maps)
                local mapsList = {}
                for id, data in pairs(MapsModule) do table.insert(mapsList, {id = tonumber(id), name = data.name}) end
                table.sort(mapsList, function(a, b) return a.id < b.id end)
                for _, mapInfo in ipairs(mapsList) do
                    table.insert(mapNames, mapInfo.name)
                    mapNameToId[mapInfo.name] = mapInfo.id
                end
            end)

            -- Get all totems for the dropdown
            local totemNames, totemNameToId = {}, {}
            pcall(function()
                local TotemsModule = require(ReplicatedStorage.Shared.List.Items.Totems)
                for id, data in pairs(TotemsModule) do
                    table.insert(totemNames, data.name)
                    totemNameToId[data.name] = id
                end
                table.sort(totemNames)
            end)

            local selectedMapId = 1 
            local selectedTotemId = totemNameToId[totemNames[1]] 
            local autoUseTotemThread = nil

            TotemsSection:Dropdown("SelectMapForTotem", {
                Title = "Select Map",
                Values = mapNames,
                Default = mapNames[1] or "Spawn",
                Searchable = true,
                Multi = false,
                Callback = function(mapName)
                    selectedMapId = mapNameToId[mapName]
                end
            })

            TotemsSection:Dropdown("SelectTotemToUse", {
                Title = "Select Totem",
                Values = totemNames,
                Default = totemNames[1],
                Searchable = true,
                Multi = false,
                Callback = function(totemName)
                    selectedTotemId = totemNameToId[totemName]
                end
            })

            TotemsSection:Toggle("AutoUseTotem", {
                Title = "Auto Use",
                Description = "Automatically places the selected totem in the selected map if one isn't already active there. It might visually be spawned on you, but the effect will apply to the selected map.",
                Default = false,
                Callback = function(enabled)
                    if not enabled and autoUseTotemThread then
                        task.cancel(autoUseTotemThread)
                        autoUseTotemThread = nil
                        return
                    end

                    if enabled and not autoUseTotemThread then
                        
                        local function checkAndUseTotem()
                            pcall(function()
                                local playerData = DataController:getData()
                                local TotemController = Knit.GetController("TotemController")
                                
                                -- Check if a totem is already active in the selected map
                                local isTotemActiveInMap = false
                                for _, totemData in pairs(TotemController:getCurrentTotems()) do
                                    if totemData.mapId == selectedMapId then
                                        isTotemActiveInMap = true
                                        break
                                    end
                                end
                                
                                if isTotemActiveInMap then
                                    return
                                end
                                
                                -- Find the selected totem's UUID in the player's inventory
                                local totemUUID = nil
                                local hasTotem = false
                                for uuid, itemData in pairs(playerData.inventory.totem or {}) do
                                    if itemData.nm == selectedTotemId then
                                        if (itemData.am or 0) > 0 then
                                            totemUUID = uuid
                                            hasTotem = true
                                        end
                                        break
                                    end
                                end

                                if hasTotem then
                                    InventoryService:useItem(totemUUID, {mapId = selectedMapId})
                                end
                            end)
                        end

                        -- Instant check when toggled on
                        checkAndUseTotem()

                        -- Start the main loop
                        autoUseTotemThread = task.spawn(function()
                            while task.wait(5) do
                                checkAndUseTotem()
                            end
                            autoUseTotemThread = nil
                        end)
                    end
                end
            })



            PassSection = Tabs.Claim:AddSection("Season Pass")

            PassSection:Toggle("AutoClaimAndReset", { 
                Title = "Auto Claim and Reset Season Pass", 
                Description = "Automatically claims rewards and resets pass:\n• Premium: Reset after claiming tiers 1-12 (both tracks)\n• Free: Reset after claiming tiers 1-12 (free track only)", 
                Default = false, 
                Callback = function(Value) 
                    _G.AutoClaimAndResetToggle = Value
                end 
            })

            task.spawn(function()
                while task.wait(5) do
                    if not _G.AutoClaimAndResetToggle then continue end
                    
                    pcall(function()
                        local playerData = DataController:getData()
                        
                        if not playerData then 
                            return 
                        end
                        
                        local seasonNum = seasonVariables.season
                        local currentPassLevel = seasonUtils.seasonUtils.getPassLevel(playerData)
                        local hasPremiumPass = playerData[("season%dPassPremium"):format(seasonNum)]
                        local claimedTiersData = playerData[("season%dPassClaimed"):format(seasonNum)]
                        local totalTiers = #seasonTiersList
                        
                        
                        local claimedFree, claimedPremium = {}, {}
                        for rewardKey, _ in pairs(claimedTiersData) do
                            local track = tonumber(rewardKey:sub(1, 1))
                            local tier = tonumber(rewardKey:sub(2))
                            if track == 1 then
                                table.insert(claimedFree, tier)
                            elseif track == 2 then
                                table.insert(claimedPremium, tier)
                            end
                        end
                        table.sort(claimedFree)
                        table.sort(claimedPremium)
                        
                        if #claimedFree > 0 then
                        else
                        end
                        
                        if #claimedPremium > 0 then
                        else
                        end
                        
                        local claimedThisCycle = 0
                        for tier = 1, currentPassLevel do
                            for track = 1, 2 do
                                -- Skip premium track if no premium pass
                                if track == 2 and not hasPremiumPass then continue end
                                
                                local rewardKey = ("%d%d"):format(track, tier)
                                if not claimedTiersData[rewardKey] then
                                    local trackName = track == 1 and "Free" or "Premium"
                                    
                                    local success, err = pcall(function()
                                        SeasonService:claimTier(tier, track)
                                    end)
                                    
                                    if success then
                                        claimedThisCycle = claimedThisCycle + 1
                                    else
                                    end
                                    
                                    task.wait(0.5)
                                end
                            end
                        end
                        
                        if claimedThisCycle > 0 then
                        else
                        end
                        
                        -- Check if we should reset
                        local shouldReset = false
                        local resetReason = ""
                        
                        if hasPremiumPass then
                            -- Premium: Check if tiers 1-12 are claimed on BOTH tracks
                            local premiumTiersComplete = true
                            for tier = 1, 14 do
                                if tier > currentPassLevel then
                                    premiumTiersComplete = false
                                    resetReason = string.format("Not enough level (at %d/12)", currentPassLevel)
                                    break
                                end
                                
                                for track = 1, 2 do
                                    local rewardKey = ("%d%d"):format(track, tier)
                                    if not claimedTiersData[rewardKey] then
                                        premiumTiersComplete = false
                                        resetReason = string.format("Tier %d %s not claimed (key: %s)", 
                                            tier, track == 1 and "Free" or "Premium", rewardKey)
                                        break
                                    end
                                end
                                
                                if not premiumTiersComplete then break end
                            end
                            shouldReset = premiumTiersComplete
                            if shouldReset then
                                resetReason = "All tiers 1-12 claimed (Premium + Free tracks)"
                            end
                        else
                            local freeTiersComplete = true
                            for tier = 1, 14 do
                                if tier > currentPassLevel then
                                    freeTiersComplete = false
                                    resetReason = string.format("Not enough level (at %d/12)", currentPassLevel)
                                    break
                                end
                                
                                local rewardKey = ("%d%d"):format(1, tier) -- Track 1 = Free
                                if not claimedTiersData[rewardKey] then
                                    freeTiersComplete = false
                                    resetReason = string.format("Tier %d Free not claimed (key: %s)", tier, rewardKey)
                                    break
                                end
                            end
                            shouldReset = freeTiersComplete
                            if shouldReset then
                                resetReason = "All tiers 1-12 claimed (Free track only)"
                            end
                        end
                        
                        
                        if shouldReset then
                            local success, err = pcall(function()
                                SeasonService:resetPass()
                            end)
                            
                            if success then
                            else
                            end
                            task.wait(1)
                        end
                    end)
                end
            end)

            Aura = Tabs.MineFish:AddSection("Aura")
            local AuraDices = require(ReplicatedStorage.Shared.List.Items.AuraDices)
            selectedDiceItems, autoRollThread = {}, nil
            local diceNames, diceOptions = {}, {}
            do local names = {} for name, info in pairs(AuraDices) do table.insert(names, info.name); diceOptions[info.name]=name end table.sort(names); diceNames=names end

            updateDiceStatus = function()
                local statusLines, hasSelected = {}, false
                pcall(function()
                    DataController:waitForData()
                    local playerData = DataController:getData()
                    for diceName, isSelected in pairs(selectedDiceItems) do
                        if isSelected then
                            hasSelected = true
                            local item = Util.itemUtils.getItemFromName(playerData, diceOptions[diceName])
                            table.insert(statusLines, string.format("%s (%dx)", diceName, (item and item:getAmount() or 0)))
                        end
                    end
                end)
                return not hasSelected and "No dice selected" or table.concat(statusLines, "\n")
            end

            local AuraDiceDropdown = Aura:Dropdown("SelectAuraDice", { Title = "Select Aura Dice", Values = diceNames, Multi = true, Searchable = true, Default = {} })
            local SelectedDiceParagraph = Aura:Paragraph("SelectedDiceDisplay", { Title = "Selected Dice", Content = "No dice selected" })
            AuraDiceDropdown:OnChanged(function(value) selectedDiceItems = value end)

            Aura:Toggle("AutoRoll", { Title = "Auto Roll", Default = false,
                Callback = function(enabled)
                    if autoRollThread then task.cancel(autoRollThread); autoRollThread = nil end
                    if enabled then
                        autoRollThread = task.spawn(function()
                            while enabled do
                                local availableDice = {}
                                pcall(function()
                                    DataController:waitForData(); local playerData = DataController:getData()
                                    for diceName, isSelected in pairs(selectedDiceItems) do
                                        if isSelected then local item=Util.itemUtils.getItemFromName(playerData, diceOptions[diceName]); if item and item:getAmount()>0 then table.insert(availableDice, diceOptions[diceName]) end end
                                    end
                                end)
                                if #availableDice > 0 then pcall(function() AuraService:roll(availableDice[math.random(1,#availableDice)]) end) end
                                task.wait(1)
                            end
                        end)
                    end
                end
            })

            task.spawn(function() while true do SelectedDiceParagraph:SetValue(updateDiceStatus()); task.wait(1) end end)

            do -- Scoped block for Craft Dice to avoid local register overflow
            local CraftDiceSection = Tabs.MineFish:AddSection("Craft Dice")

            -- Get all aura dice crafting recipes
            local AuraDiceCrafting = require(ReplicatedStorage.Shared.List.AuraDiceCrafting)
            local diceCraftOptions, diceCraftMap = {}, {}

            for i, recipe in ipairs(AuraDiceCrafting) do
                local requiredName = recipe.item:getName()
                local rewardName = recipe.reward:getName()
                local displayName = requiredName .. " → " .. rewardName
                table.insert(diceCraftOptions, displayName)
                diceCraftMap[displayName] = {
                    recipeIndex = i,
                    requiredName = requiredName,
                    rewardName = rewardName,
                    requiredAmount = recipe.item:getAmount(),
                    rewardId = rewardName
                }
            end

            local selectedDiceCrafts = {}

            local DiceCraftDropdown = CraftDiceSection:Dropdown("SelectDiceCrafts", {
                Title = "Select Dice to Craft",
                Description = "Choose which aura dice to craft",
                Values = diceCraftOptions,
                Multi = true,
                Searchable = true,
                Default = {},
                Callback = function(value)
                    selectedDiceCrafts = value
                end
            })

            local isAutoCraftDiceEnabled = false

            CraftDiceSection:Toggle("CraftAllDice", {
                Title = "Craft All (Selected)",
                Description = "Automatically crafts all selected aura dice as much as possible",
                Default = false,
                Callback = function(enabled)
                    isAutoCraftDiceEnabled = enabled
                    if enabled then
                        task.spawn(function()
                            while isAutoCraftDiceEnabled do
                                pcall(function()
                                    DataController:waitForData()
                                    local playerData = DataController:getData()
                                    for displayName, isSelected in pairs(selectedDiceCrafts) do
                                        if isSelected and diceCraftMap[displayName] then
                                            local craftInfo = diceCraftMap[displayName]
                                            local requiredItem = AuraDiceCrafting[craftInfo.recipeIndex].item
                                            local rewardItem = AuraDiceCrafting[craftInfo.recipeIndex].reward
                                            local requiredName = craftInfo.requiredName
                                            local requiredAmount = craftInfo.requiredAmount
                                            local rewardId = craftInfo.recipeIndex

                                            local playerItem = Util.itemUtils.getItemFromName(playerData, requiredName)
                                            local playerAmount = playerItem and playerItem:getAmount() or 0
                                            local maxCraftable = math.floor(playerAmount / requiredAmount)

                                            if maxCraftable > 0 then
                                                local Knit = require(ReplicatedStorage.Packages.Knit)
                                                local AuraService = Knit.GetService("AuraService")
                                                AuraService:craftDice(rewardId, maxCraftable)
                                                task.wait(1)
                                            end
                                        end
                                    end
                                end)
                                task.wait(5)
                            end
                        end)
                    end
                end
            })
            end -- End of Craft Dice scoped block
            
            local PetArchiverSection = Tabs.MineFish:AddSection("Pet Archiver")

            local petsToKeepInput = PetArchiverSection:AddInput("PetsToKeepInput", {
                Title = "Number of best Pets to KEEP",
                Default = "20",
                Numeric = true,
                Description = "Keeps your strongest pets."
            })

            local keepSpecialToggle = PetArchiverSection:AddToggle("KeepSpecialPetsToggle", {
                Title = "Keep Event Pets",
                Description = "Keep pets with an event boost.",
                Default = true
            })

            PetArchiverSection:AddButton({
                Title = "Archive Unwanted Pets",
                Description = "This will never archive a pet which has a % bonus. This will archive all pets, other then equipped pets, your strongest pets, and event pets (if selected).",
                Callback = function()
                    local numToKeep = tonumber(petsToKeepInput.Value) or 20
                    local shouldKeepPercentBonus = keepSpecialToggle.Value
                    
                    local playerData = DataController:getData()
                    local PetDefinitions = require(ReplicatedStorage.Shared.List.Pets.Pets)
                    
                    if not playerData or not playerData.inventory or not playerData.inventory.pet then
                        warn("Pet Archiver: Could not load pet inventory data.")
                        return
                    end

                    local allPetsMasterList = {}
                    pcall(function()
                        for petId, petRawData in pairs(playerData.inventory.pet) do
                            local petObject = Util.itemUtils.createItemFromData(petRawData)
                            if petObject then
                                table.insert(allPetsMasterList, {
                                    id = petId,
                                    name = petObject:getName(),
                                    multiplier = petObject:getMultiplier()
                                })
                            end
                        end
                    end)
                    table.sort(allPetsMasterList, function(a, b) return a.multiplier > b.multiplier end)

                    local petsToKeepIds = {}

                    -- Rule 1: Keep Top N pets
                    for i = 1, math.min(numToKeep, #allPetsMasterList) do
                        petsToKeepIds[allPetsMasterList[i].id] = true
                    end

                    -- Rule 2: Keep ALL equipped pets
                    if playerData.equippedPets then
                        for petId, _ in pairs(playerData.equippedPets) do
                            petsToKeepIds[petId] = true
                        end
                    end
                    
                    -- Rule 3 & 4: Keep special bonus pets
                    for _, petData in ipairs(allPetsMasterList) do
                        local petDef = PetDefinitions[petData.name]
                        if petDef then
                            -- ALWAYS keep pets with the dynamic 'special' key
                            if petDef.special then
                                petsToKeepIds[petData.id] = true
                            end
                            -- CONDITIONALLY keep pets with the 'specialMultiplier' key
                            if petDef.specialMultiplier and shouldKeepPercentBonus then
                                petsToKeepIds[petData.id] = true
                            end
                        end
                    end

                    local petsToArchiveIds = {}
                    for petId, _ in pairs(playerData.inventory.pet) do
                        if not petsToKeepIds[petId] then
                            petsToArchiveIds[petId] = true
                        end
                    end

                    if next(petsToArchiveIds) then
                        pcall(function()
                            PetService:archivePets(petsToArchiveIds, 1)
                        end)
                    else
                    end
                end
            })

            local PetsSection = Tabs.MineFish:AddSection("Pets")

            local AutoEquipBestPets = false
            local autoEquipThread

            PetsSection:Toggle("AutoEquipBestPets", {
                Title = "Auto Equip Best Pets",
                Default = false,
                Callback = function(enabled)
                    AutoEquipBestPets = enabled

                    -- stop existing thread
                    if autoEquipThread then
                        task.cancel(autoEquipThread)
                        autoEquipThread = nil
                    end

                    -- helper function for clicking Equip Best
                    local function equipBest()
                        pcall(function()
                            local button = player.PlayerGui:FindFirstChild("MainUI", true)
                            if not button then return end

                            button = button:FindFirstChild("EquipBest", true)
                            if not button then return end

                            local click = button:FindFirstChild("Click") or button

                            for _, connection in pairs(getconnections(click.MouseButton1Down)) do
                                connection:Fire()
                            end
                            for _, connection in pairs(getconnections(click.MouseButton1Up)) do
                                connection:Fire()
                            end
                        end)
                    end

                    if enabled then
                        -- RUN ONCE INSTANTLY
                        equipBest()

                        -- START LOOP
                        autoEquipThread = task.spawn(function()
                            while AutoEquipBestPets do
                                equipBest()
                                task.wait(5)
                            end
                        end)
                    end
                end
            })


            EventSection = Tabs.MineFish:AddSection("Events")
            isAutoBreakingMeteors = false
            EventSection:Toggle("AutoBreakMeteors", { Title = "Auto Break Meteors (Infinite Range)", Default = false,
                Callback = function(Value)
                    isAutoBreakingMeteors = Value
                    if Value then
                        task.spawn(function()
                            while isAutoBreakingMeteors do
                                local allMeteors = CollectionService:GetTagged("Meteor")
                                if #allMeteors > 0 then
                                    while #allMeteors > 0 and isAutoBreakingMeteors do
                                        for _, meteor in ipairs(allMeteors) do
                                            pcall(function() local id=meteor:GetAttribute("meteorId"); if id then EventService.damageMeteor:Fire(id) end end)
                                        end
                                        task.wait()
                                        allMeteors = CollectionService:GetTagged("Meteor")
                                    end
                                end
                                task.wait(5)
                            end
                        end)
                    end
                end
            })

            -- ============================================================
            -- PERFORMANCE TAB
            -- ============================================================
            do
            local PerfSection = Tabs.Settings:AddSection("Rendering")

            -- Black Screen with full GUI overlay + F3 keybind + mobile wake button
            local blackScreenGui = nil
            local blackScreenActive = false

            local function toggleBlackScreen(forceState)
                if forceState ~= nil then blackScreenActive = forceState else blackScreenActive = not blackScreenActive end

                if blackScreenActive then
                    if not blackScreenGui then
                        blackScreenGui = Instance.new("ScreenGui")
                        blackScreenGui.Name = "RCU_BlackScreen"
                        blackScreenGui.DisplayOrder = 999999
                        blackScreenGui.IgnoreGuiInset = true
                        blackScreenGui.ResetOnSpawn = false

                        local bg = Instance.new("Frame")
                        bg.Name = "Background"
                        bg.Size = UDim2.new(1, 0, 1, 0)
                        bg.BackgroundColor3 = Color3.new(0, 0, 0)
                        bg.BorderSizePixel = 0
                        bg.Parent = blackScreenGui

                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 0, 30)
                        label.Position = UDim2.new(0, 0, 0, 10)
                        label.BackgroundTransparency = 1
                        label.Text = "RCU Black Screen Active  |  Press F3 or tap Wake Up to exit"
                        label.TextColor3 = Color3.fromRGB(80, 80, 80)
                        label.TextSize = 14
                        label.Font = Enum.Font.Gotham
                        label.Parent = bg

                        local wakeBtn = Instance.new("TextButton")
                        wakeBtn.Name = "WakeUp"
                        wakeBtn.Size = UDim2.new(0, 200, 0, 50)
                        wakeBtn.Position = UDim2.new(0.5, -100, 0.5, -25)
                        wakeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                        wakeBtn.BorderSizePixel = 0
                        wakeBtn.Text = "Wake Up"
                        wakeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
                        wakeBtn.TextSize = 18
                        wakeBtn.Font = Enum.Font.GothamBold
                        wakeBtn.Parent = bg

                        local corner = Instance.new("UICorner")
                        corner.CornerRadius = UDim.new(0, 8)
                        corner.Parent = wakeBtn

                        wakeBtn.MouseButton1Click:Connect(function()
                            toggleBlackScreen(false)
                        end)

                        blackScreenGui.Parent = LocalPlayer.PlayerGui
                    end
                    blackScreenGui.Enabled = true
                else
                    if blackScreenGui then
                        blackScreenGui.Enabled = false
                    end
                end
            end

            -- F3 keybind
            game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.KeyCode == Enum.KeyCode.F3 then
                    toggleBlackScreen()
                end
            end)

            PerfSection:Toggle("BlackScreen", {
                Title = "Black Screen Mode",
                Description = "Covers the entire screen with a black overlay to save GPU. Press F3 or tap the Wake Up button to toggle off.",
                Default = false,
                Callback = function(enabled)
                    toggleBlackScreen(enabled)
                end
            })

            PerfSection:Toggle("DisableParticles", {
                Title = "Disable All Particles",
                Description = "Removes particle emitters, beams, trails, and other visual effects to reduce lag.",
                Default = false,
                Callback = function(enabled)
                    _G.ParticlesDisabled = enabled
                    if enabled then
                        task.spawn(function()
                            local function disableEffects(parent)
                                for _, obj in ipairs(parent:GetDescendants()) do
                                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                                        obj.Enabled = false
                                    end
                                end
                            end
                            disableEffects(Workspace)
                            while _G.ParticlesDisabled do
                                disableEffects(Workspace)
                                task.wait(5)
                            end
                        end)
                    end
                end
            })

            PerfSection:Toggle("LowQualityTerrain", {
                Title = "Low Quality Terrain",
                Description = "Reduces terrain rendering quality. Helps on low-end devices.",
                Default = false,
                Callback = function(enabled)
                    pcall(function()
                        local terrain = Workspace:FindFirstChildOfClass("Terrain")
                        if terrain then
                            terrain.Decoration = not enabled
                            if enabled then
                                terrain.WaterWaveSize = 0
                                terrain.WaterWaveSpeed = 0
                                terrain.WaterTransparency = 1
                            else
                                terrain.WaterWaveSize = 0.15
                                terrain.WaterWaveSpeed = 10
                                terrain.WaterTransparency = 0.3
                            end
                        end
                    end)
                end
            })

            PerfSection:Toggle("DisableTextures", {
                Title = "Remove Textures and Decals",
                Description = "Strips textures and decals from all parts. Makes the game look plain but runs faster.",
                Default = false,
                Callback = function(enabled)
                    _G.TexturesDisabled = enabled
                    if enabled then
                        task.spawn(function()
                            local function removeTextures(parent)
                                for _, obj in ipairs(parent:GetDescendants()) do
                                    if obj:IsA("Texture") or obj:IsA("Decal") then
                                        obj.Transparency = 1
                                    end
                                end
                            end
                            removeTextures(Workspace)
                            while _G.TexturesDisabled do
                                removeTextures(Workspace)
                                task.wait(10)
                            end
                        end)
                    else
                        pcall(function()
                            for _, obj in ipairs(Workspace:GetDescendants()) do
                                if obj:IsA("Texture") or obj:IsA("Decal") then
                                    obj.Transparency = 0
                                end
                            end
                        end)
                    end
                end
            })

            local RenderSection = Tabs.Settings:AddSection("Render Settings")

            RenderSection:Slider("FPSCap", {
                Title = "FPS Cap",
                Description = "Limit your framerate. Lower = less GPU usage. Set to 0 for unlimited.",
                Default = 60,
                Min = 0,
                Max = 240,
                Rounding = 0,
                Callback = function(value)
                    pcall(function()
                        if setfpscap then
                            setfpscap(value == 0 and math.huge or value)
                        end
                    end)
                end
            })

            RenderSection:Slider("RenderDistance", {
                Title = "Render Distance",
                Description = "Controls how far away objects are visible. Lower values improve performance.",
                Default = 2500,
                Min = 100,
                Max = 10000,
                Rounding = 0,
                Callback = function(value)
                    pcall(function()
                        if LocalPlayer then
                            LocalPlayer.ReplicationFocus = nil
                        end
                        game:GetService("Lighting").FogEnd = value
                    end)
                end
            })

            local MemorySection = Tabs.Settings:AddSection("Memory")

            MemorySection:Button({
                Title = "Force Garbage Collection",
                Description = "Manually clears unused memory. The script already does this every 30 seconds automatically.",
                Callback = function()
                    pcall(function() collectgarbage("collect") end)
                    local kb = gcinfo()
                    Library:Notify({Title = "Memory", Content = "Cleaned. Current usage: " .. math.floor(kb / 1024) .. " MB", Duration = 3})
                end
            })

            MemorySection:Toggle("AggressiveGC", {
                Title = "Aggressive Garbage Collection",
                Description = "Runs garbage collection every 10 seconds instead of 30. Uses slightly more CPU but keeps memory lower.",
                Default = false,
                Callback = function(enabled)
                    _G.AggressiveGC = enabled
                    if enabled then
                        task.spawn(function()
                            while _G.AggressiveGC do
                                pcall(function() collectgarbage("collect") end)
                                task.wait(10)
                            end
                        end)
                    end
                end
            })

            local UISection = Tabs.Settings:AddSection("UI Cleanup")

            UISection:Toggle("HideGameUI", {
                Title = "Hide Game UI",
                Description = "Hides the game's built-in UI elements. Useful for AFK farming to reduce GPU overhead.",
                Default = false,
                Callback = function(enabled)
                    pcall(function()
                        local mainUI = LocalPlayer.PlayerGui:FindFirstChild("MainUI")
                        if mainUI then
                            mainUI.Enabled = not enabled
                        end
                    end)
                end
            })

            UISection:Toggle("DisableShadows", {
                Title = "Disable Shadows",
                Description = "Turns off global shadows for a noticeable FPS boost.",
                Default = false,
                Callback = function(enabled)
                    pcall(function()
                        game:GetService("Lighting").GlobalShadows = not enabled
                    end)
                end
            })
            end -- End Performance scope

            -- ============================================================
            -- ============================================================
            -- VISUALS TAB
            -- ============================================================
            do
            local MountSection = Tabs.Visuals:AddSection("Mounts / Hoverboards")
            local MountsList = nil
            local MountController = nil
            pcall(function() MountsList = require(ReplicatedStorage.Shared.List.Items.Mounts) end)
            pcall(function() MountController = Knit.GetController("MountController") end)

            local function getMountNames()
                local list = {"None"}
                if MountsList then
                    for mountId in pairs(MountsList) do table.insert(list, tostring(mountId)) end
                end
                table.sort(list)
                return list
            end

            local selectedMount = "None"

            local mountDropdown = MountSection:Dropdown("SelectMount", {
                Title = "Select Mount",
                Description = "Choose a mount or hoverboard to equip. This is client-side only (visual).",
                Values = getMountNames(),
                Default = "None",
                Multi = false,
                Searchable = true,
                Callback = function(v) selectedMount = v end
            })

            MountSection:Button({
                Title = "Refresh Mount List",
                Callback = function()
                    mountDropdown:SetValues(getMountNames())
                end
            })

            MountSection:Button({
                Title = "Equip Selected Mount",
                Description = "Spawns the selected mount on your character (client-side visual only).",
                Callback = function()
                    if not selectedMount or selectedMount == "None" then
                        Library:Notify({Title="Mount", Content="Select a mount first.", Duration=3})
                        return
                    end
                    if MountController then
                        pcall(function() MountController:despawnMount(LocalPlayer) end)
                        local ok = pcall(function() MountController:spawnMount(LocalPlayer, {cl="mount", nm=selectedMount}) end)
                        if ok then
                            Library:Notify({Title="Mount", Content="Equipped "..selectedMount, Duration=3})
                        else
                            Library:Notify({Title="Mount", Content="Failed to equip. Mount may not exist.", Duration=3})
                        end
                    else
                        Library:Notify({Title="Mount", Content="MountController not available.", Duration=3})
                    end
                end
            })

            MountSection:Button({
                Title = "Remove Mount",
                Description = "Despawns your current mount.",
                Callback = function()
                    if MountController then
                        pcall(function() MountController:despawnMount(LocalPlayer) end)
                        Library:Notify({Title="Mount", Content="Mount removed.", Duration=3})
                    end
                end
            })
            end -- End Visuals scope

            -- ============================================================
            -- WEBHOOK TAB (Inline)
            -- ============================================================
            do
            local WebhookSection = Tabs.Discord:AddSection("Configuration")
            local WEBHOOK_URL = ""
            local DISCORD_USER_ID = ""
            local selectedRarities = {}
            local showRobloxUser = false
            local showPetImage = true
            local webhookEnabled = false
            local statsWebhookEnabled = false

            local PetRarities = require(ReplicatedStorage.Shared.List.Pets.Rarities)
            local PetsModule = require(ReplicatedStorage.Shared.List.Pets.Pets)
            local TiersList = require(ReplicatedStorage.Shared.List.Pets.Tiers)
            local EggsModule = require(ReplicatedStorage.Shared.List.Pets.Eggs)

            local gameName = "Unknown Game"
            pcall(function() gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)

            local thumbCache = {}
            local webhookQueue = {}
            local isProcessingQueue = false

            local function wh_formatNumber(num)
                local suf = {
                    {1e63,"Vg"},{1e60,"Ng"},{1e57,"Og"},{1e54,"Sg"},{1e51,"Se"},
                    {1e48,"Qi"},{1e45,"Qa"},{1e42,"Tg"},{1e39,"Vg"},{1e36,"UDe"},
                    {1e33,"De"},{1e30,"No"},{1e27,"Oc"},{1e24,"Sp"},{1e21,"Sx"},
                    {1e18,"Qn"},{1e15,"Qd"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}
                }
                for _, d in ipairs(suf) do
                    if num >= d[1] then return string.format("%.2f%s", num/d[1], d[2]):gsub("%.00","") end
                end
                return tostring(math.floor(num))
            end

            local function getRarityColor(rarity)
                for _, rd in ipairs(PetRarities) do
                    if rd.name == rarity and rd.textColor and rd.textColor.gradient then
                        local kp = rd.textColor.gradient.Keypoints
                        if #kp > 0 then
                            local c = kp[1].Value
                            return math.floor(c.R*255)*65536 + math.floor(c.G*255)*256 + math.floor(c.B*255)
                        end
                    end
                end
                return 0xFFFFFF
            end

            local function getPetChance(eggName, petName)
                local eggData = EggsModule[eggName]
                if not eggData then
                    for _, d in pairs(EggsModule) do if d.pets and d.pets[petName] then eggData = d; break end end
                end
                if eggData and eggData.pets and eggData.pets[petName] then
                    local pw = eggData.pets[petName]
                    local tw = 0
                    for _,w in pairs(eggData.pets) do tw = tw + w end
                    local pct = (pw/tw)*100
                    if pct < 0.0001 then return string.format("%.8f%%", pct)
                    elseif pct < 1 then return string.format("%.4f%%", pct)
                    else return string.format("%.2f%%", pct) end
                end
                return "Unknown"
            end

            local function fetchThumbnail(assetId)
                if thumbCache[assetId] then return thumbCache[assetId] end
                task.wait(0.05)
                local s, r = pcall(function()
                    return requestFunc({
                        Url = "https://thumbnails.roblox.com/v1/assets?assetIds="..assetId.."&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false",
                        Method = "GET", Headers = {["accept"]="application/json"}
                    })
                end)
                if s and r and r.Body then
                    local ok, data = pcall(HttpService.JSONDecode, HttpService, r.Body)
                    if ok and data.data and data.data[1] then
                        thumbCache[assetId] = data.data[1].imageUrl
                        return thumbCache[assetId]
                    end
                end
                return nil
            end

            local function processQueue()
                if isProcessingQueue then return end
                isProcessingQueue = true
                task.spawn(function()
                    while #webhookQueue > 0 do
                        local batch = {}
                        local pingMsg = DISCORD_USER_ID ~= "" and string.format("<@%s>", DISCORD_USER_ID) or ""
                        for i = 1, 10 do
                            if #webhookQueue == 0 then break end
                            table.insert(batch, table.remove(webhookQueue, 1))
                        end
                        local embeds = {}
                        for _, pd in ipairs(batch) do
                            local thumb = showPetImage and pd.assetId and fetchThumbnail(pd.assetId) or nil
                            local pv = showRobloxUser and string.format("%s ||(%s)||", LocalPlayer.Name, LocalPlayer.UserId) or "Anonymous"
                            local fields = {
                                {name="Player", value=pv, inline=false},
                                {name="Pet Name", value=pd.baseName, inline=false},
                                {name="Type", value=pd.typeName, inline=true},
                                {name="Shiny", value=pd.isShiny and "Yes" or "No", inline=true},
                                {name="Rarity", value=pd.rarity, inline=true},
                                {name="Chance", value=pd.chance, inline=true},
                                {name="Multiplier", value=pd.multiplier, inline=true}
                            }
                            local embed = {
                                title = "Pet Hatched",
                                color = getRarityColor(pd.rarity),
                                fields = fields,
                                footer = {text = "RCU Logger | " .. os.date("%I:%M %p")}
                            }
                            if thumb then embed.thumbnail = {url = thumb} end
                            table.insert(embeds, embed)
                        end
                        if #embeds > 0 and WEBHOOK_URL ~= "" then
                            pcall(function()
                                requestFunc({Url=WEBHOOK_URL, Method="POST",
                                    Headers={["Content-Type"]="application/json"},
                                    Body=HttpService:JSONEncode({content=pingMsg, embeds=embeds})
                                })
                            end)
                        end
                        task.wait(1)
                    end
                    isProcessingQueue = false
                end)
            end

            local function isValidWebhookUrl(url)
                return type(url) == "string" and (
                    url:match("^https://discord%.com/api/webhooks/%d+/[%w_%-]+$")
                    or url:match("^https://discordapp%.com/api/webhooks/%d+/[%w_%-]+$")
                ) ~= nil
            end

            local function sanitizeDiscordId(input)
                return tostring(input or ""):gsub("[^%d]", "")
            end

            WebhookSection:AddInput("WebhookURL", {
                Title = "Webhook URL",
                Default = "",
                Description = "Paste your Discord webhook URL here (Server Settings > Integrations > Webhooks)",
                Callback = function(v)
                    local url = tostring(v or "")
                    if url == "" then
                        WEBHOOK_URL = ""
                    elseif isValidWebhookUrl(url) then
                        WEBHOOK_URL = url
                    else
                        WEBHOOK_URL = ""
                        Library:Notify({Title="Invalid URL", Content="Only Discord webhook URLs are accepted.", Duration=4})
                    end
                end
            })

            WebhookSection:AddInput("DiscordUserID", {
                Title = "Discord User ID (optional)",
                Default = "",
                Description = "Your Discord user ID for ping notifications. Leave empty to disable pings.",
                Callback = function(v) DISCORD_USER_ID = sanitizeDiscordId(v) end
            })

            WebhookSection:AddToggle("ShowRobloxUser", {
                Title = "Show Roblox Username",
                Description = "Include your Roblox username and ID in webhook embeds",
                Default = false,
                Callback = function(v) showRobloxUser = v end
            })

            WebhookSection:AddToggle("ShowPetImage", {
                Title = "Show Pet Thumbnail",
                Description = "Fetches the pet image from Roblox. May cause a brief freeze on first hatch of each pet type.",
                Default = true,
                Callback = function(v) showPetImage = v end
            })

            WebhookSection:AddButton({
                Title = "Test Webhook",
                Description = "Sends a test embed to verify your webhook URL works",
                Callback = function()
                    if WEBHOOK_URL == "" then
                        Library:Notify({Title="Error", Content="Enter a Webhook URL first.", Duration=3})
                        return
                    end
                    local pv = showRobloxUser and string.format("```%s (%s)```", LocalPlayer.Name, LocalPlayer.UserId) or "```Anonymous```"
                    local ping = DISCORD_USER_ID ~= "" and string.format("<@%s>", DISCORD_USER_ID) or ""
                    task.spawn(function()
                        local ok = pcall(function()
                            requestFunc({Url=WEBHOOK_URL, Method="POST",
                                Headers={["Content-Type"]="application/json"},
                                Body=HttpService:JSONEncode({
                                    content=ping,
                                    embeds={{
                                        title="Webhook Connected",
                                        description="Your webhook is configured and ready.",
                                        color=0x00FF00,
                                        fields={
                                            {name="Player", value=pv, inline=false},
                                            {name="Game", value=gameName, inline=true},
                                            {name="Executor", value=identifyexecutor and identifyexecutor() or "Unknown", inline=true}
                                        },
                                        footer={text="RCU by Ducky"},
                                        timestamp=os.date("!%Y-%m-%dT%H:%M:%S")
                                    }}
                                })
                            })
                        end)
                        Library:Notify({Title=ok and "Success" or "Error", Content=ok and "Test sent to Discord!" or "Failed to send.", Duration=3})
                    end)
                end
            })

            local PetWebhookSection = Tabs.Discord:AddSection("Pet Webhook")

            local function getRarityList()
                local list = {}
                for _, r in ipairs(PetRarities) do if r.name then table.insert(list, r.name) end end
                return list
            end

            PetWebhookSection:Dropdown("WebhookRarities", {
                Title = "Rarities to Track",
                Description = "Only pets with these rarities will trigger a webhook notification",
                Values = getRarityList(),
                Multi = true, Searchable = true, Default = {},
                Callback = function(val)
                    selectedRarities = {}
                    for k,v in pairs(val) do if v then selectedRarities[k] = true end end
                end
            })

            PetWebhookSection:AddToggle("EnablePetWebhook", {
                Title = "Enable Pet Hatch Webhook",
                Description = "Sends a Discord notification whenever you hatch a pet matching the selected rarities",
                Default = false,
                Callback = function(v) webhookEnabled = v end
            })

            -- Connect to egg hatch signal
            if EggService then
                EggService.openEgg:Connect(function(eggName, petTable)
                    if not webhookEnabled then return end
                    local actualPets = petTable
                    local actualEggName = eggName
                    if type(eggName) == "table" then actualPets = eggName; actualEggName = "Unknown" end
                    if type(actualPets) ~= "table" then return end
                    task.spawn(function()
                        for _, pd in ipairs(actualPets) do
                            local basePet = PetsModule[pd.nm]
                            if basePet and selectedRarities[basePet.rarity] then
                                local tier = pd.ti or 1
                                local mult = basePet.multiplier or 0
                                local tierMult = math.max(1, tier*2-2)
                                local shinyMult = pd.sh and 1.5 or 1
                                local total = mult * tierMult * shinyMult
                                local typeName = (tier > 1 and TiersList[tier]) and TiersList[tier].name or "Normal"
                                local assetId = basePet.images and basePet.images[tier] and tostring(basePet.images[tier]):match("%d+") or nil
                                table.insert(webhookQueue, {
                                    baseName=pd.nm, typeName=typeName, isShiny=pd.sh,
                                    rarity=basePet.rarity, multiplier="x"..wh_formatNumber(total),
                                    chance=getPetChance(actualEggName, pd.nm), assetId=assetId
                                })
                            end
                        end
                        processQueue()
                    end)
                end)
            end

            -- === STATS WEBHOOK ===
            local StatsSection = Tabs.Discord:AddSection("Stats Webhook")

            local statsCategories = {"Basic Stats", "Multipliers", "Equipped Pets", "Inventory Summary", "Hive Stats", "Hatch Stats"}
            local selectedStatsCategories = {}

            StatsSection:Dropdown("StatsCategories", {
                Title = "Data to Include",
                Description = "Select which categories of data to send in the stats webhook",
                Values = statsCategories,
                Multi = true,
                Default = {},
                Callback = function(val)
                    selectedStatsCategories = {}
                    for k, v in pairs(val) do if v then selectedStatsCategories[k] = true end end
                end
            })

            StatsSection:Button({
                Title = "Select All Categories",
                Callback = function()
                    local all = {}
                    for _, cat in ipairs(statsCategories) do all[cat] = true end
                    selectedStatsCategories = all
                end
            })

            local function buildStatsEmbeds()
                local pd = DataController:getData()
                if not pd then return nil end
                local embeds = {}
                local pName = LocalPlayer.Name

                -- Basic Stats
                if selectedStatsCategories["Basic Stats"] then
                    local clicks = pd.clicks or 0
                    local rebirths = pd.rebirths or 0
                    local gems = pd.gems or 0
                    local prestige = pd.prestige or 0
                    local highestMap = 0
                    if pd.maps then for mapId in pairs(pd.maps) do local n = tonumber(mapId); if n and n > highestMap then highestMap = n end end end
                    local skulls = pd.skulls or 0

                    local lines = {
                        "Clicks     : " .. wh_formatNumber(clicks),
                        "Rebirths   : " .. wh_formatNumber(rebirths),
                        "Gems       : " .. wh_formatNumber(gems),
                        "Skulls     : " .. wh_formatNumber(skulls),
                        "Prestige   : " .. prestige,
                        "Highest Map: " .. highestMap,
                    }
                    table.insert(embeds, {
                        title = "📊 Basic Stats — " .. pName,
                        description = "```\n" .. table.concat(lines, "\n") .. "\n```",
                        color = 0x5865F2,
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                    })
                end

                -- Multipliers
                if selectedStatsCategories["Multipliers"] then
                    local lines = {}
                    pcall(function()
                        local function tryGet(name, func)
                            local ok, val = pcall(func)
                            if ok and val then table.insert(lines, name .. ": " .. tostring(val)) end
                        end
                        if pd.upgrades then
                            for upgId, level in pairs(pd.upgrades) do
                                table.insert(lines, upgId .. ": Lv" .. level)
                            end
                        end
                    end)
                    if #lines == 0 then table.insert(lines, "No multiplier data available") end
                    table.sort(lines)
                    table.insert(embeds, {
                        title = "✨ Multipliers/Upgrades — " .. pName,
                        description = "```\n" .. table.concat(lines, "\n") .. "\n```",
                        color = 0xE91E63,
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                    })
                end

                -- Equipped Pets
                if selectedStatsCategories["Equipped Pets"] then
                    local lines = {}
                    pcall(function()
                        if pd.equippedPets then
                            for petId in pairs(pd.equippedPets) do
                                local petData = pd.inventory and pd.inventory.pet and pd.inventory.pet[petId]
                                if petData then
                                    local obj = Util.itemUtils.createItemFromData(petData)
                                    if obj then
                                        local name = obj:getName()
                                        local mult = obj:getMultiplier()
                                        table.insert(lines, name .. " — x" .. wh_formatNumber(mult))
                                    end
                                end
                            end
                        end
                    end)
                    table.sort(lines)
                    if #lines == 0 then table.insert(lines, "No pets equipped") end
                    table.insert(embeds, {
                        title = "🐾 Equipped Pets (" .. #lines .. ") — " .. pName,
                        description = "```\n" .. table.concat(lines, "\n") .. "\n```",
                        color = 0xFF9800,
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                    })
                end

                -- Inventory Summary (detailed item lists)
                if selectedStatsCategories["Inventory Summary"] then
                    local inv = pd.inventory or {}
                    local categories = {
                        {key="potion", title="Potions", color=0x03A9F4},
                        {key="fruit", title="Fruits", color=0x8BC34A},
                        {key="smoothie", title="Smoothies", color=0xFF5722},
                        {key="totem", title="Totems", color=0x00BCD4},
                        {key="box", title="Boxes", color=0xFFC107},
                        {key="auraDice", title="Aura Dice", color=0x9C27B0},
                        {key="activeEvent", title="Active Events", color=0xE91E63},
                        {key="exclusive", title="Exclusive Items", color=0xFF9800},
                    }
                    for _, cat in ipairs(categories) do
                        if inv[cat.key] then
                            local items = {}
                            for _, item in pairs(inv[cat.key]) do
                                local name = item.nm or "?"
                                local amount = item.am or 1
                                -- Try to get readable name
                                local readableName = name
                                pcall(function()
                                    local obj = Util.itemUtils.createItemFromData(item)
                                    if obj and obj.getRealName then readableName = obj:getRealName()
                                    elseif obj and obj.getName then readableName = obj:getName() end
                                end)
                                table.insert(items, {name=readableName, amount=amount})
                            end
                            if #items > 0 then
                                table.sort(items, function(a,b) return a.amount > b.amount end)
                                local lines = {}
                                for _, it in ipairs(items) do
                                    table.insert(lines, wh_formatNumber(it.amount) .. "x " .. it.name)
                                end
                                -- Discord embed description limit is 4096 chars, truncate if needed
                                local desc = table.concat(lines, "\n")
                                if #desc > 3900 then desc = desc:sub(1, 3900) .. "\n... (truncated)" end
                                table.insert(embeds, {
                                    title = "🎒 " .. cat.title .. " — " .. pName,
                                    description = "```\n" .. desc .. "\n```",
                                    color = cat.color,
                                    timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                                })
                            end
                        end
                    end
                end

                -- Hive Stats
                if selectedStatsCategories["Hive Stats"] then
                    local lines = {}
                    pcall(function()
                        local honeyAm = 0
                        pcall(function() local h = Util.itemUtils.getItemFromName(pd, "honey"); honeyAm = h and h:getAmount() or 0 end)
                        table.insert(lines, "Honey        : " .. wh_formatNumber(honeyAm))
                        table.insert(lines, "Honey Pending: " .. wh_formatNumber(pd.honeyToCollect or 0))
                        if pd.hiveUpgrades then
                            for uid, lvl in pairs(pd.hiveUpgrades) do
                                table.insert(lines, uid .. ": Lv" .. lvl)
                            end
                        end
                        local beeCount = 0
                        if pd.inventory and pd.inventory.bee then
                            for _, b in pairs(pd.inventory.bee) do beeCount = beeCount + (b.am or 1) end
                        end
                        table.insert(lines, "Total Bees   : " .. beeCount)
                        local eqBees = 0
                        if pd.equippedBees then for _ in pairs(pd.equippedBees) do eqBees = eqBees + 1 end end
                        table.insert(lines, "Equipped Bees: " .. eqBees)
                    end)
                    if #lines == 0 then table.insert(lines, "No hive data") end
                    table.insert(embeds, {
                        title = "🍯 Hive Stats — " .. pName,
                        description = "```\n" .. table.concat(lines, "\n") .. "\n```",
                        color = 0xFFC107,
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                    })
                end

                -- Hatch Stats
                if selectedStatsCategories["Hatch Stats"] then
                    local lines = {}
                    pcall(function()
                        local stats = pd.stats or {}
                        local keys = {"eggsOpened", "legendaryHatched", "mythicalHatched", "eternalHatched",
                            "secretHatched", "divineHatched", "supremeHatched", "ultimateHatched",
                            "auraRolls", "treesDestroyed", "fruitsCollected", "potionsUsed",
                            "chestsOpened", "fallingStarsCollected", "dungeonDamage"}
                        for _, k in ipairs(keys) do
                            if stats[k] and stats[k] > 0 then
                                table.insert(lines, k .. ": " .. wh_formatNumber(stats[k]))
                            end
                        end
                        if pd.indexCollected then
                            table.insert(lines, "Index Collected: " .. pd.indexCollected)
                        end
                    end)
                    if #lines == 0 then table.insert(lines, "No hatch stats") end
                    table.insert(embeds, {
                        title = "🥚 Hatch & Activity Stats — " .. pName,
                        description = "```\n" .. table.concat(lines, "\n") .. "\n```",
                        color = 0x9C27B0,
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
                    })
                end

                -- Add footer to last embed
                if #embeds > 0 then
                    embeds[#embeds].footer = {text = "RCU Stats | " .. os.date("%I:%M %p %m/%d/%Y")}
                end

                return embeds
            end

            StatsSection:AddButton({
                Title = "Send Stats Now",
                Description = "Sends selected data categories to your Discord webhook. Uses compact code blocks to keep embeds small.",
                Callback = function()
                    if WEBHOOK_URL == "" then
                        Library:Notify({Title="Error", Content="Enter a Webhook URL first.", Duration=3})
                        return
                    end
                    if not next(selectedStatsCategories) then
                        Library:Notify({Title="Error", Content="Select at least one data category first.", Duration=3})
                        return
                    end
                    task.spawn(function()
                        pcall(function()
                            DataController:waitForData()
                            local embeds = buildStatsEmbeds()
                            if not embeds or #embeds == 0 then return end
                            local ping = DISCORD_USER_ID ~= "" and string.format("<@%s>", DISCORD_USER_ID) or ""
                            -- Discord allows max 10 embeds per message, send in batches
                            for i = 1, #embeds, 10 do
                                local batch = {}
                                for j = i, math.min(i + 9, #embeds) do table.insert(batch, embeds[j]) end
                                requestFunc({Url=WEBHOOK_URL, Method="POST",
                                    Headers={["Content-Type"]="application/json"},
                                    Body=HttpService:JSONEncode({content=(i==1 and ping or ""), embeds=batch})
                                })
                                if i + 10 <= #embeds then task.wait(1) end
                            end
                            Library:Notify({Title="Sent", Content=#embeds.." embeds sent to Discord!", Duration=3})
                        end)
                    end)
                end
            })

            local statsIntervalInput = StatsSection:AddInput("StatsInterval", {
                Title = "Auto-Send Interval (minutes)",
                Default = "30",
                Numeric = true,
                Description = "How often to automatically send stats. Set 0 to disable auto-send."
            })

            StatsSection:Toggle("AutoSendStats", {
                Title = "Auto Send Stats",
                Description = "Sends the selected stat categories to your webhook on a timer",
                Default = false,
                Callback = function(enabled)
                    statsWebhookEnabled = enabled
                    if _G.StatsWebhookThread then task.cancel(_G.StatsWebhookThread); _G.StatsWebhookThread = nil end
                    if enabled then
                        _G.StatsWebhookThread = task.spawn(function()
                            while statsWebhookEnabled do
                                local interval = (tonumber(statsIntervalInput.Value) or 30) * 60
                                if interval <= 0 then interval = 1800 end
                                task.wait(interval)
                                if not statsWebhookEnabled or WEBHOOK_URL == "" then break end
                                pcall(function()
                                    DataController:waitForData()
                                    local embeds = buildStatsEmbeds()
                                    if not embeds or #embeds == 0 then return end
                                    local ping = DISCORD_USER_ID ~= "" and string.format("<@%s>", DISCORD_USER_ID) or ""
                                    for i = 1, #embeds, 10 do
                                        local batch = {}
                                        for j = i, math.min(i + 9, #embeds) do table.insert(batch, embeds[j]) end
                                        requestFunc({Url=WEBHOOK_URL, Method="POST",
                                            Headers={["Content-Type"]="application/json"},
                                            Body=HttpService:JSONEncode({content=(i==1 and ping or ""), embeds=batch})
                                        })
                                        if i + 10 <= #embeds then task.wait(1) end
                                    end
                                end)
                            end
                        end)
                    end
                end
            })
            end -- End Webhook scope

            SaveManager:SetLibrary(Library)
            InterfaceManager:SetLibrary(Library)
            SaveManager:IgnoreThemeSettings()
            SaveManager:SetIgnoreIndexes{}
            InterfaceManager:SetFolder("FluentScriptHub")
            SaveManager:SetFolder("FluentScriptHub/RCU-main")

            InterfaceManager:BuildInterfaceSection(Tabs.Settings)
            SaveManager:BuildConfigSection(Tabs.Settings)

            Window:SelectTab(1)
            SaveManager:LoadAutoloadConfig()

            local usercountsection = Tabs.Settings:AddSection("User Count")

            local userCountParagraph = Tabs.Settings:AddParagraph("UserCountStatus", {
                Title = "Script User Count",
                Content = "Loading..."
            })


            -- Step 1: Register the user
            local registerResponse = requestFunc({
                Url = "https://duckyscripts.pythonanywhere.com/api/rcu/add-user",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode({
                    username = username,
                    userid = userid
                })
            })

            if registerResponse and registerResponse.Body then
            end


            task.spawn(function()
                while true do
                    local heartbeatResponse = requestFunc({
                        Url = "https://duckyscripts.pythonanywhere.com/api/rcu/active",
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json"
                        },
                        Body = HttpService:JSONEncode({
                            userid = userid,
                            active = true
                        })
                    })

                    if heartbeatResponse and heartbeatResponse.Body then
                        pcall(function()
                            local responseBody = heartbeatResponse.Body
                            local data = HttpService:JSONDecode(responseBody)
                            local activeCount = data.active_count or 0
                            local totalCount = data.count or 0
                            userCountParagraph:SetValue("Total users: " .. tostring(totalCount) .. "\nActive Users: " .. tostring(activeCount))
                        end)
                    end

                    task.wait(30) 
                end
            end)
        end

        task.spawn(function()
            if not game:IsLoaded() then game.Loaded:Wait() end

            Knit = require(ReplicatedStorage.Packages.Knit)
            Knit.OnStart():await()

            ClickService = Knit.GetService("ClickService")
            EggService = Knit.GetService("EggService")
            RebirthService = Knit.GetService("RebirthService")
            GardenService = Knit.GetService("GardenService")
            TreeService = Knit.GetService("TreeService")
            AxeService = Knit.GetService("AxeService")
            InventoryService = Knit.GetService("InventoryService")
            PetService = Knit.GetService("PetService")
            RewardService = Knit.GetService("RewardService")
            ClanService = Knit.GetService("ClanService")
            UpgradeService = Knit.GetService("UpgradeService")
            SeasonService = Knit.GetService("SeasonService")
            FarmService = Knit.GetService("FarmService")
            AuraService = Knit.GetService("AuraService")
            EventService = Knit.GetService("EventService")
            OrbService = Knit.GetService("OrbService")
            BuildingService = Knit.GetService("BuildingService")
            LumberjackService = Knit.GetService("LumberjackService")
            DungeonService = Knit.GetService("DungeonService")
            
            DataController = Knit.GetController("DataController")
            EggController = Knit.GetController("EggController")
            TreeController = Knit.GetController("TreeController")
            AuraController = Knit.GetController("AuraController")
            MapController = Knit.GetController("MapController")
            OrbController = Knit.GetController("OrbController")
            ItemController = Knit.GetController("ItemController")
            SoundController = Knit.GetController("SoundController")
            FarmController = Knit.GetController("FarmController")
            BuildingController = Knit.GetController("BuildingController")
            HatchingController = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("HatchingController"))
            
            Functions = require(ReplicatedStorage.Shared.Functions)
            seasonVariables = require(ReplicatedStorage.Shared.Variables)
            seasonUtils = require(ReplicatedStorage.Shared.Util)
            seasonTiersList = require(ReplicatedStorage.Shared.List[("Season%*"):format(seasonVariables.season)].Tiers)
            Util = require(ReplicatedStorage.Shared.Util)
            Values = require(ReplicatedStorage.Shared.Values)   

            Window = Library:Window{
                Title = "RCU",
                SubTitle = "By Duckie",
                TabWidth = 160,
                Size =  UDim2.fromOffset(580, 460),
                Resize = false,
                Theme = "Darker",
                MinimizeKey = Enum.KeyCode.LeftShift
            }

            Tabs = {
                Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
                Rejoin = Window:AddTab({ Title = "Auto Rejoin", Icon = "recycle" }),
                Main = Window:AddTab({ Title = "Auto Farm", Icon = "crown" }),
                Eggs = Window:AddTab({ Title = "Eggs", Icon = "egg" }),
                Tree = Window:AddTab({ Title = "Axe/Tree", Icon = "phosphor-tree-evergreen-duotone" }),
                Farm = Window:AddTab({ Title = "Farming", Icon = "phosphor-farm-bold" }),
                Pet = Window:AddTab({ Title = "Pet Crafting", Icon = "paw-print" }),
                Dungeon = Window:AddTab({ Title = "Dungeon", Icon = "phosphor-shield-checkered-bold" }),
                BeeHive = Window:AddTab({ Title = "Bee Hive", Icon = "hexagon" }),
                Craft = Window:AddTab({ Title = "Building", Icon = "hammer" }),
                Quest = Window:AddTab({ Title = "Quests", Icon = "phosphor-scroll-bold" }),
                MineFish = Window:AddTab({ Title = "Mine/Fish/Misc", Icon = "pickaxe" }),
                Claim = Window:AddTab({ Title = "Auto Claim", Icon = "gift" }),
                Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
                Discord = Window:AddTab({ Title = "Webhook", Icon = "phosphor-discord-logo" })
            }

            -- Compatibility aliases for external loadstrings that use old tab names
            Tabs.Misc = Tabs.MineFish
            Tabs.Mine = Tabs.MineFish
            Tabs.Fish = Tabs.MineFish
            Tabs.Machine = Tabs.MineFish
            Tabs.Dunegon = Tabs.Dungeon  -- typo in original dungeon script
            Tabs.Webhook = Tabs.Discord

            BuildUI()
        end)
        loadSuccess = true
    end)
    
    if success and loadSuccess then
        print(string.format("[RCU] Successfully loaded on attempt %d/%d", attempt, maxRetries))
        break
    else
        warn(string.format("[RCU] Failed to load (Attempt %d/%d): %s", attempt, maxRetries, tostring(errorMsg)))
        
        if attempt < maxRetries then
            warn(string.format("[RCU] Retrying in %d seconds...", retryDelay))
            task.wait(retryDelay)
        else
            warn("[RCU] Failed to load after " .. maxRetries .. " attempts. Please try again.")
        end
    end
end
