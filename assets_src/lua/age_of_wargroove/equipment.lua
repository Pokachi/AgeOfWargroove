local Equipment = {}


local attackerRandomMinModifier = {
    dagger = 0.03
}

local attackerRandomMaxModifier = {
    axe = 0.03
}

local attackerDamageModifier = {
    short_sword = 0.02
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

function Equipment.getAttackerDamageModifier(unitClass)
    if attackerDamageModifier[unitClass] ~= nil then
        return attackerDamageModifier[unitClass]
    end
    return 0
end

return Equipment