local AOW = require "age_of_wargroove/age_of_wargroove"
local Events = require "initialized/events"
local Wargroove = require "wargroove/wargroove"
local Constants = require "constants"

local Actions = {}

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
                local effectId = Wargroove.spawnUnitEffect(u.id, "units/structures/tech_level", effectToDraw, "", true)
            end
        end
    end
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
                
                local goldHp = AOW.getGoldCount(pos) / Constants.goldPerTurnPerMine
                goldUnit:setHealth(goldHp, -1)
                goldUnit.playerId = -2
                Wargroove.updateUnit(goldUnit)
            end
        end
    end

end

function Actions.modifyGoldAtPos(context)
    local posX = context:getInteger(0)
    local posY = context:getInteger(1)
    local operation = context:getOperation(2)
    local gold = context:getInteger(3)
    local pos = { x = posX, y = posY }
    local remainingGold = operation(AOW.getGoldCount(pos), gold)
    AOW.setGoldCount(pos, remainingGold)
    
    local goldHp = remainingGold / Constants.goldPerTurnPerMine * 2
    
    local goldCamp = Wargroove.getUnitAt(pos)
    local goldUnit = Wargroove.getUnitById(goldCamp.loadedUnits[1])
    
    goldUnit:setHealth(goldHp, -1)
    Wargroove.updateUnit(goldUnit)
    
    if goldUnit.health == 0 then
        table.remove(goldCamp.loadedUnits, 1)
        Wargroove.updateUnit(goldCamp)
        AOW.removeGoldGenerationFromPos(pos)
    end
    
end

return Actions
