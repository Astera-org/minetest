--------------------------------------------------------------------------
--CRAFTS
--------------------------------------------------------------------------
--[[
Carcasses:
Invertebrate,
Fish,
Bird,
(Mammal, Lizard)


Sizes:
small, large

--
leather, Bone, skin, sinews, feathers?
]]

-- Internationalization
local S = animals.S

local random = math.random
local floor = math.floor
--------------------------------------------------------------------------
--Carcasses
-------------------------------------------
local box_small_invert = {
  {-0.125, -0.5, -0.1875, 0.125, -0.4375, 0.1875}, -- NodeBox1
  {-0.0625, -0.4375, -0.1875, 0.0625, -0.375, 0.1875}, -- NodeBox2
  {-0.0625, -0.5, -0.25, 0.0625, -0.4375, -0.1875}, -- NodeBox3
  {-0.0625, -0.5, 0.1875, 0.0625, -0.4375, 0.25}, -- NodeBox4
}

local box_large_invert ={
  {-0.1875, -0.5, -0.25, 0.1875, -0.375, 0.25}, -- NodeBox1
  {-0.125, -0.375, -0.25, 0.125, -0.3125, 0.25}, -- NodeBox2
  {-0.0625, -0.5, -0.375, 0.0625, -0.375, -0.25}, -- NodeBox3
  {-0.0625, -0.5, 0.25, 0.0625, -0.375, 0.375}, -- NodeBox4
}

local box_small_bird = {
  {-0.125, -0.5, -0.1875, 0.125, -0.375, 0.125}, -- NodeBox1
  {-0.0625, -0.375, -0.1875, 0.0625, -0.3125, 0.0625}, -- NodeBox2
  {-0.0625, -0.5, -0.3125, 0.0625, -0.375, -0.1875}, -- NodeBox3
  {-0.0625, -0.5, 0.125, 0.0625, -0.4375, 0.25}, -- NodeBox4
  {0.125, -0.5, -0.125, 0.3125, -0.4375, 0}, -- NodeBox5
  {-0.3125, -0.5, -0.125, -0.125, -0.4375, 0}, -- NodeBox6
  {0.125, -0.5, 0.0625, 0.1875, -0.4375, 0.25}, -- NodeBox7
  {-0.1875, -0.5, 0.0625, -0.125, -0.4375, 0.25}, -- NodeBox8
}

local box_small_fish = {
  {-0.125, -0.5, -0.1875, 0.125, -0.4375, 0.1875}, -- NodeBox1
  {-0.0625, -0.4375, -0.1875, 0.0625, -0.375, 0.1875}, -- NodeBox2
  {-0.0625, -0.5, -0.3125, 0.0625, -0.4375, -0.1875}, -- NodeBox3
  {-0.0625, -0.5, 0.1875, 0.0625, -0.4375, 0.375}, -- NodeBox4
  {0.125, -0.5, -0.125, 0.1875, -0.4375, 0.125}, -- NodeBox9
  {-0.1875, -0.5, -0.125, -0.125, -0.4375, 0.125}, -- NodeBox10
}

local box_large_fish = {
  {-0.25, -0.5, -0.3125, 0.25, -0.375, 0.3125}, -- NodeBox1
  {-0.125, -0.375, -0.3125, 0.125, -0.3125, 0.25}, -- NodeBox2
  {-0.125, -0.5, -0.4375, 0.125, -0.375, -0.3125}, -- NodeBox3
  {-0.125, -0.5, 0.3125, 0.125, -0.375, 0.4375}, -- NodeBox4
  {0.25, -0.5, 0, 0.375, -0.4375, 0.25}, -- NodeBox9
  {-0.375, -0.5, 0, -0.25, -0.4375, 0.25}, -- NodeBox10
  {-0.0625, -0.3125, -0.1875, 0.0625, -0.25, 0}, -- NodeBox11
}

local list = {
	{
    "invert_small",
    S("Small Invertebrate"),
    box_small_invert,
    minimal.stack_max_medium,
    1,
    10,
  
  },
  {
    "invert_large",
    S("Large Invertebrate"),
    box_large_invert,
    minimal.stack_max_medium/4,
    2,
    20,
  },
  {
    "vert_small",
    S("Small Vertebrate"),
    box_small_invert,
    minimal.stack_max_medium,
    3,
    30,
  },
  {
    "vert_large",
    S("Large Vertebrate"),
    box_large_invert,
    minimal.stack_max_medium/4,
    4,
    60,
  },
  {
    "bird_small",
    S("Small Bird"),
    box_small_bird,
    minimal.stack_max_medium/4,
    2,
    30,
  },
  {
    "fish_small",
    S("Small Fish"),
    box_small_fish,
    minimal.stack_max_medium/4,
    2,
    25,
  },
  {
    "fish_large",
    S("Large Fish"),
    box_large_fish,
    minimal.stack_max_bulky,
    3,
    35,
  },
}


for i in ipairs(list) do
	local name = list[i][1]
	local desc = list[i][2]
	local box = list[i][3]
	local stack = list[i][4]
	local carcass = list[i][5]
  local food_value = list[i][6]

  --raw
  minetest.register_node("animals:carcass_"..name, {
	  description = S('@1 Carcass', desc),
    tiles = {"animals_carcass.png"},
    drawtype = "nodebox",
  	paramtype = "light",
  	node_box = {
  		type = "fixed",
  		fixed = box
  	},
    food_value = food_value,
  	stack_max = stack/2,
  	groups = {snappy = 3, dig_immediate = 3, falling_node = 1, temp_pass = 1, carcass = carcass},
  	on_use = function(itemstack, user, pointed_thing)
      addNutrient(user,"hunger",food_value) 
      itemstack:take_item()
      return itemstack
    end,
  })

  --cooked
  minetest.register_node("animals:carcass_"..name.. "_cooked", {
    description = S('Cooked @1', desc),
    tiles = {"nodes_nature_silt.png"},
    drawtype = "nodebox",
    paramtype = "light",
    node_box = {
      type = "fixed",
      fixed = box
    },
    stack_max = stack,
    groups = {snappy = 3, dig_immediate = 3, falling_node = 1, temp_pass = 1},
    sounds = nodes_nature.node_sound_defaults(),
  })

--burned
  minetest.register_node("animals:carcass_"..name.. "_burned", {
    description = S('Burned @1', desc),
    tiles = {"animals_carcass_burned.png"},
    drawtype = "nodebox",
    paramtype = "light",
    node_box = {
      type = "fixed",
      fixed = box
    },
    stack_max = stack,
    groups = {snappy = 3, dig_immediate = 3, falling_node = 1, temp_pass = 1},
    sounds = nodes_nature.node_sound_defaults(),
  })

  exile_add_food_hooks("animals:carcass_"..name)
  exile_add_food_hooks("animals:carcass_"..name.. "_cooked")
  exile_add_food_hooks("animals:carcass_"..name.. "_burned")
end

function carcassTimer(pos)
  --minimal.log("carcass timer")
  -- TODO: check if there is a carcass item at the given position
  

  -- Check if the chance of spawning a skip fungus is met
  if math.random() <= 0.04 then
    -- Spawn skip fungus at the given position
    animals.hatch_egg(pos, 'air', 'air', "animals:skip_fungus", 4000, 1)
    return false
  end

  --[[ TODO: 
  -- Check if the chance of removing the carcass is met
  if math.random() <= 0.07 then
    -- Remove the carcass at the given position
    minetest.remove_node(pos)
  end
  ]]--
  return true
end


local nextCarcassTime=os.time()
local carcassList={}

minetest.register_globalstep(function(dtime)
  if nextCarcassTime < os.time() then
    nextCarcassTime = os.time() + 30
    -- iterate through carcassList and call carcass_timer on each
    for i = #carcassList, 1, -1 do
      if not carcassTimer(carcassList[i]) then
          table.remove(carcassList, i)
      end
    end
  end
end)

function addCarcass(pos)
  table.insert(carcassList,pos)
end