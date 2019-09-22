local Constants = {}

Constants.goldPerTurnPerMine = 80
Constants.gemPerTurnPerMine = 120
Constants.globalStateUnitPos = { x = -43, y = -57 }
Constants.populationPerVillage = 4
Constants.populationPerHQ = 8
Constants.HPotValue = 25
Constants.GPotValue = 25
Constants.salvageValueReturn = 0.5
Constants.ranks = 5
Constants.rankExpReqs = { 0.0, 1.0, 3.0, 6.0, 10.0, 15.0}
Constants.rankOffMults = { 1.0, 1.1, 1.2, 1.3, 1.4, 1.5}
Constants.rankDefMults = { 1.0, 0.95, 0.9, 0.85, 0.8, 0.75}

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
    gate_foundation = {2, "gate"},
    villager = {1, "villager"},
    witch = {2, "witch"},
    warship = {2, "warship"},
    wagon = {2, "wagon"},
    turtle = {2, "turtle"},
    trebuchet = {2, "trebuchet"},
    travelboat = {2, "travelboat"},
    spearman = {2, "spearman"},
    soldier = {1, "soldier"},
    merman = {2, "merman"},
    mage = {2, "mage"},
    knight = {2, "knight"},
    harpy = {2, "harpy"},
    harpoonship = {2, "harpoonship"},
    giant = {2, "giant"},
    dragon = {2, "dragon"},
    dog = {1, "dog"},
    balloon = {2, "balloon"},
    ballista = {2, "ballista"},
    archer = {2, "archer"},
}

Constants.allLandUpgrades = {
"archer_upgrade",
"knight_upgrade",
"ballista_upgrade",
"trebuchet_upgrade", 
"giant_upgrade"
}

Constants.allSeaUpgrades = {
}

Constants.allAirUpgrades = {
}

Constants.allPriestUpgrades = {
}

return Constants