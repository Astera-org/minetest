local random = math.random
local pi = math.pi
local time = os.time
local sqrt = math.sqrt

local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min
local tan = math.tan
local pow = math.pow

local function math_clamp(...) -- num, min, max
  return minimal.math_clamp(...)
end

local max_objects = 30
local mo_check_radius = 40 -- maxobject check radius

animals = animals
mobkit = mobkit

local use_vh1 = minetest.get_modpath("visual_harm_1ndicators")

--------------------------------------------------------------------------
--basic
--------------------------------------------------------------------------


-- returns 2D angle from self to target in radians
local function get_yaw_to_object(pos, opos)
  local ankat = pos.x - opos.x
  local gegkat = pos.z - opos.z
  local yaw = math.atan2(ankat, gegkat)
  return yaw
end


--flee sound (has to be in water!)
local function flee_sound(self)
	if not self.isinliquid then
		return
	end
	mobkit.make_sound(self,'flee')
end

--------------------------------------------------------------------------
--Life and death
--------------------------------------------------------------------------

----------------------------------------------------
-- drop on death what is defined in the entity table
function animals.handle_drops(self)
   if use_vh1 then
      VH1.clear_bar(self.object)
   end

   if not self.drops then
     return
   end

   for _,item in ipairs(self.drops) do

     local amount = random (item.min, item.max)
     local chance = random(1,100)
     local pos = self.object:get_pos()
     pos.y = pos.y+0.5

     if chance < (100/item.chance) then
       --leave time for death animation to end
       minetest.after(5, function()
         minetest.add_item(pos, item.name.." "..tostring(amount))
       end)
     end

   end
 end

----------------------------------------------------
--core health
function animals.core_hp(self)
  --default drowing and fall damage
  local hp = self.hp
  mobkit.vitals(self)
  --die from damage
  if use_vh1 and hp ~= self.hp then -- hp has changed, update hp bar
     VH1.update_bar(self.object, self.hp, self.max_hp)
  end
  hp = self.hp
  if hp <= 0 then
    mobkit.clear_queue_high(self)
    animals.handle_drops(self)
    mobkit.hq_die(self)
    return false
  else
    return true
  end
end



function animals.core_hp_water(self)

  if not self.isinliquid then
    mobkit.hurt(self,1)
    if use_vh1 then
       VH1.update_bar(self.object, self.hp, self.max_hp)
    end
  end
  --die from damage
  local hp = self.hp


local energy = mobkit.recall(self,'energy')
local age = mobkit.recall(self,'age')
if not age then age=0 end
if not energy then energy = 0 end
  if hp <= 0 then
    mobkit.clear_queue_high(self)
    animals.handle_drops(self)
    mobkit.hq_die(self)
    return false
  else
    return true
  end
end


local function get_mean_temp(pos) -- this could be put somewhere else like in climate or minimal
  local temps = {}
  
  if (type(pos) ~= "table") then -- no pos table is given then
    return 15
  elseif (type(pos.x) ~= "number" or type(pos.y) ~= "number" or type(pos.z) ~= "number") then -- incase an invalid pos is given
    return 15
  end
  
  for x = -1, 1, 1 do -- create matrix of possible positions
    for y = -1, 1, 1 do
      for z = -1, 1, 1 do
        local npos = {x = (pos.x - x), y = (pos.y - y), z = (pos.z - z)} -- matrix the pos :D
        
        temps[#temps + 1] = climate.get_point_temp(npos, true)
      end
    end
  end
  
  local mtemp = 0 -- start with a number so it can be calculated
  for _,num in pairs(temps) do
    mtemp = mtemp + num
  end
  
  return mtemp / #temps -- return the "mean" of the matrix'd temps
end

----------------------------------------------------
--core health, energy and age
function animals.core_life(self, lifespan, pos)

  local energy = mobkit.recall(self,'energy')
  local age = mobkit.recall(self,'age')
  local hbnate = mobkit.recall(self,'hibernate')
  
  local energy_loss = self.energy_loss or 0.25

  --stops some crashes in creative?
  if not energy then
    energy = 1
  end
  if not age then
    age = 0
  end
  if not hbnate then
    hbnate = false
  end

  age = age + 1
  if (hbnate == false) then
    energy = energy - energy_loss
  elseif (random() <= 0.005) then -- 0.5% chance to lose energy during hibernation
    energy = energy - energy_loss
  end

  --die from exhaustion, old age
  if energy <=0 or age > lifespan then
    mobkit.clear_queue_high(self)
    animals.handle_drops(self)
    mobkit.hq_die(self)
    return nil
  end

  --die from high temp
  local temp = climate.get_point_temp(pos, true)
  if (temp == 450) then -- get the mathematical "mean" of the pos and the surroundings nodes (workaround to torches)
    temp = get_mean_temp(pos)
  end
  if temp > 100 then -- if it's still boiling time
    -- make the animal exhausted and hurt them (instant death)
     energy = 0
     mobkit.hurt(self, temp)
  end

  --temperature stress
  if temp < self.min_temp or temp > self.max_temp then
    -- if this temperature is uncomfortable, try to find somewhere else!
    if (self.class ~= 2) then
      -- only for land creatures
      animals.hq_roam_comfort_temp(self,80, self.max_temp / 2)
      hbnate = false -- moving around, thus not hibernating
    end
    if temp > self.max_temp * 4 then
       mobkit.hurt(self,2)
    end
  end


  --heal using energy
  if self.hp < self.max_hp and energy > 10 and random() <= 0.75 then
    if not (not self.isinliquid and self.class == 2) then
      -- if not a fish out of water then (fish in water will heal up nicely :D)
      mobkit.heal(self,1)
      if use_vh1 then
	 VH1.update_bar(self.object, self.hp, self.max_hp)
      end
      energy = energy - 5
    end
  end
  
  if (hbnate == true) then
    mobkit.clear_queue_low(self)
    mobkit.animate(self,"dead")
  end

  return age, energy, hbnate
end



----------------------------------------------------
--put an egg in the world, return energy
function animals.place_egg(pos, egg_name, energy, energy_egg, medium)
  
  local p = mobkit.get_node_pos(pos)
  local e = energy
  local animal_name = string.gsub(egg_name,"_eggs","")
  animal_name = string.gsub(animal_name,"_egg","") -- incase it is singular
  local objcount = #animals.get_entities_inside_radius(animal_name,pos,mo_check_radius)

  if minetest.get_node(p).name == medium and objcount < max_objects then

    local posu = {x = p.x, y = p.y - 1, z = p.z}
    local n = mobkit.nodeatpos(posu)

    if n and n.walkable and n.name ~= "nodes_nature:tree_mark" then
      minetest.set_node(p, {name = egg_name})
      e = energy - energy_egg
    end

  end

  return e
end


----------------------------------------------------
--release offspring from an egg (called from timers)
function animals.hatch_egg(pos, medium_name, replace_name, name, energy_egg, young_per_egg)

   local air = minetest.find_nodes_in_area(
      {x=pos.x-1, y=pos.y-1, z=pos.z-1},
      {x=pos.x+1, y=pos.y+1, z=pos.z+1}, {medium_name})
  --if can't find the stuff this mob moves through then it dies
	if #air < 1 then
		minetest.set_node(pos, {name = replace_name})
		return false
	end

  local cnt = 0
  local start_e = math.floor(energy_egg/young_per_egg)
  local objcount = #animals.get_entities_inside_radius(name, pos, mo_check_radius)
  while cnt < young_per_egg and objcount < max_objects do
    local ran_pos = air[random(#air)]
    local ent = minetest.add_entity(ran_pos, name)
    minetest.sound_play("animals_hatch_egg", {pos = pos, gain = 0.2, max_hear_distance = 6})
    ent = ent:get_luaentity()
    mobkit.remember(ent,'energy', start_e)
    mobkit.remember(ent,'age',0)
    objcount = objcount + 1
    cnt = cnt + 1
  end

  minetest.set_node(pos, {name = replace_name})
  return false

end

 --------------------------------------------------------------------------
 --Movement
 --------------------------------------------------------------------------



----------------------------------------------
--roam to places with equal or lesser darkness
function animals.hq_roam_dark(self,prty)
  local timer = time() + 30
  local func=function(self)
    if time() > timer then
      return true
    end

    if mobkit.is_queue_empty_low(self) and self.isonground then
       local pos = mobkit.get_stand_pos(self)
       local neighbor = random(8)

       local height, tpos, liquidflag = mobkit.is_neighbor_node_reachable(self,neighbor)

       if height and not liquidflag then
       local light = minetest.get_node_light(pos, 0.5) or 0
       local lightn = minetest.get_node_light(tpos, 0.5) or 0
       if lightn <= light then
         mobkit.dumbstep(self,height,tpos,0.3)
       else
         return true
       end
     end
		end
	end
	mobkit.queue_high(self,func,prty)
end



----------------------------------------------
--roam to places with comfortable temperature
function animals.hq_roam_comfort_temp(self,prty, opt_temp)
  local timer = time() + 30

  local func = function(self)
    if time() > timer then
      return true
    end

    if mobkit.is_queue_empty_low(self) and self.isonground then
       local pos = mobkit.get_stand_pos(self)
       local neighbor = random(8)

       local height, tpos, liquidflag = mobkit.is_neighbor_node_reachable(self,neighbor)

       if height and not liquidflag then
	  local temp = climate.get_point_temp(pos, true)
	  local tempn = climate.get_point_temp(tpos, true)
	  local dif = abs(opt_temp - temp)
	  local difn = abs(opt_temp - tempn)

	  if difn <= dif then
	     mobkit.dumbstep(self,height,tpos,0.3)
	  else
	     return true
	  end
       end
    end
  end
  mobkit.queue_high(self,func,prty)
end


----------------------------------------------
--roam to a better surface (by group)
function animals.hq_roam_surface_group(self, group, prty)
  local timer = time() + 15

  local func=function(self)

    if time() > timer then
      return true
    end

    if mobkit.is_queue_empty_low(self) and self.isonground then
      local neighbor = random(8)

      local height, tpos, liquidflag = mobkit.is_neighbor_node_reachable(self, neighbor)

      if height and not liquidflag then
        --is it the correct group?
        local s_pos = tpos
        s_pos.y = s_pos.y - 1
        local under = minetest.get_node(s_pos)

        if under and minetest.get_item_group(under.name, group) > 0 then
          mobkit.dumbstep(self, height, tpos, 0.3)
        else
          return true
        end
      end

    end
  end
  mobkit.queue_high(self,func,prty)
end


----------------------------------------------
--roam to a walkable (by group) i.e. walk into the node itself c.f. under
function animals.hq_roam_walkable_group(self, group, prty)
  local timer = time() + 15

  local func=function(self)

    if time() > timer then
      return true
    end

    if mobkit.is_queue_empty_low(self) and self.isonground then
       local neighbor = random(8)

       local height, tpos, liquidflag = mobkit.is_neighbor_node_reachable(
	  self, neighbor)

       if height and not liquidflag then
        --is it the correct?
        local n_node = minetest.get_node(tpos).name

        if minetest.get_item_group(n_node, group) > 0 then
          mobkit.dumbstep(self, height, tpos, 0.3)
        else
          return true
        end
      end

    end
  end
  mobkit.queue_high(self,func,prty)
end


local function aqua_path_safe(start_pos,p)
	local path=minetest.raycast(start_pos,p,false,true)
	for pointed_thing in path do
		local node=mobkit.nodeatpos(pointed_thing.intersection_point)
		if node and node.drawtype ~= 'liquid' then
			return false
		end
	end
	return true
end


 ---------------------------------------------------
--(currently duplicated in mobkit, but only as a local function)
local function aqua_radar_dumb(pos,yaw,range,reverse)
 range = range or 4
 local function okpos(p,start_pos)
   local node = mobkit.nodeatpos(p)
   if node then
     if node.drawtype == 'liquid' then
       local nodeu = mobkit.nodeatpos(mobkit.pos_shift(p,{y=1}))
       local noded = mobkit.nodeatpos(mobkit.pos_shift(p,{y=-1}))
       if ((nodeu and nodeu.drawtype == 'liquid') or (noded and noded.drawtype == 'liquid')) then
         return true
       else
         return false
       end
     else
       local h,_ = mobkit.get_terrain_height(p)
       if h then
         local node2 = mobkit.nodeatpos({x=p.x,y=h+1.99,z=p.z})
         if node2 and node2.drawtype == 'liquid' then
		 return true, h
	 end
       else
         return false
       end
     end
   else
     return false
   end
 end
-- check node in front at range.
 local fpos = mobkit.pos_translate2d(pos,yaw,range)
 local ok,h = okpos(fpos,pos)


 if not ok then
--check nodes right and left of possition.
--Reverse checks from back to front first
   local ffrom, fto, fstep
   if reverse then
     ffrom, fto, fstep = 3,1,-1
   else
     ffrom, fto, fstep = 1,3,1
   end
   for i=ffrom, fto, fstep  do
     ok,h = okpos(mobkit.pos_translate2d(pos,yaw+i,range),pos)
     if ok then
       return yaw+i,h
     end
     ok,h = okpos(mobkit.pos_translate2d(pos,yaw-i,range),pos)
     if ok then
       return yaw-i,h
     end
   end
   -- No safe path so reverse direction.
   return yaw+pi,h
 else
   return yaw, h
 end
end


---------------------------------------------------
-- turn around  from opos and swim away until out of sight
function animals.hq_swimfrompos(self,prty,opos,speed)
  local timer = time() + 2
  local func = function(self)

    if time() > timer then
      return true
    end

    local pos = mobkit.get_stand_pos(self)
    local distance = vector.distance(pos,opos)
    -- rotate 30 degrees to right from current yaw
    local yaw = self.object:get_yaw() - pi/6
    if distance > 0.5 then
	-- or 180 from pos we're running from if no longer close to it
    	yaw = get_yaw_to_object(pos, opos) - pi
    end


    if (distance/1.5) < self.view_range then
      local swimto, height = aqua_radar_dumb(pos,yaw,1)
      if height and height > pos.y then
        local vel = self.object:get_velocity()
        vel.y = vel.y+0.2
        self.object:set_velocity(vel)
      end

      mobkit.hq_aqua_turn(self,prty,swimto,speed)

    else
      return true
    end

  end
  mobkit.queue_high(self,func,prty)
 end



---------------------------------------------------
-- turn around  from tgtob and swim away until out of sight
function animals.hq_swimfrom(self,prty,tgtobj,speed)
  local timer = time() + 2

  local func = function(self)

    if time() > timer then
      return true
    end

    if not mobkit.is_alive(tgtobj) then
      return true
    end
    local pos = mobkit.get_stand_pos(self)
    local opos = tgtobj:get_pos()

    local yaw = get_yaw_to_object(pos, opos) - (pi/2)
    local distance = vector.distance(pos,opos)

    if (distance/1.5) < self.view_range then
      local swimto, height = aqua_radar_dumb(pos,yaw,speed)
      if height and height > pos.y then
        local vel = self.object:get_velocity()
        vel.y = vel.y+0.1
        self.object:set_velocity(vel)
      end

      mobkit.hq_aqua_turn(self,prty,swimto,speed)

    else
      return true
    end

  end
  mobkit.queue_high(self,func,prty)
 end




 ---------------------------------------------------
 -- chase tgtob until somewhat out of sight
function mobkit.hq_chaseafter(self,prty,tgtobj)
  local timer = time() + 3

  local func = function(self)
    if time() > timer then
      return true
    end

    if not mobkit.is_alive(tgtobj) then return true end

    if mobkit.is_queue_empty_low(self) and self.isonground then
			local pos = mobkit.get_stand_pos(self)
			local opos = tgtobj:get_pos()
			if vector.distance(pos,opos) > 3 then
        mobkit.make_sound(self,'warn')
				mobkit.goto_next_waypoint(self,opos)
			else
				mobkit.lq_idle(self,1)
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end

 ---------------------------------------------------
 -- chase tgtob and swim until somewhat out of sight
 function animals.hq_swimafter(self,prty,tgtobj,speed)
   local timer = time() + 3

   local func = function(self)
     if time() > timer then
       return true
     end

     if not mobkit.is_alive(tgtobj) then
       return true
     end

     local pos = mobkit.get_stand_pos(self)
     local opos = tgtobj:get_pos()

     local yaw = get_yaw_to_object(pos, opos) -pi
     local distance = vector.distance(pos,opos)

     if distance < self.view_range/3 then
       local swimto, height = aqua_radar_dumb(pos,yaw,3)
       if height and height > pos.y then
         local vel = self.object:get_velocity()
         vel.y = vel.y+0.1
         self.object:set_velocity(vel)
       end

       mobkit.hq_aqua_turn(self,prty,swimto,speed)

     else
       return true
     end

   end
   mobkit.queue_high(self,func,prty)
 end





--------------------------------------------------------------------------
--Attack and feeding
--------------------------------------------------------------------------

----------------------------------------------------------------
--on_punch
function animals.on_punch(self, tool_capabilities, puncher, prty, chance)
  if mobkit.is_alive(self) then
    --do damage
    mobkit.clear_queue_high(self)
    local hbnate = mobkit.recall(self,'hibernate')
    local dmg = tool_capabilities.damage_groups.fleshy or 1
    mobkit.hurt(self,dmg)
    mobkit.make_sound(self,'punch')
    if use_vh1 then
       VH1.update_bar(self.object, self.hp, self.max_hp)
    end
    --fight or flight
    --flee if hurt (or hibernating!)
    if self.hp < self.max_hp/10 or self.hp <= (dmg * 2) or hbnate == true then 
      mobkit.animate(self,'fast')
      mobkit.make_sound(self,'warn')
      mobkit.hq_runfrom(self, prty, puncher)
    elseif prty < 20 then
      animals.fight_or_flight(self, puncher, prty, chance)
    end


  end
end


function animals.on_punch_water(self, tool_capabilities, puncher, prty, chance)
  if mobkit.is_alive(self) then
    --do damage
    mobkit.clear_queue_high(self)
    mobkit.hurt(self,tool_capabilities.damage_groups.fleshy or 1)
    mobkit.make_sound(self,'punch')
    if use_vh1 then
       VH1.update_bar(self.object, self.hp, self.max_hp)
    end

    --fight or flight
    if self.hp < self.max_hp/10 then
      mobkit.animate(self,'fast')
      animals.hq_swimfrom(self, prty, puncher, self.max_speed)
      flee_sound(self)
    else
      animals.fight_or_flight_water(self, puncher, prty, chance)
    end

  end
end

----------------------------------------------------------------
--attack or run vs player
function animals.fight_or_flight_plyr(self, plyr, prty, chance)
  mobkit.clear_queue_high(self)
  --fight chance, or run away (don't do it attach bc buggers physics)
  if random()< chance and plyr:get_attach() == nil then
    mobkit.hq_warn(self,prty,plyr)
  else
    --mobkit.animate(self,'fast')
    --mobkit.make_sound(self,'scared')
    mobkit.hq_runfrom(self,prty, plyr)
  end
end

--attack or run vs entity
function animals.fight_or_flight(self, threat, prty, chance)
  mobkit.clear_queue_high(self)
  --fight chance, or run away
  if random()< chance then
    mobkit.hq_warn(self,prty, threat)
  else
    --mobkit.animate(self,'fast')
    --mobkit.make_sound(self,'scared')
    mobkit.hq_runfrom(self,prty, threat)
  end
end




----attack or run vs player in water
function animals.fight_or_flight_plyr_water(self, plyr, prty, chance)
  mobkit.clear_queue_high(self)
  --ignore chance, or run away
  if random()< chance and plyr:get_attach() == nil then
    mobkit.hq_aqua_attack(self, prty, plyr, self.max_speed)
  else
    mobkit.animate(self,'fast')
    animals.hq_swimfrom(self, prty, plyr, self.max_speed)
    flee_sound(self)
  end
end

----attack or run vs player in water
function animals.fight_or_flight_water(self, threat, prty, chance)
  mobkit.clear_queue_high(self)
  --ignore chance, or run away
  if random()< chance then
    mobkit.hq_aqua_attack(self, prty, threat, self.max_speed)
  else
    mobkit.animate(self,'fast')
    animals.hq_swimfrom(self, prty, threat, self.max_speed)
    flee_sound(self)
  end
end

----------------------------------------------------------------
--Find and Flee predators
function animals.predator_avoid(self, prty, chance)

  for  _, pred in ipairs(self.predators) do
    local thr = mobkit.get_closest_entity(self,pred)
    if thr then
      animals.fight_or_flight(self, thr, prty, chance)
      return thr
    end
  end
end


function animals.predator_avoid_water(self, prty, chance)

  for  _, pred in ipairs(self.predators) do
    local thr = mobkit.get_closest_entity(self,pred)
    if thr then
      animals.fight_or_flight_water(self, thr, prty, chance)
      return thr
    end
  end
end

----------------------------------------------------------------
--Find and hunt prey
function animals.prey_hunt(self, prty)

  for  _, prey in ipairs(self.prey) do
    local tgtobj = mobkit.get_closest_entity(self,prey)
    if tgtobj then
      animals.hq_attack_eat(self,prty,tgtobj)
      return true
    end
  end
end


function animals.prey_hunt_water(self, prty)

  for  _, prey in ipairs(self.prey) do
    local tgtobj = mobkit.get_closest_entity(self,prey)
    if tgtobj then
      mobkit.animate(self,'fast')
      flee_sound(self)
      animals.hq_aqua_attack_eat(self, prty, tgtobj, self.max_speed)
      return true
    end
  end
end




----------------------------------------------------
--for things that eat spreading surface
function animals.eat_spreading_under(pos, chance)
  local p = mobkit.get_node_pos(pos)
  local posu = {x = p.x, y = p.y - 1, z = p.z}
  local under = minetest.get_node(posu).name

  if minetest.get_item_group(under, "spreading") > 0 then
    if random()< chance then
      --set node to it's drop
      --this is to scratch up surface layers
      local nodedef = minetest.registered_nodes[under]
      local drop = nodedef.drop
      minetest.check_for_falling(posu)
      minetest.set_node(posu, {name = drop})
      minetest.sound_play("nodes_nature_dig_crumbly", {gain = 0.2, pos = pos, max_hear_distance = 10})
    end

    return true

  else
    return false
  end

end

----------------------------------------------------
--for things that eat sediment (i.e. dig in the mud)
function animals.eat_sediment_under(pos, chance)
  local p = mobkit.get_node_pos(pos)
  local posu = {x = p.x, y = p.y - 1, z = p.z}
  local under = minetest.get_node(posu).name

  if minetest.get_item_group(under, "sediment") > 0 then
    if random()< chance then
      --set node to it's drop
      --this is to scratch up surface layers
      local nodedef = minetest.registered_nodes[under]
      local drop = nodedef.drop
      minetest.check_for_falling(posu)
      minetest.set_node(posu, {name = drop})
      minetest.sound_play("nodes_nature_dig_crumbly", {gain = 0.2, pos = pos, max_hear_distance = 10})
    end

    return true

  else
    return false
  end

end


----------------------------------------------------
--eating any flora

function animals.eat_flora(pos, chance)
  local p = mobkit.get_node_pos(pos)
  local node = minetest.get_node(p).name

  if minetest.get_item_group(node, "flora") > 0
  and minetest.get_item_group(node, "cane_plant") == 0
  then
    --gain energy
    if random()< chance then
      --destroy the plant
      minetest.set_node(p, {name = 'air'})
      minetest.sound_play("nodes_nature_dig_snappy", {gain = 0.2, pos = pos, max_hear_distance = 10})
    end

    return true
  else
    return false
  end
end


----------------------------------------------------------------
--like mobkit version, but including removal of prey and gaining energy
--to hit is to catch... for predators, where the chewing does the killing
function animals.hq_aqua_attack_eat(self,prty,tgtobj,speed)
 local timer = time() + 12

	local tyaw = 0
	local prvscanpos = {x=0,y=0,z=0}
	local init = true
	local tgtbox = tgtobj:get_properties().collisionbox

	local func = function(self)
  if time() > timer then
    return true
  end

		if not mobkit.is_alive(tgtobj) then
    return true
  end

		if init then
			mobkit.animate(self,'fast')
			mobkit.make_sound(self,'attack')
			init = false
		end

		local pos = mobkit.get_stand_pos(self)
		local yaw = self.object:get_yaw()
		local scanpos = mobkit.get_node_pos(mobkit.pos_translate2d(pos,yaw,speed))
		if not vector.equals(prvscanpos,scanpos) then
			prvscanpos=scanpos
			local nyaw,height = aqua_radar_dumb(pos,yaw,speed*0.5)
			if height and height > pos.y then
				local vel = self.object:get_velocity()
				vel.y = vel.y+1
				self.object:set_velocity(vel)
			end
			if yaw ~= nyaw then
				tyaw=nyaw
				mobkit.hq_aqua_turn(self,prty+1,tyaw,speed)
				return
			end
		end

		local tpos = tgtobj:get_pos()
		tyaw=minetest.dir_to_yaw(vector.direction(pos,tpos))
		mobkit.turn2yaw(self,tyaw,3)
		yaw = self.object:get_yaw()
		if mobkit.timer(self,1) then
			if not mobkit.is_in_deep(tgtobj) then return true end
			local vel = self.object:get_velocity()
			if tpos.y>pos.y+0.5 then self.object:set_velocity({x=vel.x,y=vel.y+0.5,z=vel.z})
			elseif tpos.y<pos.y-0.5 then self.object:set_velocity({x=vel.x,y=vel.y-0.5,z=vel.z}) end
		end
		if mobkit.is_pos_in_box(mobkit.pos_translate2d(pos,yaw,self.attack.range),tpos,tgtbox) then	--bite
    mobkit.make_sound(self,'bite')
			tgtobj:punch(self.object,1,self.attack)
			mobkit.hq_aqua_turn(self,prty,yaw-pi,speed)
    if random()>0.15 then
      local ent = tgtobj:get_luaentity()
      local ent_e = (mobkit.recall(ent,'energy') or 1)
      local self_e = (mobkit.recall(self,'energy') or 1)
      mobkit.remember(self,'energy', (ent_e*0.7) + self_e)
      ent.object:remove()
      return true
    end
		end
		mobkit.go_forward_horizontal(self,speed)
	end
  mobkit.queue_high(self,func,prty)
end





---------------------------------------------------
--like mobkit version, but including removal of prey and gaining energy
--to hit is to catch... for predators, where the chewing does the killing
local function lq_jumpattack_eat(self,height,target)
	local phase=1
	local tgtbox = target:get_properties().collisionbox

	local func=function(self)
		if not mobkit.is_alive(target) then return true end

		if self.isonground then
			if phase==1 then	-- collision bug workaround
				local vel = self.object:get_velocity()
				vel.y = -mobkit.gravity*sqrt(height*2/-mobkit.gravity)
				self.object:set_velocity(vel)
				mobkit.make_sound(self,'charge')
				phase=2
			else
				mobkit.lq_idle(self,0.3)
				return true
			end
		elseif phase==2 then
			local dir = minetest.yaw_to_dir(self.object:get_yaw())
			local vy = self.object:get_velocity().y
			dir=vector.multiply(dir,6)
			dir.y=vy
			self.object:set_velocity(dir)
			phase=3
		elseif phase==3 then	-- in air
			local tgtpos = target:get_pos()
			local pos = self.object:get_pos()

			-- calculate attack spot
			local yaw = self.object:get_yaw()
			local dir = minetest.yaw_to_dir(yaw)
			local apos = mobkit.pos_translate2d(pos,yaw,self.attack.range)

			if mobkit.is_pos_in_box(apos,tgtpos,tgtbox)
      or (mobkit.isnear2d(pos,tgtpos,1) and random()<0.1) --makes up for issue with some boxes not working together
      then	--bite
				target:punch(self.object,1,self.attack)
					-- bounce off
				local vy = self.object:get_velocity().y
				self.object:set_velocity({x=dir.x*-3,y=vy,z=dir.z*-3})
					-- play attack sound if defined
				mobkit.make_sound(self,'attack')
				phase=4
        local ent = target:get_luaentity()
        local ent_hp = ent.hp or 1
        local ent_mhp = ent.max_hp or 1
        local dmg = 1
        if (type(self.attack) == "table") then
          if (type(self.attack.damage_groups) == "table") then
            dmg = self.attack.damage_groups.fleshy or 1
            
            dmg = math_clamp(dmg,0,ent_mhp) -- clamp damage between 0 and entity max health to prevent excessive energygain
          end
        end
        
        mobkit.hurt(ent,dmg) -- hurt opponent
        
        -- eat bits of opponent
        local ent_e = (mobkit.recall(ent,'energy') or 1)
        local self_e = (mobkit.recall(self,'energy') or 1)
        local energygain = (ent_e * (dmg / ent_mhp) ) -- omnomnom
        
        mobkit.remember(self,'energy', (energygain*0.4)  + self_e) -- take 40%
        mobkit.remember(ent,'energy', ent_e - energygain) -- make opponent lose energy
        
        if (ent.hp <= dmg) then
          local ent_e = (mobkit.recall(ent,'energy') or 1)
          local self_e = (mobkit.recall(self,'energy') or 1)
          mobkit.remember(self,'energy', (energygain*0.25) + self_e) -- add another 25% for nomming fully
          ent.object:remove()
          return true
        end
        
			end
		end
	end
	mobkit.queue_low(self,func)
end



function animals.hq_attack_eat(self,prty,tgtobj)
  local timer = time() + 12

	local func = function(self)
    if time() > timer then
      return true
    end

		if not mobkit.is_alive(tgtobj) then return true end

		if mobkit.is_queue_empty_low(self) then
      local pos = mobkit.get_stand_pos(self)
		--	local pos = mobkit.get_stand_pos(self)
			local tpos = mobkit.get_stand_pos(tgtobj)
			local dist = vector.distance(pos,tpos)
			if dist > 3 then
				return true
			else
			   mobkit.lq_turn2pos(self,tpos)
			   local tgtheight = tgtobj:get_luaentity().height
			   if tgtheight == nil then
			      tgtheight = 0
			   end
        local height = tgtobj:is_player() and 0.35 or tgtheight*0.6
				if tpos.y+height>pos.y then
					lq_jumpattack_eat(self,tpos.y+height-pos.y,tgtobj)

				else
					mobkit.lq_dumbwalk(self,mobkit.pos_shift(tpos,{x=random()-0.5,z=random()-0.5}))
				end
			end
		end
	end
	mobkit.queue_high(self,func,prty)
end





----------------------------------------------------------------
--Social Behaviour


----------------------------------------------------------------
--territorial behaviour
--avoid those in better condition
function animals.territorial(self, energy, eat)

  for  _, riv in ipairs(self.rivals) do

    local rival = mobkit.get_closest_entity(self, riv)

    if rival then

      --flee if hurt
      if self.hp < self.max_hp/4 then
        mobkit.animate(self,'fast')
        mobkit.make_sound(self,'warn')
        mobkit.hq_runfrom(self, 25, rival)
        return true
      end

      --contest! The more energetic one wins
      local r_ent = rival:get_luaentity()
      local r_ent_e = mobkit.recall(r_ent,'energy') or 0

      if energy > r_ent_e then
        if eat then
          animals.hq_attack_eat(self, 25, rival)
        else
          mobkit.animate(self,'fast')
          mobkit.make_sound(self,'warn')
          mobkit.hq_chaseafter(self,25,rival)
        end
        return true
      else
        mobkit.animate(self,'fast')
        mobkit.make_sound(self,'warn')
        mobkit.hq_runfrom(self,25,rival)
        return true
      end
    end

  end

end


--water version
function animals.territorial_water(self, energy, eat)

  for  _, riv in ipairs(self.rivals) do

    local rival = mobkit.get_closest_entity(self, riv)

    if rival then

      --flee if hurt
      if self.hp < self.max_hp/4 then
        mobkit.animate(self,'fast')
        flee_sound(self)
        animals.hq_swimfrom(self, 25, rival ,self.max_speed)
        return true
      end

      --contest! The more energetic one wins
      local r_ent = rival:get_luaentity()
      local r_ent_e = mobkit.recall(r_ent,'energy')

      --not clear why some have nil, but it happens
      if r_ent_e == nil then
        return
      end

      if energy > r_ent_e then
        if eat then
          animals.hq_aqua_attack_eat(self, 25, rival, self.max_speed)
          flee_sound(self)
        else
          --harass
          mobkit.animate(self,'fast')
          animals.hq_swimafter(self, 15, rival, self.max_speed)
          flee_sound(self)
        end
        return true
      else
        mobkit.animate(self,'fast')
        flee_sound(self)
        animals.hq_swimfrom(self, 25, rival ,self.max_speed)
        return true
      end
    end

  end

end


----------------------------------------------------------------
--flocking behaviour
--follow friends

function animals.hq_flock(self,prty,tgtobj, min_dist)
  local timer = time() + 5

  local func = function(self)
    if time() > timer then
      return true
    end

    if not mobkit.is_alive(tgtobj) then return true end

    if mobkit.is_queue_empty_low(self) then
      local pos = mobkit.get_stand_pos(self)
      local tpos = mobkit.get_stand_pos(tgtobj)
      local dist = vector.distance(pos,tpos)
      if dist <= min_dist then
        mobkit.lq_idle(self,1)
        return true
      else
        mobkit.goto_next_waypoint(self,tpos)
      end
    end
  end

  mobkit.queue_high(self,func,prty)
end



function animals.hq_flock_water(self,prty,tgtobj, min_dist, speed)
  local timer = time() + 7

  local func = function(self)
    if time() > timer then
      return true
    end

    if not mobkit.is_alive(tgtobj) then
      return true
    end

    local pos = mobkit.get_stand_pos(self)
    local opos = tgtobj:get_pos()

    local yaw = get_yaw_to_object(pos, opos) - (pi/2)
    local distance = vector.distance(pos,opos)

    if distance > min_dist then
      local swimto, height = aqua_radar_dumb(pos,yaw,3)
      if height and height > pos.y then
        local vel = self.object:get_velocity()
        vel.y = vel.y+0.1
        self.object:set_velocity(vel)
      end

      mobkit.hq_aqua_turn(self,prty,swimto,speed)

    else
      --sync with target
      local tvel = tgtobj:get_velocity()
      local tyaw = tgtobj:get_yaw()

      mobkit.hq_aqua_turn(self,prty+1,tyaw,tvel)
      mobkit.make_sound(self,'call')
      return true
    end

  end
  mobkit.queue_high(self,func,prty)
 end







function animals.flock(self, prty, min_dist, aqua_speed)

  for  _, fr in ipairs(self.friends) do

    --local friend = mobkit.get_closest_entity(self, fr)
    local friend =mobkit.get_nearby_entity(self, fr)

    if friend then
      --get distance, if too far away go to them
      if aqua_speed then
        mobkit.animate(self,'walk')
        mobkit.make_sound(self,'call')
        animals.hq_flock_water(self, prty, friend, min_dist, aqua_speed)
      else
        mobkit.animate(self,'walk')
        mobkit.make_sound(self,'call')
        animals.hq_flock(self, prty, friend, min_dist)
      end
      return
    end
  end

end

----------------------------------------------------------------
--mate
--go after them, if close enough do the deed
function animals.hq_mate(self,prty,tgtobj)
  local timer = time() + 10

  local func = function(self)
    if time() > timer then
      return true
    end

    if not mobkit.is_alive(tgtobj) then return true end

    if mobkit.is_queue_empty_low(self) then
      local pos = mobkit.get_stand_pos(self)
      local tpos = mobkit.get_stand_pos(tgtobj)
      local dist = vector.distance(pos,tpos)
      if dist <= self.attack.range then
        mobkit.lq_idle(self,1)
        mobkit.make_sound(self,'mating')
        if self.sex == "male" then
          --get the other one pregnant
          mobkit.remember(tgtobj,'pregnant',true)
        else
          --get pregnant
          mobkit.remember(self,'pregnant',true)
        end
        return true
      else
        mobkit.make_sound(self,'call')
        mobkit.goto_next_waypoint(self,tpos)
      end
    end
  end

  mobkit.queue_high(self,func,prty)
end

--assess potential mate
function animals.mate_assess(self, name)
  local mate = mobkit.get_nearby_entity(self, name)
  if mate then
    --see if they are in the mood
    local ent = mate:get_luaentity()
    local sexy = mobkit.recall(ent,'sexual') or false
    local preg = mobkit.recall(ent,'pregnant') or false
    if sexy == true and preg == false then
      return ent
    else
      return false
    end
  else
    return false
  end

end

function animals.get_entities_inside_radius(creature,pos,radius,match_string)
  if (type(radius) ~= "number") then
    radius = 30
  end
  -- will use string.match if true
  if (type(match_string) ~= "boolean") then
    match_string = true
  end
  -- if provided creature is an entity or objectref
  if (type(creature) == "userdata") then
    if (type(creature["get_luaentity"]) == "function") then
      creature = creature:get_luaentity()
    end
    if (type(creature) ~= "nil" and type(creature) ~= "boolean" and type(creature) ~= "string") then
      creature = creature["name"]
    else
      creature = ""
    end
  end
  
  if (type(creature) ~= "string") then
    creature = "*"
  end
  if (type(pos) ~= "table") then
    return
  end
  if (type(pos.x) ~= "number" or type(pos.y) ~= "number" or type(pos.z) ~= "number") then
    minetest.log("warning","animals.get_entities_inside_radius: provided position is invalid")
    return
  end
  
  local objs = minetest.get_objects_inside_radius(pos,radius)
  local aobjs = {}
  
  for _,v in pairs(objs) do
    local name = ""
    local obj
    if (type(v) ~= "nil") then
      obj = v:get_luaentity()
    end
    if (type(obj) ~= "nil") then
      name = obj.name
    end
    if (type(name) == "string") then
      -- if match_string is true, then will use string.match() 
      if (name == creature or creature == "*" or (match_string == true and string.match(creature,name))) then
        aobjs[#aobjs + 1] = v
      end
    end
  end
  
  return aobjs
end



-- Animals Interactors Interactions
animals.interactors = {}
function animals.add_interactors(itype,creature,...) -- interactiontype, creature to be set with properties, all possible creatures to add
  -- adds the minetest luaentity names of creatures to a certain interaction type provided by a specified creature
  -- for example, animals.add_interactor("rivals","pegasun","animals:pegasun") would add the entity "animals:pegasun" to the rivals of "pegasun"
  -- lowercase strings for easier finding and indexing
  if (type(itype) ~= "string") then
    return
  else
    itype = string.lower(itype)
  end
  
  if (type(creature) ~= "string") then
    return
  else
    creature = string.lower(creature)
  end
  
  local posscreatures = {...} -- convert specified creatures into an easily accessible table (the ... for multiple args)
  
  local interactable = animals.interactors[creature] -- finds the creature's table provided within animals.interactors
  if (type(interactable) ~= "table") then -- creates new one if not found
    animals.interactors[creature] = {}
    
    interactable = animals.interactors[creature]
  end
  
  local itable = animals.interactors[creature][itype] -- finds the specified interactiontype table within creature's table
  if (type(itable) ~= "table") then -- create new table with the interactiontype if it isn't specified
    animals.interactors[creature][itype] = {}
    
    itable = animals.interactors[creature][itype]
  end
  
  for _,interactor in pairs(posscreatures) do
    if (type(interactor) == "string") then
      -- add said creature as an "interactor" within the provided interactiontype (if specified creature is an entity name)
      itable[#itable + 1] = interactor
    end
  end
  
  return true
end

function animals.get_interactors(creature,itype) -- creature to get stats from, interationtype
  -- get a table of the creatures that interact with the specified creature in the specified interactiontype way
  if (type(itype) ~= "string") then
    return {}
  else
    itype = string.lower(itype)
  end
  
  if (type(creature) ~= "string") then
    return {}
  else
    creature = string.lower(creature)
  end
  -- get the creature's interactors table
  local interactable = animals.interactors[creature]
  if (type(interactable) ~= "table") then
    return {}
  end
  -- get who the creature interacts in what specified way
  local itable = interactable[itype]
  if (type(itable) ~= "table") then
    return {}
  end
  -- return an empty table or the specified table of interaction type
  return itable
end

-------- Mobkit function rewrites

-- makes it so animals do not see or interact with the player (if the animals use this instead of mobkit's) if player is in creative

function animals.get_nearby_player(self,forceplyr)
  -- "forceplyr" bool parameter to force a player despite creative mode
  local plyr = mobkit.get_nearby_player(self) -- get player from mobkit
  if (plyr) then
    -- if player, then check if player is NOT in creative...
    if (not minimal.player_in_creative(plyr) or forceplyr == true) then
      return plyr
    end
  end
end

-- Taken directly from mobkit to properly calculate fall damage
function animals.vitals(self)
	-- vitals: fall damage
	local vel = self.object:get_velocity()
	local velocity_delta = abs(self.lastvelocity.y - vel.y)
  
  if (velocity_delta > mobkit.safe_velocity) then
    -- let's see if there's a node with fall_damage_add_percent first
    local node = mobkit.nodeatpos(mobkit.pos_shift(self.object:get_pos(),{y = -1}))
    
    if (type(node) == "table") then
      local multiplier = node.groups.fall_damage_add_percent -- used for fall damage calculation
      if (type(multiplier) == "number") then
        -- convert multiplier into a usable decimal
        multiplier = multiplier/100
        if (multiplier <= 0) then
          -- if it's negative, make positive, and subtract it by 1 to get the result of which velocity should be of itself (-70 = 0.3)
          multiplier = -multiplier
          multiplier = 1 - multiplier
        else
          multiplier = 1 + multiplier
        end
        
        velocity_delta = floor(velocity_delta * multiplier)
      end
      
      if (node.drawtype == "airlike") then
        -- this ouchy code got initiated in air
        -- sometimes this happens when trampolining and it will hurt the mob by a lot...
        -- so let's pretend they landed on something soft and multiply the velocity_delta by 0.5 :D (because this'll also activate when mobs land on other mobs or players)
        velocity_delta = velocity_delta * 0.5
      end
    end
  end
  
	if velocity_delta > mobkit.safe_velocity then
    -- alright, time to do some damage if it's still over safe_velocity
    local damage = floor(self.max_hp * min(1, velocity_delta/mobkit.terminal_velocity))
    
    self.hp = self.hp - damage
	end
	
	-- vitals: oxygen
	if self.lung_capacity then
		local colbox = self.object:get_properties().collisionbox
		local headnode = mobkit.nodeatpos(mobkit.pos_shift(self.object:get_pos(),{y=colbox[5]})) -- node at hitbox top
		if headnode and headnode.drawtype == 'liquid' then 
			self.oxygen = self.oxygen - self.dtime
		else
			self.oxygen = math_clamp(self.oxygen + (self.dtime * 2),0,self.lung_capacity)
		end
			
		if self.oxygen <= 0 then mobkit.hurt(self,self.max_hp*0.1) end	-- drown by 10% of max_hp
	end
end
