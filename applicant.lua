local utils = require("utils")
local M = {}


local races = {"Dwarf", "Elf", "Human", "Halfling", "Gnome"}
local kingdoms = {"Durgondar", "Kharzakul", "Thrainholme", "Elvenmere", "Stonevale", "Mordakar", "Irondeep"}

local namePools = {
    Dwarf = {
        first = {"Durin", "Brok", "Kazgar", "Thrain", "Guldin", "Norin", "Ragnar", "Bolgar", "Balin", "Gromli"},
        last = {"Stonebeard", "Ironfoot", "Goldhelm", "Deepdelver", "Hammerhand", "Rockfist"}
    },
    Elf = {
        first = {"Elandor", "Thaliel", "Lirael", "Faelar", "Sylvar", "Aerendil", "Galadren", "Celethil"},
        last = {"Moonwhisper", "Starbloom", "Silverleaf", "Dawnrunner"}
    },
    Human = {
        first = {"Edric", "Mira", "Joren", "Lysa", "Tomas", "Kara", "George", "Sara", "Gavin", "Rosa"},
        last = {"Smith", "Brown", "Carter", "Mason", "Turner", "Baker"}
    },
    Halfling = {
        first = {"Pip", "Milo", "Rosie", "Samlin", "Daisy", "Frodo", "Lobelia", "Merry", "Ponto"},
        last = {"Underfoot", "Brandybuck", "Goodbarrel", "Greenhill", "Yonder"}
    },
    Gnome = {
        first = {"Fizz", "Tink", "Nim", "Boddynock", "Wizzle", "Glim", "Zook", "Quill"},
        last = {"Cogspinner", "Nimblefizz", "Sparkwhistle", "Muddlemuck"}
    }
}

function M.generateName(race)
    local pool = namePools[race] or namePools["Human"]
    local first = pool.first[math.random(#pool.first)]
    local last = pool.last[math.random(#pool.last)]
    return first .. " " .. last
end

function M.generateApplicant(currentYear)
    local monthNum = math.random(1, #utils.months)
    local expiryYear = math.random(currentYear - 2, currentYear + 3)
    local expiryMonth = utils.monthNumberToName(math.random(1, #utils.months))
    local expiryDay = math.random(1, 10)
    local race = races[math.random(#races)]
    return {
        name = M.generateName(race),
        race = race,
        kingdom = kingdoms[math.random(#kingdoms)],
        passportExpiry = {
            year = expiryYear,
            month = expiryMonth,
            day = expiryDay
        }
    }
end

return M