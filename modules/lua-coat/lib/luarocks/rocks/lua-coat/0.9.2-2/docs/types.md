
# Coat.Types

---

# Reference

This module provides the ability to create constrained type
and parametrized type which are used in attribute definition.

All functions are stored in a global space.

The option `isa` handles :

- basic types from Lua
- Coat classnames
- subtypes
- parametrized types

The option `does` handles :

- Coat rolenames

Subtypes are declared by `subtype` or `enum` statements.

Parametrized types have the following forms
(and don't need a preliminary declaration):

- `table<type>`
- `table<type_k,type_v>`

## Global Functions

#### coerce.type = { from = via [, from = via, ...] }

Declares the `type` coerce from the type named `from` via a function `via`.

#### enum.name = { string1, string2 [, ...] }

Creates a subtype `name` for a given set of strings.

#### subtype.name = { as = parent, where = validator [, message = msg ] }

Creates a subtype `name` from the type `parent`
which passes the constraint specified in the function `validator`,
the optional `msg` is used as error message.

# Examples

## Constrained Types

```lua
require 'Coat.Types'

subtype.Natural = {
    as = 'number',
    where = function (val) return val > 0 end,
}

subtype.NaturalLessThanTen = {
    as = 'Natural',
    where = function (val) return val < 10 end,
    message = "This number (%d) is not less than ten!",
}

enum.MyApp.Colour = { 'Red', 'Green', 'Blue' }

subtype.DateTime = {
    as = 'string',
    where = function (val) return true end,
}

coerce.DateTime = {
    number = function (val) return os.date("!%d/%m/%Y %H:%M:%S", val) end
}
```

## Parametrized Types

```lua
require 'Coat.Types'

class 'A'

has.array_of_str = { is = 'rw', isa = 'table<string>' }
has.hash_of_a = { is = 'rw', isa = 'table<string,A>' }
has.hash_of_num = { is = 'rw', isa = 'table<string,number>' }
has.many_a = { is = 'rw', isa = 'table<A>' }
```
