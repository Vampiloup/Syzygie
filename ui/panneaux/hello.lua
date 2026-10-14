-- ui/panneaux/hello.lua
local events = require("core.events")
local M = {}

local MARGIN = 24
local panel = { w = 360, h = 220 }   -- ancré en haut à droite

local function place(left, top, right, bottom)
  panel.x = right - panel.w - MARGIN
  panel.y = top + MARGIN
end

local function inside(x, y)
  return x >= panel.x and x <= panel.x + panel.w
     and y >= panel.y and y <= panel.y + panel.h
end

events.on("resize", place)

events.on("draw_ui", function()
  love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
  love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 12, 12)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Hello", panel.x + 16, panel.y + 16)   -- coordonnées locales au panneau
end)

events.on("mousepressed", function(x, y, button)
  if button == 1 and inside(x, y) then
    print("Clic dans le panneau Hello")
  end
end)

events.on("keypressed", function(key)
  if key == "o" then print("Touche 'o' reçue !") end
end)

return M
