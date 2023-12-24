


-- The hand
minetest.register_item(":", {
	type = "none",
	wield_image = "wieldhand.png",
	wield_scale = {x=1,y=1,z=2.5},
	liquids_pointable = true,
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level = 1,
		groupcaps = {
			choppy = {times={[3]=minimal.hand_chop}, uses=0, maxlevel=1},
			crumbly = {times={[3]=minimal.hand_crum}, uses=0, maxlevel=1},
			snappy = {times={[3]=minimal.hand_snap}, uses=0, maxlevel=1},
			oddly_breakable_by_hand = {times={[1]=minimal.hand_crum*minimal.t_scale1,[2]=minimal.hand_crum*minimal.t_scale2,[3]=minimal.hand_crum}, uses=0},
		},
		damage_groups = {fleshy=minimal.hand_dmg},
	}
})

--[[
minetest.register_item(":", {
	type = "none",
	wield_image = "wieldhand.png",
	wield_scale = {x = 1, y = 1, z = 2.5},
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level = 0,
	},
	})
]]--

minetest.register_tool("main:rock", {
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

minetest.register_tool("main:tool_bones", {
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
