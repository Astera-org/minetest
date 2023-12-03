local FIRE_SPREAD_CHANCE = 30 -- A chance out of 100 that fire will spread each second
local FIRE_BURN_TIME = 10 -- Time in seconds before a flammable item is destroyed
local FIRE_EXTINGUISH_TIME = 2 -- Time in seconds before fire without fuel goes out
local WATER_ALPHA = "^[opacity:" .. 160
local WATER_VISC = 1
local LAVA_VISC = 7


minetest.register_node("basenodes:corpse", {
	description = "Corpse".."\n"..
		"Punch: Eat (+5)",
	drawtype = "plantlike",
	tiles = {"basenodes_corpse.png"},
	inventory_image = "basenodes_corpse.png",
	wield_image = "basenodes_corpse.png",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	groups = {dig_immediate=3},
	on_timer = function(pos, elapsed)
		minetest.set_node(pos, {name = "basenodes:bones"})
	end,
	on_construct = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(180) -- time in seconds until the corpse turns into bones
	end,
	-- Eating the Corpse will reduce hunger
	on_use = function(itemstack, user, pointed_thing)
		addNutrient(user,"hunger",200) -- hunger reduction value may be changed as needed.
		itemstack:take_item()
		return itemstack
	end,
})

minetest.register_node("basenodes:bones", {
	description = "Bones",
	drawtype = "plantlike",
	tiles = {"basenodes_bones.png"},
	inventory_image = "basenodes_bones.png",
	wield_image = "basenodes_bones.png",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	groups = {dig_immediate=3},
	on_punch = function(pos, node, player)
		minetest.remove_node(pos)
		player:get_inventory():add_item('main', 'basenodes:tool_bones')
	end,
})

minetest.register_node("basenodes:fire", {
    description = "Fire",
    drawtype = "firelike",
    tiles = {{
        name = "fire_basic_flame_animated.png",
        animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 1},
    }},
    inventory_image = "fire_basic_flame.png",
    light_source = 14,
    groups = {igniter = 2, dig_immediate = 3},
    drop = '',
    walkable = false,
    buildable_to = true,
    damage_per_second = 4,
    on_timer = function(pos, elapsed)
        -- Check for flammable things around the fire
        if not spread_fire(pos) then
            -- Extinguish fire if there are no flammable things to burn
            minetest.get_node_timer(pos):start(FIRE_EXTINGUISH_TIME)
        else
            minetest.get_node_timer(pos):start(1)
        end
    end,
    on_construct = function(pos)
        -- Start a timer that tries to spread the fire every second
        local timer = minetest.get_node_timer(pos)
        timer:start(1)
    end,
    on_blast = function() end, -- Fire cannot be exploded
})

-- Function to check for flammable nodes, spread fire, or extinguish fire
function spread_fire(pos)
    -- flammable group is used to determine if nodes are flammable
    local has_flammable_around = false
    local positions = minetest.find_nodes_in_area(
        {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
        {x = pos.x + 1, y = pos.y + 1, z = pos.z + 1}, {"group:flammable"}
    )
    for _, flammable_pos in ipairs(positions) do
        has_flammable_around = true
        if math.random(0, 99) < FIRE_SPREAD_CHANCE then
            minetest.set_node(flammable_pos, {name = "basenodes:fire"})
        end
    end

    local positions_water = minetest.find_nodes_in_area(
        {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
        {x = pos.x + 1, y = pos.y + 1, z = pos.z + 1}, {"group:water"}
    )
    for _, water_pos in ipairs(positions_water) do
        minetest.remove_node(pos)
        return false -- fire extinguished by water
    end

    return has_flammable_around
end

-- Function to destroy flammable items
minetest.register_abm({
    label = "Fire consumes flammable items",
    nodenames = {"group:flammable"},
    neighbors = {"basenodes:fire"},
    interval = 1.0,
    chance = 1,
    action = function(pos, node)
        local timer = minetest.get_node_timer(pos)
        if not timer:is_started() then
            timer:start(FIRE_BURN_TIME)
        end
    end,
    on_timer = function(pos, elapsed)
        minetest.remove_node(pos) -- Destroy the flammable node
        minetest.check_for_falling(pos) -- Check for falling nodes
        return false -- Stop the timer
    end
})

minetest.register_node("basenodes:dirt_with_grass", {
	description = "Dirt with Grass",
	tiles ={"default_grass.png",
		-- a little dot on the bottom to distinguish it from dirt
		"default_dirt.png^basenodes_dirt_with_grass_bottom.png",
		{name = "default_dirt.png^default_grass_side.png",
		tileable_vertical = false}},
	groups = {crumbly=3, soil=1},
})


minetest.register_node("basenodes:dirt", {
	description = "Dirt",
	tiles ={"default_dirt.png"},
	groups = {crumbly=3, soil=1},
})

minetest.register_node("basenodes:stone", {
	description = "Stone",
	tiles = {"default_stone.png"},
	groups = {cracky=3},
})

minetest.register_node("basenodes:sand", {
	description = "Sand",
	tiles ={"default_sand.png"},
	groups = {crumbly=3},
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


minetest.register_node("basenodes:apple", {
	description = "Apple".."\n"..
		"Punch: Eat (+2)",
	drawtype = "plantlike",
	tiles ={"default_apple.png"},
	inventory_image = "default_apple.png",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	groups = {dig_immediate=3},

	-- Make eatable because why not?
	on_use = minetest.item_eat(2),
})

minetest.register_node("basenodes:snowblock", {
	description = "Snow Block",
	tiles ={"default_snow.png"},
	groups = {crumbly=3},
})


