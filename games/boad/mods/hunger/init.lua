--[[
Implements the players needing certain nutrients. 
The hunger or thirst will increase till the player eats or drinks
]]--

function damagePlayer(player,amount)
   
    local current_health = player:get_hp()  -- Get the current health
    local new_health = current_health - amount  -- Calculate new health

    -- Ensure new health is not less than zero
    if new_health < 0 then
        new_health = 0
        --print("should die")
    end

    player:set_hp(new_health)
end


minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        -- Your code here. For example, you can check the player's position
        -- or health and perform some action.
        -- print(dtime)
        local health = player:get_hp()
        if health > 0
            local player_meta = player:get_meta()
            local hstr=player_meta:get_string("hunger")
            print("Global" .. hstr)
            local h=tonumber( hstr )
            local t=tonumber(player_meta:get_string("thirst"))
            print(h .. " " .. t)
        --ensureNutrient(player,"thirst")
            h = h-dtime*20
            t= t-dtime*30
            print(h .. " " .. t)
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

minetest.register_on_dieplayer(function(player)
    print("resetting meta values")
    local player_meta = player:get_meta()
    player_meta:set_string("hunger",1000)
    player_meta:set_string("thirst",1000)

    local meta2=player:get_meta()
    print("After reset:" .. meta2:get_string("hunger"))
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
