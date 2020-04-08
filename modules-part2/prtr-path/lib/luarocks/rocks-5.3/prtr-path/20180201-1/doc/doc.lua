
------------------------------------------------------------------------------

readme '../README.md'
index {
	name = 'path',
	header = [[A simple module to manipulate file paths in Lua]],
}

------------------------------------------------------------------------------

header()

chapter('about', "About", [[
The prtr-path module is a simple Lua module that manipulates file paths. Path objects can be created from strings, and concatenated together using the / operator. Additionally they provide some useful accessors, methods and metamethods.

The name path is not original, but it reflects the purpose of the library. The prtr- prefix (a contraction for piratery.net, the website domain) is used in case some other Linux bindings emerge with the same naming problems.

## Support

All support is done through the [Lua mailing list](http://www.lua.org/lua-l.html).

Feel free to ask for further developments. I can't guarantee that I'll develop everything you ask, but I want my code to be as useful as possible, so I'll do my best to help you. You can also send me request or bug reports (for code and documentation) directly at [jerome.vuarand@gmail.com](mailto:jerome.vuarand@gmail.com).

## Credits

This module is written and maintained by [Jérôme Vuarand](mailto:jerome.vuarand@gmail.com).

It is available under a [MIT-style license](LICENSE.txt).

]])

chapter('installation', 'Installation', [[
prtr-path sources are available in its [Mercurial repository](http://hg.piratery.net/path/):

    hg clone http://hg.piratery.net/path/

Tarballs of the latest code can be downloaded directly from there: as [gz](http://hg.piratery.net/path/get/tip.tar.gz), [bz2](http://hg.piratery.net/path/get/tip.tar.bz2) or [zip](http://hg.piratery.net/path/get/tip.zip).

Finally, I published some rockspecs:

    luarocks install prtr-path
]])

chapter('manual', 'Manual', [=[
This module revolves around a `path` object type. A `path` can represent the path to a file on the computer filesystem, but hides platform-specific details. It can also represent portions of a URL. At the moment only Unix paths and Windows paths are supported, but more path types may be added on request.

The basic objective of this library is to avoid writing directory separators inside strings in Lua code, to improve the portability of that code. Path strings should be converted to path objects as soon as possible, and from there manipulated using the `path` object facilities.

To use this module:

    local pathlib = require 'path'

Note that in the examples here we use the name `pathlib` in the code to reference the module itself and `path` to reference the path datatype. This is to avoid ambiguities. The module name however is `"path"`, and that name should be passed to `require` (as shown above).

All `path` objects are immutable, but they are not interned like Lua strings, and as such the semantics when used as keys in tables differ. To create a path object, one can either call the function `pathlib.split` to split a string, or assemble new paths from existing paths using the / operator. An empty `path` object is predefined with the name `pathlib.empty`.

### pathlib.split ( string )

The `split` function takes a `string` as parameter, and converts it to an equivalent `path` object. The string may contains either a Unix path with slash characters, or a Windows path with backslash characters. The path may optionally start with a root element, which would be a letter followed by a colon to represent a Windows drive, or a double backslash to mark the path as a UNC path.

If the path string following the root starts with a slash or a backslash, it is marked as absolute (UNC paths are always absolute).

    local lua = pathlib.split([[/usr/bin/lua]])

A convention used in the rest of this manual is to use the alias `P` for pathlib.split. It is defined as follows:

    local P = pathlib.split
    local explorer = P[[C:\Windows\explorer.exe]]

### pathlib.empty

`pathlib.empty` is an empty path. It can be used to represent a special empty path, or as a basis to build relative paths.

    local E = pathlib.empty

    local conf = E / '.conf' / 'app.cfg'

### pathlib.type (value)

The `pathlib.type` function is similar to the standard Lua `type` and `io.type` functions. It will return the string `"path"` if `value` is a path object. Otherwise it will return the same value as the standard Lua `type` function.

### pathlib.install ()

The `pathlib.install` function will install the path module inside the following other modules: `_G` (for `loadfile` and `dofile`), `io`, `os` and `lfs`. All functions in these modules receiving or returning path strings will instead accept or return `path` objects.

    local lfs = require 'lfs'
    pathlib.install()
    
    local root = lfs.currentdir()
    local path = root / '.conf' / 'myapp.cfg'
    local config
    if lfs.attributes(path, 'mode') then
        config = dofile(path)
    end

### path.string

`path.string` is a string representation of the `path` object, in a platform-specific format. Use this accessor to pass the path to functions that expect paths as a string in the native representation of the platform. Note that a UNC path will use backslashes on all platforms. To force the use of slashes (or any other character) in UNC paths, use `path:tostring(separator)` with a `separator` string.

### path.ustring

`path.ustring` is a string representation of the `path` object in Unix format, with slashes as directory separators. A Windows path with a drive root may still have a drive letter before the first slash. A Windows UNC path will start with two slashes.

### path.wstring

`path.wstring` is a string representation of the `path` object in Windows format, with backslashes as directory separators.

### path.leaf, path.file

`path.file` is the last component of a path, as a `string`. The path library is disconnected from any underlying file system, so this name may represent either a file or a directory (or nothing).

`path.leaf` is an alias for `path.file`.

### path.parent, path.dir

`path.parent` is the parent `path` of the object, which is an identical path minus the last component. The `parent` of an empty `path` is `nil`.

`path.dir` is an alias for `path.parent`.

### path.root

A `path` object may have an optional root. This root is a string that can be either a drive letter (an uppercase letter followed by a colon, for example `"C:"`), or the string `"UNC"` for UNC paths. Rooted paths are mostly useful to represent Windows file paths.

### path.absolute

`path.absolute` is a boolean value that specifies whether the `path` object is absolute or not. Note that a path with a root drive may not necessarily be absolute. For example `[[C:\Windows]]` is an absolute path, but `[[E:Data\Subdir]]` is relative. All UNC paths are absolute.

### path.relative

`path.relative` is the complementary value of `path.absolute`.

### path:tostring ([separator])

`path:tostring()` is identical to `path.string`. An optional `separator` string can be passed as argument, and it will be used instead of slashes and backslashes as directory separators. Note that the prefix of a UNC path will consist of two of these separators.

### tostring (path)

`tostring(path)` is identical to `path.string`, with the additional benefit that if `path` is not a `path` object, the result of the expression is still a string.

### # path

`#path` returns the number of components in the path, excluding any root or the absolute prefix. The following paths all have a length of 3: `P[[C:\Windows\system32\kernel32.dll]]`, `P'/usr/bin/lua'`, `P".conf/myapp/app.cfg"`.

### path:sub (i [, j])

Returns a path containing the components of `path` in the range [i-j]. If `j` is omitted, it is the length of the `path`. If `j` is negative, it is considered as an index from the end of the path (-1 being the last component, -2 the one before that, etc.). If `i` is greater or equal to 1, the resulting path is relative and has no root. To keep the same `root` and `absolute` flag as `path`, `i` must be 0 or negative. Therefore a convenient way to get the relative part of an absolute path is to call `path:sub(1)`.

### path1 == path2

This expression if true if `path1` and `path2` are identical paths, including all components, `root` and `absolute` flag.

### path / path

This expression concatenates two paths in a sensible way, which is not always straightforward. However some cases are ambiguous and will generate an error.

### path / string

This expression concatenates a path and a string, and returns a path identical to the passed one except it contains an additional component. Thanks to Lua operator precedence, several of these can be chained.

    local P = pathlib.split
    local path = P(os.getenv('HOME)) / '.conf' / 'myapp' / 'app.cfg'

Note however that the division operator has a higher precedence than the concatenation operator, so the following will generate an error:

    local appname = 'foo'
    local path = P(os.getenv('HOME)) / '.conf' / appname / appname..'.cfg'

In this case the correct syntax would be:

    local path = P(os.getenv('HOME)) / '.conf' / appname / (appname..'.cfg')

]=])

footer()

------------------------------------------------------------------------------

--[[
Copyright (c) Jérôme Vuarand

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

-- vi: ts=4 sts=4 sw=4 noet
