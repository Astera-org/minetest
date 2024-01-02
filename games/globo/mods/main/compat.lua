minimal = {
	stack_max_bulky = 2,
	stack_max_medium = 24,
	stack_max_light = 288,
	--hand base abilities
	hand_punch_int = 0.8,
	hand_max_lvl = 1,
	hand_crac = 3.5,
	hand_chop = 1.5,
	hand_crum = 1.0,
	hand_snap = 0.5,
	hand_dmg = 1,

	t_scale2 = 3,
	t_scale1 = 6,

}

minimal = minimal

minimal.mtversion = {}

local version = minetest.get_version()
local tabstr = string.split(version.string,".")
local major = tonumber(tabstr[1])
local minor = tonumber(tabstr[2])
local dev = tostring(string.match(tabstr[3], "-dev") ~= nil)
-- '%d[%d]*' extracts the first string of consecutive numeric chars
local patch = tonumber(string.match(tabstr[3], '%d[%d]*'))
minetest.log("action", "Running on version: "..version.project.." "..
	     major.."."..minor.."."..patch.." Dev version: "..dev)
minimal.mtversion = { project = version.project, major = major,
		      minor = minor, patch = patch, dev = dev }

function minimal.mt_required_version(maj, min, pat)
   if minimal.mtversion.project ~= "Minetest" then
      return false -- Not running Minetest? #TODO check indiv feature support
   end
   if minimal.mtversion.major > maj or
      ( minimal.mtversion.major == maj and
	minimal.mtversion.minor > min ) or
      ( minimal.mtversion.major == maj and
	minimal.mtversion.minor == min and
	minimal.mtversion.patch >= pat ) then
      return true
   else
      return false
   end
end

function minimal.get_daylight(pos, tod)
   if minetest.get_natural_light then
      return minetest.get_natural_light(pos, tod)
   else
      return minetest.get_node_light(pos,tod)
   end
end

minimal.compat_alpha = {}
if minimal.mt_required_version(5, 4, 0) then
   minimal.compat_alpha = {
      ["blend"] = "blend",
      ["opaque"] = "opaque",
      ["clip"] = "clip",
   }
else
   minimal.compat_alpha = {
      ["blend"] = true,
      ["opaque"] = false,
      ["clip"] = true, -- may be false for some draw types?
   }
end

function minimal.math_clamp(num,min,max) -- math.clamp implementation from my function library (TPH/TubberPupperHusker)
   -- PARAMETERS: num;"number" - number to be clamped | min;"number" - minimum number that 'num' can be | max;"number" - maximum number that 'num' can be
   -- RETURNS: number - 'num' that is clamped (or not if 'num' is between 'min' and 'max')
   -- FUNCTION: clamps a specified number between a min & max
   ------------------------------------------------------------------------------------------------------------------
   assert(type(num) == "number","math.clamp: no number provided to be clamped!")
   assert(type(min) == "number","math.clamp: no minimum number provided for clamping")
   assert(type(max) == "number","math.clamp: no maximum number provided for clamping")
   
   -- if num, min, and max are numbers then
   if (min > max) then -- if programmer puts max number in place of minimum number... don't punish them for it
     local temp = min -- create a temporary value so that 'min' can be stored
     min = max
     max = temp -- set 'max' to the temporary value
   end
   
   if (num < min) then
     num = min
   elseif (num > max) then
     num = max
   end
   -- "if elseif" statement because if it's lower than minimum then it's obviously not going to be greater than maximum and vice versa (and DO NOT clamp if the number is between min and max)
   
   return num
 end


 function minimal.log(message)
   minetest.chat_send_all(message)
   minetest.log("action", message)
 end


 function shallowCopy(orig)
   local copy = {}
   for key, value in pairs(orig) do
       copy[key] = value
   end
   return copy
end

function posToStr(pos)
   return "("..pos.x..","..pos.y..","..pos.z..")"
end

function strToPos(str)
   local x, y, z = str:match("%((%-?%d+),(%-?%d+),(%-?%d+)%)")
   if x and y and z then
       return {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
   else
       minimal.log("Invalid position string: " .. str)
       return {x=0,y=0,z=0}
   end
end


