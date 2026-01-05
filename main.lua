love.math.setRandomSeed(os.time())

-- Librairies
inspect = require("libs.inspect.inspect")
colors = require "libs.ansicolors.ansicolors"
textureAtlas = require("libs.TA")

-- print(colors(inspect(myTable, { newline = "\n", indent = "  " })))

game_prep = require "game_prep"
game_ref = require "game_ref"
galaxy = require "generation_galaxy"

local camX, camY = 0, 0  -- position caméra initiale

local isDragging = false
local dragStartX, dragStartY = 0, 0     -- position souris quand on clique
local camStartX, camStartY = 0, 0       -- position caméra au moment du clic


-- Double clicks
local clickCount = 0
local clickTime = 0

local png_files = nil
local starsBatch = nil
local orbitsBatch = nil


function love.load()

    love.window.setMode(1920, 1080, {resizable=true, fullscreen = false, vsync = true})
    game_ref.load(game_prep)
    galaxy.load(game_ref)

    game_ref.current_global_scale = math.pow(game_ref.zoom.gap, -game_ref.zoom.state)

        -- Loading objets : Galaxy Starfield
    atlas_galaxy = textureAtlas.newDynamicSize()
    atlas_galaxy:setFilter("nearest")

    local png_files = getFilesWithExtension("assets/" .. game_ref.path.default .. "/images/galaxy", ".png")
    print("Nombre de PNG trouvés : " .. #png_files)   -- debug
    for _, filename in ipairs(png_files) do
        local path = "assets/" .. game_ref.path.default .. "/images/galaxy/" .. filename
        local success, image = pcall(love.graphics.newImage, path)
        if success then
            local id = filename:gsub("%.png$", "")
            atlas_galaxy:add(love.graphics.newImage(path), id)

        else
            print("Échec chargement : " .. path .. " → " .. tostring(image))  -- img contient l'erreur
        end
    end
    atlas_galaxy:hardBake("height")
    collectgarbage("collect")
    -- atlas_galaxy:setFilter("linear", "linear")

    -- Stabatch : Galaxy starfield

    starsBatch_proche = love.graphics.newSpriteBatch(atlas_galaxy.image, galaxy.number_of_systems, "stream")
    for i = 1, galaxy.number_of_systems do          -- stars near (zoom in)
        local x = galaxy.star_system.position_x[i]  -- Position X du système i
        local y = galaxy.star_system.position_y[i]  -- Position Y du système i
        local type_etoile = game_prep.starfield.type_etoile_proche[galaxy.star_system.type[i]]
        local vx, vy, vw, vh = atlas_galaxy:getViewport(type_etoile)
        local quad = love.graphics.newQuad(vx, vy, vw, vh, atlas_galaxy.image:getDimensions())
        starsBatch_proche:add(quad, x, y, 0, (0.25 * game_ref.current_global_scale), sx, vw/2, vh/2)

    end
    starsBatch_lointain = love.graphics.newSpriteBatch(atlas_galaxy.image, galaxy.number_of_systems, "stream")
    for i = 1, galaxy.number_of_systems do          -- stars far (zoom out)
        local x = galaxy.star_system.position_x[i]  -- Position X du système i
        local y = galaxy.star_system.position_y[i]  -- Position Y du système i
        local type_etoile = game_prep.starfield.type_etoile_lointain[galaxy.star_system.type[i]]
        local vx, vy, vw, vh = atlas_galaxy:getViewport(type_etoile)
        local quad = love.graphics.newQuad(vx, vy, vw, vh, atlas_galaxy.image:getDimensions())
        starsBatch_lointain:add(quad, x, y, 0, 1, sx, vw/2, vh/2)
    end


    local totalOrbits = galaxy.number_of_systems * galaxy.star_system.NbOrbits
 --   orbitsBatch = love.graphics.newSpriteBatch(planetImg, totalOrbits, "dynamic")

    -- Caméra exactement au milieu du monde
    camX = galaxy.size_X / 2
    camY = galaxy.size_Y / 2

    -- Centrage sur système :
    -- camX = galaxy.star_system.position_x[start_sys]
    -- camY = galaxy.star_system.position_y[start_sys]
    -- game_ref.zoom.state = 4

    -- Option : zoom initial pour voir une bonne partie de la galaxie
    -- local margin = 0.9
    -- local fit_x = love.graphics.getWidth()  / galaxy.size_X * margin
    -- local fit_y = love.graphics.getHeight() / galaxy.size_Y * margin
    -- local fit_zoom = math.min(fit_x, fit_y)

    -- Si zoom not by default :
    -- game_ref.zoom.state = math.ceil( -math.log(fit_zoom) / math.log(game_ref.zoom.gap) )


    zoom_state()
end


function love.update(dt)

--  refill_batch_orbits()

    -- move camera with keys
    local camSpeed     = 300 * dt / math.max(game_ref.current_global_scale, 0.05)
    if love.keyboard.isDown("up") then camY = camY - camSpeed end
    if love.keyboard.isDown("down") then camY = camY + camSpeed end
    if love.keyboard.isDown("left") then camX = camX - camSpeed end
    if love.keyboard.isDown("right") then camX = camX + camSpeed end
 --   print (" zoom : " .. game_ref.zoom.state .. " " )

    -- clicking simple or double-click
    if clickCount > 0 then
         clickTime = clickTime + dt
         if clickTime > game_ref.ui.doubleClickThreshold then
             if clickCount == 1 then
                 print("Simple click")
             else
                 print("Double click")
             end
             clickCount = 0
             clickTime = 0
         end
    end

end

function love.draw()

    atlas_galaxy:draw("geante_glacee", 50,50)
    atlas_galaxy:draw("geante_gazeuse", 114,50)

    -- Save graphic state
    love.graphics.push()

    -- Center the screen
    love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)

    -- Zoom global (inverse car state grand = zoom out)
    love.graphics.scale(game_ref.current_global_scale, game_ref.current_global_scale)

    -- Apply cam new pos (-cam reverse sens)
    love.graphics.translate(-camX, -camY)
    -- love.graphics.translate(galaxy.size_X / 2 , galaxy.size_Y / 2)

    -- Draw stars
    zoom_state()
   --  love.graphics.draw(starsBatch_proche)

    -- Draw orbitals
 --   love.graphics.draw(orbitsBatch)

    -- restaure graphic state (for unzoomed stuff)
    love.graphics.pop()

    -- HUD
    love.graphics.print("Zoom: x" .. game_ref.zoom.state, 10, 10)

end


--
--
--

-- What's changing at zoom state X ?
function zoom_state()
    game_ref.current_global_scale = math.pow(game_ref.zoom.gap, -game_ref.zoom.state)
	if game_ref.zoom.state <= game_ref.zoom.proche then
		love.graphics.draw(starsBatch_proche)
	else
		love.graphics.draw(starsBatch_lointain)
    end
end


function love.wheelmoved(x, y)

    local old_state = game_ref.zoom.state
    if y > 0 then       -- molette haut → zoom in → state diminue
        game_ref.zoom.state = math.max(game_ref.zoom.min, game_ref.zoom.state - 1)
      --  zoom_state()
    elseif y < 0 then   -- molette bas → zoom out → state augmente
        game_ref.zoom.state = math.min(game_ref.zoom.max, game_ref.zoom.state + 1)
     --   zoom_state()
    end

end


function love.keypressed(key, scancode, isrepeat)

end



function love.mousepressed(x, y, button)

    if button == 3 then -- middle click
            isDragging = true
            dragStartX, dragStartY = x, y
            camStartX, camStartY = camX, camY
    end

   -- game_ref.ui.doubleClickThreshold

    if button == 1 then  -- Bouton gauche de la souris
        clickCount = clickCount + 1
        clickTime = 0  -- Réinitialise le minuteur
    end

end


function love.mousereleased(x, y, button)
    if button == 3 then
        isDragging = false
    end
end

function love.mousemoved(x, y, dx, dy)
    if isDragging then
        -- Inverse the move.
        local divisor = math.max(game_ref.current_global_scale, 0.05)
        camX = camStartX - (x - dragStartX) / divisor
        camY = camStartY - (y - dragStartY) / divisor
    end
end


--
--
--



function getFilesWithExtension(path, extension)
    local files = {}
    -- Récupère tous les éléments du dossier
    local items = love.filesystem.getDirectoryItems(path or "")

    -- Filtre sur l'extension voulue
    for _, filename in ipairs(items) do
        -- Vérifie que c'est bien un fichier (pas un dossier)
        local info = love.filesystem.getInfo((path or "") .. "/" .. filename)
        if info and info.type == "file" then
            -- take the file extension
            local ext = filename:sub(-#extension):lower()   -- version 2 (plus rapide)

            if ext == extension:lower() then
                table.insert(files, filename)
            end
        end
    end
    return files
end


--
--
--


function refill_batch_orbits()

     orbitsBatch:clear()
       for sys = 1, galaxy.number_of_systems do
           local centerX = galaxy.star_system.position_x[sys]
           local centerY = galaxy.star_system.position_y[sys]
        -- For each orbit around this system
           for orbit = 1, galaxy.star_system.NbOrbits do
               local radius = (orbit * 6 + 4)
               local angularSpeed = 0.8 / orbit
               local angle = galaxy.star_system.orbital.phase[sys][orbit] +  (love.timer.getTime() * angularSpeed)
               local px = centerX + math.cos(angle) * radius
               local py = centerY + math.sin(angle) * radius
               local size = game_ref.current_global_scale * 0.6
    --           print (size)
               orbitsBatch:add(px, py, 0, size, size, (planetImg:getWidth()/2), planetImg:getHeight()/2)
           end
       end

end


