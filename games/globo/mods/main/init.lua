


-- Values that need to be moved into a config file

-- won't allow you to go below 64. World goes gray
MAP_SIZE=256

STARVE_1_MUL=7
STARVE_2_MUL=5

APPLE_CHANCE_DIE=25
SNOW_CHANCE_DIE=25

NUM_SNOW=20
NUM_APPLE=20

CHANCE_APPLE_SPAWN=10
CHANCE_SNOW_SPAWN=10


-- Globo settings
START_TEMPERATURE=98

-- Inventory settings
INVENTORY_SIZE = 2  -- Players can only hold 2 items at a time in inventory

HEAL_RATE = 0.5
HEAL_RATE_SLEEP = 1

PLAYER_STARVE_RATE = 0.5
PLAYER_DEHYDRATION_RATE =0.5

-- Energy settings
ENERGY_MAX_START = 1000  -- Starting maximum energy
ENERGY_RECOVERY_RATE = 2  -- Rate at which energy is recovered per second when still
ENERGY_RECOVERY_RATE_SLEEP = 10
ENERGY_WALK_COST = 3     -- Cost of energy per second while walking
ENERGY_RUN_COST = 10      -- Cost of energy per second while running
ENERGY_JUMP_COST = 20     -- Cost of energy per jump

SLEEP_STARVE_COE=0.3 
TIRED_RATE=0.5

local default_path = minetest.get_modpath("main")
dofile(default_path.."/player.lua")
dofile(default_path.."/creatures.lua")
dofile(default_path.."/nodes.lua")
dofile(default_path.."/decorations.lua")