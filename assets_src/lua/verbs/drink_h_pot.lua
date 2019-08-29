local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Constants = require "constants"
local AI = require "age_of_wargroove/ai"

local DrinkHPot = Verb:new()

function DrinkHPot:canExecuteAnywhere(unit)
    if unit.loadedUnits == nil then
        return false
    end

    for i, equipmentId in ipairs(unit.loadedUnits) do
        local equipment = Wargroove.getUnitById(equipmentId)
        if equipment.unitClassId == "health_pot" then
            return true
        end
    end
    
    return false
end


function DrinkHPot:execute(unit, targetPos, strParam, path)
    unit.health = unit.health + Constants.HPotValue
    
    for i, equipmentId in ipairs(unit.loadedUnits) do
        local equipment = Wargroove.getUnitById(equipmentId)
        if equipment.unitClassId == "health_pot" then
            table.remove(unit.loadedUnits, i)
            Wargroove.removeUnit(equipment)
            return
        end
    end
end

function DrinkHPot:generateOrders(unitId, canMove)
    return AI.drinkHPotOrders(unitId, canMove)
end

function DrinkHPot:getScore(unitId, order)
    return AI.drinkHPotScore(unitId, order)
end

return DrinkHPot
