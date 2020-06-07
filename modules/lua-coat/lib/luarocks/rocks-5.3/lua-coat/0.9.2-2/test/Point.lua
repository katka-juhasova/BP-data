
require 'Coat'

class 'Point'

has.x = { is = 'rw', isa = 'number', default = 0 }
has.y = { is = 'rw', isa = 'number', default = 0 }

function overload:__tostring ()
    return '(' .. tostring(self.x) .. ', ' .. tostring(self.y) .. ')'
end

function method:draw ()
    return "drawing " .. self._CLASS .. tostring(self)
end
