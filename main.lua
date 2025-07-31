local gamestate = require("gamestate")
local rules = require("rules")
local utils = require("utils")

function love.load()
    gamestate.init()
end

function love.keypressed(key)
    if gamestate.gameOver then return end

    local applicant = gamestate:getCurrentApplicant()
    local ruleSet = gamestate.rules
    local currentDate = gamestate.date

    if key == "a" then
        if rules.checkApplicant(applicant, ruleSet, currentDate) then
            gamestate:increaseScore()
        else
            gamestate:addMistake()
        end
        gamestate:advance()

    elseif key == "d" then
        if not rules.checkApplicant(applicant, ruleSet, currentDate) then
            gamestate:increaseScore()
        else
            gamestate:addMistake()
        end
        gamestate:advance()

    elseif key == "k" then
        gamestate:toggleAllies()
    end
end

function love.draw()
    if gamestate.gameOver then
        love.graphics.printf("Game Over! Final Score: " .. gamestate.score, 0, 200, 800, "center")
        return
    end

    love.graphics.printf("Day " .. gamestate.day .. " | Date: " .. utils.getDateString(gamestate.date), 0, 10, 800, "center")
    love.graphics.printf("Score: " .. gamestate.score .. " | Strikes: " .. gamestate.mistakes .. "/" .. gamestate.maxMistakes, 0, 30, 800, "center")

    local ruleSet = gamestate.rules

    love.graphics.printf("Admittance Rules:", 10, 60, 800, "left")
    if ruleSet.requireRace then
        love.graphics.printf("- Must be of race: " .. ruleSet.requireRace, 30, 80, 800, "left")
    end
    if ruleSet.requireAlly then
        love.graphics.printf("- Must be from an allied kingdom", 30, 100, 800, "left")
    end
    if ruleSet.noExpiredPassports then
        love.graphics.printf("- Passport must not be expired", 30, 120, 800, "left")
    end

    local y = 160

    if gamestate.showAllies then
        love.graphics.printf("Current Allied Kingdoms:", 10, y, 800, "left")
        for i, k in ipairs(ruleSet.alliedKingdoms or {}) do
            love.graphics.printf("- " .. k, 30, y + i * 20, 800, "left")
        end
    else
        local applicant = gamestate:getCurrentApplicant()
        love.graphics.printf("Applicant " .. gamestate.currentIndex .. " of " .. gamestate.maxApplicantsPerDay, 0, y, 800, "center")
        love.graphics.printf("Name: " .. applicant.name, 0, y + 40, 800, "center")
        love.graphics.printf("Race: " .. applicant.race, 0, y + 70, 800, "center")
        love.graphics.printf("Kingdom: " .. applicant.kingdom, 0, y + 100, 800, "center")
        love.graphics.printf("Passport Expiry: " .. utils.getDateString(applicant.passportExpiry), 0, y + 130, 800, "center")

        love.graphics.printf("Press A to Approve, D to Deny, K to View Allies", 0, y + 180, 800, "center")
    end
end