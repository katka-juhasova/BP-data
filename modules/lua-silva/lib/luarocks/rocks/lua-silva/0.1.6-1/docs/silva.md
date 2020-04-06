
# Silva

---

# Manual

## The instanciation : `matcher = Silva(pattern [, kind])`

The instanciation of a `matcher` is done by the call of `Silva`
with a `pattern` and an optional parameter which selects the `kind` of pattern,
its default value is `'template'`, the following values are handled :

  - `'identity'` wraps the Lua string equality (`==`)
  - `'lua'` wraps the Lua regex (`string.match`)
  - `'pcre'` wraps the PCRE regex from [lrexlib-pcre](https://luarocks.org/modules/rrt/lrexlib-pcre)
  - `'shell'` wraps the POSIX `fnmatch()` function (available via FFI or [LuaPosix](https://github.com/luaposix/luaposix) or implemented in plain Lua)
  - `'template'` wraps an URI Template ([RFC 6570](https://tools.ietf.org/html/rfc6570) - level 3) regex engine

Each kind of pattern is implemented as a plugin, so this list is easily extensible.

## The match : `matcher(str)`

when `str` matches, it returns a table containing capture values or the whole string `str`,
otherwise it returns `nil`.


# Examples

## with 'identity'

```lua
local Silva = require 'Silva'

local matcher = Silva('/index.html', 'identity')
print(matcher('/index.html'))  --> /index.html
```

## with 'lua'

```lua
local Silva = require 'Silva'

local matcher = Silva('/%w+%.html', 'lua')
print(matcher('/lua.html'))  --> /lua.html
```

## with 'lua' and capture

```lua
local Silva = require 'Silva'

local matcher = Silva('/foo/(%w+)', 'lua')
local capture = matcher('/foo/bar')
print(capture[1]) --> bar
```

## with 'pcre'

```lua
local Silva = require 'Silva'

local matcher = Silva('/\\w+\\.html', 'pcre')
print(matcher('/lua.html'))  --> /lua.html
```

## with 'pcre' and capture

```lua
local Silva = require 'Silva'

local matcher = Silva('/foo/(\\w+)', 'pcre')
local capture = matcher('/foo/bar')
print(capture[1]) --> bar
```

## with 'template'

```lua
local Silva = require 'Silva'

local matcher = Silva('/foo/{var}', 'template')
local capture = matcher('/foo/bar')
print(capture.var) --> bar

local matcher = Silva('/foo/{path}{?query,number}')
local capture = matcher('/foo/bar?number=42&query=baz')
print(capture.path, capture.number, capture.query) --> bar   42    baz
```

## with 'shell'

```lua
local Silva = require 'Silva'

local matcher = Silva('/?*.html', 'shell')
print(matcher('/shell.html'))  --> /shell.html

local matcher = Silva('/[Ff]oo[1-9][0-9]', 'shell')
print(matcher('/foo42'))  --> /foo42
```

## glob / shell

```lua
local function glob (dirname, patt)
    return coroutine.wrap(function ()
        local sme = require'Silva'(patt, 'shell')
        for fname in require'lfs'.dir(dirname) do
            if sme(fname) then
                coroutine.yield(fname)
            end
        end
    end)
end

for k in glob('test', '*.lua') do
    print(k)
end

for k in glob('src/Silva', '*.lua') do
    print(k)
end
```
