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
      { id = "empire",     label = "Empire",     w = 120, h = 40 },
      { id = "science",    label = "Science",    w = 120, h = 40 },
      { id = "diplomatie", label = "Diplomatie", w = 120, h = 40 },
      { id = "economie",   label = "Économie",   w = 120, h = 40 },
  }},
  { ancre = "haut-droite", dir = "gauche", boutons = {
      { id = "reglages", label = "Réglages", w = 120, h = 40 },
  }},
  { ancre = "bas-droite", dir = "gauche", boutons = {
      { id = "appel_tour", label = "Fin du tour", w = 160, h = 48 },
  }},
}

-- (ax, ay) : 0 = gauche/haut, 1 = droite/bas
local ANCRES = {
  ["haut-gauche"] = {0, 0}, ["haut-droite"] = {1, 0},
  ["bas-gauche"]  = {0, 1}, ["bas-droite"]  = {1, 1},
}
local DIRS = {
  droite = {1, 0}, gauche = {-1, 0}, bas = {0, 1}, haut = {0, -1},
}

-- liste à plat pour le survol, le clic et le dessin
local tous = {}
for _, g in ipairs(groupes) do
  assert(ANCRES[g.ancre], "ancre inconnue : " .. tostring(g.ancre))
  assert(DIRS[g.dir],     "direction inconnue : " .. tostring(g.dir))
  for _, b in ipairs(g.boutons) do tous[#tous + 1] = b end
end



-- placement : ancré en bas à gauche, dans les bornes réelles de la fenêtre
local function place(left, top, right, bottom)
  for _, g in ipairs(groupes) do
    local ax, ay = unpack(ANCRES[g.ancre])   -- LÖVE = LuaJIT : unpack global OK
    local dx, dy = unpack(DIRS[g.dir])

    local cx = (ax == 0) and left + MARGIN or right  - MARGIN
    local cy = (ay == 0) and top  + MARGIN or bottom - MARGIN

    for _, b in ipairs(g.boutons) do
      if dx ~= 0 then
        -- file horizontale : x suit la direction, y suit l'ancre
        if dx > 0 then b.x = cx;        cx = cx + b.w + ESPACE
        else           b.x = cx - b.w;  cx = b.x - ESPACE end
        b.y = (ay == 0) and cy or cy - b.h
      else
        -- file verticale : y suit la direction, x suit l'ancre
        if dy > 0 then b.y = cy;        cy = cy + b.h + ESPACE
        else           b.y = cy - b.h;  cy = b.y - ESPACE end
        b.x = (ax == 0) and cx or cx - b.w
      end
      b.cle = "hud_general." .. b.id
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
