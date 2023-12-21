
function registerDecorations()
    print("register decorations")
    
    minetest.register_decoration({
        deco_type = "simple",
        place_on = {"basenodes:dirt_with_grass"},
        sidelen = 16,
        fill_ratio = 0.005,
        biomes = {"mapgen:grassland"},
        decoration = "main:brambles",
    })

    minetest.register_decoration({
        name="thorn_deco",
        deco_type = "simple",
        place_on = {"basenodes:dirt_with_grass"},
        sidelen = 16,
        fill_ratio = 0.003,
        biomes = {"mapgen:grassland"},
        decoration = "main:thorns",
    })

    minetest.register_decoration({
        name="potatoes_deco",
        deco_type = "simple",
        place_on = {"basenodes:dirt_with_grass"},
        sidelen = 16,
        fill_ratio = 0.004,
        biomes = {"mapgen:grassland"},
        decoration = "main:potatoes",
    })

    minetest.register_decoration({
        deco_type = "simple",
        place_on = {"basenodes:dirt_with_grass"},
        sidelen = 16,
        fill_ratio = 0.002,
        biomes = {"mapgen:grassland"},
        decoration = "main:sumac",
    })

    minetest.register_decoration({
        name="pulse_blossom_deco",
        deco_type = "simple",
        place_on = {"basenodes:dirt_with_grass"},
        sidelen = 16,
        fill_ratio = 0.002,
        biomes = {"mapgen:grassland"},
        decoration = "main:pulse_blossom",
    })

    minetest.register_decoration({
        deco_type = "simple",
        place_on = {"basenodes:dirt_with_grass"},
        sidelen = 16,
        fill_ratio = 0.003,
        biomes = {"mapgen:grassland"},
        decoration = "main:sun_berry",
    })

    minetest.register_decoration({
        deco_type = "simple",
        place_on = {"basenodes:dirt_with_grass"},
        sidelen = 16,
        fill_ratio = 0.001,
        biomes = {"mapgen:grassland"},
        decoration = "main:coffee",
    })

    minetest.register_decoration({
        name = "grib_weed_deco",
        deco_type = "simple",
        place_on = {"basenodes:dirt_with_grass"},
        sidelen = 16,
        fill_ratio = 0.0001,
        biomes = {"mapgen:grassland"},
        decoration = "main:grib_weed",
        flags = {node_dust = "main:grib_weed", gen_notify = true},
    })

    minetest.register_decoration({
        deco_type = "simple",
        place_on = {"basenodes:dirt_with_grass"},
        sidelen = 16,
        fill_ratio = 0.004,
        biomes = {"mapgen:grassland"},
        decoration = "main:corn",
    })
    
    minetest.register_decoration({
        deco_type = "simple",
        place_on = {"basenodes:dirt_with_grass"},
        sidelen = 80,
        fill_ratio = 0.001,
        decoration = "basenodes:glow_stone",
    })

    minetest.register_decoration({
        deco_type = "simple",
        place_on = {"basenodes:dirt_with_grass"},
        sidelen = 80,
        fill_ratio = 0.01,
        decoration = "basenodes:apple",
    })

    minetest.register_decoration({
        deco_type = "simple",
        place_on = {"basenodes:dirt_with_grass"},
        sidelen = 80,
        fill_ratio = 0.01,
        decoration = "basenodes:snowblock",
    })
end
