local utils = require("utils")
local M = {}

local syllables = {"Dur", "Grom", "Thra", "Kaz", "Bol", "Guld", "Nor", "Rag", "Zul", "Brok"}
local suffixes = {"mir", "dor", "gash", "vek", "in", "or", "dun", "rak", "thar", "ul"}

local races = {"Dwarf", "Elf", "Human", "Orc", "Goblin"}
local kingdoms = {"Durgondar", "Kharzakul", "Thrainholme", "Elvenmere", "Stonevale", "Mordakar", "Irondeep"}

function M.generateName()
    local prefix = syllables[math.random(#syllables)]
    local suffix = suffixes[math.random(#suffixes)]
    return prefix .. suffix
end

function M.generateApplicant(currentYear)
    local monthNum = math.random(1, #utils.months)
    return {
        name = M.generateName(),
        race = races[math.random(#races)],
        kingdom = kingdoms[math.random(#kingdoms)],
        passportExpiry = {
            year = math.random(currentYear - 1, currentYear + 3),
            month = utils.monthNumberToName(monthNum),
            day = math.random(1,10)
        }
    }
end

return M