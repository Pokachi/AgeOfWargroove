local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local AOW = require "age_of_wargroove/age_of_wargroove"
local AI = require "age_of_wargroove/ai"
local Constants = require "constants"

local RecruitTwoPhaseTwo = Verb:new()

function RecruitTwoPhaseTwo:getMaximumRange(unit, endPos)
    return 1
end

function RecruitTwoPhaseTwo:canExecuteAnywhere(unit)
    return #unit.loadedUnits > 0
end

function RecruitTwoPhaseTwo:getTargetType()
    return "all"
end


function RecruitTwoPhaseTwo:canExecuteWithTarget(unit, endPos, targetPos, strParam)

    local u = Wargroove.getUnitAt(targetPos)

    local recruit = Wargroove.getUnitById(unit.loadedUnits[1])

    return (endPos.x ~= targetPos.x or endPos.y ~= targetPos.y) and (u == nil or unit.id == u.id) and Wargroove.canStandAt(recruit.unitClassId, targetPos)
end


function RecruitTwoPhaseTwo:preExecute(unit, targetPos, strParam, endPos)
    local uc = Wargroove.getUnitById(unit.loadedUnits[1]).unitClassId
    print(uc)
    if tonumber(Wargroove.getUnitState(unit, "turnsBuilding")) + 1 >= AOW.getTurnRequirement(uc) then
        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local target = Wargroove.getSelectedTarget()

        if (target == nil) then
            return false, ""
        end
    end
    
    return true, ""
end

function RecruitTwoPhaseTwo:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitById(unit.loadedUnits[1])
    local turnsSpendRecuriting = tonumber(Wargroove.getUnitState(unit, "turnsBuilding"))

    if turnsSpendRecuriting + 1 >= AOW.getTurnRequirement(targetUnit.unitClassId) then 
        Wargroove.spawnUnit(unit.playerId, targetPos, targetUnit.unitClassId, false)
        Wargroove.waitFrame()
        
        local newUnit = Wargroove.getUnitAt(targetPos)
        newUnit.hadTurn = true
        
        Wargroove.updateUnit(newUnit)
        
        Wargroove.removeUnit(targetUnit.id)
        table.remove(unit.loadedUnits, 1)
        
        unit:setGroove(0)
    else
        Wargroove.setUnitState(unit, "turnsBuilding", turnsSpendRecuriting + 1)
        local groove = unit.groove + math.floor(100 / AOW.getTurnRequirement(targetUnit.unitClassId))
        unit:setGroove(groove)
    end
end

function RecruitTwoPhaseTwo:generateOrders(unitid, canMove)
    return AI.trainOrders(unitid, canMove)
end

function RecruitTwoPhaseTwo:getScore(unitid, order)
    return AI.trainScore(unitid, order)
end

return RecruitTwoPhaseTwo
