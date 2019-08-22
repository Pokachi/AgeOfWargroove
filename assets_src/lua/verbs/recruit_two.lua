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
    
    if uc.id == "gold_camp" then
        return u ~= nil and u.unitClass.id == "gold"
    end
    
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

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local target = Wargroove.getSelectedTarget()

    if (target == nil) then
        RecruitTwo.classToRecruit = nil
        return false, ""
    end

    return true, RecruitTwo.classToRecruit
end

function RecruitTwo:execute(unit, targetPos, strParam, path)
    RecruitTwo.classToRecruit = nil
    
    if strParam == "" then
        print("RecruitTwo was not given a class to recruit.")
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
    
    
    local gold = {}
    if (uc.id == "gold_camp") then
        gold = Wargroove.getUnitAt(targetPos)
        gold.pos = { x = -100, y = -100 }
        Wargroove.updateUnit(gold)
    end
    
    local newUnit = Wargroove.getUnitAt(targetPos)
    newUnit.playerId = unit.playerId
    newUnit.hadTurn = true
    
    local techLevel = tonumber(AOW.getTechLevel(unit.playerId))
    if techLevel > 1 and (uc.id == "hq" or uc.id == "port" or uc.id == "tower" or uc.id == "barracks") then
        local EffectName = AOW.getTechLevelEffectName(techLevel)
        local techLevelEffectId = Wargroove.spawnUnitEffect(newUnit.id, "units/structures/tech_level", EffectName, "", true)
    end
    
    if (uc.id == "gold_camp") then
        local remainingGold = AOW.getGoldCount(targetPos)
        if remainingGold == 0 then
            AOW.setGoldCount(targetPos, Constants.goldPerTurnPerMine * gold.health / 2)
        end
        
        gold.transportedBy = newUnit.id
        gold.inTransport = true
        Wargroove.updateUnit(gold)
        
        table.insert(newUnit.loadedUnits, gold.id)
    end
    Wargroove.updateUnit(newUnit)

    Wargroove.unsetFacingOverride(unit.id)

    strParam = ""
end

return RecruitTwo
