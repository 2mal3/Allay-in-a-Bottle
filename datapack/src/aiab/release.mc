import ../../macros/log.mcm


function release {
  advancement revoke @s only aiab:release/release

  data modify storage aiab:data root set from entity @s SelectedItem.tag.aiab

  # Iterative function to find block to place on
  scoreboard players set .length aiab.data 45

  execute anchored eyes run {
    name raycast

    scoreboard players remove .length aiab.data 1
    execute if score .length aiab.data matches 0 run return 0

    execute(unless block ^ ^ ^0.1 #aiab:release/air) {
      execute positioned ^ ^ ^ run function aiab:release/found
    } else {
      execute positioned ^ ^ ^0.1 run function aiab:release/raycast
    }
  }
}

function found {
  # Some nice effects
  particle minecraft:end_rod ~ ~0.2 ~ 0.2 0.4 0.2 0 4
  execute if data storage aiab:data root.allay run playsound minecraft:entity.allay.ambient_without_item player @a ~ ~ ~
  execute if data storage aiab:data root.vex run playsound minecraft:entity.vex.charge player @a ~ ~ ~

  # Summon the mob with the right data and maybe automount or pair it
  execute if data storage aiab:data root.allay summon minecraft:allay run function aiab:release/summon
  execute if data storage aiab:data root.vex summon minecraft:vex run function aiab:release/summon

  item replace entity @s weapon.mainhand with minecraft:glass_bottle
}

function summon {
  data modify entity @s NoAI set from storage aiab:data root.data.NoAI
  data modify entity @s CustomName set from storage aiab:data root.data.CustomName
  data modify entity @s Health set from storage aiab:data root.data.Health
  data modify entity @s HandItems set from storage aiab:data root.data.HandItems
  data modify entity @s UUID set from storage aiab:data root.data.UUID
  data modify entity @s DuplicationCooldown set from storage aiab:data root.data.DuplicationCooldown
  data modify entity @s Brain set from storage aiab:data root.data.Brain

  # Auto mount minecarts if there are any
  execute if data storage aiab:data root.allay run ride @s mount @e[type=minecraft:minecart,distance=..1.5,sort=nearest,limit=1]
  # Auto pair note blocks if the area effect cloud was summoned still there
  execute if data storage aiab:data root.allay run {
    execute positioned ~1 ~ ~ if block ~ ~ ~ minecraft:note_block run function aiab:release/pair_noteblock
    execute positioned ~-1 ~ ~ if block ~ ~ ~ minecraft:note_block run function aiab:release/pair_noteblock
    execute positioned ~ ~ ~1 if block ~ ~ ~ minecraft:note_block run function aiab:release/pair_noteblock
    execute positioned ~ ~ ~-1 if block ~ ~ ~ minecraft:note_block run function aiab:release/pair_noteblock
    execute positioned ~ ~1 ~ if block ~ ~ ~ minecraft:note_block run function aiab:release/pair_noteblock
    execute positioned ~ ~-1 ~ if block ~ ~ ~ minecraft:note_block run function aiab:release/pair_noteblock
  }
}

function pair_noteblock {
  log AllayInABottle debug entity <Pair noteblock>

  # "91ec111c-dfb1-4d25-9181-46c732b790ca"
  summon minecraft:area_effect_cloud ~ ~ ~ {UUID: [I; -1846800100, -542028507, -1853798713, 850890954]}

  data merge entity @s {Brain: {memories: {"minecraft:liked_noteblock_cooldown_ticks": {value: 600}, "minecraft:liked_noteblock": {value: {pos: [I; 0, 0, 0], dimension: "minecraft:overworld"}}}}}

  execute if dimension minecraft:the_nether run data modify entity @s Brain.memories."minecraft:liked_noteblock".value.dimension set value "minecraft:the_nether"
  execute if dimension minecraft:the_end run data modify entity @s Brain.memories."minecraft:liked_noteblock".value.dimension set value "minecraft:the_end"

  data modify entity @s Brain.memories."minecraft:liked_noteblock".value.pos[0] set from entity 91ec111c-dfb1-4d25-9181-46c732b790ca Pos[0]
  data modify entity @s Brain.memories."minecraft:liked_noteblock".value.pos[1] set from entity 91ec111c-dfb1-4d25-9181-46c732b790ca Pos[1]
  data modify entity @s Brain.memories."minecraft:liked_noteblock".value.pos[2] set from entity 91ec111c-dfb1-4d25-9181-46c732b790ca Pos[2]
}


blocks air {
  minecraft:air
  minecraft:cave_air
  \#minecraft:rails
}

advancement release {
  "criteria": {
    "requirement": {
      "trigger": "minecraft:using_item",
      "conditions": {
        "item": {
          "items": [
            "minecraft:honey_bottle"
          ],
          "nbt": "{aiab:{mob: 1b}}"
        }
      }
    }
  },
  "rewards": {
    "function": "aiab:release/release"
  }
}
