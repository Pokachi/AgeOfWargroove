local AOW = require "age_of_wargroove/age_of_wargroove"
local Events = require "initialized/events"
local Wargroove = require "wargroove/wargroove"
local Constants = require "constants"

local Actions = {}

-- This is called by the game when the map is loaded.
function Actions.init()
  Events.addToActionsList(Actions)
end

function Actions.populate(dst)
    dst["modify_gold_at_pos"] = Actions.modifyGoldAtPos
    dst["remove_generate_gold_per_turn_from_pos"] = Actions.removeGenerateGoldPerTurnFromPos
end

function Actions.removeGenerateGoldPerTurnFromPos(context)

    for i, unit in ipairs(context.deadUnits) do
        if unit.unitClassId == "gold_camp" then
            local pos = { x = unit.pos.x, y = unit.pos.y }
            
            local goldUnit = Wargroove.getUnitAt(pos)
            
            if goldUnit ~= nil then
                AOW.removeGoldGenerationFromPos(pos)
                
                local goldUnit = Wargroove.getUnitAt(pos)
                
                local goldHp = AOW.getGoldCount(pos) / Constants.goldPerTurnPerMine
                goldUnit:setHealth(goldHp, -1)
                Wargroove.updateUnit(goldUnit)
            end
        end
    end

end

function Actions.modifyGoldAtPos(context)
    local posX = context:getInteger(0)
    local posY = context:getInteger(1)
    local operation = context:getOperation(2)
    local gold = context:getInteger(3)
    local pos = { x = posX, y = posY }
    local remainingGold = operation(AOW.getGoldCount(pos), gold)
    AOW.setGoldCount(pos, remainingGold)
    
    local goldHp = remainingGold / Constants.goldPerTurnPerMine
    
    local goldCamp = Wargroove.getUnitAt(pos)
    local goldUnit = Wargroove.getUnitById(goldCamp.loadedUnits[1])
    
    goldUnit:setHealth(goldHp, -1)
    Wargroove.updateUnit(goldUnit)
    
    if goldUnit.health == 0 then
        table.remove(goldCamp.loadedUnits, 1)
        Wargroove.updateUnit(goldCamp)
        AOW.removeGoldGenerationFromPos(pos)
    end
    
end

return Actions
