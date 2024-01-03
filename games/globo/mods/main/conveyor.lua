
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
    { north=-1, south= 0, east= 0, west= 0}, -- 2 north out only
    { north= 0, south=-1, east= 0, west= 0}, -- 3 south out only
    { north= 0, south= 0, east=-1, west= 0}, -- 4 east out only
    { north= 0, south= 0, east= 0, west=-1}, -- 5 west out only
    { north= 1, south= 0, east= 0, west= 0}, -- 6 north in only
    { north= 0, south= 1, east= 0, west= 0}, -- 7 south in only
    { north= 0, south= 0, east= 1, west= 0}, -- 8 east in only
    { north= 0, south= 0, east= 0, west= 1}, -- 9 west in only
    { north= 1, south=-1, east= 0, west= 0}, -- 10 north in, south out
    { north= 1, south= 0, east=-1, west= 0}, -- 11 north in, east out
    { north= 1, south= 0, east= 0, west=-1}, -- 12 north in, west out
    { north=-1, south= 1, east= 0, west= 0}, -- 13 south in, north out
    { north= 0, south= 1, east=-1, west= 0}, -- 14 south in, east out
    { north= 0, south= 1, east= 0, west=-1}, -- 15 south in, west out
    { north=-1, south= 0, east= 1, west= 0}, -- 16 east in, north out
    { north= 0, south=-1, east= 1, west= 0}, -- 17 east in, south out
    { north= 0, south= 0, east= 1, west=-1}, -- 18 east in, west out
    { north=-1, south= 0, east= 0, west= 1}, -- 19 west in, north out
    { north= 0, south=-1, east= 0, west= 1}, -- 20 west in, south out
    { north= 0, south= 0, east=-1, west= 1}, -- 21 west in, east out
    { north= 1, south=-1, east= 1, west=-1}, -- 22 crossroads, in north out south, in east out west
    { north= 1, south=-1, east=-1, west= 1}, -- 23 crossroads, in north out south, in west out east
    { north=-1, south= 1, east= 1, west=-1}, -- 24 crossroads, in south out north, in east out west
    { north=-1, south= 1, east=-1, west= 1}, -- 25 crossroads, in south out north, in west out east
    { north= 1, south= 0, east=-1, west=-1}, -- 26 Spilt north in, east or west out
    { north= 0, south= 1, east=-1, west=-1}, -- 27 Spilt south in, east or west out
    { north=-1, south=-1, east= 1, west= 0}, -- 28 Spilt east in, north or south out
    { north=-1, south=-1, east= 0, west= 1}, -- 29 Spilt west in, north or south out
    { north= 1, south= 1, east=-1, west= 0}, -- 30 merge north or south in, east out
    { north= 1, south= 1, east= 0, west=-1}, -- 31 merge north or south in, west out
    { north=-1, south= 0, east= 1, west= 1}, -- 32 merge east or west in, north out
    { north= 0, south=-1, east= 1, west= 1}, -- 33 merge west or east in, south out
    { north= 1, south=-1, east= 1, west= 0}, -- 34 merge north or east in, south out
    { north= 1, south= 0, east= 1, west=-1}, -- 35 merge north or east in, west out
    { north= 1, south=-1, east= 0, west= 1}, -- 36 merge north or west in, south out
    { north= 1, south= 0, east=-1, west= 1}, -- 37 merge north or west in, east out
    { north=-1, south= 1, east= 1, west= 0}, -- 38 merge south or east in, north out
    { north= 0, south= 1, east= 1, west=-1}, -- 39 merge south or east in, west out
    { north=-1, south= 1, east= 0, west= 1}, -- 40 merge south or west in, north out
    { north= 0, south= 1, east=-1, west= 1}, -- 41 merge south or west in, east out
}


local function getNeighborValue(pos,offset)
    local nPos=shallowCopy(pos)
    nPos.x=nPos.x+offset.x
    nPos.z=nPos.z+offset.z

    for y = -1,1 do
        nPos.y=pos.y+y
        local neighbor_node = minetest.get_node(nPos)
        if neighbor_node.name == "main:conveyor" then
            -- Found a neighboring conveyor belt, return its param
            local param=minetest.get_meta(nPos):get_int("param")
            return param, nPos
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

        if matchCount == 4 then return end

        if matchCount > numMatches then
            numMatches=matchCount
            closestIndex=i
        end
    end

    minimal.log("makeValidDir closestIndex:"..closestIndex.." numMatches:"..numMatches)
    dir.north=dirMap[closestIndex].north
    dir.south=dirMap[closestIndex].south
    dir.east=dirMap[closestIndex].east
    dir.west=dirMap[closestIndex].west
end



local function connectRawNeighbor(yourDir,neighbor,yc,nc)
    local nDir=shallowCopy(dirMap[neighbor.param])
    yourDir[yc]=-1
    nDir[nc]=1
    if getDirMapIndex(yourDir)==0 then  
        yourDir[yc]=1
        nDir[nc]=-1
        if getDirMapIndex(yourDir)==0 then 
            yourDir[yc]=-1 
            nDir[nc]=-1
            minimal.log("connect still invalid:"..dump(yourDir))
        end
    end
    --minimal.log("connectRawNeighbor yourDir"..dump(yourDir))
    
   
    neighbor.param=getDirMapIndex(nDir)

    --minimal.log("connectRawNeighbor nDir: "..neighbor.param..dump(nDir))
end

local function connectExistingNeighbor(yourDir,neighbor,yc,nc)
    local nDir=shallowCopy(dirMap[neighbor.param])
   
    if nDir[nc] == 0 then 
        yourDir[yc]=-1
        nDir[nc]=1
        if getDirMapIndex(nDir)==0 then 
            yourDir[yc]=1
            nDir[nc]=-1
            if getDirMapIndex(nDir)==0 then 
                yourDir[yc]=-1 
                nDir[nc]=-1
                minimal.log("connectNeighbor still invalid*"..dump(nDir)) 
            end
        end
    else 
        yourDir[yc]=-nDir[nc]
    end

    --minimal.log("connectExistingNeighbor yourDir"..dump(yourDir))

    neighbor.param=getDirMapIndex(nDir)
    --minimal.log("connectExistingNeighbor nDir: "..neighbor.param..dump(nDir))
end




local function setConveyorParam(pos)
    -- Directions to check (assuming a 2D grid, add more for a 3D setup)

    local neighbors={ {param=0,pos=nil}, {param=0,pos=nil}, {param=0,pos=nil}, {param=0,pos=nil} }

    local offsets = {
        {x = 1, z = 0}, -- East
        {x = -1,  z = 0}, -- west
        {x = 0,  z = 1}, -- north
        {x = 0,  z = -1}, -- south
    }

    for i,offset in ipairs(offsets) do
       neighbors[i].param , neighbors[i].pos = getNeighborValue(pos,offset)
       --minimal.log(""..i..") dir:"..neighbors[i].dir.." pos:"..dump(neighbors[i].pos))
    end

    local yourDir={ north=0, south=0, east=0, west=0}
    --minimal.log("0 dir:"..getDirMapIndex(yourDir))
    --minimal.log("yourDir 0: "..getDirMapIndex(yourDir).." "..dump(yourDir))

    -- must connect to the existing ones first so we match the raw guys based on what is already laid
    if neighbors[1].param > 1 then  --  east neighbor
        connectExistingNeighbor(yourDir,neighbors[1],"east","west")
    end

    if neighbors[2].param > 1 then -- west neighbor
        connectExistingNeighbor(yourDir,neighbors[2],"west","east")
    end

    if neighbors[3].param > 1 then -- north neighbor
        connectExistingNeighbor(yourDir,neighbors[3],"north","south")
    end

    if neighbors[4].param > 1 then -- south neighbor
        connectExistingNeighbor(yourDir,neighbors[4],"south","north")
    end

    if neighbors[1].param == 1 then  --  east neighbor
        connectRawNeighbor(yourDir,neighbors[1],"east","west")
    end

    if neighbors[2].param == 1 then -- west neighbor
        connectRawNeighbor(yourDir,neighbors[2],"west","east")
    end

    if neighbors[3].param == 1 then -- north neighbor
        connectRawNeighbor(yourDir,neighbors[3],"north","south")
    end

    if neighbors[4].param == 1 then -- south neighbor
        connectRawNeighbor(yourDir,neighbors[4],"south","north")
    end



    --minimal.log("1 yourDir:"..getDirMapIndex(yourDir))
    --repairDir(yourDir)
    makeValidDir(yourDir)
    

    local newParamValue=getDirMapIndex(yourDir)
    if newParamValue == 0 then
        minimal.log("findConveyorDir no direction found")
        return
    end

    --minimal.log("yourDir:("..pos.x..","..pos.z..") param:"..newParamValue)
    minetest.get_meta(pos):set_int("param",newParamValue)

    for i = 1,4 do
        if neighbors[i].param>0 then 
            --minimal.log("neighbor ("..neighbors[i].pos.x..","..neighbors[i].pos.z..") param:"..neighbors[i].param)
            minetest.get_meta(neighbors[i].pos):set_int("param",neighbors[i].param)
        end
    end    
end


minetest.register_node("main:conveyor", {
    drawtype= "raillike",
    tiles = {"conveyor1.png", "conveyor2.png", "conveyor3.png", "conveyor4.png"},
    groups = {snappy = 3, handy=1, attached_node=1, rail=1,  dig_by_water=0, destroy_by_lava_flow=0, transport=1}, -- connect_to_raillike=minetest.raillike_group("rail"),
    is_ground_content = false,
	inventory_image = "conveyor1.png",
	wield_image = "conveyor1.png",
	paramtype = "light",
    paramtype2 = "facedir",
	walkable = false,
    --[[
    collision_box= {
        type = "fixed",
        fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
    }, ]]--
    selection_box = {
        type = "fixed",
        fixed = {-1/2, -1/2, -1/2, 1/2, -1/2+1/16, 1/2},
    },
	stack_max = 3,
		
    after_destruct = function(pos)
        
    end,
	

	on_construct = function(pos)
        --minimal.log("conveyor on_construct("..pos.x..","..pos.z..")")
        setConveyorParam(pos)
    end,
})


--[[
    divide the into 4 regions, go the direction the region says. if the direction there is 0 then find a nearby region with a direction
]]
local function getSideDir(dir,railPos,objPos)
    -- find which side the objPos is closest to
    -- get vector from railPos to objPos

    local vec=vector.direction(railPos,objPos)
    local landed
    
    if (math.abs(vec.x) > math.abs(vec.z)) then
        if vec.x < 0 then
            landed="east"
        else landed="west" end
    elseif vec.z < 0 then
        landed="south"
    else landed="north" end

    if dir[landed] == -1 then return landed end
    local goingIn=(math.abs(vector.distance(railPos,objPos))>.5)
    if goingIn and dir[landed] == 1 then return landed end
 
    -- not sure which direction to go pick an out direction
    if dir.north == -1 then return "north" end
    if dir.south == -1 then return "south" end
    if dir.east == -1 then return "east" end
    if dir.west == -1 then return "west" end

    if dir[landed] == 1 then return landed end --just keep going if there is no other out dir
    return nil
end

-- Define the ABM (Active Block Modifier) for moving objects
minetest.register_abm({
    nodenames = {"main:conveyor"}, -- The node this ABM applies to
    interval = 1.0, -- Run every second
    chance = 1, -- Always run

    action = function(pos, node)
        local objects = minetest.get_objects_inside_radius(pos, 0.7)
        local param = minetest.get_meta(pos):get_int("param")
        local dirValues = dirMap[param]
         
        for _, obj in ipairs(objects) do
            --minimal.log("on belt("..pos.x..","..pos.z..") param"..param)
            local side=getSideDir(dirValues,pos,obj:get_pos())
            if side ~= nil then
                local velocity = { x = 0, y = 2, z = 0 }
                local magnitude=dirValues[side]*2
                local checkPos=shallowCopy(pos)
                --checkPos.y=checkPos.y-1
                if side =="east" then velocity.x = -magnitude checkPos.x=pos.x+1
                elseif side=="west" then velocity.x = magnitude checkPos.x=pos.x-1
                elseif side=="north" then velocity.z= -magnitude checkPos.z=pos.z+1
                else velocity.z= magnitude checkPos.z=pos.z-1 end

                -- check if the node in the direction it is going is higher
                local lift=false
                local checkNode=minetest.get_node(checkPos)
                if checkNode.name ~= "air" and checkNode.name ~= "main:conveyor" then 
                    --minimal.log("Need lift")
                    lift=true 
                end --else minimal.log("checkPos: "..posToStr(checkPos) ) end

        
                if obj:is_player() then 
                    velocity.y=0
                    if lift then velocity.y=1 end
                    minetest.after(0, function()
                        obj:set_pos(vector.add(obj:get_pos(), velocity))
                    end)
                else
                    if lift then 
                        local p=obj:get_pos() 
                        p.y = p.y+1
                        obj:set_pos(p)
                    end
                    obj:set_velocity(velocity)
                end
            end
        end
    end,
})


--------------------------------------------
-- TESTS
--------------------------------------------


function messWithDir(dir)
    dir.north=12
end

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

    ret=getDirMapIndex(dir)
    if ret ~= 13  then
        minimal.log("tanglerTest expected 13 got "..ret)
    end

   -- messWithDir(dir)
   -- minimal.log("Mess result "..dir.north)

    minimal.log("tangler Test over")
end
