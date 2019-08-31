local Events = require "wargroove/events"
local Wargroove = require "wargroove/wargroove"
local Constants = require "constants"
local AOW = require "age_of_wargroove/age_of_wargroove"
local Equipment = require "age_of_wargroove/equipment"

local AiUtils = {}

local inspect = require "inspect"

AiUtils.locationMap = {}
function AiUtils.addToLocationMap(pos, key, value)
    local keyStr = pos.x .. "," .. pos.y .. ":" .. key
    
    AiUtils.locationMap[keyStr] = value
end

function AiUtils.getFromLocationMap(pos, key)
    local keyStr = pos.x .. "," .. pos.y .. ":" .. key
    local value = AiUtils.locationMap[keyStr]
    if value == nil then
        return 0
    end
    return value
end

function AiUtils.generateGoldHeatMap(goldUnits)
    for i, goldPos in ipairs(goldUnits) do
        local key = goldPos.x .. "," .. goldPos.y .. ":gold"
        local stack = {{x=goldPos.x,y=goldPos.y+1,value=35},{x=goldPos.x-1,y=goldPos.y,value=35},{x=goldPos.x+1,y=goldPos.y,value=35},{x=goldPos.x,y=goldPos.y-1,value=35}}
        
        while #stack > 0 do
            local current = table.remove(stack, 1)
            if Wargroove.canStandAt("villager", {x=current.x,y=current.y}) then
                local value = current.value - 0.5 - Wargroove.getTerrainMovementCostAt({x=current.x,y=current.y})
                if AiUtils.getFromLocationMap({x=current.x,y=current.y}, key) < current.value then
                    AiUtils.addToLocationMap({x=current.x,y=current.y}, key, current.value)
                    local targets = Wargroove.getTargetsInRange({x=current.x,y=current.y}, 1, "all")
                    for i, target in ipairs(targets) do
                        if target ~= nil and AiUtils.distance(goldPos, target) <= 25 and value > 0 then
                            table.insert(stack, {x=target.x,y=target.y,value=value})
                        end
                    end
                end
            end
        end
    end
    local gStateSoldier = AOW.getGlobalStateSoldier()
    Wargroove.setUnitState(gStateSoldier, "aiGoldHeatMap", inspect(AiUtils.locationMap))
    Wargroove.updateUnit(gStateSoldier)
end
function AiUtils.readGoldHeatMapFromState()
    local gStateSoldier = AOW.getGlobalStateSoldier()
    local heatMap = Wargroove.getUnitState(gStateSoldier, "aiGoldHeatMap")
    if heatMap ~= nil then
        AiUtils.locationMap = (loadstring or load)("return "..heatMap)()
    end
end
function AiUtils.posToStr(pos)
    return pos.x .. "," .. pos.y
end
function AiUtils.has_value(tab, val)
    for index, value in ipairs(tab) do
        if AiUtils.posToStr(value) == AiUtils.posToStr(val) then
            return true
        end
    end
    return false
end

function AiUtils.distance(posA, posB)
    return math.abs(posA.x - posB.x) + math.abs(posA.y - posB.y)
end

function AiUtils.AStar(startPos, endPos, h)
   
    local lowestFScore = function(set, fScore)
        local score = 9999999
        local ret = nil
        local index = 1
        for i, pos in ipairs(set) do
            local tmpScore = fScore[AiUtils.posToStr(pos)]
            if score > tmpScore then
                score = tmpScore
                ret = pos
                index = i
            end
        end
        return ret, index
    end
    local reconstructPath = function(from, cur)
        local path = {cur}
        local c = cur
        while c ~= nil and AiUtils.has_value(path, c) do
            c = from[AiUtils.posToStr(c)]
            table.insert(path, c)
        end
        return path, (30 - (#path))
    end
    local endStr = AiUtils.posToStr(endPos)
    local openSet = {startPos}
    local closedSet = {}
    local cameFrom = {}
    local gScore = {}
    local fScore = {}
    gScore[AiUtils.posToStr(startPos)] = 0
    
    fScore[AiUtils.posToStr(startPos)] = h(startPos, endPos)
    
    while next(openSet) ~= nil do
        local current, index = lowestFScore(openSet, fScore)
        local currentStr = AiUtils.posToStr(current)
        if currentStr == endStr then
            return reconstructPath(cameFrom, current)
        end
        table.remove(openSet, index)
        closedSet[currentStr] = current
        local neighbors = Wargroove.getTargetsInRange(current, 1, "all")
        for i, neighbor in ipairs(neighbors) do
            neighbor["facing"] = nil
            neighborStr = AiUtils.posToStr(neighbor)
            if closedSet[neighborStr] == nil and Wargroove.canStandAt("villager", neighbor) then
                local tmpGScore = gScore[currentStr] + Wargroove.getTerrainMovementCostAt(neighbor)
                if gScore[neighborStr] == nil or gScore[neighborStr] > tmpGScore then
                    cameFrom[neighborStr] = current
                    gScore[neighborStr] = tmpGScore
                    fScore[neighborStr] = tmpGScore + h(neighbor, endPos)
                    if (not AiUtils.has_value(openSet, neighbor)) then
                        table.insert(openSet, neighbor)
                    end
                end
            end
        end
    end
    
    return ""
    
end


return AiUtils