

-- returns 2D angle from self to target in radians
function get_yaw_to_object(pos, opos)
    local ankat = pos.x - opos.x
    local gegkat = pos.z - opos.z
    local yaw = math.atan2(ankat, gegkat)
    return yaw
end
  
  
  --flee sound (has to be in water!)
  function flee_sound(self)
      if not self.isinliquid then
          return
      end
      --mobkit.make_sound(self,'flee')
  end

  
function yaw_to_neighbor(yaw)
    local angle = yaw % (2 * math.pi)  -- Normalize yaw to [0, 2π)
    local increment= math.pi / 8
  
    local index=1
  
    if angle >= (3 * increment) and angle < (5*increment) then
        index = 5  -- West  
    elseif angle >= (increment) and angle < (3 * increment) then
        index = 4  -- Northwest 
    elseif angle >= (15 * increment) or angle < (increment) then
        index = 3  -- North
    elseif angle >= (13 * increment) and angle < (15 * increment) then
        index = 2  -- Northeast
    elseif angle >= (11 * increment) and angle < (13 * increment) then
        index = 1  -- East
    elseif angle >= (9 * increment) and angle < (11 * increment) then
        index = 8  -- Southeast
    elseif angle >= (7 * increment) and angle < (9 * increment) then
        index = 7  -- South
    elseif angle >= (5 * increment) and angle < (7 * increment) then
        index = 6  -- Southwest
    else
      minetest.log("action", "yaw_to_neighbor: angle="..angle.." index="..index)
    end
  
  
    return index
  end

function is_dropped_item(obj)
    return obj and obj:get_luaentity() and obj:get_luaentity().name == "__builtin:item"
end
  
function get_dropped_item_name(obj)
    if is_dropped_item(obj) then
        local luaentity = obj:get_luaentity()
        local itemstack = ItemStack(luaentity.itemstring)
        return itemstack:get_name()
    end
    return nil
end

function get_dropped_item_groups(obj)
    if is_dropped_item(obj) then
        local lua_entity = obj:get_luaentity()
        local itemstring = lua_entity.itemstring
        local item_def = minetest.registered_items[itemstring]
        if item_def then
            return item_def.groups
        end
    end
    return nil
end



  function get_mean_temp(pos) -- this could be put somewhere else like in climate or minimal
    local temps = {}
    
    if (type(pos) ~= "table") then -- no pos table is given then
      return 15
    elseif (type(pos.x) ~= "number" or type(pos.y) ~= "number" or type(pos.z) ~= "number") then -- incase an invalid pos is given
      return 15
    end
    
    for x = -1, 1, 1 do -- create matrix of possible positions
      for y = -1, 1, 1 do
        for z = -1, 1, 1 do
          local npos = {x = (pos.x - x), y = (pos.y - y), z = (pos.z - z)} -- matrix the pos :D
          
          temps[#temps + 1] = climate.get_point_temp(npos, true)
        end
      end
    end
    
    local mtemp = 0 -- start with a number so it can be calculated
    for _,num in pairs(temps) do
      mtemp = mtemp + num
    end
    
    return mtemp / #temps -- return the "mean" of the matrix'd temps
  end

function closest_node_in_group(center_pos, range, group_name)
    local min_dist = range + 1
    local closest_pos = nil

    for x = -range, range do
        for y = -range, range do
            for z = -range, range do
                local pos = {x = center_pos.x + x, y = center_pos.y + y, z = center_pos.z + z}
                local node = minetest.get_node(pos)
                if minetest.get_item_group(node.name, group_name) > 0 then
                    local dist = vector.distance(center_pos, pos)
                    if dist < min_dist then
                        min_dist = dist
                        closest_pos = pos
                    end
                end
            end
        end
    end

    return closest_pos
end