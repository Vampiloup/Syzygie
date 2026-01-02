local game_ref = {
            screen_X = 0,                           -- Size X of the game screen
            screen_Y = 0,                           -- Size Y of the game screen
            zoom = {                                -- Zoom state
                state = 4,                                  -- Zoom level (particularly at start)
                gap = 1.1,                                  -- difference of visible zoom between each level (1 stat more = x1.1)
                min = -20,                                  -- Minimal zoom
                max = 30,                                   -- Maximal zoom
                proche = 8,                                 -- Equal or more that state for the camera to be NEAR the system.
                show_label = -5,                            -- Equal or more that state to show System label on the world map
                show_orbitals = 20                          -- Equal or more that state to show Orbitals on the World map
            },
            current_global_scale = 1,               -- Global Zoom (zoom modified by gap. Calculated in game in love.update)
            path = {                                -- paths of assets used in the game
                default = "syzygie"                     -- Default mod
            },
            ui = {
                doubleClickThreshold = 0.3
            }
    }


function game_ref.load()

end

function game_ref.update(dt)

end

function game_ref.draw()

end

return game_ref
