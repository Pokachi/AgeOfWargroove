local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local AOW = require "age_of_wargroove/age_of_wargroove"
local AI = require "age_of_wargroove/ai"
local Constants = require "constants"

local Mine = Verb:new()

function Mine:getMaximumRange(unit, endPos)
    return 1
end

function Mine:getTargetType()
    return "unit"
end

function Mine:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local target = Wargroove.getUnitAt(targetPos)
    if (not target) or (target == structure) or (not Wargroove.areAllies(target.playerId, unit.playerId)) then
        return false
    end
    
    if target ~= nil and target.unitClassId == "gold_camp" then
        local capacity = target.unitClass.loadCapacity
        
        if #target.loadedUnits > 1 then
            local firstUnit = Wargroove.getUnitById(target.loadedUnits[1])
            if firstUnit.unitClassId ~= "gold" and firstUnit.unitClassId ~= "gem" then
                capacity = target.unitClass.loadCapacity -1
            end
        end
        
        if #target.loadedUnits >= capacity then
            return false
        end
        
        return true
    end
    
    return false
end

function Mine:execute(unit, targetPos, strParam, path)
    local transport = Wargroove.getUnitAt(targetPos)
    table.insert(transport.loadedUnits, unit.id)
    unit.inTransport = true
    unit.transportedBy = transport.id
    Wargroove.updateUnit(transport)
end

function Mine:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.pos = { x = -100, y = -100 }
end

function Mine:generateOrders(unitId, canMove)
    return AI.placeVillagerInMineOrders(unitId, canMove)
end

function Mine:getScore(unitId, order)
    return AI.placeVillagerInMineScore(unitId, order)
end
return Mine
