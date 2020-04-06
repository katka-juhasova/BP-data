local cjson = require('cjson')
local http = require('resty.http')

local rollbarHref = 'https://api.rollbar.com/api/1/'
local apiToken = os.getenv('ROLLBAR_API_TOKEN')
local forceFail = os.getenv('ROLLBAR_FORCE_ONFAIL')

assert(apiToken ~= nil, 'Environment variable ROLLBAR_API_TOKEN not set')

local M = {}
local Helpers = {}

function M.createMessageItem(msg, environment, altApiToken, altHref, altForceFail)
  apiHref = altHref or rollbarHref
  token = altApiToken or apiToken
  env = environment or 'production'
  exitOnFail = altForceFail or forceFail or false

  -- Create item details table

  local body = {
    ['access_token'] = token,
    data = {
      environment = env,
      body = {
        message = {
          body = msg
        }
      }
    }
  }

  -- Build and send request

  local httpc = http.new()
  local request = Helpers.buildRequest({}, body, 'POST')
  local res, err = httpc:request_uri(apiHref .. 'item/', request)
  if not res or res.status ~= 200 then
    ngx.log(ngx.ERR, 'Error occurred while creating Rollbar message item: ' .. res.status)
    if exitOnFail then
      return ngx.exit(res.status)
    end
  end
end

function Helpers.buildRequest(headers, body, method)
  local req = {
    method = method or ngx.var.request_method,
  }

  if headers then
    req['headers'] = {
      ['Content-Type'] = headers['Content-Type'],
      accept = 'application/json'
    }

    if headers['Authorization'] then
      req['headers']['Authorization'] = headers['Authorization']
    end
  end

  if body then
    req['body'] = cjson.encode(body)
  end
  return req
end

return M
