local Verb = require "wargroove/verb"
local Wargroove = require "wargroove/wargroove"
local AI = require "age_of_wargroove/ai"

local WaitVillager = Verb:new()


function WaitVillager:getTargetType()
    return "empty"
end

function WaitVillager:canExecuteAnywhere(unit)
    return (not Wargroove.isHuman(unit.playerId))
end

function WaitVillager:execute(unit, targetPos, strParam, path)

end

function WaitVillager:generateOrders(unitId, canMove)
    return AI.waitVillagerOrders(unitId, canMove)
end

function WaitVillager:getScore(unitId, order)
    return AI.waitVillagerScore(unitId, order)
end

return WaitVillager