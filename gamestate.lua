local applicant = require("applicant")
local rules = require("rules")
local utils = require("utils")

local M = {}

function M.init()
    math.randomseed(os.time())

    M.day = 1
    M.maxApplicantsPerDay = 5
    M.applicantsToday = 0

    M.score = 0
    M.mistakes = 0
    M.maxMistakes = 3

    M.gameOver = false
    M.showAllies = false

    M.date = { day = 1, month = "Dawnrise", year = 1325 }

    M.applicants = {}
    M.currentIndex = 1

    M.rules = rules.getRulesForDay(M.day)
    
    M:generateApplicants()
end

function M:generateApplicants()
    self.applicants = {}
    for i = 1, self.maxApplicantsPerDay do
        table.insert(self.applicants, applicant.generateApplicant(self.date.year))
    end
end

function M:advance()
    self.currentIndex = self.currentIndex + 1
    self.applicantsToday = self.applicantsToday + 1

    if self.applicantsToday >= self.maxApplicantsPerDay then
        -- Advance day & date
        self.day = self.day + 1
        self.applicantsToday = 0
        self.currentIndex = 1
        utils.advanceDate(self.date)

        self.rules = rules.getRulesForDay(self.day)
        self:generateApplicants()
    end
end

function M:getCurrentApplicant()
    return self.applicants[self.currentIndex]
end

function M:increaseScore()
    self.score = self.score + 1
end

function M:addMistake()
    self.mistakes = self.mistakes + 1
    if self.mistakes >= self.maxMistakes then
        self.gameOver = true
    end
end

function M:toggleAllies()
    self.showAllies = not self.showAllies
end

return M