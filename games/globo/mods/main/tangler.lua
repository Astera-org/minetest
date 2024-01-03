
--[[
    starting from this position we want the vies to roll out along the ground. 

    directions: north east south west
]]

local function isValidVineSpot(pos)
    local node=minetest.get_node(pos)
    if node.name=="main:conveyor" then return false end

    -- Check if this node is air or flora
    if node.name == "air" or minetest.get_item_group(node.name, "flora") > 0 then
        -- Check the node below
        local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
        local below_node = minetest.get_node(below_pos)
        local below_node_def = minetest.registered_nodes[below_node.name]
        -- If the node below is walkable, return true
        if below_node_def and below_node_def.walkable then
            return true
        end
    end
    return false
end


-- destroy flora to place vine
-- make sure there is not already a vine here
local function findVineSpot(pos)
    local startY=pos.y
    for y=-1,1 do
        pos.y=startY+y
        if isValidVineSpot(pos) then return true end
    end
    return false
end

local function getPosInDir(dir,pos)
    if dir==1 then pos.z=pos.z+1 
    elseif dir==2 then pos.x=pos.x+1
    elseif dir==3 then pos.z=pos.z-1
    elseif dir==4 then pos.x=pos.x-1 end
end

local function isVineInSpace(pos)
    local p=shallowCopy(pos)
    for y=-1,1 do
        local node=minetest.get_node(p)
        if node.name=="main:conveyor" then return true end
    end
    return false
end

local function countNearVines(pos)
    local p=shallowCopy(pos)
    local ret=0
    p.x=pos.x+1
    if isVineInSpace(pos) then ret =ret+1 end
    p.x=pos.x-1
    if isVineInSpace(pos) then ret =ret+1 end
    p.x=pos.x
    p.z=pos.z+1
    if isVineInSpace(pos) then ret =ret+1 end
    p.z=pos.z-1
    if isVineInSpace(pos) then ret =ret+1 end

    return ret
end


local function leftVine(dir,pos,length)
    dir=dir-1
    if dir==0 then dir=4 end
    local newPos=shallowCopy(pos)
    getPosInDir(dir,newPos)
    local count=countNearVines(newPos)
    if math.random(1,4) < count then return end
    if math.random(1,4) < count then return end
    growVine(dir,newPos,length+1)
end

local function rightVine(dir,pos,length)
    dir=dir+1
    if dir==5 then dir=1 end
    local newPos=shallowCopy(pos)
    getPosInDir(dir,newPos)
    local count=countNearVines(newPos)
    if math.random(1,4) < count then return end
    if math.random(1,4) < count then return end
    growVine(dir,newPos,length+1)
end

local function straightVine(dir,pos,length)
    local newPos=shallowCopy(pos)
    getPosInDir(dir,newPos)
    local count=countNearVines(newPos)
    if math.random(1,4) < count then return end
    if math.random(1,4) < count then return end
    growVine(dir,newPos,length+1)
end

-- get the node in that direction
-- if no node stop
-- place new vine
-- determine next directions if any
function growVine(dir,pos,length)
    local newPos=shallowCopy(pos)
    if findVineSpot(newPos) then
        minetest.set_node(newPos, {name = "main:conveyor"})
        if length > 40 then return end -- cap vine length
        local r=math.random(1,1000)
        r = r- length*4
        
        if r < 10 then
            leftVine(dir,newPos,length)
            straightVine(dir,newPos,length)
            rightVine(dir,newPos,length)    -- 0 to 10
        elseif r<40 then
            leftVine(dir,newPos,length)
            straightVine(dir,newPos,length)  -- 10 to 40
        elseif r<70 then
            straightVine(dir,newPos,length)
            rightVine(dir,newPos,length)  -- 40 to 70
        elseif r<220 then
            rightVine(dir,newPos,length)  -- 70 to 220
        elseif r<370 then
            leftVine(dir,newPos,length)  -- 220 to 370
        else straightVine(dir,newPos,length) end
    end
end

local function startVine(dir,pos)
    -- find a starting location
    -- call growVine
end

minetest.register_node("main:tangler_heart", {
    tiles = {
        "nodes_nature_sasaran_log_top.png",
        "nodes_nature_sasaran_log_top.png",
        "nodes_nature_sasaran_log.png"
    },

    groups = {log = 1, choppy = 3, flammable = 25},

    on_timer = function(pos, elapsed)
      --minimal.log("main:tangler on_timer")
       -- cause damage to any creature around
		local objects = minetest.get_objects_inside_radius(pos, 10)
		for _, obj in ipairs(objects) do
			if obj:is_player() then
				--minetest.chat_send_player(obj:get_player_name(), "You have been damaged by a tangler")
				changePlayerHP(obj, -1)
			elseif obj:get_luaentity() ~= nil then
				local mob = obj:get_luaentity()
				mobkit.hurt(mob,1)
			end
		end
        return true -- Continue the cycle
    end,

    on_construct = function(pos)
		--minimal.log("main:tangler heart".. posToStr(pos))
        local timer = minetest.get_node_timer(pos)
		timer:start(2)
    end

})


local function findGround(pos)
    local startY=pos.y
    for y=-3,3 do
        pos.y=startY+y
        if isValidVineSpot(pos) then return end
    end
    pos.y=startY
end

minetest.register_node("main:tangler", {
    

	on_construct = function(pos)
		--minimal.log("main:tangler".. posToStr(pos))

        pos.y=pos.y
        local northPos=shallowCopy(pos)
        northPos.z=pos.z+2
        findGround(northPos)
        
        local southPos=shallowCopy(pos)
        southPos.z=pos.z-2
        findGround(southPos)

        local eastPos=shallowCopy(pos)
        eastPos.x=pos.x+2
        findGround(eastPos)

        local westPos=shallowCopy(pos)
        westPos.x=pos.x-2
        findGround(westPos)

        straightVine(1,northPos,0)
        straightVine(2,eastPos,0)
        straightVine(3,southPos,0)
        straightVine(4,westPos,0)
--[[
        for y=0,3 do
            local p=shallowCopy(northPos)
            p.y=p.y+y
            minetest.set_node(p, {name = "main:glow_stone"})
            p=shallowCopy(southPos)
            p.y=p.y+y
            minetest.set_node(p, {name = "main:glow_stone"})
            p=shallowCopy(eastPos)
            p.y=p.y+y
            minetest.set_node(p, {name = "main:glow_stone"})
            p=shallowCopy(westPos)
            p.y=p.y+y
            minetest.set_node(p, {name = "main:glow_stone"})
        end  
]]--
        minetest.after(2, function()
            minetest.set_node(pos, {name="main:tangler_heart"})
        end)
	end,
})