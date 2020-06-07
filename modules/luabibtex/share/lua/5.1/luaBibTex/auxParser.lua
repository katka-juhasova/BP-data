require"luno.string"
require"luno.table"
require"luno.io"
require"luno.util"
require"luno.functional"


auxParser = {}

local function swapKeyValue(tb)
    local ret = {}
    for i, v in pairs(tb) do
        ret[v] = i
    end
    return ret
end


function auxParser.parseContents(auxContents)
    local ret = {}
    local lines = luno.string.splitLines(auxContents)

    local ini, fim
    local citations = {}
    local citationPos = 1
    local bibSource
    for i, line in ipairs(lines) do
        -- Citations:
        local ini, fim, refNames = string.find(line, "\\citation{([%w%d%._:,]+)}")
        if ini ~= nil then
            refNames = luno.string.split(refNames, ",")
            for j, refName in ipairs(refNames) do
                if citations[refName] == nil then
                    citations[refName] = citationPos
                    citationPos = citationPos + 1
                end
            end
        end

        -- BibData (em LuaBibTex passa a ser bibSource):
        ini, fim, bibSource = string.find(line, "\\bibdata{([%w%d]+)}")
        if ini ~= nil then
            ret.bibSource = bibSource
        end

        -- BibStyle:
        ini, fim, bibStyle = string.find(line, "\\bibstyle{([%w%d]+)}")
        if ini ~= nil then
            ret.bibStyle = bibStyle
        end
    end
    ret.citations = swapKeyValue(citations)

    return ret
end

