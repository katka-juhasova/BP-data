-----------------------
-- A lua ocr.space wrapper
--
-- Get your key here https://ocr.space/ocrapi
-- @module ocr-space
-- @author IgorMael
-- @license MIT


local http = require("socket.http")
local ltn12 = require("ltn12")
local cjson = require("cjson")
local encode = (require "multipart-post").encode
local source_types = {
    "url",
    "file",
    "base64Image"
}

--- Define the requisition file type
-- find which key type is present on the function
-- @local
-- @param source The source of the request
-- @treturn string a string with the type url | file | base64Image
local function get_type(source)
    for _, value in ipairs(source_types) do
        if source[value] then
            return value
        end
    end
end

local OcrSpace = {}
OcrSpace.__index = OcrSpace
setmetatable(OcrSpace, {
    __call = function (cls, ...)
      return cls.new(...)
    end,
})

--- Initialize the api and set the api key
-- @export
-- @tparam string apiKey The apiKey
-- @tparam table default The default request settings
-- @treturn table An ocrSpace instance
-- @error You must provide an apiKey
-- @error The apikey must be a string
function OcrSpace.new(apiKey, default)
    if not apiKey then
        error("You must provide an apiKey", 2)
    end
    if type(apiKey) ~= "string" then
        error("The apikey must be a string", 2)
    end
    local self = setmetatable({}, OcrSpace)
    default = default or {}
    self.apikey = apiKey
    self.default = {
        url = default["url"],
        file = default["file"],
        base64Image = default["base64Image"],
        language =  default["language"] or "eng",
        isOverlayRequired = default["isOverlayRequired"],
        filetype = default["filetype"],
        detectOrientation = default["detectOrientation"],
        isCreateSearchablePdf = default["isCreateSearchablePdf"],
        isSearchablePdfHideTextLayer = default["isSearchablePdfHideTextLayer"],
        scale = default["scale"],
        isTable = default["isTable"]
    }
    return self
end

--- Define the default api options
-- @export
-- @tparam table options A table with the new default settings
function OcrSpace:set_default(options)
    for key, value in pairs(options) do
        self.default[key] = value
    end
end

--- Get the current default setting
-- @export
-- @treturn table a table with the currenty settings
function OcrSpace:get_default()
    return self.default
end

--- Do a post request to the api and return the parsed text
-- @export
-- @tparam table source The source of the request
-- @tparam table options A table with the request settings
-- @error You should specify a url, file or base64Image
-- @treturn table a table with the parsed result
function OcrSpace:post(source, options)
    source = source or self.default["url"] or self.default["file"] or self.default["base64Image"]
    if not source then
        error("You should specify a url, file or base64Image", 2)
    end

    local req_body = {}
    for key,value in pairs(self.default) do
        req_body[key] = value
    end
    if options then
        for key,value in pairs(options) do
            req_body[key] = value
        end
    end

    local source_type = get_type(source)
    if source_type == "file" and type(source["file"]) == "userdata" then
        source["file"] = {name = "file.png", data = source["file"]:read("*a")}
    end
    req_body[source_type] = source[source_type]

    local form, boundary = encode(req_body)
    local header = {
        apikey = self.apikey,
        ["Content-Type"] = "multipart/form-data; charset=utf-8; boundary="..boundary,
        ["Content-Length"] = #form
    }

    local response_body = {}
    http.request{
        url = "https://api.ocr.space/parse/image",
        source = ltn12.source.string(form),
        sink = ltn12.sink.table(response_body),
        headers = header,
        method = "POST"
    }
    return cjson.decode(response_body[1])
end

--- Make a get request to the Api and return the parsed text
-- @export
-- @tparam string imageUrl A url to the source image
-- @tparam table options A table with the request settings
-- @treturn table a table with the parsed result
-- @error source should be a string
function OcrSpace:get(imageUrl, options)
    if self.apikey == nil then
        error("apikey not provided. Initialize the library first")
    end
    options = options or {}
    local url = [[https://api.ocr.space/parse/imageurl?]]
    if not imageUrl or type(imageUrl) ~= "string" then
        error("source should be a string")
    end
    url = url .. "apikey=" .. self.apikey .. "&url=" .. imageUrl .. "&language=" .. (options["language"] or self.default["language"])
    if options["isOverlayRequired"] or self.default["isOverlayRequired"] then
        url = url .. "&isOverlayRequired=True"
    end
    local response_body = {}
    http.request{url = url,sink = ltn12.sink.table(response_body)}
    return cjson.decode(response_body[1])
end

return OcrSpace
