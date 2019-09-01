local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local AOW = require "age_of_wargroove/age_of_wargroove"
local Constants = require "constants"

local RecruitTwo = Verb:new()

local costMultiplier = 1

function getCost(cost)
    return math.floor(cost * costMultiplier + 0.5)
end

function RecruitTwo:getMaximumRange(unit, endPos)
    return 1
end

function RecruitTwo:canExecuteAnywhere(unit)
    if unit.unitClassId ~= "hq" and #unit.loadedUnits > 0 then
        return false
    end
    return AOW.getPopulationSizeForUnit(unit.unitClassId) + AOW.getCurrentPopulation(unit.playerId) <= AOW.getPopulationCap(unit.playerId)
end

function RecruitTwo:getTargetType()
    return "all"
end

function RecruitTwo:getRecruitableTargets(unit)

    local allAvailableRecruits = unit.recruits
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

RecruitTwo.classToRecruit = nil

function RecruitTwo:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    -- if we haven't choose what to RecruitTwo yet, then we can always execute
    if RecruitTwo.classToRecruit == nil then
        return true
    end

    if not self:canSeeTarget(targetPos) then
        return false
    end

    local classToRecruit = RecruitTwo.classToRecruit
    if classToRecruit == nil then
        classToRecruit = strParam
    end

    local u = Wargroove.getUnitAt(targetPos)
    if (classToRecruit == "") then
        return u == nil
    end

    local uc = Wargroove.getUnitClass(classToRecruit)
    
    return (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) and (u == nil or unit.id == u.id) and Wargroove.canStandAt(classToRecruit, targetPos) and Wargroove.getMoney(unit.playerId) >= getCost(uc.cost)
end


function RecruitTwo:preExecute(unit, targetPos, strParam, endPos)
    local recruitableUnits = RecruitTwo.getRecruitableTargets(self, unit);
    Wargroove.openRecruitMenu(unit.playerId, unit.id, unit.pos, unit.unitClassId, recruitableUnits, costMultiplier);

    while Wargroove.recruitMenuIsOpen() do
        coroutine.yield()
    end

    RecruitTwo.classToRecruit = Wargroove.popRecruitedUnitClass();

    if RecruitTwo.classToRecruit == nil then
        return false, ""
    end

    if AOW.getTurnRequirement(RecruitTwo.classToRecruit) == 1 then
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local target = Wargroove.getSelectedTarget()

        if (target == nil) then
            RecruitTwo.classToRecruit = nil
            return false, ""
        end
    end

    return true, RecruitTwo.classToRecruit
end

function RecruitTwo:execute(unit, targetPos, strParam, path)
    RecruitTwo.classToRecruit = nil
    
    if strParam == "" then
        print("RecruitTwo was not given a class to recruit.")
        return
    end

    local uc = Wargroove.getUnitClass(strParam)
    
    Wargroove.changeMoney(unit.playerId, -getCost(uc.cost))
    
    if AOW.getTurnRequirement(strParam) == 1 then 
        
        Wargroove.spawnUnit(unit.playerId, targetPos, strParam, false)
        Wargroove.waitFrame()
        
        local newUnit = Wargroove.getUnitAt(targetPos)
        newUnit.hadTurn = true
        
        Wargroove.updateUnit(newUnit)
    else
        Wargroove.spawnUnit(unit.playerId, { x = -42, y = -19 }, strParam, false)
        Wargroove.waitFrame()
        
        local newUnit = Wargroove.getUnitAt({ x = -42, y = -19 })
        newUnit.transportedBy = unit.id
        newUnit.inTransport = true
        newUnit.pos = ({ x = -42, y = -20 })
        Wargroove.updateUnit(newUnit)
        
        table.insert(unit.loadedUnits, newUnit.id)
        Wargroove.setUnitState(unit, "turnsBuilding", 1)
        local groove = math.floor(100 / AOW.getTurnRequirement(strParam))
        unit:setGroove(groove)
    end

    strParam = ""
end

return RecruitTwo
