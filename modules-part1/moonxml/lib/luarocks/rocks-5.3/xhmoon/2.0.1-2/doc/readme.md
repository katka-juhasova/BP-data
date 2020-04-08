XHMoon
================================================================================

A simple helper library to be used in MoonXML to create a generator syntax for
XML and HTML code.

When required, it returns a single function which returns a new *language*.

This function accepts a node handler function as its argument.
The node handler will be called for each node (XML tag) and output its
corresponding representation in the *language*.

*Languages* in this context are the set of rules for how to build the output
from an xhmoon template, and are internally represetned as a table.

A node handler should accept four arguments:

-	Environment
	The environment of the language.
-	Tag name
	The name of the tag to be generated.
-	Attributes
	A table of key-value pairs representing attributes of the node.
-	Content
	A function that should be called where the content of the node should go.
	If it is given an argument, it will assume it to be a function that escapes
	a string and call it on text entries; if not, it won't escape text by
	default.

An example node handler for XML:

	function(env, tag, args, inner)
		local argstrings = {}
		for key, value in pairs(args) do
			table.insert(argstrings, ('%s="%s"'):format(key, value))
		end
		if inner
			env.print(([[<%s %s >]]):format(tag, table.concat(argstrings)))
			inner(escape)
			env.print(([[</%s>]]):format(tag))
		else
			env.print(([[<%s %s />]]):format(tag, table.concat(argstrings)))
		end
	end

The *language* returned by the function provides an environment in which to run
another function and can be duplicated with the `derive` method.
Derived *languages* inherit all of its parents properties and can be modified and
extended as needed.

Initializers
--------------------------------------------------------------------------------

Since version 1.2.0 *languages* can have initializers.

Initializers are functions that initialize an environment. This can include
defining custom functions that rely on the environment and should be inheritable
in such a way that they use the derived *languages* environment when called from
that *language*.

Initializers can be passed as an argument to the *language* constructor
or as the second argument to the `derive` method.

In Lua 5.1, initializers will have their environment set to the environment in
question before being called, and reset afterwards. Regardless of version, they
will be called with the environment as their first argument.

### Example use

	-- Assumes the node handler has been already defined elsewhere
	local html = require 'moonxml' (node_handler, function(_ENV)
		function html5()
			print '<!doctype html>'
		end
	end)

This adds a `html5` function that can be used in `html` and all derived
languages, which generates an HTML 5 doctype.

Note that calling the first argument `_ENV` is equivalent to calling it `foo`
and setting `_ENV = foo` at the start of the function. In Lua 5.1 this has no
special meening and in 5.2+ it sets the environment of the function.

Changelog
--------------------------------------------------------------------------------

### 2.0.1
- Fix bug with environment inheritance

### 2.0.0
- Make escaping by default optional
- Kinda wreck the interface

### 1.2.0
- Add initializers

### 1.1.3
- Fix bug that was causing derived *languages* not to inherit methods defined
	directly on their parents

### 1.1.2
- Rename file from xh.lua to xhmoon.lua for consistency
- Add some basic tests

### 1.1.1
- Fix severe bugs in loadluafile
- Delete moonscript file and just switch to Lua

### 1.1
- Add loadlua and loadluafile functions
