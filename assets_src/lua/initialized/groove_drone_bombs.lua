local Wargroove = require "wargroove/wargroove"
local OriginalDroneBombs = require "verbs/groove_drone_bombs"

local DroneBombs = {}


function DroneBombs.init()
    OriginalDroneBombs.execute = DroneBombs.execute
end

function DroneBombs:execute(unit, targetPos, strParam, path)
    if strParam == "" then
        print("DroneBomb:execute was not given any target positions.")
        return
    end

    Wargroove.setIsUsingGroove(unit.id, true)
    Wargroove.updateUnit(unit)

    Wargroove.playPositionlessSound("battleStart")
    Wargroove.playGrooveCutscene(unit.id)

    local targetPositions = OriginalDroneBombs.parseTargets(self, strParam)

    Wargroove.playUnitAnimation(unit.id, "groove")
    Wargroove.playMapSound("koji/kojiGroove", unit.pos)
    Wargroove.waitTime(1.1)    
    Wargroove.playMapSound("koji/kojiDroneSpawn", unit.pos)

    for i, dronePos in pairs(targetPositions) do
        local spawnAnimation = ""
        if dronePos.x == unit.pos.x and dronePos.y > unit.pos.y then
            spawnAnimation = "spawn_down"
        elseif dronePos.x == unit.pos.x and dronePos.y < unit.pos.y then
            spawnAnimation = "spawn_up"
        elseif dronePos.y == unit.pos.y and dronePos.x > unit.pos.x then
            spawnAnimation = "spawn_right"
        elseif dronePos.y == unit.pos.y and dronePos.x < unit.pos.x then
            spawnAnimation = "spawn_left"
        end
        Wargroove.spawnUnit(unit.playerId, dronePos, "drone", false, spawnAnimation)
        
        Wargroove.waitFrame()
        -- Set drone's artifact-set to same as Koji's (and will update to match his)
        local u = Wargroove.getUnitAt(dronePos)
        u.loadedUnits = unit.loadedUnits
        Wargroove.updateUnit(u)
        -- NOTE: If we want it so drone's power doesn't match Koji's as he accumulates more artifacts,
        -- make this do a shallow copy of unit.loadedUnits instead of just setting to the reference
    end
    Wargroove.waitTime(0.3)

    Wargroove.playGrooveEffect()

    Wargroove.waitTime(1.6)

    Wargroove.waitTime(0.5)

end

return DroneBombs
