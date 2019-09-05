local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local AOW = require "age_of_wargroove/age_of_wargroove"
local AI = require "age_of_wargroove/ai"
local Constants = require "constants"

local Build = Verb:new()

local costMultiplier = 1

function getCost(cost)
    return math.floor(cost * costMultiplier + 0.5)
end

function Build:getMaximumRange(unit, endPos)
    return 1
end


function Build:getTargetType()
    return "all"
end

function Build:getRecruitableTargets(unit)
    local allAvailableRecruits = {"hq_foundation","port_foundation","barracks_foundation","tower_foundation","city_foundation","water_city_foundation","gold_camp"}
    local availableRecruits = {}
    
    local availableRecruitsAtTechLevel = AOW.getRecruitsAtTechLevel(AOW.getTechLevel(unit.playerId))
    for i, unitId in ipairs(allAvailableRecruits) do
        for i, unitIdAtTechLevel in ipairs(availableRecruitsAtTechLevel) do
            if unitId == unitIdAtTechLevel then
                table.insert(availableRecruits, unitId)
            end
        end
    end
    return availableRecruits
end

Build.classToRecruit = nil

function Build:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    -- if we haven't choose what to build yet, then we can always execute
    if Build.classToRecruit == nil then
        local target = Wargroove.getUnitAt(targetPos)
        if (target ~= nil) then
            for i, tag in ipairs(target.unitClass.tags) do
                if tag == "foundation" then
                    return false
                end
            end
        end
        return true
    end

    if not self:canSeeTarget(targetPos) then
        return false
    end

    local classToRecruit = Build.classToRecruit
    if classToRecruit == nil then
        classToRecruit = strParam
    end

    local u = Wargroove.getUnitAt(targetPos)
    if (classToRecruit == "") then
        return u == nil
    end

    local uc = Wargroove.getUnitClass(classToRecruit)
    
    if uc.id == "gold_camp" then
        return u ~= nil and (u.unitClass.id == "gold" or u.unitClass.id == "gem")
    end
    
    return (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) and (u == nil or unit.id == u.id) and Wargroove.canStandAt(classToRecruit, targetPos) and Wargroove.getMoney(unit.playerId) >= getCost(uc.cost)
end


function Build:preExecute(unit, targetPos, strParam, endPos)
    -- if we are building an existing foundation, then always return true
    if (target ~= nil) then
        local u = Wargroove.getUnitAt(target)
        
        if u ~= nil then
            for i, tag in ipairs(u.unitClass.tags) do
                if tag == "foundation" then
                    return true
                end
            end
        end
    end
    
    local recruitableUnits = Build.getRecruitableTargets(self, unit);
    Wargroove.openRecruitMenu(unit.playerId, unit.id, unit.pos, unit.unitClassId, recruitableUnits, costMultiplier);

    while Wargroove.recruitMenuIsOpen() do
        coroutine.yield()
    end

    Build.classToRecruit = Wargroove.popRecruitedUnitClass();

    if Build.classToRecruit == nil then
        return false, ""
    end
    
    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local target = Wargroove.getSelectedTarget()

    if (target == nil) then
        Build.classToRecruit = nil
        return false, ""
    end

    return true, Build.classToRecruit
end

function Build:execute(unit, targetPos, strParam, path)
    Build.classToRecruit = nil
    
    if strParam == "" then
        print("Build was not given a class to recruit.")
        return
    end

    local facingOverride = ""
    if targetPos.x > unit.pos.x then
        facingOverride = "right"
    elseif targetPos.x < unit.pos.x then
        facingOverride = "left"
    end

    if facingOverride ~= "" then
        Wargroove.setFacingOverride(unit.id, facingOverride)
    end

    local uc = Wargroove.getUnitClass(strParam)
    
    Wargroove.changeMoney(unit.playerId, -getCost(uc.cost))
    
    Wargroove.spawnUnit(unit.playerId, targetPos, strParam, false)
    Wargroove.waitFrame()
    
    
    local resource = {}
    if (uc.id == "gold_camp") then
        resource = Wargroove.getUnitAt(targetPos)
        resource.pos = { x = -100, y = -100 }
        Wargroove.updateUnit(resource)
    end
    
    local hp = math.floor(100 / AOW.getTurnRequirement(uc.id))
    
    local newUnit = Wargroove.getUnitAt(targetPos)
    newUnit.playerId = unit.playerId
    newUnit.hadTurn = true
    newUnit:setHealth(hp, -1)
    Wargroove.setUnitState(newUnit, "turnsBuilding", 1)
    
    if (uc.id == "gold_camp") then
        local remainingGold = AOW.getGoldCount(targetPos)
        if remainingGold == 0 then
            if resource.unitClassId == "gold" then
                AOW.setGoldCount(targetPos, Constants.goldPerTurnPerMine * resource.health / 2)
            elseif resource.unitClassId == "gem" then
                AOW.setGoldCount(targetPos, Constants.gemPerTurnPerMine * resource.health / 4)
            end
        end
        
        resource.transportedBy = newUnit.id
        resource.inTransport = true
        Wargroove.updateUnit(resource)
        
        table.insert(newUnit.loadedUnits, resource.id)
    end
    
    Wargroove.updateUnit(newUnit)

    Wargroove.unsetFacingOverride(unit.id)

    strParam = ""
end

function Build:generateOrders(unitId, canMove)
    local unit = Wargroove.getUnitById(unitId)
    local orders = {}
    for i,s in ipairs(Build:getRecruitableTargets(unit)) do
        if s == "gold_camp" then
            local aiOrders = AI.placeMineOrders(unitId, canMove)
            for i,o in ipairs(aiOrders) do
                table.insert(orders,o)
            end
        else
            local aiOrders = AI.placeStructureOrders(unitId, canMove, s)
            for i,o in ipairs(aiOrders) do
                table.insert(orders,o)
            end
        end
    end
    return orders
end

function Build:getScore(unitId, order)
    if order.strParam == "" then
        return 0
    end
    if order.strParam == "gold_camp" then
        return AI.placeMineScore(unitId, order)
    else
        return AI.placeStructureScore(unitId, order)
    end
end

return Build
