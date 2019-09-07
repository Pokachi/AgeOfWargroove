local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local Constants = require "constants"

local Salvage = Verb:new()

function Salvage:getMaximumRange(unit, endPos)
    return 1
end

function Salvage:getTargetType()
    return "unit"
end

function Salvage:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local u = Wargroove.getUnitAt(targetPos)
    
    if u ~= nil and Wargroove.areAllies(unit.playerId, u.playerId) then
        for i, tag in ipairs(u.unitClass.tags) do
            if tag == "salvageable" then
                return true
            end
        end
    end
    
    return false
end

function Salvage:execute(unit, targetPos, strParam, path)
    local u = Wargroove.getUnitAt(targetPos)
    
    local goldGain = math.floor(u.unitClass.cost * u.health * 0.01 * Constants.salvageValueReturn + 0.5)
    
    u:setHealth(0, -1)     
    
    Wargroove.updateUnit(u)
    Wargroove.changeMoney(unit.playerId, goldGain)
    
end

return Salvage