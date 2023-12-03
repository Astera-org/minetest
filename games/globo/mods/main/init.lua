


-- Values that need to be moved into a config file

-- won't allow you to go below 64. World goes gray
MAP_SIZE=64

MIN_COORD=-32 -- TODO why these numbers?
MAX_COORD=47

STARVE_1_MUL=15
STARVE_2_MUL=10

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

-- Energy settings
ENERGY_MAX_START = 1000  -- Starting maximum energy
ENERGY_RECOVERY_RATE = 1  -- Rate at which energy is recovered per second when still
ENERGY_WALK_COST = 1     -- Cost of energy per second while walking
ENERGY_RUN_COST = 10      -- Cost of energy per second while running
ENERGY_JUMP_COST = 20     -- Cost of energy per jump

local default_path = minetest.get_modpath("main")
dofile(default_path.."/player.lua")