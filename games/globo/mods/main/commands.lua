target=nil

minetest.register_chatcommand("mark", {
    description = "Mark the mob under your cursor as the target",
    params = "",  
    privs = {fly = true},     -- Privileges required to use the command
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local dir = player:get_look_dir()
        local pos = player:get_pos()
		local newpos = {x = pos.x + dir.x, y = pos.y+dir.y, z = pos.z + dir.z}
        

        local entity=nearest(newpos)
		if entity ~= nil then
            target=entity:get_luaentity()
            minetest.chat_send_player(name,"Marking"..target.name)
			return
		end

        minetest.chat_send_player(name,"Nothing found to mark")
    end,
})

function nearest(pos)
    local nearby_objects = minetest.get_objects_inside_radius(pos, 10)
    --minetest.chat_send_all("objs:"..dump(nearby_objects))
    local cobj = nil
    local dist = 64
    for _,obj in ipairs(nearby_objects) do
        local luaent = obj:get_luaentity()
        --minetest.chat_send_all("luaent:"..luaent.name)
        if mobkit.is_alive(obj) and not obj:is_player() and luaent then
            local opos = obj:get_pos()
            local odist = math.abs(opos.x-pos.x) + math.abs(opos.z-pos.z)
            if odist < dist then
                dist=odist
                cobj=obj
            end
        end
    end
    return cobj
end

minetest.register_chatcommand("d", {
    description = "Dump stats of target mob",
    params = "",  
    privs = {fly = true},
    func = function(name, param)
        if target then
            local h=mobkit.recall(target,'hibernate')
            local s=mobkit.recall(target,'sexual')
            local p=mobkit.recall(target,'pregnant')
            local a=mobkit.recall(target,'action')
            --local yaw = target.object:get_yaw()
            minetest.chat_send_player(name,target.name)
            minetest.chat_send_player(name,"HP:"..target.hp)
            minetest.chat_send_player(name,"Energy:"..mobkit.recall(target,'energy'))
            minetest.chat_send_player(name,"Age:"..mobkit.recall(target,'age'))
            if h ~=nil then
                minetest.chat_send_player(name,"Hiber:"..h)
            end
            if s ~= nil then
                minetest.chat_send_player(name,"Sexual:"..dump(s))
            end
            if p ~= nil then
                minetest.chat_send_player(name,"Preg:"..dump(p))
            end
            if a ~= nil then
                minetest.chat_send_player(name,"Action:"..a)
            end
            --minetest.chat_send_player(name,"Yaw:"..yaw)
            --minetest.chat_send_player(name,"HQ:"..dump(target.hqueue))
            --minetest.chat_send_player(name,"LQ:"..dump(target.lqueue))
            minetest.chat_send_player(name,"Pri:"..mobkit.get_queue_priority(target))

        else 
            minetest.chat_send_player(name,"No target set use /mark")
        end
    end,
})


minetest.register_chatcommand("mob", {
    description = "create a mob in front of you",
    params = "<mob name>",  
    privs = {fly = true},
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local dir = player:get_look_dir()
        local pos = player:get_pos()
		local newpos = {x = pos.x + dir.x, y = pos.y+dir.y, z = pos.z + dir.z}
        minimal.log("mob:"..param)
        animals.hatch_egg(newpos, 'air', 'air', "animals:"..param, 2000, 1)
        local entity=nearest(newpos)
		if entity ~= nil then
            target=entity:get_luaentity()
            minetest.chat_send_player(name,"Marking "..target.name)
			return
        else
            minetest.chat_send_player(name,"Failed to create "..param)
        end
    end,
})

minetest.register_chatcommand("max", {
    description = "give you the max stats again",
    params = "<mob name>",  
    privs = {fly = true},
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local meta = player:get_meta()
        meta:set_int("hunger", 1000)
        meta:set_int("thirst", 1000)
        meta:set_int("energy", 1000)
    end,
})

minetest.register_chatcommand("node", {
    description = "give you stats of the node in front of you",
    params = "",  
    privs = {fly = true},
    func = function(name, param)
        -- get the node in front of the player
        local player = minetest.get_player_by_name(name)
        local dir = player:get_look_dir()
        local pos = player:get_pos()

        local newpos = {x = pos.x + dir.x, y = pos.y, z = pos.z + dir.z}
        local node = minetest.get_node(newpos)
        minimal.log("node:"..node.name.." p1:"..dump(node.param1).." p2:"..dump(node.param2))
        local node_def = minetest.registered_nodes[node.name]
        if node_def and node_def.groups then
            for group, value in pairs(node_def.groups) do
        --        minimal.log(group..":"..dump(value))
            end
        else
            minimal.log("no groups")
        end 
    end,
})

minetest.register_chatcommand("pop", {
    description = "Show population of each type of mob",
    params = "<mob type>",  
    privs = {fly = true},
    func = function(name, param)
        -- if <mob type> is set then show the stats for each mob that exists of that type
        minimal.log("pop: "..param)
        local nearby_objects = minetest.get_objects_inside_radius({x=0,y=0,z=0}, 1000)
        if param == "" then    
            local pop = {} 
            for _,obj in ipairs(nearby_objects) do
                local luaent = obj:get_luaentity()
                if mobkit.is_alive(obj) and not obj:is_player() and luaent then
                    local name = luaent.name
                    if pop[name] == nil then
                        pop[name] = 1
                    else
                        pop[name] = pop[name] + 1
                    end
                end
            end
            for k,v in pairs(pop) do
                minimal.log(k..":"..v)
            end
        else
            for _,obj in ipairs(nearby_objects) do
                local luaent = obj:get_luaentity()
                if mobkit.is_alive(obj) and not obj:is_player() and luaent then
                    local name = luaent.name
                    if name == "animals:"..param then  
                        minimal.log(" hp:"..luaent.hp.." energy:"..mobkit.recall(luaent,'energy').." age:"..mobkit.recall(luaent,'age'))
                    end
                end
            end
        end
    end,
})


minetest.register_chatcommand("test", {
    description = "run test functions",
    params = "",  
    privs = {fly = true},
    func = function(name, param)
       tanglerTest()
    end,
})




