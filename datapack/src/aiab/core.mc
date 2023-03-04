import ../../macros/log.mcm


function load {
  log AllayInABottle info server <Datapack reloaded>

  scoreboard objectives add aiab.data dummy

  # Initializes the datapack at the first startup or new version
  execute unless score %installed aiab.data matches 1 run function aiab:core/install
  execute if score %installed aiab.data matches 1 unless score $version aiab.data matches <%config.version.int%> run function aiab:core/update
}

function install {
  log AllayInABottle info server <Datapack installed>
  scoreboard players set %installed aiab.data 1

  # Scoreboards
  scoreboard objectives add aiab.data dummy
  scoreboard objectives add aiab.uuid dummy
  scoreboard objectives add 2mal3.debug_mode dummy
  # Set the version in format: xx.xx.xx
  scoreboard players set $version aiab.data <%config.version.int%>
  # Set variables
  scoreboard players set %id aiab.uuid 0

  # Storages
  #declare storage aiab:data
  data merge storage aiab:data {root: {}}

  # Teams
  team add aiab.no_collision
  team modify aiab.no_collision collisionRule never

  schedule 4s replace {
    tellraw @a {"text":"Allay in a Bottle <%config.version.str%> by 2mal3 was installed!","color":"green"}
  }
}

function update {
  # v2.0.0
  execute if score $version aiab.data matches ..10101 run {
    log AllayInABottle info server <Updated datapack to v2.0.0>
    function aiab:core/install
  }

  # v2.0.1
  execute if score $version aiab.data matches 20000 run {
    log AllayInABottle info server <Updated datapack to v2.0.1>
    scoreboard players set $version aiab.data 20001
  }

  # v2.1.0
  execute if score $version aiab.data matches 20001 run {
    log AllayInABottle info server <Updated datapack to v2.1.0>
    scoreboard players set $version aiab.data 20100
  }
}


function first_join {
  # Gives each player a unique id
  scoreboard players operation @s aiab.uuid = %id aiab.uuid
  scoreboard players add %id aiab.uuid 1

  # Warns the player if he uses a not supported server software or minecraft version
  execute store result score .temp_0 aiab.data run data get entity @s DataVersion
  execute unless score .temp_0 aiab.data matches 3105.. run tellraw @s [{"text":"[","color":"gray"},{"text":"AllayInABottle","color":"gold"},{"text":"/","color":"gray"},{"text":"WARN","color":"gold"},{"text": "/","color": "gray"},{"text": "Server","color": "gold"},{"text":"]: ","color":"gray"},{"text":"This Minecraft version is not supported by the datapack. Please use the 1.19.x to prevent errors.","color":"gold"}]
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
    "title": "Allay in a Bottle <%config.version.str%>",
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
  tellraw @a {"text":"Allay in a Bottle <%config.version.str%> by 2mal3 was successfully uninstalled.","color": "green"}

  # Disables the datapack
  datapack disable "file/Allay-in-a-Bottle"
  datapack disable "file/Allay-in-a-Bottle.zip"
}
