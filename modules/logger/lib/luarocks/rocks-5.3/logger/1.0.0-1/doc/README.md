# Lua-logger

## About

Lua-logger is a fork of [LuaLogging](http://neopallium.github.com/lualogging/) which is a port of Log4j upon which it's design was based. The name of the module was changed by [@mwchase](https://github.com/mwchase) in his fork to [`log4l`](https://github.com/mwchase/log4l) to indicate the differences and to assimilate other [Log4j ports'](https://en.wikipedia.org/wiki/Log4j#Ports) names.
I took [@mwchase's version](https://github.com/mwchase/log4l) and made so many changes I decided to publish it under my own domain. I decided to change the name as well and I called the [luarock](http://luarocks.org/) `logger`.

This is free software and uses the same license as Lua.

## Installation

With LuaRocks:

```
luarocks install logger
```

## Usage

Quick example:

```lua
Logger = require('logger')
myLogger = Logger()

myLogger:debug('started logging stuff')
myLogger:info('this is just an info message')

myLogger:setLevel('ERROR') -- makes only error / fatal messages appended
myLogger:debug('this debug message should not be printed')
myLogger:info('another unprinted info message')
```

Requiring the `logger` module returns a logger 'constructor'. There are 2 parameters the constructor accepts:

- Appender function
- Settings table

For example, it may accept these parameters like this:

```lua
Logger = require('logger')
myLoggerSettings = {
  -- ...
}
myLoggerAppender = function(self, level, message)
end
myLogger = Logger(myLoggerAppender, myLoggerSettings)

-- ...
```

### The appender function

The appender function should have this signature:

```lua
function(self, level, message)
end
```

- `self` is the logger object himself.
- `level` is a string representation of the log level of the message.
- `message` is the message itself.

The default function prints the message to `io.stderr` along with indicating the log level but you can write your own function that will do whatever you want - append entries to a SQL database, send messages via email etc..

You can also check for the current level of the logger in the appender function using `self.level`. This variable is a string representation of the log level. The default log levels are:

```
local DEFAULT_LEVELS = {
	-- The highest possible rank and is intended to turn off logging.
	"OFF",
	-- Severe errors that cause premature termination. Expect these to be immediately visible on a status console.
	"FATAL",
	-- Other runtime errors or unexpected conditions. Expect these to be immediately visible on a status console.
	"ERROR",
	-- Use of deprecated APIs, poor use of API, 'almost' errors, other runtime situations that are undesirable or
	-- unexpected, but not necessarily "wrong". Expect these to be immediately visible on a status console.
	"WARN",
	-- Interesting runtime events (startup/shutdown). Expect these to be immediately visible on a console, so be
	-- conservative and keep to a minimum.
	"INFO",
	-- Detailed information on the flow through the system. Expect these to be written to logs only. Generally speaking,
	-- most lines logged by your application should be written as DEBUG.
	"DEBUG",
	-- Most detailed information. Expect these to be written to logs only
	"TRACE"
}
```

The order makes a difference: The index of Level `"OFF"` is `6` and level `"TRACE"`'s index is `1` - **The lowest the number is - the more detailed the message**. This design is Similar to that of Python's Logger, see [this table](https://docs.python.org/3/library/logging.html#logging-levels).

Note that like `self.level`, `self.level_order` represents the numerical order of the logger's current log level.

### The settings table

As noted above, the constructor accepts a second parameter which is the settings table. This table may consist of 2 inner objects:

- `levels`: A table like the above `DEFAULT_LEVELS` but with a custom set of levels names.
- `init_level`: A string of the log level the logger should start with.

### Changing log level after initialization

You can change the log level after initialization with the following method:

```lua
myLogger:setLevel('ERROR') -- makes only error / fatal messages appended
```

This method accepts the log level either as a number or as a string. The parameters `level` and `level_order` of `self` in the appender function will update accordingly so it is recommended to use this rather then manually changing the `myLogger`'s `level` and `level_order` fields.

### Getting a level's index by name

The Logger constructor creates a field in the returned logger called `levelIndexByName` which may help you getting the numerical level of any string level. Example:

```lua
> myLogger = require('logger')()
> myLogger.levelIndexByName["WARN"] < myLogger.levelIndexByName["ERROR"]
true
```
