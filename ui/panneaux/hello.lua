
-- ui/panneaux/hello.lua
local events       = require("core.events")
local screen       = require("affichage.ecran")
local couches      = require("core.couches")
local couches_z    = require("core.couches_z")

local M = {}
local MARGIN = 24
local panel = { w = 360, h = 220 }
local ouvert = false
local item

local close          -- déclaration anticipée : onKey en a besoin avant sa définition

local function place(left, top, right, bottom)
  panel.x = right - panel.w - MARGIN
  panel.y = top + MARGIN
end

local function inside(x, y)
  return x >= panel.x and x <= panel.x + panel.w
     and y >= panel.y and y <= panel.y + panel.h
end

local function onDraw()
  love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
  love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 12, 12)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Hello", panel.x + 16, panel.y + 16)
end

local function onClick(x, y, button)
  if button == 1 then print("Clic dans le panneau Hello") end
  -- inutile de retester inside() : pick l'a déjà fait
end

local function onKey(key, scancode, isrepeat)
  if key == "o" then print("Touche 'o' reçue !") end
  if key == "x" then close() end      -- close sera assignée plus bas
end

local function open()
  if ouvert then return end
  ouvert = true
  place(screen.bounds())
  events.on("keypressed", onKey)
  events.on("resize", place)

  item = couches.add({
    z = couches_z.PANNEAUX,
    contient = inside,
    onpress = onClick,
    draw = onDraw,                  -- remplace events.on("draw_ui", onDraw)
  })

end

function close()
  if not ouvert then return end
  ouvert = false
  events.off("keypressed", onKey)
  events.off("resize", place)
  couches.remove(item)
  item = nil
end

M.open = open
M.close = close
M.is_open = function() return ouvert end

return M
