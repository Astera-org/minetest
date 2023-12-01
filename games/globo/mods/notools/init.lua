
minetest.register_item(":", {
	type = "none",
	wield_image = "wieldhand.png",
	wield_scale = {x = 1, y = 1, z = 2.5},
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level = 0,
	},

	on_use = function(itemstack, user, pointed_thing)		
		if pointed_thing.type == "node" then
			local pos = pointed_thing.under
			local node = minetest.get_node(pos)
	
			if node.name == "basenodes:apple" then
				addNutrient(user,"hunger",100)
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
			end
		end
	end,
	
})
