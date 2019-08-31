local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local AOW = require "age_of_wargroove/age_of_wargroove"
local Constants = require "constants"
local inspect = require "inspect"

local Salvage = Verb:new()

function Salvage:getMaximumRange(unit, endPos)
    return 1
end

function Salvage:getTargetType()
    return "unit"
end

-- maybe only allow own buildings to be salvaged?
function Salvage:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local u = Wargroove.getUnitAt(targetPos)
    
    if u ~= nil and Wargroove.areAllies(unit.playerId, u.playerId) then
        for i, unitClassId in ipairs(Constants.salvageables) do
            if u.unitClassId == unitClassId then                
                return true
            end
        end
    end
    
    return false
end

function Salvage:execute(unit, targetPos, strParam, path)
    local u = Wargroove.getUnitAt(targetPos)
    
    local goldGain = u.unitClass.cost * u.health * 0.01 * Constants.salvageValueReturn
    
    --Wargroove.removeUnit(u.id)
    u:setHealth(0, -1)    
    --Wargroove.waitFrame()
    --Wargroove.clearCaches()    
    
    Wargroove.updateUnit(u)
    Wargroove.changeMoney(unit.playerId, goldGain)
    
end

--function Salvage:onPostUpdateUnit(unit, targetPos, strParam, path)
--    print(inspect(Wargroove.getAllUnitsForPlayer(unit.playerId, true)))
--end

return Salvage