import ../../macros/log.mcm


function load {
  log AllayInABottle info server <Datapack reloaded>

  scoreboard objectives add aiab.data dummy

  # Initializes the datapack at the first startup or new version
  execute unless score %installed aiab.data matches 1 run {
    name install

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
  execute if score %installed aiab.data matches 1 unless score $version aiab.data matches <%config.version.int%> run {
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

    # v1.1.0
    execute if score $version aiab.data matches 010003 run {
      log AllayInABottle info server <Updated datapack from v1.0.3 to v1.1.0>
      scoreboard players set $version aiab.data 10100
    }

    # v1.1.1
    execute if score $version aiab.data matches 10100 run {
      log AllayInABottle info server <Updated datapack from v1.1.0 to v1.1.1>
      scoreboard players set $version aiab.data 10101
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
