local Wargroove = require "wargroove/wargroove"
local AOW = require "age_of_wargroove/age_of_wargroove"
local Constants = require "constants"

local inspect = require "inspect"

local Upgrades = {}

local landUpgradesTable = {}

local landUpgradesWorkingTable = {}

local activeUpgrades = {}


function Upgrades.addActiveUpgrade(playerId, upgrade)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local activeUpgradesString = Wargroove.getUnitState(globalStateUnit, "activeUpgrades")
    if activeUpgradesString ~= nil then
        activeUpgrades = (loadstring or load)("return "..activeUpgradesString)()
    end
    if activeUpgrades[playerId] == nil then
        activeUpgrades[playerId] = {}
    end
    table.insert(activeUpgrades[playerId], upgrade)
    Wargroove.setUnitState(globalStateUnit, "activeUpgrades", inspect(activeUpgrades))
    Wargroove.updateUnit(globalStateUnit)
    
end

function Upgrades.getUpgradeDamageModifier(unit, defender)
    local unitClassId = unit.unitClassId
    local playerId = unit.playerId
    local upgrade = unitClassId .. "_upgrade"
    if Upgrades.hasUpgrade(playerId, upgrade) then
        if unitClassId == "archer" then
            return 0.05
        end
        if unitClassId == "balista" then
            return 0.07
        end
        if unitClassId == "trebuchet" and defender.unitClass.weapons[1] ~= nil then
            local weapon = Wargroove.getWeapon(defender.unitClass.weapons[1], defender.unitClassId)
            if weapon.minRange == 1 and weapon.maxRange == 1 then
                return 0.1
            end
            return 0
        end
    end
    return 0
end

function Upgrades.getUpgradeDefenseModifier(unit, attacker)
    local unitClassId = unit.unitClass.id
    local playerId = unit.playerId
    local upgrade = unitClassId .. "_upgrade"
    if Upgrades.hasUpgrade(playerId, upgrade) then
        if unitClassId == "knight" and attacker.unitClass.weapons[1] ~= nil then
            local weapon = Wargroove.getWeapon(attacker.unitClass.weapons[1].id, attacker.unitClassId)
            if weapon.minRange  > 1 or weapon.maxRange > 1 then
                return 0.1
            end
            return 0
        end
    end
    return 0
end

function Upgrades.getUpgradeTerrainDefenseModifier(unit)
    local unitClassId = unit.unitClass.id
    local playerId = unit.playerId
    local upgrade = unitClassId .. "_upgrade"
    if Upgrades.hasUpgrade(playerId, upgrade) then
        if unitClassId == "giant" then
            return math.floor(Wargroove.getTerrainDefenceAt(unit.pos)* 0.5 + 0.5)
        end
    end
    return 0
end

function Upgrades.hasUpgrade(playerId, upgrade)
    if activeUpgrades[playerId] ~= nil then
        for i, up in ipairs(activeUpgrades[playerId]) do
            if up == upgrade then
                return true
            end
        end
    end
    return false
end

function Upgrades.getActiveUpgrades(playerId)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local activeUpgradesString = Wargroove.getUnitState(globalStateUnit, "activeUpgrades")
    if activeUpgradesString ~= nil then
        activeUpgrades = (loadstring or load)("return "..activeUpgradesString)()
    end
    return activeUpgrades
end

function Upgrades.getLandUpgrades(playerId)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local landUpgradesString = Wargroove.getUnitState(globalStateUnit, "landUpgrades")
    if landUpgradesString ~= nil then
        landUpgradesTable = (loadstring or load)("return "..landUpgradesString)()
    end
    if landUpgradesTable[playerId] == nil then
        landUpgradesTable[playerId] = Constants.allLandUpgrades
        Wargroove.setUnitState(globalStateUnit, "landUpgrades", inspect(landUpgradesTable))
        Wargroove.updateUnit(globalStateUnit)
        return Constants.allLandUpgrades
    end
    
    return landUpgradesTable[playerId]
end

function Upgrades.removeLandUpgrade(playerId, index)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local landUpgradesString = Wargroove.getUnitState(globalStateUnit, "landUpgrades")
    if landUpgradesString ~= nil then
        landUpgradesTable = (loadstring or load)("return "..landUpgradesString)()
    end
    if landUpgradesTable[playerId] == nil then
        landUpgradesTable[playerId] = Constants.allLandUpgrades
    end
    table.remove(landUpgradesTable[playerId], index)
    Wargroove.setUnitState(globalStateUnit, "landUpgrades", inspect(landUpgradesTable))
    Wargroove.updateUnit(globalStateUnit)
    
end

function Upgrades.addLandUpgrade(playerId, upgrade)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local landUpgradesString = Wargroove.getUnitState(globalStateUnit, "landUpgrades")
    if landUpgradesString ~= nil then
        landUpgradesTable = (loadstring or load)("return "..landUpgradesString)()
    end
    if landUpgradesTable[playerId] == nil then
        landUpgradesTable[playerId] = Constants.allLandUpgrades
    else
        table.insert(landUpgradesTable[playerId], upgrade)
    end
    Wargroove.setUnitState(globalStateUnit, "landUpgrades", inspect(landUpgradesTable))
    Wargroove.updateUnit(globalStateUnit)
    
end

function Upgrades.setWorkingUpgrade(playerId, blacksmithId, upgrade)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local landUpgradesWorkingString = Wargroove.getUnitState(globalStateUnit, "landWorkingUpgrades")
    if landUpgradesWorkingString ~= nil then
        landUpgradesWorkingTable = (loadstring or load)("return "..landUpgradesWorkingString)()
    end
    if landUpgradesWorkingTable[playerId] == nil then
        landUpgradesWorkingTable[playerId] = {}
    end
    landUpgradesWorkingTable[playerId][blacksmithId] = upgrade
    for i, up in ipairs(landUpgradesTable[playerId]) do
        if upgrade == up then
            Upgrades.removeLandUpgrade(playerId, i)
            break;
        end
    end
    Wargroove.setUnitState(globalStateUnit, "landWorkingUpgrades", inspect(landUpgradesWorkingTable))
    Wargroove.updateUnit(globalStateUnit)
end

function Upgrades.getWorkingUpgrade(playerId, blacksmithId)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local landUpgradesWorkingString = Wargroove.getUnitState(globalStateUnit, "landWorkingUpgrades")
    if landUpgradesWorkingString ~= nil then
        landUpgradesWorkingTable = (loadstring or load)("return "..landUpgradesWorkingString)()
    end
    if landUpgradesWorkingTable[playerId] == nil then
        landUpgradesWorkingTable[playerId] = {}
    end
    return landUpgradesWorkingTable[playerId][blacksmithId]
end

function Upgrades.modifyUpgradeGroove(referenceTrigger)
    local trigger = {}
    trigger.id =  "UpgradeGroove"
    trigger.recurring = "repeat"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    
    table.insert(trigger.conditions, { id = "start_of_turn", parameters = {} })
    table.insert(trigger.conditions, { id = "player_turn", parameters = { "current" } })
    
    trigger.actions = {}
    table.insert(trigger.actions, { id = "modify_upgrade_groove", parameters = { "current" } })
    
    return trigger
end

function Upgrades.modifyUpgradeIndicators(referenceTrigger)
    local trigger = {}
    trigger.id =  "UpgradeIndicator"
    trigger.recurring = "repeat"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    
    table.insert(trigger.conditions, { id = "unit_presence", parameters = { "current", "1", "0", "blacksmith", "-1" } })
    
    trigger.actions = {}
    table.insert(trigger.actions, { id = "modify_upgrade_indicator", parameters = { "current" } })
    
    return trigger
end

return Upgrades