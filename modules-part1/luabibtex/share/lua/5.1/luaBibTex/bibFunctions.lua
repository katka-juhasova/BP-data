require"luno.functional"
require"luno.string"
require"luno.table"


-- Aliases:
luno.string.useAlias()
luno.table.useAlias()

luno.string.exposeSome()
luno.table.exposeSome()



-- Funções:
local function generalize(f, arg)
    local ret
    if type(arg) == "string" then
        ret = f(arg)
    elseif type(arg) == "table" then
        ret = F.map(f, arg)
    else
        error("bad argument #2 to 'generalize' (string or table expected, got " .. type(arg), 2)
    end

    return ret
end


function joinAuthors(authorsTable, sep)
    sep = sep or " and " -- Precisa ser atualizada para ajustar corretamente o último nome --<<<<<
    --local prependComma = prepend", "
    local authorNames = map(joinWords, authorsTable)
    --local authorNames2 = map(prependComma, drop(1, authorNames))
    --authorNames2 = table.insert(authorNames2, 1, authorNames[1])
    local ret = join(authorNames, ", ")
    return ret
end


function putLastNameFirst(tbName)
    local list = copy(tbName)
    table.insert(list, 1, table.remove(list))
    return list
end


function encloseParentheses(text)
    return "(" .. text .. ")"
end


function abbreviateFirstNames(tbName)
    local list = copy(tbName)
    for i = 1, #list-1 do
        list[i] = string.sub(list[i], 1, 1) .. "."
    end
    return list
end


function texFormatItalics(text)
    local f = function(x) return "{\\em " .. x .. "}" end
    return generalize(f, text)
end


function formatItalics(text)
    local f = function(x) return "\\emph{" .. x .. "}" end
    return generalize(f, text)
end


function formatBold(text)
    local f = function(x) return "\\textbf{" .. x .. "}" end
    return generalize(f, text)
end


function upperCase(arg)
    return generalize(string.upper, arg)
end


function prepend(str)
    return function(text)
        return str .. text
    end
end

function append(str)
    return function(text)
        return text .. str
    end
end

-- Considerar colocar esta função em outro arquivo: --<<<<<
function nextChar(ch)
    return string.char(string.byte(ch) + 1)
end


function formatItems(bblItems, formatter)

end


function sortBy(tb, field, comp)
    comp = comp or function(a, b) return a <= b end

    for ini = 1, #tb-1 do
        for i = ini, #tb do
            if not comp(tb[ini][field], tb[i][field]) then
                tb[ini], tb[i] = tb[i], tb[ini]
            end
        end
    end
end


function sortByAuthor(refs, comp)
    comp = comp or function(a, b) return a <= b end

    for ini = 1, #refs-1 do
        for i = ini, #refs do
            if not comp(refs[ini].author[1][1], refs[i].author[1][1]) then
                refs[ini], refs[i] = refs[i], refs[ini]
            end
        end
    end
end


function sortByAuthorLastName(refs, comp)
    comp = comp or function(a, b) return a <= b end

    for ini = 1, #refs-1 do
        --printDeep(refs[ini].author[1]) --<<<<<
        for i = ini, #refs do
            local key1 = string.lower(trim(joinWords(refs[ini].author[1].von) .. " " .. joinWords(refs[ini].author[1].last)))
            local key2 = string.lower(trim(joinWords(refs[i].author[1].von) .. " " .. joinWords(refs[i].author[1].last)))
            if not comp(key1, key2) then
                refs[ini], refs[i] = refs[i], refs[ini]
            end
        end
    end
end


function firstLetterUpperCase(text)
    local c = string.upper(lstring.firstChar(text))
    return c .. string.lower(lstring.removeFirst(text))
end

--##############################################################################
-- Funções nativas do BibTeX:

function joinName(name)
    local ret = ""
    if not ltable.isEmpty(name.first) then
        ret = ret .. join(name.first, "~") .. " "
    end
    if not ltable.isEmpty(name.von) then
        ret = ret .. join(name.von, "~") .. " "
    end
    if not ltable.isEmpty(name.last) then
        ret = ret .. joinWords(name.last) .. " "
    end
    if not ltable.isEmpty(name.jr) then
        ret = ret .. ", " .. joinWords(name.jr)
    end
    ret = trim(ret)
    return ret
end


function changeCase(text, mode)
    local f
    if mode == "l" then
        f = string.lower
    elseif mode == "u" then
        f = string.upper
    elseif mode == "t" then
        f = function(text)
            local ret = string.lower(text)
            ret = string.gsub(ret, "^(%a)", string.upper)
            ret = string.gsub(ret, "(:%s*%a)", string.upper)
            return ret
        end
    else
        error("Invalid value for mode: " .. mode .. ". Use 'l', 'u', or 't'.", 2)
    end
    return f(text)
end
