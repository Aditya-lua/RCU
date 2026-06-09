--[[
  table_utils.lua
  Table/collection utilities extracted from the RCU codebase for testability.
  Sources: PickaxeSim.lua (sortedKeys, filterKeys, getWorldList logic)
]]

local M = {}

--- Returns sorted keys of a table, optionally ordered by a field in sub-tables.
-- Extracted from PickaxeSim.lua:121
function M.sortedKeys(tbl, orderField)
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

--- Returns sorted keys filtered by a predicate function.
-- Extracted from PickaxeSim.lua:137
function M.filterKeys(tbl, predicate)
    local out = {}
    for k, v in pairs(tbl) do
        if predicate(k, v) then table.insert(out, k) end
    end
    table.sort(out)
    return out
end

--- Builds a sorted world-name list and an index map from a worlds table.
-- Extracted from PickaxeSim.lua:165
function M.getWorldList(worldsTable)
    local indexed = {}
    for k, v in pairs(worldsTable) do
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

return M
