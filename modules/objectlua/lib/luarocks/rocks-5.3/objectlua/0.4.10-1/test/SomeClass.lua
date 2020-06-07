local Object = require 'objectlua.Object'

local SomeClass = Object:subclass(...)

function SomeClass:itWorks()
    return true
end

return SomeClass
