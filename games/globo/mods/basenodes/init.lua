local FIRE_SPREAD_CHANCE = 30 -- A chance out of 100 that fire will spread each second
local FIRE_BURN_TIME = 10 -- Time in seconds before a flammable item is destroyed
local FIRE_EXTINGUISH_TIME = 2 -- Time in seconds before fire without fuel goes out
local WATER_ALPHA = "^[opacity:" .. 160
local WATER_VISC = 1
local LAVA_VISC = 7


minetest.register_node("basenodes:dirt_with_grass", {
	description = "Dirt with Grass",
	tiles = {
		"default_grass.png", -- Top texture
		"default_dirt.png",  -- Bottom texture
		"default_dirt.png^default_grass_side.png" -- Side textures
	},
	groups = {crumbly=3, soil=1},
})

--[[
minetest.register_node("basenodes:dirt_with_grass", {
	description = "Dirt with Grass",
	tiles ={"default_grass.png",
		"default_dirt.png",
		{name = "default_dirt.png^default_grass_side.png",
		tileable_vertical = false}},
	groups = {crumbly=3, soil=1,falling_node = 1},
})
]]--

minetest.register_node("basenodes:dirt", {
	description = "Dirt",
	tiles ={"default_dirt.png"},
	groups = {crumbly=3, soil=1, falling_node = 1},
})

minetest.register_node("basenodes:stone", {
	description = "Stone",
	tiles = {"default_stone.png"},
	groups = {cracky=3},
})

minetest.register_node("basenodes:sand", {
	description = "Sand",
	tiles ={"default_sand.png"},
	groups = {crumbly=3, falling_node = 1},
})


minetest.register_node("basenodes:water_source", {
	description = "Water Source".."\n"..
		"Swimmable, spreading, renewable liquid".."\n"..
		"Drowning damage: 1",
	drawtype = "liquid",
	waving = 3,
	tiles = {"default_water.png"..WATER_ALPHA},
	special_tiles = {
		{name = "default_water.png"..WATER_ALPHA, backface_culling = false},
		{name = "default_water.png"..WATER_ALPHA, backface_culling = true},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = "basenodes:water_flowing",
	liquid_alternative_source = "basenodes:water_source",
	liquid_viscosity = WATER_VISC,
	post_effect_color = {a = 64, r = 100, g = 100, b = 200},
	post_effect_color_shaded = true,
	groups = {water = 3, liquid = 3},
})

minetest.register_node("basenodes:water_flowing", {
	description = "Flowing Water".."\n"..
		"Swimmable, spreading, renewable liquid".."\n"..
		"Drowning damage: 1",
	drawtype = "flowingliquid",
	waving = 3,
	tiles = {"default_water_flowing.png"},
	special_tiles = {
		{name = "default_water_flowing.png"..WATER_ALPHA,
			backface_culling = false},
		{name = "default_water_flowing.png"..WATER_ALPHA,
			backface_culling = false},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	liquidtype = "flowing",
	liquid_alternative_flowing = "basenodes:water_flowing",
	liquid_alternative_source = "basenodes:water_source",
	liquid_viscosity = WATER_VISC,
	post_effect_color = {a = 64, r = 100, g = 100, b = 200},
	post_effect_color_shaded = true,
	groups = {water = 3, liquid = 3},
})

minetest.register_node("basenodes:river_water_source", {
	description = "River Water Source".."\n"..
		"Swimmable, spreading, non-renewable liquid".."\n"..
		"Drowning damage: 1",
	drawtype = "liquid",
	waving = 3,
	tiles = { "default_river_water.png"..WATER_ALPHA },
	special_tiles = {
		{name = "default_river_water.png"..WATER_ALPHA, backface_culling = false},
		{name = "default_river_water.png"..WATER_ALPHA, backface_culling = true},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = "basenodes:river_water_flowing",
	liquid_alternative_source = "basenodes:river_water_source",
	liquid_viscosity = 1,
	liquid_renewable = false,
	liquid_range = 2,
	post_effect_color = {a = 103, r = 30, g = 76, b = 90},
	post_effect_color_shaded = true,
	groups = {water = 3, liquid = 3, },
})

minetest.register_node("basenodes:river_water_flowing", {
	description = "Flowing River Water".."\n"..
		"Swimmable, spreading, non-renewable liquid".."\n"..
		"Drowning damage: 1",
	drawtype = "flowingliquid",
	waving = 3,
	tiles = {"default_river_water_flowing.png"..WATER_ALPHA},
	special_tiles = {
		{name = "default_river_water_flowing.png"..WATER_ALPHA,
			backface_culling = false},
		{name = "default_river_water_flowing.png"..WATER_ALPHA,
			backface_culling = false},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	liquidtype = "flowing",
	liquid_alternative_flowing = "basenodes:river_water_flowing",
	liquid_alternative_source = "basenodes:river_water_source",
	liquid_viscosity = 1,
	liquid_renewable = false,
	liquid_range = 2,
	post_effect_color = {a = 103, r = 30, g = 76, b = 90},
	post_effect_color_shaded = true,
	groups = {water = 3, liquid = 3, },
})


minetest.register_node("basenodes:lava_flowing", {
	description = "Flowing Lava".."\n"..
		"Swimmable, spreading, renewable liquid".."\n"..
		"4 damage per second".."\n"..
		"Drowning damage: 1",
	drawtype = "flowingliquid",
	tiles = {"default_lava_flowing.png"},
	special_tiles = {
		{name="default_lava_flowing.png", backface_culling = false},
		{name="default_lava_flowing.png", backface_culling = false},
	},
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	damage_per_second = 4,
	liquidtype = "flowing",
	liquid_alternative_flowing = "basenodes:lava_flowing",
	liquid_alternative_source = "basenodes:lava_source",
	liquid_viscosity = LAVA_VISC,
	post_effect_color = {a=192, r=255, g=64, b=0},
	groups = {lava=3, liquid=1},
})

minetest.register_node("basenodes:lava_source", {
	description = "Lava Source".."\n"..
		"Swimmable, spreading, renewable liquid".."\n"..
		"4 damage per second".."\n"..
		"Drowning damage: 1",
	drawtype = "liquid",
	tiles = { "default_lava.png" },
	special_tiles = {
		{name = "default_lava.png", backface_culling = false},
		{name = "default_lava.png", backface_culling = true},
	},
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	damage_per_second = 4,
	liquidtype = "source",
	liquid_alternative_flowing = "basenodes:lava_flowing",
	liquid_alternative_source = "basenodes:lava_source",
	liquid_viscosity = LAVA_VISC,
	post_effect_color = {a=192, r=255, g=64, b=0},
	groups = {lava=3, liquid=1},
})


minetest.register_node("basenodes:pine_tree", {
	description = "Pine Tree Trunk",
	tiles = {"default_pine_tree_top.png", "default_pine_tree_top.png", "default_pine_tree.png"},
	is_ground_content = false,
	groups = {choppy=2,oddly_breakable_by_hand=1},
})

minetest.register_node("basenodes:pine_needles", {
	description = "Pine Needles",
	drawtype = "allfaces_optional",
	tiles = {"default_pine_needles.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy=3},
})




