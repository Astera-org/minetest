-- Node Definitions

minetest.register_node("main:corpse", {
	description = "Corpse".."\n"..
		"Punch: Eat (+5)",
	drawtype = "plantlike",
	tiles = {"corpse.png"},
	inventory_image = "corpse.png",
	wield_image = "corpse.png",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	groups = {dig_immediate=3},
	on_timer = function(pos, elapsed)
		minetest.set_node(pos, {name = "main:bones"})
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

minetest.register_node("main:bones", {
	description = "Bones",
	drawtype = "plantlike",
	tiles = {"bones.png"},
	inventory_image = "bones.png",
	wield_image = "bones.png",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	walkable = false,
	groups = {dig_immediate=3},
	on_punch = function(pos, node, player)
		minetest.remove_node(pos)
		player:get_inventory():add_item('main', 'main:tool_bones')
	end,
})

minetest.register_node("main:glow_stone", {
	description = "Glow Stone",
	drawtype = "normal",
	tiles = {"glow_stone.png"},
	light_source = 7, 
	groups = {cracky = 3},
})

minetest.register_node("main:apple", {
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

minetest.register_node("main:snowblock", {
	description = "Snow Block",
	tiles ={"default_snow.png"},
	groups = {crumbly=3},
})

minetest.register_node("main:brambles", {
	description = "Brambles",
	drawtype = "plantlike",
	tiles = {"brambles.png"},
	inventory_image = "brambles.png",
	wield_image = "brambles.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flora=1},
    damage_per_second = 1,
})

minetest.register_node("main:thorns", {
	description = "Thorns",
	drawtype = "plantlike",
	tiles = {"thorns_1.png"},
	inventory_image = "thorns_0.png",
	wield_image = "thorns_0.png",
	paramtype = "light",
	damage_per_second = 1,
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 1},
    damage_per_second = 1,
})

minetest.register_node("main:potatoes", {
	description = "Potatoes",
	drawtype = "plantlike",
	tiles = {"potato_plant.png"},
	inventory_image = "potato_plant.png",
	wield_image = "potato_plant.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 2, flora=1},
	on_use = minetest.item_eat(1),  -- Assuming it's eatable
})

minetest.register_node("main:sumac", {
	description = "Sumac",
	drawtype = "plantlike",
	tiles = {"sumac.png"},
	inventory_image = "sumac.png",
	wield_image = "sumac.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 2, flora=1},
})

minetest.register_node("main:sun_berry", {
	description = "Sun Berry",
	drawtype = "plantlike",
	tiles = {"sun_berry.png"},
	inventory_image = "sun_berry.png",
	wield_image = "sun_berry.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 2, flora=1},
	on_use = minetest.item_eat(2),  -- Assuming it's eatable
})

minetest.register_node("main:coffee", {
	description = "Coffee",
	drawtype = "plantlike",
	tiles = {"coffee.png"},
	inventory_image = "coffee.png",
	wield_image = "coffee.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 2, flora=1},
})

minetest.register_node("main:grib_weed", {
	description = "Grib Weed",
	drawtype = "plantlike",
	tiles = {"grib_weed.png"},
	inventory_image = "grib_weed.png",
	wield_image = "grib_weed.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 2, flora = 1}, 
    on_timer = function(pos, elapsed)
        grib_spread(pos)
        return true -- Continue the cycle
    end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		print("place grib")
        grib_start_timer(pos) 
    end,
    on_construct = function(pos)
		minetest.log("action", "on_construct grib")
        grib_start_timer(pos) 
    end,
})

function grib_start_timer(pos)
	-- Starts a timer for grib weed's life cycle
	local timer = minetest.get_node_timer(pos)
	timer:start(20) 
end

function grib_kill(pos)
    -- Replaces grib weed with air, effectively "killing" it
    minetest.set_node(pos, {name = "air"})
end

function grib_spread(pos)
	minetest.log("action", "spread_grib_weed")
	-- Chance of spreading grib weed to adjacent positions
	local positions = minetest.find_nodes_in_area(
		{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y + 1, z = pos.z + 1},
		{"group:flora", "air"}
	)
	for _, p in ipairs(positions) do
		if math.random(1, 100) <= 10 then
			local node_under = minetest.get_node({x = p.x, y = p.y - 1, z = p.z})
			if node_under.name == "default:dirt" or node_under.name == "default:dirt_with_grass" then
				if minetest.get_node(p).name == "air" or minetest.get_node(p).name:find("group:flora") then
					minetest.set_node(p, {name = "main:grib_weed"})
				end
			end
		end
	end
end
--[[ 
local function on_construct_grib_weed(pos)
    -- Starts a timer for grib weed's life cycle
    local timer = minetest.get_node_timer(pos)
    timer:start(20) 
end

local function on_timer_grib_weed(pos, elapsed)
	spread_grib_weed(pos)
    return true -- Continue the cycle

    Get temperature at position, and if it's below 0, kill grib weed
    local temp = minetest.get_meta(pos):get_int("temperature")
    if temp and temp < 0 then
        kill_grib_weed(pos)
    else
        spread_grib_weed(pos)
        return true -- Continue the cycle
    end	
end
]]--


minetest.register_node("main:corn", {
	description = "Corn",
	drawtype = "plantlike",
	tiles = {"corn.png"},
	inventory_image = "corn.png",
	wield_image = "corn.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 2, flora=1},
	on_use = minetest.item_eat(3),  
})
