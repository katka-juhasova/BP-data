Lua object model
================

Simple object model implementation in Lua.

Inspired by [http://lua-users.org/wiki/SimpleLuaClasses](http://lua-users.org/wiki/SimpleLuaClasses)


## Features

- classes
- constructors
- destructors
- inheritance
- instanceof
- parent method calls


## Requirements

- Lua 5.1 or newer


## Installation

Using LuaRocks:

    luarocks install object-model


## Module method overview

- `class([parentClass]): table`
    - create a new class, optionally inheriting methods and properties of another one
- `instanceof(object, class): boolean`
    - check if the given object is an instance of the given class or has that class as
      one of its parents
- `new(class, ...): object`
    - create an instance of the given class and invoke its constructor
    - any additional arguments will be passed to the constructor
    - should not be used directly, invoke the class table instead (refer to the *Instantiating a class* section)
- `super(object, methodName, ...): mixed`
    - invokes a parent method
    - this is the default implementation of `object:super(method, ...)`


## Feature documentation

Let's assume you have imported the `ObjectModel` module like this:

    local o = require 'ObjectModel'


### Creating a new class

The `class` function returns a new table that you can populate with your methods
and properties.

    MyClass = o.class()


### Inheritance

If another class is passed  to the `class()` function, all of its methods
and properties are inherited.

    MyClass = o.class(OtherClass)

Internally, a shallow copy of the parent class is created for performance reasons.
Modifications of the parent class at a later point will NOT be propagated to the child
classes.


### Prototype properties

Prototype properties can be defined in the class table. They are available in all
instances of the class and can be accessed statically. Instance properties will shadow
prototype properties with the same name.

    MyClass.foo = 'bar'

**Warning!** Do not put tables into prototype properties unless you want the table
to be shared across all the instances (see instance properties).


### Methods

Lua provides syntactic sugar for this purpose.

    function MyClass:doSomething()
        -- do something, self points to the instance
		print(self.someProperty) -- getting properties
		print(self:someMethod()) -- calling other methods
	end

Same as prototype properties, methods defined this way are available in all instances
of the class and can be called statically.


### Constructors

Constructor is a special method that is invoked when a class is being instantiated.

    function MyClass:constructor(lorem, ipsum)
        -- self points to the instance
    end


### Destructors

Destructor is a special method that is invoked when an instance is being garbage-collected
by Lua.

    function MyClass:destructor()
        -- self points to the instance
        -- no arguments are passed
	end


### Instantiating a class

To create an instance of a class, simply call the class table as a function.

    local obj = MyClass('something')

All arguments passed to this function are forwarded to the constructor.


### Instance properties

Properties defined on an object are privately owned by that object. They will shadow prototype
properties with the same name.

    MyClass.test = 'hello from prototype'

    local obj = MyClass()

	print(obj.test) -- prints: hello from prototype
	obj.test = 'hello from instance'
	print(obj.test) -- prints: hello from instance
	obj.test = nil
	print(obj.test) -- prints: hello from prototype


### Instanceof

To check whether an object is instance of a specific class or has that class as one of its parents,
use the `instanceof()` function.

    local obj = MyClass()

    if o.instanceof(obj, MyClass) then
        print('obj is instance of MyClass')
    end


### Calling parent methods

If a class has inherited from another and overridden some of its methods, these methods can be
invoked using the `:super(methodName, ...)` method.

    BaseClass = o.class()

    function BaseClass:constructor(foo)
        self.foo = foo
    end

    DerivedClass = o.class(BaseClass)

    function DerivedClass:constructor(foo, bar)
        self:super('constructor', foo) -- invoke the parent constructor
        self.bar = bar
    end

    local obj = DerivedClass('hello', 'world')

    print(obj.foo, obj.bar) -- prints: hello world


### Metamethods

Metamethods can be defined the same way as any other methods and will work as expected.

    function MyClass:__tostring()
        return 'stringified!'
    end

    local obj = MyClass()

    print(obj) -- prints: stringified!
