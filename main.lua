local gamestate = require("gamestate")
local rules = require("rules")
local utils = require("utils")

local showIntro = true -- Show intro screen on load
local showMenu = true -- Show main menu on load
local showSettings = false -- Show settings screen
local menuSelection = 1 -- 1=Play, 2=Settings, 3=Quit
local menuHover = nil -- Track hovered menu option
local settingsSelection = 1 -- 1=Display, 2=Resolution, 3=Master, 4=Music, 5=SFX, 6=Return
local displayModes = {"Windowed", "Borderless", "Fullscreen"}
local displayModeIndex = 1
local resolutions = {"800x600", "1024x768", "1280x720", "1920x1080"}
local resolutionIndex = 1
local masterVolume = 1.0
local musicVolume = 1.0
local sfxVolume = 1.0
local defaultFont
local bigFont, menuFont, titleFont, smallFont
local settingsHover = nil -- optional hover state for settings
local approveHover = false
local denyHover = false

-- Day transition system
local transitionState = "none" -- "fadeOut", "showScreen", "fadeIn", "none"
local transitionTimer = 0
local transitionDuration = { fadeOut = 1.5, showScreen = 2.3, fadeIn = 0.5 } -- fadeIn is much faster
local transitionAlpha = 0
local transitionDay = 0 -- Track which day is being shown in transition
local chimePlayed = false
local chimeSound
local pendingAdvanceDay = false -- Track if we need to advance the day after transition
-- placeholderImage removed

-- Add screen and UI constants
local SCREEN = { W = 800, H = 600 }
local BUTTONS = {
    approve = { x = 180, y = 420, w = 180, h = 48 },
    deny = { x = 440, y = 420, w = 180, h = 48 },
    restart = { x = 300, y = 320, w = 200, h = 50 },
}

-- Initialize game state
function love.load()
    gamestate.init()
    showIntro = true
    if love.audio then
        chimeSound = love.audio.newSource("assets/chime.wav", "static")
    end
    -- Cache fonts once instead of creating per-frame
    bigFont = love.graphics.newFont(48)
    menuFont = love.graphics.newFont(32)
    titleFont = love.graphics.newFont(40)
    smallFont = love.graphics.newFont(24)
    defaultFont = love.graphics.getFont()
end

-- Keypress handler: all game actions
function love.keypressed(key)
    if showMenu then
        if key == "up" then menuSelection = math.max(1, menuSelection - 1)
        elseif key == "down" then menuSelection = math.min(3, menuSelection + 1)
        elseif key == "return" or key == "space" then
            if menuSelection == 1 then -- Play
                showMenu = false
                showIntro = true
            elseif menuSelection == 2 then -- Settings
                showMenu = false
                showSettings = true
            elseif menuSelection == 3 then -- Quit
                love.event.quit()
            end
        end
        return
    end
    if showSettings then
        if key == "up" then settingsSelection = math.max(1, settingsSelection - 1)
        elseif key == "down" then settingsSelection = math.min(6, settingsSelection + 1)
        elseif key == "left" then
            if settingsSelection == 1 then displayModeIndex = math.max(1, displayModeIndex - 1)
            elseif settingsSelection == 2 then resolutionIndex = math.max(1, resolutionIndex - 1)
            elseif settingsSelection == 3 then masterVolume = math.max(0, masterVolume - 0.05)
            elseif settingsSelection == 4 then musicVolume = math.max(0, musicVolume - 0.05)
            elseif settingsSelection == 5 then sfxVolume = math.max(0, sfxVolume - 0.05)
            end
        elseif key == "right" then
            if settingsSelection == 1 then displayModeIndex = math.min(#displayModes, displayModeIndex + 1)
            elseif settingsSelection == 2 then resolutionIndex = math.min(#resolutions, resolutionIndex + 1)
            elseif settingsSelection == 3 then masterVolume = math.min(1, masterVolume + 0.05)
            elseif settingsSelection == 4 then musicVolume = math.min(1, musicVolume + 0.05)
            elseif settingsSelection == 5 then sfxVolume = math.min(1, sfxVolume + 0.05)
            end
        elseif key == "return" or key == "space" then
            if settingsSelection == 6 then -- Return to menu
                showSettings = false
                showMenu = true
            end
        end
        return
    end
    if showIntro then
        showIntro = false
        return
    end
    if transitionState ~= "none" then return end -- Block input during transition
    if gamestate.gameOver then return end -- Block input if game is over

    local applicant = gamestate:getCurrentApplicant()
    local ruleSet = gamestate.rules
    local currentDate = gamestate.date

    -- Helper to start transition between days
    local function startDayTransition(dayNum, shouldAdvance)
        transitionState = "fadeOut"
        transitionTimer = 0
        transitionAlpha = 0
        transitionDay = dayNum
        chimePlayed = false
        pendingAdvanceDay = shouldAdvance or false
    end

    if key == "a" then
        if gamestate:isForbiddenApplicant(applicant) then
            gamestate.specialGameOver = true
            gamestate.gameOver = true
            return
        end
        if rules.checkApplicant(applicant, ruleSet, currentDate) then
            gamestate:increaseScore()
        else
            gamestate:addMistake()
        end
        local prevDay = gamestate.day
        -- If last applicant of the day, show end-of-day fade and advance after transition
        if gamestate:getCurrentApplicant() ~= nil then
            -- If day advanced, show transition, but don't advance yet
            if gamestate.day < gamestate.maxDays and gamestate.applicantsToday + 1 >= gamestate.maxApplicantsPerDay then
                startDayTransition(gamestate.day + 1, true)
                return
            end
            gamestate:advance()
            if gamestate.day > prevDay and not gamestate.gameOver then
                startDayTransition(gamestate.day, false)
                return
            end
        else
            startDayTransition(prevDay, true)
            return
        end

    elseif key == "d" then
        if not rules.checkApplicant(applicant, ruleSet, currentDate) then
            gamestate:increaseScore()
        else
            gamestate:addMistake()
        end
        local prevDay = gamestate.day
        if gamestate:getCurrentApplicant() ~= nil then
            if gamestate.day < gamestate.maxDays and gamestate.applicantsToday + 1 >= gamestate.maxApplicantsPerDay then
                startDayTransition(gamestate.day + 1, true)
                return
            end
            gamestate:advance()
            if gamestate.day > prevDay and not gamestate.gameOver then
                startDayTransition(gamestate.day, false)
                return
            end
        else
            startDayTransition(prevDay, true)
            return
        end

    elseif key == "f" then
        gamestate:toggleAllies()
    elseif key == "r" then
        gamestate.showRegulations = not gamestate.showRegulations
    elseif key == "c" then
        gamestate:toggleCalendar()
    end
end

function love.update(dt)
    if transitionState == "fadeOut" then
        print("Transition: fadeOut", transitionTimer)
        transitionTimer = transitionTimer + dt
        transitionAlpha = math.min(transitionTimer / transitionDuration.fadeOut, 1)
        if transitionTimer >= transitionDuration.fadeOut then
            transitionState = "showScreen"
            transitionTimer = 0
            transitionAlpha = 1
            print("Transition: showScreen")
            -- Advance day at the start of showScreen so info updates while screen is obscured
            if pendingAdvanceDay then
                gamestate:advance()
                pendingAdvanceDay = false
                print("Day advanced!")
            end
        end
    elseif transitionState == "showScreen" then
        print("Transition: showScreen", transitionTimer)
        transitionTimer = transitionTimer + dt
        if not chimePlayed and chimeSound then
            love.audio.play(chimeSound)
            chimePlayed = true
        end
        if transitionTimer >= transitionDuration.showScreen then
            transitionState = "fadeIn"
            transitionTimer = 0
            transitionAlpha = 1
            print("Transition: fadeIn")
        end
    elseif transitionState == "fadeIn" then
        print("Transition: fadeIn", transitionTimer)
        transitionTimer = transitionTimer + dt
        transitionAlpha = 1 - math.min(transitionTimer / transitionDuration.fadeIn, 1)
        if transitionTimer >= transitionDuration.fadeIn then
            transitionState = "none"
            transitionAlpha = 0
            print("Transition: none")
        end
    end
end

-- Utility: Check if a table contains a value
local function tableContains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

-- Game UI drawing function (moved out of love.draw for global access)
local function drawGameUI()
    -- Game Over Screens
    if gamestate.gameOver then
        local y = 200
        if gamestate.specialGameOver then
            love.graphics.printf("GAME OVER! You let an Elf or Elvenmere citizen into our sacred halls!", 0, y, 800, "center")
            y = y + 40
        elseif gamestate.victoryGameOver then
            love.graphics.printf("CONGRATULATIONS! The enemies of Thrum were kept at bay!", 0, y, 800, "center")
            y = y + 40
        else
            love.graphics.printf("GAME OVER! The halls of Thrum brim with spies, your watch has ended.", 0, y, 800, "center")
            y = y + 40
        end
        love.graphics.printf("Score: " .. gamestate.score .. " | Strikes: " .. gamestate.mistakes .. "/" .. gamestate.maxMistakes, 0, y, 800, "center")
        y = y + 40
        -- Draw Restart button
        local btnW, btnH = 200, 50
        local btnX, btnY = 300, y + 40
        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 10, 10)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Restart", btnX, btnY + 15, btnW, "center")
        love.graphics.setColor(1, 1, 1)
        return
    end

    -- Main game info
    love.graphics.printf("Day " .. gamestate.day .. " | Date: " .. utils.getDateString(gamestate.date), 0, 10, SCREEN.W, "center")
    love.graphics.printf("Score: " .. gamestate.score .. " | Strikes: " .. gamestate.mistakes .. "/" .. gamestate.maxMistakes, 0, 30, SCREEN.W, "center")

    -- Rules panel
    local ruleSet = gamestate.rules
    local ruleY = 80
    if ruleSet.allowedRaces then
        local nonElfRaces = {"Dwarf", "Human", "Halfling", "Gnome"}
        local isAny = #ruleSet.allowedRaces == #nonElfRaces
        for _, race in ipairs(nonElfRaces) do
            if not tableContains(ruleSet.allowedRaces, race) then
                isAny = false
                break
            end
        end
        local racesText = isAny and "Any" or ("Allowed races: " .. table.concat(ruleSet.allowedRaces, ", "))
        love.graphics.printf("- " .. racesText, 30, ruleY, 800, "left")
        ruleY = ruleY + 20
    elseif ruleSet.requireRace then
        love.graphics.printf("- Allowed races: " .. ruleSet.requireRace, 30, ruleY, 800, "left")
        ruleY = ruleY + 20
    end
    if ruleSet.requireAlly then
        love.graphics.printf("- Must be from an allied kingdom", 30, ruleY, 800, "left")
        ruleY = ruleY + 20
    end
    if ruleSet.noExpiredPassports then
        love.graphics.printf("- Passport must not be expired", 30, ruleY, 800, "left")
        ruleY = ruleY + 20
    end

    local y = 160

    -- Calendar panel
    if gamestate.showCalendar and gamestate.day > 1 then
        love.graphics.printf("Calendar:", 10, y, 800, "left")
        local maxLen = #tostring(#utils.months)
        for i, month in ipairs(utils.months) do
            local numStr = tostring(i)
            while #numStr < maxLen do
                numStr = " " .. numStr
            end
            love.graphics.printf(numStr .. ". " .. month, 30, y + i * 20, 800, "left")
        end
        love.graphics.printf("Press C to close calendar", 0, y + (#utils.months + 2) * 20, SCREEN.W, "center")
        return
    end

    -- Allies panel
    if gamestate.showAllies and gamestate.day > 2 then
        love.graphics.printf("Current Allied Kingdoms:", 10, y, 800, "left")
        if not ruleSet.requireAlly or not ruleSet.alliedKingdoms or #ruleSet.alliedKingdoms == 0 then
            love.graphics.printf("None", 30, y + 20, 800, "left")
        else
            for i, k in ipairs(ruleSet.alliedKingdoms or {}) do
                love.graphics.printf("- " .. k, 30, y + i * 20, 800, "left")
            end
        end
    elseif gamestate.showRegulations then
        love.graphics.setColor(0.7, 0.7, 0.9, 1)
        love.graphics.rectangle("fill", 100, 300, 600, 160)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf("REGULATIONS:", 100, 310, 600, "center")
        love.graphics.printf("- Passports that expire on today's date are NOT valid.", 100, 340, 600, "left")
        love.graphics.printf("- No Elves or citizens of Elvenmere are permitted to enter our sacred halls.", 100, 370, 600, "left")
        love.graphics.printf("- All applicants must be scrutinised thoroughly!", 100, 400, 600, "left")
        love.graphics.setColor(1, 1, 1, 1)
        return
    else
        -- Applicant info panel
        local applicant = gamestate:getCurrentApplicant()
        if applicant then
            love.graphics.printf("Applicant " .. tostring(gamestate.currentIndex) .. " of " .. tostring(gamestate.maxApplicantsPerDay), 0, y, 800, "center")
            love.graphics.printf("Name: " .. (applicant.name or "Unknown"), 0, y + 40, 800, "center")
            love.graphics.printf("Race: " .. (applicant.race or "Unknown"), 0, y + 70, 800, "center")
            love.graphics.printf("Kingdom: " .. (applicant.kingdom or "Unknown"), 0, y + 100, 800, "center")
            love.graphics.printf("Passport Expiry: " .. (applicant.passportExpiry and utils.getDateString(applicant.passportExpiry) or "Unknown"), 0, y + 130, 800, "center")

            local prompt = "Press A to Approve, D to Deny"
            if gamestate.day > 1 then prompt = prompt .. ", C to View Calendar" end
            if gamestate.day > 2 then prompt = prompt .. ", F to View Allies" end
            prompt = prompt .. ", R to Check Regulations"
            love.graphics.printf(prompt, 0, y + 180, SCREEN.W, "center")

            -- Draw Approve/Deny buttons (use BUTTONS constants)
            local a = BUTTONS.approve
            local d = BUTTONS.deny
            if approveHover then
                love.graphics.setColor(0.2, 0.6, 0.2, 1)
            else
                love.graphics.setColor(0.4, 0.8, 0.4, 1)
            end
            love.graphics.rectangle("fill", a.x, a.y, a.w, a.h, 10, 10)
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf("Approve", a.x, a.y + 12, a.w, "center")
            if denyHover then
                love.graphics.setColor(0.7, 0.2, 0.2, 1)
            else
                love.graphics.setColor(0.9, 0.4, 0.4, 1)
            end
            love.graphics.rectangle("fill", d.x, d.y, d.w, d.h, 10, 10)
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf("Deny", d.x, d.y + 12, d.w, "center")
        else
            love.graphics.printf("No more applicants today.", 0, y, SCREEN.W, "center")
        end
    end

    -- Dwarven flavor rule at bottom
    love.graphics.setColor(0.8, 0.6, 0.2, 1) -- gold-ish
    love.graphics.printf("BY ORDER OF THE IRON COUNCIL: NO ELVES! NO CITIZENS OF ELVENMERE!", 0, 520, SCREEN.W, "center")
    love.graphics.setColor(1, 1, 1, 1) -- reset color
end

function love.draw()
    if showMenu then
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.rectangle("fill", 0, 0, SCREEN.W, SCREEN.H)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(bigFont)
        love.graphics.printf("THRUM", 0, 80, SCREEN.W, "center")
        love.graphics.setFont(menuFont)
        local options = {"Play", "Settings", "Quit"}
        for i, opt in ipairs(options) do
            local y = 200 + (i-1)*60
            local isSelected = menuSelection == i
            local isHovered = menuHover == i
            if isHovered or isSelected then
                love.graphics.setColor(0.8, 0.6, 0.2, 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.printf(opt, 0, y, SCREEN.W, "center")
        end
        love.graphics.setFont(defaultFont)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    if showSettings then
        love.graphics.setColor(0.15, 0.15, 0.2, 1)
        love.graphics.rectangle("fill", 0, 0, SCREEN.W, SCREEN.H)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(titleFont)
        love.graphics.printf("Settings", 0, 60, SCREEN.W, "center")
        love.graphics.setFont(smallFont)
        local labels = {
            "Display Mode: " .. displayModes[displayModeIndex],
            "Resolution: " .. resolutions[resolutionIndex],
            string.format("Master Volume: %.0f%%", masterVolume*100),
            string.format("Music Volume: %.0f%%", musicVolume*100),
            string.format("SFX Volume: %.0f%%", sfxVolume*100),
            "Return to Main Menu"
        }
        for i, label in ipairs(labels) do
            local y = 140 + (i-1)*50
            if settingsSelection == i then
                love.graphics.setColor(0.8, 0.6, 0.2, 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.printf(label, 0, y, SCREEN.W, "center")
        end
        love.graphics.setFont(defaultFont)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    if showIntro then
        love.graphics.setColor(0.7, 0.7, 0.9, 1)
        love.graphics.rectangle("fill", 100, 200, 600, 300)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf("THE GATE OF THRUM STANDS BEFORE YOU", 100, 220, 600, "center")
        love.graphics.printf("REGULATIONS:", 100, 260, 600, "center")
        love.graphics.printf("- Passports that expire on today's date are NOT valid.", 100, 290, 600, "left")
        love.graphics.printf("- No elves or citizens of Elvenmere are permitted to enter our sacred halls.", 100, 320, 600, "left")
        love.graphics.printf("- Our list of grudges is ever-growing! Always check the daily admission rules.", 100, 350, 600, "left")
        love.graphics.setColor(0, 0.2, 0.6, 1)
        love.graphics.printf("PRESS ANY KEY TO BEGIN", 100, 400, 600, "center")
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- Day transition overlay logic (restored)
    if transitionState ~= "none" then
        if transitionState == "fadeOut" or transitionState == "fadeIn" then
            drawGameUI()
            love.graphics.setColor(0, 0, 0, transitionAlpha)
            love.graphics.rectangle("fill", 0, 0, 800, 600)
            love.graphics.setColor(1, 1, 1, 1)
            return
        elseif transitionState == "showScreen" then
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("fill", 0, 0, 800, 600)
            love.graphics.setFont(bigFont)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("Day " .. tostring(transitionDay), 0, 250, SCREEN.W, "center")
            love.graphics.setFont(defaultFont)
            love.graphics.setColor(1, 1, 1, 1)
            return
        end
    end

    drawGameUI()
end

function love.mousemoved(x, y, dx, dy, istouch)
    -- Menu hover
    if showMenu then
        menuHover = nil
        for i = 1, 3 do
            local optY = 200 + (i-1)*60
            local optH = 40
            if x >= 0 and x <= SCREEN.W and y >= optY and y <= optY + optH then
                menuHover = i
                break
            end
        end
    end
    -- Settings hover
    if showSettings then
        settingsHover = nil
        for i = 1, 6 do
            local optY = 140 + (i-1)*50
            local optH = 36
            if x >= 0 and x <= SCREEN.W and y >= optY and y <= optY + optH then
                settingsHover = i
                break
            end
        end
    end
    -- Approve/Deny hover when in main game
    approveHover = false
    denyHover = false
    if not showMenu and not showSettings and not showIntro and not gamestate.gameOver and transitionState == "none" then
        local a = BUTTONS.approve
        local d = BUTTONS.deny
        if x >= a.x and x <= a.x + a.w and y >= a.y and y <= a.y + a.h then
            approveHover = true
        elseif x >= d.x and x <= d.x + d.w and y >= d.y and y <= d.y + d.h then
            denyHover = true
        end
    end
end

function love.mousepressed(x, y, button)
    if showMenu then
        -- Main menu option hitboxes
        for i = 1, 3 do
            local optY = 200 + (i-1)*60
            local optH = 40
            if x >= 0 and x <= SCREEN.W and y >= optY and y <= optY + optH then
                menuSelection = i
                if button == 1 then -- left click
                    if i == 1 then showMenu = false; showIntro = true
                    elseif i == 2 then showMenu = false; showSettings = true
                    elseif i == 3 then love.event.quit() end
                end
                return
            end
        end
        return
    end
    if showSettings then
        -- Settings option hitboxes
        for i = 1, 6 do
            local optY = 140 + (i-1)*50
            local optH = 36
            if x >= 0 and x <= SCREEN.W and y >= optY and y <= optY + optH then
                settingsSelection = i
                if button == 1 then
                    if i == 1 then displayModeIndex = displayModeIndex % #displayModes + 1
                    elseif i == 2 then resolutionIndex = resolutionIndex % #resolutions + 1
                    elseif i == 3 then masterVolume = math.min(1, masterVolume + 0.1)
                    elseif i == 4 then musicVolume = math.min(1, musicVolume + 0.1)
                    elseif i == 5 then sfxVolume = math.min(1, sfxVolume + 0.1)
                    elseif i == 6 then showSettings = false; showMenu = true end
                end
                return
            end
        end
        return
    end
    if showIntro then
        showIntro = false
        return
    end
    if gamestate.gameOver then
        -- Restart button uses BUTTONS.restart
        local r = BUTTONS.restart
        if x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
            gamestate:restart()
            showIntro = true
        end
        return
    end
    -- Approve/Deny click handling (map to A/D logic)
    if not showMenu and not showSettings and not showIntro and not gamestate.gameOver and transitionState == "none" then
        if button == 1 then
            local a = BUTTONS.approve
            local d = BUTTONS.deny
            if x >= a.x and x <= a.x + a.w and y >= a.y and y <= a.y + a.h then
                love.keypressed('a')
                return
            elseif x >= d.x and x <= d.x + d.w and y >= d.y and y <= d.y + d.h then
                love.keypressed('d')
                return
            end
        end
    end
end