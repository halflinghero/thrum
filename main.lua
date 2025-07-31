
local gamestate = require("gamestate")
local rules = require("rules")
local utils = require("utils")

local showIntro = true

function love.load()
    gamestate.init()
    showIntro = true
end

function love.keypressed(key)
    if showIntro then
        if key == "b" then
            showIntro = false
        end
        return
    end
    if gamestate.gameOver then return end

    local applicant = gamestate:getCurrentApplicant()
    local ruleSet = gamestate.rules
    local currentDate = gamestate.date

    print("[DEBUG] Key pressed:", key)
    print("[DEBUG] Applicant race:", applicant.race)
    print("[DEBUG] Applicant kingdom:", applicant.kingdom)

    if key == "a" then
        -- Move forbidden check before rules check
        if gamestate:isForbiddenApplicant(applicant) then
            gamestate.specialGameOver = true
            gamestate.gameOver = true
            return -- Prevent further code execution
        end
        if rules.checkApplicant(applicant, ruleSet, currentDate) then
            gamestate:increaseScore()
            gamestate:advance()
        else
            gamestate:addMistake()
            gamestate:advance()
        end

    elseif key == "d" then
        if not rules.checkApplicant(applicant, ruleSet, currentDate) then
            gamestate:increaseScore()
        else
            gamestate:addMistake()
        end
        gamestate:advance()

    elseif key == "f" then
        gamestate:toggleAllies()
    elseif key == "r" then
        gamestate.showRegulations = not gamestate.showRegulations
    elseif key == "c" then
        gamestate:toggleCalendar()
    end
end

-- Helper function to check if a table contains a value
local function tableContains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

function love.draw()
    if showIntro then
        love.graphics.setColor(0.7, 0.7, 0.9, 1)
        love.graphics.rectangle("fill", 100, 200, 600, 300)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf("WELCOME TO THE GATE OF THRUM", 100, 220, 600, "center")
        love.graphics.printf("REGULATIONS:", 100, 260, 600, "center")
        love.graphics.printf("- Passports that expire on today's date are NOT valid.", 100, 290, 600, "left")
        love.graphics.printf("- No elves or citizens of Elvenmere are permitted to enter our sacred halls.", 100, 320, 600, "left")
        love.graphics.printf("- Our list of grudges is ever-growing! Always check the daily admission rules.", 100, 350, 600, "left")
        love.graphics.setColor(0, 0.2, 0.6, 1)
        love.graphics.printf("Press B to begin!", 100, 400, 600, "center")
        love.graphics.setColor(1, 1, 1, 1)
        return
    end
    if gamestate.gameOver then
        if gamestate.specialGameOver then
            love.graphics.setColor(1, 0.2, 0.2, 1)
            love.graphics.printf("GAME OVER! You let a filthy Elf or Elvenmere agent into our sacred halls!", 0, 200, 800, "center")
            love.graphics.setColor(1, 1, 1, 1)
            return
        elseif gamestate.victoryGameOver then
            love.graphics.setColor(0.8, 0.6, 0.2, 1)
            love.graphics.printf("THE WEEK IS DONE! YOU HAVE SERVED THE IRON COUNCIL WITH UNYIELDING VIGILANCE. DRINK YOUR FILL UNTIL THE NEXT WEEK'S WORK!", 0, 200, 800, "center")
            love.graphics.setColor(1, 1, 1, 1)
            return
        else
            love.graphics.printf("Game Over! Final Score: " .. gamestate.score, 0, 200, 800, "center")
            return
        end
    end

    love.graphics.printf("Day " .. gamestate.day .. " | Date: " .. utils.getDateString(gamestate.date), 0, 10, 800, "center")
    love.graphics.printf("Score: " .. gamestate.score .. " | Strikes: " .. gamestate.mistakes .. "/" .. gamestate.maxMistakes, 0, 30, 800, "center")

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
        love.graphics.printf("- Our list of grudges is ever-growing! Always check the daily admission rules.", 100, 400, 600, "left")
        love.graphics.setColor(1, 1, 1, 1)
        return
    else
        local applicant = gamestate:getCurrentApplicant()
        love.graphics.printf("Applicant " .. gamestate.currentIndex .. " of " .. gamestate.maxApplicantsPerDay, 0, y, 800, "center")
        love.graphics.printf("Name: " .. applicant.name, 0, y + 40, 800, "center")
        love.graphics.printf("Race: " .. applicant.race, 0, y + 70, 800, "center")
        love.graphics.printf("Kingdom: " .. applicant.kingdom, 0, y + 100, 800, "center")
        love.graphics.printf("Passport Expiry: " .. utils.getDateString(applicant.passportExpiry), 0, y + 130, 800, "center")

        local prompt = "Press A to Approve, D to Deny"
        if gamestate.day > 1 then prompt = prompt .. ", C to View Calendar" end
        if gamestate.day > 2 then prompt = prompt .. ", F to View Allies" end
        prompt = prompt .. ", R to Check Regulations"
        love.graphics.printf(prompt, 0, y + 180, 800, "center")
    end

    -- DWARVEN POLITICAL FLAVOR RULE
    love.graphics.setColor(0.8, 0.6, 0.2, 1) -- gold-ish
    love.graphics.printf("BY ORDER OF THE IRON COUNCIL: NO ELVES! NO CITIZENS OF ELVENMERE!", 0, 520, 800, "center")
    love.graphics.setColor(1, 1, 1, 1) -- reset color
end