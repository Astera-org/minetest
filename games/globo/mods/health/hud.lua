----------------------------------------------------------------------
--HUD
----------------------------------------------------------------------

-- Internationalization
local S = HEALTH.S

local hud = {}
local hudupdateseconds = 60 -- JED tonumber(minetest.settings:get("exile_hud_update"))
-- global setting for whether to show stats
local mtshowstats = minetest.settings:get_bool("exile_hud_show_stats") or true
local mthudopacity = minetest.settings:get("exile_hud_icon_transparency") or 127

-- These are color values for the various status levels. They have to be modified
-- per-function below because textures expect one color format and text another.
-- This is a minetest caveat.

-- In texture coloring we simply concat a #.
--		"#"..stat_color

-- In text coloring we concat an 0x and convert the resulting string to a number.
--		tostring("0x"..stat_color)

local stat_fine 	= "FFFFFF"
local stat_slight 	= "FDFF46"
local stat_problem 	= "FF8100"
local stat_major 	= "DF0000"
local stat_extreme	= "8008FF"

local hud_vert_pos	= -128 -- all HUD icon vertical position
local hud_extra_y	= -16  -- pixel offset for hot/cold icons
local hud_text_y	= 32   -- optional text stat offset

local longbarpos = {
   [true] = { ["y"] = 0, ["x"] = 64 },
   [false] = { ["y"] = 80, ["x"] = 0}
}

local hud_health_x	= -300
local hud_hunger_x	= -300
local hud_thirst_x	= -64
local hud_energy_x	= 0
local hud_air_temp_x 	= 64
local hud_sick_x 	= 300
local hud_body_temp_x	= 300

local icon_scale = {x = 1, y = 1}  -- all HUD icon image scale

wielded_hud = {}
wielded_hud.list = {}

function wielded_hud.register_hudwield(itemname, updatefunc, unwieldfunc)
   -- functions should accept (player, pname, playermeta)
   -- updatefunc should set up and/or update your hud elements
   -- unwieldfunc is called so you can clean up and delete hud elements
   wielded_hud.list[itemname] = { update = updatefunc,
				  unwield = unwieldfunc }
end

local function tobool(str)
   if str == "true" then
      return true
   end
   return false
end

local function are_stats_visible(hud_data)
   return (( hud_data.showstats and hud_data.showstats == true ) or
      ( hud_data.showstats == nil and mtshowstats == true ) )
end

local stdpos = { x = .5, y = 1}




minetest.register_chatcommand("show_stats", {
	params = S("[ help | clear ]"),
	description = S("Enable or disable stats showing below icons. "..
			"Pass 'clear' as a parameter to revert to defaults."),
    func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local meta = player:get_meta()
		local hud_data = hud[name]
		if param == "help" then
		   local wlist = S("/show_stats:\n"..
		      "Toggle stats showing below icons. Use '/show_stats "..
		      "clear' to revert to defaults")
		   return false, wlist
		elseif param == "clear" then
		   meta:set_string("exile_hud_show_stats", "")
		   hud_data.showstats = nil
		   return true, S("Cleared setting")
		else
		   local show_stats = meta:get("exile_hud_show_stats")
		   if not show_stats then
		      show_stats = tostring(mtshowstats)
		   end
		   local newval = not tobool(show_stats)
		   meta:set_string("exile_hud_show_stats", tostring(newval))
		   hud_data.showstats = newval
		   if newval == true then
		      return true, S("Enabled stats.")
		   else
		      return true, S("Disabled stats.")
		   end
		end
	end
})

