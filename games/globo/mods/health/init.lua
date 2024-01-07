-------------------------------------
--HEALTH

--[[
Two global step functions
Fast, and slow.

Fast applies environmental and action based effects (in on_actions)
Slow applies internal metabolism effects (here)
]]

------------------------------------

HEALTH = {}

-- Internationalization
HEALTH.S = minetest.get_translator("health")
HEALTH.FS = function(...)
    return minetest.formspec_escape(HEALTH.S(...))
end

dofile(minetest.get_modpath('health')..'/health_effects.lua')
dofile(minetest.get_modpath('health')..'/on_actions.lua')
dofile(minetest.get_modpath('health')..'/hud.lua')
dofile(minetest.get_modpath('health')..'/food.lua')

-----------------------------
--Player Attibutes
--
--use standard values base, so it doesn't compound each time called
--Only adjusted values saved in player meta so they can be accessed without recalculating
--cf hunger etc which do get change and have no base value
local heal_rate = 2 -- 4
local thirst_rate = -10
local hunger_rate = -3 -- -2
local recovery_rate = 6 -- 5
local move = 0
local jump = 0

--no clothing temperature comfort zone
local temp_min = 18--20
local temp_max = 32--30

--e.g. for new players
local function set_default_attibutes(player)
	local meta = player:get_meta()
	meta:set_int("thirst", 1000)
	meta:set_int("hunger", 1000)
	meta:set_int("energy", 1000)
	meta:set_int("temperature", 37)
	meta:set_int("heal_rate", heal_rate)
	meta:set_int("thirst_rate", thirst_rate)
	meta:set_int("hunger_rate", hunger_rate)
	meta:set_int("recovery_rate", recovery_rate)
	meta:set_int("move", move)
	meta:set_int("jump", jump)
	meta:set_int("clothing_temp_min", temp_min)
	meta:set_int("clothing_temp_max", temp_max )

end


-- return names of the effects on the effects list as a string
function effectListStr(player)
	local meta = player:get_meta()
	local effects_list = meta:get_string("effects_list")
	-- get a list of just the names
	local effects_names = {}
	for _, effect in ipairs(minetest.deserialize(effects_list) or {}) do
		table.insert(effects_names, effect[1])
	end
	return table.concat(effects_names, ", ")
end

-----------------------------
--Applies Health Effects
--called by malus_bonus
--runs through player's current effects, runs the function for that effect
--takes all the same variables, and outputs as any effect may use them.
--adjusted outputs feed back into malus_bonus
local function do_effects_list(meta, player, health, energy, thirst, hunger, temperature, h_rate, r_rate, t_rate, hun_rate,  mov, jum)
	local effects_list = meta:get_string("effects_list")
	effects_list = minetest.deserialize(effects_list) or {}

	if not effects_list then
		return h_rate, r_rate, t_rate, hun_rate, mov, jum, health, energy, thirst, hunger, temperature
	end

	for key, effect in ipairs(effects_list) do
        minimal.log("HE: "..effect[1])

		local name = effect[1]
		local order = effect[2]
		local valid = false

		----------
		if name == "Food Poisoning" then
		   r_rate, mov, jum, temperature
		      = HEALTH.food_poisoning(order, player, meta, effects_list,
					      r_rate, mov, jum, temperature)
		   valid = true
		end

		----------
		if name == "Fungal Infection" then
		   r_rate, mov, jum, temperature
		      = HEALTH.fungal_infection(order, player, meta,
						effects_list, r_rate, mov, jum,
						temperature)
		   valid = true
		end

		----------
		if name == "Dust Fever" then
		   r_rate, mov, jum, temperature
		      = HEALTH.dust_fever(order, player, meta, effects_list,
					  r_rate, mov, jum, temperature)
		   valid = true
		end

		----------
		if name == "Drunk" then
		   r_rate, mov, jum, h_rate, temperature
		      = HEALTH.drunk(order, player, meta, effects_list,
				     r_rate, mov, jum, h_rate, temperature)
		   valid = true
		end

		----------
		if name == "Hangover" then
		   mov, jum = HEALTH.hangover(order, player, meta,
					      effects_list, mov, jum)
		   valid = true
		end

		----------
		if name == "Intestinal Parasites" then
		   r_rate, hun_rate
		      = HEALTH.intestinal_parasites(order, player, meta,
						    effects_list, r_rate,
						    hun_rate)
		   valid = true
		end

		----------
		if name == "Tiku High" then
		   r_rate, hun_rate, mov, jum, temperature
		      = HEALTH.tiku_high(order, player, meta, effects_list,
					 r_rate, hun_rate, mov, jum, temperature)
		   valid = true
		end

		----------
		if name == "Neurotoxicity" then
		   mov, jum = HEALTH.neurotoxicity(order, player, meta,
						   effects_list, mov, jum)
		   valid = true
		end

		----------
		if name == "Hepatotoxicity" then
		   mov, jum, r_rate, h_rate
		      = HEALTH.hepatotoxicity(order, player, meta, effects_list,
					      mov, jum, r_rate, h_rate)
		   valid = true
		end

		----------
		if name == "Photosensitivity" then
		   h_rate, r_rate
		      = HEALTH.photosensitivity(order, player, meta,
						effects_list, h_rate, r_rate)
		   valid = true
		end

		---------
		if name == "Meta-Stim" then
		   h_rate, r_rate, hun_rate, t_rate
		      = HEALTH.meta_stim(order, player, meta, effects_list,
					 h_rate, r_rate, hun_rate, t_rate)
		   valid = true
		end

		if valid == false then
		   table.remove(effects_list, key)
		   meta:set_string("effects_list",
				   minetest.serialize(effects_list))
		   meta:set_int("effects_num", #effects_list)
		end
	end

	return h_rate, r_rate, t_rate, hun_rate, mov, jum, health, energy, thirst, hunger, temperature

end





-----------------------------
--Bonus Malus... so can be called whenever player status is changed
--takes standard rates and adjusts them based on player status.
--saves adjusted rates and applies physics.
--send it attributes to adjust by,
--also give name and meta, bc anything calling it should already have that
-- returns the adjusted rates so they can be used if desired
--
function HEALTH.malus_bonus(player, meta, health, energy, thirst, hunger, temperature)

	--use standard values, so it doesn't compound each time adjusted.
	--Only saved to player meta so they can be accessed without recalculating
	local h_rate = heal_rate
	local t_rate = thirst_rate
	local hun_rate = hunger_rate
	local r_rate = recovery_rate
	local mov = move
	local jum = jump


	--(hunger/Energy has 10x stock)
	--0-20 starving/severe dehydrated: malus, no heal
	--20-40 malnourished/dehydrated: malus
	--40-60 hungry/thirsty: small malus
	--60-80 good:
	--80-100 overfull: small malus

	--80-100 well rested. bonus
	--60-80 rested.
	--40-60 tired. small malus
	--20-40 fatigued. malus
	--0-20 exhausted. malus no heal

	--<27 death
	--27-32: severe hypo. malus no heal
	--32-37: hypothermia. malus
	--36-38: normal
	--38-43: hyperthermia. malus.
	--43-47: severe heat stroke. malus no heal
	-->47 death

	--
	--update rates
	--
	mov, jum, r_rate, h_rate, t_rate= calcHealthMods(player, health, energy, thirst, hunger, temperature)


	--health effects
	local HE_mov
	local HE_jum
	h_rate, r_rate, t_rate, hun_rate, HE_mov, HE_jum, health, energy, thirst, hunger, temperature = do_effects_list(meta, player, health, energy, thirst, hunger, temperature, h_rate, r_rate, t_rate, hun_rate,  mov, jum)

	

	--save adjusted rates for access (e.g. by a medical tab/equipment etc)
	meta:set_int("heal_rate", h_rate)
	meta:set_int("thirst_rate", t_rate)
	meta:set_int("hunger_rate", hun_rate)
	meta:set_int("recovery_rate", r_rate)
	meta:set_int("move", HE_mov)
	meta:set_int("jump", HE_jum)

	--apply player physics
	--don't do in bed or it buggers the physics
	
		player_monoids.speed:add_change(player, 1 + (mov/100), "health:physics")
		player_monoids.jump:add_change(player, 1 + (jum/100), "health:physics")
		--split physics from hunger etc from that from health effects
		--this means quick_physics can fiddle with one half, without overriding the half from effects
		HE_mov = HE_mov - mov
		HE_jum = HE_jum - jum
		player_monoids.speed:add_change(player, 1 + (HE_mov/100), "health:physics_HE")
		player_monoids.jump:add_change(player, 1 + (HE_jum/100), "health:physics_HE")

	--return adjusted rates so can be applied if necessary
	return h_rate, r_rate, t_rate, hun_rate, mov, jum, health, energy, thirst, hunger, temperature

end


-----------------------------
--Main
--
minetest.register_on_newplayer(function(player)
	set_default_attibutes(player)
end)

function reset_attributes(player)
   set_default_attibutes(player)
end

minetest.register_on_joinplayer(function(player)
	
	--set physics etc
    local name = player:get_player_name()
	local meta = player:get_meta()
	local health = player:get_hp()
	local thirst = meta:get_int("thirst")
	local hunger = meta:get_int("hunger")
	local energy = meta:get_int("energy")
	local temperature = meta:get_int("temperature")
	--HEALTH.malus_bonus(player, meta, health, energy, thirst, hunger, temperature)

	local velo = meta:get_string("player_velocity")
	if velo ~= nil then
	   local velo_vec = minetest.string_to_pos(velo)
	   if velo_vec ~= nil then
	      player:add_velocity(velo_vec)
	   end
	    meta:set_string("player_velocity", "")
	end
end)


minetest.register_on_dieplayer(function(player)
	--redo physics (to clear what killed them)
	player_monoids.speed:del_change(player, "health:physics")
	player_monoids.jump:del_change(player, "health:physics")
	player_monoids.speed:del_change(player, "health:physics_HE")
	player_monoids.jump:del_change(player, "health:physics_HE")
    player_monoids.speed:del_change(player, "main")
	player_monoids.jump:del_change(player, "main")
	--clear Health effects list
	local meta = player:get_meta()
	meta:set_string("effects_list", "")
	meta:set_int("effects_num", 0)
end)

minetest.register_on_respawnplayer(function(player)
	set_default_attibutes(player)
end)

minetest.register_on_leaveplayer(function(player, timed_out)
      --TODO: Find a way to save this on singleplayer or for 1st hosted player
      local meta = player:get_meta()
      local velo = player:get_velocity() or player:get_player_velocity()
      meta:set_string("player_velocity", minetest.pos_to_string(velo))
end)


--Main update values
local timer = 0
--frequency of updating and applying effects
local interval = 60
minetest.register_globalstep(function(dtime)
	timer = timer + dtime

	--run
	if timer > interval then
		timer = 0
		for _,player in ipairs(minetest.get_connected_players()) do

			local name = player:get_player_name()
			local meta = player:get_meta()
			local health = player:get_hp()
			-- don't damage us if we're already dead
			if health > 0  then
				local thirst = meta:get_int("thirst")
				local hunger = meta:get_int("hunger")
				local energy = meta:get_int("energy")
				local temperature = meta:get_int("temperature")

				--apply rate adjustments so they are correct for current player status
				local h_rate, r_rate, t_rate, hun_rate, mov, jum, health, energy, thirst, hunger, temperature  = HEALTH.malus_bonus(player, meta, health, energy, thirst, hunger, temperature)


				--update and min max
				local health1, thirst1, hunger1, energy1, temperature1

				thirst1 = thirst + t_rate
				thirst1 = bound(thirst1,0,1000)

				hunger1 = hunger + hun_rate
				hunger1=bound(hunger1,0,1000)

				energy1 = energy + r_rate
				energy1=bound(energy1,0,1000)

				health1 = health + h_rate

				if temperature > 37 then
					temperature1 = temperature - 1
					if temperature > 47 then
						health1 = health1 - 50
					end

				elseif temperature < 37 then
					temperature1 = temperature + 1
					if temperature < 27 then
						health1 = health1 - 50
					end
				else
					temperature1 = temperature
				end

				health1=bound(health1,0,PLAYER_MAX_HEALTH)

				player:set_hp(health1)
				meta:set_int("thirst", thirst1)
				meta:set_int("hunger", hunger1)
				meta:set_int("energy", energy1)
				meta:set_int("temperature", temperature1)
				
			end
		end
	end
end)


function calcHealthMods(player, health, energy, thirst, hunger, temperature)
    --use standard values
    local mov = 0
    local jum = 0
    local h_rate = heal_rate
    local t_rate = thirst_rate
    local hun_rate = hunger_rate
    local r_rate = recovery_rate

    --bonus/malus from health
    if health <= 50 then
        mov = mov - 50
        jum = jum - 50
        h_rate = h_rate - 3
        r_rate = r_rate - 4
    elseif health < 200 then
        mov = mov - 25
        jum = jum - 25
        h_rate = h_rate - 2
        r_rate = r_rate - 2
    elseif health < 400 then
        mov = mov - 20
        jum = jum - 20
        h_rate = h_rate - 1
        r_rate = r_rate - 1
    elseif health < 600 then
        mov = mov - 15
        jum = jum - 15
    elseif health < 800 then
        mov = mov - 10
        jum = jum - 10
    end

    --bonus/malus from energy
    if energy > 800 then
        h_rate = h_rate + 2
        mov = mov + 15
        jum = jum + 15
    elseif energy < 10 then
        h_rate = h_rate - 1
        mov = mov - 40
        jum = jum - 40
        t_rate = t_rate - 120
        hun_rate = hun_rate - 24
    elseif energy < 200 then
        h_rate = h_rate - 1
        mov = mov - 20
        jum = jum - 20
        t_rate = t_rate - 40
        hun_rate = hun_rate - 8
    elseif energy < 400 then
        mov = mov - 10
        jum = jum - 10
        t_rate = t_rate - 30
        hun_rate = hun_rate - 4
    elseif energy < 600 then
        mov = mov - 5
        jum = jum - 5
        t_rate = t_rate - 20
        hun_rate = hun_rate - 2
    elseif energy < 700 then
        hun_rate = hun_rate - 1
    end


    --bonus/malus from thirst
    if thirst > 80 then
        h_rate = h_rate + 1
        r_rate = r_rate + 2
        mov = mov + 1
        jum = jum + 1
    elseif thirst < 10 then
        h_rate = h_rate - 12
        r_rate = r_rate - 10
        mov = mov - 30
        jum = jum - 30
    elseif thirst < 20 then
        h_rate = h_rate - 2
        r_rate = r_rate - 2
        mov = mov - 20
        jum = jum - 20
    elseif thirst < 40 then
        h_rate = h_rate - 1
        r_rate = r_rate - 1
        mov = mov - 10
        jum = jum - 10
    elseif thirst < 60 then
        mov = mov - 1
        jum = jum - 1
    end

    --bonus/malus from hunger
    if hunger > 800 then
        h_rate = h_rate + 1
        r_rate = r_rate + 2
        mov = mov + 1
        jum = jum + 1
    elseif hunger < 1 then
        h_rate = h_rate - 12
        r_rate = r_rate - 10
        mov = mov - 30
        jum = jum - 30
    elseif hunger < 200 then
        h_rate = h_rate - 2
        r_rate = r_rate - 2
        mov = mov - 20
        jum = jum - 20
    elseif hunger < 400 then
        h_rate = h_rate - 1
        r_rate = r_rate - 1
        mov = mov - 10
        jum = jum - 10
    elseif hunger < 600 then
        mov = mov - 1
        jum = jum - 1
    end

    --temp malus..severe..having this happen would make you very ill
    if temperature >= 100 or temperature <= 0 then -- now will cause immediate death
    --you dead
        h_rate = h_rate - 10000
        r_rate = r_rate - 10000
        mov = mov - 10000
        jum = jum - 10000
    elseif temperature > 47 or temperature < 27 then
        h_rate = h_rate - 16
        r_rate = r_rate - 64
        mov = mov - 80
        jum = jum - 80
    elseif temperature > 43 or temperature < 32 then
        h_rate = h_rate - 8
        r_rate = r_rate - 32
        mov = mov - 40
        jum = jum - 40
    elseif temperature > 38 or temperature < 37 then
        h_rate = h_rate - 4
        r_rate = r_rate - 8
        mov = mov - 20
        jum = jum - 20
    end


    local player_pos = player:get_pos()
    local node_name = minetest.get_node(player_pos).name
    local water = minetest.get_item_group(node_name,"water")
    if water > 0 then 
        --minimal.log("Slowing down player in water "..mov)
        local min=math.min(mov,-90)
        mov= math.max(mov - 80,min)
    end


    --minimal.log("calcHealthMods: "..mov.." "..jum)

    return mov, jum, r_rate, h_rate, t_rate
end


