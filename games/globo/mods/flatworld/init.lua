

-- sets this for the NEXT map that is generated. very lame
minetest.settings:set("mapgen_limit", MAP_SIZE)

minetest.register_on_mapgen_init(function(mgparams)
    
    minetest.set_mapgen_setting("mg_name", "v7", true)
	local flags = minetest.get_mapgen_setting("mg_flags")

    if flags then
        local new_flags = flags:gsub("caves", "nocaves")
        minetest.set_mapgen_setting("mg_flags", new_flags, true)
    end

end)



minetest.register_alias("mapgen_water_source", "basenodes:water_source")
minetest.register_alias("mapgen_river_water_source", "basenodes:river_water_source")

minetest.register_alias("mapgen_dirt", "basenodes:dirt")
minetest.register_alias("mapgen_stone", "basenodes:dirt")
minetest.register_alias("mapgen_dirt_with_grass", "basenodes:dirt_with_grass")
minetest.register_alias("mapgen_apple", "basenodes:apple")


minetest.clear_registered_biomes()
minetest.clear_registered_decorations()

if minetest.settings:get_bool("devtest_register_biomes", true) then
	minetest.register_biome({
		name = "mapgen:grassland",
		node_top = "basenodes:dirt_with_grass",
		depth_top = 1,
		node_filler = "basenodes:dirt",
		depth_filler = 1,
		node_riverbed = "basenodes:sand",
		depth_riverbed = 2,
		node_dungeon = "basenodes:cobble",
		node_dungeon_alt = "basenodes:mossycobble",
		node_dungeon_stair = "stairs:stair_cobble",
		y_max = 31000,
		y_min = 4,
		heat_point = 50,
		humidity_point = 50,
	})

	minetest.register_biome({
		name = "mapgen:grassland_ocean",
		node_top = "basenodes:sand",
		depth_top = 1,
		node_filler = "basenodes:sand",
		depth_filler = 3,
		node_riverbed = "basenodes:sand",
		depth_riverbed = 2,
		node_cave_liquid = "basenodes:water_source",
		node_dungeon = "basenodes:cobble",
		node_dungeon_alt = "basenodes:mossycobble",
		node_dungeon_stair = "stairs:stair_cobble",
		y_max = 3,
		y_min = -255,
		heat_point = 50,
		humidity_point = 50,
	})

	minetest.register_biome({
		name = "mapgen:grassland_under",
		node_cave_liquid = {"basenodes:water_source", "basenodes:lava_source"},
		node_dungeon = "basenodes:cobble",
		node_dungeon_alt = "basenodes:mossycobble",
		node_dungeon_stair = "stairs:stair_cobble",
		y_max = -256,
		y_min = -31000,
		heat_point = 50,
		humidity_point = 50,
	})
end


