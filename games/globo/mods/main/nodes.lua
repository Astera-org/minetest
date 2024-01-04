-- Node Definitions
function start_node_timer(pos)
	local timer = minetest.get_node_timer(pos)
	timer:start(60*1*GAME_SPEED) 
end


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
	light_source = 14, 
	groups = {cracky = 3, falling_node = 1},
	on_punch = function(pos, node, player, pointed_thing)
		-- move this node 1 space in the direction the player is facing if possibl
		local dir = player:get_look_dir()
		--minetest.chat_send_player(player:get_player_name()," " .. dir.x .. " " .. dir.y .. " " .. dir.z)
		local newpos = {x = pos.x + dir.x, y = pos.y, z = pos.z + dir.z}
		if minetest.get_node(newpos).name ~= "air" then
			return
		end
		minetest.set_node(newpos, {name = "main:glow_stone"})
		minetest.remove_node(pos)
		minetest.check_for_falling(newpos)
	end,
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

minetest.register_node("main:brambles", {
	description = "Brambles",
	drawtype = "plantlike",
	tiles = {"brambles.png"},
	inventory_image = "brambles.png",
	wield_image = "brambles.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 40, flora=1},
    damage_per_second = 50,
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
	groups = {snappy = 1,flammable = 20, flora=1},
	on_construct = function(pos)
        local timer = minetest.get_node_timer(pos)
		local t=(math.random(60,270)+math.random(60,270))/2
		timer:start(t*GAME_SPEED) 
    end,
	on_timer = function(pos, elapsed)
		minetest.set_node(pos, {name = "main:pulse_blossom_on"})
		return false 
    end,
})

minetest.register_node("main:pulse_blossom_on", {
	description = "Pulse Blossom",
	drawtype = "plantlike",
	tiles = {"pulse_blossom_on.png"},
	inventory_image = "pulse_blossom.png",
	wield_image = "pulse_blossom.png",
	paramtype = "light",
	light_source= 10,
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 1,flammable = 20, flora=1},
	on_construct = function(pos)
        local timer = minetest.get_node_timer(pos)
		timer:start(10*GAME_SPEED)  
    end,
	on_timer = function(pos, elapsed)
		
		local node = minetest.get_node(pos)
		local p1=node.param2+1
		if p1 == 1 then
			minetest.swap_node(pos, {name = "main:pulse_blossom_on", param2 = p1})
			local timer = minetest.get_node_timer(pos)
			timer:start(1)
			return false 
		end

		if p1 > 10 then
			minetest.set_node(pos, {name = "main:pulse_blossom"})
			return false
		end	

		-- cause damage to any creature around
		local objects = minetest.get_objects_inside_radius(pos, 4)
		for _, obj in ipairs(objects) do
			if obj:is_player() then
				minetest.chat_send_player(obj:get_player_name(), "You have been damaged by a pulse blossom")
				changePlayerHP(obj, -200)
			elseif obj:get_luaentity() ~= nil then
				local mob = obj:get_luaentity()
				mobkit.hurt(mob,200)
			end
		end

		minetest.swap_node(pos, {name = "main:pulse_blossom_on", param2 = p1})
		return true
    end,
})

minetest.register_node("main:player_egg", {
	description = 'Player Egg',
	tiles = {"animals_gundu_eggs.png"},
	stack_max = minimal.stack_max_medium,
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {-0.125, -0.5, -0.125,  0.125, -0.125, 0.125},
	},
	groups = {snappy = 3, falling_node = 1, dig_immediate = 3, flammable = 10,  temp_pass = 1, edible = 1, egg=1},
	on_construct = function(pos)
		--minimal.log("player egg on construct")
		minetest.get_node_timer(pos):start(600*GAME_SPEED)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		--minimal.log("player egg after_place_node")
		minetest.get_meta(pos):set_string("owner", placer:get_player_name())
	end,
	on_timer =function(pos, elapsed)
		local playerName=minetest.get_meta(pos):get_string("owner")
		minimal.log("player egg on timer "..dump(playerName))

		if playerName ~= "" then
			local player=minetest.get_player_by_name(playerName)
			if player ~= nil then
				local meta=player:get_meta()
				local score=meta:get_int("score") or 0
				score=score+1
				meta:set_int("score",score)
			end
		end
		-- remove egg
		minetest.remove_node(pos)
		return false
	end,
})





minetest.register_node("main:thorns", {
	description = "Thorns",
	drawtype = "plantlike",
	tiles = {"thorns_1.png"},
	inventory_image = "thorns_0.png",
	wield_image = "thorns_0.png",
	paramtype = "light",
	damage_per_second = 50,
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 1,flammable = 30, flora=1},
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
	damage_per_second = 50,
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 1, flammable = 30, flora=1},
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
	groups = {snappy = 3, flammable = 30, flora=1},
	on_construct = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(600*GAME_SPEED) 
		minetest.get_meta(pos):set_int("potato",0)
    end,
	on_timer = function(pos, elapsed)
		local meta=minetest.get_meta(pos)
		local pCount=meta:get_int("potato")+1
		if pCount>2 then
			if potatoes_spred(pos) then
				pCount=0
			end
		end
		meta:set_int("potato",pCount)

		return true -- Continue the cycle
    end,
	on_use = function(itemstack, player, pointed_thing)
		addNutrient(player,"hunger",20)
		itemstack:take_item()
		return itemstack
	end,
	on_punch = function(pos, node, player, pointed_thing)
		local meta=minetest.get_meta(pos)
		local pCount=meta:get_int("potato")
		if pCount > 0 then  -- Check if potato
			local inv=player:get_inventory()
			if inv:room_for_item("main", "main:potatoes") then
				--minetest.chat_send_player("singleplayer", "potato harvest taken")
				inv:add_item("main", "main:potatoes")
				meta:set_int("potato",0)
			end
		end
	end,
})


function potatoes_spred(pos)	
	-- Chance of spreading potatoes to adjacent positions
	local positions = minetest.find_nodes_in_area_under_air(
		{x = pos.x - 2, y = pos.y - 1, z = pos.z - 2},
		{x = pos.x + 2, y = pos.y + 1, z = pos.z + 2},
		{"group:spreading"}
	)

	if #positions > 0 then
		local newPos=positions[math.random(#positions)]
		newPos.y=newPos.y+1
		minetest.set_node(newPos, {name = "main:potatoes"})
		return true
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
	groups = {snappy = 3, flammable = 30, flora=1},
	on_punch = function(pos, node, player, pointed_thing)
		changePlayerHP(player,-100)
	end,
})

minetest.register_node("main:moon_berry", {
	description = "Moon Berry",
	drawtype = "plantlike",
	tiles = {"moon_berry.png"},
	inventory_image = "moon_berry.png",
	wield_image = "moon_berry.png",
	paramtype = "light",
	light_source=4,
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 30, flora=1},
})

minetest.register_node("main:sun_berry", {
	description = "Sun Berry",
	drawtype = "plantlike",
	tiles = {"sun_berry.png"},
	inventory_image = "sun_berry.png",
	wield_image = "sun_berry.png",
	paramtype = "light",
	light_source=13,
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flammable = 30, flora=1},
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
	groups = {snappy = 3, flammable = 30, flora=1},
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
	groups = {snappy = 3, flammable = 35, flora = 1}, 
    on_timer = function(pos, elapsed)
        if math.random() < .1 then grib_spread(pos) end
        return true 
    end,
	
    on_construct = function(pos)
		--minetest.log("action", "on_construct grib")
        start_node_timer(pos) 
    end,
})

function grib_spread(pos)	
	-- Chance of spreading grib weed to adjacent positions
	local positions = minetest.find_nodes_in_area_under_air(
		{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y + 1, z = pos.z + 1},
		{"group:flora"}
	)

	if #positions > 0 then
		local newPos=positions[math.random(#positions)]
		if minetest.get_node(newPos).name ~= "main:grib_weed" then
			minetest.set_node(newPos, {name = "main:grib_weed"})
			return
		end
	end

	positions = minetest.find_nodes_in_area_under_air(
		{x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
		{x = pos.x + 1, y = pos.y + 1, z = pos.z + 1},
		{"group:spreading"}
	)

	if #positions > 0 then
		local newPos=positions[math.random(#positions)]
		newPos.y=newPos.y+1
		minetest.set_node(newPos, {name = "main:grib_weed"})
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
	groups = {snappy = 3, flammable = 35, flora=1},
	on_use = minetest.item_eat(3),  
})

minetest.register_node("main:pond", {
	on_construct = function(pos)
		-- TODO: hack since mts files seem annoying

		local pondDepth=math.random(-11,-5)
		local pondDepth2=math.random(-11,-5)
		pondDepth=math.max(pondDepth,pondDepth2)

		for x = -2,2 do
			for z = -2,2 do
				if x==-2 or x==2 or z==-2 or z==2 and math.random()<.5 then
					-- skip this column
				else
					for y=pondDepth+1,1 do
						local p = {x=pos.x+x,y=pos.y+y,z=pos.z+z}
						minetest.set_node(p,{name="air"})
					end

					if x==-2 or x==2 or z==-2 or z==2 and math.random()<.5 then
						-- skip this column
					else
						for y=pondDepth-3,pondDepth do
							local p = {x=pos.x+x,y=pos.y+y,z=pos.z+z}
							minetest.set_node(p,{name="nodes_nature:freshwater_source"})
						end
					end
				end
			end
		end
	end,
})
