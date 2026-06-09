--[[
    shared/TableUtils.lua
    Generic table / number utility functions used across multiple scripts.

    Usage:
        local T = loadstring(game:HttpGet("...shared/TableUtils.lua"))()
        T.round(3.7)          --> 4
        T.isnil(thing)        --> true/false
        T.formatCash(1234567) --> "1.23M"
]]

local T = {}

--- Round a number to the nearest integer.
function T.round(n)
    return math.floor(tonumber(n) + 0.5)
end

--- Nil-check helper (avoids verbose `x == nil` everywhere).
function T.isnil(thing)
    return thing == nil
end

--- Return sorted keys of a table. If `orderField` is provided, sort by
--- `tbl[key][orderField]`; otherwise sort keys alphabetically.
function T.sortedKeys(tbl, orderField)
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

--- Return sorted keys of `tbl` that pass `predicate(key, value)`.
function T.filterKeys(tbl, predicate)
    local out = {}
    for k, v in pairs(tbl) do
        if predicate(k, v) then table.insert(out, k) end
    end
    table.sort(out)
    return out
end

--- Pretty-print a table to the output console (recursive).
function T.prettyPrint(data, indent)
    indent = indent or 0
    local prefix = string.rep("    ", indent)
    if type(data) ~= "table" then
        print(prefix .. tostring(data))
        return
    end
    for k, v in pairs(data) do
        if type(v) == "table" then
            print(prefix .. tostring(k) .. " = {")
            T.prettyPrint(v, indent + 1)
            print(prefix .. "}")
        else
            print(prefix .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

--- Format large numbers with K / M / B / T suffixes.
function T.formatCash(n)
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

--- Yield periodically during large loops to avoid freezing.
-- Call as `T.lightYield(index, batchSize)` inside a loop.
function T.lightYield(index, batchSize)
    batchSize = batchSize or 50
    if (tonumber(index) or 0) % batchSize == 0 then
        task.wait()
    end
end

return T
