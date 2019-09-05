local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local AI = require "age_of_wargroove/ai"

local PickUp = Verb:new()


function PickUp:getTargetType()
    return "unit"
end


function PickUp:getMaximumRange(unit, endPos)
    return 1
end


function PickUp:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    -- Has a unit?
    local targetUnit = Wargroove.getUnitAt(targetPos)
    if (not targetUnit) or (targetUnit == unit) then
        return false
    end

    -- Has space?
    local capacity = unit.unitClass.loadCapacity
    if #unit.loadedUnits >= capacity then
        return false
    end
    
    -- Can carry me?
    local targetTags = targetUnit.unitClass.tags
    
    for i, targetTag in ipairs(targetTags) do
        if targetTag == "equipment" then
            return true
        end
    end
    return false
end


function PickUp:execute(unit, targetPos, strParam, path)
    local equipment = Wargroove.getUnitAt(targetPos)
    table.insert(unit.loadedUnits, equipment.id)
    equipment.inTransport = true
    equipment.transportedBy = unit.id
end


function PickUp:onPostUpdateUnit(unit, targetPos, strParam, path)
    local equipment = Wargroove.getUnitAt(targetPos)
    equipment.pos = { x = -78, y = -78 }
    Wargroove.updateUnit(equipment)
end

function PickUp:generateOrders(unitId, canMove)
    return AI.pickUpOrders(unitId, canMove)
end

function PickUp:getScore(unitId, order)
    return AI.pickUpScore(unitId, order)
end

return PickUp
