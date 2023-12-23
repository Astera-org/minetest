nodes_nature = {}

-- Internationalization
nodes_nature.S = minetest.get_translator("nodes_nature")

-- Load files
local path = minetest.get_modpath("nodes_nature")


--------------------------------

dofile(path.."/sounds.lua")
dofile(path.."/data_plant.lua")
dofile(path.."/data_rock.lua")

dofile(path.."/sediment.lua")
dofile(path.."/rock.lua")
dofile(path.."/ore.lua")
dofile(path.."/life.lua")
dofile(path.."/trees.lua")
dofile(path.."/liquids.lua")

dofile(path.."/flora_spread.lua")
dofile(path.."/dripping_water.lua")
dofile(path.."/moisture_spread.lua")
