--[[

Class: ServerManager

Server manager class, used for making calls to a Pijaz API service and/or
rendering service.

PUBLIC METHODS:

buildRenderCommand(inParameters)
buildRenderServerUrlRequest(inParameters)
getApiKey()
getApiServerUrl()
getApiVersion()
getAppId()
getRenderServerUrl()
sendApiCommand(inParameters)

PRIVATE METHODS:

_buildRenderServerQueryParams(params)
_deepcopy(self, t)
_extractInfo(self, data)
_extractResult(self, data)
_httpRequest(self, url, method,
_isRenderRequestAllowed(self, product)
_parseJson(self, jsonString)
_processAccessToken(self, params, data)
_sendApiCommand(self, inParameters, retry)
_stringifyParameters(self, params, separator)

]]

local PIJAZ_API_VERSION = 1
local PIJAZ_API_SERVER = 'http://api.pijaz.com/'
local PIJAZ_RENDER_SERVER = 'http://render.pijaz.com/'
local SERVER_REQUEST_ATTEMPTS = 2

local json = require "cjson"
local http = require "socket.http"
local url = require "socket.url"

-- Class setup.
local M = {}
M.__index = M
setmetatable(M, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

-- PUBLIC METHODS

--- Build the set of query parameters for a render request.
--
-- @param inParameters
--   A table with the following key/value pairs.
--
--     product: An instance of the Product class
--     renderParameters: A table of all params sent to the render request.
--
-- @return
--     If successful, a table of query parameters to pass to the rendering
--     server. These can be converted into a full URL by calling
--     buildRenderServerUrlRequest(params).
-- @usage srv:buildRenderCommand(params)
-- @see buildRenderServerUrlRequest()
function M:buildRenderCommand(inParameters)
  local params = inParameters
  if _isRenderRequestAllowed(self, params.product) then
    return _buildRenderServerQueryParams(self, params)
  else
    local commandParameters = {}
    commandParameters.workflow = params.renderParameters.workflow
    if params.renderParameters.xml then
      commandParameters.xml = params.renderParameters.xml
    end
    local options = {}
    options.command = 'get-token'
    options.commandParameters = commandParameters
    local response = self:sendApiCommand(options)
    if response then
      return _processAccessToken(self, params, response)
    end
  end
end

--- Builds a fully qualified render request URL.
--
-- @param inParameters
--   A table of query parameters for the render request.
-- @return:
--   The constructed URL.
-- @usage srv:buildRenderServerUrlRequest(params)
function M:buildRenderServerUrlRequest(inParameters)
  local url = self:getRenderServerUrl() .. "render-image?" .. _stringifyParameters(self, inParameters)
  return url
end

--- Get the API key of the client application.
--
-- @return:
--   The API key.
-- @usage srv:getApiKey()
function M:getApiKey()
  return self.apiKey
end

--- Get current API server URL.
--
-- @return:
--   The API server URL.
-- @usage srv:getApiServerUrl()
function M:getApiServerUrl()
  return self.apiServer
end

--- Get the API version the server manager is using.
--
-- @return:
--   The API version.
-- @usage srv:getApiVersion()
function M:getApiVersion()
  return self.apiVersion
end

--- Get the client application ID.
--
-- @return:
--   The application ID.
-- @usage srv:getAppId()
function M:getAppId()
  return self.appId
end

--- Get current render server URL.
--
-- @return:
--   The render server URL.
-- @usage srv:getRenderServerUrl()
function M:getRenderServerUrl()
  return self.renderServer
end

--- Create a new instance of the product class.
--
-- @param inParameters
--   A table with the following key/value pairs.
--     appId: Required. The ID of the client application.
--     apiKey: Required. The API key associated with the client. This key should
--       be kept confidential, and is used to allow the associated client to
--       access the API server.
--     renderServer: Optional. The base URL of the rendering service. Include
--       the trailing slash. Default: http://render.pijaz.com/
--     apiServer: Optional. The base URL of the API service. Include
--       the trailing slash. Default: http://api.pijaz.com/
--     refreshFuzzSeconds: Optional. Number of seconds to shave off the lifetime
--       of a rendering access token, this allows a smooth re-request for a new
--       set of access params. Default: 10
--     apiVersion: Optional. The API version to use. Currently, only version 1
--       is supported. Default: 1
-- @return
--   A server object.
-- @usage srv = ServerManager(inParameters)
function M.new(inParameters)
  local params = inParameters
  local server = {}
  server.appId = params.appId
  server.apiKey = params.apiKey
  server.apiServer = params.apiServer or PIJAZ_API_SERVER
  server.renderServer = params.renderServer or PIJAZ_RENDER_SERVER
  server.refreshFuzzSeconds = params.refreshFuzzSeconds or 10
  server.apiVersion = params.apiVersion or PIJAZ_API_VERSION
  setmetatable(server, M)
  return server
end

--- Send a command to the API server.
--
-- @param inParameters
--   A table with the following key/value pairs:
--     command: Required. The command to send to the API server. One of the
--       following:
--         get-token: Retrieve a rendering access token for a workflow.
--           commandParameters:
--             workflow: The workflow ID.
--   commandParameters: Optional. A table of parameters. See individual
--     command for more information
--   method: Optional. The HTTP request type. GET or POST. Default: GET.
-- @return:
--   If the request succeed, then a table of the response data, otherwise two
--   values: nil, and an error message.
-- @usage srv:sendApiCommand(params)
function M:sendApiCommand(inParameters)
  return _sendApiCommand(self, inParameters, SERVER_REQUEST_ATTEMPTS - 1)
end

-- PRIVATE METHODS

--- Construct a URL with all user supplied and constructed parameters
function _buildRenderServerQueryParams(self, params)
  local accessInfo = params.product:getAccessInfo()
  local queryParams = _deepcopy(self, accessInfo.renderAccessParameters)
  if type(params.renderParameters) == 'table' then
    for key, value in pairs(params.renderParameters) do
      if value then
        queryParams[key] = value
      end
    end
  end
  return queryParams
end

--- Recursively copy a table's contents, including metatables.
function _deepcopy(self, t)
  if type(t) ~= 'table' then
    return t
  end
  local mt = getmetatable(t)
  local res = {}
  for k,v in pairs(t) do
    if type(v) == 'table' then
      v = deepcopy(v)
    end
    res[k] = v
  end
  setmetatable(res, mt)
  return res
end

--- Extract the information from a server JSON response.
function _extractInfo(self, data)
  local json = _parseJson(self, data)
  if json.result and json.result.result_num and json.result.result_num == 0 then
    return json.info
  end
  return false
end

--- Extract the result from a server JSON response.
function _extractResult(self, data)
  local json = _parseJson(self, data)
  if json.result and json.result.result_num and json.result.result_text then
    return json.result
  end
  return false
end

--- Perform an HTTP request.
--
-- @param url
--   A string containing a fully qualified URI.
-- @param method
--   Optional. A string defining the HTTP request method to use. Only GET
--   and POST are supported.
-- @param data
--   A table containing data to include in the request.
-- @return
--   Four values, the response, the response code, a table of headers, and the
--   status.
-- @usage
--   response, responseCode, headers, status = srv:_httpRequest(url, method, data)
function _httpRequest(self, url, method, data)
  method = method and string.upper(method) or 'GET'

  local body
  if method == 'GET' then
    if type(data) == 'table' then
      url = url .. '?' .. _stringifyParameters(self, data)
    end
  elseif method == 'POST' then
    body = _stringifyParameters(self, data, "\n")
  end

  local response, responseCode, headers, status = http.request(url, body)

  return response, responseCode, headers, status
end

-- Verifies that valid access parameters are attached to the product.
function _isRenderRequestAllowed(self, product)
  local accessInfo = product:getAccessInfo()
  if accessInfo then
    local expireTimestamp = accessInfo.timestamp + accessInfo.lifetime - self.refreshFuzzSeconds
    if os.time() <= expireTimestamp then
      return true
    end
  end
  return false
end

--- Parse a JSON string.
-- @param jsonString
--   Required. The JSON string to parse.
-- @return
--   The parsed JSON string, converted to a table.
-- @usage
--   srv:_parseJson('{"key": "value"}')
function _parseJson(self, jsonString)
  if jsonString and jsonString ~= "" then
    -- Invalid JSON causes an error, so wrap the parsing in a protected call.
    local result, data = pcall(
      function ()
        return json.decode(jsonString)
      end
    )
    if result then
      return data
    else
      return result, data
    end
  end
end

--- Handles setting up product access info and building render params.
function _processAccessToken(self, params, data)
  local accessInfo = {}

  -- Store the time the access params were obtained -- used to count
  -- against the lifetime param to expire the info.
  accessInfo.timestamp = os.time()
  -- Extract the lifetime param, no need to pass this along to the
  -- rendering server.
  accessInfo.lifetime = tonumber(data.lifetime)
  data.lifetime = nil

  accessInfo.renderAccessParameters = data

  params.product:setAccessInfo(accessInfo)

  return _buildRenderServerQueryParams(self, params)
end

--- Sends a command to the API server.
function _sendApiCommand(self, inParameters, retry)
  params = inParameters
  local url = self:getApiServerUrl() .. params.command
  local method = params.method or 'GET'

  params.commandParamaters = params.commandParameters or {}
  params.commandParameters.app_id = self:getAppId()
  params.commandParameters.api_key = self:getApiKey()
  params.commandParameters.api_version = self:getApiVersion()

  -- DEBUG.
  --print("uuid: " .. params.commandParameters.request_id .. ", command: " .. params.command)

  response, responseCode = _httpRequest(self, url, method, params.commandParameters)

  if responseCode == 200 then
    local jsonResult = _extractResult(self, response)
    if jsonResult.result_num == 0 then
      return _extractInfo(self, response)
    else
      return nil, jsonResult.result_text
    end
  else
    if retry > 0 then
      retry = retry - 1
      return _sendApiCommand(self, inParameters, retry)
    else
      return nil, responseCode
    end
  end
end

--- Builds a parameter string from a table.
-- @param params
--   Optional. A table of query parameters, key is parameter name, value is
--   parameter value.
-- @param separator
--   Optional. The separator to use in the constructed string. Default '&'.
-- @return
--   The query string.
-- @usage srv:_stringifyParameters({ foo = "bar", baz = "bang" })
function _stringifyParameters(self, params, separator)
  local separator = separator or '&'
  local paramParts = {}
  for name, value in pairs(params) do
    if value then
      table.insert(paramParts, string.format("%s=%s", url.escape(name), url.escape(value)))
    end
  end

  local paramString = table.concat(paramParts, separator)
  return paramString
end

return M
