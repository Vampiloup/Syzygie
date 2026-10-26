local events    = require("core.events")
local exclusif  = require("core.exclusif")
local screen    = require("affichage.ecran")
local couches   = require("core.couches")
local couches_z = require("core.couches_z")
local registre  = require("core.registre")
local fermer    = require("ui.widgets.fermer")

local MARGIN_X = 24
local MARGIN_Y = 72
local AXE_X = {
  gauche = function(p, l, r) return l + MARGIN_X end,
  centre = function(p, l, r) return math.floor((l + r - p.w) / 2) end,
  droite = function(p, l, r) return r - p.w - MARGIN_X end,
}
local AXE_Y = {
  haut   = function(p, t, b) return t + MARGIN_Y end,
  centre = function(p, t, b) return math.floor((t + b - p.h) / 2) end,
  bas    = function(p, t, b) return b - p.h - MARGIN_Y end,
}

local M = {}

function M.new(def)
  local panel  = { w = def.w, h = def.h }
  local groupe = def.groupe or "panneaux_jeu"
  local ouvert, item, touche = false, nil, nil
  local close
  local P = { panel = panel }

  local btn = fermer.new(panel, function() close() end)

  local ax = assert(AXE_X[def.ancrage_x or "droite"], "ancrage_x invalide pour '" .. tostring(def.id) .. "' : " .. tostring(def.ancrage_x))
  local ay = assert(AXE_Y[def.ancrage_y or "haut"],   "ancrage_y invalide pour '" .. tostring(def.id) .. "' : " .. tostring(def.ancrage_y))
  local function place(l, t, r, b)
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
    btn.draw()
  end

  local function onPress(x, y, b)
    if btn.press(x, y, b) then return end
    if def.onclick then def.onclick(x, y, b) end
  end
  local function onRelease(x, y, b)
    if btn.release(x, y, b) then return end
    if def.onrelease then def.onrelease(x, y, b) end
  end
  local function onMove(x, y, dx, dy)
    btn.move(x, y)
    if def.onmove then def.onmove(x, y, dx, dy) end
  end
  local function onLeave()
    btn.leave()
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
    btn.leave()
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
