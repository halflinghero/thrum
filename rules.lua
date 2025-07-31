local utils = require("utils")

local M = {}

local ruleSets = {
    [1] = {
        requireRace = "Dwarf",
        requireAlly = true,
        noExpiredPassports = true,
        alliedKingdoms = { "Durgondar", "Kharzakul", "Stonevale" }
    },
    [2] = {
        requireRace = "Dwarf",
        requireAlly = false,
        noExpiredPassports = true,
        alliedKingdoms = {}
    },
    [3] = {
        requireRace = "Elf",
        requireAlly = true,
        noExpiredPassports = true,
        alliedKingdoms = { "Elvenmere", "Thrainholme" }
    },
    [4] = {
        requireRace = "Elf",
        requireAlly = true,
        noExpiredPassports = false,
        alliedKingdoms = { "Elvenmere", "Thrainholme" }
    },
    [5] = {
        requireRace = nil,
        requireAlly = true,
        noExpiredPassports = true,
        alliedKingdoms = { "Irondeep", "Mordakar" }
    }
}

function M.getRulesForDay(day)
    return ruleSets[day] or ruleSets[1]
end

function M.checkApplicant(applicant, ruleSet, currentDate)
    local isValid = true

    if ruleSet.requireRace and applicant.race ~= ruleSet.requireRace then
        isValid = false
    end

    if ruleSet.requireAlly then
        local isAlly = false
        for _, ally in ipairs(ruleSet.alliedKingdoms or {}) do
            if applicant.kingdom == ally then
                isAlly = true
                break
            end
        end
        if not isAlly then
            isValid = false
        end
    end

    if ruleSet.noExpiredPassports and applicant.passportExpiry then
        if utils.isDateExpired(applicant.passportExpiry, currentDate) then
            isValid = false
        end
    end

    return isValid
end

return M