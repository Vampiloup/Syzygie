-- ui.hud.lua
local events    = require("core.events")
local couches   = require("core.couches")
local couches_z = require("core.couches_z")

local boutons = {
  { id = "empire", label = "Empire", w = 120, h = 40 },
  { id = "science",  label = "Science",  w = 120, h = 40 },
  { id = "diplomatie",  label = "Diplomatie",  w = 120, h = 40 },
}

local MARGIN = 24
local ESPACE = 12

-- placement : ancré en bas à gauche, dans les bornes réelles de la fenêtre
local function place(left, top, right, bottom)
  local x = left + MARGIN
  for _, b in ipairs(boutons) do
    b.x = x
    b.y = bottom - MARGIN - b.h
    x = x + b.w + ESPACE
  end
end
events.on("resize", place)

local function trouver(px, py)
  for _, b in ipairs(boutons) do
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
    for _, b in ipairs(boutons) do
      local c = (b == enfonce) and 0.35 or (b == survol) and 0.25 or 0.15
      love.graphics.setColor(c, c, c + 0.05, 0.9)
      love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 8, 8)
      love.graphics.setColor(1, 1, 1)
      love.graphics.print(b.label, b.x + 12, b.y + 12)
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
