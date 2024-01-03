

--[[ works
minetest.register_entity("animals:test", {
    description = "Test",
    visual_size = {x = 10, y = 10},
	mesh = "animalia_bat.b3d",
    visual = "mesh",
	textures = {
		"animalia_bat_1.png",
		"animalia_bat_2.png",
		"animalia_bat_3.png",
	},
})

minetest.register_entity("animals:test", {
    description = "Test",
    visual = "mesh",
    physical = true,
	collide_with_objects = true,
    on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
    springiness=0,
	buoyancy = 1.01,
	max_speed = 3,					-- m/s
	jump_height = 2,				-- nodes/meters
	view_range = 15,					-- nodes/meters
    collisionbox = {-0.3, -0.01, -0.3, 0.3, 0.84, 0.3},


    visual_size = {x = 10, y = 10},
    mesh = "animalia_cat.b3d",
	textures = {
		"animalia_cat_1.png",
		"animalia_cat_2.png",
		"animalia_cat_3.png",
		"animalia_cat_4.png",
		"animalia_cat_5.png",
		"animalia_cat_6.png",
		"animalia_cat_7.png",
		"animalia_cat_8.png",
		"animalia_cat_9.png",
		"animalia_cat_ash.png",
		"animalia_cat_birch.png",
	},
})

minetest.register_entity("animals:test", {
    description = "Test",
    visual = "mesh",
    physical = true,
	collide_with_objects = true,
    on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
    springiness=0,
	buoyancy = 1.01,
	max_speed = 3,					-- m/s
	jump_height = 2,				-- nodes/meters
	view_range = 15,					-- nodes/meters
    collisionbox = {-0.3, -0.01, -0.3, 0.3, 0.84, 0.3},


    visual_size = {x = 10, y = 10},
    mesh = "animalia_chicken.b3d",
	textures = {
		"animalia_chicken_1.png",
		"animalia_chicken_2.png",
		"animalia_chicken_3.png"
	},
	male_textures = {
		"animalia_rooster_1.png",
		"animalia_rooster_2.png",
		"animalia_rooster_3.png"
	},
})

minetest.register_entity("animals:test", {
    description = "Test",
    visual = "mesh",
    physical = true,
	collide_with_objects = true,
    on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
    springiness=0,
	buoyancy = 1.01,
	max_speed = 3,					-- m/s
	jump_height = 2,				-- nodes/meters
	view_range = 15,					-- nodes/meters
    collisionbox = {-0.3, -0.01, -0.3, 0.3, 0.84, 0.3},


    visual_size = {x = 10, y = 10},
    mesh = "animalia_cow.b3d",
	female_textures = {
		"animalia_cow_1.png^animalia_cow_udder.png",
		"animalia_cow_2.png^animalia_cow_udder.png",
		"animalia_cow_3.png^animalia_cow_udder.png",
		"animalia_cow_4.png^animalia_cow_udder.png",
		"animalia_cow_5.png^animalia_cow_udder.png"
	},
	textures = {
		"animalia_cow_1.png",
		"animalia_cow_2.png",
		"animalia_cow_3.png",
		"animalia_cow_4.png",
		"animalia_cow_5.png"
	},
	child_textures = {
		"animalia_cow_1.png",
		"animalia_cow_2.png",
		"animalia_cow_3.png",
		"animalia_cow_4.png",
		"animalia_cow_5.png"
	},
})

]]--

minetest.register_entity("animals:test", {
    description = "Test",
    visual = "mesh",
    physical = true,
	collide_with_objects = true,
    on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
    springiness=0,
	buoyancy = 1.01,
	max_speed = 3,					-- m/s
	jump_height = 2,				-- nodes/meters
	view_range = 15,					-- nodes/meters
    collisionbox = {-0.3, -0.01, -0.3, 0.3, 0.84, 0.3},


    visual_size = {x = 10, y = 10},
    mesh = "animalia_rat.b3d",
	textures = {
		"animalia_rat_1.png",
		"animalia_rat_2.png",
		"animalia_rat_3.png"
	},
})

