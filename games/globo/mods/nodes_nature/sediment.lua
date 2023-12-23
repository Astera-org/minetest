---------------------------------------------------------
--SEDIMENT
--
----------------------------------------------------------

-- Internationalization
local S = nodes_nature.S

-- Useful objects for node definitions
sediment = {}
sediment.hardness = {
   soft = 3,
   medium = 2,
   hard = 1,
}
local hardness = sediment.hardness

local textures = {
    wet = "nodes_nature_mud.png",
    salty = "nodes_nature_mud_salt.png",
    agri_top = "nodes_nature_ag_top.png",
    agri_side = "nodes_nature_ag_side.png",
    agri_top_depleted = "nodes_nature_ag_dep_top.png",
    agri_side_depleted = "nodes_nature_ag_dep_side.png",
}

sediment.sounds = {
    dirt = nodes_nature.node_sound_dirt_defaults(),
    dirt_wet = nodes_nature.node_sound_dirt_defaults({
            footstep = {name = "nodes_nature_mud", gain = 0.4},
            dug = {name = "nodes_nature_mud", gain = 0.4}}),

    sand = nodes_nature.node_sound_sand_defaults(),
    sand_wet = nodes_nature.node_sound_sand_defaults({
            footstep = {name = "nodes_nature_mud", gain = 0.4},
            dug = {name = "nodes_nature_mud", gain = 0.4}}),

    gravel = nodes_nature.node_sound_gravel_defaults(),
    gravel_wet = nodes_nature.node_sound_gravel_defaults({
            footstep = {name = "nodes_nature_mud", gain = 0.4},
            dug = {name = "nodes_nature_mud", gain = 0.4}}),
}
local sounds = sediment.sounds

-- Utility functions
-----------------------------------

local function merge_tables (t1, t2)
    local new_table = {}
    --copy table
    for key, value in pairs(t1) do
        new_table[key] = value
    end
    --merge tables
    for key, value in pairs(t2) do
        new_table[key] = value
    end
    return new_table
end

-- Soil erosion and fertilizers
-----------------------------------

--soil degrades from farming
local function erode_deplete_ag_soil(pos, depleted_name)
	local c = math.random()
	--rain makes this more likely (erosive, washes nutrient out)
	local adjust = 1
	if climate.get_rain(pos) then
	   adjust = 2
	end

	if c < (0.05 * adjust) then -- 90-95% chance nothing happens
	   return true
	end
	--4-8% chance of rain/water erosion
	if c > (0.01 * adjust) then
		--erode if exposed, and near water or raining
		local positions = minetest.find_nodes_in_area(
			{x = pos.x - 1, y = pos.y, z = pos.z - 1},
			{x = pos.x + 1, y = pos.y, z = pos.z + 1},
			{"group:water", "air"})

		if #positions >= 1 then
			local name = minetest.get_node(pos).name
			local new = name:gsub("%_depleted","")
			new = new:gsub("%_agricultural_soil","")
			--would prefer stairs:slab, but sand/etc lacks wet
			new = new:gsub("%nature:","%nature:slope_pike_")
			minetest.swap_node(pos, {name = new})
			return false
		end

	elseif minetest.get_node({x=pos.x, y=(pos.y+1), z=pos.z}) == 'air' then
	        -- ^ don't deplete a planted node; already handled in life.lua
		-- and a 1-2% chance to be depleted via neglect
		minetest.swap_node(pos, {name = depleted_name})
		return false
	end
end

--For using fertilizer on punch
local function fertilize_ag_soil(pos, puncher, restored_name)
   --hit it with fertilizer to restore
   local itemstack = puncher:get_wielded_item()
   local ist_name = itemstack:get_name()

   if minetest.get_item_group(ist_name, "fertilizer") >= 1 then
      minetest.swap_node(pos, {name = restored_name})
      local inv = puncher:get_inventory()
      inv:remove_item("main", ist_name)
   end
end

-- Sediments
-----------------------------------

function sediment.new(args)
   local groups =
      {falling_node = 1, crumbly = args.hardness, sediment = args.fertility}
   local mod_name = args.mod_name or "nodes_nature" -- allows making artificial soils
   local node_name = mod_name..":"..args.name
   local texture_name = args.texture_name or mod_name.."_"..args.name..".png"
   local sed = {
      name = args.name,
      description = args.description,
      hardness = args.hardness,
      fertility = args.fertility,
      texture_name = texture_name,
      dry_node_name = node_name,
      wet_node_name = node_name.."_wet",
      wet_salty_node_name = node_name.."_wet_salty",
      ag_soil = node_name.."_agricultural_soil",
      ag_soil_wet = node_name.."_agricultural_soil_wet",
      sound = args.sound,
      sound_wet = args.sound_wet,
      groups = groups,
      groups_wet =
	 merge_tables(groups, {wet_sediment = 1, puts_out_fire = 1}),
      groups_wet_salty =
	 merge_tables(groups, {wet_sediment = 2, puts_out_fire = 1}),
      mod_name = mod_name,

   }
   return sed
end

local function get_dry_node_props(sed)
    local props = {
        description = sed.description,
        tiles = {sed.texture_name},
        stack_max = minimal.stack_max_bulky,
        groups = table.copy(sed.groups),
        drop = sed.dry_node_name,
        sounds = sed.sound,
        _wet_name = sed.wet_node_name,
        _wet_salty_name = sed.wet_salty_node_name,
    }
    props.groups.bare_sediment = 1
    return props
end

function sediment.register_dry(sed)
    local props = get_dry_node_props(sed)
    minetest.register_node(sed.dry_node_name, props)
end

local function get_wet_node_props(sed)
    local props = {
        description = S("Wet @1", sed.description),
        tiles = {sed.texture_name.."^"..textures.wet},
        stack_max = minimal.stack_max_bulky,
        groups = table.copy(sed.groups_wet),
        drop = sed.wet_node_name,
        sounds = sed.sound_wet,
        _dry_name = sed.dry_node_name,
    }
    props.groups.bare_sediment = 1
    return props
end

function sediment.register_wet(sed)
    local props = get_wet_node_props(sed)
    minetest.register_node(sed.wet_node_name, props)
end

local function get_wet_salty_node_props(sed)
    local props = {
        description = S("Salty Wet @1", sed.description),
        tiles = {sed.texture_name.."^"..textures.wet.."^"..textures.salty},
        stack_max = minimal.stack_max_bulky,
        groups = sed.groups_wet_salty,
        drop = sed.wet_salty_node_name,
        sounds = sed.sound_wet,
        _dry_name = sed.dry_node_name,
    }
    return props
end

function sediment.register_wet_salty(sed)
    local props = get_wet_salty_node_props(sed)
    minetest.register_node(sed.wet_salty_node_name, props)
end

function sediment.register_stair_and_slab(sed)
    stairs.register_stair_and_slab(
        sed.name,
        sed.dry_node_name,
        "mixing_spot",
        "true",
        {falling_node = 1, crumbly = sed.hardness},
        {sed.texture_name},
        sed.description.." Stair",
        sed.description.." Slab",
        minimal.stack_max_bulky * 2,
        sed.sound
    )
end

function sediment.do_slopes(sed)
    local doslopes = minetest.settings:get_bool('exile_enableslopes')
    local slopechance = minetest.settings:get('exile_slopechance') or 20
    if doslopes then
        naturalslopeslib.register_slope(sed.dry_node_name, {}, slopechance)
        naturalslopeslib.register_slope(sed.wet_node_name, {}, slopechance)
        naturalslopeslib.register_slope(sed.wet_salty_node_name, {}, slopechance)
    end
end

-- Soils
-----------------------------------
soil = {}

function soil.new(args)
    local mod_name = args.mod_name or "nodes_nature"
    local node_name = mod_name..":"..args.name
    local soil = {
        name = args.name,
        description = args.description,
        sediment = args.sediment,
        dry_node_name = node_name,
        wet_node_name = node_name.."_wet",

        texture_name = mod_name.."_"..args.name..".png",
        texture_side_name = mod_name.."_"..args.name.."_side.png",
    }
    return soil
end

function soil.register_dry(soil)
    local sed = soil.sediment
    local additional_properties = {
        description = soil.description,
        groups = merge_tables(sed.groups, {spreading = 1}),
        tiles = {soil.texture_name, sed.texture_name,
                 {name = sed.texture_name.."^"..soil.texture_side_name}},
        _ag_soil = sed.ag_soil,
        _wet_name = soil.wet_node_name,
    }
    local sed_props = get_dry_node_props(sed)
    local soil_props = merge_tables(sed_props, additional_properties)
    minetest.register_node(soil.dry_node_name, soil_props)
end

function soil.register_wet(soil)
    local sed = soil.sediment
    local additional_properties = {
        description = S("Wet @1", soil.description),
	groups = merge_tables(sed.groups, {wet_sediment = 1, puts_out_fire = 1,
				       spreading = 1}),
        tiles = {soil.texture_name.."^"..textures.wet, sed.texture_name.."^"..textures.wet,
                 {name = sed.texture_name.."^"..soil.texture_side_name.."^"..textures.wet}},
        _ag_soil = sed.ag_soil_wet,
        _dry_name = sed.dry_node_name,
    }
    local sed_props = get_wet_node_props(sed)
    local soil_props = merge_tables(sed_props, additional_properties)
    minetest.register_node(soil.wet_node_name, soil_props)
end

function soil.do_slopes(soil)
    local doslopes = minetest.settings:get_bool('exile_enableslopes')
    local slopechance = minetest.settings:get('exile_slopechance') or 20
    if doslopes then
        naturalslopeslib.register_slope(soil.dry_node_name, {}, slopechance)
        naturalslopeslib.register_slope(soil.wet_node_name, {}, slopechance)
    end
end

-- Agricultural soils
-----------------------------------
agricultural_soil = {}

function agricultural_soil.new(args)
    local sed = args.sediment
    local name = args.name
    local mod_name = args.mod_name or sed.mod_name or "nodes_nature"
    local node_name = mod_name..":"..name
    local ag_soil = {
        name = name,
        description = args.description,
        sediment = sed,
        texture_name = textures.agri_top,
        texture_side_name = textures.agri_side,
        texture_depleted_name = textures.agri_top_depleted,
        texture_depleted_side_name = textures.agri_side_depleted,
        dry_node_name = node_name,
        wet_node_name = node_name.."_wet",
        depleted_node_name = node_name.."_depleted",
        wet_depleted_node_name = node_name.."_wet_depleted",
    }
    return ag_soil
end

function agricultural_soil.register_dry(ag_soil)
    local sed = ag_soil.sediment
    local props = {
        description = ag_soil.description,
        tiles = {
            {name = sed.texture_name.."^"..ag_soil.texture_name},
            sed.texture_name,
            {name = sed.texture_name.."^"..ag_soil.texture_side_name}},
        stack_max = minimal.stack_max_bulky,
        groups = merge_tables(sed.groups, {agricultural_soil = 1}),
        sounds = sed.sound,
        drop = sed.dry_node_name,
        _wet_name = ag_soil.wet_node_name,
        _wet_salty_name = sed.wet_salty_node_name,
        on_construct = function(pos)
            --speed of erosion, degrade to depleted
            minetest.get_node_timer(pos):start(math.random(90, 300))
        end,
        on_timer = function(pos,elapsed)
            return erode_deplete_ag_soil(pos, ag_soil.depleted_node_name)
        end,
    }
    minetest.register_node(ag_soil.dry_node_name, props)
end

function agricultural_soil.register_wet(ag_soil)
    local sed = ag_soil.sediment
    local props = {
        description = S("Wet @1", ag_soil.description),
        tiles = {
            {name = sed.texture_name.."^"..ag_soil.texture_name.."^"..textures.wet},
            sed.texture_name.."^"..textures.wet,
            {name = sed.texture_name.."^"..ag_soil.texture_side_name.."^"..textures.wet}},
        stack_max = minimal.stack_max_bulky,
        groups = merge_tables(sed.groups_wet, {agricultural_soil = 1}),
        sounds = sed.sound_wet,
        drop = sed.wet_node_name,
        _dry_name = ag_soil.dry_node_name,
        on_construct = function(pos)
            --speed of erosion, degrade to depleted
            minetest.get_node_timer(pos):start(math.random(90, 300))
        end,
        on_timer = function(pos, elapsed)
            return erode_deplete_ag_soil(pos, ag_soil.depleted_node_name)
        end,
    }
    minetest.register_node(ag_soil.wet_node_name, props)
end

function agricultural_soil.register_depleted(ag_soil)
    local sed = ag_soil.sediment
    local props = {
        description = S("Depleted @1", ag_soil.description),
        tiles = {
            {name = sed.texture_name.."^"..ag_soil.texture_depleted_name},
            sed.texture_name,
            {name = sed.texture_name.."^"..ag_soil.texture_depleted_side_name}},
        stack_max = minimal.stack_max_bulky,
        groups = merge_tables(sed.groups, {depleted_agricultural_soil = 1}),
        sounds = sed.sound,
        drop = sed.dry_node_name,
        _wet_name = ag_soil.wet_depleted_node_name,
        _wet_salty_name = sed.wet_salty_node_name,
        on_punch = function(pos, node, puncher, pointed_thing)
            fertilize_ag_soil(pos, puncher, ag_soil.dry_node_name)
        end,
        on_construct = function(pos)
            --speed of erosion, reversion to natural/depleted
            minetest.get_node_timer(pos):start(math.random(60, 300))
        end,
        on_timer = function(pos,elapsed)
            return erode_deplete_ag_soil(pos, sed.dry_node_name)
        end,
    }
    minetest.register_node(ag_soil.depleted_node_name, props)
end

function agricultural_soil.register_wet_depleted(ag_soil)
    local sed = ag_soil.sediment
    local props = {
        description = S("Wet Depleted @1", ag_soil.description),
        tiles = {
            {name = sed.texture_name.."^"..ag_soil.texture_depleted_name.."^"..textures.wet},
            sed.texture_name.."^"..textures.wet,
            {name = sed.texture_name.."^"..ag_soil.texture_depleted_side_name.."^"..textures.wet}},
        stack_max = minimal.stack_max_bulky,
        groups = merge_tables(sed.groups_wet, {depleted_agricultural_soil = 1}),
        sounds = sed.sound_wet,
        drop = sed.wet_node_name,
        _dry_name = ag_soil.dry_node_name,
        on_punch = function(pos, node, puncher, pointed_thing)
            fertilize_ag_soil(pos, puncher, ag_soil.wet_node_name)
        end,
        on_construct = function(pos)
            --speed of erosion, reversion to natural/depleted
            minetest.get_node_timer(pos):start(math.random(60, 300))
        end,
        on_timer = function(pos,elapsed)
            return erode_deplete_ag_soil(pos, sed.wet_node_name)
        end,
    }
    minetest.register_node(ag_soil.wet_depleted_node_name, props)
end

function agricultural_soil.register_recipe(agri_soil)
    crafting.register_recipe({
            type = "mixing_spot",
            output = agri_soil.dry_node_name,
            items = {agri_soil.sediment.dry_node_name.." 1","group:fertilizer 1"},
            level = 1,
            always_known = true,
    })
end

function agricultural_soil.register_recipe_wet(agri_soil)
    crafting.register_recipe({
            type = "mixing_spot",
            output = agri_soil.wet_node_name,
            items = {agri_soil.sediment.wet_node_name.." 1","group:fertilizer 1"},
            level = 1,
            always_known = true,
    })
end

-- Functions for making sets: sediment + soil + agricultural soil
---------------------------------------------------

-- Registers sediments, their slabs, wet, salty, slopes etc. and crafting recipes
function sediment.register_sed_variants(sed)
    sediment.register_dry(sed)
    sediment.register_wet(sed)
    sediment.register_wet_salty(sed)
    sediment.register_stair_and_slab(sed)
    sediment.do_slopes(sed)
end

-- Registers agricultural soils and their variants
-- (dry, wet, depleted) and recipes to craft them
function sediment.register_agri_soil_variants(sed)
    local agri =
        agricultural_soil.new({name = sed.name.."_agricultural_soil",
                               description = S("@1 Agricultural Soil", sed.description),
                               sediment = sed})
    agricultural_soil.register_dry(agri)
    agricultural_soil.register_wet(agri)
    agricultural_soil.register_depleted(agri)
    agricultural_soil.register_wet_depleted(agri)
    agricultural_soil.register_recipe(agri)
    agricultural_soil.register_recipe_wet(agri)
end

-- Registers soils with "grasses" and their variants including slopes
function sediment.register_soil_variants(soil_list)
    for _, s in ipairs(soil_list) do
        soil.register_dry(s)
        soil.register_wet(s)
        soil.do_slopes(s)
    end
end

-- Registers sediments, their variants (slabs, wet, salty, etc.) and agricultural soils
-- including crafting recipes
function sediment.register_all_sed_and_agri_variants(sed_list)
    for _, sed in pairs(sed_list) do
        sediment.register_sed_variants(sed)
        sediment.register_agri_soil_variants(sed)
    end
end

---------------------------------------------
-- Nodes and recipes are defined here
---------------------------------------------

-- list of sediments to be used for mapgen
local sediment_list = {
   sand = sediment.new({name = "sand",
			description = S("Sand"), hardness = hardness.soft,
			fertility = 4, sound = sounds.sand,
			sound_wet = sounds.sand_wet}),
   silt = sediment.new({name = "silt",
			description = S("Silt"), hardness = hardness.soft,
			fertility = 3, sound = sounds.dirt,
			sound_wet = sounds.dirt_wet}),
   clay = sediment.new({name = "clay",
			description = S("Clay"), hardness = hardness.medium,
			fertility = 2, sound = sounds.dirt,
			sound_wet = sounds.dirt_wet}),
   gravel = sediment.new({name = "gravel",
			  description = S("Gravel"), hardness = hardness.soft,
			  fertility = 5, sound = sounds.gravel,
			  sound_wet = sounds.gravel_wet}),
   loam = sediment.new({name = "loam",
			description = S("Loam"), hardness = hardness.soft,
			fertility = 1, sound = sounds.dirt,
			sound_wet = sounds.dirt_wet}),
   volcanic_ash = sediment.new({name = "volcanic_ash",
				description = S("Volcanic ash"),
				hardness = hardness.soft,
				fertility = 1, sound = sounds.sand,
				sound_wet = sounds.sand_wet}),
}

local soil_list = {
    --Forest & Woodland
   soil.new({name = "woodland_soil",
	     description = S("Woodland Soil"),
	     sediment = sediment_list.silt}),

    --Wetlands
   soil.new({name = "marshland_soil",
	     description = S("Marshland Soil"),
	     sediment = sediment_list.silt}),

    --Shrubland & Grassland
    soil.new({name = "grassland_soil", description = S("Grassland Soil"),
	      sediment = sediment_list.clay}),

    --Barrenland & Duneland
    soil.new({name = "duneland_soil",
	      description = S("Duneland Soil"),
	      sediment = sediment_list.sand}),

    -- Highland
    soil.new({name = "highland_soil",
	      description = S("Highland Soil"),
	      sediment = sediment_list.gravel}),

    --Legacy
    soil.new({name = "grassland_barren_soil",
	      description = S("Barren Grassland Soil"),
	      sediment = sediment_list.gravel}),
    soil.new({name = "woodland_dry_soil",
	      description = S("Dry Woodland Soil"),
	      sediment = sediment_list.silt}),
}

-- Recipes for loam
crafting.register_recipe({
	type = "mixing_spot",
	output = "nodes_nature:loam 3",
	items = {"nodes_nature:clay 1","nodes_nature:silt 1","nodes_nature:sand 1"},
	level = 1,
	always_known = true,
})

crafting.register_recipe({
	type = "mixing_spot",
	output = "nodes_nature:loam_wet 3",
	items = {"nodes_nature:clay_wet 1","nodes_nature:silt_wet 1","nodes_nature:sand_wet 1"},
	level = 1,
	always_known = true,
})

-- Actually registers (almost) all soils in the game
-- see red_ochre above
sediment.register_all_sed_and_agri_variants(sediment_list)
sediment.register_soil_variants(soil_list)
