local Object = require 'objectlua.Object'
local Class  = require 'objectlua.Class'

TestObjectImplementation = {}

function TestObjectImplementation:testObjectModel()
    assertEquals(debug.getmetatable(Class), Class.class.__prototype__)
    assertEquals(debug.getmetatable(Class.class.__prototype__), Object.class.__prototype__)
    assertEquals(debug.getmetatable(Object.class), Class.__prototype__)
    assertEquals(debug.getmetatable(Class.__prototype__), Object.__prototype__)
end

function TestObjectImplementation:testClassMethods()
   local Foo = Object:subclass()
   function Foo.class:sayHello()
      return 'Hello'
   end

   assertEquals(nil, Foo.class.sayHello)
   assertEquals('function', type(Foo.class.__prototype__.sayHello))
   assertEquals('Hello',Foo:sayHello())
end

function TestObjectImplementation:testFenv()
    local function notFenved()
        assert(toto ~= 1)
    end

    local function fenved()
        notFenved()
        return toto
    end

    setfenv(fenved, setmetatable({toto = 1}, {__index = _G}))
    assertEquals(fenved(), 1)
end
