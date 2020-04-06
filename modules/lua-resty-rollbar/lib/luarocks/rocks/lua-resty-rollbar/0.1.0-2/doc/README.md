# lua-resty-rollbar

Simple module for [OpenResty](http://openresty.org/) to send errors to
[Rollbar](https://rollbar.com).

`lua-resty-rollbar` is a Lua Rollbar client that makes it easy to report errors to Rollbar with
stack traces. Errors are sent to Rollbar asynchronously in a light thread.

## Installation

Install using LuaRocks:

```
luarocks install lua-resty-rollbar 0.1.0
```

## Usage

```lua
local rollbar = require 'resty.rollbar'

rollbar.set_token('MY_TOKEN')
rollbar.set_environment('production') -- defaults to 'development'

function main()
	res, err = do_something()
	if not res {
		// Error reporting
		rollbar.report(rollbar.ERR, err)
		return
	}
end
```
