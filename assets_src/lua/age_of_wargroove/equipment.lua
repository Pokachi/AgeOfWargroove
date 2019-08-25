local Wargroove = require "wargroove/wargroove"
local Equipment = {}


local attackerRandomMinModifier = {
    dagger = 0.03,
    rare_sword = 0.03
}

local attackerRandomMaxModifier = {
    axe = 0.03,
    rare_sword = 0.03
}

local attackerDamageModifier = {
    short_sword = 0.02,
    rare_sword = 0.02
}

local defenderRandomMinModifier = {
    armor = 0.03,
    rare_shield = 0.03
}

local defenderRandomMaxModifier = {
    helmet = 0.03,
    rare_shield = 0.03
}

local defenderDamageModifier = {
    shield = 0.02,
    rare_shield = 0.02
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

function Equipment.getDefenderRandomMinModifier(unitClass)
    if defenderRandomMinModifier[unitClass] ~= nil then
        return defenderRandomMinModifier[unitClass]
    end
    return 0
end

function Equipment.getDefenderRandomMaxModifier(unitClass)
    if defenderRandomMaxModifier[unitClass] ~= nil then
        return defenderRandomMaxModifier[unitClass]
    end
    return 0
end

function Equipment.getDefenderDamageModifier(unitClass)
    if defenderDamageModifier[unitClass] ~= nil then
        return defenderDamageModifier[unitClass]
    end
    return 0
end

local bowArtifactWeapon = {
  canMoveAndAttack = true,
  directionality = "omni",
  horizontalAndVerticalExtraWidth = 0,
  horizontalAndVerticalOnly = false,
  id = "commanderBow",
  maxRange = 3,
  minRange = 1
}

function Equipment.addBowForCommander(unit)
    --check if commander has bow, if so, add bow weapon to commander
    if unit.unitClass.isCommander then
        if unit.loadedUnits ~= nil and #unit.loadedUnits > 0 then
            for i, weaponId in ipairs(unit.loadedUnits) do
                local weapon = Wargroove.getUnitById(weaponId)
                if weapon.unitClassId == "bow" then
                    for i, loadedWeapons in ipairs(unit.unitClass.weapons) do
                        if loadedWeapons.id == "commanderBow" then
                            return
                        end
                    end
                    table.insert(unit.unitClass.weapons, bowArtifactWeapon)
                end
            end
        end
    end
end

return Equipment