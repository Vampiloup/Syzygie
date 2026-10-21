-- core/exclusif.lua
local M = {}
local actifs = {}   -- groupe -> fonction close du panneau actuellement ouvert

-- À appeler dans open() : ferme l'éventuel occupant du groupe, puis s'inscrit
function M.prendre(groupe, close)
  local ancien = actifs[groupe]
  if ancien and ancien ~= close then ancien() end
  actifs[groupe] = close
end

-- À appeler dans close() : libère la place si c'est bien ce panneau
function M.liberer(groupe, close)
  if actifs[groupe] == close then actifs[groupe] = nil end
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
