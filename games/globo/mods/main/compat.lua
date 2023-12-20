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
