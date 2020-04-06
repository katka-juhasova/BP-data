
# Tag

---

## with closure

Encode URI

```lua
local c = require'CBOR'
local TAG_URI = 32

c.coders['function'] = function (buffer, fct)
    fct(buffer)
end

local function URI (str)
    return function (buffer)
        c.coders.tag(buffer, TAG_URI)
        c.coders.text_string(buffer, str)
    end
end

c.encode{homepage = URI'http://www.luarocks.org'}
```

Encode/Decode BASE64

```lua
local c = require 'CBOR'
local b64 = require 'base64'
local TAG_BASE64 = 34

c.coders['function'] = function (buffer, fct)
    fct(buffer)
end

local function BASE64 (str)
    return function (buffer)
        c.coders.tag(buffer, TAG_BASE64)
        c.coders.text_string(buffer, b64.encode(str))
    end
end

c.register_tag(TAG_BASE64, function (str)
    assert(type(str) == 'string', "invalid data item")
    return b64.decode(str)
end)

c.encode{'encoded_as_string', BASE64'encoded_base64'}
```

## with table as object

Add a method `tocbor` into the class or the prototype.

```lua
local c = require'CBOR'
local TAG_COMPLEX = 42

local Cplx = {}
do
    Cplx.__index = Cplx

    function Cplx.new (re, im)
        local obj = {
            re = tonumber(re),
            im = im ~= nil and tonumber(im) or 0.0,
        }
        return setmetatable(obj, Cplx)
    end

    function Cplx:__tostring ()
        return '(' .. tostring(self.re) .. ', ' .. tostring(self.im) .. ')'
    end

    function Cplx:tocbor (buffer)
        buffer[#buffer+1] = c.TAG(TAG_COMPLEX)
        buffer[#buffer+1] = c.ARRAY(2)
        c.coders.number(buffer, self.re)
        c.coders.number(buffer, self.im)
    end
end

c.coders.table = function (buffer, obj)
    local mt = getmetatable(obj)
    if mt and mt.tocbor then
        obj:tocbor(buffer)
    else
        c.coders._table(buffer, obj)
    end
end

c.register_tag(TAG_COMPLEX, function (data)
    local re, im = unpack(data)
    return Cplx.new(re, im)
end)

local a = Cplx.new(1, 2)
c.encode(a)
```

With [Coat](https://fperrad.frama.io/lua-Coat/),
a method `tocbor` in each class is not needed.

```lua
local Meta = require 'Coat.Meta.Class'
local c = require 'CBOR'
local TAG_COAT = 1234

c.coders.table = function (buffer, obj)
    local classname = obj._CLASS
    if classname then
        buffer[#buffer+1] = c.TAG(TAG_COAT)
        buffer[#buffer+1] = c.ARRAY(2)
        c.coders.text_string(buffer, classname)
        c.coders._table(buffer, obj._VALUES)
    else
        c.coders._table(buffer, obj)
    end
end

c.register_tag(TAG_COAT, function (data)
    local classname, values = unpack(data)
    local class = assert(Meta.class(classname))
    return class.new(values)
end)
```

```lua
class 'Point'

has.x = { is = 'ro', isa = 'number', default = 0 }
has.y = { is = 'ro', isa = 'number', default = 0 }
has.desc = { is = 'rw', isa = 'string' }

function overload:__tostring ()
    return '(' .. tostring(self.x) .. ', ' .. tostring(self.y) .. ')'
end

local a = Point{x = 1, y = 2}
c.encode(a)
```

## with userdata

```lua
local c = require'CBOR'
local bc = require 'bc'
local TAG_BC = 42
bc.digits(65)

c.coders.userdata = function (buffer, u)
    if getmetatable(u) == bc then
        c.coders.tag(buffer, TAG_BC)
        c.coders.text_string(buffer, tostring(u))
    else
        error("encode 'userdata' is unimplemented")
    end
end

c.register_tag(TAG_BC, function (data)
    return bc.number(data)
end)
```

With a method `tocbor` which contains the encoding stuff.
This allows to work with many kind of `userdata`,
`CBOR.coders.userdata` is _generic_.

```lua
local c = require'CBOR'
local bc = require 'bc'
local TAG_BC = 42
bc.digits(65)

function bc:tocbor (buffer)
    c.coders.tag(buffer, TAG_BC)
    c.coders.text_string(buffer, tostring(self))
end

c.coders.userdata = function (buffer, u)
    local mt = getmetatable(u)
    if mt and mt.tocbor then
        u:tocbor(buffer)
    else
        error("encode 'userdata' is unimplemented")
    end
end

c.register_tag(TAG_BC, function (data)
    return bc.number(data)
end)
```
