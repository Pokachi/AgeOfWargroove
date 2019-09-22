local Wargroove = require "wargroove/wargroove"
local AOW = require "age_of_wargroove/age_of_wargroove"
local Constants = require "constants"

local inspect = require "inspect"

local Upgrades = {}

local landUpgradesTable = {}
local landUpgradesWorkingTable = {}

local seaUpgradesTable = {}
local seaUpgradesWorkingTable = {}

local airUpgradesTable = {}
local airUpgradesWorkingTable = {}

local priestUpgradesTable = {}
local priestUpgradesWorkingTable = {}

local activeUpgrades = {}


-- Sets an active upgrade for any building for a given player
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
    return 0
end

function Upgrades.getUpgradeDefenseModifier(unit, attacker)
    local unitClassId = unit.unitClass.id
    local playerId = unit.playerId
    return 0
end

function Upgrades.getUpgradeTerrainDefenseModifier(unit)
    local unitClassId = unit.unitClass.id
    local playerId = unit.playerId
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
-- Gets all active upgrades for every building for a given player
function Upgrades.getActiveUpgrades(playerId)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local activeUpgradesString = Wargroove.getUnitState(globalStateUnit, "activeUpgrades")
    if activeUpgradesString ~= nil then
        activeUpgrades = (loadstring or load)("return "..activeUpgradesString)()
    end
    return activeUpgrades
end

-- Get all the priest based upgrades that player has NOT researched yet
function Upgrades.getPriestUpgrades(playerId)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local upgradesString = Wargroove.getUnitState(globalStateUnit, "priestUpgrades")
    if upgradesString ~= nil then
        priestUpgradesTable = (loadstring or load)("return "..upgradesString)()
    end
    if priestUpgradesTable[playerId] == nil then
        priestUpgradesTable[playerId] = Constants.allPriestUpgrades
        Wargroove.setUnitState(globalStateUnit, "priestUpgrades", inspect(priestUpgradesTable))
        Wargroove.updateUnit(globalStateUnit)
        return Constants.allPriestUpgrades
    end
    
    return priestUpgradesTable[playerId]
end
-- Remove a priest upgrades that player has NOT researched yet from the list (used by setWorkingUpgrade)
function Upgrades.removePriestUpgrade(playerId, index)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local upgradesString = Wargroove.getUnitState(globalStateUnit, "priestUpgrades")
    if upgradesString ~= nil then
        priestUpgradesTable = (loadstring or load)("return "..upgradesString)()
    end
    if priestUpgradesTable[playerId] == nil then
        priestUpgradesTable[playerId] = Constants.allPriestUpgrades
    end
    table.remove(priestUpgradesTable[playerId], index)
    Wargroove.setUnitState(globalStateUnit, "priestUpgrades", inspect(priestUpgradesTable))
    Wargroove.updateUnit(globalStateUnit)
    
end
-- Add a priest upgrade that player has NOT researched yet to the list (Could be used by a cancel verb)
function Upgrades.addPriestUpgrade(playerId, upgrade)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local upgradesString = Wargroove.getUnitState(globalStateUnit, "priestUpgrades")
    if upgradesString ~= nil then
        priestUpgradesTable = (loadstring or load)("return "..upgradesString)()
    end
    if priestUpgradesTable[playerId] == nil then
        priestUpgradesTable[playerId] = Constants.allPriestUpgrades
    else
        table.insert(priestUpgradesTable[playerId], upgrade)
    end
    Wargroove.setUnitState(globalStateUnit, "priestUpgrades", inspect(priestUpgradesTable))
    Wargroove.updateUnit(globalStateUnit)
    
end

-- Get all the air based upgrades that player has NOT researched yet
function Upgrades.getAirUpgrades(playerId)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local upgradesString = Wargroove.getUnitState(globalStateUnit, "airUpgrades")
    if upgradesString ~= nil then
        priestUpgradesTable = (loadstring or load)("return "..upgradesString)()
    end
    if priestUpgradesTable[playerId] == nil then
        priestUpgradesTable[playerId] = Constants.allPriestUpgrades
        Wargroove.setUnitState(globalStateUnit, "airUpgrades", inspect(priestUpgradesTable))
        Wargroove.updateUnit(globalStateUnit)
        return Constants.allPriestUpgrades
    end
    
    return airUpgradesTable[playerId]
end
-- Remove an air based upgrade that player has NOT researched yet from the list (used by setWorkingUpgrade)
function Upgrades.removeAirUpgrade(playerId, index)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local upgradesString = Wargroove.getUnitState(globalStateUnit, "airUpgrades")
    if upgradesString ~= nil then
        airUpgradesTable = (loadstring or load)("return "..upgradesString)()
    end
    if airUpgradesTable[playerId] == nil then
        airUpgradesTable[playerId] = Constants.allAirUpgrades
    end
    table.remove(airUpgradesTable[playerId], index)
    Wargroove.setUnitState(globalStateUnit, "airUpgrades", inspect(airUpgradesTable))
    Wargroove.updateUnit(globalStateUnit)
    
end
-- Add a air upgrade that player has NOT researched yet to the list (Could be used by a cancel verb)
function Upgrades.addAirUpgrade(playerId, upgrade)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local upgradesString = Wargroove.getUnitState(globalStateUnit, "airUpgrades")
    if upgradesString ~= nil then
        airUpgradesTable = (loadstring or load)("return "..upgradesString)()
    end
    if airUpgradesTable[playerId] == nil then
        airUpgradesTable[playerId] = Constants.allAirUpgrades
    else
        table.insert(airUpgradesTable[playerId], upgrade)
    end
    Wargroove.setUnitState(globalStateUnit, "airUpgrades", inspect(airUpgradesTable))
    Wargroove.updateUnit(globalStateUnit)
    
end
-- Get all the sea based upgrades that player has NOT researched yet
function Upgrades.getSeaUpgrades(playerId)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local upgradesString = Wargroove.getUnitState(globalStateUnit, "seaUpgrades")
    if upgradesString ~= nil then
        seaUpgradesTable = (loadstring or load)("return "..upgradesString)()
    end
    if seaUpgradesTable[playerId] == nil then
        seaUpgradesTable[playerId] = Constants.allSeaUpgrades
        Wargroove.setUnitState(globalStateUnit, "seaUpgrades", inspect(seaUpgradesTable))
        Wargroove.updateUnit(globalStateUnit)
        return Constants.allSeaUpgrades
    end
    
    return seaUpgradesTable[playerId]
end
-- Remove a sea based upgrade that player has NOT researched yet from the list (used by setWorkingUpgrade)
function Upgrades.removeSeaUpgrade(playerId, index)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local upgradesString = Wargroove.getUnitState(globalStateUnit, "seaUpgrades")
    if upgradesString ~= nil then
        seaUpgradesTable = (loadstring or load)("return "..upgradesString)()
    end
    if seaUpgradesTable[playerId] == nil then
        seaUpgradesTable[playerId] = Constants.allSeaUpgrades
    end
    table.remove(seaUpgradesTable[playerId], index)
    Wargroove.setUnitState(globalStateUnit, "seaUpgrades", inspect(seaUpgradesTable))
    Wargroove.updateUnit(globalStateUnit)
    
end
-- Add a sea upgrade that player has NOT researched yet to the list (Could be used by a cancel verb)
function Upgrades.addSeaUpgrade(playerId, upgrade)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local upgradesString = Wargroove.getUnitState(globalStateUnit, "seaUpgrades")
    if upgradesString ~= nil then
        seaUpgradesTable = (loadstring or load)("return "..upgradesString)()
    end
    if seaUpgradesTable[playerId] == nil then
        seaUpgradesTable[playerId] = Constants.allSeaUpgrades
    else
        table.insert(seaUpgradesTable[playerId], upgrade)
    end
    Wargroove.setUnitState(globalStateUnit, "seaUpgrades", inspect(seaUpgradesTable))
    Wargroove.updateUnit(globalStateUnit)
    
end
-- Get all the land (blacksmith) based upgrades that player has NOT researched yet
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
-- Remove a land based upgrade that player has NOT researched yet from the list (used by setWorkingUpgrade)
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
-- Add a land based upgrade that player has NOT researched yet to the list (Could be used by a cancel verb)
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
-- Sets the upgrade that a structure is working on
function Upgrades.setWorkingUpgrade(playerId, structureId, upgrade)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local landUpgradesWorkingString = Wargroove.getUnitState(globalStateUnit, "landWorkingUpgrades")
    if landUpgradesWorkingString ~= nil then
        landUpgradesWorkingTable = (loadstring or load)("return "..landUpgradesWorkingString)()
    end
    if landUpgradesWorkingTable[playerId] == nil then
        landUpgradesWorkingTable[playerId] = {}
    end
    landUpgradesWorkingTable[playerId][structureId] = upgrade
    for i, up in ipairs(landUpgradesTable[playerId]) do
        if upgrade == up then
            Upgrades.removeLandUpgrade(playerId, i)
            break;
        end
    end
    Wargroove.setUnitState(globalStateUnit, "landWorkingUpgrades", inspect(landUpgradesWorkingTable))
    Wargroove.updateUnit(globalStateUnit)
end
-- Gets the upgrade that a structure is working on
function Upgrades.getWorkingUpgrade(playerId, structureId)
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local landUpgradesWorkingString = Wargroove.getUnitState(globalStateUnit, "landWorkingUpgrades")
    if landUpgradesWorkingString ~= nil then
        landUpgradesWorkingTable = (loadstring or load)("return "..landUpgradesWorkingString)()
    end
    if landUpgradesWorkingTable[playerId] == nil then
        landUpgradesWorkingTable[playerId] = {}
    end
    return landUpgradesWorkingTable[playerId][structureId]
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

function Upgrades.reportDeadUpgradeTrigger(referenceTrigger)
    local trigger = {}
    trigger.id =  "reportDeadBlacksmith"
    trigger.recurring = "repeat"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    
    table.insert(trigger.conditions, { id = "unit_killed", parameters = { "*unit", "current", "blacksmith", "any", "-1" } })
    table.insert(trigger.conditions, { id = "player_turn", parameters = { "current" } })
    
    trigger.actions = {}
    
    table.insert(trigger.actions, { id = "upgrade_death_cancel_upgrade", parameters = {"current"} })
    
    return trigger
end

return Upgrades