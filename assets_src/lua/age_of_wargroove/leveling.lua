local Wargroove = require "wargroove/wargroove"
local Constants = require "constants"
local Utils = require "utils"
local Leveling = {}

local rankSprites = { 
                        "fx/ranks/rank1",
                        "fx/ranks/rank2",
                        "fx/ranks/rank3",
                        "fx/ranks/rank4",
                        "fx/ranks/rank5"
                     }

-- Utils
function Leveling.canLevel(unit) return Utils.tableContains(unit.unitClass.tags, "canLevel") end
function Leveling.getExperience(unit) return Wargroove.getUnitState(unit, "experience") end
function Leveling.getRank(unit) return Wargroove.getUnitState(unit, "rank") end

function Leveling.getRankExpReqs(unit)
    local rankExpReqs = { [0] = 0}
    local cost = unit.unitClass.cost
    
    for i = 1, Constants.ranks do
        rankExpReqs[i] = Constants.rankExpReqs[i + 1] * cost
    end
    
    return rankExpReqs
end

function Leveling.redraw(unit)
    Wargroove.setUnitState(unit, "rankSpriteId", "")
    local experience = Leveling.getExperience(unit) or 0    
    Leveling.setExperience(unit, tonumber(experience), true)
end

function Leveling.onLoadTrigger(referenceTrigger)
    return
    {
        id = "rankLoadTrigger",
        recurring = "repeat",
        players = referenceTrigger.players,
        conditions = 
        {
            {
                id = "on_load",
                parameters = {}
            }
        },
        actions =
        {
            {
                id = "redraw_unit_ranks",
                parameters = { "*unit", "-1", "any"}
            }
        }
    }
end

function Leveling.setExperience(unit, value, silent)
    silent = silent or false
    if Leveling.canLevel(unit) then
        -- Exp and Rank
        Wargroove.setUnitState(unit, "experience", value)        
        local oldRank = Leveling.getRank(unit) or 0
        local rankExpReqs = Leveling.getRankExpReqs(unit)
        local newRank = -1
        for i=1, Constants.ranks do
            if value < rankExpReqs[i] then
                newRank = i - 1
                break
            end
        end
        if newRank == -1 then
            newRank = Constants.ranks
        end
        Wargroove.setUnitState(unit, "rank", newRank)
        
        -- Sprite and SFX
        local rankGain = newRank - tonumber(oldRank)
        local rankSpriteId = Wargroove.getUnitState(unit, "rankSpriteId")
        if rankSpriteId ~= nil and rankSpriteId ~= "" then
            Wargroove.deleteUnitEffect(rankSpriteId, "death")
        end
        rankSpriteId = ""
        if newRank > 0 then
            if rankGain > 0 then
                if not silent then
                    Wargroove.playMapSound("unitPromote", unit.pos)
                    rankSpriteId = Wargroove.spawnUnitEffect(unit.id, rankSprites[newRank], "idle", "rankup", true)
                else
                    rankSpriteId = Wargroove.spawnUnitEffect(unit.id, rankSprites[newRank], "idle", "idle", true)
                end
            elseif rankGain == 0 then
                rankSpriteId = Wargroove.spawnUnitEffect(unit.id, rankSprites[newRank], "idle", "idle", true)
            else
                if not silent then
                    --Wargroove.playMapSound("unitDemote", unit.pos)
                    rankSpriteId = Wargroove.spawnUnitEffect(unit.id, rankSprites[newRank], "idle", "rankdown", true)
                else
                    rankSpriteId = Wargroove.spawnUnitEffect(unit.id, rankSprites[newRank], "idle", "idle", true)
                end                 
            end            
        end
        Wargroove.setUnitState(unit, "rankSpriteId", rankSpriteId)
        
        -- Groove
        local progress = 0.0
        if newRank ~= Constants.ranks then
            progress = math.min(99, (value - rankExpReqs[newRank]) / (rankExpReqs[newRank + 1] - rankExpReqs[newRank]) * 100)
        end
        unit:setGroove(progress)
        
        Wargroove.updateUnit(unit)
    end
end

function Leveling.setRank(unit, value, silent)
    silent = silent or false
    local rank = math.max(math.min(rank, Constants.ranks), 0)
    Leveling.setExperience(unit, Leveling.getRankExpReqs(unit)[rank], silent)
end

function Leveling.getOffMult(unit)
    local rank = Leveling.getRank(unit) or 0
    return Constants.rankOffMults[tonumber(rank) + 1] 
end

function Leveling.getDefMult(unit) 
    local rank = Leveling.getRank(unit) or 0
    return Constants.rankDefMults[tonumber(rank) + 1] 
end

function Leveling.ecoDamage(defender, preHealth, postHealth)
    return (preHealth - postHealth) * defender.unitClass.cost * 0.01
end

return Leveling