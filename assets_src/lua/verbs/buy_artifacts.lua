local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local AOW = require "age_of_wargroove/age_of_wargroove"
local Constants = require "constants"
local Equipment = require "age_of_wargroove/equipment"
local Inspect = require "inspect"

local BuyArtifacts = Verb:new()

local costMultiplier = 1

function getCost(cost)
    return math.floor(cost * costMultiplier + 0.5)
end

function BuyArtifacts:getMaximumRange(unit, endPos)
    return 1
end


function BuyArtifacts:getTargetType()
    return "unit"
end

function BuyArtifacts:getRecruitableTargets(unit)
    return Equipment.generateRandomArtifacts(5)
end

BuyArtifacts.classToRecruit = nil

function BuyArtifacts:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local unit = Wargroove.getUnitAt(targetPos)

    if unit ~= nil and unit.unitClassId == "shop" then
        return true
    end
    
    return false
end

function BuyArtifacts:roundUp(numToRound, multiple)
    local remainder = numToRound % multiple;
    if remainder == 0 then
        return numToRound
    end

    return numToRound + multiple - remainder;
end

function BuyArtifacts:preExecute(unit, targetPos, strParam, endPos)
    local currentTurn = Wargroove.getTurnNumber()
    
    local recruitableUnits = {}
    local shop = Wargroove.getUnitAt(targetPos)
    local lastStockedTurn = tonumber(Wargroove.getUnitState(shop, "stockingTurn"))
    local stockingTurn = 0
    if lastStockedTurn ~=nil then
        stockingTurn = self:roundUp(lastStockedTurn, 5) + 1
    end
    
    local currentStockString = Wargroove.getUnitState(shop, "currentStock")
    
    if currentStockString ~= nil then
        recruitableUnits = (loadstring or load)("return "..currentStockString)()
    end
    
    if currentTurn >= stockingTurn  or currentStockString == nil then
        recruitableUnits = BuyArtifacts.getRecruitableTargets(self, unit)
        Wargroove.setUnitState(shop, "currentStock", Inspect(recruitableUnits))
        Wargroove.setUnitState(shop, "stockingTurn", currentTurn)
        Wargroove.updateUnit(shop)
    end
    
    Wargroove.openRecruitMenu(unit.playerId, unit.id, unit.pos, unit.unitClassId, recruitableUnits, costMultiplier)

    while Wargroove.recruitMenuIsOpen() do
        coroutine.yield()
    end

    BuyArtifacts.classToRecruit = Wargroove.popRecruitedUnitClass()

    if BuyArtifacts.classToRecruit == nil then
        return false, ""
    end

    return true, BuyArtifacts.classToRecruit
end

function BuyArtifacts:execute(unit, targetPos, strParam, path)
    BuyArtifacts.classToRecruit = nil
    
    if strParam == "" then
        print("BuyArtifacts was not given a class to recruit.")
        return
    end

    local uc = Wargroove.getUnitClass(strParam)
    
    Wargroove.changeMoney(unit.playerId, -getCost(uc.cost))
    
    Wargroove.spawnUnit(unit.playerId, { x = -93, y = -32 }, strParam, false)
    Wargroove.waitFrame()
    
    local newUnit = Wargroove.getUnitAt({ x = -93, y = -32 })
    
    --remove the purchased item from stock
    local shop = Wargroove.getUnitAt(targetPos)
    local currentStockString = Wargroove.getUnitState(shop, "currentStock")
    local recruitableUnits = (loadstring or load)("return "..currentStockString)()
    for i, currentStock in ipairs(recruitableUnits) do
        if newUnit.unitClassId == currentStock then
            table.remove(recruitableUnits, i)
            break;
        end
    end
    Wargroove.setUnitState(shop, "currentStock", Inspect(recruitableUnits))
    Wargroove.updateUnit(shop)
    
    table.insert(unit.loadedUnits, newUnit.id)
    newUnit.inTransport = true
    newUnit.transportedBy = unit.id
    newUnit.pos = { x = -78, y = -78 }
    Wargroove.updateUnit(newUnit)

    strParam = ""
end

return BuyArtifacts
