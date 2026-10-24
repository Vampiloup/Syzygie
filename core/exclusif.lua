-- core.exclusif.lua

local M = {}
local actifs = {}   -- groupe -> fonction close du panneau ouvert

function M.prendre(groupe, close)
  local ancien = actifs[groupe]
  if ancien and ancien ~= close then ancien() end
  actifs[groupe] = close
end

function M.liberer(groupe, close)
  if actifs[groupe] == close then actifs[groupe] = nil end
end

-- ferme tous les panneaux ouverts ; renvoie true si au moins un l'était
function M.fermer_tout()
  local ferme = false
  for _, close in pairs(actifs) do
    close()            -- close appelle liberer : mettre un champ à nil pendant pairs est permis
    ferme = true
  end
  return ferme
end

return M

-- Usage dans un panneau (ex. economie.lua) :

-- local exclusif = require("core.exclusif")
-- local GROUPE = "panneaux_jeu"
--
-- local function open()
--  if ouvert then return end
--  exclusif.prendre(GROUPE, close)     -- ferme Science s'il est ouvert
--  ouvert = true
--  -- ... le reste inchangé
--end
--
--function close()
--  if not ouvert then return end
--  ouvert = false
--  exclusif.liberer(GROUPE, close)
--  -- ... le reste inchangé
--end
