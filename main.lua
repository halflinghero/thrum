function love.load()
    love.graphics.setFont(love.graphics.newFont(16))
    math.randomseed(os.time())

    currentEntry = {}
    entryNumber = 0
    score = 0
    strikes = 0
    maxStrikes = 3
    currentDay = 1

    days = {
        {
            name = "Day 1",
            rules = {
                { description = "Only dwarves allowed", check = function(entry) return entry.species == "Dwarf" end },
                { description = "No expired documents", check = function(entry) return entry.valid == true end },
            }
        },
        {
            name = "Day 2",
            rules = {
                { description = "Only dwarves from Durgondar", check = function(entry) return entry.species == "Dwarf" and entry.kingdom == "Durgondar" end },
                { description = "No expired documents", check = function(entry) return entry.valid == true end },
            }
        },
        {
            name = "Day 3",
            rules = {
                { description = "No gnomes or elves", check = function(entry) return entry.species ~= "Elf" and entry.species ~= "Gnome" end },
                { description = "Must be from allied kingdoms", check = function(entry)
                    local allies = { Durgondar = true, Khazgrim = true }
                    return allies[entry.kingdom] == true
                end }
            }
        }
    }

    entriesPerDay = 5
    loadNextEntry()
end

function loadNextEntry()
    if strikes >= maxStrikes then
        currentEntry = nil
        return
    end

    if entryNumber >= entriesPerDay then
        currentDay = currentDay + 1
        entryNumber = 0
        if currentDay > #days then
            currentEntry = nil
            return
        end
    end

    entryNumber = entryNumber + 1

    local names = {"Durgin", "Thrain", "Borin", "Fundin", "Khazrak", "Durgrim", "Magni", "Thorek", "Balin", "Oin", "Gimli"}
    local kingdoms = {"Durgondar", "Khazgrim", "Elvaria", "Gnomeregan", "Stonehelm"}
    local species = {"Dwarf", "Elf", "Gnome", "Human"}

    currentEntry = {
        name = names[math.random(#names)],
        kingdom = kingdoms[math.random(#kingdoms)],
        species = species[math.random(#species)],
        valid = math.random() > 0.2 -- 80% chance it's valid
    }
end

function love.keypressed(key)
    if not currentEntry then return end

    if key == "a" then
        evaluateEntry(true)
    elseif key == "d" then
        evaluateEntry(false)
    end
end

function evaluateEntry(approved)
    local rules = days[currentDay].rules
    local passed = true
    for _, rule in ipairs(rules) do
        if not rule.check(currentEntry) then
            passed = false
            break
        end
    end

    local correct = (passed and approved) or (not passed and not approved)

    if correct then
        score = score + 1
    else
        strikes = strikes + 1
    end

    loadNextEntry()
end

function love.draw()
    if strikes >= maxStrikes then
        love.graphics.print("Game Over - You made too many mistakes!", 20, 20)
        love.graphics.print("Final Score: " .. score, 20, 50)
        return
    end

    if not currentEntry then
        love.graphics.print("You completed all days!", 20, 20)
        love.graphics.print("Final Score: " .. score, 20, 50)
        return
    end

    love.graphics.print("Day: " .. currentDay .. " - " .. days[currentDay].name, 20, 20)
    love.graphics.print("Entry #: " .. entryNumber .. "/" .. entriesPerDay, 20, 40)
    love.graphics.print("Score: " .. score .. "   Strikes: " .. strikes .. "/" .. maxStrikes, 20, 60)

    love.graphics.print("Passport Info:", 20, 100)
    love.graphics.print("Name: " .. currentEntry.name, 40, 130)
    love.graphics.print("Kingdom: " .. currentEntry.kingdom, 40, 150)
    love.graphics.print("Species: " .. currentEntry.species, 40, 170)
    love.graphics.print("Valid Document: " .. (currentEntry.valid and "Yes" or "No"), 40, 190)

    love.graphics.print("Today's Rules:", 300, 100)
    for i, rule in ipairs(days[currentDay].rules) do
        love.graphics.print("- " .. rule.description, 320, 120 + i * 20)
    end

    love.graphics.print("Press [A] to APPROVE, [D] to DENY", 20, 250)
end