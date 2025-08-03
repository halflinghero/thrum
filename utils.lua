
local M = {}

-- List of months in the Thrum calendar
M.months = {
    "Dawnrise", "Emberfall", "Frostmere", "Thundercry",
    "Moonsong", "Starshine", "Ashveil", "Suncrest",
    "Goldleaf", "Nightbloom"
}

-- Converts a month number to its name
function M.monthNumberToName(num)
    return M.months[num] or "Unknown"
end

-- Converts a month name to its number (1-based)
function M.monthNameToNumber(name)
    for i, m in ipairs(M.months) do
        if m == name then return i end
    end
    return nil
end

-- Returns a formatted date string (e.g., "1st of Dawnrise, Year 1320")
function M.getDateString(date)
    local suffix = "th of"
    if date.day == 1 then suffix = "st of"
    elseif date.day == 2 then suffix = "nd of"
    elseif date.day == 3 then suffix = "rd of"
    end
    return string.format("%d%s %s, Year %d", date.day, suffix, date.month, date.year)
end

-- Advances the date by one day, rolling over months and years as needed
function M.advanceDate(date)
    local monthIndex = M.monthNameToNumber(date.month)
    if not monthIndex then
        error("Invalid month name: " .. tostring(date.month))
    end

    date.day = date.day + 1
    if date.day > 10 then
        date.day = 1
        monthIndex = monthIndex + 1
        if monthIndex > #M.months then
            monthIndex = 1
            date.year = date.year + 1
        end
        date.month = M.months[monthIndex]
    end
end

-- Returns true if applicantDate is before or equal to currentDate (i.e., expired)
function M.isDateExpired(applicantDate, currentDate)
    local aMonth = M.monthNameToNumber(applicantDate.month)
    local cMonth = M.monthNameToNumber(currentDate.month)

    if applicantDate.year < currentDate.year then
        return true
    elseif applicantDate.year == currentDate.year then
        if aMonth < cMonth then
            return true
        elseif aMonth == cMonth and applicantDate.day <= currentDate.day then
            return true -- Expiry on or before today is invalid
        end
    end
    return false
end

return M