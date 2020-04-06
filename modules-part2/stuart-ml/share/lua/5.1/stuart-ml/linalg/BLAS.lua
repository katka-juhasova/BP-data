local M = {}

--[[ y += a * x
@param a number
@param vectorX Vector
@param vectorY Vector
--]]
M.axpy = function(a, vectorX, vectorY)
  local class = require 'stuart.class'
  local Vector = require 'stuart-ml.linalg.Vector'
  assert(class.istype(vectorX, Vector))
  assert(class.istype(vectorY, Vector))
  assert(vectorX:size() == vectorY:size())
  local DenseVector = require 'stuart-ml.linalg.DenseVector'
  if class.istype(vectorY,DenseVector) then
    local SparseVector = require 'stuart-ml.linalg.SparseVector'
    if class.istype(vectorX,SparseVector) then
      return M.axpy_sparse_dense(a,vectorX,vectorY)
    elseif class.istype(vectorX,DenseVector) then
      return M.axpy_sparse_dense(a,vectorX:toSparse(),vectorY)
    else
      error('axpy only supports DenseVector and SparseVector types for vectorX 2nd arg')
    end
  end
  error('axpy only supports adding to a DenseVector')
end

M.axpy_sparse_dense = function(a, x, y)
  local nnz = #x.indices
  if a == 1.0 then
    for k=1,nnz do
      y.values[x.indices[k]+1] = y.values[x.indices[k]+1] + x.values[k]
    end
  else
    for k=1,nnz do
      y.values[x.indices[k]+1] = y.values[x.indices[k]+1] + a * x.values[k]
    end
  end
end

M.dot = function(x, y)
  assert(x:size() == y:size())
  local class = require 'stuart.class'
  local istype = class.istype
  local DenseVector = require 'stuart-ml.linalg.DenseVector'
  if istype(x,DenseVector) and istype(y,DenseVector) then
    return M.dot_sparse_dense(x:toSparse(), y)
  end
  local SparseVector = require 'stuart-ml.linalg.SparseVector'
  if istype(x,SparseVector) and istype(y,DenseVector) then
      return M.dot_sparse_dense(x, y)
  elseif istype(x,DenseVector) and istype(y,SparseVector) then
      return M.dot_sparse_dense(y, x)
  elseif istype(x,SparseVector) and istype(y,SparseVector) then
      return M.dot_sparse_sparse(x, y)
  else
    error('dot only supports DenseVector and SparseVector types')
  end
end

M.dot_sparse_dense = function(x, y)
  local nnz = #x.indices
  local sum = 0.0
  for k=1,nnz do
    sum = sum + x.values[k] * y.values[x.indices[k]+1]
  end
  return sum
end

M.dot_sparse_sparse = function(x, y)
  local nnzx = #x.indices
  local nnzy = #y.indices
  local kx = 0
  local ky = 0
  local sum = 0.0
  while kx < nnzx and ky < nnzy do
    local ix = x.indices[kx+1]
    while ky < nnzy and y.indices[ky+1] < ix do
      ky = ky + 1
    end
    if ky < nnzy and y.indices[ky+1] == ix then
      sum = sum + x.values[kx+1] * y.values[ky+1]
      ky = ky + 1
    end
    kx = kx + 1
  end
  return sum
end

--[[ x = a * x
--]]
M.scal = function(a, x)
  for i=1,#x.values do
    x.values[i] = a * x.values[i]
  end
end

--[[ Adds alpha * v * v.t to a matrix in-place. This is the same as BLAS's ?SPR.
--]]
M.spr = function(alpha, v, U)
  local class = require 'stuart.class'
  local Vector = require 'stuart-ml.linalg.Vector'
  if class.istype(U, Vector) then U = U.values end
  
  local DenseVector = require 'stuart-ml.linalg.DenseVector'
  if class.istype(v, DenseVector) then
    v = v:toSparse()
  end
  
  local SparseVector = require 'stuart-ml.linalg.SparseVector'
  if class.istype(v, SparseVector) then
    local colStartIdx, prevCol = 0, 0
    local nnz = #v.indices
    for j = 1, nnz do
      local col = v.indices[j]
      --  Skip empty columns
      colStartIdx = colStartIdx + (col - prevCol) * (col + prevCol + 1) / 2
      local av = alpha * v.values[j]
      for i = 1, j do
        U[colStartIdx + v.indices[i] + 1] = U[colStartIdx + v.indices[i] + 1] + av * v.values[i]
      end
      prevCol = col
    end
    return
  end
  
  error('Unsupported vector type')
end

return M
