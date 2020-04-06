
# Coat.Role

---

# Reference

## Global Functions

#### role( modname )

Create a Coat role as a standard Lua module.

## Functions in the _built_ Role

#### excludes( role [, ...] )

A role could exclude a list of other roles.

#### has.name = { options }

Adds a attribute `name` in the current role, like in a class.

#### method.name = func

Registers a method, like in a class.

#### requires( method [, ...] )

A role could require a list of method in the class which consumes it.

# Examples

## Like an Interface

```lua
require 'Coat.Role'

role 'Breakable'
requires '_break'

require 'Coat'

class 'Car'
with 'Breakable'

function method:_break ()
    return "I broke"
end
```
