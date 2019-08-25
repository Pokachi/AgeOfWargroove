local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Constants = require "constants"

local DimensionalDoor = Verb:new()

local coolDownStateName = "D_DOOR_CD"

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
    
    local coolDownTimer = Wargroove.getUnitState(unit, coolDownStateName)
    if coolDownTimer ~= nil then
        if Wargroove.getTurnNumber() < tonumber(coolDownTimer) then
            return false
        end
    end
    
    
    for i, equipmentId in ipairs(unit.loadedUnits) do
        local equipment = Wargroove.getUnitById(equipmentId)
        if equipment.unitClassId == "dimensional_door" then
            
            local allUnits = Wargroove.getAllUnitsForPlayer(unit.playerid, false)
            for i, unit in ipairs(allUnits) do
                if unit.unitClassId == "hq" then
                    table.insert(strongholdPos, unit.pos)
                end
            end
            return true
        end
    end
    
    return false
end

function DimensionalDoor:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    for i, pos in ipairs(strongholdPos) do
        if (math.abs(targetPos.x - pos.x) == 1 and targetPos.y == pos.y) or (math.abs(targetPos.y - pos.y) == 1 and targetPos.x == pos.x) then
            return true
        end
    end
    return flase
end

function DimensionalDoor:onPostUpdateUnit(unit, targetPos, strParam, path)
    local currentTurn = Wargroove.getTurnNumber()
    Wargroove.setUnitState(unit, coolDownStateName, currentTurn + Constants.coolDown.door);
    unit.pos = targetPos
end

return DimensionalDoor
