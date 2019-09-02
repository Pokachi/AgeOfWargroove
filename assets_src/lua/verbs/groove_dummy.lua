local Wargroove = require "wargroove/wargroove"
local GrooveVerb = require "wargroove/groove_verb"

local DummyGroove = GrooveVerb:new()


function DummyGroove:getMaximumRange(unit, endPos)
    return 1
end


function DummyGroove:getTargetType()
    return "empty"
end


function DummyGroove:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    return false
end


function DummyGroove:execute(unit, targetPos, strParam, path)
    
end

function DummyGroove:generateOrders(unitId, canMove)
    return {}
end

function DummyGroove:getScore(unitId, order)
    return {score = 0, introspection = {}}
end

return DummyGroove
