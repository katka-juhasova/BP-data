# luarestructure

luarestructure is a nearly line-by-line port of [restructure] (including this README)
from Javascript to Lua.

[restructure]: https://github.com/devongovett/restructure

Restructure allows you to declaratively encode and decode binary data.
It supports a wide variety of types to enable you to express a multitude
of binary formats without writing any parsing code.

Some of the supported features are C-like structures, versioned structures,
pointers, arrays of any type, strings of a large number of encodings, enums,
bitfields, and more.  See the documentation below for more details.

## Example

This is just a small example of what Restructure can do. Check out the API documentation
below for more information.

```lua
local r = require('restructure')

local Person = r.Struct.new({
  { name = r.String.new(r.uint8, 'utf8') },
  { age = r.uint8 }
})

-- decode a person from a buffer
local stream = r.DecodeStream.new(buffer)
Person.decode(stream) -- returns an object with the fields defined above

-- encode a person from an object
-- pipe the stream to a destination, such as a file
local stream = r.EncodeStream.new()

Person.encode(stream, {
  name = 'Devon',
  age = 21
})

local f = io.open("out.bin", "wb")
f:write(stream.getContents())
```


## API

All of the following types support three standard methods:

* `decode(stream)` - decodes an instance of the type from the given DecodeStream
* `size(value)` - returns the amount of space the value would take if encoded
* `encode(stream, value)` - encodes the given value into the given EncodeStream

Restructure supports a wide variety of types, but if you need to write your own for
some custom use that cannot be represented by them, you can do so by just implementing
the above methods. Then you can use your type just as you would any other type, in structures
and whatnot.

### Number Types

The following built-in number types are available:

```lua
uint8, uint16, uint24, uint32, int8, int16, int24, int32, float, double, fixed16, fixed32
```

Numbers are big-endian (network order) by default, but little-endian is supported, too:

```lua
uint16le, uint24le, uint32le, int16le, int24le, int32le, floatle, doublele, fixed16le, fixed32le
```

To avoid ambiguity, big-endian may be used explicitly:

```lue
uint16be, uint24be, uint32be, int16be, int24be, int32be, floatbe, doublebe, fixed16be, fixed32be
```

### Boolean

Booleans are encoded as `0` or `1` using one of the above number types.

```lua
local bool = r.Boolean.new(r.uint32)
```

### Reserved

The `Reserved` type simply skips data in a structure, where there are reserved fields.
Encoding produces zeros.

```lua
-- 10 reserved uint8s (default is 1)
local reserved = r.Reserved.new(r.uint8, 10)
```

### Optional

The `Optional` type only encodes or decodes when given condition is truthy.

```lua
-- includes field
local optional = r.Optional.new(r.uint8, true)

-- excludes field
local optional = r.Optional.new(r.uint8, false)

-- determine whether field is to be included at runtime with a function
local optional = r.Optional.new(r.uint8, function(res) do
  return bit32.band(res.flags, 0x50)
end);
```

### Enum

The `Enum` type maps a number to the value at that index in an array.

```lua
local color = r.Enum.new(r.uint8, {'red', 'orange', 'yellow', 'green', 'blue', 'purple'})
```

### Bitfield

The `Bitfield` type maps a number to an object with boolean keys mapping to each bit in that number,
as defined in an array.

```lua
local bitfield = r.Bitfield.new(r.uint8, {'Jack', 'Kack', 'Lack', 'Mack', 'Nack', 'Oack', 'Pack', 'Quack'})
bitfield.decode(stream)

local result = {
  Jack = true,
  Kack = false,
  Lack = false,
  Mack = true,
  Nack = true,
  Oack = false,
  Pack = true,
  Quack = true
}

bitfield:encode(stream, result)
```

### Buffer

Extracts a slice of the buffer to a Lua string.  The length can be a constant, or taken from
a previous field in the parent structure.

```lua
-- fixed length
local buf = r.Buffer.new(2);

-- length from parent structure
local struct = r.Struct.new({
  { bufLen = r.uint8 },
  { buf = r.Buffer.new('bufLen') }
})
```

### String

A `String` maps a binary byte stream to a Lua string.  The length can be a constant, taken
from a previous field in the parent structure, or encoded using a number type immediately before the string.

In order to stay compatible with the original Javascript API, the constructor allows an additional
argument to specify the encodings (for e.g. `'ascii'`, `'utf8'`, `'ucs2'`, `'utf16le'`, `'utf16be'` etc).
However, this is only for informational purposes, because strings in Lua are just a series of bytes. The consumer
code can use this information to do additional processing (before encoding or after decoding) if desired.

```lua
-- fixed length, ascii encoding by default
local str = r.String.new(2)

-- length encoded as number before the string, utf8 encoding
local str = r.String.new(r.uint8, 'utf8')

-- length from parent structure
var struct = r.Struct.new({
  { len = r.uint8 },
  { str = r.String.new('len', 'utf16be') }
})

-- null-terminated string (also known as C string)
local str = r.String.new(nil, 'utf8')
```

### Array

An `Array` maps to and from a JavaScript array containing instances of a sub-type. The length can be a constant,
taken from a previous field in the parent structure, encoded using a number type immediately
before the string, or computed by a function.

```lua
-- fixed length, containing numbers
local arr = r.Array.new(r.uint16, 2)

-- length encoded as number before the array containing strings
local arr = r.Array.new(r.String.new(10), r.uint8);

-- length computed by a function
local arr = new r.Array(r.uint8, function() { return 5 });

-- length from parent structure
local struct = r.Struct.new({
  { len = r.uint8 },
  { arr = r.Array.new(r.uint8, 'len') }
})

-- treat as amount of bytes instead (may be used in all the above scenarios)
local arr = r.Array.new(r.uint16, 6, 'bytes')
```

### LazyArray

The `LazyArray` type extends from the `Array` type, and is useful for large arrays that you do not need to access sequentially.
It avoids decoding the entire array upfront, and instead only decodes and caches individual items as needed. It only works when
the elements inside the array have a fixed size.

Instead of returning a Lua table array, the `LazyArray` type returns a custom object that can be used to access the elements.

```lua
local arr = r.LazyArray.new(r.uint16, 2048);
local res = arr.decode(stream);

-- get a single element
var el = res.get(2)

-- convert to a normal array (decode all elements)
local array = res.toArray()
```

### Struct

A `Struct` maps to and from Lua tables, containing keys of various previously discussed types. Sub structures,
arrays of structures, and pointers to other types (discussed below) are supported.

_NOTE: The original Javascript API relied on the fact that keys are iterated in [order of creation/insertion][spec].
However, Lua makes no guarantees about order of iteration of keys._

_This means that the first argument to the `Struct` class is a table of tables, ensuring that order of keys
is preserved. Note the change in the examples below, and in the next section._

[spec]: http://www.ecma-international.org/ecma-262/6.0/#sec-ordinary-object-internal-methods-and-internal-slots-ownpropertykeys

```lua
var Person = new r.Struct({
  { name: r.String.new(r.uint8, 'utf8') },
  { age: r.uint8 }
})
```

### VersionedStruct

A `VersionedStruct` is a `Struct` that has multiple versions. The version is typically encoded at
the beginning of the structure, or as a field in a parent structure. There is an optional `header`
common to all versions, and separate fields listed for each version number.

```lua
-- the version is read as a uint8 in this example
-- you could also get the version from a key on the parent struct
local Person = r.VersionedStruct.new(r.uint8, {
  -- optional header common to all versions
  header = {
    { name = r.String.new(r.uint8, 'utf8') }
  },
  0 = {
    { age: r.uint8 }
  },
  1 = {
    { hairColor: r.Enum.new(r.uint8, {'black', 'brown', 'blonde'}) }
  }
})
```

### Pointer

Pointers map an address or offset encoded as a number, to a value encoded elsewhere in the buffer.
There are a few options you can use: `type`, `relativeTo`, `allowNull`, and `nullValue`.
The `type` option has these possible values:

* `local` (default) - the encoded offset is relative to the start of the containing structure
* `immediate` - the encoded offset is relative to the position of the pointer itself
* `parent` - the encoded offset is relative to the parent structure of the immediate container
* `global` - the encoded offset is global to the start of the file

The `relativeTo` option specifies that the encoded offset is relative to a field on the containing structure.
By default, pointers are relative to the start of the containing structure (`local`).

The `allowNull` option lets you specify whether zero offsets are allowed or should produce `nil`. This is
set to `true` by default. The `nullValue` option is related, and lets you override the encoded value that
represents `nil`. By default, the `nullValue` is zero.

The `lazy` option allows lazy decoding of the pointer's value by defining a getter on the parent object.
This only works when the pointer is contained within a Struct, but can be used to speed up decoding
quite a bit when not all of the data is needed right away.

```lua
local Address = new r.Struct.new({
  { street = r.String.new(r.uint8) },
  { zip = new r.String(5) }
})

local Person = new r.Struct({
  { name = r.String.new(r.uint8, 'utf8') },
  { age = r.uint8 },
  { ptrStart = r.uint8 },
  { address = r.Pointer.new(r.uint8, Address) }
})
```

If the type of a pointer is set to 'void', it is not decoded and the computed address in the buffer
is simply returned. To encode a void pointer, create a `r.VoidPointer.new(type, value)`.

## License

MIT
