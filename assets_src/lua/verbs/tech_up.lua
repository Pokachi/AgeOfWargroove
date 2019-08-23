local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local AOW = require "age_of_wargroove/age_of_wargroove"
local Constants = require "constants"

local TechUp = Verb:new()

function TechUp:canExecuteAnywhere(unit)
    local maxTechlevel = AOW.getMaxTechLevel()
    local currentTechLevel = AOW.getTechLevel(unit.playerId)
    if (currentTechLevel == maxTechlevel) then
        return false
    end
    
    local techUpCost = AOW.getTechUpCost(currentTechLevel)
    
    if techUpCost > Wargroove.getMoney(unit.playerId) then
        return false
    end

    return true
end

function TechUp:getCostAt(unit, endPos, targetPos)
    local currentTechLevel = AOW.getTechLevel(unit.playerId)
    local techUpCost = AOW.getTechUpCost(currentTechLevel)
    
    return techUpCost
end

function TechUp:execute(unit, targetPos, strParam, path)
    local allUnits = Wargroove.getAllUnitsForPlayer(unit.playerId, true)
    local newTechLevel = AOW.getTechLevel(unit.playerId) + 1
    local techUpCost = AOW.getTechUpCost(AOW.getTechLevel(unit.playerId))
    AOW.setTechLevel(unit.playerId, newTechLevel)
    
    Wargroove.changeMoney(unit.playerId, -techUpCost)
    
    Wargroove.showDialogueBox("neutral", "generic_outlaw", "player " .. tostring(unit.playerId + 1) .. " has reached tech level " .. tostring(newTechLevel), "")
    
end

return TechUp
