local Equipment = {}


local attackerRandomMinModifier = {
    short_sword = 0.03
}

local attackerRandomMaxModifier = {
}

function Equipment.getAttackerRandomMinModifier(unitClass)
    if attackerRandomMinModifier[unitClass] ~= nil then
        return attackerRandomMinModifier[unitClass]
    end
    return 0
end

function Equipment.getAttackerRandomMaxModifier(unitClass)
    if attackerRandomMaxModifier[unitClass] ~= nil then
        return attackerRandomMaxModifier[unitClass]
    end
    return 0
end

return Equipment