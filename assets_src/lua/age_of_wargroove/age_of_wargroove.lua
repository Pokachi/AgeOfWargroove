local Events = require "wargroove/events"
local Wargroove = require "wargroove/wargroove"
local Constants = require "constants"

local AgeOfWargroove = {}

-- goldPos
--{
--    {
--        x,
--        y,
--        value
--    },
--    {
--        x,
--        y,
--        value
--    },
--    ...
--}

-- populationCap
--{
--    {
--        playerId,
--        cap
--    },
--    {
--        playerId,
--        cap
--    },
--    ...
--}

-- techLevel
--{
--    {
--        playerId,
--        currentLevel
--    },
--    {
--        playerId,
--        currentLevel
--    }
--}

local state = { goldPos = {}, populationCap = {}, techLevel = {}, maxPopulation = 100, maxTechLevel = 3 }

local inspect = require "inspect"

function AgeOfWargroove.spawnGlobalStateSoldier()
    local trigger = {}
    trigger.id =  "spawnInitialUnitTrigger"
    trigger.recurring = "start_of_match"
    trigger.players = { 1, 0, 0, 0, 0, 0, 0, 0 }
    trigger.conditions = {}
    trigger.actions = {}
    
    table.insert(trigger.actions, { id = "spawn_global_state_unit", parameters = { }  })
    
    return trigger

end

function AgeOfWargroove.getGlobalStateSoldier()
    return Wargroove.getUnitAt( Constants.globalStateUnitPos )
end

function AgeOfWargroove.generateGoldPerTurnFromPosTrigger(referenceTrigger)
    local trigger = {}
    trigger.id =  "generateGoldPerTurnFromPosMasterTrigger"
    trigger.recurring = "repeat"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    trigger.actions = {}
    
    table.insert(trigger.conditions, { id = "end_of_turn", parameters = { } })
    table.insert(trigger.actions, { id = "generate_gold_per_turn_from_pos", parameters = { "current" }  })
    
    return trigger

end

function AgeOfWargroove.drawTechLevelEffect(referenceTrigger)
    local trigger = {}
    trigger.id =  "drawTechLevelEffect"
    trigger.recurring = "repeat"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    trigger.actions = {}
    
    table.insert(trigger.actions, { id = "draw_tech_level_effect", parameters = { "current" }  })
    
    return trigger

end

function AgeOfWargroove.drawMiningCampIndicator(referenceTrigger)
    local trigger = {}
    trigger.id =  "drawMiningCampIndicator"
    trigger.recurring = "repeat"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    trigger.actions = {}
    
    table.insert(trigger.actions, { id = "draw_mining_camp_indicator", parameters = {  }  })
    
    return trigger

end

function AgeOfWargroove.getTechLevel(playerId)
    state.techLevel={}
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local techLevelString = Wargroove.getUnitState(globalStateUnit, "techLevel")

    if techLevelString ~= nil then
        state.techLevel = (loadstring or load)("return "..techLevelString)()
    end
    
    for i, techLevel in ipairs(state.techLevel) do
        if techLevel.playerId == playerId then
            return tonumber(techLevel.currentLevel)
        end
    end
    return 1
end

function AgeOfWargroove.setTechLevel(playerId, newLevel)   
    if newLevel > state.maxTechLevel then
        newLevel = 3
    end
    
    
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    
    for i, techLevel in ipairs(state.techLevel) do
        if techLevel.playerId == playerId then
            techLevel.currentLevel = newLevel
            Wargroove.setUnitState(globalStateUnit, "techLevel", inspect(state.techLevel))
            Wargroove.updateUnit(globalStateUnit)
            return
        end
    end
    
    local techLevel = { playerId = playerId, currentLevel = newLevel }
    table.insert(state.techLevel, techLevel)
    
    Wargroove.setUnitState(globalStateUnit, "techLevel", inspect(state.techLevel))
    Wargroove.updateUnit(globalStateUnit)
end

function AgeOfWargroove.setInitialTechLevel(referenceTrigger)
    local trigger = {}
    trigger.id =  "setInitialTechLevel"
    trigger.recurring = "oncePerPlayer"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    trigger.actions = {}
    table.insert(trigger.actions, { id = "set_tech_level", parameters = { "current", 1}  })
    
    return trigger
end

function AgeOfWargroove.getTurnRequirement(unitClass)
    if Constants.buildData[unitClass] ~= nil then
        return Constants.buildData[unitClass][1]
    end
    return 1
end

function AgeOfWargroove.getBuildProduct(unitClass)
    if Constants.buildData[unitClass] ~= nil then
        return Constants.buildData[unitClass][2]
    end
    return 1
end

function AgeOfWargroove.modifyUnitCapTrigger(referenceTrigger)
    local trigger = {}
    trigger.id =  "modifyPopulationCapAlways"
    trigger.recurring = "repeat"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    trigger.actions = {}
    table.insert(trigger.actions, { id = "modify_population_cap", parameters = { "current" }  })
    
    return trigger
end

function AgeOfWargroove.reportDeadVillageTrigger(referenceTrigger)
    local trigger = {}
    trigger.id =  "reportDeadVillages"
    trigger.recurring = "repeat"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    
    table.insert(trigger.conditions, { id = "unit_lost", parameters = { "*structure", "any", "-1" } })
    table.insert(trigger.conditions, { id = "player_turn", parameters = { "current" } })
    
    trigger.actions = {}
    
    table.insert(trigger.actions, { id = "report_dead_village", parameters = {} })
    
    return trigger
end

local LevelOneRecruits = {"soldier", "dog", "spearman", "wagon", "travelboat", "villager", "merman", "barracks_foundation", "city_foundation", "port_foundation", "water_city_foundation", "gold_camp"}
local LevelTwoRecruits = {"soldier", "dog", "spearman", "wagon", "archer", "mage", "knight", "turtle", "harpoonship", "balloon", "harpy", "travelboat", "villager", "merman", "barracks_foundation", "city_foundation", "port_foundation", "water_city_foundation", "hq_foundation", "tower_foundation", "gold_camp"}
local LevelThreeRecruits = {"soldier", "dog", "spearman", "wagon", "archer", "mage", "knight", "trebuchet", "ballista", "giant", "turtle", "harpoonship", "warship", "balloon", "harpy", "witch", "dragon", "travelboat", "villager", "merman", "barracks_foundation", "city_foundation", "port_foundation", "water_city_foundation", "hq_foundation", "tower_foundation", "gold_camp"}
local TechLevelCost = { 500, 1000, -1 }
local TechEffect = { "techLevel2", "techLevel3" }

function AgeOfWargroove.getTechLevelEffectName(techLevel)
    return TechEffect[techLevel - 1]
end

function AgeOfWargroove.getRecruitsAtTechLevel(techlevel)
    if tonumber(techlevel) == 1 then
        return LevelOneRecruits
    elseif tonumber(techlevel) == 2 then
        return LevelTwoRecruits
    else
        return LevelThreeRecruits
    end
end

function AgeOfWargroove.getTechUpCost(techlevel)
    return TechLevelCost[tonumber(techlevel)]
end

function AgeOfWargroove.getMaxTechLevel()
    return state.maxTechLevel
end

function AgeOfWargroove.getPopulationSizeForUnit(unitClass)
    return 1
end

function AgeOfWargroove.getCurrentPopulation(playerId)
    local currentPop = 0
    local allUnits = Wargroove.getAllUnitsForPlayer(playerId, true)
    for i, u in ipairs(allUnits) do
        if u.unitClass.isStructure == false and u.unitClassId ~= "crystal" and u.unitClassId ~= "drone" and u.unitClassId ~= "vine" then
            currentPop = currentPop + AgeOfWargroove.getPopulationSizeForUnit(u.unitClassId)
        end
    end
    
    return currentPop
end

function AgeOfWargroove.getPopulationCap(playerId)
    state.populationCap={}
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local popCapString = Wargroove.getUnitState(globalStateUnit, "populationCap")
    if popCapString ~= nil then
        state.populationCap = (loadstring or load)("return "..popCapString)()
    end
    
    for i, playerCap in ipairs(state.populationCap) do
        if playerCap.playerId == playerId then
            return playerCap.cap
        end
    end
    return 0
end

function AgeOfWargroove.setPopulationCap(playerId, newCap)    
    if newCap > state.maxPopulation then
        newCap = state.maxPopulation
    end
    
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    
    for i, playerCap in ipairs(state.populationCap) do
        if playerCap.playerId == playerId then
            playerCap.cap = newCap
            Wargroove.setUnitState(globalStateUnit, "populationCap", inspect(state.populationCap))
            Wargroove.updateUnit(globalStateUnit)
            return
        end
    end
    local playerCap = { playerId = playerId, cap = newCap }
    table.insert(state.populationCap, playerCap)
    
    Wargroove.setUnitState(globalStateUnit, "populationCap", inspect(state.populationCap))
    Wargroove.updateUnit(globalStateUnit)
end

function AgeOfWargroove.setInitialPopulationCap(referenceTrigger)
    local trigger = {}
    trigger.id =  "setInitialPopulationCap"
    trigger.recurring = "oncePerPlayer"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    trigger.actions = {}
    
    table.insert(trigger.actions, { id = "set_init_pop_cap", parameters = { "current" } })
    
    return trigger
end

function AgeOfWargroove.modifyDefeatHQTrigger(trigger)
    trigger.conditions = {}
    table.insert(trigger.conditions, { id = "unit_presence", parameters = { "current", "0", "0", "hq", "-1" } })
    return trigger
end

function AgeOfWargroove.getReportDeadMineCampTrigger()
    local trigger = {}
    trigger.id =  "reportDeadMineCamp"
    trigger.recurring = "repeat"
    trigger.players = {}
    for i = 1, 8, 1 do
        table.insert(trigger.players, 1)
    end
    trigger.conditions = {}
    
    table.insert(trigger.conditions, { id = "unit_killed", parameters = { "*unit", "current", "gold_camp", "any", "-1" } })
    table.insert(trigger.conditions, { id = "player_turn", parameters = { "current" } })
    
    trigger.actions = {}
    
    table.insert(trigger.actions, { id = "remove_generate_gold_per_turn_from_pos", parameters = {} })
    
    return trigger
end

function AgeOfWargroove.setGoldCount(targetPos, goldRemaining)
    
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    
    for i, pos in ipairs(state.goldPos) do
        if (pos.x == targetPos.x and pos.y == targetPos.y) then
            pos.value = goldRemaining
            Wargroove.setUnitState(globalStateUnit, "goldPos", inspect(state.goldPos))
            Wargroove.updateUnit(globalStateUnit)
            return
        end
    end
    local pos = { x = targetPos.x, y = targetPos.y, value = goldRemaining}
    table.insert(state.goldPos, pos)
    
    Wargroove.setUnitState(globalStateUnit, "goldPos", inspect(state.goldPos))
    Wargroove.updateUnit(globalStateUnit)
end

function AgeOfWargroove.getGoldCount(targetPos)
    state.goldPos={}
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local goldPosString = Wargroove.getUnitState(globalStateUnit, "goldPos")
    if goldPosString ~= nil then
        state.goldPos = (loadstring or load)("return "..goldPosString)()
    end
    
    for i, pos in ipairs(state.goldPos) do
        if (pos.x == targetPos.x and pos.y == targetPos.y) then
            return pos.value
        end
    end
    return 0
end

function AgeOfWargroove.getRecordedGoldPos()
    state.goldPos={}
    local globalStateUnit = Wargroove.getUnitAt( Constants.globalStateUnitPos )
    local goldPosString = Wargroove.getUnitState(globalStateUnit, "goldPos")
    if goldPosString ~= nil then
        state.goldPos = (loadstring or load)("return "..goldPosString)()
    end
    
    return state.goldPos
end

function AgeOfWargroove.modifyDDoorGroove()
    local trigger = {}
    trigger.id =  "DDoorGroove"
    trigger.recurring = "repeat"
    trigger.players = { 1, 0, 0, 0, 0, 0, 0, 0}
    trigger.conditions = {}
    
    table.insert(trigger.conditions, { id = "start_of_turn", parameters = {} })
    table.insert(trigger.conditions, { id = "player_turn", parameters = { "current" } })
    
    trigger.actions = {}
    table.insert(trigger.actions, { id = "modify_dimensional_door_groove", parameters = { } })
    
    return trigger
end

function AgeOfWargroove.generateGoldPerTurnFromPos(targetPos, playerId, goldPerTurn)
    local trigger = {}
    trigger.id =  tostring(targetPos.x) .. "-" .. tostring(targetPos.y) .. "generateGold"
    trigger.recurring = "repeat"
    trigger.players = {}
    for i = 1, 8, 1 do
        if i == playerId + 1 then
            table.insert(trigger.players, 1)
        else
            table.insert(trigger.players, 0)
        end
    end
    trigger.conditions = {}
    
    table.insert(trigger.conditions, { id = "start_of_turn", parameters = {} })
    table.insert(trigger.conditions, { id = "player_turn", parameters = { "current" } })
    
    trigger.actions = {}
    
    local goldLeft = AgeOfWargroove.getGoldCount(targetPos);
    
    if (goldLeft <= goldPerTurn) then
        table.insert(trigger.actions, { id = "modify_gold", parameters = { "current", "1", goldLeft } })
        table.insert(trigger.actions, { id = "modify_gold_at_pos", parameters = { targetPos.x, targetPos.y, 2, goldLeft } })
    else
        table.insert(trigger.actions, { id = "modify_gold", parameters = { "current", "1", goldPerTurn } })
        table.insert(trigger.actions, { id = "modify_gold_at_pos", parameters = { targetPos.x, targetPos.y, 2, goldPerTurn } })
    end
    
    Events.addTriggerToList(trigger)
    
end

function AgeOfWargroove.removeGoldGenerationFromPos(targetPos)
    local triggerId =  tostring(targetPos.x) .. "-" .. tostring(targetPos.y) .. "generateGold"
    Events.removeTriggerFromList(triggerId)
end

return AgeOfWargroove
