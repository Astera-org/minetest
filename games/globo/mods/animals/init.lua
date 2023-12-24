animals = {}

-- Internationalization
animals.S = minetest.get_translator("animals")

local path = minetest.get_modpath(minetest.get_current_modname())

dofile(path.."/crafts.lua")
dofile(path.."/api_capture.lua")
dofile(path.."/api.lua")


dofile(path.."/impethu.lua")
dofile(path.."/kubwakubwa.lua")
dofile(path.."/darkasthaan.lua")

dofile(path.."/gundu.lua")
dofile(path.."/sarkamos.lua")

dofile(path.."/pegasun.lua")
dofile(path.."/sneachan.lua")

dofile(path.."/badger.lua")
dofile(path.."/chaoshawk.lua")
dofile(path.."/cow.lua")
dofile(path.."/frostmephit.lua")
dofile(path.."/giantmoth.lua")
dofile(path.."/lavaox.lua")
dofile(path.."/mongoose.lua")
dofile(path.."/ogre.lua")
dofile(path.."/sandslug.lua")
dofile(path.."/snagon.lua")
dofile(path.."/wolf.lua")


---
--Food Web

--[[
The aim is for mobs to be permanent populations, rather than spawning "ex nihilo".
Therefore most are small animals with small ranges. Have actual food webs that keep them alive.

Ocean:
"plankton (water)" -> gundu -> sarkamos


Caves:
"invisibly small stuff" -> impethu -> kubwakubwa/darkasthaan-> darkasthaan



Land:
plants/dirt/sneachan -> pegasun














]]
