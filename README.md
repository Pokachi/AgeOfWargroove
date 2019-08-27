# Age Of Wargroove
A mod for Wargroove

Change the gameplay to be more like Age of Empires or Warcraft. In a nutshell, HQ produces villagers, villagers construct buildings and mine gold. Rest of the gameplay is the same as before

## Changes:
1. Can no longer reinforce from buildings
1. Mage are op now (heals cost no gold)
1. Buildings no longer regenerate
1. Villagers can repair buildings (cost half of of the building's original cost, repair 20 hp per turn)
1. Buildings will be destroyed when HP reaches 0
1. Buildings no longer generate gold
1. HQ can recruit villagers
1. Villagers can build buildings
1. New building "Mining Camp" that can be build on top of "Gold". Mining Camp takes 1.3x damage
1. Gold is hostile neutral and takes no damage, so you can't walk through them
1. Villagers can garrison Mining Camp to gather gold (80 gold per villagers per turn, up to 3 villagers per camp)
1. Each gold will have a value of 4000, and for every 80 gold mined from the gold pile, gold pile's hp will decrease by 2 (so a gold pile with 12 hp can be mined for 480 gold. Which is 3 villagers in the mining camp for 2 turns or 1 villager in the mining camp for 6 turns)
1. Villagers inside the mining camp are lost when the mining camp is destroyed
1. 3 Different Tech Levels
    ```
    Level 1 production:
        #HQ: villager
        #Villager: barracks, port, village, water village, mining camp
        #Barracks: swords, dog, pikeman
        #Port: barge, merfolk
    Level 2 Production (In addition):
        #Villager: Tower, Gate, HQ
        #Barracks: wagon, mage, archer, knight
        #Port: turtle, harpoon ship
        #Tower: balloon, harpy
    Level 3 Production (in addition):
        #Barracks: ballista, trebuchet, giant
        #Port: warship
        #Tower: witch, dragon
    ```

1. Population cap (HQ increases population cap by 8, village and water village increase it by 4. You cannot recruit new units when you are population capped. You can check your max population and current population by hovering over HQ or any of the villages. max population is 100)
1. Commanders can pick up up to 6 artifacts. The first 8 artifact's effect are stackable
    ```
    #dagger = +3% to minimal damage, 250g
    #axe = +3% to maximal damage, 250g
    #sword = +2% to overall damage, 350g
    #sword of Death = +2% overall damage, +3% minimal damage, +3% maximal damage, 750g
    #armor = -3% to incoming minimal damage, 250g
    #helmet = -3% to incoming maximal damage, 250g
    #shield = -2% to incoming damage, 350g
    #shield of life = -2% to incoming damage, -3% to incoming minimal damage, -3% to incoming maximal damage, 750g
    #dimensional door = allows commander to teleport next to an empty space by the HQ. 5 turns cool down, 600g
    #health potion = recovers 25 hp. One time use item, 100g
    #groove potion = recovers 25 points of groove (not %). One time use item, 150g
    #bow = allows commander to attack up to 3 tiles away as well as water and flying unit but at half of the normal damage. Commander still do full damage at melee range against land units.
    ```
1. Artifacts can be destroyed
1. Commanders can purchase artifacts from shop. Shop generates 5 random artifacts, and will restock every 5 turns

## TODO:
1. Building foundations so that it takes multiple "build" command to finish building a building (either 1 villager with multiple turns or multiple villagers on a single turn)
1. Retreat Verb to allow units to quickly retreat to HQ
1. New buildings: marketplace, hero's altar, wall, blacksmith, monestary, research lab, outpost, watchtower, and maybe castle if I can figure out how to do a 4 tile building
1. Unit upkeep
1. Salvage verb
1. Commander Leveling
1. New Units
1. Better sprites (Terrible ms paint art for new buildings atm)
1. Fix description strings
1. AI
1. Bug fixes
1. Nerf Mage

## NexusMod URL
https://www.nexusmods.com/wargroove/mods/20
