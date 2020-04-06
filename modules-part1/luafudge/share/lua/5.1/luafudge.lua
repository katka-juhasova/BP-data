local fudge = {}

local levels = {}
levels.russian = {
    "хуже некуда", "совсем-совсем-совсем ужасно" , "совсем-совсем ужасно",
    "совсем ужасно", "ужасно", "плохо", "посредственно",
    "нормально", "хорошо", "прекрасно", "превосходно", "легендарно",
    "легендарно+", "легендарно++", "легендарно+++", "как Аллах"
}
levels.english = {
    "i'm a looser, baby", "very very very terrible", "very very terrible",
    "very terrible", "terrible", "poor", "mediocre",
    "fair", "good", "great", "superb", "legendary",
    "legendary+", "legendary++", "legendary+++", "like a boss"
}
levels.german = {
    "grauenhaft----", "grauenhaft---", "grauenhaft--",
    "grauenhaft-", "grauenhaft", "armselig", "unterdurchschnittlich",
    "durchschnittlich", "gut", "großartig", "superb", "legendär",
    "legendär+", "legendär++", "legendär+++", "legendär++++"
}
-- TODO: other languages

levels.default = levels.english
-- because english is locale C standard
-- and original FUDGE rulebook is in english

-- FIXME: magic numbers. Make it using levels.default
-- local default_level_key = 6
local min_level_key = 5
local max_level_key = 13

fudge.lang = "default"

function fudge.set_lang(lang)
    assert(type(lang) == "string", "lang mus be string")
    assert(levels[lang], "No such language: "..lang)
    fudge.lang = lang
end

local function to_number(level_text)
    for key, level in pairs(levels[fudge.lang]) do
        if level == level_text then
            return key
        end
    end
end

local function to_string(level_key)
    assert(type(level_key) == "number", "Argument must be a number")
    assert(levels[fudge.lang][level_key], "Level not found")
    return levels[fudge.lang][level_key]
end

function fudge.normalize(level)
    assert(fudge.is_valid(level), level.." is not valid FUDGE level")
    local level_key = to_number(level)
    if level_key < min_level_key then
        level_key = min_level_key
    elseif level_key > max_level_key then
        level_key = max_level_key
    end
    return to_string(level_key)
end

function fudge.is_valid(level)
    level = to_number(level)
    if level then
        return true
    else
        return false
    end
end

function fudge.roll()
    -- Return a 4-table of dices in numeric format
    local dices = {}
    for _ = 1, 4 do
        table.insert(dices, math.random(-1, 1))
    end
    return dices
end

function fudge.dices_to_string(dices)
    local signs = ""
    for _, value in pairs(dices) do
        if value > 0 then
            signs = signs .. "+"
        elseif value < 0 then
            signs = signs .. "-"
        else
            signs = signs .. "="
        end
    end
    return signs
end

function fudge.diff(x, y)
    -- Return a difference between two FUDGE levels
    assert(fudge.is_valid(x), x.." is not valid FUDGE level")
    assert(fudge.is_valid(y), y.." is not valid FUDGE level")
    return to_number(x) - to_number(y)
end

local function add_modifiers_table(level_key, modifiers)
    for _, i in ipairs(modifiers) do
       level_key = level_key + i
    end
    return level_key
end

function fudge.add_modifiers(level, ...)
    -- Return a level with appended modifiers
    -- modifiers can be numbers or table of numbers
    assert(fudge.is_valid(level), level.." is not valid FUDGE level")
    level = to_number(level)
    for _, i in ipairs({...}) do
        if type(i) == "table" then
            level = add_modifiers_table(level, i)
        else
            level = level + i
        end
    end
    return to_string(level)
end

return fudge
