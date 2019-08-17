local Wargroove = require "wargroove/wargroove"
local OriginalSpellHeall = require "verbs/spell_heal"

local SpellHeal = {}

local healAmount = 20

function SpellHeal.init()
    OriginalSpellHeall.canExecuteAnywhere = SpellHeal.canExecuteAnywhere
    OriginalSpellHeall.getCostAt = SpellHeal.getCostAt
    OriginalSpellHeall.execute = SpellHeal.execute
end

function SpellHeal:canExecuteAnywhere(unit)
    return true
end


function SpellHeal:getCostAt(unit, endPos, targetPos)
    return 0
end


function SpellHeal:execute(unit, targetPos, strParam, path)
    local targets = Wargroove.getTargetsInRange(targetPos, 1, "unit")

    local function distFromTarget(a)
        return math.abs(a.x - targetPos.x) + math.abs(a.y - targetPos.y)
    end
    table.sort(targets, function(a, b) return distFromTarget(a) < distFromTarget(b) end)

    Wargroove.spawnMapAnimation(targetPos, 1, "fx/heal_spell", "idle", "over_units", {x = 11, y = 11})
    Wargroove.playMapSound("mageSpell", targetPos)
    Wargroove.waitTime(0.7)

    for i, pos in ipairs(targets) do
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil then
            local uc = u.unitClass
            if Wargroove.areAllies(u.playerId, unit.playerId) and (not uc.isStructure) then
                Wargroove.playMapSound("unitHealed", pos)
                u:setHealth(u.health + healAmount, unit.id)
                Wargroove.updateUnit(u)
                Wargroove.spawnMapAnimation(pos, 0, "fx/heal_unit")
                Wargroove.waitTime(0.2)
            end
        end
    end
    Wargroove.waitTime(0.3)
end

return SpellHeal
