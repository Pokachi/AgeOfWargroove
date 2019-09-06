local Events = require "wargroove/events"
local Wargroove = require "wargroove/wargroove"
local Constants = require "constants"
local AOW = require "age_of_wargroove/age_of_wargroove"
local Equipment = require "age_of_wargroove/equipment"
local AIUtils = require "age_of_wargroove/ai_utilities"

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
            if unitClassId == "barracks" or unitClassId == "barracks_foundation" then
                AIGlobals[playerId].barracks = AIGlobals[playerId].barracks + 1
            elseif unitClassId == "tower" or unitClassId == "tower_foundation" then
                AIGlobals[playerId].towers = AIGlobals[playerId].towers + 1
            elseif unitClassId == "port" or unitClassId == "port_foundation" then
                AIGlobals[playerId].ports = AIGlobals[playerId].ports + 1
            elseif unitClassId == "villager" or unitClassId == "villager_foundation" then
                AIGlobals[playerId].villagers = AIGlobals[playerId].villagers + 1
            elseif unitClassId == "gold_camp" then
                AIGlobals[playerId].goldCamps = AIGlobals[playerId].goldCamps + 1
                table.insert(AIGlobals[playerId].goldCampsPos, unit.pos)
            end
        elseif (unitClassId == "gold" or unitClassId == "gem") and unit.pos.x >= 0 and unit.pos.y >= 0 then
            table.insert(AIGlobals[playerId].goldPos, unit.pos)
        end
    end
    AIUtils.readGoldHeatMapFromState()
end

function AI.getAIGlobals()
    return AIGlobals
end

function AI.setupAIHeatMap(playerId)
    if playerId == nil then
        return
    end
    local allUnits = Wargroove.getUnitsAtLocation(nil)
    local golds = {}
    for i, unit in ipairs(allUnits) do
        if (unit.unitClass.id == "gold" or unit.unitClass.id == "gem") and unit.pos.x >= 0 and unit.pos.y >= 0 then
            table.insert(golds, unit.pos)
        end
    end
    AIUtils.generateGoldHeatMap(golds)
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

function AI.setupAIHeatMapTrigger(referenceTrigger)
    local trigger = {}
    trigger.id =  "setupAIHeatMap"
    trigger.recurring = "oncePerPlayer"
    trigger.players = { 1, 0, 0, 0, 0, 0, 0, 0 }
    trigger.conditions = {}
    table.insert(trigger.conditions, { id = "start_of_turn", parameters = {} })
    trigger.actions = {}
    table.insert(trigger.actions, { id = "setup_ai_heatmap", parameters = { "current" }  })
    
    return trigger
end

function AI.modifyAIGlobalsAlwaysTrigger(referenceTrigger)
    local trigger = {}
    trigger.id =  "modifyAIGlobalsAlwaysTrigger"
    trigger.recurring = "repeat"
    trigger.players = referenceTrigger.players
    trigger.conditions = {}
    table.insert(trigger.conditions, { id = "end_of_unit_turn", parameters = { } })
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
    if classToRecruit == "" then
        return orders
    end
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
                if Wargroove.areAllies(u.playerId, unit.playerId) and uc.isStructure and uc.id == "gold_camp" and not (#(u.loadedUnits) >= uc.loadCapacity) and #(u.loadedUnits) ~= 0 and u.loadedUnits[1] ~= nil then
                    local lc = Wargroove.getUnitById(u.loadedUnits[1]).unitClass.id;
                    if lc == "gold" or lc == "gem" then
                        orders[#orders+1] = {targetPosition = targetPos, strParam = "", movePosition = pos, endPosition = pos}
                    end
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
                if uc.id == "gold" or uc.id == "gem" then
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
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local score = -1
    
    if AIGlobals[unit.playerId].goldCamps > 0 and AIGlobals[unit.playerId].villagers > 3 then
        score = 75
    end
    return { score = score, healthDelta = 0, introspection = {}}
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
    if classToRecruit == "barracks_foundation" and AIGlobals[unit.playerId].barracks >= 3 then
        return orders
    end
    if classToRecruit == "tower_foundation" and AIGlobals[unit.playerId].towers >= 1 then
        return orders
    end
    if classToRecruit == "port_foundation" and AIGlobals[unit.playerId].ports >= 1 then
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
    if (order.strParam == "city_foundation" or order.strParam == "water_city_foundation") and popDiff <= 2 then
        score = 80
    else
        score = 1
    end
    if order.strParam == "hq_foundation" and popDiff <= 2 then
        score = 68 + AOW.getPopulationCap(unit.playerId)
    end
    if order.strParam == "barracks_foundation" then
        score = 10 * AIGlobals[unit.playerId].villagers - AIGlobals[unit.playerId].barracks * 35
    end
    if order.strParam == "tower_foundation" then
        score = 15
    end
    if order.strParam == "port_foundation" then
        score = 15
    end
    for i,targetPos in ipairs(unitsInRange) do
        local u = Wargroove.getUnitAt(targetPos)
        if u ~= nil then
            if ((u.unitClass.id == "hq_foundation" and Wargroove.areAllies(u.playerId, unit.playerId)) or (u.unitClass.id == "hq" and Wargroove.areAllies(u.playerId, unit.playerId)) or u.unitClass.id == "gold" or u.unitClass.id == "gem" or u.unitClass.id == "gold_camp") and order.strParam ~= "gold_camp" then
                score = score - 75
            end
            if u.unitClass.id == "city_foundation" or u.unitClass.id == "city" then
                score = score - 3
            end
            if u.unitClass.id == "barracks_foundation" or u.unitClass.id == "tower_foundation" or u.unitClass.id == "barracks" or u.unitClass.id == "tower" then
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
    if unit.loadedUnits ~= nil and #(unit.loadedUnits) > 0 and unit.loadedUnits[1] ~= nil then
        local lc = Wargroove.getUnitById(unit.loadedUnits[1]).unitClass.id
        if lc ~= "gold" and lc ~= "gem" then
            for i, id in ipairs(unit.loadedUnits) do
                local u = Wargroove.getUnitById(id)
                if u ~= nil then 
                    local targets = Wargroove.getTargetsInRange(unit.pos, 1, "empty")
                    if targets ~= nil or #targets ~= 0 then
                        for l, target in ipairs(targets) do
                            if start then
                                start = false
                            else
                                strParam = strParam .. ";"
                            end
                            if target ~= nil and Wargroove.canStandAt("villager", target) then
                                strParam = strParam .. u.id .. ":" .. target.x .. "," .. target.y
                                break
                            end
                        end
                    end
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
        if Wargroove.canStandAt(unitClass.id, targetPos) then
            table.insert(orders, {targetPosition = targetPos, strParam = "", movePosition = targetPos, endPosition = targetPos})
        end
    end
    
    return orders
end
function AI.waitVillagerScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    
    local endPos = order.endPosition
    
    local goldBonus = 225
    if AIGlobals[unit.playerId].goldCamps > 0 then
        goldBonus = 0
    end
    local score = -1
    for i, pos in ipairs(AIGlobals[unit.playerId].goldPos) do
        local key = pos.x .. "," .. pos.y .. ":gold"
        local tmpScore = AIUtils.getFromLocationMap(endPos, key) + goldBonus
        score = math.max(tmpScore, score)
    end
    for i, pos in ipairs(AIGlobals[unit.playerId].goldCampsPos) do
        local key = pos.x .. "," .. pos.y .. ":gold"
        local u = Wargroove.getUnitAt(pos)
        if u ~= nil and Wargroove.areAllies(u.playerId, unit.playerId) and u.unitClass.isStructure and u.unitClass.id == "gold_camp" and not (#(u.loadedUnits) >= u.unitClass.loadCapacity) and #(u.loadedUnits) ~= 0 and u.loadedUnits[1] ~= nil then
            local tmpScore = AIUtils.getFromLocationMap(endPos, key) + 5
            score = math.max(tmpScore, score)
        end
    end
    score = score / 3
    return { score = score, healthDelta = 0, introspection = {}}
end

function AI.pickUpOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local orders = {}
    local movePositions = {}
    if canMove then 
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    
    for i, movePos in ipairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, movePos, movePos, 1, "unit")
        for i, target in ipairs(targets) do
        local u = Wargroove.getUnitAt(target)
            if u ~= nil then
                local allArtifacts = Equipment.getAllArtifactsIds()
                local exists = false
                for j, a in ipairs(allArtifacts) do
                    exists = exists or (a == u.unitClass.id)
                end
                if exists then
                    table.insert(orders, {targetPosition = target, strParam = "", movePosition = movePos, endPosition = movePos})
                end
            end
        end
    end
    return orders
end

function AI.pickUpScore(unitId, order)
    return { score = 6, healthDelta = 0, introspection = {}}
end

function AI.buyArtifactsOrders(unitId, canMove, recruitableUnits)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local orders = {}
    local movePositions = {}
    if canMove then 
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    if #(unit.loadedUnits) >= unitClass.loadCapacity then
        return orders
    end
    for i, movePos in ipairs(movePositions) do
        local targets = Wargroove.getTargetsInRangeAfterMove(unit, movePos, movePos, 1, "unit")
        for k, target in ipairs(targets) do
            local u = Wargroove.getUnitAt(target)
            if u ~= nil and u.unitClass.id == "shop" then
                local allArtifacts = Equipment.getAllArtifactsIds()
                for p, r in ipairs(recruitableUnits) do
                    
                    local exists = false
                    for j, a in ipairs(allArtifacts) do
                        exists = exists or (a == r)
                    end
                    if exists and Wargroove.getMoney(unit.playerId) >= Wargroove.getUnitClass(r).cost then
                        table.insert(orders, {targetPosition = target, strParam = r, movePosition = movePos, endPosition = movePos})
                    end
                end
            end
        end
    end
    return orders
end

function AI.buyArtifactsScore(unitId, order)
    if order == nil or order.strParam == "" then
        return { score = -1, healthDelta = 0, introspection = {}}
    end
    return { score = 5.9, healthDelta = 0, introspection = {}}
end

function AI.drinkGPotOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local orders = {}
    local movePositions = {}
    if unit.loadedUnits == nil then
        return orders
    end
    local hasPot = false
    for i, equipmentId in ipairs(unit.loadedUnits) do
        local equipment = Wargroove.getUnitById(equipmentId)
        if equipment.unitClassId == "health_pot" then
            hasPot = true
            break
        end
    end
    if (not hasPot) then
        return orders
    end
    if canMove then 
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    local totalGroove = unit.grooveCharge + Constants.GPotValue
    if totalGroove >= 100 then
        return orders
    end
    for i, movePos in ipairs(movePositions) do
        table.insert(orders, {targetPosition = movePos, strParam = "", movePosition = movePos, endPosition = movePos})
    end
    return orders
end

function AI.drinkGPotScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local score = (20 - math.sqrt(unit.grooveCharge + Constants.GPotValue + 10))
    
    return { score = score, healthDelta = 0, introspection = {}}
end

function AI.drinkHPotOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local orders = {}
    local movePositions = {}
    if unit.loadedUnits == nil then
        return orders
    end
    local hasPot = false
    for i, equipmentId in ipairs(unit.loadedUnits) do
        local equipment = Wargroove.getUnitById(equipmentId)
        if equipment.unitClassId == "health_pot" then
            hasPot = true
            break
        end
    end
    if (not hasPot) then
        return orders
    end
    if canMove then 
        movePositions = Wargroove.getTargetsInRange(unit.pos, unitClass.moveRange, "empty")
    end
    local totalHealth = unit.health + Constants.HPotValue
    if totalHealth >= 100 then
        return orders
    end
    for i, movePos in ipairs(movePositions) do
        table.insert(orders, {targetPosition = movePos, strParam = "", movePosition = movePos, endPosition = movePos})
    end
    return orders
end

function AI.drinkHPotScore(unitId, order)
    local unit = Wargroove.getUnitById(unitId)
    local score = (25 - math.sqrt(unit.health + Constants.HPotValue))
    
    return { score = score, healthDelta = Constants.HPotValue, introspection = {{ key = "healScore", value = score }}}
end

function AI.buildTwoOrders(unitId, canMove)
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
                for i, tag in ipairs(u.unitClass.tags) do
                    if tag == "foundation" then
                        orders[#orders+1] = {targetPosition = targetPos, strParam = classToRecruit, movePosition = pos, endPosition = pos}
                        break
                    end
                end
            end
        end
    end
    return orders
end

function AI.buildTwoScore(unitId, order)
    return { score = 85, healthDelta = 0, introspection = {}}
end

function AI.trainOrders(unitId, canMove)
    local orders = {}
    local unit = Wargroove.getUnitById(unitId)
    local unitClass = Wargroove.getUnitClass(unit.unitClassId)
    local placePositions = Wargroove.getTargetsInRange(unit.pos, 1, "empty")

    for i, targetPos in pairs(placePositions) do
        orders[#orders+1] = {targetPosition = targetPos, strParam = "", movePosition = unit.pos, endPosition = unit.pos}
    end
    return orders
end

function AI.trainScore(unitId, order)
    return { score = 30, healthDelta = 0, introspection = {}}
end

return AI