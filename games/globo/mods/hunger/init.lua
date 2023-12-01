--[[
Implements the players needing certain nutrients. 
The hunger or thirst will increase till the player eats or drinks
]]--

function damagePlayer(player,amount)
    local new_health = player:get_hp() - amount  

    if new_health < 0 then
        new_health = 0
    end

    player:set_hp(new_health)
end

function addNutrient(player,name,value)
    local meta = player:get_meta()
	local nut=tonumber( meta:get_string(name) )
    print("Nut: " .. nut)
    nut = nut + value
    if nut < 0 then 
        nut = 0
    elseif nut>1000 then
        nut = 1000
    end
	meta:set_string(name, nut)
end

local function updateHUD(player, hunger_level, thirst_level)
    -- Remove existing HUD elements if they exist
    local hud_ids = player:get_meta():get("hud_ids")
    if hud_ids then
        hud_ids = minetest.deserialize(hud_ids)
        if hud_ids.hunger_id then
            player:hud_remove(hud_ids.hunger_id)
        end
        if hud_ids.thirst_id then
            player:hud_remove(hud_ids.thirst_id)
        end
    else
        hud_ids = {}
    end

    -- Add new HUD elements for hunger and thirst
    hud_ids.hunger_id = player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.5, y = 0.8},
        offset = {x = 0, y = 0},
        text = "Hunger: " .. hunger_level,
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 100},
        number = 0xFFFFFF,
    })

    hud_ids.thirst_id = player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.5, y = 0.85},
        offset = {x = 0, y = 0},
        text = "Thirst: " .. thirst_level,
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 100},
        number = 0xFFFFFF,
    })

    -- Save HUD element IDs for later removal
    player:get_meta():set_string("hud_ids", minetest.serialize(hud_ids))
end



minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local health = player:get_hp()
        if health > 0 then
            local player_meta = player:get_meta()
            local h=tonumber( player_meta:get_string("hunger") )
            local t=tonumber(player_meta:get_string("thirst"))
           
            h = h-dtime*STARVE_1_MUL 
            t= t-dtime*STARVE_2_MUL
            if h<0 then
                h=0
                damagePlayer(player,dtime)
            end
            if t<0 then
                t=0
                damagePlayer(player,dtime)
            end

            player_meta:set_string("hunger",h)
            player_meta:set_string("thirst",t)

            updateHUD(player,h,t)
        end
    end
end)


minetest.register_on_joinplayer(function(player)
    local player_meta = player:get_meta()
    local h=player_meta:get_string("hunger")
    local t=player_meta:get_string("thirst")
    if h == "" then
        player_meta:set_string("hunger", 1000)
    end 
    if t == "" then
        player_meta:set_string("thirst", 1000)
    end 
end)

minetest.register_on_respawnplayer(function(player)
    --print("resetting meta values: " .. player:get_player_name())
    local player_meta = player:get_meta()
    player_meta:set_string("hunger",1000)
    player_meta:set_string("thirst",1000)

    local meta2=player:get_meta()
    --print("After reset:" .. meta2:get_string("hunger"))
    return false
end)


--[[

local f=function(self, dtime, moveresult)
    print(dtime)
end


    -- local timer = minetest.get_node_timer(pos)
-- timer:start(10.5)
player:set_properties({hp_max = 5,
--eye_height=4,
on_step=f,})

-- player.on_step = function(self, dtime, moveresult)
--     print(dtime)
-- end

]]--
