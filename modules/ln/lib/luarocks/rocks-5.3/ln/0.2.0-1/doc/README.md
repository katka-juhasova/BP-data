# ln: The Natural Logger for Lua

This is a clone of [ln](https://github.com/Xe/ln) for Lua. ln works by using
key->value pairs to create structured logging output. By default, this outputs
logs formatted similar to [logfmt][logfmt].

[logfmt]: https://www.brandur.org/logfmt

Example:

```lua
local ln = require "ln"

ln.log {foo = "bar"}
-- time="2019-12-25T13:24:00" foo=bar
```

It also supports multiple tables:

```lua
local ln = require "ln"

ln.log({foo = "bar"}, {needs_space = "a string value with spaces"})
-- time="2019-12-25T13:24:00" foo=bar needs_space="a string value with spaces"
```

And logging errors:

```lua
local ln = require "ln"

local result, err = thing_that_could_fail()
if err ~= nil then
  ln.err(err, {tried = "thing_that_could_fail()"})
end
-- time="2019-12-25T13:27:32" err="vibe check failed" tried=thing_that_could_fail()
```

And outputting logs as JSON:

```
local ln = require "ln"

ln.default_logger.formatter = ln.JSONFormatter:new()
ln.log {foo = "bar"}
-- {"foo":"bar","time":"2019-12-25T13:27:32"}
```

Or creating your own logger instance:

```lua
local ln = require "ln"

local lgr = ln.Logger:new()
lgr:log {foo = "bar"}
-- time="2019-12-25T13:27:32" foo=bar
```

Or custom filters

```lua
local lgr = ln.Logger:new {
  filters = {
    function(message)
      if string.find(message, "debug=true") and os.getenv("DEBUG") ~= "YES" then
        return false
      end
    end,
    print,
  }
}

lgr:log {debug = "true", line = "PRIVMSG #foo :bar", dir = "out"}
```

This will make the log line only show up when `DEBUG` is set to `"YES"`.