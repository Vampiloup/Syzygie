local M = {}
local listeners = {}

function M.on(name, fn)
  listeners[name] = listeners[name] or {}
  table.insert(listeners[name], fn)
end

function M.emit(name, ...)
  for _, fn in ipairs(listeners[name] or {}) do
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
