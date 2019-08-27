local Events = require "wargroove/events"
local Wargroove = require "wargroove/wargroove"
local Constants = require "constants"
local AOW = require "age_of_wargroove/age_of_wargroove"

local AI = {}

local inspect = require "inspect"

local AIGlobals = {}

function AI.updateAIGlobals(playerId)    
    if playerId == nil then
        return
    end
    local allUnits = Wargroove.getUnitsAtLocation(nil)
    AIGlobals[playerId] = {barracks=0, towers=0, ports=0, goldPos={}, villagers=0, goldCamps=0, goldCampsPos={}}
    for i, unit in ipairs(allUnits) do
        local unitClassId = unit.unitClass.id
        if unit.playerId == playerId  then
            if unitClassId == "barracks" then
                AIGlobals[playerId].barracks = AIGlobals[playerId].barracks + 1
            elseif unitClassId == "tower" then
                AIGlobals[playerId].towers = AIGlobals[playerId].towers + 1
            elseif unitClassId == "port" then
                AIGlobals[playerId].ports = AIGlobals[playerId].ports + 1
            elseif unitClassId == "villager" then
                AIGlobals[playerId].villagers = AIGlobals[playerId].villagers + 1
            elseif unitClassId == "gold_camp" then
                AIGlobals[playerId].goldCamps = AIGlobals[playerId].goldCamps + 1
                table.insert(AIGlobals[playerId].goldCampsPos, unit.pos)
            end
        elseif unitClassId == "gold" and unit.pos.x >= 0 and unit.pos.y >= 0 then
            table.insert(AIGlobals[playerId].goldPos, unit.pos)
        end
    end
end

function AI.getAIGlobals()
    return AIGlobals
end

function AI.modifyAIGlobalsTrigger(referenceTrigger)
    local trigger = {}
    trigger.id =  "modifyAIGlobalsTrigger"
    trigger.recurring = "repeat"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    table.insert(trigger.conditions, { id = "start_of_turn", parameters = {} })
    trigger.actions = {}
    table.insert(trigger.actions, { id = "modify_ai_globals", parameters = { "current" }  })
    
    return trigger
end

function AI.modifyAIGlobalsAlwaysTrigger(referenceTrigger)
    local trigger = {}
    trigger.id =  "modifyAIGlobalsAlwaysTrigger"
    trigger.recurring = "repeat"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    table.insert(trigger.conditions, { id = "unit_presence", parameters = { "current", "0", "0", "barracks", "-1" } })
    trigger.actions = {}
    table.insert(trigger.actions, { id = "modify_ai_globals", parameters = { "current" }  })
    
    return trigger
end

function AI.buildVillagerOrders(unitId, canMove)
    local orders = {}
    if ( not canMove ) then
        return orders
    end
    
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local money = Wargroove.getMoney(unit.playerId)
    local villagerClass = Wargroove.getUnitClass("villager")
    local villagerCost = villagerClass.cost
    if money < villagerCost then
        return orders
    end
    if AOW.getPopulationCap(unit.playerId) <= AOW.getCurrentPopulation(unit.playerId) then
        return orders
    end
    
    if AIGlobals[unit.playerId].villagers >= 18 then
        return orders
    end
    
    local targets = {{x=1,y=0},{x=-1,y=0},{x=0,y=1},{x=0,y=-1}}
    
    for i,targetPos in ipairs(targets) do
        local target = {x=unit.pos.x + targetPos.x, y=unit.pos.y + targetPos.y}
        if Wargroove.getUnitAt(target) == nil then
            table.insert(orders, { targetPosition = target, strParam = "villager", movePosition = unit.pos, endPosition = unit.pos })
        end
    end
    return orders
end

function AI.buildVillagerScore(unitId, order)
    return { score = 50, healthDelta = 0, introspection = {}}
end

function AI.buildUnitOrders(unitId, canMove, classToRecruit)
    local orders = {}
    
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local money = Wargroove.getMoney(unit.playerId)
    local recruitClass = Wargroove.getUnitClass(classToRecruit)
    local recruitCost = recruitClass.cost
    if money < recruitCost then
        return orders
    end
    if AOW.getPopulationCap(unit.playerId) <= AOW.getCurrentPopulation(unit.playerId) then
        return orders
    end
    
    local targets = {{x=1,y=0},{x=-1,y=0},{x=0,y=1},{x=0,y=-1}}
    
    for i,targetPos in ipairs(targets) do
        local target = {x=unit.pos.x + targetPos.x, y=unit.pos.y + targetPos.y}
        if Wargroove.getUnitAt(target) == nil then
            table.insert(orders, { targetPosition = target, strParam = classToRecruit, movePosition = unit.pos, endPosition = unit.pos })
        end
    end
    return orders
end

function AI.buildUnitScore(unitId, order)
    return { score = 25, healthDelta = 0, introspection = {}}
end

function AI.placeVillagerInMineOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")
        for j, targetPos in pairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)
            if u ~= nil then
                local uc = Wargroove.getUnitClass(u.unitClassId)
                if Wargroove.areAllies(u.playerId, unit.playerId) and uc.isStructure and uc.id == "gold_camp" and not (#(u.loadedUnits) >= uc.loadCapacity) and #(u.loadedUnits) ~= 0 and u.loadedUnits[1] ~= nil and Wargroove.getUnitById(u.loadedUnits[1]).unitClass.id == "gold" then
                    orders[#orders+1] = {targetPosition = targetPos, strParam = "", movePosition = pos, endPosition = pos}
                end
            end
        end
    end

    return orders
end

function AI.placeVillagerInMineScore(unitId, order)
    return { score = 49, healthDelta = 0, introspection = {}}
end

function AI.placeMineOrders(unitId, canMove)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local money = Wargroove.getMoney(unit.playerId)
    local goldCampClass = Wargroove.getUnitClass("gold_camp")
    local goldCampCost = goldCampClass.cost
    if money < goldCampCost then
        return orders
    end
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "unit")
        for j, targetPos in pairs(targets) do
            local u = Wargroove.getUnitAt(targetPos)
            if u ~= nil then
                local uc = Wargroove.getUnitClass(u.unitClassId)
                if uc.id == "gold" then
                    orders[#orders+1] = {targetPosition = targetPos, strParam = "gold_camp", movePosition = pos, endPosition = pos}
                end
            end
        end
    end

    return orders
end

function AI.placeMineScore(unitId, order)
    local score = 45
    local unit = Wargroove.getUnitById(unitId)
    if AIGlobals[unit.playerId].goldCamps == 0 then
        score = 100
    end
    return { score = score, healthDelta = 0, introspection = {}}
end

function AI.techUpOrders(unitId, canMove, cost)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local money = Wargroove.getMoney(unit.playerId)
    if money < cost then
        return {}
    end
    return {{targetPosition = unit.pos, strParam = "", movePosition = unit.pos, endPosition = unit.pos}}
end

function AI.techUpScore(unitId, order)
    return { score = 75, healthDelta = 0, introspection = {}}
end

function AI.placeStructureOrders(unitId, canMove, classToRecruit)
    local orders = {}

    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local money = Wargroove.getMoney(unit.playerId)
    local recruitClass = Wargroove.getUnitClass(classToRecruit)
    local recruitCost = recruitClass.cost
    if money < recruitCost then
        return orders
    end
    if classToRecruit == "barracks" and AIGlobals[unit.playerId].barracks >= 3 then
        return orders
    end
    if classToRecruit == "tower" and AIGlobals[unit.playerId].towers >= 1 then
        return orders
    end
    if classToRecruit == "port" and AIGlobals[unit.playerId].ports >= 1 then
        return orders
    end
    local movePositions = {}
    if canMove then
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    table.insert(movePositions, unit.pos)

    for i, pos in pairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, pos, pos, 1, "empty")
        for j, targetPos in pairs(targets) do
            if Wargroove.canStandAt(classToRecruit, targetPos) then
                orders[#orders+1] = {targetPosition = targetPos, strParam = classToRecruit, movePosition = pos, endPosition = pos}
            end
        end
    end

    return orders
end

function AI.placeStructureScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local endPos = order.endPosition
    local unitsInRange = Wargroove.getTargetsInRange(endPos, 2, "unit")
    local score = -1
    local popDiff = AOW.getPopulationCap(unit.playerId) - AOW.getCurrentPopulation(unit.playerId)
    if (order.strParam == "city" or order.strParam == "water_city") and popDiff <= 1 then
        score = 80
    else
        score = -80
    end
    if order.strParam == "hq" and popDiff <= 1 then
        score = 68 + AOW.getPopulationCap(unit.playerId)
    end
    if order.strParam == "barracks" then
        score = 10 * AIGlobals[unit.playerId].villagers - AIGlobals[unit.playerId].barracks * 35
    end
    if order.strParam == "tower" then
        score = 15
    end
    if order.strParam == "port" then
        score = 15
    end
    for i,targetPos in ipairs(unitsInRange) do
        local u = Wargroove.getUnitAt(targetPos)
        if u ~= nil then
            if ((u.unitClass.id == "hq" and Wargroove.areAllies(u.playerId, unit.playerId)) or u.unitClass.id == "gold" or u.unitClass.id == "gold_camp") and order.strParam ~= "gold_camp" then
                score = score - 30
            end
            if u.unitClass.id == "city" then
                score = score - 3
            end
            if u.unitClass.id == "barracks" or u.unitClass.id == "tower" then
                score = score - 5
            end
        end
    end
    return { score = score, healthDelta = 0, introspection = {}}
end

function AI.unloadCampOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local start = true
    local strParam = ""
    
    if unit.loadedUnits ~= nil and #(unit.loadedUnits) > 0 and unit.loadedUnits[1] ~= nil and  Wargroove.getUnitById(unit.loadedUnits[1]).unitClass.id ~= "gold" then
        for i, id in ipairs(unit.loadedUnits) do
            local u = Wargroove.getUnitById(id)
            if u ~= nil then 
                local targets = Wargroove.getTargetsInRange(unit.pos, 1, "empty")
                if targets ~= nil or #targets ~= 0 then
                    local target = targets[1]
                    if start then
                        start = false
                    else
                        strParam = strParam .. ";"
                    end

                    strParam = strParam .. u.id .. ":" .. target.x .. "," .. target.y
                end
            end
        end
    end
    
    return {{targetPosition = unit.pos, strParam = strParam, movePosition = unit.pos, endPosition = unit.pos}}
end

function AI.unloadCampScore(unitId, order)
    return { score = 15, healthDelta = 0, introspection = {}}
end

function AI.waitVillagerOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    
    local orders = {{targetPosition = unit.pos, strParam = "", movePosition = unit.pos, endPosition = unit.pos}}
    if (not canMove) then
        return orders
    end
    
    local movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    
    for i, targetPos in ipairs(movePositions) do
        print("AI Location Score at: " .. targetPos.x .. " " .. targetPos.y)
        print(inspect(Wargroove.getAILocationScore(unitId, targetPos)))
        table.insert(orders, {targetPosition = targetPos, strParam = "", movePosition = targetPos, endPosition = targetPos})
    end
    
    return orders
end

function AI.waitVillagerScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    
    local endPos = order.endPosition
    local score = -1
    for i, gPos in ipairs(AIGlobals[unit.playerId].goldPos) do
        local locationScore = 11 - ((math.abs(gPos.x - endPos.x) + math.abs(gPos.y - endPos.y)) * 0.35)
        if locationScore > score then
            score = locationScore
        end
    end
    for i, gPos in ipairs(AIGlobals[unit.playerId].goldCampsPos) do
        local u = Wargroove.getUnitAt(gPos)
        local uc = u.unitClass
        if u ~= nil and not (#(u.loadedUnits) >= uc.loadCapacity) and #(u.loadedUnits) ~= 0 and u.loadedUnits[1] ~= nil and Wargroove.getUnitById(u.loadedUnits[1]).unitClass.id == "gold" then
            local locationScore = 20 - ((math.abs(gPos.x - endPos.x) + math.abs(gPos.y - endPos.y)) * 0.35)
            if locationScore > score then
                score = locationScore
            end
        end
    end
    return { score = score, healthDelta = 0, introspection = {}}
end

return AI