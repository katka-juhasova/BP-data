
------------------------------------------------------------------------------

readme '../README.md'
index {
	name = 'dump',
	header = [[A simple module to dump Lua values to strings and files]],
}

------------------------------------------------------------------------------

header()

chapter('about', "About", [[
The prtr-dump module is a simple Lua module that pretty-prints some Lua values in such a way that they are human-readable, while still being valid Lua source to be reloaded by the Lua interpreter.

The name dump is not original, but it reflects the purpose of the library. The prtr- prefix (a contraction for piratery.net, the website domain) is used in case some other Linux bindings emerge with the same naming problems.

## Support

All support is done through the [Lua mailing list](http://www.lua.org/lua-l.html).

Feel free to ask for further developments. I can't guarantee that I'll develop everything you ask, but I want my code to be as useful as possible, so I'll do my best to help you. You can also send me request or bug reports (for code and documentation) directly at [jerome.vuarand@gmail.com](mailto:jerome.vuarand@gmail.com).

## Credits

This module is written and maintained by [Jérôme Vuarand](mailto:jerome.vuarand@gmail.com).

It is available under a [MIT-style license](LICENSE.txt).
]])

chapter('installation', 'Installation', [[
prtr-dump sources are available in its [Mercurial repository](http://hg.piratery.net/dump/):

    hg clone http://hg.piratery.net/dump/

Tarballs of the latest code can be downloaded directly from there: as [gz](http://hg.piratery.net/dump/get/tip.tar.gz), [bz2](http://hg.piratery.net/dump/get/tip.tar.bz2) or [zip](http://hg.piratery.net/dump/get/tip.zip).

Finally, I published some rockspecs:

    luarocks install prtr-dump
]])

chapter('manual', 'Manual', [[
This module is very basic: it exposes three functions, `tostring`, `toscript` and `tofile`, that all take a `value` parameter. The following Lua types are supported: `nil`, `boolean`, `number`, `string` and `table`. For tables, additional restrictions apply. The table keys must be booleans, numbers or strings. The values can be any type supported by this library.

Tables are printed with indentation, recursively. Key-value pairs are ordered in a predictable way so that two identical tables will always be serialized to the same string or file. The key-value pairs are also ordered in a sensible way to improve reading of the data by a human (string keys come first, integer keys are omitted when compatible with an array constructor).

Note that reference comparison is done during the dump to detect and handle multiple references to sub-tables. However this can only be dumped by the `toscript` and `tofile` functions. And at the moment none of the functions can handle reference cycles in the reference graph.

Finally very large tables will be serialized in a special way to avoid the limit on the number of constants in a Lua chunk. By default the key-value pairs will be grouped in chunks of 10 000. This may however be too large if the values are moderately large tables themselves. You can change the `dump.groupsize` variable dynamically to adjust that behaviour.

To use this module:

    local dump = require 'dump'

### dump.tostring ( value )

The `tostring` function takes a value as parameter, and returns an equivalent `string`:

    local value = {
        attribute = 42,
        'foo',
        37,
    }
    
    local s = dump.tostring(value)

To reload the value, use the following code:

    local script = 'return '..s
    local value = loadstring(script)() -- note the double set of parenthesis

### dump.tofile ( value, file )<br/>dump.tofile ( value, filename )

The `tofile` function takes a `value` and a `file` object or a `filename` string as parameters. The `file` object can be any value that has a `write` method that takes a single `string` as parameter, for example the file objects of the Lua `io` library. If a string is passed as a second parameter, it is considered as a filename that will be open, written to and closed. The serialized value is prefixed with the string `"return "`, so that executing the file with for example `dofile` will return the equivalent value. Also if the value is a table containing multiple references (direct or indirect) to some sub-table, some local variables will be created so that dofile reconstructs an equivalent table graph.

    local file = io.open('value.lua')
    dump.tofile(value, file)
    file:close()
    
    dump.tofile(value, 'value.lua')

To reload the value, use the following code:

    local value = dofile('value.lua')

### dump.toscript ( value )

The `toscript` function takes a value as parameter, and returns a `string` that is a Lua script which would recreate an equivalent value. Like `tofile` it can handle multiple references to sub-tables. As such it is more powerful than `tostring`, but the returned `string` for simple values is less human-friendly.

    local script = dump.toscript(value)

To reload the value, use the following code:

    local value = loadstring(script)() -- note the double set of parenthesis

]])

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
