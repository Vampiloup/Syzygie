-- ui.widgets.panneau.lua
--
-- MODIF H : les boutons internes d'un panneau ne sont plus passés en code (def.boutons)
-- mais lus dans le registre (catégorie "hud_bouton_panneau"), via M.init().

local events    =               require("core.events")
local exclusif  =               require("core.exclusif")
local screen    =               require("affichage.ecran")
local couches   =               require("core.couches")
local couches_z =               require("core.couches_z")
local registre  =               require("core.registre")
local fermer    =               require("ui.widgets.fermer")
local bouton    =               require("ui.widgets.bouton")



local function preset()
  return registre.get("hud_panneau", "general")
end

local AXE_X = {
  gauche = function(p, l, r) return l + preset().margin_x end,
  centre = function(p, l, r) return math.floor((l + r - p.w) / 2) end,
  droite = function(p, l, r) return r - p.w - preset().margin_x end,
}
local AXE_Y = {
  haut   = function(p, t, b) return t + preset().margin_y end,
  centre = function(p, t, b) return math.floor((t + b - p.h) / 2) end,
  bas    = function(p, t, b) return b - p.h - preset().margin_y end,
}

local M = {}

-- MODIF H : les panneaux sont créés (M.new) quand leur module est chargé par "require",
-- donc AVANT mods.charger() : le registre est encore vide à ce moment-là.
-- Chaque panneau dépose donc ici une fonction qui construira ses boutons plus tard,
-- et M.init() les appelle toutes une fois le registre rempli.
local constructeurs = {}     -- constructeurs[id_du_panneau] = function(liste_de_boutons)
local initialise = false

function M.new(def)
  local panel  = { w = def.w, h = def.h }
  local groupe = def.groupe or "panneaux_jeu"
  local ouvert, item, touche = false, nil, nil
  local close
  local P = { panel = panel }

  local btn = fermer.new(panel, function() close() end)

  -- MODIF H : plus de def.boutons. Si un panneau l'utilise encore, on le dit clairement.
  if def.boutons ~= nil then
    error("panneau '" .. tostring(def.id) .. "' : 'boutons' n'est plus supporté, " ..
          "déclarer les boutons dans hud_bouton_panneau (registre)", 2)
  end

  -- boutons internes : remplis par M.init() à partir du registre
  local widgets = {}

  -- MODIF H : seuls les panneaux qui ont un id peuvent avoir des boutons
  -- (l'id est ce qui les relie aux entrées du registre).
  if def.id then
    constructeurs[def.id] = function(liste)
      for _, bd in ipairs(liste) do
        -- Le clic est signalé à tout le monde par un événement : le module du panneau
        -- (par exemple reglages.lua) l'écoute et décide quoi faire.
        bd.action = function(id) events.emit("panneau_bouton", def.id, id) end
        widgets[#widgets + 1] = bouton.new(panel, bd)
      end
    end
  end

  local function place(l, t, r, b)
    local pr = def.preset and registre.get("hud_panneau", def.preset)
    panel.w = panel.w or pr.largeur
    panel.h = panel.h or pr.hauteur
    local ax = AXE_X[(pr and pr.ancrage_x) or def.ancrage_x or "droite"]
    local ay = AXE_Y[(pr and pr.ancrage_y) or def.ancrage_y or "haut"]
    panel.x = screen.snap(ax(panel, l, r))
    panel.y = screen.snap(ay(panel, t, b))
  end

  local function inside(x, y)
    return x >= panel.x and x <= panel.x + panel.w
       and y >= panel.y and y <= panel.y + panel.h
  end

  local function onDraw()
    if def.fond ~= false then
      love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
      love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 12, 12)
      love.graphics.setColor(1, 1, 1)
    end
    if def.draw then def.draw(panel) end
    for _, w in ipairs(widgets) do w.draw() end
    btn.draw()
  end

  local function onPress(x, y, b)
    if btn.press(x, y, b) then return end
    for _, w in ipairs(widgets) do
      if w.press(x, y, b) then return end
    end
    if def.onclick then def.onclick(x, y, b) end
  end
  local function onRelease(x, y, b)
    if btn.release(x, y, b) then return end
    for _, w in ipairs(widgets) do
      if w.release(x, y, b) then return end
    end
    if def.onrelease then def.onrelease(x, y, b) end
  end
  local function onMove(x, y, dx, dy)
    btn.move(x, y)
    for _, w in ipairs(widgets) do w.move(x, y) end   -- pas de court-circuit : le survol doit se mettre à jour partout
    if def.onmove then def.onmove(x, y, dx, dy) end
  end
  local function onLeave()
    btn.leave()
    for _, w in ipairs(widgets) do w.leave() end
    if def.onleave then def.onleave() end
  end
  local function onKey(key, sc, rep)
    if key == "x" then close() return end
    if def.onkey then def.onkey(key, sc, rep) end
  end

  local function open()
    if ouvert then return end
    -- MODIF H : garde-fou. Sans init(), le panneau s'ouvrirait SANS ses boutons,
    -- sans aucun message : on préfère une erreur explicite.
    if not initialise then
      error("panneau.init() n'a pas été appelée (à faire dans love.load, après mods.charger)")
    end
    exclusif.prendre(groupe, close)
    ouvert = true
    place(screen.bounds())
    events.on("keypressed", onKey)
    events.on("resize", place)

    local it = {
      z = def.z or couches_z.PANNEAUX, contient = inside,
      onpress = onPress, onrelease = onRelease,
      onmove = onMove, onleave = onLeave, draw = onDraw,
    }
    for k, v in pairs(def.extra or {}) do it[k] = v end
    item = couches.add(it)
    if def.on_open then def.on_open() end
  end

  function close()
    if not ouvert then return end
    ouvert = false
    onLeave()   -- remet à zéro survol/enfoncé du bouton fermer ET des boutons internes
    exclusif.liberer(groupe, close)
    events.off("keypressed", onKey)
    events.off("resize", place)
    couches.remove(item)
    item = nil
    if def.on_close then def.on_close() end
  end

  P.open, P.close = open, close
  P.toggle  = function() if ouvert then close() else open() end end
  P.is_open = function() return ouvert end

  if def.id then
    events.on("keypressed", function(key)
      touche = touche or registre.get_field("panneau_hub", def.id, "touche")
      if key ~= touche then return end
      if ouvert then close()
      else
        if def.pre_touche then def.pre_touche() end
        open()
      end
    end)
  end

  return P
end


-- MODIF H : lecture et validation des boutons de panneau, puis construction des widgets.
-- À appeler UNE fois, depuis love.load(), APRÈS mods.charger() et APRÈS le chargement
-- (require) de tous les modules de panneaux.
function M.init()
  if initialise then error("panneau.init() ne doit être appelée qu'une seule fois") end
  initialise = true

  -- Valeurs par défaut (entrée "general"), comme pour hud_bouton.
  local defauts = registre.get("hud_bouton_panneau", "general")
  for _, champ in ipairs({ "w", "h" }) do
    if type(defauts[champ]) ~= "number" then
      error("hud_bouton_panneau 'general' : le champ '" .. champ .. "' est manquant ou n'est pas un nombre")
    end
  end

  local par_panneau = {}   -- par_panneau[id_du_panneau] = liste de définitions validées
  for _, bd in ipairs(registre.list("hud_bouton_panneau")) do
    if bd.id ~= "general" then

      -- Le panneau cité doit exister : détecte les fautes de frappe dans le JSON.
      local pid = bd.panneau
      if type(pid) ~= "string" or not constructeurs[pid] then
        error("hud_bouton_panneau '" .. bd.id .. "' : panneau inconnu : " .. tostring(pid))
      end

      -- Ancrage : obligatoire (comme pour hud_groupe). Les VALEURS (gauche, haut...)
      -- sont vérifiées par bouton.lua au moment de la création.
      for _, champ in ipairs({ "ancrage_x", "ancrage_y" }) do
        if type(bd[champ]) ~= "string" then
          error("hud_bouton_panneau '" .. bd.id .. "' : le champ '" .. champ ..
                "' est manquant ou n'est pas un texte")
        end
      end

      local w, h = bd.w or defauts.w, bd.h or defauts.h
      if type(w) ~= "number" or type(h) ~= "number" or w <= 0 or h <= 0 then
        error("hud_bouton_panneau '" .. bd.id .. "' : w et h doivent être des nombres positifs")
      end

      -- x et y (décalage depuis l'ancrage) sont optionnels : nil = 0.
      for _, champ in ipairs({ "x", "y" }) do
        if bd[champ] ~= nil and type(bd[champ]) ~= "number" then
          error("hud_bouton_panneau '" .. bd.id .. "' : '" .. champ .. "' doit être un nombre")
        end
      end

      par_panneau[pid] = par_panneau[pid] or {}
      local liste = par_panneau[pid]
      liste[#liste + 1] = {
        id = bd.id, w = w, h = h, x = bd.x, y = bd.y,
        ancrage_x = bd.ancrage_x, ancrage_y = bd.ancrage_y,
        -- clé i18n construite comme avant : "hud_<panneau>.<bouton>"
        -- (par exemple hud_reglages.sortie_jeu : les fichiers de langue ne changent pas).
        cle = "hud_" .. pid .. "." .. bd.id,
      }
    end
  end

  -- Chaque panneau construit ses widgets avec sa liste (vide s'il n'a aucun bouton).
  for pid, construire in pairs(constructeurs) do
    construire(par_panneau[pid] or {})
  end
end

return M
