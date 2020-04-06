require"lfs"

require"luno.argReader"
require"luno.table"
require"luno.util"
require"luno.functional"
luno.functional.exposeAll()

require"luaBibTex.bibFunctions"
require"luaBibTex.auxParser"
require"luaBibTex.bibParser"
require"luaBibTex.bblGenerator"
require"luaBibTex.logger"
fsh = require"luaBibTex.fileSystemHelper"


--##############################################################################
--bibDir = [[C:\Eric\UFF\Mestrado\Dissertacao\Base\Dissertacao\trunk]]
--bibFile = bibDir .. "\\referencias.bib"
--auxFile = "dissertacao.aux"
--auxFileName = bibDir .. "\\" .. auxFile


--##############################################################################
fieldTypes =
{
    article       = {"author", "title", "journal",
                     "volume", "number", "pages",
                     "year", "month", "note"},

    book          = {"author", "title", "publisher",
                     "volume", "number", "series",
                     "address", "edition", "year", "month", "note"},

    incollection  = {"author", "title", "booktitle", "publisher",
                     "year", "editor", "volume", "number",
                     "series", "type", "chapter", "pages",
                     "address", "edition", "month", "note"},

    techreport    = {"author", "title", "institution", "year",
                     "type", "number", "address", "month", "note"},

    booklet       = {"title", "author", "howpublished", "address",
                     "month", "year", "note"},

    conference    = {"author", "title", "booktitle", "editor",
                    "volume", "number", "series", "pages",
                    "address", "year", "month", "publisher", "note"},

    mastersthesis = {"author", "title", "school", "type",
                     "address", "year", "month", "note"},

    phdthesis     = {"author", "title", "year", "school",
                     "address", "month", "keywords", "note"},

    inbook        = {"author", "title", "editor", "booktitle", "chapter",
                     "pages", "publisher", "year", "volume", "number",
                     "series", "type", "address", "edition", "month", "note"},

    misc          = {"author", "title", "howpublished",
                     "year", "month", "note"},
}
fieldTypes.inproceedings = fieldTypes.conference




--##############################################################################

--------------------------------------------------------------------------------
function loadBibStyle(bibStyleFileName, bibSearchPath)
    local bibStyle
    local styleFile
    for i, dir in ipairs(bibSearchPath) do
        styleFile = dir .. "/" .. bibStyleFileName
        if fsh.pathExists(styleFile) then
            bibStyle = dofile(styleFile)
            break
        end
    end

    return bibStyle, styleFile
end


function getDirFromPath(path)
    return string.match(path, "(.-)[\\/]%?") or ""
end
--------------------------------------------------------------------------------
function main(...)

    local bibSearchPath = split(package.path, ";")
    bibSearchPath = map(getDirFromPath, bibSearchPath)
    bibSearchPath = map(rpartial(op.cat, "/luaBibTex"), bibSearchPath)

    local arg = {...}
    local baseName = arg[1]

    -- Pegar as informações no arquivo .aux:
    local auxFileName = baseName .. ".aux"
    local auxContents = luno.io.getTextFromFile(auxFileName)
    local auxData = auxParser.parseContents(auxContents)
    logger.logEvent("Usando arquivo aux: " .. auxFileName)

    -- Pegar as informações do arquivo .bib:
    local bibFileName = auxData.bibSource .. ".bib"
    local bibContents = luno.io.getTextFromFile(bibFileName)
    local bibData = bibParser.parseDatabase(bibContents)

    -- Carregar estilos:
    local bibStyleFileName = auxData.bibStyle .. ".lbst"
    local bibStyle, styleFile = loadBibStyle(bibStyleFileName, bibSearchPath)
    if bibStyle ~= nil then
        logger.logEvent("Usando arquivo de estilos : " .. styleFile)
    else
        error("Bibfile " .. bibStyleFileName .. " not found", 2)
    end

    -- Gerar .bbl:
    local bblContents = bblGenerator.createBblContents(auxData, bibData, bibStyle)
    luno.io.saveTextToFile(bblContents, baseName .. ".bbl")

    --printDeep(bibData)
    --printDeep(auxData)
    --printDeep(referenceList)
    --printDeep(bblItems)
    --print(bblContents)
end


--main(...)
