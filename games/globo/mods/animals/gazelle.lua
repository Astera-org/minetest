----------------------------------------------------------------------
-- Gazelle
--[[
males and females, must mate to reproduce.
lives off flora
]]
---------------------------------------------------------------------

-- Internationalization
local S = animals.S

local random = math.random
local floor = math.floor

local gazelle=animalData[animal.gazelle]
local gazelleMale=animalData[animal.gazelleMale]


local function gazelleEat(self,pos)
    --minimal.log("cow eat called")
    if random()< 0.25 then
        if not animals.eat_spreading_under(self,pos, 0.002) then
            mobkit.animate(self,'walk')
            mobkit.remember(self,"action","surface roam")
            animals.hq_roam_surface_group(self, 'spreading', 20)
        end
    else
        mobkit.remember(self,"action","eat_flora")
        animals.eat_flora(self,pos, 20, 0.5)
    end
end

local function gazelleExplore(self,pos)
    if random() < 0.95 then
        --wander random
        mobkit.animate(self,'walk')
        animals.hq_roam_far(self,10)
    else
        --wander temp
        mobkit.animate(self,'walk')
        animals.hq_roam_comfort_temp(self,10, 21)
    end
end

-----------------------------------
local function brain(self)

	--die from damage
	if not animals.core_hp(self) then
		return
	end

	if mobkit.timer(self,1) then

		local pos = mobkit.get_stand_pos(self)

		local age, energy = animals.core_life(self, gazelle.lifespan, pos)
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


		local prty = mobkit.get_queue_priority(self)
		-------------------
		--High priority actions
		if prty < 50 then
			--Threats
			local plyr = mobkit.get_nearby_player(self)
			if plyr then
				animals.fight_or_flight_plyr(self, plyr, 55, 0.01)
			end

			animals.predator_avoid(self, 55, 0.01)
		end


		----------------------
		--Low priority actions
		if prty < 20 then
            if energy < (self.energy_max*.5) then
                mobkit.remember(self,"action","eat")
                gazelleEat(self,pos)
            else 
                --random choice between
                --feeding, exploring, social
                --chance differs by time
                local ce = 0.1
                local cs = 0.1
                -- c feeding is simply what happens if no
                --others are selected
                local tod = minetest.get_timeofday()
                if tod <0.2 or tod >0.8 then
                    --more social at night
                    ce = 0.01
                    cs = 0.75
                elseif tod >0.55 and tod <0.55 then
                    --explore during midday
                    ce = 0.5
                    cs = 0.1
                end


                if random() < ce then
                    gazelleExplore(self,pos)

                elseif random() < cs then

                    --social
                    if random()< 0.3 then
                        animals.flock(self, 25, 3)
                    elseif random()< 0.01 then
                        animals.territorial(self, energy, false)
                    elseif random() < 0.05 then

                        --reproduction
                        if self.hp >= self.max_hp
                        and energy >= self.energy_max - 100 then

                            --are we already pregnant?
                            local preg = mobkit.recall(self,'pregnant') or false
                            if preg == true then
                                mobkit.lq_idle(self,3)
                                local birth=false
                                if random() < 0.5 then 
                                    birth = animals.birth(pos, "animals:gazelle", "air",  gazelle.eggEnergy, 1)
                                else 
                                    birth = animals.birth(pos, "animals:gazelle_male", "air" , gazelle.eggEnergy, 1)
                                end
                                if birth then
                                    minimal.log("gazelle giving birth")
                                    mobkit.remember(self,'pregnant',false)
                                    energy=energy-gazelle.eggEnergy
                                end

                            else

                                --we are randy
                                mobkit.remember(self,'sexual',true)
                                local mate = animals.mate_assess(self, 'animals:gazelle_male')
                                if mate then
                                    --go get him!
                                    --mobkit.make_sound(self,'mating')
                                    if random() < 0.5 then
                                        animals.hq_mate(self, 25, mate)
                                    end
                                end
                            end
                        else
                            --I'm too tired darling
                            mobkit.remember(self,'sexual',false)
                        end
                    end

                elseif energy < self.energy_max then
                    gazelleEat(self,pos)
                end
            end

		end

		-------------------
		--generic behaviour
		if mobkit.is_queue_empty_high(self) then
			mobkit.animate(self,'walk')
			animals.hq_roam_far(self,10)
		end
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

		local age, energy = animals.core_life(self, gazelleMale.lifespan, pos)
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


		local prty = mobkit.get_queue_priority(self)
		-------------------
		--High priority actions
		if prty < 50 then


			--Threats
			local plyr = mobkit.get_nearby_player(self)
			if plyr then
				animals.fight_or_flight_plyr(self, plyr, 55, 0.6)
			end

			animals.predator_avoid(self, 55, 0.6)

		end


		----------------------
		--Low priority actions

		if prty < 20 then
            if energy < (self.energy_max*.5) then
                mobkit.remember(self,"action","eat")
                gazelleEat(self,pos)
            else 
                --random choice between
                --feeding, exploring, social
                --chance differs by time
                local ce = 0.2
                local cs = 0.4
                -- c feeding is simply what happens if no
                --others are selected
                local tod = minetest.get_timeofday()
                if tod <0.2 or tod >0.8 then
                    --more social at night
                    ce = 0.01
                    cs = 0.95
                elseif tod >0.55 and tod <0.55 then
                    --explore during midday
                    ce = 0.6
                    cs = 0.2
                end


                if random() < ce then
                    gazelleExplore(self,pos)
                elseif random() < cs then

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
                            local mate = animals.mate_assess(self, 'animals:gazelle')

                            if mate then
                                --go get her!
                                --mobkit.make_sound(self,'mating')
                                if random() < 0.5 then
                                    mobkit.remember(self, "energy", energy - 200) -- energy use for mating lol
                                    animals.hq_mate(self, 25, mate)
                                end
                            end

                        else
                            --in no state for hankypanky
                            mobkit.remember(self, 'sexual', false)
                        end
                    end

                elseif energy < self.energy_max then
                    gazelleEat(self,pos)
                end
			end

		end

		-------------------
		--generic behaviour
		if mobkit.is_queue_empty_high(self) then
			mobkit.animate(self,'walk')
			animals.hq_roam_far(self,10)
		end
	end
end




---------------
-- the CREATURE
---------------

--eggs
minetest.register_node("animals:gazelle_spawn_herd", {
	description = S('Gazelle Spawn'),
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
		animals.spawnHerd(pos,  "animals:gazelle", gazelle.eggEnergy, 0.002,20)
		animals.spawnHerd(pos, "animals:gazelle_male", gazelle.eggEnergy, 0.002,20)
	end,
})

local baseGazelle = {
	physical = true,
	collide_with_objects = true,
	collisionbox = {-0.35, -0.19, -0.35, 0.35, 0.65, 0.35},
	visual = "mesh",
	mesh = "herbivore.b3d",
	textures = {"herbivore.png"},
	visual_size = {x = 1.3, y = 1.3},
	makes_footstep_sound = true,
	timeout = 0,

	--damage
	max_hp = 1000,
	heal_rate= 1,
	lung_capacity = 20,
	min_temp = -20,
	max_temp = 45,
    energy_loss = 1,
	energy_max= 8000,

	--interaction
	predators = {"animals:wolf", "animals:wolf_male","animals:puma"},
	friends = {"animals:gazelle", "animals:gazelle_male"},
	rivals = {""},

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
	max_speed = 3.5,					-- m/s
	jump_height = 2.5,				-- nodes/meters
	view_range = 7,					-- nodes/meters

	--attack
	attack={range=0.8, damage_groups={fleshy=60}},
	armor_groups = {fleshy=100},

	--on actions
	drops = {
		{name = "animals:carcass_vert_large", chance = 1, min = 1, max = 2,},
	},
    on_construct = function(pos)
        minimal.log("gazelle spawned")
    end,
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		--minimal.log("cow punched. hp:"..self.hp)
		animals.on_punch(self, tool_capabilities, puncher, 55, 0.05)
		return true
	end,
	on_rightclick = function(self, clicker)
	end,
}


local maleGazelle=shallowCopy(baseGazelle)
maleGazelle.logic=brain_male
maleGazelle.sex="male"
maleGazelle.rivals = {""}
maleGazelle.max_hp=gazelleMale.hp


minetest.register_entity("animals:gazelle_male",maleGazelle)
minetest.register_entity("animals:gazelle",baseGazelle)
