require 'luaunit'

require 'TestObject'
require 'TestObjectImplementation'
require 'TestPrototype'
--require 'objectlua.Tests.TestTraits'

local result = LuaUnit:run()
if 0 ~= result then
    os.exit(1)
end

