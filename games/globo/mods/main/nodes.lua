-- Node Definitions
function start_node_timer(pos)
	local timer = minetest.get_node_timer(pos)
	timer:start(60*1*GAME_SPEED) 
end


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

minetest.register_node("main:pulse_blossom", {
	description = "Pulse Blossom",
	drawtype = "plantlike",
	tiles = {"pulse_blossom.png"},
	inventory_image = "pulse_blossom.png",
	wield_image = "pulse_blossom.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 1},
	on_construct = function(pos)
        local timer = minetest.get_node_timer(pos)
		local t=(math.random(60,270)+math.random(60,270))/2
		timer:start(t*GAME_SPEED) 
    end,
	on_timer = function(pos, elapsed)
		print("start pulse")
		minetest.set_node(pos, {name = "main:pulse_blossom_on"})

		return false 
    end,
})

minetest.register_node("main:pulse_blossom_on", {
	description = "Pulse Blossom",
	drawtype = "plantlike",
	tiles = {"pulse_blossom.png"},
	inventory_image = "pulse_blossom.png",
	wield_image = "pulse_blossom.png",
	paramtype = "light",
	light_source= 10,
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 1},
	on_construct = function(pos)
        start_node_timer(pos) 
    end,
	on_timer = function(pos, elapsed)
		local node = minetest.get_node(pos)
		local p1=node.param1+1
		if p1 > 10 then
			minetest.set_node(pos, {name = "main:pulse_blossom"})
			return false
		end

		local ret = true
		if p1 == 1 then
			ret=false
			local timer = minetest.get_node_timer(pos)
			timer:start(10*GAME_SPEED) 
		end
		-- cause damage to any creature around
		local objects = minetest.get_objects_inside_radius(pos, 3)
		for _, obj in ipairs(objects) do
			if obj:is_player() then
				local player = obj:get_player_name()
				changePlayerHP(player, -1)
			elseif obj:is_player() == false and obj:get_luaentity() ~= nil then
				local mob = obj:get_luaentity()
				mob:set_hp(mob:get_hp() - 1)
			end
		end

		minetest.swap_node(pos, {name = "main:pulse_blossom_on", param1 = p1})
		return ret
    end,
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
	on_construct = function(pos)
        start_node_timer(pos) 
    end,
	on_timer = function(pos, elapsed)
		if math.random(1, 1000) <= 60 then
			minetest.set_node(pos, {name = "main:thorns_fruit"})
		end
		return true -- Continue the cycle
    end,
})

minetest.register_node("main:thorns_fruit", {
	description = "Thorns",
	drawtype = "plantlike",
	tiles = {"thorns_3.png"	},
	inventory_image = "thorns_0.png",
	wield_image = "thorns_0.png",
	paramtype = "light",
	damage_per_second = 1,
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 1},
	on_punch = function(pos, node, player, pointed_thing)
		addNutrient(player,"hunger",100)
		minetest.set_node(pos, {name = "main:thorns"})
	end,
})

minetest.register_node("main:potatoes", {
	description = "Potatoes",
	drawtype = "plantlike",
	tiles = {"potato_plant.png"},
	inventory_image = "potato.png",
	wield_image = "potato.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 2, flora=1},
	on_construct = function(pos)
        start_node_timer(pos) 
    end,
	on_timer = function(pos, elapsed)
		local node = minetest.get_node(pos)
		local p1=node.param1+1
		local p2=node.param2
	
		if p1 > 10 then
			if p2 == 0 then  -- Check if potato
				p2=1 -- Set potato state
			end
			if p1 > 30 then
				if potatoes_spred(pos) then
					p1=10
				end
			end
		end
		minetest.swap_node(pos, {name = "main:potatoes", param1 = p1, param2=p2})
		return true -- Continue the cycle
    end,
	on_use = function(itemstack, player, pointed_thing)
		addNutrient(player,"hunger",100)
		itemstack:take_item()
		return itemstack
	end,
	on_punch = function(pos, node, player, pointed_thing)
		if node.param2 == 1 then  -- Check if potato
			local inv=player:get_inventory()
			if inv:room_for_item("main", "main:potatoes") then
				--minetest.chat_send_player("singleplayer", "potato harvest taken")
				inv:add_item("main", "main:potatoes")
				minetest.swap_node(pos, {name = "main:potatoes", param1 = 0, param2 = 0}) -- Set potato state
			end
		end
	end,
})


function potatoes_spred(pos)	
	-- Chance of spreading potatoes to adjacent positions
	local positions = minetest.find_nodes_in_area(
		{x = pos.x - 2, y = pos.y - 1, z = pos.z - 2},
		{x = pos.x + 2, y = pos.y + 1, z = pos.z + 2},
		{"air"}
	)

	local newPos=positions[math.random(#positions)]

	local node_under = minetest.get_node({x = newPos.x, y = newPos.y - 1, z = newPos.z})
	if node_under.name == "basenodes:dirt" or node_under.name == "basenodes:dirt_with_grass" then
		if minetest.get_node(newPos).name == "air" then
			print("spread potatoes")
			minetest.set_node(newPos, {name = "main:potatoes"})
			return true
		end
	end
	return false
end



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
	on_punch = function(pos, node, player, pointed_thing)
		changePlayerHP(player,-2)
	end,
})

minetest.register_node("main:sun_berry", {
	description = "Sun Berry",
	drawtype = "plantlike",
	tiles = {"sun_berry.png"},
	inventory_image = "sun_berry.png",
	wield_image = "sun_berry.png",
	paramtype = "light",
	light_source=4,
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 2, flora=1},
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
	on_punch = function(pos, node, player, pointed_thing)
		changePlayerEnergy(player,200)
	end,
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
		--print("place grib")
        start_node_timer(pos) 
    end,
    on_construct = function(pos)
		--minetest.log("action", "on_construct grib")
        start_node_timer(pos) 
    end,
})


function grib_kill(pos)
    -- Replaces grib weed with air, effectively "killing" it
    minetest.set_node(pos, {name = "air"})
end

function grib_spread(pos)	
	-- Chance of spreading grib weed to adjacent positions
	local positions = minetest.find_nodes_in_area(
		{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y + 1, z = pos.z + 1},
		{"group:flora", "air"}
	)
	for _, p in ipairs(positions) do
		if math.random(1, 1000) <= 20 then
			local node_under = minetest.get_node({x = p.x, y = p.y - 1, z = p.z})
			if node_under.name == "basenodes:dirt" or node_under.name == "basenodes:dirt_with_grass" then
				if minetest.get_node(p).name == "air" or minetest.get_node(p).name:find("group:flora") then
					--minetest.log("action", "spread_grib_weed")
					minetest.set_node(p, {name = "main:grib_weed"})
				end
			end
		end
	end
end


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
