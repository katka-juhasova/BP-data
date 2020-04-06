
require"luno.string"
require"luno.functional"

luno.functional.exposeAll()
luno.string.useAlias()
luno.string.exposeSome()

--##############################################################################
bblGenerator = {}

bblGenerator.MAX_LINE = 80

function bblGenerator.breakLine(line, maxLine)
    local ret = {}
    local uini, ufim
    local ini, fim = 0, 0
    if #line < maxLine then
        ret = {line, nil}
    else
        while fim ~= nil and fim <= maxLine do
            ini, fim = string.find(line, "%W%w", fim+1)
            if fim == nil or fim > maxLine then
                ret[1] = trim(string.sub(line, 1, uini))
                if ufim ~= nil then
                    ret[2] = "  " .. string.sub(line, ufim)
                end
            end
            uini, ufim = ini, fim
        end
    end
    return ret
end

function bblGenerator.breakLines(text, maxLine)
    local lines = lstring.splitLines(text)
    for i, line in ipairs(lines) do
        if #line > maxLine then
            local blines = bblGenerator.breakLine(line, maxLine)
            lines[i] = blines[1]
            if blines[2] ~= nil then
                table.insert(lines, i+1, blines[2])
            end
        end
    end
--printDeep(lines) --<<<<<
    return joinLines(lines)
end


function bblGenerator.createBblData(auxData, bibData, bibStyle)
    -- Criar lista de referências:
    local bblData = {}
    for i, citation in ipairs(auxData.citations) do -- => Filtrar pelas publicações que aparecem nos \citation:
        local item = bibData[citation]
        -- Armazenar o nome da referência:
        item.refName = citation
        -- Armazenar a ordem de aparição no texto:
        item.docOrder = i

        table.insert(bblData, item)
    end

    -- Criar lista ordenada de acordo com o critério definido no estilo:
    bibStyle.sortBblData(bblData)

    return bblData
end


function bblGenerator.createBblContents(auxData, bibData, bibStyle)

    local bblData = bblGenerator.createBblData(auxData, bibData, bibStyle)

    -- Escrever conteúdo do arquivo .bbl:
    local bblContents = ""
    bblContents = bblContents .. "\\begin{thebibliography}{#n}\n"
    bblContents = string.gsub(bblContents, "#n", #bblData)
    bblContents = bblContents .. bibStyle.customBblHeader
    --printDeep(bblData) --<<<<<
    for i, bblEntry in ipairs(bblData) do
        --print(i, bblEntry.refName) --<<<<<
        bblContents = bblContents .. bibStyle.genItem(bblEntry) .. "\n\n"
    end
    bblContents = bblContents .. "\\end{thebibliography}\n"

    bblContents = bblGenerator.breakLines(bblContents, bblGenerator.MAX_LINE)

    return bblContents
end

