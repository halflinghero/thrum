local gamestate = require("gamestate")
local rules = require("rules")
local utils = require("utils")

local showIntro = true -- Show intro screen on load
local defaultFont

-- Day transition system
local transitionState = "none" -- "fadeOut", "showScreen", "fadeIn", "none"
local transitionTimer = 0
local transitionDuration = { fadeOut = 0.7, showScreen = 1.2, fadeIn = 0.7 } -- Shorter fade for debugging
local transitionAlpha = 0
local bannerText = ""
local chimePlayed = false
local chimeSound

-- Initialize game state
function love.load()
    gamestate.init()
    showIntro = true
    if love.audio then
        chimeSound = love.audio.newSource("assets/chime.wav", "static")
    end
    defaultFont = love.graphics.getFont()
end

-- Keypress handler: all game actions
function love.keypressed(key)
    if showIntro then
        showIntro = false
        return
    end
    if transitionState ~= "none" then return end -- Block input during transition
    if gamestate.gameOver then return end -- Block input if game is over

    local applicant = gamestate:getCurrentApplicant()
    local ruleSet = gamestate.rules
    local currentDate = gamestate.date

    local function startDayTransition()
        transitionState = "fadeOut"
        transitionTimer = 0
        transitionAlpha = 0
        bannerY = -80
        bannerText = "Day " .. tostring(gamestate.day) .. " Begins!\n" .. utils.getDateString(gamestate.date)
        chimePlayed = false
    end

    if key == "a" then
        -- Instantly end game if forbidden applicant is approved
        if gamestate:isForbiddenApplicant(applicant) then
            gamestate.specialGameOver = true
            gamestate.gameOver = true
            return
        end
        -- Apply rules for approval
        if rules.checkApplicant(applicant, ruleSet, currentDate) then
            gamestate:increaseScore()
        else
            gamestate:addMistake()
        end
        local prevDay = gamestate.day
        gamestate:advance()
        if gamestate.day > prevDay and not gamestate.gameOver then
            startDayTransition()
            return
        end

    elseif key == "d" then
        -- Deny applicant, score if correct
        if not rules.checkApplicant(applicant, ruleSet, currentDate) then
            gamestate:increaseScore()
        else
            gamestate:addMistake()
        end
        local prevDay = gamestate.day
        gamestate:advance()
        if gamestate.day > prevDay and not gamestate.gameOver then
            startDayTransition()
            return
        end

    elseif key == "f" then
        gamestate:toggleAllies()
    elseif key == "r" then
        gamestate.showRegulations = not gamestate.showRegulations
    elseif key == "c" then
        gamestate:toggleCalendar()
    end
function love.update(dt)
    if transitionState == "fadeOut" then
        transitionTimer = transitionTimer + dt
        transitionAlpha = math.min(transitionTimer / transitionDuration.fadeOut, 1)
        if transitionTimer >= transitionDuration.fadeOut then
            transitionState = "showScreen"
            transitionTimer = 0
            transitionAlpha = 1
        end
    elseif transitionState == "showScreen" then
        transitionTimer = transitionTimer + dt
        if not chimePlayed and chimeSound then
            love.audio.play(chimeSound)
            chimePlayed = true
        end
        if transitionTimer >= transitionDuration.showScreen then
            transitionState = "fadeIn"
            transitionTimer = 0
            transitionAlpha = 1
        end
    elseif transitionState == "fadeIn" then
        transitionTimer = transitionTimer + dt
        transitionAlpha = 1 - math.min(transitionTimer / transitionDuration.fadeIn, 1)
        if transitionTimer >= transitionDuration.fadeIn then
            transitionState = "none"
            transitionAlpha = 0
        end
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

-- Main draw function: handles all UI and game screens
function love.draw()
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

    -- Day transition overlay
    if transitionState ~= "none" then
        -- Draw previous frame as usual, then overlay
        if transitionState == "fadeOut" or transitionState == "fadeIn" then
            love.graphics.setColor(0, 0, 0, transitionAlpha)
            love.graphics.rectangle("fill", 0, 0, 800, 600)
        end
        if transitionState == "showScreen" then
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("fill", 0, 0, 800, 600)
            love.graphics.setColor(0.2, 0.2, 0.3, 0.95)
            love.graphics.rectangle("fill", 100, 200, 600, 160, 20, 20)
            love.graphics.setColor(1, 1, 1, 1)
            local bigFont = love.graphics.newFont(32)
            love.graphics.setFont(bigFont)
            love.graphics.printf(bannerText, 100, 240, 600, "center")
            love.graphics.setFont(defaultFont)
        end
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
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
    love.graphics.printf("Day " .. gamestate.day .. " | Date: " .. utils.getDateString(gamestate.date), 0, 10, 800, "center")
    love.graphics.printf("Score: " .. gamestate.score .. " | Strikes: " .. gamestate.mistakes .. "/" .. gamestate.maxMistakes, 0, 30, 800, "center")

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
        love.graphics.printf("Press C to close calendar", 0, y + (#utils.months + 2) * 20, 800, "center")
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
            love.graphics.printf(prompt, 0, y + 180, 800, "center")
        else
            love.graphics.printf("No more applicants today.", 0, y, 800, "center")
        end
    end

    -- Dwarven flavor rule at bottom
    love.graphics.setColor(0.8, 0.6, 0.2, 1) -- gold-ish
    love.graphics.printf("BY ORDER OF THE IRON COUNCIL: NO ELVES! NO CITIZENS OF ELVENMERE!", 0, 520, 800, "center")
    love.graphics.setColor(1, 1, 1, 1) -- reset color
end

function love.mousepressed(x, y, button)
    if gamestate.gameOver then
        -- Check if Restart button is clicked
        local btnW, btnH = 200, 50
        local btnX, btnY = 300, 320
        if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
            gamestate:restart()
            showIntro = true
        end
        return
    end
end