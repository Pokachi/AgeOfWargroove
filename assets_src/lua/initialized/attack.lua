local Wargroove = require "wargroove/wargroove"
local OriginalAttack = require "verbs/attack"
local Equipment = require "age_of_wargroove/equipment"

local Attack = {}

function Attack.init()
    OriginalAttack.getMaximumRange = Attack.getMaximumRange
end

function Attack:getMaximumRange(unit, endPos)
    local maxRange = 0
    
    Equipment.addBowForCommander(unit)

    for i, weapon in ipairs(unit.unitClass.weapons) do
        if weapon.canMoveAndAttack or endPos == nil or (endPos.x == unit.pos.x and endPos.y == unit.pos.y) then
            maxRange = math.max(maxRange, weapon.maxRange)
        end
    end

    if hasBow == false then
        maxRange = 1
    end

    return maxRange
end

return Attack
