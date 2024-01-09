

function randomFloat(min, max)
    return min + math.random()  * (max - min)
end

function bound(value,min,max)
    if(value<min) then return min end
    if(value>max) then return max end
    return value
end

function isInList(target, list)
    for _, value in ipairs(list) do
        if value == target then
            return true
        end
    end
    return false
end

function is_dropped_item_in_group_at_pos(group, pos, radius)
    local objects = minetest.get_objects_inside_radius(pos, radius or 0.6) -- Adjust radius as needed
    for _, obj in ipairs(objects) do
        if obj:get_luaentity() and obj:get_luaentity().name == "__builtin:item" then
            local itemstack = ItemStack(obj:get_luaentity().itemstring)
            if minetest.get_item_group(itemstack:get_name(), group) > 0 then
                return true -- Found a dropped item in the group
            end
        end
    end
    return false -- No dropped item found in the group
end