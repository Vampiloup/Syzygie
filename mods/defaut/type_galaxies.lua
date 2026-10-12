return {
    galaxy_form = {
        { id = "square",          nom = "Square" },
        { id = "disc_dense",      nom = "Disc with dense center" },
        { id = "disc_uniform",    nom = "Disc with uniform density" },
        { id = "ring_very_large", nom = "Ring very large" },
        { id = "ring_large",      nom = "Ring large" },
        { id = "ring_thin",       nom = "Ring thin" },
        { id = "ring_very_thin",  nom = "Ring very thin" },
  },
    galaxy_size = {
        { id = "minuscule",       nom = "minuscule", map_X = 1250, map_Y = 1250 },
        { id = "petite",          nom = "petite",    map_X = 1875, map_Y = 1875 },
        { id = "medium",          nom = "medium",    map_X = 2500, map_Y = 2500 },
        { id = "grande",          nom = "grande",    map_X = 3125, map_Y = 3125 },
        { id = "geante",          nom = "geante",    map_X = 4375, map_Y = 4375 },
        { id = "immense",         nom = "immense",   map_X = 6250, map_Y = 6250 },
  },
    galaxy_density = {
        { id = "epars",           nom = "épars",      density = 0.5 },
        { id = "clairseme",       nom = "clairsemé",  density = 0.75 },
        { id = "medium",          nom = "medium",     density = 1 },
        { id = "dense",           nom = "dense",      density = 1.5 },
        { id = "compact",         nom = "compact",    density = 2 },
  },
    galaxy_defaults = {
        { id = "standard", map_form = "defaut:disc_uniform", map_size = "defaut:medium", map_density = "defaut:medium" },
  }
}
