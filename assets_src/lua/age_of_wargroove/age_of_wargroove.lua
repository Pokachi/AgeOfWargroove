local Events = require "wargroove/events"
local Wargroove = require "wargroove/wargroove"

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
--        cap,
--        current
--    },
--    {
--        playerId,
--        cap,
--        current
--    },
--    ...
--}

local state = { goldPos = {}, populationCap = {}}

function AgeOfWargroove.getPopulationCap(playerId)
    for i, playerCap in ipairs(state.popupationCap) do
        if playerCap.playerId == playerId then
            return playerCap.cap
        end
    end
    return 0
end

function AgeOfWargroove.setPopulationCap(playerId, newCap)    
    for i, playerCap in ipairs(state.popupationCap) do
        if playerCap.playerId == playerId then
            playerCap.cap = newCap
            return
        end
    end
    local playerCap = { playerId = playerId, cap = newCap }
    table.insert(state.populationCap, playerCap)
end

function AgeOfWargroove.setInitialPopulationCap()
    local trigger = {}
    trigger.id =  "setInitialPopulationCap"
    trigger.recurring = "once"
    trigger.players = {}
    for i = 1, 8, 1 do
        if i == 0 then
            table.insert(trigger.players, 1)
        else
            table.insert(trigger.players, 0)
        end
    end
    trigger.conditions = {}
    
    table.insert(trigger.conditions, { id = "unit_killed", parameters = { "*unit", "current", "gold_camp", "any", "-1" } })
    table.insert(trigger.conditions, { id = "player_turn", parameters = { "current" } })
    
    trigger.actions = {}
    
    table.insert(trigger.actions, { id = "remove_generate_gold_per_turn_from_pos", parameters = {} })
    
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
    
    for i, pos in ipairs(state.goldPos) do
        if (pos.x == targetPos.x and pos.y == targetPos.y) then
            pos.value = goldRemaining
            return
        end
    end
    local pos = { x = targetPos.x, y = targetPos.y, value = goldRemaining}
    table.insert(state.goldPos, pos)
end

function AgeOfWargroove.getGoldCount(targetPos)
    
    for i, pos in ipairs(state.goldPos) do
        if (pos.x == targetPos.x and pos.y == targetPos.y) then
            return pos.value
        end
    end
    return 0
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
