lusty-statsd
============

Version 0.2

Log yo events to statsd

Require it in your config to append it to context.

Uses the [lua-statsd-client](https://github.com/stvp/lua-statsd-client)
library.

### Context

```lua
local config = {
  --...
  context = {
    ["lusty-statsd.context.statsd"] = {
      host = "stats.mysite.com", -- default = 127.0.0.1
      port = 8125, -- default = 8125,
      namespace = "mysite.stats", -- default = nil
      predicate = function(context) end -- default = nil
    }
  }
}
```

```lua
context.statsd.gauge("users", #my_users_table)
context.statsd.counter("events", 5)
context.statsd.increment("events", 1)
context.statsd.decrement("events", 3)
context.statsd.timer("page_render", 105)
context.statsd.histogram("page_render_time", 105)
context.statsd.meter("page_load", 1)
```


License
-------
Copyright 2013 Olivine Labs, LLC. MIT licensed. See LICENSE file for details.

