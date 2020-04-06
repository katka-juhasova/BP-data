local httprequestparser = {
    VERSION = "1.0",
    dependencies = {'dkjson', 'lxp.lom'}
}
local json = require 'dkjson';
local lom = require "lxp.lom"

local function isEmpty(s)
    return s == nil or s == '' or s == ""
end

local function splitString(toSplitString, delimiter)
    local result = {};
    for match in (toSplitString .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function trimString(toTrimString)
    local from = toTrimString:match "^%s*()"
    return from > #toTrimString and "" or toTrimString:match(".*%S", from)
end

local function _privatefindElementFromRequestBody(requestBody, element)
    s, e = string.find(requestBody:lower(), element:lower())
    if e == nil then
        return nil
    end
    ls, le = string.find(requestBody:lower(), "\n", e)
    local line = requestBody:sub(s, le)
    s, e = string.find(line, ':')
    if s == nil then
        return nil
    end
    local elementValue = trimString(line:sub(s + 1, string.len(line)))
    return elementValue
end

local function fetchFirstLineFromRequestPayLoad(requestPayload)
    se, e = string.find(requestPayload, "\n")
    if e == nil then
        return nil
    end
    s = requestPayload:sub(1, e)
    return s;
end

--[[    Algorithm
--  split requestBody wrt new line.
--  loop through the table and find empty line.
--  when empty line found then set falg variable to stop the request body data to table.
--  this separate table contains the request body.
--  concatenate the table to string and return the request body string.
]]
local function fetchRequestBody(requestBody)
    local splitRequestBody = splitString(requestBody, "\n")
    local flag = false
    local requestBody = {}

    for k, v in pairs(splitRequestBody) do
        if (v == '\n' or isEmpty(trimString(v))) then
            flag = true
        end
        if (flag == true) then
            table.insert(requestBody, v)
        end
    end
    requestBody = table.concat(requestBody)
    return requestBody;
end

--[[
-- Will return Content-Type header present in request body
-- ]]
function httprequestparser.getContentType(requestBodyBuffer)
    return _privatefindElementFromRequestBody(requestBodyBuffer, "Content%-Type")
end

--[[
-- Will return Accept header present in request body
-- ]]
function httprequestparser.getAccept(requestBodyBuffer)
    return _privatefindElementFromRequestBody(requestBodyBuffer, "Accept")
end

--[[
-- Will return Host header present in request body
-- ]]
function httprequestparser.getHost(requestBodyBuffer)
    return _privatefindElementFromRequestBody(requestBodyBuffer, "Host")
end

--[[
-- Will return All Headers present in request body as table
-- ]]
function httprequestparser.getAllHeaders(requestBodyBuffer)
    local splitRequestBody = splitString(requestBodyBuffer, "\n")
    local requestHeaders = {}
    local i = 0
    for k, v in pairs(splitRequestBody) do
        if i == 0 then
            i = i + 1
        else
            if (v == '\n' or isEmpty(trimString(v))) then
                break
            else
                s, e = string.find(v, ':')
                if s ~= nil then
                    local headerName = v:sub(1, s)
                    local headerValue = v:sub(s + 1, string.len(v))
                    requestHeaders[trimString(headerName)] = trimString(headerValue)
                end
            end
        end
    end
    return requestHeaders;
end

--[[
-- Will return http method present in Request body.
-- ]]
function httprequestparser.getHttpMethod(requestBodyBuffer)
    local line = fetchFirstLineFromRequestPayLoad(requestBodyBuffer)
    if line == nil then
        return nil
    end
    s, e = string .find(line, '%s')
    if s == nil then
        return nil
    end
    return trimString(line:sub(1, s));
end

--[[
-- Will return request uri present in Request body.
-- ]]
function httprequestparser.getRequestURI(requestBodyBuffer)
    local line = fetchFirstLineFromRequestPayLoad(requestBodyBuffer)
    if line == nil then
        return nil
    end
    s, e = string .find(line, '%s')
    if s == nil then
        return nil
    end
    return trimString(line:sub(s + 1, string.len(line)));
end

--[[
-- Will return element present in request body as String
-- ]]
function httprequestparser.findElementFromRequestBody(requestBodyBuffer, element)
    return _privatefindElementFromRequestBody(requestBodyBuffer, element)
end

--[[
-- Will return true or false if request body is xml or not.
-- ]]
function httprequestparser.isXMLBody(requesBodyBuffer)
    local contentType = httprequestparser.getContentType(requesBodyBuffer)
    if (string.find(contentType, 'xml') ~= nil) then
        return true
    else
        return false
    end
end

--[[
-- Will return true or false if request body is json or not.
-- ]]
function httprequestparser.isJSONBody(requesBodyBuffer)
    local contentType = httprequestparser.getContentType(requesBodyBuffer)
    if (string.find(contentType, 'json') ~= nil) then
        return true
    else
        return false
    end
end

--[[
-- Will return request body as String
-- ]]
function httprequestparser.getRequestBodyAsString(requestBodyBuffer)
    local splitRequestBody = splitString(requestBodyBuffer, "\n")
    local flag = false
    local requestBody = '';

    for k, v in pairs(splitRequestBody) do
        if (v == '\n' or isEmpty(trimString(v))) then
            flag = true
        end
        if (flag == true) then
            requestBody = requestBody .. v
        end
    end
    return requestBody;
end

--[[
-- Will return Json Object if the request body is in Json Format.
-- Users will have to use dkjson function on Json Object.
-- ]]
function httprequestparser.handleJsonBody(requestBodyBuffer)
    local contentType = httprequestparser.getContentType(requestBodyBuffer)
    if (string.find(contentType, 'json') ~= nil) then
        return nil
    end
    local requestBody = fetchRequestBody(requestBodyBuffer)
    if isEmpty(requestBody) then
        return nil
    end
    return json.decode(requestBody)
end

--[[
-- Will return XML Object if the request body is in XML Format.
-- Users will have to use lxp.lom function on XML Object.
-- ]]
function httprequestparser.handleXMLBody(requestBodyBuffer)
    local requestBody = fetchRequestBody(requestBodyBuffer)
    if isEmpty(requestBody) then
        return nil
    end
    return lom.parse(requestBody)

end

return httprequestparser