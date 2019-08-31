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

Constants.recruitData = {
    witch = 2,
    warship = 2,
    wagon = 2,
    trutle = 2,
    trebuchet = 2,
    travelboat = 2,
    spearman = 2,
    soldier = 2,
    merman = 2,
    mage = 2,
    knight = 2,
    harpy = 2,
    harpoonship = 2,
    giant = 2,
    dragon = 2,
    dog = 2,
    balloon = 2,
    ballista = 2,
    archer = 2,
}

return Constants