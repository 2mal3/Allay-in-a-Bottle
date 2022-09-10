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

        summon minecraft:villager ~ 1000 ~ {NoGravity:1b,Silent:1b,Team:"aiab.noCollision",Invulnerable:1b,NoAI:1b,Tags:["aiab.villager","aiab.init"],ActiveEffects:[{Id:14b,Amplifier:1b,Duration:99999,ShowParticles:0b}]}
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
  item replace entity @p weapon.mainhand with minecraft:honey_bottle{display:{Name:'{"text":"Allay in a Bottle","color":"yellow","italic":false}'},CustomModelData:3330301} 1
  item modify entity @p weapon.mainhand aiab:set
  item modify entity @p weapon.mainhand aiab:store

  # Removes the allay
  tp @s ~ -1000 ~
  kill @s
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
    }
  ]
}


## Release allay from a bottle
function release {
  log AllayInABottle debug entity <Released Allay>
  advancement revoke @s only aiab:release

  playsound minecraft:entity.allay.ambient_without_item player @a ~ ~ ~
  execute anchored eyes positioned ^ ^-0.5 ^1.5 run {
    summon minecraft:allay ~ ~ ~ {Tags:["aiab.init"]}
    particle minecraft:end_rod ~ ~0.2 ~ 0.2 0.4 0.2 0 4
  }

  # Transfer stored data to allay
  data modify storage aiab:data data set from entity @s SelectedItem.tag.aiab.data
  execute as @e[type=minecraft:allay,distance=..2,sort=nearest,tag=aiab.init] run {
    tag @s remove aiab.init

    data modify entity @s Health set from storage aiab:data data.Health
    data modify entity @s HandItems set from storage aiab:data data.HandItems
    data modify entity @s Brain set from storage aiab:data data.Brain
  }

  item replace entity @s weapon.mainhand with minecraft:glass_bottle
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
      scoreboard players set $version aiab.data 010001
      # Set variables
      scoreboard players set %id aiab.uuid 0

      # Storages
      #declare storage aiab:data
      data merge storage aiab:data {data:{}}

      # Teams
      team add aiab.noCollision
      team modify aiab.noCollision collisionRule never

      schedule 4s replace {
        tellraw @a {"text":"Allay in a Bottle v1.0.1 by 2mal3 was installed!","color":"green"}
      }
    }
    execute if score %installed aiab.data matches 1 unless score $version aiab.data matches 010001 run {
      log AllayInABottle info server <Updated datapack>
      scoreboard players set $version aiab.data 010001
    }
  }

  function first_join {
    # Gives each player a unique id
    scoreboard players operation @s aiab.uuid = %id aiab.uuid
    scoreboard players add %id aiab.uuid 1

    # Warns the player if he uses a not supported minecraft version
    execute store result score .temp0 aiab.data run data get entity @s DataVersion
    execute unless score .temp0 aiab.data matches 3105..3120 run tellraw @s [{"text":"[","color":"gray"},{"text":"AllayInABottle","color":"gold"},{"text":"/","color":"gray"},{"text":"WARN","color":"gold"},{"text": "/","color": "gray"},{"text": "Server","color": "gold"},{"text":"]: ","color":"gray"},{"text":"This Minecraft version is not supported by the datapack. Please use 1.19 to prevent errors.","color":"gold"}]
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
      "title": "Allay in a Bottle v1.0.1",
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
    tellraw @a {"text":"Allay in a Bottle v1.0.1 by 2mal3 was successfully uninstalled.","color": "green"}

    # Disables the datapack
    datapack disable "file/Allay-in-a-Bottle"
    datapack disable "file/Allay-in-a-Bottle.zip"
  }
}
