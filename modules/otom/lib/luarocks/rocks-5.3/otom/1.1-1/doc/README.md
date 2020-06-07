# One-To-One Map

A **O**ne-**T**o-**O**ne **M**ap enforces a one-to-one relationship between keys and values.

## Installation

Install using [LuaRocks](https://luarocks.org):

	luarocks install otom

Alternatively, you could just grab `otom.lua` and use it directly in your project.

## Testing

This module uses [busted](https://olivinelabs.com/busted/) for testing. Once you have that installed, navigate to the repository root directory and run:

	busted .

## Basic Use

	otom = require("otom")
	t = otom.new()
	t.x = "Hello"
	t.y = "Hello"
	assert(t.x == nil)
	assert(t.y == "Hello")

Since there is a one-to-one relationship between keys and values, it becomes trivial to find a key for a given value. `otom` heavily supports this feature: `otom.new()` returns both a "forward table" which maps keys to values and a "reverse table" which maps values to keys. **Every feature supported by the forward table is supported by the reverse table as well.**

	ft, rt = otom.new()
	ft.x = "Hello"
	ft.y = "World"
	assert(rt.Hello == "x")
	assert(rt.World == "y")

These tables are proxies. However, thanks to the [\_\_pairs metamethod in Lua 5.3](https://www.lua.org/manual/5.3/manual.html#pdf-pairs) it is still possible to use `pairs` and `ipairs` as usual.

	assert(rawget(ft, "x") == nil)
	assert(rawget(rt, "Hello") == nil)
	for k,v in pairs(ft) do
		assert(rt[v] == k)
	end
	for k,v in pairs(rt) do
		assert(ft[v] == k)
	end

## Initial Tables and Iterator Factories

A one-to-one map can be created from a regular table.

	planets = { "Mercury", "Venus", "Earth", "Mars" }
	planet_ft, planet_rt = otom.new(planets)
	for i,v in ipairs(planet_ft) do
		assert(planet_rt[v] == i)
	end

`otom.new` takes up to three arguments related to handling this initial table.

	otom.new([initial_table], [repeat_mode], [iter_factory])

### repeat\_mode 

By default, if the initial table has a repeated value, `otom.new` throws an error.

	res = pcall(function() t = otom.new({ "A", "A", "B" }) end)
	assert(res == false)

However this behaviour can be changed by setting `repeat_mode` to one of the following values:

 + `otom.ERR`: when a repeated value is found, throw an error (default behaviour).
 + `otom.FIRST`: when a repeated value is found, only preserve the first key-value association encountered with that value.
 + `otom.LAST`: when a repeated value is found, only preserve the last key-value association encountered with that value.

The initial table is traversed in an order defined (or undefined, in the case of `pairs`) by the `iter_factory` argument.

### iter\_factory

By default, the initial table is traversed using `pairs`. However, that might not always be the optimal choice for traversal, especially since the order of keys accessed by `pairs` is not specified.

The `iter_factory` is an iterator factory function that will be called with the initial table as an argument. It will be used in a generic for loop to traverse that table. Among the functions in the Lua standard library, `pairs` and `ipairs` are the better choices of iterator factory.

Setting the `iter_factory` to `ipairs` allows you to use `repeat_mode` to predictably handle repeated values in the initial table.

	t = otom.new({ "A", "A", "B" }, otom.FIRST, ipairs)
	assert(t[1] == "A")
	assert(t[2] == nil)
	assert(t[3] == "B")

	t = otom.new({ "A", "A", "B" }, otom.LAST, ipairs)
	assert(t[1] == nil)
	assert(t[2] == "A")
	assert(t[3] == "B")

You can use other iterator factories if you wish. Iterators and iterator factories are explained extensively in [this section of PIL](https://www.lua.org/pil/7.html).

It is possible to do away with having an initial table entirely if the iterator factory can produce all the necessary values.

	t = otom.new(nil, nil, my_awesome_iter)

The above code will call `my_awesome_iter(nil)` to try extracting keys and values to be used in the forward table (which will become the value and keys, respectively, of the reverse table).

	for k,v in my_awesome_iter(nil) do
		--Place k,v correctly
	end

## Hacking

**This is outside the supported use of this module**, but it is possible to bypass the one-to-one restriction like so:

	t = otom.new({ "A", "B" })
	_, rawt = pairs(t)
	rawt[3] = "A"
	for k,v in pairs(t) do
		print(k, v) --The value "A" is repeated.
	end

The `rawt` variable is a table which **actually** stores the values retrieved through `t`. Doing this puts the forward and reverse tables "out-of-sync".

It may be useful to access `rawt` when writing iterators and iterator factories. However for most tasks it is probably best to avoid messing with `rawt`.
