local game_prep = {
            default = {                                                         -- Defaults
                map_form = 3,
                map_size = 3,
                map_density = 3
            },
            map_form = {                                                        -- Form of the starfield (game world)
                {nom = "Square"},
                {nom = "Disc with dense center"},
                {nom = "Disc with uniform density"},
                {nom = "Ring very large"},
                {nom = "Ring large"},
                {nom = "Ring thin"},
                {nom = "Ring very thin"}
            },
            map_size = {                                                        -- Size of the starfield
                {nom = "minuscule", map_X = 1250, map_Y = 1250},
                {nom = "petite", map_X = 1875, map_Y = 1875},
                {nom = "medium", map_X = 2500, map_Y = 2500},
                {nom = "grande", map_X = 3125, map_Y = 3125},
                {nom = "geante", map_X = 4375, map_Y = 4375},
                {nom = "immense", map_X = 6250, map_Y = 6250}
            },
            map_density = {                                                     -- Density of Systems
                {nom = "épars", density = 0.5},
                {nom = "clairsemé", density = 0.75},
                {nom = "medium", density = 1},
                {nom = "dense", density = 1.5},
                {nom = "compact", density = 1.2}
            },
            starfield = {
      --          type_etoile = {"etoile_rouge","etoile_orange","etoile_jaune", "etoile_blanc", "etoile_cyan", "etoile_bleu", "etoile_violet"}
                type_etoile_lointain    = {"etoile_lointain_rouge","etoile_lointain_orange","etoile_lointain_jaune", "etoile_lointain_blanc", "etoile_lointain_cyan"},
                type_etoile_proche      = {"etoile_proche_rouge","etoile_proche_orange","etoile_proche_jaune", "etoile_proche_blanc", "etoile_proche_cyan"},
                orbitals                = {
                    chance                  = {20, 30, 25 ,25, 11},
                    type                    = {"", "rock_planet", "ice_giant" ,"gaz_giant", "asteroids"}
                }
            }
}

langue = {
        starfield = {
            orbital = {"vide", "planète rocheuse", "géante glacée" ,"géante gazeuse", "asteroides"}
        }
}


function game_prep.load()

end

function game_prep.update(dt)

end

function game_prep.draw()

end

return game_prep
