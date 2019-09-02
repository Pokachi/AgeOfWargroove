local OriginalEvents = require "wargroove/events"
local Wargroove = require("wargroove/wargroove")
local TriggerContext = require("triggers/trigger_context")
local Resumable = require("wargroove/resumable")
local AOW = require("age_of_wargroove/age_of_wargroove")
local Leveling = require("age_of_wargroove/leveling")

local Events = {}

local triggerContext = TriggerContext:new({
    state = "",
    fired = {},
    campaignFlags = {},    
    mapFlags = {},
    mapCounters = {},
    party = {},
    campaignCutscenes = {},
    creditsToPlay = ""
})

local triggerList = nil
local triggerConditions = {}
local triggerActions = {}
local pendingDeadUnits = {}
local activeDeadUnits = {}

-- This is called by the game when the map is loaded.
function Events.init()
  OriginalEvents.populateTriggerList = Events.populateTriggerList
  OriginalEvents.doCheckEvents = Events.doCheckEvents
  OriginalEvents.startSession = Events.startSession
  OriginalEvents.getMatchState = Events.getMatchState
  OriginalEvents.addToActionsList = Events.addToActionsList
  OriginalEvents.addToConditionsList = Events.addToConditionsList
  OriginalEvents.setMapFlag = Events.setMapFlag
  OriginalEvents.canExecuteTrigger = Events.canExecuteTrigger
  OriginalEvents.executeTrigger = Events.executeTrigger
  OriginalEvents.isConditionTrue = Events.isConditionTrue
  OriginalEvents.runAction = Events.runAction
  OriginalEvents.reportUnitDeath = Events.reportUnitDeath
  OriginalEvents.addTriggerToList = Events.addTriggerToList
  OriginalEvents.removeTriggerFromList = Events.removeTriggerFromList
  OriginalEvents.getTriggerKey = Events.getTriggerKey
end

function Events.startSession(matchState)
    pendingDeadUnits = {}

    Events.populateTriggerList()

    function readVariables(name)
        src = matchState[name]
        dst = triggerContext[name]

        for i, var in ipairs(src) do
            dst[var.id] = var.value
        end
    end

    readVariables("mapFlags")
    readVariables("mapCounters")
    readVariables("campaignFlags")

    for i, var in ipairs(matchState.triggersFired) do
        triggerContext.fired[var] = true
    end

    for i, var in ipairs(matchState.party) do
        table.insert(triggerContext.party, var)
    end

    for i, var in ipairs(matchState.campaignCutscenes) do
        table.insert(triggerContext.campaignCutscenes, var)
    end

    triggerContext.creditsToPlay = matchState.creditsToPlay
end


function Events.getMatchState()
    local result = {}

    function writeVariables(name)
        local src = triggerContext[name]
        local dst = {}
        result[name] = dst

        for k, v in pairs(src) do
            table.insert(dst, { id = k, value = v })
        end
    end

    writeVariables("mapFlags")
    writeVariables("mapCounters")
    writeVariables("campaignFlags")

    result.triggersFired = {}
    for k, v in pairs(triggerContext.fired) do
        table.insert(result.triggersFired, k)
    end

    result.party = {}
    for i, var in ipairs(triggerContext.party) do
        table.insert(result.party, var)
    end

    result.campaignCutscenes = {}
    for i, var in ipairs(triggerContext.campaignCutscenes) do
        table.insert(result.campaignCutscenes, var)
    end

    result.creditsToPlay = triggerContext.creditsToPlay

    return result
end

local additionalActions = {}
local additionalConditions = {}

function Events.addToActionsList(actions)
  table.insert(additionalActions, actions)
end

function Events.addToConditionsList(conditions)
  table.insert(additionalConditions, conditions)
end

function Events.addTriggerToList(triggerToAdd)    
    local notFinished = true
    while notFinished do
        for i, trigger in ipairs(triggerList) do
            if trigger.id ~= nil and trigger.id == triggerToAdd.id then
                table.remove(triggerList, i)
                break;
            end
            if i == #triggerList then
                notFinished = false
            end
        end
    end
    table.insert(triggerList,triggerToAdd)
end

function Events.removeTriggerFromList(triggerId)
    local notFinished = true
    while notFinished do
        for i, trigger in ipairs(triggerList) do
            if trigger.id ~= nil and trigger.id == triggerId then
                table.remove(triggerList, i)
                break;
            end
            if i == #triggerList then
                notFinished = false
            end
        end
    end
end

function Events.getTrigger(triggerId)
    for i, trigger in ipairs(triggerList) do
        if trigger.id ~= nil and trigger.id == triggerId then
            return trigger
        end
    end
    return nil
end

function Events.populateTriggerList()
    triggerList = Wargroove.getMapTriggers()
    
    --AOW specific triggers
    local referenceTrigger = Events.getTrigger("$trigger_default_defeat_hq")
    Events.addTriggerToList(AOW.spawnGlobalStateSoldier())
    Events.addTriggerToList(AOW.drawMiningCampIndicator(referenceTrigger))
    Events.addTriggerToList(AOW.drawTechLevelEffect(referenceTrigger))
    Events.addTriggerToList(AOW.generateGoldPerTurnFromPosTrigger(referenceTrigger))
    Events.addTriggerToList(AOW.getReportDeadMineCampTrigger())
    local modifiedTrigger = AOW.modifyDefeatHQTrigger(referenceTrigger)
    Events.addTriggerToList(modifiedTrigger)
    Events.addTriggerToList(AOW.setInitialTechLevel(referenceTrigger))
    Events.addTriggerToList(AOW.setInitialPopulationCap(referenceTrigger))
    Events.addTriggerToList(AOW.reportDeadVillageTrigger(referenceTrigger))
    Events.addTriggerToList(AOW.modifyUnitCapTrigger(referenceTrigger))
    Events.addTriggerToList(Leveling.onLoadTrigger(referenceTrigger))
    Events.addTriggerToList(AOW.modifyDDoorGroove())    
    
    local Actions = require("triggers/actions")
    local Conditions = require("triggers/conditions")

    Conditions.populate(triggerConditions)
    Actions.populate(triggerActions)

    for i, action in ipairs(additionalActions) do
      action.populate(triggerActions)
    end

    for i, condition in ipairs(additionalConditions) do
      condition.populate(triggerConditions)
    end
end

function Events.doCheckEvents(state)
    triggerContext.state = state
    triggerContext.deadUnits = pendingDeadUnits

    local newPendingUnits = {}
    for i, unit in ipairs(pendingDeadUnits) do
        if unit.triggeredBy ~= nil then
            table.insert(newPendingUnits, unit)
        end 
    end

    pendingDeadUnits = newPendingUnits

    for triggerNum, trigger in ipairs(triggerList) do
        local newPendingUnits = {}
        for j, unit in ipairs(pendingDeadUnits) do
            if unit.triggeredBy == nil or unit.triggeredBy ~= triggerNum then
                table.insert(newPendingUnits, unit)
            end
        end        

        pendingDeadUnits = newPendingUnits

        for n = 0, 7 do
            triggerContext.triggerInstancePlayerId = n
            if Events.canExecuteTrigger(trigger) then
                Events.executeTrigger(trigger)
                for j, unit in ipairs(pendingDeadUnits) do
                    if unit.triggeredBy == nil then
                        unit.triggeredBy = triggerNum
                        table.insert(triggerContext.deadUnits, unit)
                    end
                end
            end
        end
    end
end


function Events.setMapFlag(flagId, value)
    triggerContext:setMapFlagById(flagId, value)
end



function Events.canExecuteTrigger(trigger)
    -- Check if this trigger supports this player
    if trigger.players[triggerContext.triggerInstancePlayerId + 1] ~= 1 then
        return false
    end

    if trigger.recurring ~= 'start_of_match' then
        if triggerContext:checkState('startOfMatch') then
            return false
        end        
    elseif not triggerContext:checkState('startOfMatch') then
        return false
    end

    if trigger.recurring ~= 'end_of_match' then
        if triggerContext:checkState('endOfMatch') then
            return false
        end        
    elseif not triggerContext:checkState('endOfMatch') then
        return false
    end

    -- Check if it already ran
    if trigger.recurring ~= "repeat" then
        if triggerContext.fired[Events.getTriggerKey(trigger)] ~= nil then
            return false
        end
    end

    -- Check all conditions
    return OriginalEvents.checkConditions(trigger.conditions)
end

function Events.executeTrigger(trigger)
    triggerContext.fired[Events.getTriggerKey(trigger)] = true
    OriginalEvents.runActions(trigger.actions)
end

function Events.getTriggerKey(trigger)
    local key = trigger.id
    if trigger.recurring == "oncePerPlayer" then
        key = key .. ":" .. tostring(triggerContext.triggerInstancePlayerId)
    end
    return key
end


function Events.isConditionTrue(condition)
    local f = triggerConditions[condition.id]
    if f == nil then
        print("Condition not implemented: " .. condition.id)
    else
        triggerContext.params = condition.parameters
       return f(triggerContext)
    end
end


function Events.runAction(action)
    local f = triggerActions[action.id]
    if f == nil then
        print("Action not implemented: " .. action.id)
    else
        print("Executing action " .. action.id)
        triggerContext.params = action.parameters
        f(triggerContext)
    end
end


function Events.reportUnitDeath(id, attackerUnitId, attackerPlayerId, attackerUnitClass)
    local unit = Wargroove.getUnitById(id)
    unit.attackerId = attackerUnitId
    unit.attackerPlayerId = attackerPlayerId
    unit.attackerUnitClass = attackerUnitClass
    table.insert(pendingDeadUnits, unit)
end

return Events
