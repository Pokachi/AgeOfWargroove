local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local CancelRecruitment = Verb:new()

function CancelRecruitment:canExecuteAnywhere(unit)
    return #unit.loadedUnits > 0
end

function CancelRecruitment:execute(unit, targetPos, strParam, path)
    if #unit.loadedUnits >= 1 and unit.unitClassId ~= "hq" then
        local previousUnit = Wargroove.getUnitById(unit.loadedUnits[1])
        Wargroove.changeMoney(unit.playerId, getCost(previousUnit.unitClass.cost))
        Wargroove.removeUnit(previousUnit.id)
        Wargroove.waitFrame()
        Wargroove.clearCaches()
        table.remove(unit.loadedUnits, 1)
        unit:setGroove(0)
    end
end

function CancelRecruitment:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = false
end

return CancelRecruitment
