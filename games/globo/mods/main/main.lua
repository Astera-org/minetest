

-- local mod_storage = minetest.get_mod_storage()
-- register a global timer when the game first starts
minetest.after(GAME_LENGTH, function()

    local player=minetest.get_player_by_name("singleplayer")
    local meta = player:get_meta()
    local score=meta.get_string("score")
    minimal.log("******************************************")
    minimal.log("Game over man!")
    minimal.log("Score: "..score)
    minimal.log("******************************************")
end)