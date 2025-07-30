function love.load()
    math.randomseed(os.time())

    -- Game state (local to love.load, but stored in globals for access)
    -- We'll declare these as locals outside love.load for broader access.
end

-- Declare variables local at the top-level scope so all functions can access them
local applicants = {}
local currentIndex = 1
local score = 0
local mistakes = 0
local maxMistakes = 3
local day = 1
local maxApplicantsPerDay = 5
local applicantsToday = 0
local gameOver = false
local showAllies = false

-- Static data
local races = {"Dwarf", "Elf", "Human", "Orc", "Goblin"}
local kingdoms = {"Durgondar", "Kharzakul", "Thrainholme", "Elvenmere", "Stonevale", "Mordakar", "Irondeep"}

-- These kingdoms are allies for day 1
local alliedKingdoms = {"Durgondar", "Kharzakul", "Stonevale"}

-- Rules
local rules = {
    requireRace = "Dwarf",
    requireAlly = true,
    noExpiredPassports = true
}

function generateName()
    local syllables = {"Dur", "Grom", "Thra", "Kaz", "Bol", "Guld", "Nor", "Rag", "Zul", "Brok"}
    return syllables[math.random(#syllables)] .. syllables[math.random(#syllables)]
end

function generateApplicant()
    local applicant = {
        name = generateName(),
        race = races[math.random(#races)],
        kingdom = kingdoms[math.random(#kingdoms)],
        passportExpiry = math.random(2020, 2027)
    }
    return applicant
end

function checkApplicant(applicant)
    local isValid = true

    if rules.requireRace and applicant.race ~= rules.requireRace then
        isValid = false
    end

    if rules.requireAlly then
        local isAlly = false
        for _, ally in ipairs(alliedKingdoms) do
            if applicant.kingdom == ally then
                isAlly = true
                break
            end
        end
        if not isAlly then
            isValid = false
        end
    end

    if rules.noExpiredPassports and applicant.passportExpiry < 2025 then
        isValid = false
    end

    return isValid
end

function advanceApplicant()
    currentIndex = currentIndex + 1
    applicantsToday = applicantsToday + 1

    if applicantsToday >= maxApplicantsPerDay then
        -- End of day
        day = day + 1
        applicantsToday = 0
        currentIndex = 1
        applicants = {}
        for i = 1, maxApplicantsPerDay do
            table.insert(applicants, generateApplicant())
        end
        -- Optional: change rules/allies here per day
    end
end

function love.load()
    math.randomseed(os.time())
    applicants = {}
    currentIndex = 1
    score = 0
    mistakes = 0
    day = 1
    applicantsToday = 0
    gameOver = false
    showAllies = false

    -- Generate initial applicants
    for i = 1, maxApplicantsPerDay do
        table.insert(applicants, generateApplicant())
    end
end

function love.keypressed(key)
    if gameOver then return end

    local applicant = applicants[currentIndex]

    if key == "a" then
        -- Approve
        if checkApplicant(applicant) then
            score = score + 1
        else
            mistakes = mistakes + 1
        end
        advanceApplicant()
    elseif key == "d" then
        -- Deny
        if not checkApplicant(applicant) then
            score = score + 1
        else
            mistakes = mistakes + 1
        end
        advanceApplicant()
    elseif key == "k" then
        showAllies = not showAllies
    end

    if mistakes >= maxMistakes then
        gameOver = true
    end
end

function love.draw()
    if gameOver then
        love.graphics.printf("Game Over! Final Score: " .. score, 0, 200, 800, "center")
        return
    end

    love.graphics.printf("Day " .. day, 0, 10, 800, "center")
    love.graphics.printf("Score: " .. score .. " | Strikes: " .. mistakes .. "/" .. maxMistakes, 0, 30, 800, "center")

    if showAllies then
        love.graphics.printf("Current Allied Kingdoms:", 10, 60, 800, "left")
        for i, k in ipairs(alliedKingdoms) do
            love.graphics.printf("- " .. k, 30, 60 + i * 20, 800, "left")
        end
    else
        local applicant = applicants[currentIndex]
        love.graphics.printf("Applicant " .. currentIndex .. " of " .. maxApplicantsPerDay, 0, 80, 800, "center")
        love.graphics.printf("Name: " .. applicant.name, 0, 120, 800, "center")
        love.graphics.printf("Race: " .. applicant.race, 0, 150, 800, "center")
        love.graphics.printf("Kingdom: " .. applicant.kingdom, 0, 180, 800, "center")
        love.graphics.printf("Passport Expiry: " .. applicant.passportExpiry, 0, 210, 800, "center")

        love.graphics.printf("Press A to Approve, D to Deny, K to View Allies", 0, 260, 800, "center")
    end
end
