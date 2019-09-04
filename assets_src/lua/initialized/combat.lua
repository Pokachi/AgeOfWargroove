local OriginalCombat = require "wargroove/combat"
local Wargroove = require "wargroove/wargroove"
local Equipment = require "age_of_wargroove/equipment"
local Upgrades = require "age_of_wargroove/upgrades"
local Leveling = require "age_of_wargroove/leveling"

local Combat = {}


--
local defencePerShield = 0.10
local damageAt0Health = 0.0
local damageAt100Health = 1.0
local randomDamageMin = 0.0
local randomDamageMax = 0.1
--

function Combat:init()
    OriginalCombat.getDamage = Combat.getDamage
    OriginalCombat.solveDamage = Combat.solveDamage
    OriginalCombat.getBestWeapon = Combat.getBestWeapon
    OriginalCombat.solveCombat = Combat.solveCombat
end

function Combat:getBestWeapon(attacker, defender, delta, moved, facing)
    assert(facing ~= nil)
    
    Equipment.addBowForCommander(attacker)

    local weapons = attacker.unitClass.weapons
        for i, weapon in ipairs(weapons) do
            if OriginalCombat:canUseWeapon(weapon, moved, delta, facing) then
                local dmg = Wargroove.getWeaponDamage(weapon, defender, facing)
            if dmg > 0.0001 then
                return weapon, dmg
            end
        end
    end

    return nil, 0.0
end

function Combat:getDamage(attacker, defender, solveType, isCounter, attackerPos, defenderPos, attackerPath, isGroove, grooveWeaponIdOverride)
    if type(solveType) ~= "string" then
        error("solveType should be a string. Value is " .. tostring(solveType))
    end

    local delta = {x = defenderPos.x - attackerPos.x, y = defenderPos.y - attackerPos.y }
    local moved = attackerPath and #attackerPath > 1

    local randomValue = 0.5
    if solveType == "random" and Wargroove.isRNGEnabled() then
        local values = { attacker.id, attacker.unitClassId, attacker.startPos.x, attacker.startPos.y, attackerPos.x, attackerPos.y,
                         defender.id, defender.unitClassId, defender.startPos.x, defender.startPos.y, defenderPos.x, defenderPos.y,
                         isCounter, Wargroove.getTurnNumber(), Wargroove.getCurrentPlayerId() }
        local str = ""
        for i, v in ipairs(values) do
            str = str .. tostring(v) .. ":"
        end
        randomValue = Wargroove.pseudoRandomFromString(str)
    end
    if solveType == "simulationOptimistic" then
        if isCounter then
            randomValue = 0
        else
            randomValue = 1
        end
    end
    if solveType == "simulationPessimistic" then
        if isCounter then
            randomValue = 1
        else
            randomValue = 0
        end
    end

    local attackerRankOffMult = Leveling.getOffMult(attacker)
    local attackerRankDefMult = Leveling.getDefMult(attacker)
    local defenderRankOffMult = Leveling.getOffMult(defender)    
    local defenderRankDefMult = Leveling.getDefMult(defender)
    local attackerHealth = isGroove and 100 or attacker.health
    local attackerEffectiveness = (attackerHealth * 0.01) * (damageAt100Health - damageAt0Health) * (attackerRankOffMult * defenderRankDefMult) + damageAt0Health
    local defenderEffectiveness = (defender.health * 0.01) * (damageAt100Health - damageAt0Health) * (defenderRankOffMult * attackerRankDefMult) + damageAt0Health

    -- For structures, check if there's a garrison; if so, attack as if it was that instead
    local effectiveAttacker
    if attacker.garrisonClassId ~= '' then
        effectiveAttacker = {
            id = attacker.id,
            pos = attacker.pos,
            startPos = attacker.startPos,
            playerId = attacker.playerId,
            unitClassId = attacker.garrisonClassId,
            unitClass = Wargroove.getUnitClass(attacker.garrisonClassId),
            health = attackerHealth,
            state = attacker.state
        }
        attackerEffectiveness = 1.0
    else
        effectiveAttacker = attacker
    end

    local passiveMultiplier = OriginalCombat:getPassiveMultiplier(effectiveAttacker, defender, attackerPos, defenderPos, attackerPath, isCounter, attacker.state)
    attackerEffectiveness = attackerEffectiveness * passiveMultiplier

    local defenderUnitClass = Wargroove.getUnitClass(defender.unitClassId)
    local defenderIsInAir = defenderUnitClass.inAir
    local defenderIsStructure = defenderUnitClass.isStructure

    local terrainDefence
    if defenderIsInAir then
        terrainDefence = Wargroove.getSkyDefenceAt(defenderPos)
    elseif defenderIsStructure then
        terrainDefence = 0
    else
        terrainDefence = Wargroove.getTerrainDefenceAt(defenderPos) + Upgrades.getUpgradeTerrainDefenseModifier(defender)
    end

    local terrainDefenceBonus = terrainDefence * defencePerShield

    local weapon, baseDamage
    if (isGroove) then
        if (grooveWeaponIdOverride ~= nil) then
            weapon = grooveWeaponIdOverride
            baseDamage = Wargroove.getWeaponDamageForceGround(weapon, defender)
        else
            weapon = attacker.unitClass.weapons[1].id
            baseDamage = Wargroove.getWeaponDamageForceGround(weapon, defender)
        end
    else	
        weapon, baseDamage = self:getBestWeapon(effectiveAttacker, defender, delta, moved, attackerPos.facing)
    end

    if weapon == nil or (isCounter and not weapon.canMoveAndAttack) or baseDamage < 0.01 then
        return 0, false
    end

    local multiplier = 1.0
    if Wargroove.isHuman(defender.playerId) then
        multiplier = Wargroove.getDamageMultiplier()

        -- If the player is on "easy" for damage, make the AI overlook that.
        if multiplier < 1.0 and solveType == "aiSimulation" then
            multiplier = 1.0
        end
    end

    local randomMinModifier = 0
    local randomMaxModifier = 0
    local damageModifier = 0
    if attacker.loadedUnits ~= nil and #attacker.loadedUnits > 0 then
        for i, uid in ipairs(attacker.loadedUnits) do
            local u = Wargroove.getUnitById(uid)
            randomMinModifier = randomMinModifier + Equipment.getAttackerRandomMinModifier(u.unitClassId)
            randomMaxModifier = randomMaxModifier + Equipment.getAttackerRandomMaxModifier(u.unitClassId)
            damageModifier = damageModifier + Equipment.getAttackerDamageModifier(u.unitClassId)
        end
    end
    if defender.loadedUnits ~= nil and #defender.loadedUnits > 0 then
        for i, uid in ipairs(defender.loadedUnits) do
            local u = Wargroove.getUnitById(uid)
            randomMinModifier = randomMinModifier - Equipment.getDefenderRandomMinModifier(u.unitClassId)
            randomMaxModifier = randomMaxModifier - Equipment.getDefenderRandomMaxModifier(u.unitClassId)
            damageModifier = damageModifier - Equipment.getDefenderDamageModifier(u.unitClassId)
        end
    end
    damageModifier = damageModifier + Upgrades.getUpgradeDamageModifier(attacker, defender) - Upgrades.getUpgradeDefenseModifier(defender, attacker)
    local damage = self:solveDamage(baseDamage, attackerEffectiveness, defenderEffectiveness, terrainDefenceBonus, randomValue, multiplier, randomMinModifier, randomMaxModifier, damageModifier)

    local hasPassive = passiveMultiplier > 1.01
    return damage, hasPassive
end

function Combat:solveDamage(weaponDamage, attackerEffectiveness, defenderEffectiveness, terrainDefenceBonus, randomValue, multiplier, randomMinModifier, randomMaxModifier, damageModifier)
    local modifiedRandomMax = randomMaxModifier + randomDamageMax
    local modifiedRandomMin = randomMinModifier + randomDamageMin
    if modifiedRandomMin > modifiedRandomMax then
        modifiedRandomMax = (modifiedRandomMin + modifiedRandomMax) / 2
        modifiedRandomMin = modifiedRandomMax
    end
    local randomBonus = modifiedRandomMin + (modifiedRandomMax - modifiedRandomMin) * randomValue

    local offence = weaponDamage + randomBonus + damageModifier
    local defence = defenderEffectiveness * math.max(0, terrainDefenceBonus) - math.max(0, -terrainDefenceBonus)
    local damage = attackerEffectiveness * offence * (1.0 - defence) * multiplier

    return math.max(math.floor(100 * damage + 0.5), 1)
end

function Combat:solveCombat(attackerId, defenderId, attackerPath, solveType)
	local attacker = Wargroove.getUnitById(attackerId)
	assert(attacker ~= nil)
	local defender = Wargroove.getUnitById(defenderId)
	assert(defender ~= nil)

	local results = {
		attackerHealth = attacker.health,
		defenderHealth = defender.health,
		attackerAttacked = false,
		defenderAttacked = false,
		hasCounter = false,
		hasAttackerCrit = false
	}

	local e0 = self:getEndPosition(attackerPath, attacker.pos)
	Wargroove.pushUnitPos(attacker, e0)

    -- Attack
	local attackResult
	attackResult, results.hasAttackerCrit = self:solveRound(attacker, defender, solveType, false, attacker.pos, defender.pos, attackerPath)
	if attackResult ~= nil then
		results.defenderHealth = attackResult
		results.attackerAttacked = true
		if results.defenderHealth < 1 and solveType == "random" then
			results.defenderHealth = 0
		end
	end

    -- Counter
	if results.defenderHealth > 0 then
		local damagedDefender = {
			id = defender.id,
			pos = defender.pos,
			startPos = defender.startPos,
			playerId = defender.playerId,
			health = results.defenderHealth,
			unitClass = defender.unitClass,
			unitClassId = defender.unitClassId,
			garrisonClassId = defender.garrisonClassId,
			state = defender.state
		}
		local defenderResult
		defenderResult, results.hasDefenderCrit = self:solveRound(damagedDefender, attacker, solveType, true, defender.pos, attacker.pos, {defender.pos})
		if defenderResult ~= nil then
			results.attackerHealth = defenderResult
			results.defenderAttacked = true
			results.hasCounter = true
			if results.attackerHealth < 1 and solveType == "random" then
				results.attackerHealth = 0
			end
		end
	end
    
    -- Experience distribution
    if solveType == "random" then
        local attEcoDamage = Leveling.ecoDamage(defender, defender.health, results.defenderHealth)
        local attExp = Leveling.getExperience(attacker) or 0        
        Leveling.setExperience(attacker, attEcoDamage + tonumber(attExp))
        
        if results.defenderHealth > 0 then
            local defEcoDamage = Leveling.ecoDamage(attacker, attacker.health, results.attackerHealth)
            local defExp = Leveling.getExperience(defender) or 0            
            Leveling.setExperience(defender, defEcoDamage + tonumber(defExp))
        end
    end
    
	Wargroove.popUnitPos()
	
	return results
end

return Combat