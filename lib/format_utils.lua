--[[
  format_utils.lua
  Formatting utilities extracted from the RCU codebase for testability.
  Sources: SSC_Elite_Farm_v3.lua (formatCash, formatDuration, rarityColor)
           RCU_Main_Final_Fixed.lua (wh_formatNumber)
]]

local M = {}

--- Formats large numbers with K/M/B/T suffixes.
-- Extracted from SSC_Elite_Farm_v3.lua:345
function M.formatCash(n)
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

--- Formats seconds into HH:MM:SS.
-- Extracted from SSC_Elite_Farm_v3.lua:2101
function M.formatDuration(secs)
    secs = math.max(0, math.floor(secs))
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

--- Map of card rarity names to Discord embed colors.
-- Extracted from SSC_Elite_Farm_v3.lua:361
M.RARITY_COLORS = {
    Common              = 9807270,
    Bronze              = 13467442,
    Silver              = 12500670,
    Gold                = 16766720,
    Platinum            = 11725548,
    Legendary           = 16753920,
    Mythic              = 14684400,
    Mythical            = 14684400,
    Divine              = 4233727,
    Primordial          = 9856770,
    ["Azure Zenith"]    = 3447003,
    ["Crimson Zenith"]  = 13632027,
    Oblivion            = 2829617,
    Eternity            = 16767093,
    Astral              = 9510911,
    Sovereign           = 16776960,
    Vandal              = 16711935,
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
M.DEFAULT_EMBED_COLOR = 3447003

--- Returns the Discord embed color for a given rarity name.
-- Extracted from SSC_Elite_Farm_v3.lua:393
function M.rarityColor(rarityName)
    return M.RARITY_COLORS[tostring(rarityName)] or M.DEFAULT_EMBED_COLOR
end

--- Formats numbers with extended suffix notation (K through Vg).
-- Extracted from RCU_Main_Final_Fixed.lua:6470
function M.wh_formatNumber(num)
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

--- Pretty-prints a table with indentation.
-- Extracted from SSC_Elite_Farm_v3.lua:110
function M.prettyPrint(data, indent)
    indent = indent or 0
    local prefix = string.rep("    ", indent)
    if type(data) ~= "table" then
        return prefix .. tostring(data)
    end
    local lines = {}
    for k, v in pairs(data) do
        if type(v) == "table" then
            table.insert(lines, prefix .. tostring(k) .. " = {")
            table.insert(lines, M.prettyPrint(v, indent + 1))
            table.insert(lines, prefix .. "}")
        else
            table.insert(lines, prefix .. tostring(k) .. " = " .. tostring(v))
        end
    end
    return table.concat(lines, "\n")
end

return M
