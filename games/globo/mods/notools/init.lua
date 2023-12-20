


minetest.register_item(":", {
	type = "none",
	wield_image = "wieldhand.png",
	wield_scale = {x = 1, y = 1, z = 2.5},
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level = 0,
	},
--[[
	on_use = function(itemstack, player, pointed_thing)		
		if pointed_thing.type == "node" then
			local pos = pointed_thing.under
			local node = minetest.get_node(pos)
	
			if node.name == "basenodes:apple" then
				addNutrient(player,"hunger",100)
				if math.random(0,99) < APPLE_CHANCE_DIE then
					local pos = pointed_thing.under
					minetest.remove_node(pos)
				end
			elseif node.name == "basenodes:snowblock" then
				addNutrient(user,"thirst",100)
				if math.random(0,99) < SNOW_CHANCE_DIE then
					local pos = pointed_thing.under
					minetest.remove_node(pos)
				end
			elseif node.name == "basenodes:pine_tree" and
			    itemstack:get_name() == "notools:rock" then
				minetest.remove_node(pos)
				minetest.add_item(pos, 'basenodes:pine_tree')
			end
		end
	return nil
	end,
	]]--
	})

minetest.register_tool("notools:rock", {
	description = "Rock",
	inventory_image = "default_stone.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level = 0,
		groupcaps={
			choppy = {times = {[2] = 2.00, [3] = 1.00}, uses = 20, maxlevel = 1},
		},
	},
})

minetest.register_tool("notools:tool_bones", {
	description = "Bone Tool",
	inventory_image = "basenodes_tool_bones.png",
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level = 1,
		groupcaps={
			crumbly = {times = {[1]=2.00, [2]=1.00}, uses = 20, maxlevel = 1},
			snappy = {times = {[2]=3.00, [3]=2.40}, uses = 20, maxlevel = 1},
		},
		damage_groups = {fleshy=2},
	},
})
