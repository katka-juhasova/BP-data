local mysql = require "resty.mysql"
return function(lusty, config)
  local db, err = mysql:new()
  if not db then
    lusty.context.log("Failed to instantiate MySQL Driver: "..err ,"error")
    return nil, err
  end

  db:set_timeout(config.timeout)

  local ok, err, errno, sqlstate = db:connect({
    host = config.host,
    port = config.port,
    database = config.database,
    user = config.username,
    password = config.password,
  })

  if not ok then
    err = "Failed to connect to MySQL: "..err..": "..(errno or "unknown").." "..(sqlstate or "unknown")
    return nil, err
  end
  return db
end
