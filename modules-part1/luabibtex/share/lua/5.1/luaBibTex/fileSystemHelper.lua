require "lfs"

fileSystemHelper = {}

function fileSystemHelper.copy(from, to)
    -- Se o destino for um diretório => concatenar o nome do arquivo:
    local filename = string.match(from, ".+/(.+)$") or from
    if isDir(to) then
        to = to .. "/" .. filename
    end

    -- Obter conteúdo do arquivo de origem:
    local hfrom = io.open(from, "rb")
    local contents = hfrom:read("*a")
    hfrom:close()

    -- Gravar o arquivo de saída:
    local hto = io.open(to, "wb")
    hto:write(contents)
    hto:close()
end


function fileSystemHelper.vcopy(from, to, verbose)
    copy(from, to)
    if verbose == true then
        print("Copiado: " .. from .. " -> " .. to)
    end
end


function fileSystemHelper.isDir(path)
    return lfs.attributes(path, "mode") == "directory"
end


function fileSystemHelper.pathExists(path)
    return lfs.attributes(path) ~= nil
end


return fileSystemHelper
