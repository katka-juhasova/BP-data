
# CBOR

---

# Reference

#### encode( data )

Serialize a `data`.

#### decode( str )

Deserialize a `string`.

#### decoder( src )

Accept a `string` or a [`ltn12.source`](http://w3.impa.br/~diego/software/luasocket/ltn12.html#source)
and returns a iterator.

The iterator gives a couple of values,
the _interesting_ value is the second.

#### set_string( str )

Configures the behaviour of `encode`.
The valid options are `'byte_string'`, `'text_string'` and `'check_utf8'` (only if Lua 5.3).
The default is `'text_string'`.

#### set_array( str )

Configures the behaviour of `encode`.
The valid options are `'without_hole'`, `'with_hole'` and `'always_as_map'`.
The default is `'without_hole'`.

#### set_nil( str )

Configures the behaviour of `encode`.
The valid options are `'null'` and `'undef'`.
The default is `'undef'`.

#### set_float( str )

Configures the behaviour of `encode`.
The valid options are `'half'`, `'single'` and `'double'`.
The default is _usually_ `'double'`.

#### register_tag( tag, builder )

Configures the behaviour of `decode`.
Registers a function `builder` which will be called for a tagged value.

## Data Conversion

- The following __Lua__ types could be converted :
  `nil`, `boolean`, `number`, `string` and `table`.
- A __Lua__ `number` is converted into an __CBOR__ `integer`
  if `math.floor(num) == num`, otherwise it is converted
  into the __CBOR__  `half` or `single` or `double` (see `set_float`).
- When a __CBOR__ 64 bits `integer` is converted to a __Lua__ `number`
  it is possible that the resulting number will not represent the original number but just an approximation.
- A __Lua__ `table` is converted into a __CBOR__ `array`
  only if _all_ the keys are composed of strictly positive integers,
  without hole or with holes (see `set_array`).
  Otherwise it is converted into __CBOR__ `map`.
- An empty `table` is always converted into a __CBOR__ `array`.
- With `set_array'always_as_map'`,
  all __Lua__ `table` are converted into a __CBOR__ `map`.
- Lua does not allow `nil` and `NaN (0/0)` as `table` index, by default,
  the deserialization of this kind of __CBOR__ map skips the key/value pair.
  The value could preserved by defining the module member `sentinel` which is used as key.
- LIMITATION : __CBOR__ cannot handle data with _cyclic_ reference.

# Examples

## Basic usage

```lua
local c = require 'CBOR'

c.set_float'single'
c.set_nil'null'
c.set_array'with_hole'
c.set_string'text_string'

cbor = c.encode(data)
data = c.decode(cbor)
```

See other usages in [Stream](stream.md) and [Tag](tag.md).

## Advanced usage

The following Lua hack allows to have several instances
of the module `CBOR`, each one with its own settings.

```lua
local c1 = require 'CBOR'
package.loaded['CBOR'] = nil    -- the hack is here
local c2 = require 'CBOR'

c1.set_array'without_hole'
c2.set_array'always_as_map'
```
