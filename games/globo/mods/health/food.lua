--food.lua
--handles the intake of food and drink

--Modding info:
--[[
 To add new foods, define your node(s), then pass a table with food info to
exile_add_food(table). Its on_use will be set automatically.
 Make sure all your nodes have been defined BEFORE you send any tables!
 exile_add_food() will override a node's on_use.

 For cookable things, define the node, and a name_cooked/name_burned version,
then pass the cooking data to exile_add_bake(table). Don't forget to add the
cooked version to the food table.
 If the burned version is not also added to foods, it will be inedible.
 exile_add_bake() will override a node's on_construct and on_timer.

 If a food can only be cooked in a pot, don't define a name_cooked node,
but add it to the food table anyway. The cooking pot will make a soup using
the food table's data, but the food will not be able to bake in an oven or
over a fire.
#TODO: Test this ^^ after the cooking pot supports both tables
]]--

-- Internationalization
local S = HEALTH.S

dofile(minetest.get_modpath('health')..'/data_food.lua')

-- Declare globals
food_harm_table = food_harm_table
food_table = food_table
bake_table = bake_table

local function do_food_harm(user, nodename)
   if not food_harm_table[nodename] then return end
   local fht = food_harm_table[nodename]
   for i = 1, #fht do
      if math.random() < fht[i][2] then
	 HEALTH.add_new_effect(user, {fht[i][1], fht[i][3]})
      end
   end
end

local __eat_click_settings_cache = {}
minetest.register_chatcommand("eat2x", {
        params = "true | false",
        description = "Toggles double-click to eat",
        func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local meta = player:get_meta()
        local eat2x=meta:get_string("conf_eat2x") or minetest.settings:get("exile_eat_doubleclick") or "false"
        if param and param ~="" then
                local wlist = "/eat2x:\n"..
                "Toggle double-click to eat"
                return false, wlist
        end
        if eat2x == "true" then
                eat2x = "false"
        else
                eat2x = "true"
        end

        meta:set_string("conf_eat2x", eat2x)
	minetest.chat_send_player(name,"Double-Click to eat: "..eat2x)
	if eat2x == 'true' then
		eat2x = true
	else
		eat2x = false
	end
	__eat_click_settings_cache[name] = not eat2x
        end,
})

function eat_ok (itemstack, user, pointed_thing)
	local pt_pos = minetest.get_pointed_thing_position(pointed_thing)
	local pname = user:get_player_name()
	local single_click = __eat_click_settings_cache
	if single_click[pname] == nil then
		local pmeta = user:get_meta()
		local eat2x = pmeta:get_string("conf_eat2x") or minetest.settings:get('exile_eat_doubleclick') or 'false'
		if eat2x == 'true' then
			eat2x = true
		else
			eat2x = false
		end
		single_click[pname] = not eat2x
	end
	if ( single_click[pname] ) or minimal.click_count_ready(pname,
								"eat2x",
								pt_pos,
								2, 2) then
		return true
	else
	minetest.chat_send_player(pname, S("double click to eat"))
	end
end

function exile_eatdrink_playermade(itemstack, user, pointed_thing)
   local imeta = itemstack:get_meta()
   local pname = user:get_player_name()
   local t = minetest.deserialize(imeta:get_string("eat_value"))
   if t == nil then minetest.log("warning", pname..
				    " ate an invalid food of type "..
				    itemstack:get_name())
      return
   end
   if eat_ok(itemstack, user, pointed_thing) then
	  return HEALTH.use_item(itemstack, user, t[1], t[2], t[3], t[4], t[5], t[6])
   end
end

function exile_eatdrink(itemstack, user, pointed_thing)
   local name = itemstack:get_name()

   if minetest.registered_aliases[name] then
      name = minetest.registered_aliases[name]
   end
   if not food_table[name] then
      minetest.chat_send_player(user:get_player_name(),
				S("This is inedible."))
      return
   end
   if eat_ok(itemstack, user, pointed_thing) then
	   do_food_harm(user, name)
	   local t = food_table[name]
	   return HEALTH.use_item(itemstack, user, t[1], t[2], t[3], t[4], t[5], t[6])
   else
      return
   end
end


-- Overrides for edible and bakable nodes
local eat_redef = {
   on_use = function(itemstack, user, pointed_thing)
		return exile_eatdrink(itemstack, user, pointed_thing)
end}

local function bake_error(pos, selfname)
   local posstr = minetest.pos_to_string(pos)
   minetest.log("error", "Warning, attempting to use a bake timer at "..
		"pos: "..posstr..", set on a non-bakeable node:"..selfname)
end

local bake_redef = {
   on_construct = function(pos)
      local selfname = minetest.get_node(pos).name
      selfname = selfname:gsub("_cooked","") -- ensure we have the base name
      if bake_table[selfname] == nil then
	 bake_error(pos, selfname)
	 return true
      end
      ncrafting.start_bake(pos, bake_table[selfname][2])
   end,
   on_timer = function(pos, elapsed)
      local selfname = minetest.get_node(pos).name
      selfname = selfname:gsub("_cooked","") -- ensure we have the base name
      if bake_table[selfname] == nil then
	 bake_error(pos, selfname)
	 return true
      end
      return ncrafting.do_bake(pos, elapsed,
			       bake_table[selfname][1],
			       bake_table[selfname][2])
end}

function exile_add_food(table)
   --Add new foods, mod must send a table in the food_data.lua format
   for k, v in pairs(table) do
      food_table[k] = v
      if minetest.registered_nodes[k] then
	 minetest.override_item(k, eat_redef)
      end
   end
end
function exile_add_bake(table)
   --Add new bakables, mod must send a table in the food_data.lua format
   for k, v in pairs(table) do
      bake_table[k] = v
      if minetest.registered_nodes[k] then
	 minetest.override_item(k, bake_redef)
      end
   end
end
function exile_add_harm(table)
   --Add new food harm, mod must send a table in the food_data.lua format
   for k, v in pairs(table) do
      food_harm_table[k] = v
   end
end

function exile_add_food_hooks(name)
   if (minetest.get_item_group(name,'edible') > 0) or food_table[name] then
      minetest.override_item(name, eat_redef)
   end
   if bake_table[name] then
      minetest.override_item(name, bake_redef)
   end
   if string.match(name, "_cooked") then
	 minetest.override_item(name, bake_redef)
   end
end

-- Add food hooks to all nodes in edible group
minetest.register_on_mods_loaded(function()
	for name,_ in pairs(minetest.registered_nodes) do
		if minetest.get_item_group(name,'edible') > 0 then
			exile_add_food_hooks(name)
		end
	end
end)

-- Finalized table list
--Outputs a compilned list of all added foods to the minetest log, info level
minetest.after(1, function()
   minetest.log("info", "Finalized list of food_table entries:")
   for k, v in pairs(food_table) do
      if minetest.registered_nodes[k] then
	 minetest.log("info",k)
      end
   end
   minetest.log("info","-------")
   minetest.log("info", "Finalized list of bake_table entries:")
   for k, v in pairs(bake_table) do
      if not minetest.registered_nodes[k] then
	 minetest.log("info", "Bake table contains an undefined node: "..k)
      else
	 if minetest.registered_nodes[k.."_cooked"] then
	    minetest.log("info",k)
	 else
	    minetest.log("info", "undefined node (cooking pot only entry): "..
			    k.."_cooked")
	 end
      end
   end
   minetest.log("info","-------")
end)
