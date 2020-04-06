Lua Statsd client for OpenResty
=================

`lua-resty-statsd` is an application of the [patch](https://github.com/mediba-system/lua-resty-statsd/blob/master/src/resty_statsd.patch) to take advantage of the Nginx cosoket to `lua-statsd-client`.
`lua-statsd-client` is a [Statsd](https://github.com/etsy/statsd) client for Lua. It supports all Statsd meter types.

Installation
------------

```sh
% luarocks install lua-resty-statsd
```

Usage
-----

```lua
-- require constructor
local Statsd = require "statsd"

-- create statsd object, which will open up a persistent port
local statsd = Statsd({
  host = "stats.mysite.com" -- default: 127.0.0.1
  port = 8888 -- default: 8125
  namespace = "mysite.stats" -- default: none
})

statsd:gauge( "users", #my_users_table )
statsd:counter( "events", 5 )
statsd:increment( "events", 1 )
statsd:decrement( "events", 3 )
statsd:timer( "page_render", 105 )
statsd:histogram( "page_render_time", 105 )
statsd:meter( "page_load", 1 )
```

Original
-----------

https://github.com/stvp/lua-statsd-client
