local Events = require "wargroove/events"
local Wargroove = require "wargroove/wargroove"
local Constants = require "constants"
local AOW = require "age_of_wargroove/age_of_wargroove"

local AI = {}

local inspect = require "inspect"

local AIGlobals = {numBarracks}

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
    if AOW.getPopulationCap(playerId) >= AOW.getCurrentPopulation(playerId) then
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
    if ( not canMove ) then
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
    if AOW.getPopulationCap(playerId) >= AOW.getCurrentPopulation(playerId) then
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
    return { score = 1, healthDelta = 0, introspection = {}}
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
    if AOW.getPopulationCap(playerId) >= AOW.getCurrentPopulation(playerId) then
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
    return { score = 45, healthDelta = 0, introspection = {}}
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
    local villageClass = Wargroove.getUnitClass("city")
    local villageCost = villageClass.cost
    if money < villageCost then
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
    local score = 25
    local popDiff = AOW.getPopulationCap(unit.playerId) - AOW.getCurrentPopulation(unit.playerId)
    if order.strParam == "city" and popDiff <= 1 then
        score = 80
    end
    if order.strParam == "hq" and popDiff <= 1 then
        score = 68 + AOW.getPopulationCap(unit.playerId)
    end
    for i,targetPos in ipairs(unitsInRange) do
        local u = Wargroove.getUnitAt(targetPos)
        if u ~= nil then
            if (u.unitClass.id == "hq" and Wargroove.areAllies(u.playerId, unit.playerId)) or u.unitClass.id == "gold" or u.unitClass.id == "gold_camp" then
                score = - 30
            end
            if u.unitClass.id == "city" then
                score = score - 1
            end
            if u.unitClass.id == "barracks" or u.unitClass.id == "tower" then
                score = score - 2
            end
        end
    end
    return { score = score, healthDelta = 0, introspection = {}}
end

return AI