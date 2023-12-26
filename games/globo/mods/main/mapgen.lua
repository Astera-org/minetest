minetest.register_alias("mapgen_stone", "nodes_nature:conglomerate")
minetest.register_alias("mapgen_water_source", "nodes_nature:salt_water_source")
minetest.register_alias("mapgen_river_water_source", "nodes_nature:freshwater_source")

-- sets this for the NEXT map that is generated. very lame
-- minetest.settings:set("mapgen_limit", MAP_SIZE)

minetest.set_mapgen_setting("mg_name", "valleys", true)
minetest.set_mapgen_setting("mg_flags", "nocaves, nodungeons, light, decorations, biomes", true)
minetest.set_mapgen_setting("mgvalleys_spflags", "altitude_chill, humid_rivers, vary_river_depth, altitude_dry", true)
	


-- registerDecorations()


