
require "luno.oop"
require "luno.functional"
require "luno.string"
luno.functional.exposeAll()
luno.string.exposeSome()


class "NameObject"

function NameObject.init(obj)
    obj.first = {}
    obj.von   = {}
    obj.last  = {}
    obj.jr    = {}
end


function NameObject.getFirst(obj)
    return obj.first
end


function NameObject.getLast(obj)
    return obj.last
end


function NameObject.getVon(obj)
    return obj.von
end


function NameObject.getJr(obj)
    return obj.jr
end


function NameObject.setFirst(obj, first)
    obj.first = first
end


function NameObject.setLast(obj, last)
    obj.last = last
end


function NameObject.setVon(obj, von)
    obj.von = von
end


function NameObject.setJr(obj, jr)
    obj.jr = jr
end


local function findVonPart(splitedName)
    -- Identificar a parte "von":
    local bVon, eVon
    for i, part in ipairs(splitedName) do
        if lstring.beginsWith("%l", part) then
            bVon = i
            break
        end
    end

    if bVon ~= nil then
        local i = bVon
        while splitedName[i] ~= nil and lstring.beginsWith("%l", splitedName[i]) do
            eVon = i
            i = i + 1
        end
    end

    return bVon, eVon
end


function NameObject.parse(obj, name)
    name = trim(name)
    local nameList = map(trim, split(name, ","))
    if #nameList == 1 then
        -- Estilo "First von Last"
        local parts = splitWords(name)
        if #parts == 1 then
            obj:setLast(parts)
        else
            -- Identificar a parte "von":
            local bVon, eVon = findVonPart(parts)

            if bVon ~= nil then
                obj:setFirst(ltable.slice(parts, 1, bVon-1))
                obj:setVon(ltable.slice(parts, bVon, eVon))
                obj:setLast(ltable.slice(parts, eVon + 1))
            else -- sem parte von
                obj:setLast{last(parts)}
                obj:setFirst(init(parts))
            end
        end

    elseif #nameList == 2 then
        -- Estilo "von Last, First"
        obj:setFirst(splitWords(last(nameList)))

        -- Identificar von e last:
        local parts = splitWords(head(nameList))
        local bVon, eVon = findVonPart(parts)
        if bVon ~= 1 then
            -- Sem parte "von"
            obj:setLast(parts)
        else
            obj:setVon(ltable.slice(parts, bVon, eVon))
            obj:setLast(ltable.slice(parts, eVon + 1))
        end

    elseif #nameList == 3 then
        -- Estilo "von Last, Jr, First"
        obj:setFirst(splitWords(last(nameList)))
        obj:setJr(splitWords(nameList[2]))

        -- Identificar von e last:
        local parts = splitWords(head(nameList))
        local bVon, eVon = findVonPart(parts)
        if bVon ~= 1 then
            -- Sem parte "von"
            obj:setLast(parts)
        else
            obj:setVon(ltable.slice(parts, bVon, eVon))
            obj:setLast(ltable.slice(parts, eVon + 1))
        end

    else
        -- Erro no arquivo .bib
    end

    return obj
end
