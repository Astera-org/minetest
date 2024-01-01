
--[[
How conveyors work:
When a track is first laid down, it checks for neighboring tracks and sets its direction accordingly.
When a minecart is on a track, it checks for neighboring tracks and moves in that direction.
When a track is destroyed, it checks for minecarts on it and forces them to execute their "floating" check.

A newly laid track will try to match the directions of the tracks alreay there
If laid next to an existing no direction track, both will assume that the direction is toward the older track

]]--


-- neighbor on your left has the dir of i what possible dirs can you have. Any that are going in or out to the west

local dirMap={
    { north= 0, south= 0, east= 0, west= 0}, -- 1 no direction set
    { north= 1, south=-1, east= 0, west= 0}, -- 2 north in, south out
    { north= 1, south= 0, east=-1, west= 0}, -- 3 north in, east out
    { north= 1, south= 0, east= 0, west=-1}, -- 4 north in, west out
    { north=-1, south= 1, east= 0, west= 0}, -- 5 south in, north out
    { north= 0, south= 1, east=-1, west= 0}, -- 6 south in, east out
    { north= 0, south= 1, east= 0, west=-1}, -- 7 south in, west out
    { north=-1, south= 0, east= 1, west= 0}, -- 8 east in, north out
    { north= 0, south=-1, east= 1, west= 0}, -- 9 east in, south out
    { north= 0, south= 0, east= 1, west=-1}, -- 10 east in, west out
    { north=-1, south= 0, east= 0, west= 1}, -- 11 west in, north out
    { north= 0, south=-1, east= 0, west= 1}, -- 12 west in, south out
    { north= 0, south= 0, east=-1, west= 1}, -- 13 west in, east out
    { north= 1, south=-1, east= 1, west=-1}, -- 14 crossroads, in north out south, in east out west
    { north= 1, south=-1, east=-1, west= 1}, -- 15 crossroads, in north out south, in west out east
    { north=-1, south= 1, east= 1, west=-1}, -- 16 crossroads, in south out north, in east out west
    { north=-1, south= 1, east=-1, west= 1}, -- 17 crossroads, in south out north, in west out east
    { north= 1, south= 0, east=-1, west=-1}, -- 18 Spilt north in, east or west out
    { north= 0, south= 1, east=-1, west=-1}, -- 19 Spilt south in, east or west out
    { north=-1, south=-1, east= 1, west= 0}, -- 20 Spilt east in, north or south out
    { north=-1, south=-1, east= 0, west= 1}, -- 21 Spilt west in, north or south out
    { north= 1, south= 1, east=-1, west= 0}, -- 22 merge north or south in, east out
    { north= 1, south= 1, east= 0, west=-1}, -- 23 merge north or south in, west out
    { north=-1, south= 0, east= 1, west= 1}, -- 24 merge east or west in, north out
    { north= 0, south=-1, east= 1, west= 1}, -- 25 merge west or east in, south out
}


local function get_conveyor_dir(pos,offset)
    for y = -1,1 do
        local neighbor_pos = vector.add(pos, {x = offset.x, y = y, z = offset.z})
        local neighbor_node = minetest.get_node(neighbor_pos)
        if neighbor_node.name == "main:conveyor" then
            -- Found a neighboring conveyor belt, return its direction
            return neighbor_node.param1, neighbor_pos
        end
    end

    return -1,nil -- no neighbor
end

local function getDirMapIndex(dir)
    for i,d in ipairs(dirMap) do
        --minimal.log("getDirMapIndex ",)
        if d.north == dir.north and d.south == dir.south and 
           d.east == dir.east and d.west == dir.west then
            return i
        end
    end

    return 0
end

local function repairDir(dir)
    if dir.north == 0 and dir.south == 0 and dir.east==0 and dir.west==0 then return dir end

    local hasIn=false
    local hasOut=false
    if dir.north == 1 or dir.south == 1 or dir.east==1 or dir.west==1 then hasIn=true end
    if dir.north == -1 or dir.south == -1 or dir.east==-1 or dir.west==-1 then hasOut=true end
    if hasIn and not hasOut then
        if dir.north == 1 then dir.south=-1 
        elseif dir.south == 1 then dir.north=-1
        elseif dir.east == 1 then dir.west=-1
        elseif dir.west == 1 then dir.east=-1 end

        return dir
    end

    if hasOut and not hasIn then
        if dir.north == -1 then dir.south=1 
        elseif dir.south == -1 then dir.north=1
        elseif dir.east == -1 then dir.west=1
        elseif dir.west == -1 then dir.east=1 end

        return dir
    end

    return dir
end

--todo this seems broken
local function makeValidDir(dir)
    -- loop through the dirMap and see if any match yours
    -- keep track of the closest match
    local numMatches=0
    local closestIndex=0
    for i,d in ipairs(dirMap) do
        local matchCount=0
        if d.north == dir.north then matchCount=matchCount+1 end
        if d.south == dir.south then matchCount=matchCount+1 end
        if d.east == dir.east then matchCount=matchCount+1 end
        if d.west == dir.west then matchCount=matchCount+1 end

        if matchCount == 4 then return dir end

        if matchCount > numMatches then
            numMatches=matchCount
            closestIndex=i
        end
    end

    dir.north=dirMap[closestIndex].north
    dir.south=dirMap[closestIndex].south
    dir.east=dirMap[closestIndex].east
    dir.west=dirMap[closestIndex].west

    return dir
    --return dirMap[closestIndex]
end

local function connectNorth(yourDir,neighborDir)
    if neighborDir==0 then
        local testDir=copyDir(yourDir)
        testDir.south=-1
        if getDirMapIndex(testDir)>0 then return -1 end
        testDir.south=1
        if getDirMapIndex(testDir)>0 then return 1 end
        return -1  
    else
        local nDir=dirMap[neighborDir]
        if nDir.south == 0 then 
            local testDir=copyDir(nDir)
            testDir.south=-1
            if getDirMapIndex(testDir)>0 then return -1 end
            testDir.south=1
            if getDirMapIndex(testDir)>0 then return 1 end
            return -1
        else return -nDir.south end
    end
end
local function connectSouth(yourDir,neighborDir)
    if neighborDir==0 then
        local testDir=copyDir(yourDir)
        testDir.north=-1
        if getDirMapIndex(testDir)>0 then return -1 end
        testDir.north=1
        if getDirMapIndex(testDir)>0 then return 1 end
        return -1  
    else
        local nDir=dirMap[neighborDir]
        if nDir.north == 0 then 
            local testDir=copyDir(nDir)
            testDir.north=-1
            if getDirMapIndex(testDir)>0 then return -1 end
            testDir.north=1
            if getDirMapIndex(testDir)>0 then return 1 end
            return -1
        else return -nDir.north end
    end
end
local function connectEast(yourDir,neighborDir)
    if neighborDir==0 then
        local testDir=copyDir(yourDir)
        testDir.west=-1
        if getDirMapIndex(testDir)>0 then return -1 end
        testDir.west=1
        if getDirMapIndex(testDir)>0 then return 1 end
        return -1  
    else
        local nDir=dirMap[neighborDir]
        if nDir.west == 0 then 
            local testDir=copyDir(nDir)
            testDir.west=-1
            if getDirMapIndex(testDir)>0 then return -1 end
            testDir.west=1
            if getDirMapIndex(testDir)>0 then return 1 end
            return -1
        else return -nDir.west end
    end
end
local function connectWest(yourDir,neighborDir)
    if neighborDir==0 then
        local testDir=copyDir(yourDir)
        testDir.east=-1
        if getDirMapIndex(testDir)>0 then return -1 end
        testDir.east=1
        if getDirMapIndex(testDir)>0 then return 1 end
        return -1  
    else
        local nDir=dirMap[neighborDir]
        if nDir.east == 0 then 
            local testDir=copyDir(nDir)
            testDir.east=-1
            if getDirMapIndex(testDir)>0 then return -1 end
            testDir.east=1
            if getDirMapIndex(testDir)>0 then return 1 end
            return -1
        else return -nDir.east end
    end
end

local function set_conveyor_direction(pos)
    -- Directions to check (assuming a 2D grid, add more for a 3D setup)

    local neighbors={ {param=0,pos=nil}, {param=0,pos=nil}, {param=0,pos=nil}, {param=0,pos=nil} }

    local offsets = {
        {x = 1, z = 0}, -- East
        {x = -1,  z = 0}, -- west
        {x = 0,  z = 1}, -- north
        {x = 0,  z = -1}, -- south
    }

    for i,offset in ipairs(offsets) do
       neighbors[i].param , neighbors[i].pos = get_conveyor_dir(pos,offset)
       --minimal.log(""..i..") dir:"..neighbors[i].dir.." pos:"..dump(neighbors[i].pos))
    end

    local yourDir={ north=0, south=0, east=0, west=0}
    minimal.log("0 dir:"..getDirMapIndex(yourDir))

    minimal.log("yourDir 0: "..getDirMapIndex(yourDir).." "..dump(yourDir))

    if neighbors[1].param >= 0 then  --  east neighbor
        yourDir.east= connectEast(yourdir,neighbors[1].dir)
    end

    if neighbors[2].dir >= 0 then -- west neighbor
        yourDir.west= connectSouth(yourdir,neighbors[2].dir)
    end

    if neighbors[3].dir >= 0 then -- north neighbor
        yourDir.west= connectSouth(yourdir,neighbors[3].dir)
    end

    if neighbors[4].dir >= 0 then -- south neighbor
        yourDir.south=connectSouth(yourdir,neighbors[4].dir)
    end

    minimal.log("1 dir:"..getDirMapIndex(yourDir))
    yourDir=repairDir(yourDir)
    yourDir=makeValidDir(yourDir)
    minimal.log("1.5 dir:"..getDirMapIndex(yourDir))

    -- check for not set neighbors
    if neighbors[1].dir == 0 or neighbors[1].dir == 1  then  --  east neighbor
        -- see if it works with east in, if not then east must be out
        yourDir.east= -1
        if getDirMapIndex(yourDir) == 0 then
            yourDir.east= 1
        end
        yourDir=repairDir(yourDir)
        minimal.log("yourDir5: "..dump(yourDir))
        minimal.log("yourDir5: "..getDirMapIndex(yourDir).." "..dump(yourDir))
        minimal.log("1 neigbor not set")
    end

    if neighbors[2].dir == 0 or neighbors[2].dir == 1 then -- west neighbor
        -- see if it works with west in, if not then west must be out
        yourDir.west= -1
        if getDirMapIndex(yourDir) == 0 then
            yourDir.west= 1
        end
        yourDir=repairDir(yourDir)
        minimal.log("yourDir6: "..getDirMapIndex(yourDir).." "..dump(yourDir))
        minimal.log("2 neigbor not set")
    end

    if neighbors[3].dir == 0 or neighbors[3].dir == 1 then -- north neighbor
        -- see if it works with north in, if not then north must be out
        yourDir.north= -1
        if getDirMapIndex(yourDir) == 0 then
            yourDir.north= 1
        end
        yourDir=repairDir(yourDir)
        minimal.log("yourDir7: "..getDirMapIndex(yourDir).." "..dump(yourDir))
        minimal.log("3 neigbor not set")
    end

    if neighbors[4].dir == 0 or neighbors[4].dir == 1 then -- south neighbor
        -- see if it works with south in, if not then south must be out
        yourDir.south= -1
        if getDirMapIndex(yourDir) == 0 then
            yourDir.south= 1
        end
        yourDir=repairDir(yourDir)
        minimal.log("yourDir8: "..getDirMapIndex(yourDir).." "..dump(yourDir))
        minimal.log("4 neigbor not set")
    end


    minimal.log("2 dir:"..getDirMapIndex(yourDir).." "..dump(yourDir))

    local newParamValue=getDirMapIndex(yourDir)
    if newParamValue == 0 then
        minimal.log("findConveyorDir no direction found")
        return
    end

    local existingNeedUpdate=false
    -- must update your param1 before you update the non set neighbors
    local node = minetest.get_node(pos)
    if node.name == "main:conveyor" then
        if node.param1 ~= newParamValue then
            existingNeedUpdate=true
            minimal.log("Updating param1:"..node.param1.." to "..newParamValue)
            minetest.set_node(pos, {name = "main:conveyor", param1 = newParamValue})
        end
    else 
        minimal.log("set_conveyor_direction node not a conveyor")
    end

    for i = 1,4 do
        if neighbors[i].dir == 1 or (neighbors[i].dir>1 and existingNeedUpdate) then 
            minimal.log("re-setting neighbor "..i)
            set_conveyor_direction(neighbors[i].pos)
        end
    end    
end


minetest.register_node("main:conveyor", {
    drawtype= "raillike",
    tiles = {"conveyor1.png", "conveyor2.png", "conveyor3.png", "conveyor4.png"},
    groups = {handy=1, attached_node=1,rail=1,  dig_by_water=0, destroy_by_lava_flow=0, transport=1}, -- connect_to_raillike=minetest.raillike_group("rail"),
    is_ground_content = false,
	inventory_image = "conveyor1.png",
	wield_image = "conveyor1.png",
	--paramtype = "light",
    paramtype2 = "facedir",
	walkable = false,
    selection_box = {
        type = "fixed",
        fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
    },
	stack_max = 3,
		
    after_destruct = function(pos)
        -- Scan for minecarts in this pos and force them to execute their "floating" check.
        -- Normally, this will make them drop.
        local objs = minetest.get_objects_inside_radius(pos, 1)
        for o=1, #objs do
            local le = objs[o]:get_luaentity()
            if le then
                -- All entities in this mod are minecarts, so this works
                if string.sub(le.name, 1, 14) == "mcl_minecarts:" then
                    le._last_float_check = mcl_minecarts.check_float_time
                end
            end
        end
    end,
	

	on_construct = function(pos)
        
        minimal.log("conveyor on_construct")
        local node = minetest.get_node(pos)
        if node.param1 == 0 then
            set_conveyor_direction(pos)
        end  
    end,

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        
    end,
})

function tanglerTest()
    for i,dir in ipairs(dirMap) do
        if i ~= getDirMapIndex(dir) then
            minimal.log("getDirMapIndex failed: "..i.." dir:".. dump(dir))
        end
    end

    local dir={
        north = -1,
        south = -1,
        east = 0,
        west = 0
    }
    local ret=getDirMapIndex(dir)
    if getDirMapIndex(dir) ~= 0  then
        minimal.log("tanglerTest expected 0 got "..ret)
    end

    dir={
        north = 0,
        south = 0,
        east = -1,
        west = 0
    }
    local ret=getDirMapIndex(dir)
    if ret ~= 0  then
        minimal.log("tanglerTest expected 0 got "..ret)
    end

    dir=repairDir(dir)
    ret=getDirMapIndex(dir)
    if ret ~= 13  then
        minimal.log("tanglerTest expected 13 got "..ret)
    end

    minimal.log("tangler Test over")
end



--[[

-- Define the ABM (Active Block Modifier) for moving objects
minetest.register_abm({
    nodenames = {"main:conveyor"}, -- The node this ABM applies to
    interval = 1.0, -- Run every second
    chance = 1, -- Always run

    action = function(pos, node)
        local objects = minetest.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objects) do
            if obj:is_player() == false then
                local dir = minetest.facedir_to_dir(node.param1)
                local new_pos = vector.add(pos, dir)
                local new_node = minetest.get_node(new_pos)
                if new_node.name == "main:conveyor" then
                    obj:set_pos(new_pos)
                    obj:set_velocity(vector.new(0, 0, 0)) -- Stop the object from moving further
    
                    -- Schedule a move in the new direction on the next ABM cycle
                    minetest.after(0, function()
                        if obj then
                            local new_dir = minetest.facedir_to_dir(new_node.param1)
                            obj:set_velocity(vector.multiply(new_dir, 1))
                        end
                    end)
                end
            end
        end
    end,

    action = function(pos, node)
        local objects = minetest.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objects) do
            if obj:is_player() == false then
                local meta = minetest.get_meta(pos)
                local dir = minetest.deserialize(meta:get_string("direction"))

                local new_pos = vector.add(pos, dir)
                local new_node = minetest.get_node(new_pos)
                if new_node.name == "main:conveyor" then
                    local new_meta = minetest.get_meta(new_pos)
                    local new_dir = minetest.deserialize(new_meta:get_string("direction"))

                    obj:set_pos(new_pos)
                    obj:set_velocity(vector.new(0, 0, 0)) -- Stop the object from moving further

                    -- Schedule a move in the new direction on the next ABM cycle
                    minetest.after(0, function()
                        if obj then
                            obj:set_velocity(vector.multiply(new_dir, 1))
                        end
                    end)
                end
            end
        end
    end, 
})

]]--






