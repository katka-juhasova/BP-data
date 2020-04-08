local query = require 'lusty-store-mysql.query'
local connection = require 'lusty-store-mysql.store.mysql.connection'

local function keysAndValues(tbl)
  local n, keys, values = 1, {}, {}
  for k, v in pairs(tbl) do
    keys[n] = k
    if type(v) == 'number' then
      values[n] = v
    else
      values[n] = ngx.quote_sql_str(v)
    end
    n = n + 1
  end
  return keys, values
end

local function makeUpdate(tbl)
  local n, update = 1, {}
  for k, v in pairs(tbl) do
    if type(v) == 'number' then
      update[n] = k..'='..v
    else
      update[n] = k..'='..ngx.quote_sql_str(v)
    end
    n=n+1
  end
  return table.concat(update, ' ,')
end

return {
  handler = function(context)
    local db, err = connection(lusty, config)
    if not db then error(err) end
    local q, m
    if getmetatable(context.query) then
      q, m = query(context.query)
    else
      q = context.query
    end
    local keys, values = keysAndValues(context.data)
    local update = makeUpdate(context.data)
    q = "UPDATE "..config.collection.." SET "..update.." "..(#q>0 and " WHERE "..q or "")..";"
    local results = {}
    local res, err, errno, sqlstate = db:query(q)
    db:set_keepalive(config.idle_timeout or 600000, config.pool_size or 10)
    if not res then
      return nil, "Query |"..q.."| failed: "..err
    end
    return res
  end
}
