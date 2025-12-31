love.math.setRandomSeed(os.time())

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

local starImg = nil
local starsBatch = nil
local orbitsBatch = nil


function love.load()

    love.window.setMode(1920, 1080, {resizable=true, fullscreen = false, vsync = true})
    game_ref.load(game_prep)
    galaxy.load(game_ref)





        --[[
            local textureAtlas = require("libs.TA")   -- assure-toi que le chemin est exact
    -- Création atlas dynamic size
    local TA = textureAtlas.newDynamicSize(2,0, 0)
    TA:setFilter("nearest")

    -- Récupère les fichiers (ton helper)
    -- local png_files = getFilesWithExtension("/assets/syzygie/images/galaxy", ".png")
    -- Ou mieux, pour cohérence avec game_ref :
    local png_files = getFilesWithExtension("assets/" .. game_ref.path.default .. "/images/galaxy", ".png")

    print("Nombre de PNG trouvés : " .. #png_files)   -- debug crucial

    local added_count = 0

    -- Étape 1 : AJOUTER toutes les images
    for _, filename in ipairs(png_files) do
        local path = "assets/" .. game_ref.path.default .. "/images/galaxy/" .. filename

        local success, imgage = pcall(love.graphics.newImage, path)
        if success then
            -- ID simple : nom du fichier sans .png
            local id = filename:gsub("%.png$", "")
 --           TA:add(imgage, id)
            added_count = added_count + 1
            print("Ajoutée : " .. id)
            print("Échec chargement : " .. path .. " → " .. tostring(imgage))  -- img contient l'erreur
        end
    end

  ]]

    img = love.graphics.newImage("assets/" .. game_ref.path.default .. "/images/galaxy/etoile_blanc.png")
    planetImg = love.graphics.newImage("assets/" .. game_ref.path.default .. "/images/galaxy/geante_glacee.png")

    starsBatch = love.graphics.newSpriteBatch(img, galaxy.number_of_systems, "dynamic")
    for i = 1, galaxy.number_of_systems do
        local x = galaxy.star_system.position_x[i]  -- Position X du système i
        local y = galaxy.star_system.position_y[i]  -- Position Y du système i
        starsBatch:add(x, y, 0, 1, 1, img:getWidth()/2, img:getHeight()/2)
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



end

function love.update(dt)

    game_ref.current_global_scale = math.pow(game_ref.zoom.gap, -game_ref.zoom.state)
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


--[[

    if button == 1 then -- left click

        local currentTime = love.timer.getTime()
        local timeSinceLast = currentTime - lastClickTime
        local isDoubleClick = false
        if timeSinceLast <= DOUBLE_CLICK_TIME then
            local dx = x - lastClickX
            local dy = y - lastClickY
            local distance = math.sqrt(dx*dx + dy*dy)

            if distance <= DOUBLE_CLICK_DISTANCE then
                isDoubleClick = true
                -- Double_click action.
                print("Double-clic détecté à " .. x .. "," .. y)
                local screen_center_x = love.graphics.getWidth() / 2
                local screen_center_y = love.graphics.getHeight() / 2
                local world_x = camX + (x - screen_center_x) / game_ref.current_global_scale
                local world_y = camY + (y - screen_center_y) / game_ref.current_global_scale

                -- Option : centrer immédiatement
                -- game_ref.zoom.state = game_ref.zoom.state - 2   -- zoom in de 2 crans
            end
        elseif not isDoubleClick then
            print("Simple clic")
        end

]]


function love.draw()

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
    love.graphics.draw(starsBatch)

    -- Draw orbitals
--    love.graphics.draw(orbitsBatch)

    -- restaure graphic state (for unzoomed stuff)
    love.graphics.pop()

    -- HUD
    love.graphics.print("Zoom: x" .. game_ref.zoom.state, 10, 10)

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


function getFilesWithExtension(path, extension)
    local files = {}
    -- Récupère tous les éléments du dossier
    local items = love.filesystem.getDirectoryItems(path or "")

    -- Filtre sur l'extension voulue
    for _, filename in ipairs(items) do
        -- Vérifie que c'est bien un fichier (pas un dossier)
        local info = love.filesystem.getInfo((path or "") .. "/" .. filename)
        if info and info.type == "file" then
            -- Deux façons d'obtenir l'extension (la 2e est plus robuste)
            -- local ext = filename:match("%.([^%.]+)$")   -- version 1
            local ext = filename:sub(-#extension):lower()   -- version 2 (plus rapide)

            if ext == extension:lower() then
                table.insert(files, filename)
            end
        end
    end
    return files
end

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


