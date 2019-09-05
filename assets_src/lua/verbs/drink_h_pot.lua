local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Constants = require "constants"
local AI = require "age_of_wargroove/ai"

local DrinkGPot = Verb:new()

function DrinkGPot:canExecuteAnywhere(unit)
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

function DrinkGPot:canExecuteAt(unit, endPos)
    if unit.pos.x ~= endPos.x or unit.pos.y ~= endPos.y then
        return false
    end

    return (not Wargroove.canPlayerSeeTile(-1, endPos)) or (not Wargroove.isAnybodyElseAt(unit, endPos))
end


function DrinkGPot:execute(unit, targetPos, strParam, path)
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

function DrinkGPot:generateOrders(unitId, canMove)
    return AI.drinkHPotOrders(unitId, canMove)
end

function DrinkGPot:getScore(unitId, order)
    return AI.drinkHPotScore(unitId, order)
end

function DrinkGPot:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = false
end

return DrinkGPot
