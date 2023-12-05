local creature_definitions = {
    wolf = {
        physical = true,
        stepheight = 1.1,
        collisionbox = {-0.3, -0.01, -0.3, 0.3, 0.75, 0.3},
        visual = "mesh",
        visual_size = {x=10, y=10},
        mesh = "wolf.b3d",
        textures = {"creature_wolf.png"},
        makes_footstep_sound = true,
        view_range = 15,
        walk_velocity = 2,
        run_velocity = 4,
        damage = 2,
        drops = {"farming:meat_raw 2"},
        armor = 200,
        drawtype = "front",
        water_damage = 0,
        lava_damage = 5,
        light_damage = 0,
        fear_height = 2,
        on_rightclick = nil,
    },
    cow = {
        physical = true,
        stepheight = 1.1,
        collisionbox = {-0.4, -0.01, -0.4, 0.4, 0.9, 0.4},
        visual = "mesh",
        visual_size = {x=10, y=10},
        mesh = "cow.b3d",
        textures = {"creature_cow.png"},
        makes_footstep_sound = true,
        view_range = 10,
        walk_velocity = 1.2,
        run_velocity = 1.8,
        damage = 1,
        drops = {"farming:meat_raw 3"},
        armor = 250,
        drawtype = "front",
        water_damage = 1,
        lava_damage = 10,
        light_damage = 0,
        fear_height = 2,
        on_rightclick = nil,
    },
    mongoose = {
        physical = true,
        stepheight = 1.0,
        collisionbox = {-0.25, -0.01, -0.25, 0.25, 0.5, 0.25},
        visual = "mesh",
        visual_size = {x=8, y=8},
        mesh = "mongoose.b3d",
        textures = {"creature_mongoose.png"},
        makes_footstep_sound = true,
        view_range = 12,
        walk_velocity = 1.5,
        run_velocity = 2.5,
        damage = 1,
        drops = {"farming:meat_raw 1"},
        armor = 150,
        drawtype = "front",
        water_damage = 0,
        lava_damage = 5,
        light_damage = 0,
        fear_height = 2,
        on_rightclick = nil,
    },
    zygon = {
        -- Placeholder definition; customize as needed
        physical = true,
        stepheight = 1.0,
        collisionbox = {-0.5, -0.01, -0.5, 0.5, 1.5, 0.5},
        visual = "mesh",
        visual_size = {x=12, y=12},
        mesh = "zygon.b3d",
        textures = {"creature_zygon.png"},
        makes_footstep_sound = true,
        view_range = 20,
        walk_velocity = 2,
        run_velocity = 3,
        damage = 3,
        drops = {"farming:alien_meat 2"},
        armor = 220,
        drawtype = "front",
        water_damage = 1,
        lava_damage = 0,
        light_damage = 5,
        fear_height = 2,
        on_rightclick = nil,
    },
    badger = {
        -- Placeholder definition; customize as needed
        physical = true,
        stepheight = 0.6,
        collisionbox = {-0.3, -0.01, -0.3, 0.3, 0.45, 0.3},
        visual = "mesh",
        visual_size = {x=9, y=9},
        mesh = "badger.b3d",
        textures = {"creature_badger.png"},
        makes_footstep_sound = true,
        view_range = 12,
        walk_velocity = 1.8,
        run_velocity = 2.8,
        damage = 2,
        drops = {"farming:meat_raw 2"},
        armor = 190,
        drawtype = "front",
        water_damage = 1,
        lava_damage = 5,
        light_damage = 0,
        fear_height = 2,
        on_rightclick = nil,
    },
    lava_ox = {
        -- Placeholder definition; customize as needed
        physical = true,
        stepheight = 1.1,
        collisionbox = {-0.55, -0.01, -0.55, 0.55, 1.6, 0.55},
        visual = "mesh",
        visual_size = {x=18, y=18},
        mesh = "lava_ox.b3d",
        textures = {"creature_lava_ox.png"},
        makes_footstep_sound = true,
        view_range = 8,
        walk_velocity = 0.8,
        run_velocity = 1.5,
        damage = 4,
        drops = {"farming:meat_raw 5"},
        armor = 300,
        drawtype = "front",
        water_damage = 5,
        lava_damage = 0,
        light_damage = 0,
        fear_height = 2,
        on_rightclick = nil,
    },
    chaos_hawk = {
        -- Placeholder definition; customize as needed
        physical = true,
        stepheight = 1.0,
        collisionbox = {-0.35, -0.01, -0.35, 0.35, 0.8, 0.35},
        visual = "mesh",
        visual_size = {x=9, y=9},
        mesh = "chaos_hawk.b3d",
        textures = {"creature_chaos_hawk.png"},
        makes_footstep_sound = true,
        view_range = 25,
        walk_velocity = 3,
        run_velocity = 5,
        damage = 3,
        drops = {"farming:meat_raw 2"},
        armor = 180,
        drawtype = "front",
        water_damage = 0,
        lava_damage = 7,
        light_damage = 0,
        fear_height = 3,
        on_rightclick = nil,
    },
    ogre = {
        -- Placeholder definition; customize as needed
        physical = true,
        stepheight = 1.0,
        collisionbox = {-0.7, -0.01, -0.7, 0.7, 2.5, 0.7},
        visual = "mesh",
        visual_size = {x=20, y=20},
        mesh = "ogre.b3d",
        textures = {"creature_ogre.png"},
        makes_footstep_sound = true,
        view_range = 20,
        walk_velocity = 1.5,
        run_velocity = 2.5,
        damage = 6,
        drops = {"farming:meat_raw 6"},
        armor = 300,
        drawtype = "front",
        water_damage = 2,
        lava_damage = 3,
        light_damage = 0,
        fear_height = 2,
        on_rightclick = nil,
    },
    snagon = {
        -- Placeholder definition; customize as needed
        physical = true,
        stepheight = 2.0,
        collisionbox = {-1.0, -0.01, -1.0, 1.0, 2.0, 1.0},
        visual = "mesh",
        visual_size = {x=25, y=25},
        mesh = "snagon.b3d",
        textures = {"creature_snagon.png"},
        makes_footstep_sound = true,
        view_range = 30,
        walk_velocity = 4,
        run_velocity = 6,
        damage = 8,
        drops = {"farming:meat_raw 8"},
        armor = 350,
        drawtype = "front",
        water_damage = 3,
        lava_damage = 2,
        light_damage = 0,
        fear_height = 4,
        on_rightclick = nil,
    },
    giant_moth = {
        -- Placeholder definition; customize as needed
        physical = true,
        stepheight = 1.0,
        collisionbox = {-0.5, -0.01, -0.5, 0.5, 1.0, 0.5},
        visual = "mesh",
        visual_size = {x=15, y=15},
        mesh = "giant_moth.b3d",
        textures = {"creature_giant_moth.png"},
        makes_footstep_sound = true,
        view_range = 12,
        walk_velocity = 3,
        run_velocity = 5,
        damage = 2,
        drops = {"farming:meat_raw 2"},
        armor = 200,
        drawtype = "front",
        water_damage = 1,
        lava_damage = 10,
        light_damage = 0,
        fear_height = 2,
        on_rightclick = nil,
    },
    skipping_fungus = {
        -- Placeholder definition; customize as needed
        physical = true,
        stepheight = 0.5,
        collisionbox = {-0.25, -0.01, -0.25, 0.25, 0.35, 0.25},
        visual = "cube",
        visual_size = {x=5, y=5},
        tiles = {"creature_skipping_fungus.png"},
        makes_footstep_sound = true,
        view_range = 5,
        walk_velocity = 1,
        run_velocity = 1.5,
        damage = 0,
        drops = {"farming:mushroom 2"},
        armor = 100,
        drawtype = "front",
        water_damage = 0,
        lava_damage = 5,
        light_damage = 0,
        fear_height = 1,
        on_rightclick = nil,
    },
    frost_mephit = {
        -- Placeholder definition; customize as needed
        physical = true,
        stepheight = 1.0,
        collisionbox = {-0.3, -0.01, -0.3, 0.3, 0.7, 0.3},
        visual = "mesh",
        visual_size = {x=10, y=10},
        mesh = "frost_mephit.b3d",
        textures = {"creature_frost_mephit.png"},
        makes_footstep_sound = true,
        view_range = 15,
        walk_velocity = 2,
        run_velocity = 3.5,
        damage = 3,
        drops = {"farming:ice_crystal 2"},
        armor = 160,
        drawtype = "front",
        water_damage = 0,
        lava_damage = 9,
        light_damage = 0,
        fear_height = 2,
        on_rightclick = nil,
    },
    sand_slug = {
        -- Placeholder definition; customize as needed
        physical = true,
        stepheight = 0.0,
        collisionbox = {-0.2, -0.01, -0.2, 0.2, 0.15, 0.2},
        visual = "cube",
        visual_size = {x=4, y=4},
        tiles = {"creature_sand_slug.png"},
        makes_footstep_sound = true,
        view_range = 7,
        walk_velocity = 0.5,
        run_velocity = 0.7,
        damage = 0,
        drops = {"farming:sand_particle 2"},
        armor = 100,
        drawtype = "front",
        water_damage = 1,
        lava_damage = 10,
        light_damage = 0,
        fear_height = 1,
        on_rightclick = nil,
    },
    -- Add more creature definitions here...
}

local pulse_blossom_definition = {
    physical = false,
    visual = "sprite",
    visual_size = {x = 1.0, y = 1.0},
    textures = {"basenodes_pulse_blossom.png"},
    collisionbox = {0,0,0,0,0,0},
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal = 1})
        minetest.get_node_timer(self.object:get_pos()):start(10)
    end,
    on_timer = function(self, elapsed)
        minetest.add_particle({
            pos = self.object:get_pos(),
            expirationtime = 2.0,
            texture = "basenodes_pulse_blossom_glow.png",
            size = 8,
            glow = 14 
        })
        minetest.after(2, function(pos)
            local objs = minetest.get_objects_inside_radius(pos, 2) -- 2 is the radius
            for _, obj in ipairs(objs) do
                if obj:is_player() or obj:get_luaentity() then 
                    obj:punch(obj, 1.0, {
                        full_punch_interval = 1.0,
                        damage_groups = {fleshy = 2}, -- might adjust the damage
                    })
                end
            end
            minetest.get_node_timer(pos):start(10)
        end, self.object:get_pos())

        return true
    end,
}

minetest.register_entity("main:pulse_blossom",{on_step = function(self, dtime)
    self.timer = self.timer or 0
    self.timer = self.timer + dtime
    if self.timer >= 10 then
        self.timer = 0
        -- Start glow
        self.object:settexturemod("^[brighten")
        -- Create the damage timer
        minetest.after(2, function(self)
            if self.object then
                -- Damage entities
                local pos = self.object:get_pos()
                local objects = minetest.get_objects_inside_radius(pos, 1) -- 1 is the damage radius
                for _, obj in ipairs(objects) do
                    local entity = obj:get_luaentity()
                    if entity and entity.name ~= "__builtin:item" and entity.name ~= "main:pulse_blossom" or obj:is_player() then
                        local damage = 2 -- damage value
                        obj:set_hp(obj:get_hp() - damage)
                    end
                end
                -- End glow
                self.object:settexturemod("")
            end
        end, self)
    end
end})

for name, def in pairs(creature_definitions) do
    minetest.register_entity("main:" .. name, def)
end


