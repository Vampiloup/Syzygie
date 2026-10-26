-- ui.hud.lua
local events    =              require("core.events")
local couches   =              require("core.couches")
local couches_z =              require("core.couches_z")
local i18n =                   require("core.i18n")


local MARGIN = 24
local ESPACE = 12


-- ancre = coin de départ ; dir = sens de la file
local groupes = {
  { ancre = "bas-gauche", dir = "droite", boutons = {
      { id = "empire",           w = 120, h = 40 },
      { id = "science",          w = 120, h = 40 },
      { id = "diplomatie",       w = 120, h = 40 },
      { id = "economie",         w = 120, h = 40 },
  }},
  { ancre = "haut-droite", dir = "gauche", boutons = {
      { id = "reglages",         w = 120, h = 40 },
  }},
  { ancre = "bas-droite", dir = "gauche", boutons = {
      { id = "appel_tour",       w = 160, h = 48 },
  }},
--    { ancre = "centre", dir = "bas", boutons = {
--    { id = "nouvelle_partie",  w = 240, h = 48 },
--    { id = "options",          w = 240, h = 48 },
--    { id = "quitter",          w = 240, h = 48 },
--  }},
}

-- (ax, ay) : 0 = gauche/haut, 1 = droite/bas
local ANCRES = {
  ["haut-gauche"] = {0, 0}, ["haut-droite"] = {1, 0},
  ["bas-gauche"]  = {0, 1}, ["bas-droite"]  = {1, 1},
  ["centre"] = {0.5, 0.5},
}
local DIRS = {
  droite = {1, 0}, gauche = {-1, 0}, bas = {0, 1}, haut = {0, -1},
}

-- liste à plat pour le survol, le clic et le dessin
local tous = {}
for _, g in ipairs(groupes) do
  assert(ANCRES[g.ancre], "ancre inconnue : " .. tostring(g.ancre))
  assert(DIRS[g.dir],     "direction inconnue : " .. tostring(g.dir))
  for _, b in ipairs(g.boutons) do
    tous[#tous + 1] = b
    b.cle = "hud_general." .. b.id
  end
end



-- placement : ancré en bas à gauche, dans les bornes réelles de la fenêtre
local function place(left, top, right, bottom)
  local W, H = right - left, bottom - top

  for _, g in ipairs(groupes) do
    local ax, ay = unpack(ANCRES[g.ancre])
    local dx, dy = unpack(DIRS[g.dir])
    local liste  = g.boutons

    local gw, gh = 0, 0
    for i, b in ipairs(liste) do
      local esp = (i > 1) and ESPACE or 0
      if dx ~= 0 then gw = gw + b.w + esp; gh = math.max(gh, b.h)
      else            gh = gh + b.h + esp; gw = math.max(gw, b.w) end
    end

    local x = left + MARGIN + (W - 2 * MARGIN - gw) * ax
    local y = top  + MARGIN + (H - 2 * MARGIN - gh) * ay

    local debut, fin, pas = 1, #liste, 1
    if dx < 0 or dy < 0 then debut, fin, pas = #liste, 1, -1 end

    for i = debut, fin, pas do
      local b = liste[i]
      if dx ~= 0 then
        b.x = x
        b.y = y + (gh - b.h) * ay          -- alignement perpendiculaire selon l'ancre
        x = x + b.w + ESPACE
      else
        b.y = y
        b.x = x + (gw - b.w) * ax
        y = y + b.h + ESPACE
      end
    end
  end
end
events.on("resize", place)

local function trouver(px, py)
  for _, b in ipairs(tous) do
    if px >= b.x and px <= b.x + b.w and py >= b.y and py <= b.y + b.h then
      return b
    end
  end
end

local survol, enfonce = nil, nil

couches.add({
  z = couches_z.HUD,

  -- uniquement sur les boutons, pas sur toute la barre
  contient = function(px, py) return trouver(px, py) ~= nil end,

  draw = function()
    for _, b in ipairs(tous) do
      local c = (b == enfonce) and 0.35 or (b == survol) and 0.25 or 0.15
      love.graphics.setColor(c, c, c + 0.05, 0.9)
      love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 8, 8)
      love.graphics.setColor(1, 1, 1)
      local font = love.graphics.getFont()
      local ty = b.y + (b.h - font:getHeight()) / 2
      local reponse = i18n.t(b.cle)
      love.graphics.printf(reponse, b.x, ty, b.w, "center")
    end
  end,

  onpress   = function(x, y, button)
    if button == 1 then enfonce = trouver(x, y) end
  end,

  onrelease = function(x, y, button)
    if button ~= 1 then return end
    local b = trouver(x, y)
    if b and b == enfonce then events.emit("hud_bouton", b.id) end   -- clic valide : press et release sur le même bouton
    enfonce = nil
  end,

  onmove = function(x, y) survol = trouver(x, y) end,
  onleave = function() survol = nil end,
})
