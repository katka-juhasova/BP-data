local _M = { version = "0.1.3" }

local function fileExists(filename)

    local f = io.open(filename,"r")
    if f ~= nil then 
        io.close(f) 
        return true 
    end 
    return false 

end

local function readFile(filename)
     
    local f, err = io.open(filename,"r")
    if f then 
        local lines = f:read("*a")
        f:close()
        return lines 
    end
    return nil, err

end

local function writeFile(filename, text)

    local f, err = io.open(filename, "w+")
    if f then
       f:write(text)
       f:close()
       return true
    end
    return nil, err
     
end

function copyTable(t)
 
    local t2 = {}
    for k,v in pairs(t) do
        t2[k] = v
    end
    return t2
 
end

local function mergeTables (defaults,options)

    if options then 
        for k, v in pairs(options) do
            if (type(v) == "table") and (type(defaults[k] or false) == "table") then
                mergeTables(defaults[k], options[k])
            else
                defaults[k] = v
            end
        end
    end
    return defaults

end

local function sortTableKeys (t)

    local tkeys = {}
    for k in pairs(t) do table.insert(tkeys, k) end
    table.sort(tkeys)
    return tkeys

end

local function moduleAvailable (name)

    if package.loaded[name] then
        return true
    else
        for _, searcher in ipairs(package.searchers or package.loaders) do
            local loader = searcher(name)
            if type(loader) == 'function' then
                package.preload[name] = loader
                return true
            end
        end
        return false
    end

end

_M.mergeTables = mergeTables
_M.copyTable = copyTable
_M.sortTableKeys = sortTableKeys
_M.readFile = readFile
_M.writeFile = writeFile
_M.fileExists = fileExists
_M.moduleAvailable = moduleAvailable

return _M

