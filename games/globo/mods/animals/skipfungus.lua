----------------------------------------------------------------------
-- Skip Fungus
--[[
An egg is placed near any creature that dies near the skip fungus

Blows up on death. Damaging things nearby and destroying blocks

Moves by jumping

-- Any carcass has x% chance of spawning a skip fungus egg per unit time

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
    local pos = mobkit.get_stand_pos(self)
	--die from damage
	if not animals.core_hp(self) then
        explode(pos)
		return
	end

	if mobkit.timer(self,1) then
		local age, energy = animals.core_life(self, lifespan, pos)
		--die from exhaustion or age
		if not age then
			return
		end

        if isNearOther(pos, 2) then
            self.object:remove()
            explode(pos)
            minimal.log("EXPLODE!")
            return
        end

		------------------
		--Emergency actions

		--swim to shore
		if self.isinliquid then
			mobkit.hq_liquid_recovery(self,60)
		end

        local chanceExplore = 0.1
        local tod = minetest.get_timeofday()
        if tod <0.2 or tod >0.8 then
            mobkit.lq_idle(self,5)
            return
        end

        --minimal.log(""..dump(self))
        local prey=mobkit.get_closest_other_entity(self)
        local tpos
        if prey == nil then
            -- chance to turn 
            -- jump in direction facing
            local yaw = self.object:get_yaw()
            local r=math.random()
            if r < 0.25 then
                if math.random() < 0.5 then
                    --minimal.log("turn left ")
                    yaw = yaw + .78 
                else
                    --minimal.log("turn right ")
                    yaw = yaw - .78
                end
                self.object:set_yaw(yaw)
            end
            -- get dir from yaw
            local dir=minetest.yaw_to_dir(yaw)
            tpos = pos
            tpos.x = tpos.x + dir.x*10
            tpos.z = tpos.z + dir.z*10

        else
            -- jump toward prey
            tpos=prey:get_pos()
        end

        hq_jumptowards(self, tpos)


		-----------------
		--housekeeping
		--save energy, age
		mobkit.remember(self,'energy',energy)
		mobkit.remember(self,'age',age)

	end
end

function explode(pos)
    local radius = 4
    local damage = 100

    -- Hurt all nearby mobs and players
    local objects = minetest.get_objects_inside_radius(pos, radius)
    for _, obj in ipairs(objects) do
        if obj:is_player() then
            obj:set_hp(obj:get_hp() - damage)
        elseif mobkit.is_alive(obj) then
            local mob=obj:get_luaentity()
            if mob== nil then
                minimal.log("non mob bite")
                obj:punch(obj, 1.0, {full_punch_interval=1.0, damage_groups={fleshy=damage}}, nil)
            else
                mob.on_punch(mob,obj,1,{full_punch_interval=1.0, damage_groups={fleshy=damage}})
            end
        end
    end

    -- Destroy all nearby blocks
    for x = -radius, radius do
        for y = -radius, radius do
            for z = -radius, radius do
                local posI = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
                local dist = vector.distance(pos, posI)
                
                if dist <= radius then
                    local node = minetest.get_node(posI)
                    local node_name = node.name

                    if node_name ~= "air" and node_name ~= "ignore" then
                        minetest.remove_node(posI)
                        minetest.add_item(posI, node_name)
                    end
                end
            end
        end
    end
end

function isNearOther(pos,range)
    local nearby_objects = minetest.get_objects_inside_radius(pos, range)
    for _,obj in ipairs(nearby_objects) do
        if obj:is_player() then return true end
        local luaent = obj:get_luaentity()
        if luaent ~= nil and luaent.name ~= "animals:skip_fungus" and mobkit.is_alive(obj) then
            return true
        end
    end

    return false
end

function hq_jumptowards(self, tpos)
    local pos = mobkit.get_stand_pos(self)
    -- get yaw to target
    local yaw = minetest.dir_to_yaw(vector.direction(pos, tpos))
    self.object:set_yaw(yaw)

    --minimal.log("jumping: "..pos.y+self.jump_height)
    mobkit.lq_dumbjump(self,self.jump_height)
end



---------------
-- the CREATURE
---------------

--eggs
minetest.register_node("animals:skip_spawn", {
	description = S('Skip Fungus Spawn'),
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
        print("skip hatched")
		return animals.hatch_egg(pos, 'air', 'air', "animals:skip_fungus", energy_egg, young_per_egg)
	end,
})

local baseSkip={
	physical = true,
	collide_with_objects = true,
	collisionbox = {-0.3, -0.01, -0.3, 0.3, 0.84, 0.3},
	visual = "mesh",
	mesh = "mobs_crocodile.b3d",
	textures = {"mobs_crocodile_1.png"},
	visual_size = {x = 2, y = 2},
	makes_footstep_sound = true,
	timeout = 0,

	--damage
	max_hp = 40,
	heal_rate= 0.25,
	lung_capacity = 20,
	min_temp = -20,
	max_temp = 45,
    energy_loss = 1,
    energy_max = 4000,

	--interaction
	predators = {},
    prey={},
	friends = {},
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
	jump_height = 3,				-- nodes/meters
	view_range = 8,					-- nodes/meters

	--attack
	attack={range=0.3, damage_groups={fleshy=5}},
	armor_groups = {fleshy=100},

	--on actions
	drops = {
	},
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		animals.on_punch(self, tool_capabilities, puncher, 55, 0.05)
	end,
	on_rightclick = function(self, clicker)
	end,
}


minetest.register_entity("animals:skip_fungus",baseSkip)
