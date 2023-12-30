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
    walk_velocity = 2,
    run_velocity = 5, 
    hp_max = 40,
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
    meta:set_string("energy", eCur)
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

    local hunger_level = math.floor(tonumber(meta:get_string("hunger")))
    local thirst_level = math.floor(tonumber(meta:get_string("thirst")))
    local energy_cur = math.floor(tonumber(meta:get_string("energy")))
    local energy_max = math.floor(tonumber(meta:get_string("energy_max")))
    local internal_temp=math.floor(tonumber(meta:get_string("temperature")))
    local score=math.floor(tonumber(meta:get_string("score")))

    local air=1000
    local health=math.floor(tonumber(player:get_hp()))

    local h_rate, r_rate, t_rate, hun_rate, mov, jum, health_after, energy, thirst, hunger, temperature = HEALTH.malus_bonus(player, meta, health, energy_cur, thirst_level, hunger_level, internal_temp)
    energy_cur= energy
    health=health_after
    thirst_level=thirst
    hunger_level=hunger
    internal_temp=temperature


    local sleeping = meta:get_string("sleeping") ~= ""

    local hud_ids = meta:get("hud_ids")
    hud_ids = minetest.deserialize(hud_ids)

    player:hud_change(hud_ids.score, "text", "Score: " .. score)
    player:hud_change(hud_ids.air, "text", "Air: " .. air)
    player:hud_change(hud_ids.health, "text", "Health: " .. health)
    player:hud_change(hud_ids.hunger_id, "text", "Hunger: " .. hunger_level)
    player:hud_change(hud_ids.thirst_id, "text", "Thirst: " .. thirst_level)
    player:hud_change(hud_ids.energy_id, "text", "Energy: " .. energy_cur .. " / " .. energy_max)
    player:hud_change(hud_ids.temp, "text", "Temp: " .. internal_temp .. " / " .. external_temp)
    player:hud_change(hud_ids.status, "text", effectListStr(player))

end

local invTime=os.time()
local function inventoryEffects(player)
    if invTime < os.time() then
        invTime = os.time() + 1
        local inv = player:get_inventory()
  
        for _, stack in ipairs(inv:get_list("main")) do
            if stack:get_name() == "main:ember" then
                player:set_hp(player:get_hp() - 1)
            end
        end
    end
end


minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        if stepPlayerSleep(player,dtime) then
            stepPlayerWalkRun(player)
            checkEggLay(player)
        end
        updateHUD(player)
        inventoryEffects(player)
    end
end)


function initializePlayerMeta(player)
    local meta = player:get_meta()
    if meta:get_string("energy") == "" then
        meta:set_string("energy", 1000)
    end
    if meta:get_string("energy_max") == "" then
        meta:set_string("energy_max", 1000)
    end
    if meta:get_string("hunger") == "" then
        meta:set_string("hunger", 1000)
    end
    if meta:get_string("thirst") == "" then
        meta:set_string("thirst", 1000)
    end
    if meta:get_string("score") == "" then
        meta:set_string("score", 0)
    end
end


minetest.register_on_joinplayer(function(player)
    print("Player joining")

    local privs = minetest.get_player_privs("singleplayer")
    privs.fly = true
    privs.fast = true
    privs.settime = true
    privs.give=true
    minetest.set_player_privs("singleplayer", privs)

    local inv = player:get_inventory()
    inv:set_size("main", INVENTORY_SIZE)  
   --inv:add_item("main", "main:potatoes")

    initializePlayerMeta(player)
    setupHUD(player)

end)


minetest.register_on_respawnplayer(function(player)
    local meta = player:get_meta()
    meta:set_string("energy", 1000)
    meta:set_string("energy_max", 1000)
    meta:set_string("hunger", 1000)
    meta:set_string("thirst", 1000)
    meta:set_string("sleeping","")
    local score=meta:get_string("score") or 0
    score = score - 1
    meta:set_string("score", score)

    return false
end)


function stepPlayerWalkRun(player)
    local ctrl = player:get_player_control()
    if ctrl.aux1 then -- aux1 is often mapped to the 'E' or 'Ctrl' key by default
        player:set_physics_override({
            speed = player_definition.run_velocity
        })
    else
        player:set_physics_override({
            speed = player_definition.walk_velocity
        })
    end
end

function wakeUp(player,msg)
    local meta = player:get_meta()
    if meta:get_string("sleeping")  ~= "" then
        print("Wake up: "..msg)
        meta:set_string("sleeping","")
        minetest.chat_send_player(player:get_player_name(), msg)
        player:set_physics_override({speed = player_definition.walk_velocity})
    end
end

function checkEggLay(player)
    local controls = player:get_player_control()
    if controls.left and controls.right then
        --minimal.log("player trying to lay egg")
        local meta = player:get_meta()
        local energy = tonumber(meta:get_string("energy"))
        local hunger = tonumber(meta:get_string("hunger"))
        if hunger > 500 and energy > 500 then
            local pos = player:get_pos()
            pos.y = pos.y + 0.5
            local node = minetest.get_node(pos)
            if node.name == "air" then
                minetest.add_node(pos, {name = "main:player_egg"})
                minetest.get_meta(pos):set_string("owner", player:get_player_name())
                addNutrient(player,"hunger",-200)
                addNutrient(player,"energy",-500)
            end
        end
    end
end

-- Manage sleeping
-- returns true if not sleeping
function stepPlayerSleep(player,dtime)
    local meta = player:get_meta()

    if meta:get_string("sleeping") ~= "" then
        player:set_physics_override({speed = 0})  -- Player cannot move while sleeping

        local eMax = tonumber(meta:get_string("energy_max"))
        local eCur = tonumber(meta:get_string("energy"))

        -- Increase energy and health while sleeping
        eMax = math.min(eMax + (ENERGY_RECOVERY_RATE_SLEEP * dtime), 1000)
        eCur = math.min(eCur + (ENERGY_RECOVERY_RATE_SLEEP * dtime), eMax) 
        meta:set_string("energy", eCur)
        meta:set_string("energy_max",eMax)
        changePlayerHP(player,HEAL_RATE_SLEEP * dtime)

        local controls = player:get_player_control()
        -- minetest.chat_send_player(player:get_player_name(), dump(controls))
        -- if you move forward or jump, you wake up
        if controls.up or controls.jump then
            wakeUp(player,"You wake up.")
            return true
        end

        -- Wake up if fully rested
        if eCur == 1000 then
            wakeUp(player,"You wake up feeling rested.")
        else 
            return false
        end
        
    else
        local controls = player:get_player_control()
        if controls.sneak then
            print("player going to sleep")
            meta:set_string("sleeping","1")
            player:set_physics_override({speed = 0})  -- Player cannot move while sleeping
            minetest.chat_send_player(player:get_player_name(), "You go to sleep.")
            return false
        end
    end
    return true
end


-- Function to handle when a player is hurt
local function on_player_hpchange(player, hp_change)
    local meta = player:get_meta()
    if hp_change < 0 and meta:get_string("sleeping") ~= "" then
        -- Player hurt while sleeping
        wakeUp(player,"You were hurt and have woken up.")
    end

    return hp_change
end

-- Override Minetest's on_player_hpchange callback
minetest.register_on_player_hpchange(on_player_hpchange)


-- only called when awake
function stepPlayerEnergy(player,dtime)
    local player_meta = player:get_meta()
    local eCur = tonumber(player_meta:get_string("energy"))
    local eMax = tonumber(player_meta:get_string("energy_max"))
    
    local ctrl = player:get_player_control()
    local energy_cost = 0
    
    -- Calculate energy cost based on player's actions
    if ctrl.up or ctrl.left or ctrl.right or ctrl.down then
        energy_cost = ENERGY_WALK_COST * dtime
        if ctrl.aux1 then -- Running
            energy_cost = ENERGY_RUN_COST * dtime
        end
    end
    
    if ctrl.jump then
        energy_cost = ENERGY_JUMP_COST
    end
    
    -- Update current energy
    eMax = eMax-TIRED_RATE*dtime
    eCur = math.min(math.max(eCur - energy_cost, 0),eMax )

    -- Check if the player can still walk or run
    if eCur < 200 then
        if eCur < 3 then
            player:set_physics_override({speed = 0})  -- Player cannot move
        else 
            player:set_physics_override({speed = player_definition.walk_velocity})
        end
    end
    
    -- Recover energy when player is still
    if energy_cost == 0 then
        if eCur < eMax then
            eCur = math.min(eCur + ENERGY_RECOVERY_RATE * dtime, eMax)
        end
        changePlayerHP(player,HEAL_RATE*dtime)
    end
    
    -- Set the energy values
    player_meta:set_string("energy", eCur)
    player_meta:set_string("energy_max", eMax)
    
end





