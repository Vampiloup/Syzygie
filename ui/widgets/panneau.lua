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

function M.new(def)
  local panel  = { w = def.w, h = def.h }
  local groupe = def.groupe or "panneaux_jeu"
  local ouvert, item, touche = false, nil, nil
  local close
  local P = { panel = panel }

  local btn = fermer.new(panel, function() close() end)

  -- boutons internes : def.boutons = { {x=, y=, w=, h=, ancre=, cle=, action=}, ... }
  local widgets = {}
  for _, bd in ipairs(def.boutons or {}) do
    widgets[#widgets + 1] = bouton.new(panel, bd)
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

return M
