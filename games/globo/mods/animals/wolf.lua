----------------------------------------------------------------------
-- Wolf
--[[
males and females, must mate to reproduce.
lives off animals
]]
---------------------------------------------------------------------

-- Internationalization
local S = animals.S

local random = math.random
local floor = math.floor

--energy
local energy_max = 8000 --secs it can survive without food
local energy_egg = energy_max/2 --energy that goes to egg
local egg_timer  = 60*60
local young_per_egg = 1		--will get this/energy_egg starting energy

local lifespan = energy_max * 10
local lifespan_male = lifespan * 1.2 





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
			animals.predator_avoid(self, 55, 0.01)
		end


		----------------------
		--Low priority actions
		if priority < 20 then
			--random choice between
			--feeding, exploring, social
			--chance differs by time
			local chanceExplore = 0.1
			local tod = minetest.get_timeofday()
			if tod <0.2 or tod >0.8 then
				--more social at night
				chanceExplore = 0.7
			elseif tod >0.55 and tod <0.55 then
				--explore during midday
				chanceExplore = 0.2
			end

			if energy < (self.energy_max-self.energy_max*.2) then
				if not animals.eat_carcass(self,25,2,100) then
					if not animals.prey_hunt(self, 25) then
						--random search
						mobkit.animate(self,'walk')
						animals.hq_roam_far(self,10)
						mobkit.remember(self,"action","hungry wander")
					end
				end
			elseif random() < chanceExplore then
				if random() < 0.9 then
					--wander random
					mobkit.animate(self,'walk')
					mobkit.hq_roam(self,10)
					mobkit.remember(self,"action","explore wander")
				else
					--wander temp
					mobkit.animate(self,'walk')
					animals.hq_roam_comfort_temp(self,12, 21)
					mobkit.remember(self,"action","temp wander")
				end
			else
				--social
				if random()< 0.3 then
					animals.flock(self, 25, 3)
					mobkit.remember(self,"action","flock")
				elseif random()< 0.01 then
					animals.territorial(self, energy, false)
					mobkit.remember(self,"action","territorial")
				elseif random() < 0.05 then
					--reproduction
					if self.hp >= self.max_hp
					and energy >= self.energy_max - (self.energy_max*.3) then

						--are we already pregnant?
						local preg = mobkit.recall(self,'pregnant') or false
						if preg == true then
							mobkit.lq_idle(self,3)
							if random() < 0.05 then
								energy = animals.place_egg(pos, "animals:wolf_spawn", energy, energy_egg, 'air')
								mobkit.remember(self,'pregnant',false)
							end

						else

							--we are randy
							mobkit.remember(self,'sexual',true)
							local mate = animals.mate_assess(self, 'animals:wolf_male')
							if mate then
								--go get him!
								--mobkit.make_sound(self,'mating')
								if random() < 0.5 then
									mobkit.remember(self,"action","mating")
									animals.hq_mate(self, 25, mate)
								end
							end
						end
					else
						--I'm too tired darling
						mobkit.remember(self,'sexual',false)
					end
				end
			end
		end

		-------------------
		--generic behaviour
		if mobkit.is_queue_empty_high(self) then
			mobkit.animate(self,'walk')
			animals.hq_roam_far(self,10)
			mobkit.remember(self,"action","default wander")
		end

		-----------------
		--housekeeping
		--save energy, age
		

	end
end





-----------------------------------
--MALE BEHAVIOUR
local function brain_male(self)

	--die from damage
	if not animals.core_hp(self) then
		return
	end

	if mobkit.timer(self,1) then

		local pos = mobkit.get_stand_pos(self)

		local age, energy = animals.core_life(self, lifespan_male, pos)
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
			animals.predator_avoid(self, 55, 0.6)
		end


		----------------------
		--Low priority actions

		if priority < 20 then
			--random choice between
			--feeding, exploring, social
			--chance differs by time
			local chanceExplore = 0.1
			local tod = minetest.get_timeofday()
			if tod <0.2 or tod >0.8 then
				--more social at night
				chanceExplore = 0.7
			elseif tod >0.55 and tod <0.55 then
				--explore during midday
				chanceExplore = 0.2
			end

			if energy < (self.energy_max-self.energy_max*.2) then
				if not animals.eat_carcass(self,25,2,100) then
					if not animals.prey_hunt(self, 25) then
						mobkit.animate(self,'walk')
						animals.hq_roam_far(self,10)
						mobkit.remember(self,"action","hungry wander")
					end
				end
			elseif random() < chanceExplore then
				if random() < 0.9 then
					--wander random
					mobkit.animate(self,'walk')
					mobkit.hq_roam(self,10)
				else
					--wander temp
					mobkit.animate(self,'walk')
					animals.hq_roam_comfort_temp(self,12, 21)
				end
			else
				--social
				if random()< 0.5 then
					animals.flock(self, 25, 1)
				elseif random()< 0.85 then
					animals.territorial(self, energy, false)
				elseif random() < 0.1 then

					--reproduction
					if self.hp >= self.max_hp
					and energy >= self.energy_max/2 then

						--set status as randy
						--find nearby prospect and try to mate
						mobkit.remember(self, 'sexual', true)
						local mate = animals.mate_assess(self, 'animals:wolf')

						if mate then
							--go get her!
							--mobkit.make_sound(self,'mating')
							if random() < 0.5 then
                				mobkit.remember(self, "energy", energy - 1000) -- energy use for mating lol
								animals.hq_mate(self, 25, mate)
							end
						end

					else
						--in no state for hankypanky
						mobkit.remember(self, 'sexual', false)
					end
				end
			end
		end

		-------------------
		--generic behaviour
		if mobkit.is_queue_empty_high(self) then
			mobkit.animate(self,'walk')
			animals.hq_roam_far(self,10)
		end

		-----------------
		--housekeeping
		--save energy, age
		

	end
end




---------------
-- the CREATURE
---------------

--eggs
minetest.register_node("animals:wolf_spawn", {
	description = S('Wolf Spawn'),
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
        print("wolf hatched")
		if random()<=0.5 then -- 50% for female, 50% for male
			return animals.hatch_egg(pos, 'air', 'air', "animals:wolf", energy_egg, young_per_egg)
		else
			return animals.hatch_egg(pos, 'air', 'air', "animals:wolf_male", energy_egg, young_per_egg)
		end
	end,
})

local baseWolf={
	physical = true,
	collide_with_objects = true,
	collisionbox = {-0.3, -0.01, -0.3, 0.3, 0.84, 0.3},
	visual = "mesh",
	mesh = "mobs_wolf.b3d",
	textures = {"mobs_wolf.png"},
	visual_size = {x = 3, y = 3},
	makes_footstep_sound = true,
	timeout = 0,

	--damage
	max_hp = 800,
	heal_rate= 2,
	lung_capacity = 20,
	min_temp = -20,
	max_temp = 45,
    energy_loss = 1,
	energy_max = 8000,

	--interaction
	predators = {},
    prey={"animals:cow","animals:cow_male","animals:gazelle","animals:gazelle_male","player"},
	friends = {"animals:wolf", "animals:wolf_male"},
	rivals = {},

	on_step = mobkit.stepfunc,
	on_activate = mobkit.actfunc,
	get_staticdata = mobkit.statfunc,
	logic = brain,
	-- optional mobkit props
	-- or used by built in behaviors
	--physics = [function user defined] 		-- optional, overrides built in physics
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
	max_speed = 3,					-- m/s
	jump_height = 2,				-- nodes/meters
	view_range = 15,					-- nodes/meters

	--attack
	attack={range=0.8, damage_groups={fleshy=300}},
	armor_groups = {fleshy=100},

	--on actions
	drops = {
		{name = "animals:carcass_vert_large", chance = 1, min = 1, max = 1,},
	},
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		--minimal.log("wolf punched. hp:"..self.hp)
		animals.on_punch(self, tool_capabilities, puncher, 55, 0.05)
		return true
	end,
	on_rightclick = function(self, clicker)
		--minimal.log("wolf rightclicked. hp:"..self.hp)
	end,
}


minetest.register_entity("animals:wolf",baseWolf)
local maleWolf=baseWolf
maleWolf.logic=brain_male
maleWolf.sex="male"

minetest.register_entity("animals:wolf_male",maleWolf)

