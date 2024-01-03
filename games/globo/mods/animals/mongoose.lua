----------------------------------------------------------------------
-- Mongoose
--[[
lives off animals and eggs
]]
---------------------------------------------------------------------

-- Internationalization
local S = animals.S

local random = math.random
local floor = math.floor

--energy
local energy_egg = 3000 --energy that goes to egg
local egg_timer  = 60*60
local young_per_egg = 1		--will get this/energy_egg starting energy
local lifespan = 4000 * 10


-----------------------------------
local function brain(self)

	-- mobkit.remember(self,"action","")

	--die from damage
	if not animals.core_hp(self) then
		return
	end

	if mobkit.timer(self,1) then

		local pos = mobkit.get_stand_pos(self)

		local age, energy = animals.core_life(self, lifespan, pos)
		--die from exhaustion or age
		if not age then
			return
		end
        mobkit.remember(self,'energy',energy)
		mobkit.remember(self,'age',age)

		------------------
		--Emergency actions

		--swim to shore
		if self.isinliquid then
			mobkit.hq_liquid_recovery(self,60)
		end


		local priority = mobkit.get_queue_priority(self)
		-------------------
		--High priority actions
		if priority < 50 then
			--Threats
			local player = mobkit.get_nearby_player(self)
			if player then
				animals.fight_or_flight_plyr(self, player, 55, 0.1)
				mobkit.remember(self,"action","fight player")
			end

			animals.predator_avoid(self, 55, 0.01)
		end


		----------------------
		--Low priority actions
		if priority < 20 then
			if energy < (self.energy_max-self.energy_max*.2) then
				if not animals.eat_eggs(self,25) then
                    if not animals.eat_carcass(self,25,1,100) then
					    if not animals.prey_hunt(self, 25) then
                            --random search
                            mobkit.animate(self,'walk')
                            animals.hq_roam_far(self,10)
                            mobkit.remember(self,"action","hungry wander")
                        end
					end
				end
			end
            -- TODO: have babies, sleep
		end

		-------------------
		--generic behaviour
		if mobkit.is_queue_empty_high(self) then
			mobkit.animate(self,'walk')
			animals.hq_roam_far(self,10)
			mobkit.remember(self,"action","default wander")
		end
	end
end

---------------
-- the CREATURE
---------------

--eggs
minetest.register_node("animals:mongoose_spawn", {
	description = S('Mongoose Spawn'),
	tiles = {"animals_gundu_eggs.png"},
	stack_max = minimal.stack_max_medium,
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {-0.125, -0.5, -0.125,  0.125, -0.125, 0.125},
	},
	groups = {snappy = 3, falling_node = 1, dig_immediate = 3, flammable = 1,  temp_pass = 1, edible = 1},
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(1)
	end,
	on_timer =function(pos, elapsed)
        print("mongoose hatched")
		return animals.hatch_egg(pos, 'air', 'air', "animals:mongoose", energy_egg, young_per_egg)
	end,
})

local baseMongoose={
	physical = true,
	collide_with_objects = true,
    --collisionbox = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
    --collisionbox = { -0.5, -0.5, -0.5, 2, 2, 2 },
    collisionbox = {-0.3, -0.01, -0.3, 0.3, 0.84, 0.3},
    --collisionbox = {-0.2, -1, -0.2, 0.2, -0.8, 0.2},
	visual = "mesh",
	--mesh = "mobs_rat.b3d",
	--textures = {"mobs_rat.png"},
    mesh = "mobs_wolf.b3d",
	textures = {"mobs_wolf.png"},
	visual_size = {x = 1, y = 1},
	makes_footstep_sound = true,
	timeout = 0,

	--damage
	max_hp = 20,
	heal_rate= 0.25,
	lung_capacity = 20,
	min_temp = -20,
	max_temp = 45,
    energy_loss = 0.5,
	energy_max = 4000,

	--interaction
	predators = {"animals:wolf","animals:wolf_male"},
    prey={"animals:sneachen","animals:pegasun"},
	friends = {"animals:mongoose"},
	rivals = {},

	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	logic = brain,
	
	animation = {
		walk={range={x=71, y=90}, speed=24, loop=true},
		fast={range={x=91, y=110}, speed=24, loop=true},
		stand={
			{range={x=1, y=30}, speed=28, loop=true},
			{range={x=31, y=70}, speed=32, loop=true},
		},
	},

	--movement
	springiness=0,
	buoyancy = 1.01,
	max_speed = 2,					-- m/s
	jump_height = 2,				-- nodes/meters
	view_range = 15,					-- nodes/meters

	--attack
	attack={range=0.8, damage_groups={fleshy=2}},
	armor_groups = {fleshy=100},

	--on actions
	drops = {
		{name = "animals:carcass_vert_small", chance = 1, min = 1, max = 1,},
	},
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		--minimal.log("mongoose punched. hp:"..self.hp)
		animals.on_punch(self, tool_capabilities, puncher, 55, 0.05)
	end,
	on_rightclick = function(self, clicker)
	end,
}

minetest.register_entity("animals:mongoose",baseMongoose)
