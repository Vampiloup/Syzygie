-- core.events.lua
local M = {}
local listeners = {}

function M.on(name, fn)
  listeners[name] = listeners[name] or {}
  for _, f in ipairs(listeners[name]) do
    if f == fn then
      print("[events] doublon ignoré : " .. name)  -- utile en dev, à retirer ensuite
      return false
    end
  end
  table.insert(listeners[name], fn)
  return true
end

function M.off(name, fn)
  local list = listeners[name]
  if not list then return end
  for i = #list, 1, -1 do
    if list[i] == fn then
      table.remove(list, i)
      break
    end
  end
end

function M.emit(name, ...)
  local list = listeners[name]
  if not list then return end
    -- Copie de la table pour éviter les bugs si un listener se désabonne pendant l'émission
  local currentListeners = {}
  for _, fn in ipairs(list) do
    table.insert(currentListeners, fn)
  end
  for _, fn in ipairs(currentListeners) do
    fn(...)
  end
end

return M


-- dans la simulation, quand une étoile est découverte
-- events.emit("star_discovered", star)

-- dans l'UI, ailleurs, sans que la sim le sache
-- events.on("star_discovered", function(star)
-- notifications.add(i18n.t("msg.star_discovered"))
-- end)

-- un mod peut aussi s'y abonner
-- events.on("star_discovered", function(star) ... end)
