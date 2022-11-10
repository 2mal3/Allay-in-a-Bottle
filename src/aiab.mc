import ../macros/log.mcm


## Catch the allay in a bottle
# Make sure that each player that can catch an allay is linked to a villager
clock 1t {
  name loop

  execute as @a at @s run {
    # Ensures that there is always a villager in the near of players that can catch an allay
    execute if entity @s[gamemode=!spectator,gamemode=!adventure,predicate=aiab:holding_glass_bottle] if predicate aiab:looking_at_allay at @s run {
      # Summons a click detection villager if the player first can catch a allay
      execute unless entity @s[tag=aiab.canCatchAllay] run {
        tag @s add aiab.canCatchAllay

        summon minecraft:villager ~ 1000 ~ {NoGravity: 1b, Silent: 1b, Team: "aiab.noCollision", Invulnerable: 1b, NoAI: 1b, Tags: ["aiab.villager", "aiab.init"], ActiveEffects: [{Id: 14b, Amplifier: 1b, Duration: 99999, ShowParticles: 0b}]}
        # Gives the villager the same uuid as the player
        scoreboard players operation .temp0 aiab.data = @s aiab.uuid
        execute as @e[type=minecraft:villager,sort=nearest,tag=aiab.init] run {
          tag @s remove aiab.init

          tp @s ~ ~ ~
          scoreboard players operation @s aiab.uuid = .temp0 aiab.data
        }
      }

      # Tp the summoned villager to the player as long as he can catch the ally
      scoreboard players operation .temp0 aiab.data = @s aiab.uuid
      execute as @e[type=minecraft:villager,sort=nearest,tag=aiab.villager] if score @s aiab.uuid = .temp0 aiab.data run tp @s ~ ~ ~
    }

    # Removes the summoned villager if the player can no longer catch the allay
    execute if entity @s[tag=aiab.canCatchAllay] run {
      scoreboard players set .temp0 aiab.data 0

      execute unless predicate aiab:holding_glass_bottle run scoreboard players set .temp0 aiab.data 1
      execute unless predicate aiab:looking_at_allay run scoreboard players set .temp0 aiab.data 1

      execute if score .temp0 aiab.data matches 1 run {
        tag @s remove aiab.canCatchAllay

        scoreboard players operation .temp0 aiab.data = @s aiab.uuid
        execute as @e[type=minecraft:villager,sort=nearest,tag=aiab.villager] if score @s aiab.uuid = .temp0 aiab.data run {
          tp @s ~ -1000 ~
          kill @s
        }
      }
    }
  }
}

predicate looking_at_allay {
  "condition": "minecraft:entity_properties",
  "entity": "this",
  "predicate": {
    "type_specific": {
      "type": "player",
      "looking_at": {
        "type": "minecraft:allay"
      }
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

# Catches the allay in a bottle if the player interacts with the summoned villager
advancement catch {
  "criteria": {
    "requirement": {
      "trigger": "minecraft:player_interacted_with_entity",
      "conditions": {
        "player": {
          "nbt": "{Tags:[\"aiab.canCatchAllay\"]}"
        },
        "entity": {
          "type": "minecraft:villager",
          "nbt": "{Tags:[\"aiab.villager\"]}"
        }
      }
    }
  },
  "rewards": {
    "function": "aiab:catch"
  }
}

function catch {
  advancement revoke @s only aiab:catch
  log AllayInABottle debug entity <Catched Allay>

  # Find the allay the player is looking at
  tag @s add aiab.this0
  execute as @e[type=minecraft:allay,distance=..5] run {
    scoreboard players set .temp0 aiab.data 0

    tag @s add aiab.this1
    execute as @a[tag=aiab.this0] if predicate aiab:looking_at_filter run scoreboard players set .temp0 aiab.data 1
    tag @s remove aiab.this1

    execute if score .temp0 aiab.data matches 1 run function aiab:found
  }
  tag @s remove aiab.this0
}

predicate looking_at_filter {
  "condition": "minecraft:entity_properties",
  "entity": "this",
  "predicate": {
    "type_specific": {
      "type": "player",
      "looking_at": {
        "nbt": "{Tags: [\"aiab.this1\"]}"
      }
    }
  }
}

# The allay is found
function found {
  # Some effects
  playsound minecraft:entity.allay.item_taken player @a ~ ~ ~

  # Gives the player the allay in a bottle
  execute as @p at @s run {
    # Special things if the player is holding more than one bottle
    execute unless predicate aiab:holding_one_glass_bottle run {
      log AllayInABottle debug entity <Holding more than one bottle>
      item modify entity @s weapon.mainhand aiab:remove_count
      # 2bca99d0-ca08-4506-bdef-d0370cf4c261
      summon minecraft:item ~ ~ ~ {UUID: [I; 734697936, -905427706, -1108357065, 217367137], Item: {id: "minecraft:glass_bottle", Count: 1b}}
      data modify entity 2bca99d0-ca08-4506-bdef-d0370cf4c261 Item.Count set from entity @s SelectedItem.Count
    }

    item replace entity @s weapon.mainhand with minecraft:honey_bottle{display: {Name: '{"text":"Allay in a Bottle","color":"yellow","italic":false}'}, CustomModelData: 3330301} 1
    item modify entity @s weapon.mainhand aiab:set
  }
  item modify entity @p weapon.mainhand aiab:store

  # Removes the allay
  tp @s ~ -1000 ~
  kill @s
}

modifier remove_count {
  "function": "minecraft:set_count",
  "count": -1,
  "add": true
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

modifier set {
  "function": "minecraft:set_nbt",
  "tag": "{aiab:{allay:1b}}"
}

modifier store {
  "function": "minecraft:copy_nbt",
  "source": "this",
  "ops": [
    {
      "source": "Health",
      "target": "aiab.data.Health",
      "op": "replace"
    },
    {
      "source": "HandItems",
      "target": "aiab.data.HandItems",
      "op": "replace"
    },
    {
      "source": "Brain",
      "target": "aiab.data.Brain",
      "op": "replace"
    },
    {
      "source": "UUID",
      "target": "aiab.data.UUID",
      "op": "replace"
    },
    {
      "source": "DuplicationCooldown",
      "target": "aiab.data.DuplicationCooldown",
      "op": "replace"
    },
    {
      "source": "NoAI",
      "target": "aiab.data.NoAI",
      "op": "replace"
    }
  ]
}


## Release allay from a bottle
function release {
  advancement revoke @s only aiab:release

  # Iterative function to find block to place on
  scoreboard players set .success aiab.data 0
  scoreboard players set .length aiab.data 45

  execute as @p anchored eyes run block {
    name place_mob

    execute if score .length aiab.data matches 1.. run {
      scoreboard players remove .length aiab.data 1

      execute(unless block ^ ^ ^0.1 #aiab:air) {
        scoreboard players set .success aiab.data 1

        summon minecraft:allay ^ ^-0.2 ^-0.2 {Tags: ["aiab.init"]}
        particle minecraft:end_rod ~ ~0.2 ~ 0.2 0.4 0.2 0 4
      } else {
        execute positioned ^ ^ ^0.1 run function aiab:place_mob
      }
    }
  }

  # Transfer stored data to allay if allay was placed
  execute if score .success aiab.data matches 1 run {
    log AllayInABottle debug entity <Released Allay>

    data modify storage aiab:data root set from entity @s SelectedItem.tag.aiab.data
    execute as @e[type=minecraft:allay,tag=aiab.init] run {
      tag @s remove aiab.init

      data modify entity @s Health set from storage aiab:data root.Health
      data modify entity @s HandItems set from storage aiab:data root.HandItems
      data modify entity @s Brain set from storage aiab:data root.Brain
      data modify entity @s UUID set from storage aiab:data root.UUID
      data modify entity @s DuplicationCooldown set from storage aiab:data root.DuplicationCooldown
      data modify entity @s NoAI set from storage aiab:data root.NoAI
    }
    playsound minecraft:entity.allay.ambient_without_item player @a ~ ~ ~
    item replace entity @s weapon.mainhand with minecraft:glass_bottle
  }
}


blocks air {
  minecraft:air
  minecraft:cave_air
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
          "nbt": "{aiab:{allay: 1b}}"
        }
      }
    }
  },
  "rewards": {
    "function": "aiab:release"
  }
}


## Core function
dir core {
  function load {

    log AllayInABottle info server <Datapack reloaded>

    scoreboard objectives add aiab.data dummy

    # Initializes the datapack at the first startup or new version
    execute unless score %installed aiab.data matches 1 run {
      log AllayInABottle info server <Datapack installed>
      scoreboard players set %installed aiab.data 1

      # Scoreboards
      scoreboard objectives add aiab.data dummy
      scoreboard objectives add aiab.uuid dummy
      scoreboard objectives add 2mal3.debugMode dummy
      # Set the version in format: xx.xx.xx
      scoreboard players set $version aiab.data 010003
      # Set variables
      scoreboard players set %id aiab.uuid 0

      # Storages
      #declare storage aiab:data
      data merge storage aiab:data {root: {}}

      # Teams
      team add aiab.noCollision
      team modify aiab.noCollision collisionRule never

      schedule 4s replace {
        tellraw @a {"text":"Allay in a Bottle v1.0.3 by 2mal3 was installed!","color":"green"}
      }
    }
    execute if score %installed aiab.data matches 1 unless score $version aiab.data matches 010003 run {
      execute if score $version aiab.data matches 010000 run {
        log AllayInABottle info server <Updated datapack from v1.0.0 to v1.0.1>
        scoreboard players set $version aiab.data 010001
      }

      # v1.0.2
      execute if score $version aiab.data matches 010001 run {
        log AllayInABottle info server <Updated datapack from v1.0.1 to v1.0.2>
        scoreboard players set $version aiab.data 010002
      }

      # v1.0.3
      execute if score $version aiab.data matches 010002 run {
        log AllayInABottle info server <Updated datapack from v1.0.2 to v1.0.3>
        scoreboard players set $version aiab.data 010003

        # Update storage root name
        data remove storage aiab:data data
        data merge storage aiab:data {root: {}}
      }

    }
  }

  function first_join {
    # Gives each player a unique id
    scoreboard players operation @s aiab.uuid = %id aiab.uuid
    scoreboard players add %id aiab.uuid 1
  }

  advancement first_join {
    "criteria": {
        "requirement": {
            "trigger": "minecraft:tick"
        }
    },
    "rewards": {
        "function": "aiab:core/first_join"
    }
  }

  advancement aiab {
    "display": {
      "title": "Allay in a Bottle v1.0.3",
      "description": "Transport Allays with bottles!",
      "icon": {
        "item": "minecraft:honey_bottle",
        "nbt": "{CustomModelData:3330301}"
      },
      "announce_to_chat": false,
      "show_toast": false
    },
    "parent": "global:2mal3",
    "criteria": {
      "trigger": {
        "trigger": "minecraft:tick"
      }
    }
  }

  function uninstall {
    log AllayInABottle info server <Datapack uninstalled>

    # Deletes the scoreboards
    scoreboard objectives remove aiab.data
    scoreboard objectives remove aiab.uuid

    # Sends an uninstallation message to all players
    tellraw @a {"text":"Allay in a Bottle v1.0.3 by 2mal3 was successfully uninstalled.","color": "green"}

    # Disables the datapack
    datapack disable "file/Allay-in-a-Bottle"
    datapack disable "file/Allay-in-a-Bottle.zip"
  }
}
