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
	groups = {snappy = 3},
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
})

minetest.register_node("main:potatoes", {
	description = "Potatoes",
	drawtype = "plantlike",
	tiles = {"potatoes.png"},
	inventory_image = "potatoes.png",
	wield_image = "potatoes.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 2},
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
	groups = {snappy = 3, flammable = 2},
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
	groups = {snappy = 3, flammable = 2},
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
	groups = {snappy = 3, flammable = 2},
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
	groups = {snappy = 3, flammable = 2},
})

minetest.register_node("main:corn", {
	description = "Corn",
	drawtype = "plantlike",
	tiles = {"corn.png"},
	inventory_image = "corn.png",
	wield_image = "corn.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 2},
	on_use = minetest.item_eat(3),  
})
