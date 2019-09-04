local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local AOW = require "age_of_wargroove/age_of_wargroove"
local Upgrades = require "age_of_wargroove/upgrades"
local Constants = require "constants"
local AI = require "age_of_wargroove/ai"
local Inspect = require "inspect"

local UpgradeLand = Verb:new()

UpgradeLand.classToRecruit = nil

local costMultiplier = 1

function getCost(cost)
    return math.floor(cost * costMultiplier + 0.5)
end

function UpgradeLand:canExecuteAnywhere(unit)

    if unit ~= nil and unit.unitClassId == "blacksmith" then
        return Upgrades.getWorkingUpgrade(unit.playerId, unit.id) == nil
    end
    
    return false
end

function UpgradeLand:preExecute(unit, targetPos, strParam, endPos)
    local recruitableUnits = Upgrades.getLandUpgrades(unit.playerId)
    
    Wargroove.openRecruitMenu(unit.playerId, unit.id, unit.pos, unit.unitClassId, recruitableUnits, costMultiplier)

    while Wargroove.recruitMenuIsOpen() do
        coroutine.yield()
    end

    UpgradeLand.classToRecruit = Wargroove.popRecruitedUnitClass()

    if UpgradeLand.classToRecruit == nil then
        return false, ""
    end

    return true, UpgradeLand.classToRecruit
end

function UpgradeLand:execute(unit, targetPos, strParam, path)
    UpgradeLand.classToRecruit = nil
    
    if strParam == "" then
        print("UpgradeLand was not given a class to recruit.")
        return
    end

    local uc = Wargroove.getUnitClass(strParam)
    
    Wargroove.changeMoney(unit.playerId, -getCost(uc.cost))
    
    Upgrades.setWorkingUpgrade(unit.playerId, unit.id, strParam)

    strParam = ""
end

-- function UpgradeLand:generateOrders(unitId, canMove)
    -- local shop = Wargroove.getUnitById(unitId)
    -- return AI.buyArtifactsOrders(unitId, canMove, self:getAndUpdateStock(shop))
-- end

-- function UpgradeLand:getScore(unitId, order)
    -- return AI.buyArtifactsScore(unitId, canMove)
-- end

return UpgradeLand
