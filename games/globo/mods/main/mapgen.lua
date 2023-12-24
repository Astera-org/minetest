minetest.register_alias("mapgen_stone", "nodes_nature:conglomerate")
minetest.register_alias("mapgen_water_source", "nodes_nature:salt_water_source")
minetest.register_alias("mapgen_river_water_source", "nodes_nature:freshwater_source")

-- sets this for the NEXT map that is generated. very lame
minetest.settings:set("mapgen_limit", MAP_SIZE)

minetest.register_on_mapgen_init(function(mgparams)
    
    minetest.set_mapgen_setting("mg_name", "valleys", true)
	local flags = minetest.get_mapgen_setting("mg_flags")

    if flags then
        local new_flags = flags:gsub("caves", "nocaves")
        minetest.set_mapgen_setting("mg_flags", new_flags, true)
    end

end)


-- registerDecorations()


