local Wargroove = require "wargroove/wargroove"
local Events = require "initialized/events"
local Leveling = require "age_of_wargroove/leveling"

local Conditions = {}

function Conditions.init()
  Events.addToConditionsList(Conditions)
end

function Conditions.populate(dst)
    -- Editor
    dst["experience"] = Conditions.experience
    dst["rank"] = Conditions.rank
    dst["on_load"] = Conditions.onLoad
end


local loaded = false
function Conditions.onLoad(context)
    if not loaded then
        loaded = true
        return true
    end
    return false
end

-- Editor conditions
function Conditions.experience(context)
    -- "Does {0} have {1} {2} of {3} at {4} with {5} {6} experience?"
    local operator = context:getOperator(1)
    local value = context:getInteger(2)
    local units = context:gatherUnits(0, 3, 4)
    local operator2 = context:getOperator(5)
    local value2 = context:getInteger(6)

    local nMatching = 0
    for i, unit in ipairs(units) do
        local experience = Leveling.getExperience(unit) or 0
        if operator2(tonumber(experience), value2) then
            nMatching = nMatching + 1
        end
    end

    return operator(nMatching, value)
end

function Conditions.rank(context)
    -- "Does {0} have {1} {2} of {3} at {4} with {5} {6} rank?"
    local operator = context:getOperator(1)
    local value = context:getInteger(2)
    local units = context:gatherUnits(0, 3, 4)
    local operator2 = context:getOperator(5)
    local value2 = context:getInteger(6)

    local nMatching = 0
    for i, unit in ipairs(units) do
        local rank = tonumber(Leveling.getRank(unit)) or 0
        if operator2(tonumber(rank), value2) then
            nMatching = nMatching + 1
        end
    end

    return operator(nMatching, value)
end

return Conditions
