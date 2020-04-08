local class = require 'stuart.class'

local Vector = class.new()

function Vector:_init(values)
  self.values = values or {}
end

function Vector:numActives()
  return #self.values
end

function Vector:numNonzeros()
  local moses = require 'moses'
  local nnz = moses.reduce(self.values, function(r,v)
    if v ~= 0 then r = r + 1 end
    return r
  end, 0)
  return nnz
end

return Vector
