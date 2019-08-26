local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Constants = require "constants"

local DimensionalDoor = Verb:new()


function DimensionalDoor:getMaximumRange(unit, endPos)
    local mapSize = Wargroove.getMapSize()
    return mapSize.x + mapSize.y
end

function DimensionalDoor:getTargetType()
    return "empty"
end

local strongholdPos = {}

function DimensionalDoor:canExecuteAnywhere(unit)
    if unit.loadedUnits == nil then
        return false
    end
    
    for i, equipmentId in ipairs(unit.loadedUnits) do
        local equipment = Wargroove.getUnitById(equipmentId)
        if equipment.unitClassId == "dimensional_door" then
            if equipment.grooveCharge < 5 then
                goto continue
            end
            local allUnits = Wargroove.getAllUnitsForPlayer(unit.playerid, false)
            for i, unit in ipairs(allUnits) do
                if unit.unitClassId == "hq" then
                    table.insert(strongholdPos, unit.pos)
                end
            end
            return true
        end
        ::continue::
    end
    
    return false
end

function DimensionalDoor:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    for i, pos in ipairs(strongholdPos) do
        if (math.abs(targetPos.x - pos.x) == 1 and targetPos.y == pos.y) or (math.abs(targetPos.y - pos.y) == 1 and targetPos.x == pos.x) then
            return true
        end
    end
    return false
end

function DimensionalDoor:onPostUpdateUnit(unit, targetPos, strParam, path)
    local currentTurn = Wargroove.getTurnNumber()
    
    unit.pos = targetPos
    
    -- clear dimensional door grooveCharge
    for i, equipmentId in ipairs(unit.loadedUnits) do
        local equipment = Wargroove.getUnitById(equipmentId)
        if equipment.unitClassId == "dimensional_door" then
            if equipment.grooveCharge >= 5 then
                equipment.grooveCharge = 0
                Wargroove.updateUnit(equipment)
                return
            end
        end
    end
end

return DimensionalDoor
