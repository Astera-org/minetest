

function randomFloat(min, max)
    return min + math.random()  * (max - min)
end

function bound(value,min,max)
    if(value<min) then return min end
    if(value>max) then return max end
    return value
end