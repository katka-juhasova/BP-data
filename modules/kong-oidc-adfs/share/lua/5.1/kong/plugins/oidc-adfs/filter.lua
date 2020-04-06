local M = {}

local function matches(patterns, toMatch)
  if (patterns) then
    for _, pattern in ipairs(patterns) do
      local isMatching = not (string.find(toMatch, pattern) == nil)
      if (isMatching) then return true end
    end
  end
  return false
end

function M.shouldProcessRequest(config)
  return not matches(config.filters, ngx.var.uri)
end

function M.shouldErrorRequest(config)
  if (config.auth_error_filter) then 
    return not (string.find(ngx.var.request_uri, config.auth_error_filter) == nil)
  end
  return false
end

return M
