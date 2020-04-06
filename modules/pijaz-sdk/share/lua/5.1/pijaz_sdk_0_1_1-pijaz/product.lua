--[[

Class: Product

Manages a renderable product.

PUBLIC METHODS:

clearRenderParameters()
generateUrl(additionalParams)
getAccessInfo()
getRenderParameter(key)
getWorkflowId()
saveToFile(filepath,additionalParams)
setAccessInfo(accessInfo)
setRenderParameter(key,newValue)
setWorkflowId(newWorkflowId)

PRIVATE METHODS:

_setFinalParams(self, additionalParams)

]]

local http = require "socket.http"

-- Class setup.
local M = {}
M.__index = M
setmetatable(M, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

-- PUBLIC METHODS

--- Clear out all current render parameters.
--
-- Any parameters currently stored with the product, including those passed
-- when the product was instantiated, are cleared.
function M:clearRenderParameters()
  self.renderParameters = {}
end

--- Build a fully formed URL which can be used to make a request for the
-- product from a rendering server.
--
-- @param additionalParams
--   Optional. A table of additional render parameters to be used for this
--   request only.
-- @return
--   A fully formed URL that can be used in a render server HTTP request.
function M:generateUrl(additionalParams)
  additionalParams = additionalParams or {}
  local finalParams = _setFinalParams(self, additionalParams)
  local options = {}
  options.product = self
  options.renderParameters = finalParams
  local params = self.serverManager:buildRenderCommand(options)
  if params then
    local url = self.serverManager:buildRenderServerUrlRequest(params)
    return url
  end
end

--- Return the access info for the product.
--
-- Required method for products passed to the ServerManager object.
-- @return
--   The access info.
function M:getAccessInfo()
  return self.accessInfo
end

--- Retrieve a render parameter.
--
-- @param key: The parameter name.
-- @return:
--   The render parameter, or the default render parameter if not set.
function M:getRenderParameter(key)
  local value = self.renderParameters[key] or self.productPropertyDefaults[key]
  return value
end

--- Return the workflow ID.
--
-- @return:
--   The workflow ID.
function M:getWorkflowId()
  return self.workflowId
end

--- Create a new product instance.
--
-- @param inParameters
--   A table with the following key/value pairs.
--
--     serverManager: Required. An instance of the ServerManager class.
--     workflowId: Required. The workflow ID for the product.
--     renderParameters: Optional. A table of render parameters to be included
--       with every render request. They depend on the product, but these are
--       typically supported params:
--         message: Primary message to display.
--         font: Font to use.
--         halign: Horizontal justification (left, center, right, full).
--         valign: Vertical justification (top, middle, bottom, full, even).
--         quality: Image quality to produce (0-100).
-- @return
--   A product object.
-- @usage prod = product:new(inParameters)
function M.new(inParameters)
  local params = inParameters
  local product = {}
  product.serverManager = params.serverManager
  product.workflowId = params.workflowId
  product.renderParameters = params.renderParameters or {}
  product.accessInfo = nil
  product.productPropertyDefaults = {}
  setmetatable(product, M)
  return product
end

--- Convenience method for saving a product directly to a file.
--
-- This takes care of generating the render URL, making the request to the
-- render server for the product, and saving to a file.
--
-- @param filepath
--   Required. The full file path.
-- @param additionalParams
--   Optional. A table of additional render parameters to be used for this
--   request only.
-- @return
--   True on successful save of the file, false otherwise.
function M:saveToFile(filepath, additionalParams)
  local url = self:generateUrl(additionalParams)
  if url then
    local response = http.request(url)
    if response then
      local imageFile = io.open(filepath, "wb")
      if imageFile then
        imageFile:write(response)
        imageFile:close()
        return true
      end
    end
  end
  return false
end

--- Set the access info for the product.
--
-- Required method for products passed to the ServerManager object.
function M:setAccessInfo(accessInfo)
  if accessInfo then
    self.accessInfo = accessInfo
  else
    self.accessInfo = nil
  end
end

--- Set a render parameter on the product.
--
-- @param key
--   The parameter name. Optionally a table of parameter key/value pairs can
--   be passed as the first argument, and each pair will be added.
-- @param newValue
--   The parameter value.
function M:setRenderParameter(key, newValue)
  if type(key) == 'table' then
    for k, v in pairs(key) do
      self:setRenderParameter(k, v)
    end
  else
    local param = self.renderParameters[key]
    local default = self.productPropertyDefaults[key]
    if param ~= newValue then
      if not newValue or newValue == default then
        self.renderParameters[key] = nil
      else
        self.renderParameters[key] = newValue
      end
    end
  end
end

--- Set the workflow ID.
function M:setWorkflowId(newWorkflowId)
  if self.workflowId ~= newWorkflowId then
    self.accessInfo = nil
    self.workflowId = newWorkflowId
  end
end

-- PRIVATE METHODS

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

--- Set the final render parameters for the product.
--
-- @param additionalParams
--   A table of additional render parameters.
function _setFinalParams(self, additionalParams)
  local finalParams = _deepcopy(self, self.renderParameters)
  if type(additionalParams) == 'table' then
    for key, value in pairs(additionalParams) do
      if value then
        finalParams[key] = value
      end
    end
  end
  finalParams.workflow = self.workflowId
  return finalParams
end

return M
