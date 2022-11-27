import ../../macros/log.mcm


# Make sure that each player that can catch an allay is linked to a villager
clock 1t {
  name loop

  execute as @a at @s run {
    # Ensures that there is always a villager in the near of players that can catch an allay
    execute if entity @s[gamemode=!spectator,gamemode=!adventure,predicate=aiab:catch/holding_glass_bottle] if predicate aiab:catch/looking_at_allay at @s run {
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

      execute unless predicate aiab:catch/holding_glass_bottle run scoreboard players set .temp0 aiab.data 1
      execute unless predicate aiab:catch/looking_at_allay run scoreboard players set .temp0 aiab.data 1

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
        "type": "#aiab:catch/aiabmobs"
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
    "function": "aiab:catch/catch"
  }
}

function catch {
  advancement revoke @s only aiab:catch/catch
  log AllayInABottle debug entity <Catched Allay>

  # Find the allay the player is looking at
  tag @s add aiab.this0
  execute as @e[type=#aiab:catch/aiabmobs,distance=..5,limit=1,sort=nearest] run {
    scoreboard players set .temp0 aiab.data 0

    tag @s add aiab.this1
    execute as @a[tag=aiab.this0] if predicate aiab:catch/looking_at_filter run scoreboard players set .temp0 aiab.data 1

    execute if score .temp0 aiab.data matches 1 run function aiab:catch/found
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
    execute unless predicate aiab:catch/holding_one_glass_bottle run {
      log AllayInABottle debug entity <Holding more than one bottle>
      item modify entity @s weapon.mainhand aiab:catch/remove_count
      # 2bca99d0-ca08-4506-bdef-d0370cf4c261
      summon minecraft:item ~ ~ ~ {UUID: [I; 734697936, -905427706, -1108357065, 217367137], Item: {id: "minecraft:glass_bottle", Count: 1b}}
      data modify entity 2bca99d0-ca08-4506-bdef-d0370cf4c261 Item.Count set from entity @s SelectedItem.Count
    }
  }
  
  execute (if entity @e[type=minecraft:allay,tag=aiab.this1,distance=..5]) {
      item replace entity @p weapon.mainhand with minecraft:honey_bottle{display: {Name: '{"text":"Allay in a Bottle","color":"yellow","italic":false}'}, CustomModelData: 3330301} 1
      item modify entity @p weapon.mainhand aiab:catch/set
      item modify entity @p weapon.mainhand aiab:catch/storeallay
    } else {
      item replace entity @p weapon.mainhand with minecraft:honey_bottle{display: {Name: '{"text":"Vex in a Bottle","color":"yellow","italic":false}'}, CustomModelData: 3330302} 1
      item modify entity @p weapon.mainhand aiab:catch/set
      item modify entity @p weapon.mainhand aiab:catch/storevex
    }

  # Removes the allay
  tp @s ~ -1000 ~
  kill @s
}

entities aiabmobs {
  minecraft:vex
  minecraft:allay
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
  "tag": "{aiab:{aiabmob:1b}}"
}

modifier storeallay {
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

modifier storevex {
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
      "source": "UUID",
      "target": "aiab.data.UUID",
      "op": "replace"
    },
    {
      "source": "NoAI",
      "target": "aiab.data.NoAI",
      "op": "replace"
    }
  ]
}
