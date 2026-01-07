love.math.setRandomSeed(os.time())

-- Librairies
inspect = require("libs.inspect.inspect")
colors = require "libs.ansicolors.ansicolors"
textureAtlas = require("libs.TA")

-- print(colors(inspect(myTable, { newline = "\n", indent = "  " })))

game_prep = require "game_prep"
game_ref = require "game_ref"
galaxy = require "generation_galaxy"

local isDragging = false
local dragStartX, dragStartY = 0, 0     -- position souris quand on clique
local camStartX, camStartY = 0, 0       -- position caméra au moment du clic


-- Clicks
local click = {
    x = 0,      -- screen x
    y = 0,      -- screen y
    wx = 0,     -- world x
    wy = 0      -- world y
}

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
            print("Échec chargement : " .. path .. " → " .. tostring(image))  -- Error is in "image"
        end
    end
    atlas_galaxy:hardBake("height")
    collectgarbage("collect")

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

    -- Centrage sur système :
    -- camX = galaxy.star_system.position_x[start_sys]
    -- camY = galaxy.star_system.position_y[start_sys]
    -- game_ref.zoom.state = 4

    zoom_state()
end


function love.update(dt)

--  refill_batch_orbits()

    -- move camera with keys
    local camSpeed     = 300 * dt / math.max(game_ref.current_global_scale, 0.05)
    if love.keyboard.isDown("up") then game_ref.camera.Y = game_ref.camera.Y - camSpeed end
    if love.keyboard.isDown("down") then game_ref.camera.Y = game_ref.camera.Y + camSpeed end
    if love.keyboard.isDown("left") then game_ref.camera.X = game_ref.camera.X - camSpeed end
    if love.keyboard.isDown("right") then game_ref.camera.X = game_ref.camera.X + camSpeed end
 --   print (" zoom : " .. game_ref.zoom.state .. " " )

    -- clicking simple or double-click
    if clickCount > 0 then
         clickTime = clickTime + dt
         if clickTime > game_ref.ui.doubleClickThreshold then
             if clickCount == 1 then
          --       print("Simple click")
             else
          --       print("Double click")
             end
             clickCount = 0
             clickTime = 0
         end
    end

end

function love.draw()

    game_ref.current_global_scale = math.pow(game_ref.zoom.gap, -game_ref.zoom.state)

   love.graphics.push()
-- 1. Déplacer l'origine au centre de l'écran (point fixe autour duquel on va zoomer)
    love.graphics.translate(
        love.graphics.getWidth()  / 2,
        love.graphics.getHeight() / 2
    )
    -- 2. Appliquer le zoom (scale > 1 = zoom in, scale < 1 = zoom out)
    love.graphics.scale(game_ref.current_global_scale, game_ref.current_global_scale)
    -- 3. Déplacer le monde en sens inverse de la caméra
    love.graphics.translate(-game_ref.camera.X, -game_ref.camera.Y)

    -- debug (line around galaxy)
    local half = galaxy.size_X / 2
    love.graphics.rectangle("line", -half, -half, galaxy.size_X, galaxy.size_Y)
    -- love.graphics.print("Camera world pos: " .. string.format("%.0f", game_ref.camera.X) .. ", " .. string.format("%.0f", game_ref.camera.Y), -love.graphics.getWidth()/2 + 20, -love.graphics.getHeight()/2 + 20)

    -- Draw stars
   zoom_state()
    -- Draw orbitals
                    --   love.graphics.draw(orbitsBatch)


    -- Graphic cursor
    local mx, my = love.mouse.getPosition()
    local wx, wy = game_ref:screenToWorld(mx, my)
    love.graphics.setColor(1, 0, 0, 0.6)
    love.graphics.circle("fill", wx, wy, 8)
    love.graphics.setColor(1,1,1)

    love.graphics.pop()

    -- HUD


    love.graphics.print("Zoom state: " .. game_ref.zoom.state, 10, 10)
    love.graphics.print("Scale: " .. string.format("%.3f", game_ref.current_global_scale), 10, 30)
    love.graphics.print("Camera: " .. math.floor(game_ref.camera.X) .. ", " .. math.floor(game_ref.camera.Y), 10, 50)
end

-- What's changing at zoom state X ?
function zoom_state()
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
    elseif y < 0 then   -- molette bas → zoom out → state augmente
        game_ref.zoom.state = math.min(game_ref.zoom.max, game_ref.zoom.state + 1)
    end

end


function love.keypressed(key, scancode, isrepeat)

end

function love.mousepressed(x, y, button)

    if button == 3 then -- middle click
            isDragging = true
            dragStartX, dragStartY = x, y
            camStartX, camStartY = game_ref.camera.X, game_ref.camera.Y
    end

    if button == 1 then  -- Bouton gauche de la souris
        clickCount = clickCount + 1
        clickTime = 0  -- Réinitialise le minuteur
        click.x = x
        click.y = y
        local wx, wy = game_ref:screenToWorld(x, y)
        print(string.format("Clic world : %.1f , %.1f", wx, wy))
        a, b = findSystemNear(wx, wy, 16)
        print (galaxy.star_system.nom[a])
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
        game_ref.camera.X = camStartX - (x - dragStartX) / divisor
        game_ref.camera.Y = camStartY - (y - dragStartY) / divisor
    end
end


function game_ref:screenToWorld(sx, sy)

    local wx = (sx - love.graphics.getWidth()/2) / game_ref.current_global_scale + game_ref.camera.X
    local wy = (sy - love.graphics.getHeight()/2) / game_ref.current_global_scale + game_ref.camera.Y

    return wx, wy
end

function worldToScreen(wx, wy)
    local halfW = love.graphics.getWidth()  / 2
    local halfH = love.graphics.getHeight() / 2
    local scale = game_ref.current_global_scale

    local sx = (wx - game_ref.camera.X) * scale + halfW
    local sy = (wy - game_ref.camera.Y) * scale + halfH

    return sx, sy
end


function findSystemNear(tx, ty, max_distance)
    max_distance = max_distance or 10       -- pixels ou unités selon ton échelle
    local sys = galaxy.star_system
    local best_index = nil
    local best_dist_sq = max_distance * max_distance

    for i = 1, galaxy.number_of_systems do
        local dx = sys.position_x[i] - tx
        local dy = sys.position_y[i] - ty
        local dist_sq = dx*dx + dy*dy

        if dist_sq < best_dist_sq then
            best_dist_sq = dist_sq
            best_index = i
        end
    end

    if best_index then
        return best_index, galaxy.star_system.nom[best_index]
    end
    return nil, nil
end


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
            local ext = filename:sub(-#extension):lower()

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


