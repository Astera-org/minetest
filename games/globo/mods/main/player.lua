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
--[[  doesn't work 
    hud_ids.debug = player:hud_add({
        hud_elem_type = "text",
        text = " ",
        number = 0xFFFFFF,
        position = {x = 0.05, y = 0.65},
        offset = {x = 0, y = 0},
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
    })
]]--
    local startPos = {x = 0.05, y = 0.75} 
    hud_ids.air = player:hud_add({
        hud_elem_type = "text",
        text = "Air: ",
        number = 0xFFFFFF,
        position = startPos,
        offset = {x = 0, y = 0},
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
    })

    hud_ids.health = player:hud_add({
        hud_elem_type = "text",
        text = "Health: ",
        number = 0xFFFFFF,
        position = startPos,
        offset = {x = 0, y = 20},
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
    })

    hud_ids.hunger_id = player:hud_add({
        hud_elem_type = "text",
        position = startPos,
        offset = {x = 0, y = 40},
        text = "Hunger: ",
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
        number = 0xFFFFFF,
    })

    hud_ids.thirst_id = player:hud_add({
        hud_elem_type = "text",
        position = startPos,
        offset = {x = 0, y = 60},
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
        offset = {x = 0, y = 80},
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
    })

    hud_ids.temp = player:hud_add({
        hud_elem_type = "text",
        text = "Temp: ",
        number = 0xFFFFFF,
        position = startPos,
        offset = {x = 0, y = 100},
        alignment = {x = 1, y = 0},
        scale = {x = 100, y = 100},
    })

    hud_ids.status = player:hud_add({
        hud_elem_type = "text",
        text = "",
        number = 0xFFFFFF,
        position = startPos,
        offset = {x = 0, y = 120},
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

    player:hud_change(hud_ids.air, "text", "Air: " .. air)
    player:hud_change(hud_ids.health, "text", "Health: " .. health)
    player:hud_change(hud_ids.hunger_id, "text", "Hunger: " .. hunger_level)
    player:hud_change(hud_ids.thirst_id, "text", "Thirst: " .. thirst_level)
    player:hud_change(hud_ids.energy_id, "text", "Energy: " .. energy_cur .. " / " .. energy_max)
    player:hud_change(hud_ids.temp, "text", "Temp: " .. internal_temp .. " / " .. external_temp)
    player:hud_change(hud_ids.status, "text", effectListStr(player))

    --[[ debug HUD
   
    local pointed_thing = player:get_pointed_thing()
    if pointed_thing.type == "node" then
        local pos = pointed_thing.under
        local node = minetest.get_node(pos)
        local node_name = node.name

        player:hud_change(hud_ids.debug, "text", node_name .. "(" .. node.param1 .. "," .. node.param2 .. ") pos:" .. minetest.pos_to_string(pos))
    else
        player:hud_change(hud_ids.debug, "text", "")
    end
    ]]--
end




minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        if stepPlayerSleep(player,dtime) then
            stepPlayerWalkRun(player)
            -- stepPlayerEnergy(player,dtime)
        end
        -- stepPlayerHunger(player,dtime)
        updateHUD(player)
    end
end)

function stepPlayerHunger(player,dtime)
    local health = player:get_hp()
    if health > 0 then
        local meta = player:get_meta()
        local h=tonumber( meta:get_string("hunger") )
        local t=tonumber(meta:get_string("thirst"))
        local coe=1
        if meta:get_string("sleeping")  ~= "" then
            coe=SLEEP_STARVE_COE
        end
        h = h-dtime*STARVE_1_MUL*coe
        t= t-dtime*STARVE_2_MUL*coe
        if h<200 then
            wakeUp(player,"So Hungry")
            if h<0 then
                h=0
                changePlayerHP(player,-dtime*PLAYER_STARVE_RATE)
            end
        end

        if t<200 then
            wakeUp(player,"So Thirsty")
            if t<0 then
                t=0
                changePlayerHP(player,-dtime*PLAYER_DEHYDRATION_RATE)
            end
        end

        meta:set_string("hunger",h)
        meta:set_string("thirst",t)
    end
end

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
    if meta:get_string("temperature") == "" then
        meta:set_string("temperature", START_TEMPERATURE)
    end
end


minetest.register_on_joinplayer(function(player)
    print("Player joining")

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
    meta:set_string("temperature", START_TEMPERATURE)
    meta:set_string("sleeping","")

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





