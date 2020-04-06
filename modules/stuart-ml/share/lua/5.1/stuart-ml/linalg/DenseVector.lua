local class = require 'stuart.class'
local Vector = require 'stuart-ml.linalg.Vector'

local DenseVector = class.new(Vector)

function DenseVector:_init(values)
  Vector._init(self, values)
end

function DenseVector.__eq(a, b)
  if a:size() ~= b:size() then return false end
  local moses = require 'moses'
  return moses.same(a.values, b.values)
end

function DenseVector:__index(key)
  if type(key) ~= 'number' then return rawget(getmetatable(self), key) end
  return self.values[key]
end

function DenseVector:__tostring()
  return '(' .. table.concat(self.values,',') .. ')'
end

function DenseVector:argmax()
  if self:size() == 0 then
    return -1
  else
    local maxIdx = -1
    local maxValue = self.values[1]
    for i, value in ipairs(self.values) do
      if value > maxValue then
        maxIdx = i
        maxValue = value
      end
    end
    return maxIdx
  end
end

function DenseVector:clone()
  local moses = require 'moses'
  return DenseVector.new(moses.clone(self.values))
end

DenseVector.copy = DenseVector.clone

function DenseVector:foreachActive(f)
  for i,value in ipairs(self.values) do
    f(i-1, value)
  end
end

function DenseVector:size()
  return #self.values
end

function DenseVector:toArray()
  return self.values
end

function DenseVector:toDense()
  return self
end

function DenseVector:toSparse()
  local ii = {}
  local vv = {}
  self:foreachActive(function(i,v)
    if v ~= 0 then
      ii[#ii+1] = i
      vv[#vv+1] = v
    end
  end)
  local SparseVector = require 'stuart-ml.linalg.SparseVector'
  return SparseVector.new(self:size(), ii, vv)
end

return DenseVector
