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
        animals.hatch_egg(newpos, 'air', 'air', "animals:"..param, 4000, 1)
        local entity=nearest(newpos)
		if entity ~= nil then
            target=entity:get_luaentity()
            minetest.chat_send_player(name,"Marking"..target.name)
			return
        else
            minetest.chat_send_player(name,"Failed to create "..param)
        end
    end,
})


