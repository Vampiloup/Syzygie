return {
  id          = "defaut",
  nom         = "mod.defaut.nom",          -- clé de traduction
  description = "mod.defaut.description",  -- idem
  version     = "0.1.0",
  auteur      = "Chocolemur",
  licence     = "Apache-2.0",

  api_version = 1,                         -- version du « contrat » entre le jeu et les mods
  requiert    = {},                        -- ids des mods nécessaires, ex. { "defaut" }

  donnees = {                              -- fichiers à exécuter, dans cet ordre
    "type_galaxies.lua",
    "type_etoiles.lua",
    "type_orbitales.lua",
  },
  langues = { "fr", "en" },                -- langues fournies (dossier langues/)
}
