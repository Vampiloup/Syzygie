function love.conf(t)
  t.identity = "syzygie"            -- nom du dossier de sauvegarde
  t.window.title = "Syzygie"
  t.window.width = 1280             -- Avoid "flash" at launch, then change in the game itself (settings)
  t.window.height = 720             -- //
  t.window.resizable = true
  t.window.vsync = 1
  t.modules.physics = false        -- désactive les modules inutilisés
  t.modules.joystick = false
end
