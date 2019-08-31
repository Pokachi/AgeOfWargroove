local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local AOW = require "age_of_wargroove/age_of_wargroove"
local AI = require "age_of_wargroove/ai"
local Constants = require "constants"

local Build = Verb:new()

function Build:getMaximumRange(unit, endPos)
    return 1
end

function Build:getTargetType()
    return "unit"
end

function Build:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    local u = Wargroove.getUnitAt(targetPos)
    
    if u ~= nil then
        for i, tag in ipairs(u.unitClass.tags) do
            if tag == "foundation" then
                return true
            end
        end
    end
    
    return false
end

function Build:onPostUpdateUnit(unit, targetPos, strParam, path)
    local u = Wargroove.getUnitAt(targetPos)
    local turnsBuilding = tonumber(Wargroove.getUnitState(u, "turnsBuilding"))
    
    local turnsRequired = AOW.getTurnRequirement(u.unitClassId)
    
    local hpToAdd = math.floor((100 / AOW.getTurnRequirement(u.unitClassId)) + 1)
    
    local newHp = u.health + hpToAdd
    
    if turnsRequired == (turnsBuilding + 1) then
        local endProduct = AOW.getBuildProduct(u.unitClassId)
        Wargroove.removeUnit(u.id)
        Wargroove.waitFrame()
        Wargroove.clearCaches()
        Wargroove.spawnUnit(unit.playerId, targetPos, endProduct, true, "")
        Wargroove.waitFrame()
        u = Wargroove.getUnitAt(targetPos)
    else
        Wargroove.setUnitState(u, "turnsBuilding", turnsBuilding + 1)
    end

    u:setHealth(newHp, -1)

    if (u.unitClassId == "city" or u.unitClassId == "water_city") then
        AOW.setPopulationCap(unit.playerId, AOW.getPopulationCap(unit.playerId) + Constants.populationPerVillage)
    elseif (u.unitClassId == "hq") then
        AOW.setPopulationCap(unit.playerId, AOW.getPopulationCap(unit.playerId) + Constants.populationPerHQ)
    end
    Wargroove.updateUnit(u)
end

function Build:generateOrders(unitId, canMove)
    return AI.buildTwoOrders(unitId, canMove)
end

function Build:getScore(unitId, order)
    return AI.buildTwoScore(unitId, order)
end

return Build
