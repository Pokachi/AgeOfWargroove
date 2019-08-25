local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Constants = require "constants"

local DrinkHPot = Verb:new()

function DrinkHPot:canExecuteAnywhere(unit)
    if unit.loadedUnits == nil then
        return false
    end

    for i, equipmentId in ipairs(unit.loadedUnits) do
        local equipment = Wargroove.getUnitById(equipmentId)
        if equipment.unitClassId == "groove_pot" then
            return true
        end
    end
    
    return false
end


function DrinkHPot:execute(unit, targetPos, strParam, path)
    unit.grooveCharge = unit.grooveCharge + Constants.GPotValue
    
    for i, equipmentId in ipairs(unit.loadedUnits) do
        local equipment = Wargroove.getUnitById(equipmentId)
        if equipment.unitClassId == "groove_pot" then
            table.remove(unit.loadedUnits, i)
            Wargroove.removeUnit(equipment)
            return
        end
    end
end

return DrinkHPot
