import ../../macros/log.mcm


function release {
  advancement revoke @s only aiab:release/release

  # Iterative function to find block to place on
  scoreboard players set .success aiab.data 0
  scoreboard players set .length aiab.data 45

  execute as @p anchored eyes run block {
    name place_mob

    execute if score .length aiab.data matches 1.. run {
      scoreboard players remove .length aiab.data 1

      execute(unless block ^ ^ ^0.1 #aiab:release/air) {
        scoreboard players set .success aiab.data 1

        summon minecraft:allay ^ ^-0.2 ^-0.2 {Tags: ["aiab.init"]}
        particle minecraft:end_rod ~ ~0.2 ~ 0.2 0.4 0.2 0 4

      } else execute(as @e[type=minecart,dx=0] positioned ~-0.99 ~-0.99 ~-0.99 if entity @s[type=minecart,dx=0] positioned ~0.99 ~0.99 ~0.99) {
        scoreboard players set .success aiab.data 1
        data modify storage aiab:data root set from entity @s
        execute at @e[type=minecart,dx=0] run summon minecart ~ ~ ~ {Tags: ["aiab.cartinit"], Passengers: [{id: "minecraft:allay", Tags: ["aiab.init"]}]}
        kill @s
        execute as @e[type=minecart,tag=aiab.cartinit] run {
          data modify entity @s Motion set from storage aiab:data root.Motion
          data modify entity @s Rotation set from storage aiab:data root.Rotation
          tag @s remove aiab.cartinit
        }
      } else {
        execute positioned ^ ^ ^0.1 run function aiab:release/place_mob
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
          "nbt": "{aiab:{allay: 1b}}"
        }
      }
    }
  },
  "rewards": {
    "function": "aiab:release/release"
  }
}
