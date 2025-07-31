local M = {}

M.months = {
    "Dawnrise", "Emberfall", "Frostmere", "Thundercry",
    "Moonsong", "Starshine", "Ashveil", "Suncrest",
    "Goldleaf", "Nightbloom"
}

function M.monthNumberToName(num)
    return M.months[num] or "Unknown"
end

function M.monthNameToNumber(name)
    for i, m in ipairs(M.months) do
        if m == name then return i end
    end
    return nil
end

function M.getDateString(date)
    local suffix = "th of"
    if date.day == 1 then suffix = "st of"
    elseif date.day == 2 then suffix = "nd of"
    elseif date.day == 3 then suffix = "rd of"
    end
    return string.format("%d%s %s, Year %d", date.day, suffix, date.month, date.year)
end

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

function M.isDateExpired(applicantDate, currentDate)
    local aMonth = M.monthNameToNumber(applicantDate.month)
    local cMonth = M.monthNameToNumber(currentDate.month)

    if applicantDate.year < currentDate.year then
        return true
    elseif applicantDate.year == currentDate.year then
        if aMonth < cMonth then
            return true
        elseif aMonth == cMonth and applicantDate.day < currentDate.day then
            return true
        end
    end
    return false
end

return M