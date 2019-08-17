local Wargroove = require "wargroove/wargroove"
local OriginalUnload = require "verbs/unload"
local Constants = require "constants"
local AOW = require "age_of_wargroove/age_of_wargroove"

local Unload = {}

function Unload.init()
    OriginalUnload.canExecuteWithTarget = Unload.canExecuteWithTarget
    OriginalUnload.execute = Unload.execute
end

function Unload:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if #unit.loadedUnits == 0 then
        return false
    end

    -- If it's a water transport, is it on a beach?
    local tags = unit.unitClass.tags
    for i, tag in ipairs(tags) do
        if tag == "type.sea" then
            if Wargroove.getTerrainNameAt(endPos) ~= "beach" then
                return false
            end
        end
    end

    if strParam == '' then
        -- This means that the code is seeing if it should add Dismiss to the action ui list
        -- Actual checking is done in code.f
        return true
    end

    local unitId = tonumber(strParam)

    if unitId then
        for i, location in ipairs(OriginalUnload.selectedLocations) do
            if location.x == targetPos.x and location.y == targetPos.y then
                return false
            end
        end

        local loadedUnit = Wargroove.getUnitById(unitId)
        if (loadedUnit.unitClassId == "gold") then
            return false
        end
        
        if Wargroove.canStandAt(loadedUnit.unitClassId, targetPos) then
            return true
        end

        return false
    end

    local targets = OriginalUnload:parseStrParam(strParam)
    for unitId, target in pairs(targets) do
        local loadedUnit = Wargroove.getUnitById(unitId)
        
        if (loadedUnit.unitClassId == "gold") then
            return false
        end
        
        if not Wargroove.canStandAt(loadedUnit.unitClassId, target) then
            return false
        end
    end    
    return true
end

function Unload:execute(unit, targetPos, strParam, path)
    local targets = OriginalUnload:parseStrParam(strParam)

    for unitId, target in pairs(targets) do
        local transportedUnit = Wargroove.getUnitById(unitId)
        transportedUnit.pos = target
        transportedUnit.hadTurn = true
        transportedUnit.inTransport = false
        transportedUnit.transportedBy = -1
        Wargroove.updateUnit(transportedUnit)

    end

    local newLoadedUnits = {}

    for i, unitId in ipairs(unit.loadedUnits) do
        local found = false
        for unloadedId, target in pairs(targets) do
            if unitId == unloadedId then
                found = true
            end
        end
        if not found then
            table.insert(newLoadedUnits, unitId)
        end
    end

    unit.loadedUnits = newLoadedUnits
    
    if #unit.loadedUnits > 0 then
        local firstUnit = Wargroove.getUnitById(unit.loadedUnits[1])
        if firstUnit ~= nil and firstUnit.unitClassId == "gold" then
            local numberOfMiners = #unit.loadedUnits - 1
            if numberOfMiners == 0 then
                AOW.removeGoldGenerationFromPos(unit.pos)
            else
                AOW.generateGoldPerTurnFromPos(unit.pos, unit.playerId, numberOfMiners * Constants.goldPerTurnPerMine)
            end
        end
    end
end


return Unload
