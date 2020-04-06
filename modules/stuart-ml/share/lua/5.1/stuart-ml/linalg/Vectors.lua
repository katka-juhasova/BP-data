local M = {}

M.dense = function(...)
  local moses = require 'moses'
  local DenseVector = require 'stuart-ml.linalg.DenseVector'
  if moses.isTable(...) then
    return DenseVector.new(...)
  else
    return DenseVector.new({...})
  end
end

M.norm = function(vector, p)
  assert(p >= 1.0, 'To compute the p-norm of the vector, we require that you specify a p>=1. You specified ' .. p)
  local values = vector.values
  local size = #values

  if p == 1 then
    local sum = 0.0
    for i=1,size do
      sum = sum + math.abs(values[i])
    end
    return sum
  elseif p == 2 then
    local sum = 0.0
    for i=1,size do
      sum = sum + values[i] * values[i]
    end
    return math.sqrt(sum)
  elseif p == math.huge then
    local max = 0.0
    for i=1,size do
      local value = math.abs(values[i])
      if value > max then max = value end
    end
    return max
  else
    local sum = 0.0
    for i=1,size do
      sum = sum + math.pow(math.abs(values[i]), p)
    end
    return math.pow(sum, 1.0 / p)
  end
end

M.parseNumeric = function(values)
  local moses = require 'moses'
  assert(moses.isTable(values))
  if moses.all(values, function(x) return moses.isNumber(x) end) then
    return M.dense(values)
  elseif #values >= 3 and moses.isNumber(values[1]) and moses.isTable(values[2]) and moses.isTable(values[3]) then
    return M.sparse(values[1], values[2], values[3])
  else
    error('cannot parse Vector')
  end
end

M.sparse = function(size, arg2, arg3)
  local moses = require 'moses'
  local SparseVector = require 'stuart-ml.linalg.SparseVector'
  if arg3 == nil then -- arg2 is elements
    local elements = moses.sort(arg2, function(a,b)
      if moses.isTable(a) and moses.isTable(b) then return a[1] < b[1] end
    end)
    local unpack = table.unpack or unpack
    local unzip = require 'stuart-ml.util'.unzip
    local indices, values = unpack(unzip(elements))
--    var prev = -1
--    indices.foreach { i =>
--      require(prev < i, s"Found duplicate indices: $i.")
--      prev = i
--    }
--    require(prev < size, s"You may not write an element to index $prev because the declared " +
--      s"size of your vector is $size")
    return SparseVector.new(size, indices, values)
  else -- arg2 is indices, arg3 is values
    return SparseVector.new(size, arg2, arg3)
  end
end

M.sqdist = function(v1, v2)
  assert(v1:size() == v2:size(), 'Vector dimensions do not match: Dim(v1)=' .. v1:size()
    .. ' and Dim(v2)=' .. v2:size())
  local class = require 'stuart.class'
  local SparseVector = require 'stuart-ml.linalg.SparseVector'
  if class.istype(v1,SparseVector) and class.istype(v2,SparseVector) then
    return M.sqdist_sparse_sparse(v1, v2)
  end
  local DenseVector = require 'stuart-ml.linalg.DenseVector'
  if class.istype(v1,SparseVector) and class.istype(v2,DenseVector) then
    return M.sqdist_sparse_dense(v1, v2)
  elseif class.istype(v1,DenseVector) and class.istype(v2,SparseVector) then
    return M.sqdist_sparse_dense(v2, v1)
  elseif class.istype(v1,DenseVector) and class.istype(v2,DenseVector) then
    local kv = 0
    local sz = #v1
    local squaredDistance = 0.0
    while kv < sz do
      local score = v1[kv+1] - v2[kv+1]
      squaredDistance = squaredDistance + score * score
      kv = kv + 1
    end
    return squaredDistance
  end
  error('sqdist only supports DenseVector and SparseVector types')
end

M.sqdist_sparse_sparse = function(v1, v2)
  local squaredDistance = 0.0
  local v1Values = v1.values
  local v1Indices = v1.indices
  local v2Values = v2.values
  local v2Indices = v2.indices
  local nnzv1 = #v1Indices
  local nnzv2 = #v2Indices
  local kv1 = 0
  local kv2 = 0
  while kv1 < nnzv1 or kv2 < nnzv2 do
    local score = 0.0
    if kv2 >= nnzv2 or (kv1 < nnzv1 and v1Indices[kv1+1] < v2Indices[kv2+1]) then
      score = v1Values[kv1+1]
      kv1 = kv1 + 1
    elseif kv1 >= nnzv1 or (kv2 < nnzv2 and v2Indices[kv2+1] < v1Indices[kv1+1]) then
      score = v2Values[kv2+1]
      kv2 = kv2 + 1
    else
      score = v1Values[kv1+1] - v2Values[kv2+1]
      kv1 = kv1 + 1
      kv2 = kv2 + 1
    end
    squaredDistance = squaredDistance + score * score
  end
  return squaredDistance
end

M.sqdist_sparse_dense = function(v1, v2)
  local kv1 = 0
  local kv2 = 0
  local indices = v1.indices
  local squaredDistance = 0.0
  local nnzv1 = #indices
  local nnzv2 = v2:size()
  local iv1 = -1; if nnzv1 > 0 then iv1 = indices[kv1+1] end

  while kv2 < nnzv2 do
    local score = 0.0
    if kv2 ~= iv1 then
      score = v2[kv2+1]
    else
      score = v1.values[kv1+1] - v2[kv2+1]
      if kv1 < nnzv1 - 1 then
        kv1 = kv1 + 1
        iv1 = indices[kv1+1]
      end
    end
    squaredDistance = squaredDistance + score * score
    kv2 = kv2 + 1
  end
  return squaredDistance
end

M.zeros = function(size)
  local moses = require 'moses'
  local data = moses.rep(0, size)
  local DenseVector = require 'stuart-ml.linalg.DenseVector'
  return DenseVector.new(data)
end

return M
