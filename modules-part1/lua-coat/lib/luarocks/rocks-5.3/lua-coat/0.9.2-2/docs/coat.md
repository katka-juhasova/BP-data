
# Coat

---

# Reference

## Global Functions

#### abstract( modname )

Create a Coat abstract class as a standard Lua module.

#### augment( class )

Reopen a Coat class.

#### class( modname )

Create a Coat class as a standard Lua module.

#### singleton( modname )

Create a Coat singleton class as a standard Lua module.

## Functions in the _built_ Class

#### after.name = func

Method modifier.

#### around.name = func

Method modifier.
The new method receives the old one as first parameter.

#### before.name = func

Method modifier.

#### bind.name = class or func

Create a binding for dependency injection.

#### can( obj, methname ) or obj:can( methname )

Checks if a object has a method `methname`.

#### does( obj, r ) or obj:does( r )

Checks if a object consumes `r` which is a role or rolename.

#### dump( obj [, label] ) or obj:dump( [label] )

Dumps the object.
The default value of `label` is `"obj"`.

#### extends( class [, ...] )

Extends the current class with the list of class in parameter.

#### has.name = { ['+', ] option1 = value1, option2 = value2, ... }

Adds a attribute name in the current class.
An item `'+'` allows overriding.

The following options are available :

- `builder` : function name
- `coerce` : boolean
- `default` : value or function
- `does` : role name
- `handles` : table or role for method delegation
- `inject` : boolean for dependency injection
- `is` : string (`ro`|`rw`)
- `isa` : type name
- `lazy` : boolean
- `lazy_build` : boolean
- `required` : boolean
- `reset` : boolean
- `trigger` : function

#### instance( args )

Alias of new for `singleton` class.

#### isa( obj, t ) or obj:isa( t )

Checks if a object is an instance of `t` which is a class or classname.

#### overload.name = func

Registers a metamethod.

#### override.name = func

Method modifier.

#### method.name = func

Registers a method.

#### memoize( methname )

Allows memoization for a method.

#### mock( obj, methname, func ) or obj:mock( methname, func )

Overrides a method of an object.

#### new( args )

Instanciates a object.

If exist, the user method `BUILD` is called at the end.

#### type( obj ) or obj:type()

Returns the type of `obj`.

#### unmock( obj, methname ) or obj:unmock( methname )

Restore the initial method of a mocked object.

#### with( role [, alias-excludes ] [, role, ... ] )

Composes one or more `role`,
a optional table `alias-excludes` allows to prevent name collision.

# Examples

## Point

```lua
require 'Coat'

class 'Point'

has.x = { is = 'rw', isa = 'number', default = 0 }
has.y = { is = 'rw', isa = 'number', default = 0 }

function overload:__tostring ()
    return '(' .. self.x .. ', ' .. self.y .. ')'
end

function method:draw ()
    return "drawing " .. self._CLASS .. tostring(self)
end
```

```lua
local p1 = Point{ x = 1, y = 2 }
p1:draw()
```

## Point3D

```lua
require 'Coat'

class 'Point3D'
extends 'Point'

has.z = {is = 'rw', isa = 'number', default = 0 }

function overload:__tostring ()
    return '(' .. self.x .. ', ' .. self.y .. ', ' .. self.z .. ')'
end
```

```lua
local p1 = Point3D{ x = 1, y = 2, z = 3 }
p1:draw()
```

### Tips

The following code is usually an error
because all instance of `Foo` share the same table as attribute `bar`.

```lua
class 'Foo'
has.bar = { default = {} }
```

The correct version is :

```lua
has.bar = { default = function () return {} end }
```
