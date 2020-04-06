require"luno.string"
require"luno.table"
require"luno.io"
require"luno.util"
require"luno.functional"
require"luaBibTex.bibFunctions"
require"luaBibTex.nameObject"

luno.useAliases()
luno.functional.exposeAll()

bibParser = {}

--[[
@book{agrawal001,
    author    = "Govind P. Agrawal",
    title     = "Fiber-Optic Communication Systems",
    publisher = "Wiley Inter-Science",
    year      = "2002",
}
...

--------------------------------------------------------------------------------
items =
{
    agrawal001 =
    {
        refType   = "book",
        author    = {{"Govind", "P.", "Agrawal"}},
        title     = "Fiber-Optic Communication Systems",
        publisher = "Wiley Inter-Science",
        year      = "2002",
    },
}
]]

teste = [[@book{agrawal001,
    author    = "Govind P. Agrawal",
    title     = "Fiber-Optic Communication Systems",
    publisher = "Wiley Inter-Science",
    year      = "2002",
}
]]

local refPattern = "@(%w+%b{})"
local refTypePattern = "(%w+)(%b{})"
local refNamePattern = "{([%w%.]+),"


---
--    Nomes ficam em uma tabela como a seguinte:
--    {
--        first = "",
--        von   = "",
--        last  = "",
--        jr    = "",
--    }
--
function bibParser.parseName(name)
    local nameObj = NameObject()
    nameObj:parse(name)
    return nameObj
end


function bibParser.parseKeyValue(fieldLine)
    fieldLine = pipe(trim, lstring.removeLast)(fieldLine)
    local key, value = unpack(map(trim, split(fieldLine, "=")))
    return key, value
end


function bibParser.parseRefBody(refBody)
    -- Remover as chaves no início e no final
    refBody = gtrim(refBody, "%s*{", "}%s*")

    -- Remover linhas em branco:
    local lines = filter(partial(op.ne, ""), map(trim, splitLines(refBody)))

    -- Remover a vírgula no final da linha:
    local refName = lstring.grtrim(lines[1], ",%s*")

    -- Ler os campos:
    local fields = {}
    for i = 2, #lines do
        local key, value = bibParser.parseKeyValue(lines[i])
        value = gtrim(value, "\"")
        fields[key] = value
    end

    -- Acertar nomes: (Cada nome fica em uma tabela e as partes do nome também são separadas)
    nameFields = {"author", "editor"}
    for i, fieldName in ipairs(nameFields) do
        if fields[fieldName] ~= nil then
            fields[fieldName] = split(fields[fieldName], "%s+and%s+")
            fields[fieldName] = map(bibParser.parseName, fields[fieldName])
        end
    end

    return refName, fields
end


function bibParser.parseBibItem(bibItem)
    local refName
    local fields
    local results = {string.find(bibItem, refTypePattern)}
    if not isEmpty(results) then
        refName, fields = bibParser.parseRefBody(results[4])
        fields.refType = results[3]
    end
    return fields, refName
end


function bibParser.parseDatabase(bibContents)
    local entry = {string.find(bibContents, refPattern)}
    local items = {}
    while not isEmpty(entry) do
        local item, refName = bibParser.parseBibItem(entry[3])
        if refName ~= nil and trim(refName) ~= "" then
            items[refName] = item
        end
        entry = {string.find(bibContents, refPattern, entry[2]+1)}
    end
    return items
end
