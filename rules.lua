
local utils = require("utils")
local M = {}

-- Progressive rule sets for each day
local ruleSets = {
    [1] = {
        allowedRaces = { "Dwarf" },
        requireAlly = false,
        noExpiredPassports = false,
        alliedKingdoms = {}
    },
    [2] = {
        allowedRaces = { "Dwarf" },
        requireAlly = false,
        noExpiredPassports = true,
        alliedKingdoms = {}
    },
    [3] = {
        allowedRaces = { "Dwarf", "Human" },
        requireAlly = true,
        noExpiredPassports = true,
        alliedKingdoms = { "Mordakar", "Irondeep" }
    },
    [4] = {
        allowedRaces = { "Dwarf", "Halfling" },
        requireAlly = true,
        noExpiredPassports = true,
        alliedKingdoms = { "Kharzakul", "Thrainholme" }
    },
    [5] = {
        allowedRaces = { "Dwarf", "Human", "Gnome" },
        requireAlly = true,
        noExpiredPassports = true,
        alliedKingdoms = { "Irondeep", "Stonevale" }
    },
    [6] = {
        allowedRaces = { "Dwarf", "Human", "Halfling", "Gnome" },
        requireAlly = false,
        noExpiredPassports = true,
        alliedKingdoms = {}
    },
    [7] = {
        allowedRaces = { "Dwarf", "Human", "Halfling", "Gnome" },
        requireAlly = true,
        noExpiredPassports = false,
        alliedKingdoms = { "Durgondar", "Irondeep" }
    }
}

-- Returns the rule set for a given day
function M.getRulesForDay(day)
    return ruleSets[day] or ruleSets[1]
end

-- Validates an applicant against the current rule set and date
function M.checkApplicant(applicant, ruleSet, currentDate)
    -- Static rule: Elves and those from Elvenmere are always denied
    if applicant.race == "Elf" or applicant.kingdom == "Elvenmere" then
        return false
    end

    local isValid = true

    -- Allowed races check
    if ruleSet.allowedRaces then
        local found = false
        for _, race in ipairs(ruleSet.allowedRaces) do
            if applicant.race == race then
                found = true
                break
            end
        end
        if not found then
            isValid = false
        end
    elseif ruleSet.requireRace then
        -- Never allow Elf as required race
        if ruleSet.requireRace == "Elf" then
            isValid = false
        elseif applicant.race ~= ruleSet.requireRace then
            isValid = false
        end
    end

    -- Allied kingdom check
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

    -- Passport expiry check
    if ruleSet.noExpiredPassports and applicant.passportExpiry then
        if utils.isDateExpired(applicant.passportExpiry, currentDate) then
            isValid = false
        end
    end

    return isValid
end

return M