local applicant = require("applicant")
local rules = require("rules")
local utils = require("utils")

local M = {}

function M:isForbiddenApplicant(applicant)
    return applicant and (applicant.race == "Elf" or applicant.kingdom == "Elvenmere")
end

function M.init()
    math.randomseed(os.time())

    M.day = 1
    M.maxApplicantsPerDay = 5
    M.applicantsToday = 0

    M.score = 0
    M.mistakes = 0
    M.maxMistakes = 3
    M.approvalsToday = 0
    M.maxDays = 7

    M.gameOver = false
    M.specialGameOver = false
    M.showAllies = false
    M.showCalendar = false
    M.showRegulations = false

    -- Randomise start date
    local startMonth = utils.months[math.random(1, #utils.months)]
    local startDay = math.random(1, 10)
    local startYear = math.random(1320, 1330)
    M.date = { day = startDay, month = startMonth, year = startYear }

    M.applicants = {}
    M.currentIndex = 1

    M.rules = rules.getRulesForDay(M.day)
    
    M:generateApplicants()
end

function M:generateApplicants()
    self.applicants = {}
    local ruleSet = self.rules
    local currentDate = self.date
    -- Ensure passport expiry rule persists after Day 2
    if self.day >= 2 then
        ruleSet.noExpiredPassports = true
    end

    local function biasedApplicant(year)
        local a = applicant.generateApplicant(year)
        if ruleSet.requireRace and math.random() < 0.5 then
            a.race = ruleSet.requireRace
        end
        if ruleSet.requireAlly and ruleSet.alliedKingdoms and #ruleSet.alliedKingdoms > 0 and math.random() < 0.5 then
            a.kingdom = ruleSet.alliedKingdoms[math.random(#ruleSet.alliedKingdoms)]
        end
        if ruleSet.noExpiredPassports and math.random() < 0.5 then
            -- Make sure passport is valid (not expired and not expiring today)
            a.passportExpiry.year = currentDate.year
            a.passportExpiry.month = currentDate.month
            a.passportExpiry.day = currentDate.day + 1
            if a.passportExpiry.day > 10 then
                a.passportExpiry.day = 1
            end
        end
        return a
    end

    if self.day == 1 then
        -- All passports are valid on day 1
        for i = 1, self.maxApplicantsPerDay do
            local a = applicant.generateApplicant(self.date.year)
            a.passportExpiry.year = currentDate.year
            a.passportExpiry.month = currentDate.month
            a.passportExpiry.day = currentDate.day + 1
            if a.passportExpiry.day > 10 then
                a.passportExpiry.day = 1
            end
            table.insert(self.applicants, a)
        end
    elseif self.day == self.maxDays then
        -- Last day: guarantee at least one Elf or Elvenmere applicant with correct name pool
        local trickRace, trickKingdom
        if math.random() < 0.5 then
            trickRace = "Elf"
            trickKingdom = "Kharzakul" -- not Elvenmere
        else
            trickRace = "Dwarf"
            trickKingdom = "Elvenmere"
        end
        local trickApplicant = applicant.generateApplicant(self.date.year)
        trickApplicant.race = trickRace
        trickApplicant.kingdom = trickKingdom
        -- Re-assign name and surname from correct race pool
        if applicant.namePools and applicant.namePools[trickRace] then
            local pool = applicant.namePools[trickRace]
            trickApplicant.name = pool[math.random(#pool)]
        end
        if applicant.surnamePools and applicant.surnamePools[trickRace] then
            local pool = applicant.surnamePools[trickRace]
            trickApplicant.surname = pool[math.random(#pool)]
        end
        table.insert(self.applicants, trickApplicant)
        for i = 2, self.maxApplicantsPerDay do
            table.insert(self.applicants, biasedApplicant(self.date.year))
        end
        -- Shuffle applicants
        for i = #self.applicants, 2, -1 do
            local j = math.random(i)
            self.applicants[i], self.applicants[j] = self.applicants[j], self.applicants[i]
        end
    else
        for i = 1, self.maxApplicantsPerDay - 1 do
            table.insert(self.applicants, biasedApplicant(self.date.year))
        end
        local validApplicant = applicant.generateApplicant(self.date.year)
        local tries = 0
        while not rules.checkApplicant(validApplicant, ruleSet, currentDate) and tries < 100 do
            validApplicant = applicant.generateApplicant(self.date.year)
            tries = tries + 1
        end
        table.insert(self.applicants, validApplicant)
        for i = #self.applicants, 2, -1 do
            local j = math.random(i)
            self.applicants[i], self.applicants[j] = self.applicants[j], self.applicants[i]
        end
    end
end

function M:advance()
    self.currentIndex = self.currentIndex + 1
    self.applicantsToday = self.applicantsToday + 1

    if self.applicantsToday >= self.maxApplicantsPerDay then
        if self.approvalsToday < 1 then
            self.gameOver = true
            return
        end
        self.approvalsToday = 0
        self.day = self.day + 1
        self.applicantsToday = 0
        self.currentIndex = 1
        utils.advanceDate(self.date)

        self.rules = rules.getRulesForDay(self.day)
        self:generateApplicants()
        if self.day > self.maxDays then
            self.victoryGameOver = true
            self.gameOver = true
        end
    end
    if self.gameOver then return end
end

function M:getCurrentApplicant()
    return self.applicants[self.currentIndex]
end

function M:increaseScore()
    self.score = self.score + 1
    self.approvalsToday = self.approvalsToday + 1
    if self.gameOver then return end
end

function M:addMistake()
    self.mistakes = self.mistakes + 1
    self.lastActionWasApproval = false
    if self.mistakes >= self.maxMistakes then
        self.gameOver = true
    end
    if self.gameOver then return end
end

function M:toggleAllies()
    self.showAllies = not self.showAllies
end

function M:toggleCalendar()
    self.showCalendar = not self.showCalendar
end

return M