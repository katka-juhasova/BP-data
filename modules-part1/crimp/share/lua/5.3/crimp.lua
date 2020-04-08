Crimp = Crimp or {}

local function map(func, array)
    local newArray = {}
    for index, value in ipairs(array) do
        newArray[index] = func(value)
    end
    return newArray
end

local function isArray(object)
    return type(object) == "table" and object[1] ~= nil
end

local function isHash(object)
    return type(object) == "table" and not isArray(object)
end

local function convertHashToListOfTuples(hash)
    local newArray = {}
    for key, value in pairs(hash) do
        table.insert(newArray, {tostring(key), value})
    end
    return newArray
end

local function stringCompare(a, b)
    local function firstItemOf(object)
        table.sort(object,stringCompare);
        return object[1]
    end

    if isArray(a) then a =firstItemOf(a) end
    if isArray(b) then b = firstItemOf(b) end

    if isHash(a)  then a = firstItemOf(convertHashToListOfTuples(a)) end
    if isHash(b)  then b = firstItemOf(convertHashToListOfTuples(b)) end
    return tostring(a) < tostring(b)
end

local function notateCollection(data)
    if not isArray(data) then data = convertHashToListOfTuples(data) end
    table.sort(data, stringCompare)
    return map(Crimp.notation,data)
end

local function collectionTypeSuffix(collection)
    if isArray(collection) then return "A" end
    return "H"
end

function Crimp.notation(data)
    if type(data) == "nil"     then return("_") end
    if type(data) == "string"  then return(data .. "S") end
    if type(data) == "number"  then return(data .. "N") end
    if type(data) == "boolean" then return(tostring(data) .. "B") end
    if type(data) == "table"   then return(table.concat(notateCollection(data)) .. collectionTypeSuffix(data)) end
end

function Crimp.signature(data)
    local md5 = require 'md5'

    return md5.sumhexa(Crimp.notation(data))
end

return Crimp