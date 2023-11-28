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


minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local health = player:get_hp()
        if health > 0 then
            local player_meta = player:get_meta()
            local h=tonumber( player_meta:get_string("hunger") )
            local t=tonumber(player_meta:get_string("thirst"))
           
        --ensureNutrient(player,"thirst")
            h = h-dtime*20
            t= t-dtime*30
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
