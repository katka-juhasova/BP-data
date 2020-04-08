--
-- Tested with Lua 5.1.3
--

local Prototype = require 'objectlua.Prototype'

TestPrototype = {}

----
--  Testing initialization & delegatesTo
function TestPrototype:testInitializationAndDelegatesTo()
    local namedObject = Prototype:delegated()
    function namedObject:initialize(name)
        self.name = name
    end

    local person = namedObject:delegated()

    local bob = person:spawn('Bob')
    local john = person:spawn('John')

    assertEquals(bob.name, 'Bob')
    assertEquals(john.name, 'John')

    local otherJohn = john:delegated()
    assertEquals(otherJohn.name, 'John')
    assert(otherJohn:delegatesTo(Prototype))
    assert(otherJohn:delegatesTo(john))
end

----
--  Testing clone
function TestPrototype:testClone()
    local bob = Prototype:delegated()
    function bob:getName()
        return 'X'
    end

    local john = bob:clone()

    function bob:getName()
        return 'Bob'
    end

    assertEquals(bob:getName(), 'Bob')
    assertEquals(john:getName(), 'X')

end

----
--  Testing super
function TestPrototype:testSuper()
    local base = Prototype:delegated()
    function base:getName()
        return 'Base'
    end
    local derived = base:delegated()
    function derived:getName()
        return super(self)..'>>Derived'
    end

    local john = derived:spawn()
    assertEquals(john:getName(), 'Base>>Derived')
end
