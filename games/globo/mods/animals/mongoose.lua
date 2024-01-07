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

local mongoose=animalData[animal.mongoose]


-----------------------------------
local function brain(self)

	-- mobkit.remember(self,"action","")

	--die from damage
	if not animals.core_hp(self) then
		return
	end

	if mobkit.timer(self,1) then

		local pos = mobkit.get_stand_pos(self)

		local age, energy = animals.core_life(self, mongoose.lifespan, pos)
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
				mobkit.remember(self,"action","fight/flight player")
			end

			animals.predator_avoid(self, 55, 0.01)
		end


		----------------------
		--Low priority actions
		if priority < 20 then
			-- if pregnant then have a chance to give birth
			if mobkit.recall(self,'pregnant') then
				if random() < .02 then
					minimal.log("mongoose giving birth")
					if animals.birth(pos, "animals:mongoose", "air",  mongoose.eggEnergy, 1) then
						mobkit.remember(self,'pregnant',false)
						mobkit.remember(self,'energy',energy-mongoose.eggEnergy)
					end
				end
			elseif energy < (self.energy_max-self.energy_max*.2) then
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
			elseif math.random()< .3 then
				mobkit.remember(self,'pregnant',true)
			end
            -- TODO: sleep
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
		animals.birth(pos, "animals:mongoose", "air",  mongoose.eggEnergy, 1)
		return false
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
	mesh = "animalia_rat.b3d",
	textures = {
		"animalia_rat_1.png",
		"animalia_rat_2.png",
		"animalia_rat_3.png"
	},
    --mesh = "mobs_wolf.b3d",
	--textures = {"mobs_wolf.png"},
	visual_size = {x = 10, y = 10},
	makes_footstep_sound = true,
	timeout = 0,

	--damage
	max_hp = mongoose.hp,
	heal_rate= mongoose.heal,
	lung_capacity = 20,
	min_temp = mongoose.minTemp,
	max_temp = mongoose.maxTemp,
    energy_loss = mongoose.energyLoss,
	energy_max = mongoose.energy,

	--interaction
	predators = {"animals:puma","animals:wolf_male"},
    prey={"animals:sneachen","animals:pegasun"}, -- eggs
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
	max_speed = mongoose.speed,					-- m/s
	jump_height = mongoose.jump,				-- nodes/meters
	view_range = mongoose.view,					-- nodes/meters

	--attack
	attack={range=mongoose.range, damage_groups={fleshy=mongoose.damage}},
	armor_groups = {fleshy=mongoose.armor},

	--on actions
	drops = {
		{name = "animals:carcass_vert_small", chance = 1, min = 1, max = 1,},
	},
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		--minimal.log("mongoose punched. hp:"..self.hp)
		animals.on_punch(self, tool_capabilities, puncher, 55, 0.05)
		return true
	end,
	on_rightclick = function(self, clicker)
	end,
}

minetest.register_entity("animals:mongoose",baseMongoose)
