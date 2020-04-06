## About

Have trouble with printing UTF-8 stings or saving file with UTF-8 names on Windows?

lua-native is for you:

`native.encode()` converts from UTF-8 string to system current encoding on Windows.

On other system (Mac/Linux...) it just return the 1st argument.

```lua
local native = require('native')
local mbcs = native.encode(utf8string)
print(mbcs) -- prints correctly in Windows/Mac/Linux... console...
```

`native.decode()` converts from system default encoding to UTF-8 on Windows.

On other system (Mac/Linux...) it just return the 1st argument.

```lua
local native = require('native')
local lfs = require('lfs')

function attrdir(utf8_path)
	local native_path = native.encode(utf8_path)
	local utf8_filenames = {}
  for file in lfs.dir(native_path) do
      if file ~= "." and file ~= ".." then
          utf8_filenames[#utf8_filenames+1] = native.decode(file)
      end
  end
	return utf8_filenames
end
```

## Build

1. You need [Lua for Windows][1] installed. It will set a `LUA_DEV` environment variable for you.
2. Setup a visual studio dll empty project named `nconv`, add header path `$(LUA_DEV)\include` and lib path
`$(LUA_DEV)\lib` to options, and link with `lua5.1.lib`.
3. Build the nconv.dll, and copy to `$(LUA_DEV)\clibs`.
4. Run the `test.lua` for test.

## Binary

Yes, build is boring, just get a copy of prebuild binary from the [download area][2].

## TODO

1. Add to rock repos?

[1]: http://code.google.com/p/luaforwindows/downloads/list
[2]: https://bitbucket.org/xpol/nconv/downloads
