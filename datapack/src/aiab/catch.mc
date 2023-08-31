import ../../macros/log.mcm


## Logic for handling the capturing when interacting with the allay
advancement interact {
  "criteria": {
    "requirement": {
      "trigger": "minecraft:player_interacted_with_entity",
      "conditions": {
        "item": {
          "items": [
            "minecraft:glass_bottle"
          ]
        },
        "entity": {
          "type": "minecraft:interaction"
        }
      }
    }
  },
  "rewards": {
    "function": "aiab:catch/interact"
  }
}

function interact {
  log AllayInABottle debug entity Catch
  advancement revoke @s only aiab:catch/interact

  # Special things if the player is holding more than one bottle
  execute unless predicate aiab:catch/holding_one_glass_bottle run {
    log AllayInABottle debug entity <Holding more than one bottle>
    item modify entity @s weapon.mainhand aiab:catch/remove_count
    # 2bca99d0-ca08-4506-bdef-d0370cf4c261
    summon minecraft:item ~ ~ ~ {UUID: [I; 734697936, -905427706, -1108357065, 217367137], Item: {id: "minecraft:glass_bottle", Count: 1b}}
    data modify entity 2bca99d0-ca08-4506-bdef-d0370cf4c261 Item.Count set from entity @s SelectedItem.Count
  }

  # Find the allay the player right clicked, store its data and remove it
  tag @s add aiab.this
  execute as @e[type=minecraft:interaction,distance=..6] at @s run {
    scoreboard players set .temp_0 aiab.data 0
    execute on target if entity @s[tag=aiab.this] run scoreboard players set .temp_0 aiab.data 1
    # execute on target if entity @s[tag=aiab.this] run say hi
    execute if score .temp_0 aiab.data matches 1 run {
      execute as @e[type=#aiab:catch/mobs,distance=..1,sort=nearest,limit=1] run {
        log AllayInABottle debug entity Found

        function aiab:catch/remove_interaction

        data modify storage aiab:data root.data set from entity @s
        data modify storage aiab:data root.mob set value 1b
        execute (if entity @s[type=minecraft:allay]) {
          playsound minecraft:entity.allay.item_taken player @a ~ ~ ~
          data modify storage aiab:data root.allay set value 1b
        } else {
          playsound minecraft:entity.vex.ambient player @a ~ ~ ~
          data modify storage aiab:data root.vex set value 1b
        }
        tp @s ~ -1000 ~

      }
    }
  }
  tag @s remove aiab.this

  # Give the player the new bottle with the allay data
  execute if data storage aiab:data root.allay run item replace entity @p weapon.mainhand with minecraft:honey_bottle{display: {Name: '{"text":"Allay in a Bottle","color":"yellow","italic":false}'}, CustomModelData: 3330301} 1
  execute if data storage aiab:data root.vex run item replace entity @p weapon.mainhand with minecraft:honey_bottle{display: {Name: '{"text":"Vex in a Bottle","color":"yellow","italic":false}'}, CustomModelData: 3330302} 1
  item modify entity @s weapon.mainhand aiab:catch/store
}

modifier store {
  "function": "minecraft:copy_nbt",
  "source": {
    "type": "minecraft:storage",
    "source": "aiab:data"
  },
  "ops": [
    {
      "source": "root",
      "target": "aiab",
      "op": "merge"
    }
  ]
}


modifier remove_count {
  "function": "minecraft:set_count",
  "count": -1,
  "add": true
}

predicate holding_glass_bottle {
  "condition": "minecraft:entity_properties",
  "entity": "this",
  "predicate": {
    "equipment": {
      "mainhand": {
        "items": [
          "minecraft:glass_bottle"
        ]
      }
    }
  }
}

predicate holding_one_glass_bottle {
  "condition": "minecraft:entity_properties",
  "entity": "this",
  "predicate": {
    "equipment": {
      "mainhand": {
        "items": [
          "minecraft:glass_bottle"
        ],
        "count": 1
      }
    }
  }
}

entities mobs {
  minecraft:vex
  minecraft:allay
}


## Logic to link interaction entities to the allays to enable right click detection
clock 1t {
  execute as @e[type=minecraft:allay, tag=!global.ignore, tag=!smithed.entity] at @s run function aiab:catch/clock
  execute as @e[type=minecraft:vex, tag=!global.ignore, tag=!smithed.entity] at @s run function aiab:catch/clock
}

function clock {
  # Create interaction as soon as a valid player is in reach
  execute if entity @s[tag=!aiab.has_interaction] if entity @p[predicate=aiab:catch/holding_glass_bottle,distance=..6] run {
    tag @s add aiab.has_interaction

    execute unless score @s aiab.uuid matches 0.. run {
      scoreboard players add %id aiab.uuid 1
      scoreboard players operation @s aiab.uuid = %id aiab.uuid
    }
    scoreboard players operation .temp_0 aiab.data = @s aiab.uuid

    execute summon minecraft:interaction run {
      scoreboard players operation @s aiab.uuid = .temp_0 aiab.data
      data merge entity @s {response:1b,Tags:["aiab.interaction"]}
    }
  }

  execute if entity @s[tag=aiab.has_interaction] run {
    # Link the interaction to the allay
    scoreboard players operation .search aiab.data = @s aiab.uuid
    execute as @e[type=minecraft:interaction,distance=..2,tag=aiab.interaction] if score @s aiab.uuid = .search aiab.data run tp @s ~ ~-0.2 ~

    # Remove interaction entity when no player is there
    execute unless entity @p[predicate=aiab:catch/holding_glass_bottle,distance=..6] run {
      name remove_interaction

      tag @s remove aiab.has_interaction

      scoreboard players operation .search aiab.data = @s aiab.uuid
      execute as @e[type=minecraft:interaction,distance=..2,tag=aiab.interaction] if score @s aiab.uuid = .search aiab.data run kill @s
    }
  }
}


predicate holding_glass_bottle {
  "condition": "minecraft:entity_properties",
  "entity": "this",
  "predicate": {
    "equipment": {
      "mainhand": {
        "items": [
          "minecraft:glass_bottle"
        ]
      }
    }
  }
}
