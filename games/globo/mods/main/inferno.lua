
local function check_fire_spread(source_pos,ignite_factor)
	-- get all flammable nodes near pos
	--minimal.log("check_fire_spread")
	local pos1={x=source_pos.x-1,y=source_pos.y-1,z=source_pos.z-1}
	local pos2={x=source_pos.x+1,y=source_pos.y+1,z=source_pos.z+1}
	local f = minetest.find_nodes_in_area(pos1,pos2,'group:flammable')
	--minimal.log("check_fire_spread0: "..#f.." "..source_pos.x..","..source_pos.y..","..source_pos.z)
	-- loop through all nodes in f
	for _,tinder_pos in ipairs(f) do
		-- check if node is already on fire
		local meta=minetest.get_meta(tinder_pos)
		local isBurning=meta:get_int("burning") or 0
		--minimal.log("check_fire_spread1: "..dump(isBurning))
		if isBurning==0 then  -- this one isn't on fire already
			-- get the node def
			local node=minetest.get_node(tinder_pos)
			local node_def = minetest.registered_nodes[node.name]
			
			--minimal.log("check_fire_spread: "..dump(node_def.groups.flammable*ignite_factor))
			if math.random(1, 100) < node_def.groups.flammable*ignite_factor then
				local burnTime=node_def.burn_time or 1
				--minimal.log("check_fire_spread3: "..dump(burnTime))
				-- ignite the node
				meta:set_int("burning",1)
				local flame_pos = minetest.find_node_near(tinder_pos, 1, {"air",
								"climate:air_temp",
								"climate:air_temp_visible"})
				if flame_pos ~= nil then			
					minetest.set_node(flame_pos, {name = "main:flame", param2 = burnTime})
					minetest.get_meta(flame_pos):set_string("flame_source",minetest.pos_to_string(tinder_pos))
				end
				
			end
		end
	end
end


local flame_def = {
	drawtype = "firelike",
	tiles = {
		{
			name = "flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "flame.png",
	paramtype = "light",
	light_source = 13,
	temp_effect = 50,
	temp_effect_max = 500,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	floodable = true,
	damage_per_second = 4,
	groups = {igniter = 2, flames = 1, dig_immediate = 3,
		  not_in_creative_inventory = 1,
		  temp_effect = 1, temp_pass = 1},
	drop = "",

	on_timer = function(pos)
		-- node meta should contain what it is burning
		-- determine how long this fire will burn for based on what it is burning
		-- check if it should spread to nearby nodes
		--minimal.log("flame timer")

		-- see if source still exists
		local meta=minetest.get_meta(pos)	
		local source_pos_str=meta:get_string("flame_source")
		--minimal.log("ft source_pos"..dump(source_pos_str))
		local source_pos=minetest.string_to_pos(source_pos_str)
		local source_node=minetest.get_node(source_pos)
		local group_level = minetest.get_item_group(source_node.name, "flammable")

		if group_level < 1 then
			--minimal.log("ft source gone")
			minetest.remove_node(pos)
			return
		end

		--rain, water etc puts it out
		if climate.get_rain(pos) or minetest.find_node_near(pos, 1, {"group:puts_out_fire"}) or math.random()<0.1 then
			meta=minetest.get_meta(source_pos)
			meta:set_int("burning",0)  -- LATER: remove this key from the meta table
			minetest.remove_node(pos)
			return
		end



		
		-- check if we have exceeded the burn time 
		local self=minetest.get_node(pos)
		--minimal.log("ft param2:"..self.param2)
		self.param2=self.param2-1
		if self.param2<1 then
			--minimal.log("ft burn time exceeded")
			minetest.remove_node(pos)
			minetest.set_node(source_pos, {name = "main:ember"})
			minetest.check_for_falling(source_pos)
			return
		end

		check_fire_spread(pos,1)

		-- Restart timer
		return true
	end,

	on_construct = function(pos)
	   minetest.get_node_timer(pos):start(math.random(20,50))
	   --minetest.get_node_timer(pos):start(5)
	end,

	on_flood = function(pos, oldnode, newnode) return false  end,
}

local ember_def = {
    tiles = {"ember.png"},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {-0.125, -0.5, -0.125,  0.125, -0.125, 0.125},
	},
	inventory_image = "ember.png",

	paramtype = "light",
	light_source = 3,
	temp_effect = 5,
	temp_effect_max = 50,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	floodable = true,
	damage_per_second = 1,
	groups = {igniter = 2, dig_immediate = 3, falling_node = 1,
		  temp_effect = 1, temp_pass = 1},


	on_timer = function(pos)
		--minimal.log("ember timer")

		-- embers burn out eventually
		if math.random() < 0.05 then
			--minimal.log("ember dies")
			minetest.remove_node(pos)
			return
		end

		--rain, water etc puts it out
		if climate.get_rain(pos) or minetest.find_node_near(pos, 1, {"group:puts_out_fire"}) then
			--minimal.log("ember wet")
			minetest.remove_node(pos)
			return
		end

		check_fire_spread(pos,.25)

		-- Restart timer
		return true
	end,

	on_construct = function(pos)
	   minetest.get_node_timer(pos):start(30) -- 30
	end,

	on_flood = function(pos, oldnode, newnode) return false  end,
}



minetest.register_node("main:flame", flame_def)
minetest.register_node("main:ember", ember_def)


minetest.register_abm({
	label = "Lava sparks embers",
	nodenames = {"nodes_nature:lava_source"},
	neighbors = {"air"},
	interval = 20, 
	chance = 12, 
	catch_up = false,
	action = function(pos, node)
		if math.random() < 0.1 then  
			minimal.log("lava spark")
			-- put ember on top of random space within 2 nodes of the lava
			local p = minetest.find_node_near(pos, 2, {"air",
								"climate:air_temp",
								"climate:air_temp_visible"})
			minetest.set_node(p, {name = "main:ember"})
		end

		check_fire_spread(pos,.25)
	end,
})

minetest.register_abm({
	label = "Flowing Lava Fire spread",
	nodenames = {"nodes_nature:lava_flowing"},
	neighbors = {"group:flammable"},
	interval = 20, 
	chance = 50,
	catch_up = false,
	action = function(pos, node)
		check_fire_spread(pos,.25)
	end,
})


--
-- ABM
--
-- Remove/convert flammable nodes around basic flame
--remember to set on_burn for the registered node where suitable
-- e.g. to turn trees into tech large fire
--[[
minetest.register_abm({
      label = "Ignite flammable nodes",
      nodenames = {"group:flammable"},
      neighbors = {"group:flames", "group:igniter"},
      interval = 10, -- 20
      chance = 1, -- 12
      catch_up = false,
      action = function(pos, node)
		minimal.log("fire ABM")
		local flammable_node = node
		local def = minetest.registered_nodes[flammable_node.name]
		if math.random(1, 100) > def.groups.flammable then
			return -- resisted burning
		end
		local burnTime=def.burn_time or 1
		if def.on_burn then
			def.on_burn(pos)
			--[[
		elseif minetest.get_item_group(flammable_node.name, "tree") >= 1
			or minetest.get_item_group(flammable_node.name, "log") >= 1 then
				minetest.set_node(pos, {name = "tech:large_wood_fire"})
			if math.random(1,4) == 1 then
				minetest.check_for_falling(pos)
			end  
		else
			local meta=minetest.get_meta(pos)
			local timeBurned=meta:get_int("time_burned") or 0
			minimal.log("timeBurned:"..timeBurned.." burnTime:"..burnTime)
			timeBurned=timeBurned+1
			if timeBurned>burnTime then
				minetest.set_node(pos, {name = "main:ember"})
			else
				meta:set_int("time_burned",timeBurned)
				local p = minetest.find_node_near(pos, 1, {"air",
								"climate:air_temp",
								"climate:air_temp_visible"})
				if p and math.random(1,10) < 10 then
					minetest.set_node(p, {name = "main:flame"})
				elseif minetest.find_node_near(pos, 1, "group:flames") == nil then
					minetest.set_node(pos, {name = "main:flame"})
				else
					minetest.remove_node(pos)
				end
			end			
		end
      end,
}) ]]--
