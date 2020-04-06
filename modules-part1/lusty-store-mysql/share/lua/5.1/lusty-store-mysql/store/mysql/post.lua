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
    local keys, values = keysAndValues(context.query)
    local q = "INSERT INTO "..config.collection.." ("..table.concat(keys, ' ,')..") VALUES ("..table.concat(values, ' ,')..");"
    local res, err, errno, sqlstate = db:query(q)
    db:set_keepalive(config.idle_timeout or 600000, config.pool_size or 10)
    if not res then
      return nil, "Query |"..q.."| failed: "..err
    end
    return res
  end
}
