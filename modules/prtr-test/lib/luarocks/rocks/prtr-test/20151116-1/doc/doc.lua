
------------------------------------------------------------------------------

readme '../README.md'
index {
	name = 'test',
	header = [[A simple module to simplify writing Lua modules self tests]],
	index = {
		{title="home"},
		{section='installation', title="installation"},
		{section='manual', title="manual"},
		{section='examples', title="examples"},
	},
}

------------------------------------------------------------------------------

header()

chapter('about', "About", [[
The prtr-test module is a simple Lua module that helps writing tests for other Lua modules. It's mainly exposing an `expect` global function that can be used instead of `assert` to get better error messages when a test fails. Since this is the only point of the library you may want to have a look at the [examples](#examples) below.

The name test is not original, but it reflects the purpose of the library. The prtr- prefix (a contraction for piratery.net, the website domain) is used in case some other Linux bindings emerge with the same naming problems.

## Support

All support is done through the [Lua mailing list](http://www.lua.org/lua-l.html).

Feel free to ask for further developments. I can't guarantee that I'll develop everything you ask, but I want my code to be as useful as possible, so I'll do my best to help you. You can also send me request or bug reports (for code and documentation) directly at [jerome.vuarand@gmail.com](mailto:jerome.vuarand@gmail.com).

## Credits

This module is written and maintained by [Jérôme Vuarand](mailto:jerome.vuarand@gmail.com).

It is available under a [MIT-style license](LICENSE.txt).

]])

chapter('installation', 'Installation', [[
prtr-test sources are available in its [Mercurial repository](http://hg.piratery.net/test/):

    hg clone http://hg.piratery.net/test/

Tarballs of the latest code can be downloaded directly from there: as [gz](http://hg.piratery.net/test/get/tip.tar.gz), [bz2](http://hg.piratery.net/test/get/tip.tar.bz2) or [zip](http://hg.piratery.net/test/get/tip.zip).

Finally, I published a rockspec:

    luarocks install prtr-test
]])

chapter('manual', 'Manual', [[
This module is very basic, it creates one global function, `expect`, that is similar to the Lua built-in `assert` function, but that will provide better default error messages.

To load the module, simply write:

    require 'test'

From then on a global `expect` function will be available.

### expect ( expectation, value )

The `expect` function takes two Lua values parameters. It will throw an error if the two values don't match. For immutable values (nil, booleans, numbers and strings), the values must be identical (as defined by the == operator). For functions and threads, both values must be references to the same object.

The case of tables is where this module can come handy. Both tables are compared recursively, and each key-value pair must match, with the restriction that keys can only be booleans, numbers or strings (otherwise an error is thrown).

Finally, if both values are userdata sharing the same metatable, and that metatable has a `__tostring` field, `tostring` is called on both values and the resulting strings are compared.
]])

chapter('examples', 'Examples', [[
The purpose of this module is only to get better generated error messages when tests fail. Here are some example to help you decide if this module is worth using it.

When comparing simple values, the following:

    local function f() return 42 end
    expect('foo', f())
    
would throw the error:

    script.lua:2: expectation failed! foo (string) expected, got 42 (number)

When comparing tables, a path to the first mismatching field will be displayed. The following:

    local function f() return {
        data = {'a', 'b2', 'c'},
    } end
    expect({ data = {'a', 'b', 'c'} }, f())

would throw the error:

    script.lua:4: expectation failed! b (string) expected for field .data[2], got b2 (string)
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
