local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"


local maxUnitHealth = 100
local maxRepairPerAction = 20
local costReductionMultiplier = 2


local Repair = Verb:new()
Repair.isInPreExecute = false

function Repair:getMaximumRange(unit, endPos)
    return 1
end


function Repair:getTargetType()
    return "unit"
end


function Repair:canExecuteAnywhere(unit)
    return true
end

local function getHealingCost(health, unit)
    local fullCost = Wargroove.getUnitClass(unit.unitClassId).cost
    return math.ceil(health * fullCost / maxUnitHealth / costReductionMultiplier)
end


local function getAffordableHealing(unit)
    local fullCost = Wargroove.getUnitClass(unit.unitClassId).cost
    return math.floor(Wargroove.getMoney(unit.playerId) * maxUnitHealth * costReductionMultiplier / fullCost)
end

local targetedPos = nil
function Repair:preExecute(unit, targetPos, strParam, endPos)
    Repair.isInPreExecute = true
    
    targetedPos = targetPos
    local targetUnit = Wargroove.getUnitAt(targetPos)
    local toHeal, cost = self:getHealAndCost(targetUnit)
    
    Wargroove.showDialogueBox("neutral", "generic_outlaw", "heal " .. tostring(toHeal) .. " hp for " .. tostring(cost) .. " gold. Select the target again to confirm. Right click to cancel.", "")
    
    
    Wargroove.selectTarget()
    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local target = Wargroove.getSelectedTarget()
    
    if (target == nil) then
        Repair.isInPreExecute = false
        targetedPos = nil
        return false, ""
    end
    
    Repair.isInPreExecute = false
    return true, strParam
end

function Repair:canExecuteAt(unit, endPos)
    if not Verb.canExecuteAt(self, unit, endPos) then
        return false
    end

    return true
end

function Repair:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if not self:canSeeTarget(targetPos) then
        return false
    end

    local targetUnit = Wargroove.getUnitAt(targetPos)
    
    if not targetUnit or not targetUnit.unitClass.isStructure or not Wargroove.areAllies(unit.playerId, targetUnit.playerId) then
        return false
    end

    local desiredHealing = math.min(maxUnitHealth - targetUnit.health, maxRepairPerAction)
    if desiredHealing == 0 then
        return false
    end

    if getHealingCost(1, targetUnit) > Wargroove.getMoney(unit.playerId) then
        return false
    end
    
    if Repair.isInPreExecute and targetedPos.x ~= targetPos.x and targetedPos.y ~= targetPos.y then
        return false
    end
    
    return true
end

function Repair:getHealAndCost(unit)
    local desiredHealing = math.min(maxUnitHealth - unit.health, maxRepairPerAction)
    local affordableHealing = getAffordableHealing(unit)

    local toHeal = math.min(desiredHealing, affordableHealing)
    local cost = getHealingCost(toHeal, unit)

    return toHeal, cost
end

function Repair:execute(unit, targetPos, strParam, path)
    local targetUnit = Wargroove.getUnitAt(targetPos)     

    local toHeal, cost = self:getHealAndCost(targetUnit)

    Wargroove.spawnMapAnimation(targetUnit.pos, 0, "fx/reinforce_2", "default", "over_units", { x = 12, y = 0 })
    Wargroove.playMapSound("reinforceUnitHeal", targetUnit.pos)

    targetUnit.health = targetUnit.health + toHeal
    Wargroove.updateUnit(targetUnit)
    Wargroove.changeMoney(targetUnit.playerId, -cost)
end

return Repair
