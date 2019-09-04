local AOW = require "age_of_wargroove/age_of_wargroove"
local Upgrades = require "age_of_wargroove/upgrades"
local Events = require "initialized/events"
local Leveling = require "age_of_wargroove/leveling"
local Wargroove = require "wargroove/wargroove"
local AI = require "age_of_wargroove/ai"
local Constants = require "constants"

local inspect = require "inspect"

local Actions = {}

local pop_animation_initalized = { false, false, false, false, false, false, false, false }
local tech_animation_initalized = { false, false, false, false, false, false, false, false }
local gold_animation_initialized = false

-- This is called by the game when the map is loaded.
function Actions.init()
  Events.addToActionsList(Actions)
end

function Actions.populate(dst)
    dst["modify_gold_at_pos"] = Actions.modifyGoldAtPos
    dst["remove_generate_gold_per_turn_from_pos"] = Actions.removeGenerateGoldPerTurnFromPos
    dst["generate_gold_per_turn_from_pos"] = Actions.generateGoldPerTurnFromPosAction
    dst["set_tech_level"] = Actions.setTechLevel
    dst["spawn_global_state_unit"] = Actions.spawnGlobalStateUnit
    dst["draw_tech_level_effect"] = Actions.drawTechLevelEffect
    dst["draw_mining_camp_indicator"] = Actions.drawMiningCampIndicator
    dst["set_init_pop_cap"] = Actions.setInitialPopulationCap
    dst["modify_population_cap"] = Actions.modifyCurrentPopulation
    dst["report_dead_village"] = Actions.reportDeadVillage
    dst["modify_ai_globals"] = Actions.modifyAIGlobals
    dst["setup_ai_heatmap"] = Actions.setupAIHeatMap
    dst["modify_dimensional_door_groove"] = Actions.modifyDimensionalDoorGroove
    dst["modify_upgrade_groove"] = Actions.modifyUpgradeGroove
    dst["modify_upgrade_indicator"] = Actions.modifyUpgradeIndicators
    dst["redraw_unit_ranks"] = Actions.redrawUnitRanks
    
    -- Editor
    dst["modify_experience"] = Actions.modifyExperience
    dst["modify_rank"] = Actions.modifyRank
end

function Actions.modifyUpgradeGroove(context)
    local playerId = context:getPlayerId(0)
    
    local allUnits = Wargroove.getAllUnitsForPlayer(playerId, true)
    for i, u in ipairs(allUnits) do
        if u.unitClassId == "blacksmith" then
            local upgrade = Upgrades.getWorkingUpgrade(playerId, u.id)
            if upgrade ~= nil then
                if u.grooveCharge < 5 then
                    local newGrooveCharge = u.grooveCharge + 1
                    u.grooveCharge = newGrooveCharge
                    if newGrooveCharge >= 2 then
                        Upgrades.addActiveUpgrade(playerId, upgrade)
                        Upgrades.setWorkingUpgrade(playerId, u.id, nil)
                        u.grooveCharge = 0
                    end
                    Wargroove.updateUnit(u)
                end
            end
        end
    end
end

function Actions.modifyAIGlobals(context)
    local playerId = context:getPlayerId(0)
    AI.updateAIGlobals(playerId)
end

function Actions.setupAIHeatMap(context)
    local playerId = context:getPlayerId(0)
    AI.setupAIHeatMap(playerId)
end

function Actions.reportDeadVillage(context)
    for i, u in ipairs(context.deadUnits) do
        if u.unitClassId == "city" or u.unitClassId == "water_city" then
            AOW.setPopulationCap(u.playerId, AOW.getPopulationCap(u.playerId) - Constants.populationPerVillage)
        elseif u.unitClassId == "hq" then
            AOW.setPopulationCap(u.playerId, AOW.getPopulationCap(u.playerId) - Constants.populationPerHQ)
        end
    end
end

function Actions.modifyUpgradeIndicators(context)
    local playerId = context:getPlayerId(0)
    
    local allUnits = Wargroove.getAllUnitsForPlayer(playerId, true)
    for i, u in ipairs(allUnits) do
        if u ~= nil and u.unitClassId == "blacksmith" then
            for j, up in ipairs(Constants.allLandUpgrades) do
            
                local unitLoaded = false
                local loaded = nil
                for k, l in ipairs(u.loadedUnits) do
                    loaded = Wargroove.getUnitById(l)
                    if loaded.unitClassId == up then
                        unitLoaded = true
                        break
                    end
                end
                if Upgrades.hasUpgrade(u.playerId, up) then
                    if (not unitLoaded) then
                        Wargroove.spawnUnit(-1, { x = -91, y = -12 }, up, true, "")
                        Wargroove.waitFrame()
                        local upgradeUnit = Wargroove.getUnitAt({ x = -91, y = -12 })
                        upgradeUnit.pos = { x = -99, y = -99 }
                        upgradeUnit:setGroove(1, -1)
                        table.insert(u.loadedUnits, upgradeUnit.id)
                        upgradeUnit.inTransport = true
                        upgradeUnit.transportedBy = u.id
                        Wargroove.updateUnit(upgradeUnit)
                        Wargroove.updateUnit(u)
                    else
                        loaded:setGroove(1, -1)
                        Wargroove.updateUnit(loaded)
                        Wargroove.updateUnit(u)
                    end
                end
                
                if Upgrades.getWorkingUpgrade(u.playerId, u.id) == up and (not unitLoaded) then
                    Wargroove.spawnUnit(-1, { x = -91, y = -12 }, up, true, "")
                    Wargroove.waitFrame()
                    local upgradeUnit = Wargroove.getUnitAt({ x = -91, y = -12 })
                    upgradeUnit.pos = { x = -99, y = -99 }
                    upgradeUnit:setGroove(0, -1)
                    table.insert(u.loadedUnits, upgradeUnit.id)
                    upgradeUnit.inTransport = true
                    upgradeUnit.transportedBy = u.id
                    Wargroove.updateUnit(upgradeUnit)
                    Wargroove.updateUnit(u)
                end
            end
            -- if #u.loadedUnits == 0 then
                -- for j, up in ipairs(Constants.allLandUpgrades) do
                    -- Wargroove.spawnUnit(-1, { x = -91, y = -12 }, up, true, "")
                    -- Wargroove.waitFrame()
                    -- local upgradeUnit = Wargroove.getUnitAt({ x = -91, y = -12 })
                    -- upgradeUnit.pos = { x = -99, y = -99 }
                    -- if Upgrades.hasUpgrade(u.playerId, up) then
                        -- upgradeUnit:setGroove(1, -1)
                    -- else
                        -- upgradeUnit:setGroove(0, -1)
                    -- end
                    -- table.insert(u.loadedUnits, upgradeUnit.id)
                    -- upgradeUnit.inTransport = true
                    -- upgradeUnit.transportedBy = u.id
                    -- Wargroove.updateUnit(upgradeUnit)
                    -- Wargroove.updateUnit(u)
                -- end
            -- else
                -- for j, l in ipairs(u.loadedUnits) do
                    -- local loaded = Wargroove.getUnitById(l)
                    -- if Upgrades.hasUpgrade(u.playerId, loaded.unitClassId) then
                        -- loaded:setGroove(1, -1)
                    -- else
                        -- loaded:setGroove(0, -1)
                        -- if Upgrades.getWorkingUpgrade(u.playerId, u.id) == loaded.unitClassId then
                            -- loaded:setHealth(100, -1)
                        -- else
                            -- loaded:setHealth(1, -1)
                        -- end
                    -- end
                    -- Wargroove.updateUnit(loaded)
                    -- Wargroove.updateUnit(u)
                -- end
            -- end
        end
    end
end

function Actions.modifyCurrentPopulation(context)
    local playerId = context:getPlayerId(0)
    
    local allUnits = Wargroove.getAllUnitsForPlayer(playerId, true)
    
    local popCap = AOW.getPopulationCap(playerId)
    local currentPop = AOW.getCurrentPopulation(playerId)
    
    for i, u in ipairs(allUnits) do
        
        if u.unitClassId == "hq" or u.unitClassId == "city" or u.unitClassId == "water_city" then
        
            local warningEffectId = Wargroove.getUnitState(u, "warningEffect")
            if warningEffectId ~= nil and warningEffectId ~= "" and pop_animation_initalized[playerId + 1] then
                Wargroove.deleteUnitEffect(warningEffectId, "")
                Wargroove.setUnitState(u, "warningEffect", "")
                Wargroove.updateUnit(u)
            end
            
            -- draw indicator
            if popCap - currentPop < 4 and popCap - currentPop > 0 then
                local effectId = Wargroove.spawnUnitEffect(u.id, "units/fx/warning", "warn", "", true)
                Wargroove.setUnitState(u, "warningEffect", effectId)
                Wargroove.updateUnit(u)
            elseif popCap <= currentPop then
                local effectId = Wargroove.spawnUnitEffect(u.id, "units/fx/warning", "critical", "", true)
                Wargroove.setUnitState(u, "warningEffect", effectId)
                Wargroove.updateUnit(u)
            end
            
            if #u.loadedUnits > 0 then
                local popCapUnit = Wargroove.getUnitById(u.loadedUnits[1])
                popCapUnit:setHealth(popCap, -1)
                popCapUnit:setGroove(currentPop, -1)
                Wargroove.updateUnit(popCapUnit)
            else
                Wargroove.spawnUnit(-1, { x = -91, y = -12 }, "population_indicator", true, "")
                Wargroove.waitFrame()
                local popCapUnit = Wargroove.getUnitAt({ x = -91, y = -12 })
                popCapUnit.pos = { x = -99, y = -99 }
                popCapUnit:setHealth(popCap, -1)
                popCapUnit:setGroove(currentPop, -1)
                table.insert(u.loadedUnits, popCapUnit.id)
                popCapUnit.inTransport = true
                popCapUnit.transportedBy = u.id
                Wargroove.updateUnit(popCapUnit)
                Wargroove.updateUnit(u)
            end
                
        end
    end
    pop_animation_initalized[playerId + 1] = true
end

function Actions.modifyDimensionalDoorGroove(context)
    
    local allUnits = Wargroove.getAllUnitsForPlayer(-2, true)
    
    for i, u in ipairs(allUnits) do
        
        if u.unitClassId == "dimensional_door" then
            if u.grooveCharge < 5 then
                u.grooveCharge = u.grooveCharge + 1
                Wargroove.updateUnit(u)
            end 
        end
    end
end

function Actions.setInitialPopulationCap(context)
    local playerId = context:getPlayerId(0)
    
    local allUnits = Wargroove.getAllUnitsForPlayer(playerId, true)
    
    local popCap = 0;
    
    for i, u in ipairs(allUnits) do
        if u.unitClassId == "hq" then
            popCap = popCap + Constants.populationPerHQ
        elseif u.unitClassId == "city" or u.unitClassId == "water_city" then
            popCap = popCap + Constants.populationPerVillage
        end
    end
    
    AOW.setPopulationCap(playerId, popCap)
    
end

function Actions.generateGoldPerTurnFromPosAction(context)
    local playerId = context:getPlayerId(0)
    
    local allUnits = Wargroove.getAllUnitsForPlayer(playerId, true)
    for i, u in ipairs(allUnits) do
        if u.unitClassId == "gold_camp" then
            if #u.loadedUnits > 0 then
                local firstUnit = Wargroove.getUnitById(u.loadedUnits[1])
                if firstUnit.unitClassId == "gold" then
                    local numberOfMiners = #u.loadedUnits - 1
                    if numberOfMiners > 0 then
                        AOW.generateGoldPerTurnFromPos(u.pos, u.playerId, numberOfMiners * Constants.goldPerTurnPerMine)
                    end
                elseif firstUnit.unitClassId == "gem" then
                    local numberOfMiners = #u.loadedUnits - 1
                    if numberOfMiners > 0 then
                        AOW.generateGoldPerTurnFromPos(u.pos, u.playerId, numberOfMiners * Constants.gemPerTurnPerMine)
                    end
                end
            end
        end
    end
end

function Actions.drawTechLevelEffect(context)
    local playerId = context:getPlayerId(0)
    
    local techlevel = AOW.getTechLevel(playerId)
    
    if techlevel > 1 then
        local effectToDraw = AOW.getTechLevelEffectName(techlevel)
        local allUnits = Wargroove.getAllUnitsForPlayer(playerId, true)
        for i, u in ipairs(allUnits) do
            if u.unitClassId == "hq" then
                local previousLevel = tonumber(Wargroove.getUnitState(u, "techEffectLevelDrawn"))
                if tech_animation_initalized[playerId + 1] == false or previousLevel == nil or techlevel > previousLevel then
                    if tech_animation_initalized[playerId + 1] == true and previousLevel ~= nil then
                        Wargroove.deleteUnitEffect(Wargroove.getUnitState(u, "techEffect"), "")
                    end
                    local effectId = Wargroove.spawnUnitEffect(u.id, "units/fx/tech_level", effectToDraw, "", true)
                    Wargroove.setUnitState(u, "techEffectLevelDrawn", techlevel)
                    Wargroove.setUnitState(u, "techEffect", effectId)
                    Wargroove.updateUnit(u)
                end
            end
        end
    end
    tech_animation_initalized[playerId + 1] = true
end

function Actions.spawnGlobalStateUnit(context)
    Wargroove.spawnUnit( -1, Constants.globalStateUnitPos, "soldier", true, "")
end

function Actions.setTechLevel(context)
    local playerId = context:getPlayerId(0)
    local techlevel = context:getInteger(1)
    
    AOW.setTechLevel(playerId, techlevel)
end

function Actions.removeGenerateGoldPerTurnFromPos(context)

    for i, unit in ipairs(context.deadUnits) do
        if unit.unitClassId == "gold_camp" then
            local pos = { x = unit.pos.x, y = unit.pos.y }
            
            local goldUnit = Wargroove.getUnitAt(pos)
            
            if goldUnit ~= nil then
                AOW.removeGoldGenerationFromPos(pos)
                
                local goldUnit = Wargroove.getUnitAt(pos)
                
                local goldHp
                if goldUnit.unitClassId == "gold" then
                    goldHp = AOW.getGoldCount(pos) / Constants.goldPerTurnPerMine * 2
                elseif goldUnit.unitClassId == "gem" then
                    goldHp = AOW.getGoldCount(pos) / Constants.gemPerTurnPerMine * 4
                end
                goldUnit:setHealth(goldHp, -1)
                goldUnit.playerId = -2
                Wargroove.updateUnit(goldUnit)
            end
        end
    end

end

function Actions.drawMiningCampIndicator(context)
    local goldPoses = AOW.getRecordedGoldPos()
    for i, goldPos in ipairs(goldPoses) do
        local goldCamp = Wargroove.getUnitAt({ x = goldPos.x, y = goldPos.y })
        if #goldCamp.loadedUnits > 0 then
            local goldUnit = Wargroove.getUnitById(goldCamp.loadedUnits[1])
            if (goldUnit.unitClassId == "gem" or goldUnit.unitClassId == "gold") then
                if (goldUnit.health > 0 and goldUnit.health < 20 and Wargroove.getUnitState(goldCamp, "lowGoldEffectDrawn") == nil) or gold_animation_initialized == false then
                    local effectId = Wargroove.spawnUnitEffect(goldCamp.id, "units/fx/warning", "warn", "", true)
                    Wargroove.setUnitState(goldCamp, "lowGoldEffect", effectId)
                    Wargroove.setUnitState(goldCamp, "lowGoldEffectDrawn", "warn")
                    Wargroove.updateUnit(goldCamp)
                end
            else
                if gold_animation_initialized and Wargroove.getUnitState(goldCamp, "lowGoldEffectDrawn") == "warn" then
                    Wargroove.deleteUnitEffect(Wargroove.getUnitState(goldCamp, "lowGoldEffect"), "")
                end
                
                if gold_animation_initialized == false or Wargroove.getUnitState(goldCamp, "lowGoldEffectDrawn") == "warn" then
                    Wargroove.spawnUnitEffect(goldCamp.id, "units/fx/warning", "critical", "", true)
                    Wargroove.setUnitState(goldCamp, "lowGoldEffect", effectId)
                    Wargroove.setUnitState(goldCamp, "lowGoldEffectDrawn", "critical")
                    Wargroove.updateUnit(goldCamp)
                end
            end
        else
            if gold_animation_initialized == false then
                Wargroove.spawnUnitEffect(goldCamp.id, "units/fx/warning", "critical", "", true)
                Wargroove.setUnitState(goldCamp, "lowGoldEffect", effectId)
                Wargroove.setUnitState(goldCamp, "lowGoldEffectDrawn", "critical")
                Wargroove.updateUnit(goldCamp)
            end        
        end
    end
    gold_animation_initialized = true
end

function Actions.modifyGoldAtPos(context)
    local posX = context:getInteger(0)
    local posY = context:getInteger(1)
    local operation = context:getOperation(2)
    local gold = context:getInteger(3)
    local pos = { x = posX, y = posY }
    local remainingGold = operation(AOW.getGoldCount(pos), gold)
    AOW.setGoldCount(pos, remainingGold)
    
    
    local goldCamp = Wargroove.getUnitAt(pos)
    local goldUnit = Wargroove.getUnitById(goldCamp.loadedUnits[1])
    
    local goldHp
    if goldUnit.unitClassId == "gold" then
        goldHp = remainingGold / Constants.goldPerTurnPerMine * 2
    elseif goldUnit.unitClassId == "gem" then
        goldHp = remainingGold / Constants.gemPerTurnPerMine * 4
    end
    
    
    goldUnit:setHealth(goldHp, -1)
    Wargroove.updateUnit(goldUnit)
    
    if goldUnit.health <= 0 then
        table.remove(goldCamp.loadedUnits, 1)
        Wargroove.updateUnit(goldCamp)
        AOW.removeGoldGenerationFromPos(pos)
    end
    
end

function Actions.redrawUnitRanks(context)
    local units = context:gatherUnits(2, 0, 1)
    
    for i, unit in ipairs(units) do
        Leveling.redraw(unit)
    end
    
    coroutine.yield()
end

-- Editor actions
function Actions.modifyExperience(context)
    -- "Modify Experience of {0} at {1} for {2}: {3} to {4} {5}"
    local operation = context:getOperation(3)
    local value = context:getInteger(4)
    local units = context:gatherUnits(2, 0, 1)
    local silent = context:getBoolean(5)

    for i, unit in ipairs(units) do
        local oldValue = Leveling.getExperience(unit) or 0
        local newValue = operation(tonumber(oldValue), value)
        Leveling.setExperience(unit, newValue, silent)
    end

    coroutine.yield()
end

function Actions.modifyRank(context)
    -- "Modify Rank of {0} at {1} for {2}: {3} to {4} {5}"
    local operation = context:getOperation(3)
    local value = context:getInteger(4)
    local units = context:gatherUnits(2, 0, 1)
    local silent = context:getBoolean(5)

    for i, unit in ipairs(units) do
        local oldValue = Leveling.getRank(unit) or 0
        local newValue = operation(tonumber(oldValue), value)
        Leveling.setRank(unit, newValue, silent)
    end

    coroutine.yield()
end


return Actions
