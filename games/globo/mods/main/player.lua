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

local function updateHUD(player)
    -- Remove existing HUD elements if they exist
    local meta = player:get_meta()
    local hud_ids = meta:get("hud_ids")
    if hud_ids then
        hud_ids = minetest.deserialize(hud_ids)
        if hud_ids.hunger_id then
            player:hud_remove(hud_ids.hunger_id)
        end

        if hud_ids.thirst_id then
            player:hud_remove(hud_ids.thirst_id)
        end

        if hud_ids.energy_id then
            player:hud_remove(hud_ids.energy_id)
        end
    else
        hud_ids = {}
    end

    local hunger_level = math.floor(tonumber(meta:get_string("hunger")))
    local thirst_level = math.floor(tonumber(meta:get_string("thirst")))
    local energy_cur = math.floor(tonumber(meta:get_string("energy_cur")))
    local energy_max = math.floor(tonumber(meta:get_string("energy_max")))

    -- Add new HUD elements
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

    hud_ids.energy_id = player:hud_add({
        hud_elem_type = "text",
        text = "Energy: " .. energy_cur .. " / " .. energy_max,
        number = 0xFFFFFF,
        position = {x = 0.5, y = 0.9},
        offset = {x = 0, y = 0},
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 100},
    })

    -- Save HUD element IDs for later removal
    player:get_meta():set_string("hud_ids", minetest.serialize(hud_ids))
end




minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        stepPlayerWalkRun(player)
        stepPlayerEnergy(player,dtime)
        stepPlayerSleep(player,dtime)
        stepPlayerHunger(player,dtime)
        updateHUD(player)
    end
end)

function stepPlayerHunger(player,dtime)
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
    end
end

function initializePlayerMeta(player)
    local meta = player:get_meta()
    if meta:get_string("energy_cur") == "" then
        meta:set_string("energy_cur", 1000)
    end
    if meta:get_string("energy_max") == "" then
        meta:set_string("energy_max", 1000)
    end
    if meta:get_string("hunger") == "" then
        meta:set_string("hunger", 1000)
    end
    if meta:get_string("thrist") == "" then
        meta:set_string("thrist", 1000)
    end
    if meta:get_string("temp") == "" then
        meta:set_string("temp", START_TEMPERATURE)
    end
end


minetest.register_on_joinplayer(function(player)
    print("Player joining")

    local inv = player:get_inventory()
    if inv then
        inv:set_size("main", INVENTORY_SIZE)  -- Set inventory size to INVENTORY_SIZE
    end

    initializePlayerMeta(player)

end)


minetest.register_on_respawnplayer(function(player)
    meta:set_string("energy_cur", 1000)
    meta:set_string("energy_max", 1000)
    meta:set_string("hunger", 1000)
    meta:set_string("thrist", 1000)
    meta:set_string("temp", START_TEMPERATURE)
    return false
end)

-- Global variable to keep track of sleeping players
local sleeping_players = {}



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

     -- Manage sleeping
function stepPlayerSleep(player,dtime)
    
    local player_name = player:get_player_name()
    if sleeping_players[player_name] then
        local player_meta = player:get_meta()
        local e_max = tonumber(player_meta:get_string("energy_max") or ENERGY_MAX_START)
        local e_cur = tonumber(player_meta:get_string("energy_cur") or 0)
        local hp = player:get_hp()
        local hp_max = player:get_properties().hp_max

        -- Increase energy and health while sleeping
        e_cur = math.min(e_cur + (ENERGY_RECOVERY_RATE * 2 * dtime), e_max)  -- Increased recovery rate
        player_meta:set_string("energy_cur", e_cur)
        player:set_hp(math.min(hp + (hp_max / e_max) * (ENERGY_RECOVERY_RATE * 2 * dtime), hp_max))

        -- Wake up if fully rested or hurt
        if e_cur >= e_max then
            sleeping_players[player_name] = nil
            player:set_physics_override({speed = player_definition.walk_velocity})
            minetest.chat_send_player(player_name, "You wake up feeling rested.")
        end
    else
        local controls = player:get_player_control()
        if controls.sneak then
            print("player going to sleep")
            sleeping_players[player_name] = true
            player:set_physics_override({speed = 0})  -- Player cannot move while sleeping
            minetest.chat_send_player(player_name, "You go to sleep.")
        end
    end
end


-- Function to handle when a player is hurt
local function on_player_hpchange(player, hp_change)
    local player_name = player:get_player_name()
    if hp_change < 0 and sleeping_players[player_name] then
        -- Player hurt while sleeping
        sleeping_players[player_name] = nil
        player:set_physics_override({speed = player_definition.walk_velocity})
        minetest.chat_send_player(player_name, "You were hurt and have woken up.")
    end

    return hp_change
end

-- Override Minetest's on_player_hpchange callback
minetest.register_on_player_hpchange(on_player_hpchange)



function stepPlayerEnergy(player,dtime)
    local player_meta = player:get_meta()
    local e_cur = tonumber(player_meta:get_string("energy_cur") or ENERGY_MAX_START)
    local e_max = tonumber(player_meta:get_string("energy_max") or ENERGY_MAX_START)
    
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
    e_cur = math.max(e_cur - energy_cost, 0)
    
    -- Check if the player can still walk or run
    if e_cur <= 0 then
        if not player:get_meta():get_string("exhausted") then
            player:set_physics_override({speed = 0})  -- Player cannot move
            player_meta:set_string("exhausted", "true")
        end
    elseif e_cur > 200 then
        if player:get_meta():get_string("exhausted") == "true" then
            player:set_physics_override({speed = player_definition.walk_velocity})
            player_meta:set_string("exhausted", nil)
        end
    end
    
    -- Recover energy when player is still
    if energy_cost == 0 and e_cur < e_max then
        e_cur = math.min(e_cur + ENERGY_RECOVERY_RATE * dtime, e_max)
    end
    
    -- Set the energy values
    player_meta:set_string("energy_cur", e_cur)
    player_meta:set_string("energy_max", e_max)
    
end





