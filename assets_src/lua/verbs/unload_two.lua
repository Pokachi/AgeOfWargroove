local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local AI = require "age_of_wargroove/ai"

local UnloadTwo = Verb:new()

function UnloadTwo:getTargetType()
    return "empty"
end


function UnloadTwo:getMaximumRange(unit, endPos)
    return 1
end

UnloadTwo.selectedLocations = {}

function UnloadTwo:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    if #unit.loadedUnits == 0 then
        return false
    end

    -- If it's a water transport, is it on a beach?
    local tags = unit.unitClass.tags
    for i, tag in ipairs(tags) do
        if tag == "type.sea" then
            if Wargroove.getTerrainNameAt(endPos) ~= "beach" then
                return false
            end
        end
    end

    if strParam == '' then
        -- This means that the code is seeing if it should add unload to the action ui list
        -- Actual checking is done in code.
        return true
    end

    local unitId = tonumber(strParam)

    if unitId then
        for i, location in ipairs(UnloadTwo.selectedLocations) do
            if location.x == targetPos.x and location.y == targetPos.y then
                return false
            end
        end

        local loadedUnit = Wargroove.getUnitById(unitId)

        if Wargroove.canStandAt(loadedUnit.unitClassId, targetPos) then
            return true
        end

        return false
    end

    local targets = UnloadTwo:parseStrParam(strParam)
    for unitId, target in pairs(targets) do
        local loadedUnit = Wargroove.getUnitById(unitId)
        if not Wargroove.canStandAt(loadedUnit.unitClassId, target) then
            return false
        end
    end    
    return true
end

function UnloadTwo:canUnloadMore(transportUnit, endPos, strParam, usedUnits)
    local foundUnloadable = false
    for i, unit in ipairs(transportUnit.loadedUnits) do
        local unused = true
        for j, usedUnit in ipairs(usedUnits) do
            if usedUnit == unit then
                unused = false
            end
        end

        if unused and UnloadTwo:canExecuteWithAnyTarget(transportUnit, endPos, tostring(unit)) then
            foundUnloadable = true
        end
    end
    
    return foundUnloadable
end

function UnloadTwo:preExecute(unit, targetPos, strParam, endPos)
    UnloadTwo.selectedLocations =  {}

    local targets = {}

    local initialUnitID = tonumber(strParam)

    Wargroove.selectTarget()

    while Wargroove.waitingForSelectedTarget() do
        coroutine.yield()
    end

    local target1 = Wargroove.getSelectedTarget()

    if (target1 == nil) then
        UnloadTwo:cleanUpPreExecute()
        return false, ""
    end
    
    local usedUnits = {}

    table.insert(UnloadTwo.selectedLocations, target1)
    table.insert(usedUnits, initialUnitID)
    targets[initialUnitID] = target1

    if (#unit.loadedUnits == 1 or not UnloadTwo:canUnloadMore(unit, endPos, strParam, usedUnits)) then
        UnloadTwo:cleanUpPreExecute()
        return true, UnloadTwo:targetsToString(targets)
    end

    Wargroove.displayTarget(target1)
    for i=1,(#unit.loadedUnits-1) do
        Wargroove.openUnloadMenu(usedUnits);

        while Wargroove.unloadMenuIsOpen() do
            coroutine.yield()
        end

        local unloadVerb = Wargroove.getUnloadVerb()
        if unloadVerb == "cancel" then
            UnloadTwo:cleanUpPreExecute()
            return false, ""
        elseif unloadVerb == "wait" then
            UnloadTwo:cleanUpPreExecute()
            return true, UnloadTwo:targetsToString(targets)
        end

        local unitIdToUnload = Wargroove.getUnloadedUnitId()

        if unitIdToUnload == -1 then
            UnloadTwo:cleanUpPreExecute()
            return false, ""
        end

        Wargroove.selectTarget()

        while Wargroove.waitingForSelectedTarget() do
            coroutine.yield()
        end

        local target = Wargroove.getSelectedTarget()

        if (target == nil) then
            UnloadTwo:cleanUpPreExecute()
            return false, ""
        end

        table.insert(UnloadTwo.selectedLocations, target)
        table.insert(usedUnits, unitIdToUnload)
        targets[unitIdToUnload] = target
        Wargroove.displayTarget(target)

        if (not UnloadTwo:canUnloadMore(unit, endPos, strParam, usedUnits)) then
            UnloadTwo:cleanUpPreExecute()
            return true, UnloadTwo:targetsToString(targets)
        end
    end

    UnloadTwo:cleanUpPreExecute()
    return true, UnloadTwo:targetsToString(targets)
end

function UnloadTwo:cleanUpPreExecute()
    Wargroove.clearDisplayTargets()

    UnloadTwo.selectedLocations = {}
end

function UnloadTwo:targetsToString(targets)
    local strParam = ""
    local start = true
    for unitId, target in pairs(targets) do
        if start then
            start = false
        else
            strParam = strParam .. ";"
        end

        strParam = strParam .. unitId .. ":" .. target.x .. "," .. target.y
    end
    return strParam
end

function UnloadTwo:parseStrParam(strParam)
    local targetStrs={}
    local i = 1
    for targetStr in string.gmatch(strParam, "([^"..";".."]+)") do
        targetStrs[i] = targetStr
        i = i + 1
    end

    local targets = {}
    i = 1
    for unitId, targetStr in pairs(targetStrs) do
        local vals = {}
        local j = 1
        for val in targetStr.gmatch(targetStr, "([^"..":".."]+)") do
            vals[j] = val
            j = j + 1
        end

        local unitId = vals[1]
        local target = {}
        j = 1
        for val in targetStr.gmatch(vals[2], "([^"..",".."]+)") do
            target[j] = val
            j = j + 1
        end

        targets[tonumber(unitId)] = { x = tonumber(target[1]), y = tonumber(target[2])}
        i = i + 1
    end

    return targets
end

function UnloadTwo:execute(unit, targetPos, strParam, path)
    local targets = UnloadTwo:parseStrParam(strParam)

    for unitId, target in pairs(targets) do
        local transportedUnit = Wargroove.getUnitById(unitId)
        transportedUnit.pos = target
        transportedUnit.hadTurn = true
        transportedUnit.inTransport = false
        transportedUnit.transportedBy = -1
        Wargroove.updateUnit(transportedUnit)

    end

    local newLoadedUnits = {}

    for i, unitId in ipairs(unit.loadedUnits) do
        local found = false
        for unloadedId, target in pairs(targets) do
            if unitId == unloadedId then
                found = true
            end
        end
        if not found then
            table.insert(newLoadedUnits, unitId)
        end
    end

    unit.loadedUnits = newLoadedUnits
end

function UnloadTwo:generateOrders(unitId, canMove)
    return AI.unloadCampOrders(unitId, canMove)
end

function UnloadTwo:getScore(unitId, order)
    return AI.unloadCampScore(unitId, order)
end


return UnloadTwo