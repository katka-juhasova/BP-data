local class = require 'stuart.class'
local Matrix = require 'stuart-ml.linalg.Matrix'

--[[
  Column-major dense matrix.
  The entry values are stored in a single array of doubles with columns listed in sequence.
  For example, the following matrix
  {{{
    1.0 2.0
    3.0 4.0
    5.0 6.0
  }}}
  is stored as `[1.0, 3.0, 5.0, 2.0, 4.0, 6.0]`.
--]]
local DenseMatrix = class.new(Matrix)

--[[
  @param numRows number of rows
  @param numCols number of columns
  @param values matrix entries in column major if not transposed or in row major otherwise
  @param isTransposed whether the matrix is transposed. If true, `values` stores the matrix in
                      row major.
--]]
function DenseMatrix:_init(numRows, numCols, values, isTransposed)
  assert(#values == numRows * numCols)
  Matrix:_init(self)
  self.numRows = numRows
  self.numCols = numCols
  self.values = values
  self.isTransposed = isTransposed or false
end

function DenseMatrix:__eq(other)
  if not class.istype(other, Matrix) then return false end
  if self.numRows ~= other.numRows or self.numCols ~= other.numCols then return false end
  for row = 0, self.numRows-1 do
    for col = 0, self.numCols-1 do
      if self.values[self:index(row,col)] ~= other.values[other:index(row,col)] then return false end
    end
  end
  return true
end

function DenseMatrix:apply(i, j)
  if j == nil then
    return self.values[i+1]
  else
    return self.values[self:index(i, j)]
  end
end

function DenseMatrix:asBreeze()
  error('NIY')
end

function DenseMatrix:clone()
  local moses = require 'moses'
  return DenseMatrix.new(self.numRows, self.numCols, moses.clone(self.values), self.isTransposed)
end

DenseMatrix.copy = DenseMatrix.clone

function DenseMatrix.eye(n)
  local identity = DenseMatrix.zeros(n, n)
  for i=0, n-1 do
    identity:update(i, i, 1.0)
  end
  return identity
end

function DenseMatrix:foreachActive(f)
  if not self.isTransposed then
    -- outer loop over columns
    for j = 0, self.numCols-1 do
      local indStart = j * self.numRows
      for i = 0, self.numRows-1 do
        f(i, j, self.values[1 + indStart + i])
      end
    end
  else
    -- outer loop over rows
    for i = 0, self.numRows-1 do
      local indStart = i * self.numCols
      for j = 0, self.numCols-1 do
        f(i, j, self.values[1 + indStart + j])
      end
    end
  end
end

DenseMatrix.get = DenseMatrix.apply

function DenseMatrix:index(i, j)
  assert(i >= 0 and i < self.numRows)
  assert(j >= 0 and j < self.numCols)
  if not self.isTransposed then
    return 1 + i + self.numRows * j
  else
    return 1 + j + self.numCols * i
  end
end

function DenseMatrix:map(f)
  local moses = require 'moses'
  return DenseMatrix.new(self.numRows, self.numCols, moses.map(self.values, f), self.isTransposed)
end

function DenseMatrix:numActives()
  return #self.values
end

function DenseMatrix:numNonzeros()
  local moses = require 'moses'
  return moses.countf(self.values, function(x) return x ~= 0 end)
end

function DenseMatrix.ones(numRows, numCols)
  local moses = require 'moses'
  return DenseMatrix.new(numRows, numCols, moses.ones(numRows*numCols))
end

--[[
  Generate a `SparseMatrix` from the given `DenseMatrix`. The new matrix will have isTransposed
  set to false.
--]]
function DenseMatrix:toSparse()
  local spVals = {}
  local moses = require 'moses'
  local colPtrs = moses.ones(self.numCols+1)
  local rowIndices = {}
  local nnz = 1
  for j = 0, self.numCols-1 do
    for i = 0, self.numRows-1 do
      local v = self.values[self:index(i,j)]
      if v ~= 0.0 then
        rowIndices[#rowIndices+1] = i
        spVals[#spVals+1] = v
        nnz = nnz + 1
      end
    end
    colPtrs[j+2] = nnz
  end
  local SparseMatrix = require 'stuart-ml.linalg.SparseMatrix'
  return SparseMatrix.new(self.numRows, self.numCols, colPtrs, rowIndices, spVals)
end

function DenseMatrix:transpose()
  return DenseMatrix.new(self.numCols, self.numRows, self.values, not self.isTransposed)
end

function DenseMatrix:update(...)
  local moses = require 'moses'
  local nargs = #moses.pack(...)
  if nargs == 1 then
    return self:updatef(...)
  else
    return self:update3(...)
  end
end

function DenseMatrix:updatef(f)
  for i=1,#self.values do
    self.values[i] = f(self.values[i])
  end
  return self
end

function DenseMatrix:update3(i, j, v)
  self.values[self:index(i, j)] = v
end

function DenseMatrix.zeros(numRows, numCols)
  local moses = require 'moses'
  return DenseMatrix.new(numRows, numCols, moses.zeros(numRows*numCols))
end

return DenseMatrix
