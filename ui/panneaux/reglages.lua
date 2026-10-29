-- ui.panneaux.reglages

local events  =                 require("core.events")
local panneau =                 require("ui.widgets.panneau")
local i18n =                    require("core.i18n")
local exclusif     =            require("core.exclusif")
local registre  =               require("core.registre")


local ID = "reglages"
local CLE = "hud_"..ID

-- MODIF H : plus de "boutons = {...}" ici : le bouton "sortie_jeu" est décrit dans
-- le registre (hud_bouton_panneau). Ce fichier ne garde que ce qui est du code :
-- ce que FAIT le bouton (voir "actions" plus bas).
local P = panneau.new({
  id = ID, preset = "reglages",
  draw    = function(p)
    local texte =i18n.t( CLE..".titre")
    love.graphics.print(texte, p.x + 16, p.y + 16)
  end,
  onclick = function(x, y, b) if b == 1 then print("Clic dans le panneau Réglages") end end,
})

events.on("hud_bouton", function(id) if id == ID then P.toggle() end end)

-- MODIF H : table "id du bouton -> ce qu'il fait". Pour ajouter un bouton à ce panneau :
-- 1) l'ajouter dans hud_bouton_panneau (JSON), 2) ajouter ici une ligne avec son id.
local actions = {
  reglages_sortie_jeu = function() love.event.quit() end,
}

-- Appelé à chaque clic validé sur un bouton de N'IMPORTE QUEL panneau :
-- on ignore ceux qui ne concernent pas celui-ci.
events.on("panneau_bouton", function(panneau_id, id)
  if panneau_id ~= ID then return end
  local action = actions[id] or error("panneau '" .. ID .. "' : aucune action pour le bouton '" .. tostring(id) .. "'")
  if action then action() end
end)

return P
