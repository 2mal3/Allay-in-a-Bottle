import ../../macros/log.mcm


advancement drink {
  "criteria": {
    "requirement": {
      "trigger": "minecraft:consume_item",
      "conditions": {
        "item": {
          "items": [
            "minecraft:honey_bottle"
          ],
          "nbt": "{aiab:{allay:1b}}"
        }
      }
    }
  },
  "rewards": {
    "function": "aiab:drink/drink"
  }
}

function drink {
  log AllayInABottle debug entity <Drink Allay in a Bottle>
  advancement revoke @s only aiab:drink/drink

  playsound minecraft:entity.allay.death player @a ~ ~ ~ 0.5 2
  execute anchored eyes run particle minecraft:end_rod ^ ^-0.5 ^0.4 0.2 0.2 0.2 0 4

  effect give @s minecraft:slow_falling 6 0 true
  effect give @s minecraft:levitation 3 0 true
}
