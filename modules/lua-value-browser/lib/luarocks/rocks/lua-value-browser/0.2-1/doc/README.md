# Lua value browser
Lua module for interactively printing and browsing Lua values from the standalone interpreter.

Should be compatible with Lua 5.1, 5.2 and 5.3 as well as with LuaJIT.

Adds a parameterless function `browse` to the `debug` module on `require "debug.browser"`

Keeps a linear history of visited values and therefore keeps references to values that otherwise might have been garbage collected.

Shows also meta values like
* environments
* upvalues
* metatables
* table keys which are tables, functions, treads or userdata

## Installation

Just copy the file `src/debug/browser.lua` to your local lua files or use [luarocks](https://luarocks.org)

```
luarocks install lua-value-browser
```

## Usage

```
...
> require "debug.browser"
> debug.browse()
Lua value browser 0.2
Copyright (C) 2010-2018, schorg@gmail.com
Type 'q' to quit, 'help' for help
: help
   Browse Lua runtime values, like a web page.

   Available Commands:
   [@]<expr> (h)elp  (f)orward (b)ack (r)eload .<link> (t)ab (q)uit
   
   <enter>     executes one of the above commands
   [@]<expr>   show data entity for Lua <expr>, @ escapes commands
   help (h)    show this message
   forward (f) history forward
   back (b)    history back
   reload (r)  reload current
   .<link>     select .<link>
   .<prefix>   complete to next matching link with prefix .<prefix>
   tab (t)     selects the next link
   quit (q)    quit browser

: _G 
(_G): table
  = {
      _G: table = ._G,
      _VERSION: string = Lua 5.1,
      assert: function = .assert,
      bit: table = .bit,
      collectgarbage: function = .collectgarbage,
      coroutine: table = .coroutine,
      debug: table = .debug,
      dofile: function = .dofile,
      error: function = .error,
      gcinfo: function = .gcinfo,
      getfenv: function = .getfenv,
      getmetatable: function = .getmetatable,
      io: table = .io,
      ipairs: function = .ipairs,
      jit: table = .jit,
      load: function = .load,
      ... and so on
    }
: quit
> debug.browse()
: reload
...
```
    