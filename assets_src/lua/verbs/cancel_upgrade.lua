local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Upgrades = require "age_of_wargroove/upgrades"


local CancelUpgrade = Verb:new()

function CancelUpgrade:canExecuteAnywhere(unit)
    return Upgrades.getWorkingUpgrade(unit.playerId, unit.id) ~= nil
end

function CancelUpgrade:execute(unit, targetPos, strParam, path)
    local upgrade = Upgrades.getWorkingUpgrade(unit.playerId, unit.id)
    local index = -1
    for i, val in ipairs(unit.loadedUnits) do
        if Wargroove.getUnitById(val).unitClassId == upgrade then
            index = i
            break
        end
    end
    if index ~= -1 then
        local previousUnit = Wargroove.getUnitById(unit.loadedUnits[index])
        Wargroove.changeMoney(unit.playerId, previousUnit.unitClass.cost)
        table.remove(unit.loadedUnits, index)
        previousUnit:setGroove(0)
        previousUnit.inTransport = false
        previousUnit.transportedBy = nil
        Wargroove.removeUnit(previousUnit.id)
        Wargroove.waitFrame()
        Wargroove.clearCaches()
        Wargroove.updateUnit(unit)
        Upgrades.setWorkingUpgrade(unit.playerId, unit.id, nil)
        if unit.unitClassId == "blacksmith" then
            Upgrades.addLandUpgrade(unit.playerId, upgrade)
        end
        if unit.unitClassId == "enchanting_tower" then
            Upgrades.addAirUpgrade(unit.playerId, upgrade)
        end
        if unit.unitClassId == "harbor" then
            Upgrades.addSeaUpgrade(unit.playerId, upgrade)
        end
        if unit.unitClassId == "monastery" then
            Upgrades.addPriestUpgrade(unit.playerId, upgrade)
        end
    end
end

function CancelUpgrade:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = false
end

return CancelUpgrade
