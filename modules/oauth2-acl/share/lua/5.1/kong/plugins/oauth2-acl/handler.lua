local kong = kong

local tablex = require "pl.tablex"
local EMPTY = tablex.readonly {}
local BLACK = "BLACK"
local WHITE = "WHITE"

local setmetatable = setmetatable
local mt_cache = { __mode = "k" }
local config_cache = setmetatable({}, mt_cache)
local user_in_scopes_cache = setmetatable({}, mt_cache)


local function get_user_scopes()
  local scopes = kong.request.get_header("X-Authenticated-Scope")
  if scopes == nil then
    return {}
  end
  local user_scopes = {}
  for scope in string.gmatch(scopes, "%S+") do
    user_scopes[scope] = true
  end
  return user_scopes
end

--- checks whether a user-scopes-list is part of a given list of scopes.
-- @param scopes_to_check (table) an array of scope names. Note: since the
-- results will be cached by this table, always use the same table for the
-- same set of scopes!
-- @param user_scopes (table) list of user scopes (result from
-- `get_user_scopes`)
-- @return (boolean) whether the user is part of any of the scopes.
local function user_in_scopes(scopes_to_check, user_scopes)
  -- 1st level cache on "scopes_to_check"
  local result1 = user_in_scopes_cache[scopes_to_check]
  if result1 == nil then
    result1 = setmetatable({}, mt_cache)
    user_in_scopes_cache[scopes_to_check] = result1
  end

  -- 2nd level cache on "user_scopes"
  local result2 = result1[user_scopes]
  if result2 ~= nil then
    return result2
  end

  -- not found, so validate and populate 2nd level cache
  result2 = false
  for i = 1, #scopes_to_check do
    total = 0
    checked = 0
    scopes_check = scopes_to_check[i]
    for scope_check in string.gmatch(scopes_check, "%S+") do
      total = total + 1
      if user_scopes[scope_check] then
        checked = checked + 1
      end
    end
    if total == checked then
      result2 = true
      break
    end
  end

  result1[user_scopes] = result2

  return result2
end

local function get_to_be_blocked(config, groups, in_group)
  if config.type == BLACK then
    return in_group
  end
  return not in_group
end

local ACLHandler = {}

ACLHandler.PRIORITY = 999
ACLHandler.VERSION = "2.0.0"

function ACLHandler:access(conf)
  -- simplify our plugins 'conf' table
  local config = config_cache[conf]
  if not config then
    local config_type = (conf.blacklist or EMPTY)[1] and BLACK or WHITE

    config = {
      type = config_type,
      scopes = config_type == BLACK and conf.blacklist or conf.whitelist,
      cache = setmetatable({}, mt_cache),
    }

    config_cache[conf] = config
  end

  local user_scopes = get_user_scopes()
  -- 'to_be_blocked' is either 'true' if it's to be blocked, or the header
  -- value if it is to be passed
  local to_be_blocked = config.cache[user_scopes]
  if to_be_blocked == nil then
    local in_scope = user_in_scopes(config.scopes, user_scopes)
    to_be_blocked = get_to_be_blocked(config, user_scopes, in_scope)
    -- update cache
    config.cache[user_scopes] = to_be_blocked
  end

  if to_be_blocked == true then -- NOTE: we only catch the boolean here!
    return kong.response.exit(403, {
      message = "You cannot consume this service"
    })
  end
end

return ACLHandler
