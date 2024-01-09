--[[
Implements all changes to the players:
 - needing certain nutrients. 
 - The hunger or thirst will increase till the player eats or drinks
]]--



player_definition = {
    physical = true,
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
    visual = "mesh",
    visual_size = {x=1, y=1},
    mesh = "character.b3d",
    textures = {"character.png"},
    makes_footstep_sound = true,
    view_range = 10,
    walk_velocity = 1,
    run_velocity = 1.6, 
    hp_max = PLAYER_MAX_HEALTH,
}

minetest.register_entity("main:player", player_definition)

function changePlayerEnergy(player,amount)
    local meta = player:get_meta()
    local eCur = tonumber(meta:get_string("energy"))
    local eMax = tonumber(meta:get_string("energy_max"))
    eCur = eCur + amount
    if eCur < 0 then
        eCur = 0
    elseif eCur > eMax then
        eCur = eMax
    end
    meta:set_float("energy", eCur)
end


function changePlayerHP(player,amount)
    local new_health = player:get_hp() + amount  

    if new_health < 0 then
        new_health = 0
    end

    -- if new_health > player:get_properties().hp_max

    player:set_hp(new_health)
end

function addNutrient(player,name,value)
    local meta = player:get_meta()
	local nut=meta:get_float(name)
    nut = nut + value
    if nut < 0 then 
        nut = 0
    elseif nut>1000 then
        nut = 1000
    end
	meta:set_float(name, nut)
end

function setupHUD(player)
    -- Remove existing HUD elements if they exist
    player:hud_set_flags({healthbar = false})

    local meta = player:get_meta()
    local hud_ids = meta:get("hud_ids")
    if hud_ids then
        hud_ids = minetest.deserialize(hud_ids)
        for _, id in pairs(hud_ids) do
            player:hud_remove(id)
        end
    else
        hud_ids = {}
    end

    local startPos = {x = 0, y = 1} 
    hud_ids.score = player:hud_add({
        hud_elem_type = "text",
        text = "",
        number = 0xFFFFFF,
        position = startPos,
        offset = {x = 10, y = -160},
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
    })

    hud_ids.air = player:hud_add({
        hud_elem_type = "text",
        text = "Air: ",
        number = 0xFFFFFF,
        position = startPos,
        offset = {x = 10, y = -140},
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
    })

    hud_ids.health = player:hud_add({
        hud_elem_type = "text",
        text = "Health: ",
        number = 0xFFFFFF,
        position = startPos,
        offset = {x = 10, y = -120},
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
    })

    hud_ids.hunger_id = player:hud_add({
        hud_elem_type = "text",
        position = startPos,
        offset = {x = 10, y = -100},
        text = "Hunger: ",
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
        number = 0xFFFFFF,
    })

    hud_ids.thirst_id = player:hud_add({
        hud_elem_type = "text",
        position = startPos,
        offset = {x = 10, y = -80},
        text = "Thirst: ",
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
        number = 0xFFFFFF,
    })

    hud_ids.energy_id = player:hud_add({
        hud_elem_type = "text",
        text = "Energy: ",
        number = 0xFFFFFF,
        position = startPos,
        offset = {x = 10, y = -60},
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
    })

    hud_ids.temp = player:hud_add({
        hud_elem_type = "text",
        text = "Temp: ",
        number = 0xFFFFFF,
        position = startPos,
        offset = {x = 10, y = -40},
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
    })

    hud_ids.status = player:hud_add({
        hud_elem_type = "text",
        text = "",
        number = 0xFFFFFF,
        position = startPos,
        offset = {x = 10, y = -20},
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
    })
    

    player:get_meta():set_string("hud_ids", minetest.serialize(hud_ids))
end

local function updateHUD(player)
    local meta = player:get_meta()
    local player_pos = player:get_pos()
	player_pos.y = player_pos.y + 0.6 --adjust to body height
	local external_temp = math.floor(climate.get_point_temp(player_pos, true))

    local hunger_level = meta:get_int("hunger")
    local thirst_level = meta:get_int("thirst")
    local energy_cur = meta:get_int("energy")
    local energy_max = meta:get_int("energy_max")
    local internal_temp=meta:get_int("temperature")
    local score=meta:get_int("score")
    local hun_rate=meta:get_int("hunger_rate")
    local t_rate=meta:get_int("thirst_rate")
    local r_rate=meta:get_int("recovery_rate")
    local h_rate=meta:get_int("heal_rate")

    local air=1000
    local health=player:get_hp()

    local hud_ids = meta:get("hud_ids")
    hud_ids = minetest.deserialize(hud_ids)

    player:hud_change(hud_ids.score, "text", "Score: " .. score)
    player:hud_change(hud_ids.air, "text", "Air: " .. air)
    player:hud_change(hud_ids.health, "text", "Health: " .. health.."+"..h_rate)
    player:hud_change(hud_ids.hunger_id, "text", "Hunger: " .. hunger_level.."-"..-hun_rate)
    player:hud_change(hud_ids.thirst_id, "text", "Thirst: " .. thirst_level.."-"..-t_rate)
    player:hud_change(hud_ids.energy_id, "text", "Energy: " .. energy_cur .. " / " .. energy_max.."+"..r_rate)
    player:hud_change(hud_ids.temp, "text", "Temp: " .. internal_temp .. " / " .. external_temp)
    player:hud_change(hud_ids.status, "text", effectListStr(player))

end

local invTime=os.time()
local function inventoryEffects(player)
    if invTime < os.time() then
        invTime = os.time() + 1
        local inv = player:get_inventory()
  
        for _, stack in ipairs(inv:get_list("main")) do
            local name = stack:get_name()
            if name == "main:ember" then
                changePlayerHP(player,-50)
            end
            if name == "main:pulse_blossom" or name=="main:pusle_blossom_on" then
                changePlayerHP(player,-50)
            end
            if (name == "main:sun_berry" or name=="main:moon_berry") and math.random()<0.001 then
                -- delete the item
                inv:remove_item("main", name)
            end
        end
    end
end


minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
       
        local meta = player:get_meta()
        local timePlayed=meta:get_float("time")+dtime
        meta:set_float("time",timePlayed)
        if timePlayed > GAME_LENGTH then
            minimal.log("******************************************")
            minimal.log("Game over man! Game over!")
            minimal.log("Score: "..score)
            minimal.log("******************************************")
            meta:set_float("time",0)
        end
        
        if stepPlayerSleep(player,dtime) then
            stepPlayerWalkRun(player)
        end
        updateHUD(player)
        inventoryEffects(player)
    end
end)


function initializePlayer(player)
    local meta = player:get_meta()
    if meta:get_int("joined") ==0 then
        meta:set_int("joined",1)
        meta:set_float("time",0)

        player:set_properties({hp_max = PLAYER_MAX_HEALTH})
        player:set_hp(PLAYER_MAX_HEALTH)
        meta:set_int("energy", 1000)
        meta:set_int("energy_max", 1000)
        meta:set_int("hunger", 1000)
        meta:set_int("thirst", 1000)
        meta:set_int("score", 0)
    end
end


minetest.register_on_joinplayer(function(player)
    print("Player joining")
    player:set_properties({hp_max = PLAYER_MAX_HEALTH})

    local privs = minetest.get_player_privs("singleplayer")
    privs.fly = true
    privs.fast = true
    privs.settime = true
    privs.give=true
    privs.set_weather=true
    minetest.set_player_privs("singleplayer", privs)

    local inv = player:get_inventory()
    inv:set_size("main", INVENTORY_SIZE)  
    
   --inv:add_item("main", "main:potatoes")

    initializePlayer(player)
    setupHUD(player)
end)


minetest.register_on_respawnplayer(function(player)
    local meta = player:get_meta()
    meta:set_int("energy", 1000)
    meta:set_int("energy_max", 1000)
    meta:set_int("hunger", 1000)
    meta:set_int("thirst", 1000)
    meta:set_int("sleeping",0)
    local score=meta:get_int("score") or 0
    score = score - 6
    meta:set_int("score", score)

    -- get rid of past inventory
    local inv = player:get_inventory()
    inv:set_size("main", INVENTORY_SIZE)
    inv:set_list("main", {})


    player:set_properties({hp_max = PLAYER_MAX_HEALTH})
    player:set_hp(PLAYER_MAX_HEALTH)

    return false
end)

function stepPlayerWalkRun(player)
    local ctrl = player:get_player_control()
    if ctrl.aux1 then -- aux1 is often mapped to the 'E' or 'Ctrl' key by default
        player_monoids.speed:add_change(player, player_definition.run_velocity, "main")
    else
        player_monoids.speed:add_change(player, player_definition.walk_velocity, "main")
    end
end

function wakeUp(player,msg)
    local meta = player:get_meta()
    if meta:get_int("sleeping")  == 1 then
        meta:set_int("sleeping",0)
        minetest.log(msg)
        player:set_physics_override({speed = player_definition.walk_velocity})
    end
end

function playerStartSleep(player)
    -- make sure the player isn't in water
    local pos = player:get_pos()
    pos.y = pos.y + 0.5
    local node = minetest.get_node(pos)
    if node.name ~= "air" then
        minetest.chat_send_player(player:get_player_name(), "You cannot sleep here.")
        return
    end

    local meta = player:get_meta()
    meta:set_int("sleeping",1)
    player:set_physics_override({speed = 0})  -- Player cannot move while sleeping
    minetest.log("You go to sleep.")
end

function playerLayEgg(player)
    --minimal.log("player trying to lay egg")
    local meta = player:get_meta()
    local energy = meta:get_int("energy")
    local hunger = meta:get_int("hunger")
    if hunger > 500 and energy > 500 then
        local pos = player:get_pos()
        pos.y = pos.y + 0.5
        local node = minetest.get_node(pos)
        if node.name == "air" then
            minetest.add_node(pos, {name = "main:player_egg"})
            minetest.get_meta(pos):set_string("owner", player:get_player_name())
            addNutrient(player,"hunger",-100)
            changePlayerEnergy(player,-500)
        end
    end
end

-- Manage sleeping
-- returns true if not sleeping
function stepPlayerSleep(player,dtime)
    local meta = player:get_meta()

    if meta:get_int("sleeping") == 1 then
        --player:set_physics_override({speed = 0})  -- Player cannot move while sleeping
--[[
        local eMax = meta:get_float("energy_max")
        local eCur = meta:get_float("energy")

        -- Increase energy and health while sleeping
        eMax = math.min(eMax + (ENERGY_RECOVERY_RATE_SLEEP * dtime), 1000)
        eCur = math.min(eCur + (ENERGY_RECOVERY_RATE_SLEEP * dtime), eMax) 
        meta:set_float("energy", eCur)
        meta:set_float("energy_max",eMax)
        changePlayerHP(player,HEAL_RATE_SLEEP * dtime)
]]--
        local controls = player:get_player_control()
        -- minetest.chat_send_player(player:get_player_name(), dump(controls))
        -- if you move forward or jump, you wake up
        if controls.up or controls.jump then
            wakeUp(player,"You wake up.")
            return true
        end

        local pos = player:get_pos()
        pos.y = pos.y + 0.5
        local node = minetest.get_node(pos)
        if node.name ~= "air" then
            wakeUp(player,"You can't sleep here.")
            return true
        end

        local eCur = meta:get_float("energy")
        -- Wake up if fully rested
        if eCur == 1000 then
            wakeUp(player,"You wake up feeling rested.")
        else 
            return false
        end
    end
    return true
end


-- Function to handle when a player is hurt
local function on_player_hpchange(player, hp_change, reason)
    local properties = player:get_properties()
    local max_hp = properties.hp_max
    minimal.log("Player hurt: " .. hp_change .. " reason: " .. reason.type.." max: "..max_hp)
    if reason.type == "fall" then
       hp_change = hp_change * 50
    end

    local meta = player:get_meta()
    if hp_change < 0 and meta:get_int("sleeping")==1 then
        -- Player hurt while sleeping
        wakeUp(player,"You were hurt and have woken up.")
    end
    return hp_change
end

-- Override Minetest's on_player_hpchange callback
minetest.register_on_player_hpchange(on_player_hpchange,true)
