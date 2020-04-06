local _M = {}
_M._VERSION = '0.1'

local mt = { __index = _M }

function _M.new( self, firstname, lastname )
    return setmetatable({
        firstname = firstname,
        lastname = lastname
    }, mt)
end

function _M.get_fullname(self)
    return self.firstname .. self.lastname
end

return _M

