local Constants = {}

Constants.goldPerTurnPerMine = 80
Constants.gemPerTurnPerMine = 120
Constants.globalStateUnitPos = { x = -43, y = -57 }
Constants.populationPerVillage = 4
Constants.populationPerHQ = 8
Constants.HPotValue = 25
Constants.GPotValue = 25
Constants.salvageValueReturn = 0.5

Constants.coolDown = {
    door = 5
}

Constants.buildData = {
    barracks_foundation = {2, "barracks"},
    port_foundation = {2, "port"},
    tower_foundation = {2, "tower"},
    city_foundation = {2, "city"},
    water_city_foundation = {2, "water_city"},
    hq_foundation = {3, "hq"},
    gold_camp = {1, ""},
    gate_foundation = {2, "gate"}
}

return Constants