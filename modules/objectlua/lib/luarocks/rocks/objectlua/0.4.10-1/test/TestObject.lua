--
--  Tested with Lua 5.1.3 & Lua 5.1.4
--

local Object = require 'objectlua.Object'
local Class  = require 'objectlua.Class'

TestObject = {}

function TestObject:tearDown()
    Class:reset()
    package.loaded['SomeClass'] = nil
end


----
--  Inheritance & Initialization
function TestObject:testInheritanceAndInitialization()
    local Toto = Object:subclass()

    function Toto:initialize(name)
        self.name = name
    end

    local toto = Toto:new('John')
    local otherToto = Toto:new('Bob')

    assertEquals(Toto, toto.class)
    assertEquals(Object, Toto.superclass)
    assertEquals(Object.class, Toto.class.superclass)
    assertEquals(nil, toto.new)
    assertEquals(toto.name, 'John')
    assertEquals(otherToto.name, 'Bob')
end

----
--  Testing subclassing
function TestObject:testSubclassing()
   local Toto = Object:subclass()

   function Toto:initialize(name)
      self.name = name
   end

   local john = Toto:new('John')
   local bob = Toto:new('Bob')

   assertEquals(john.name, 'John')
   assertEquals(bob.name, 'Bob')
end

----
--  Calling super
function TestObject:testSuper()
    local Toto = Object:subclass()
    function Toto:initialize(name)
        self.name = name
    end

    local Tata = Toto:subclass()
    function Tata:initialize(name)
       super(self, name)
    end

    local tata = Tata:new('Bob')
    assertEquals(tata.name, 'Bob')
end

----
--  Calling super through two levels of inheritance.
--  This one can cause a stackoverflow with a too simple super() implementation.
function TestObject:testSuperThroughTwoLevels()
    local Toto = Object:subclass()
    function Toto:initialize(name)
        self.name = name
    end

    local Tata = Toto:subclass()
    function Tata:initialize(name)
        super(self, name)
    end

    local Titi = Tata:subclass()
    function Titi:initialize(name)
        super(self, name)
    end

    local titi = Titi:new('Paul')
    assertEquals(titi.name, 'Paul')
end

----
--  Virtual calls
function TestObject:testVirtualCall()
    local Base = Object:subclass()

    function Base:initialize()
        self.type = self:getType()
    end

    function Base:getType()
        return 'base'
    end

    --
    local Derived = Base:subclass()

    function Derived:getType()
        return 'derived'
    end

    local derived = Derived:new()
    assertEquals(derived.type, 'derived')
end

----
--  Super jump
function TestObject:testSuperJump()
    local Level0 = Object:subclass()
    function Level0:getNumber()
        return 10
    end

    local Level1 = Level0:subclass()

    local Level2 = Level1:subclass()
    -- Calling super(self) in getNumber() on a Level2 object skips Level1
    -- (since it's not overriden here) and calls Level0:getNumber()
    function Level2:getNumber()
        return super(self) + 1
    end

    local level2 = Level2:new()
    assertEquals(level2:getNumber(), 11)
end

----
--  Super virtual calls through two levels...
function TestObject:testVirtualSuperThroughTwoLevels()
    local Level0 = Object:subclass()
    function Level0:initialize()
        self.type = self:getType()
    end
    function Level0:getType()
        return 'level0'
    end
    assertEquals(Level0:new().type, 'level0')

    local Level1 = Level0:subclass()
    function Level1:initialize()
        super(self)
    end
    function Level1:getType()
        return 'level1'
    end
    assertEquals(Level1:new().type, 'level1')

    local Level2 = Level1:subclass()
    function Level2:initialize()
        super(self)
    end
    function Level2:getType()
        return 'level2'
    end
    assertEquals(Level2:new().type, 'level2')
end

----
--  Calling initialize with two arguments through super
--  Passes since version 0.0.3
function TestObject:testInitializeWithTwoArguments()
    local Toto = Object:subclass()

    function Toto:initialize(name, color)
        self.name = name
        self.color = color
    end

    local toto = Toto:new('Bob', 'red')
    assertEquals(toto.name, 'Bob')
    assertEquals(toto.color, 'red')

    local Tata = Toto:subclass()
    function Tata:initialize(name, color)
        super(self, name, color)
    end
    local tata = Tata:new('John', 'blue')
    assertEquals(tata.name, 'John')
    assertEquals(tata.color, 'blue')
end

----
--  Testing class methods
function TestObject:testClassMethods()
   local Foo = Object:subclass()
   function Foo.class:sayHello()
      return 'Hello'
   end
   assertEquals(Foo:sayHello(), 'Hello')
end

----
--  Testing super on class methods
function TestObject:testSuperInClassMethods()
    local Level1 = Object:subclass()
    function Level1.class:getName()
        return 'Level1'
    end
    assert('Level1' == Level1:getName())

    local Level2 = Level1:subclass()
    function Level2.class:getName()
        return super(self)..'-Level2'
    end

    assertEquals(Level2:getName(), 'Level1-Level2')
end

----
--  Testing isKindOf
function TestObject:testIsKindOf()
    local Level1 = Object:subclass()
    local Level2 = Level1:subclass()
    local object = Object:new()
    local level2 = Level2:new()

    assert(not object:isKindOf())
    assert(object:isKindOf(Object))
    assert(not object:isKindOf(Level1))
    assert(level2:isKindOf(Object))
    assert(level2:isKindOf(Level1))
    assert(level2:isKindOf(Level2))
    assert(not object:isKindOf(Class))

    assert(not Level2:isKindOf(Level2))
end

----
--  Testing inheritsFrom
function TestObject:testInheritsFrom()
    local Level1 = Object:subclass()
    local Level2 = Level1:subclass()

    assert(Level1:inheritsFrom(Object))
    assert(Level2:inheritsFrom(Object))
    assert(Level2:inheritsFrom(Level1))
    assert(not Level2:inheritsFrom(Level2))
end

----
--  Validating object model
function TestObject:testObjectModel()
    assertEquals(Object.class.class, Class)
    assertEquals(Class.class.class, Class)
    assertEquals(Object:subclass().class.class, Class)
    assert(Object:isKindOf(Object))
    assert(Object:isKindOf(Class))
    assert(Class:isKindOf(Object))
    assert(Class:isKindOf(Class))

    assert(not Object:inheritsFrom(Class))
    assert(Class:inheritsFrom(Object))
    assert(not Object:inheritsFrom(Object))
end

----
--  Testing clone
function TestObject:testClone()
    local Level1 = Object:subclass()
    local level1 = Level1:new()
    level1.value = 5
    level1.values = {6, 7}
    local clone = level1:clone()

    assert(clone:isKindOf(level1.class))
    assert(clone.value == level1.value)
    assert(clone.values == level1.values)
end

----
--  Private metatables (get)
function TestObject:testPrivateMetatable()
    local Level1 = Object:subclass()
    local level1 = Level1:new()

    assertEquals(getmetatable(Level1), 'private')
    assertEquals(getmetatable(level1), 'private')
end

----
--  Private metatables (set)
function TestObject:testSetMetatableFails()
    local Titi = Object:subclass()
    local titi = Titi:new()
    assertError(setmetatable, titi, {})
end

----
--  Adding methods to an instance
function TestObject:testAddingMethodToInstance()
    local john = Object:new()
    function john:itWorks()
        return true
    end
    assert(john:itWorks())
end

----
--  Testing redefining new()
function TestObject:testRedefiningNew()
    local OtherNew = Object:subclass()

    function OtherNew.class:new()
       local instance = super(self)
       instance.fromOtherNew = true
       return instance
    end

    local Foo = OtherNew:subclass()
    assert(Foo:isKindOf(Class))
    local foo = Foo:new()
    assert(foo.fromOtherNew)
end

----
--  Testing exception in super(self)
--  Passes since 0.3.2
function TestObject:testExceptionInSuper()
    local Base = Object:subclass()
    function Base:getString(name)
        assert('string' == type(name))
        return 'Base:'..name
    end

    local Derived = Base:subclass()
    function Derived:getString()
        pcall(super, self) -- throws & recovers immediately
        return super(self, 'John')
    end

    local derived = Derived:new()
    assertEquals(derived:getString(), 'Base:John')
end

----
--  Testing super(self) in tail call
function TestObject:testSuperTailCall()
    local Base = Object:subclass()
    function Base:getAnyString()
        return 'Coco'
    end

    local Derived = Base:subclass()
    function Derived:getAnyString()
        return super(self)
    end

    local derived = Derived:new()
    assertEquals(derived:getAnyString(), 'Coco')
end

----
--  Testing isMeta()
function TestObject:testIsMeta()
   assert(not Object:isMeta())
   assert(not Class:isMeta())
   assert(Object.class:isMeta())
   assert(Class.class:isMeta())
   local Toto = Object:subclass()
   assert(not Toto:isMeta())
   assert(Toto.class:isMeta())
end

----
--  Multiple return values
function TestObject:testMultipleReturnValues()
    local Toto = Object:subclass()
    function Toto:returnTwoValues()
        return 1, 2
    end

    local toto = Toto:new()
    a, b = toto:returnTwoValues()
    assertEquals(a, 1)
    assertEquals(b, 2)
end

----
--
function TestObject:testCallingNonExistingMethodFails()
    local Titi = Object:subclass()
    local titi = Titi:new()
    assertError(titi.aNonExistingMethod, titi)
end

----
--  Reading outside data
function TestObject:testReadOutsideData()
    local toto = 1
    local Foo = Object:subclass()
    function Foo:readToto()
        assertEquals(toto, 1)
    end

    local foo = Foo:new()
    foo:readToto()
end

----
--  Creating global data
function TestObject:testCreateGlobalData()
    local Foo = Object:subclass()
    function Foo:createToto()
        toto = 2
    end

    local foo = Foo:new()
    foo:createToto()
    assertEquals(toto, 2)
end

----
--  Testing named subclass in tail call
function TestObject:testNamedSubclassInTailCall()
    return Object:subclass 'NamedClass'
end

----
--  Testing named classes
function TestObject:testClassName()
    local NamedClass = Object:subclass 'NamedClass'
    assertEquals(NamedClass:name(), 'NamedClass')
end

----
--  Testing scope
function TestObject:testNamedAndAnonymClassScope()
    (function()
         local NamedClass = Object:subclass 'NamedClass'
         local AnonymClass = Object:subclass()
     end)()

    assertEquals(NamedClass, nil)
    assertEquals(AnonymClass, nil)

    assert(nil ~= Class:find 'NamedClass')
    assertEquals(Class:find 'AnonymClass', nil)
end

----
--  Testing all Classes and class scope
function TestObject:testAllClasses()
    (function()
         Object:subclass 'NamedClass'
     end)()

    local classes = Class:all()

    assertEquals(classes['objectlua.Object']:name(), 'objectlua.Object')
    assertEquals(classes['objectlua.Object Metaclass']:name(), 'objectlua.Object Metaclass')

    assertEquals(classes['objectlua.Class']:name(), 'objectlua.Class')
    assertEquals(classes['objectlua.Class Metaclass']:name(), 'objectlua.Class Metaclass')

    assertEquals(classes['NamedClass']:name(), 'NamedClass')
    assertEquals(classes['NamedClass Metaclass']:name(), 'NamedClass Metaclass')
end

----
--  Testing requiring a class file
function TestObject:testLoadAClassFromFile()
    local SomeClass = require 'SomeClass'

    local someObject = SomeClass:new()
    assertEquals(someObject:className(), 'SomeClass')
    assert(someObject:itWorks())
end

function TestObject:testClassShadowedFails1()
    Object:subclass 'SomeClass'
    assertError(require, 'SomeClass')
end

function TestObject:testClassShadowedFails2()
    require 'SomeClass'
    assertError(function()
                    Object:subclass 'SomeClass'
                end)
end
