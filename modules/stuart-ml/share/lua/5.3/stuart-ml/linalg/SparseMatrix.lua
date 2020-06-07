local class = require 'stuart.class'
local Matrix = require 'stuart-ml.linalg.Matrix'

--[[
  Column-major sparse matrix.
  The entry values are stored in Compressed Sparse Column (CSC) format.
  For example, the following matrix
  {{{
    1.0 0.0 4.0
    0.0 3.0 5.0
    2.0 0.0 6.0
  }}}
  is stored as `values: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]`,
  `rowIndices=[0, 2, 1, 0, 1, 2]`, `colPointers=[0, 2, 3, 6]`.
--]]
local SparseMatrix = class.new(Matrix)

--[[
  @param numRows number of rows
  @param numCols number of columns
  @param colPtrs the 1-based index corresponding to the start of a new column (if not transposed)
  @param rowIndices the row index of the entry (if not transposed). They must be in strictly
                    increasing order for each column
  @param values nonzero matrix entries in column major (if not transposed)
  @param isTransposed whether the matrix is transposed. If true, the matrix can be considered
                      Compressed Sparse Row (CSR) format, where `colPtrs` behaves as rowPtrs,
                      and `rowIndices` behave as colIndices, and `values` are stored in row major.
--]]
function SparseMatrix:_init(numRows, numCols, colPtrs, rowIndices, values, isTransposed)
  assert(#values == #rowIndices) -- The number of row indices and values don't match
  if isTransposed then
    assert(#colPtrs == numRows+1)
  else
    assert(#colPtrs == numCols+1)
  end
  assert(#values+1 == colPtrs[#colPtrs]) -- The last value of colPtrs must be one past the number of elements
  Matrix._init(self)
  self.numRows = numRows
  self.numCols = numCols
  self.colPtrs = colPtrs
  self.rowIndices = rowIndices
  self.values = values
  self.isTransposed = isTransposed or false
end

function SparseMatrix:__eq(other)
  local moses = require 'moses'
  return self.numRows == other.numRows
    and self.numCols == other.numCols
    and moses.same(self.colPtrs, other.colPtrs)
    and moses.same(self.rowIndices, other.rowIndices)
    and moses.same(self.values, other.values)
    and self.isTransposed == other.isTransposed
end

function SparseMatrix:apply(i, j)
  local ind = self:index(i, j)
  if ind < 1 then return 0.0 else return self.values[ind] end
end

function SparseMatrix:asBreeze()
  error('NIY')
end

function SparseMatrix:asML()
  error('NIY')
end

function SparseMatrix:colIter()
  error('NIY')
end

function SparseMatrix:clone()
  local moses = require 'moses'
  return SparseMatrix.new(self.numRows, self.numCols, self.colPtrs, self.rowIndices, moses.clone(self.values))
end

SparseMatrix.copy = SparseMatrix.clone

function SparseMatrix:foreachActive(f)
  if not self.isTransposed then
    for j = 0, self.numCols-1 do
      local idxBegin = self.colPtrs[j+1]
      local idxEnd = self.colPtrs[j+2]
      for idx = idxBegin, idxEnd-1 do
        local i = self.rowIndices[idx]
        f(i, j, self.values[idx])
      end
    end
  else
    for i = 0, self.numRows-1 do
      local idxBegin = self.colPtrs[i+1]
      local idxEnd = self.colPtrs[i+2]
      for idx = idxBegin, idxEnd-1 do
        local j = self.rowIndices[idx]
        f(i, j, self.values[idx])
      end
    end
  end
end

--[[
  Generate a `SparseMatrix` from Coordinate List (COO) format. Input must be an array of
  (i, j, value) tuples. Entries that have duplicate values of i and j are
  added together. Tuples where value is equal to zero will be omitted.
  @param numRows number of rows of the matrix
  @param numCols number of columns of the matrix
  @param entries Array of (i, j, value) tuples
  @return The corresponding `SparseMatrix`
--]]
function SparseMatrix.fromCOO()
  error('NIY')
end

--[[
  Convert new linalg type to spark.mllib type.  Light copy; only copies references
--]]
function SparseMatrix.fromML()
  error('NIY')
end

--[[
  Generates the skeleton of a random `SparseMatrix` with a given random number generator.
  The values of the matrix returned are undefined.
--]]
function SparseMatrix.genRandMatrix()
  error('NIY')
end

SparseMatrix.get = SparseMatrix.apply

function SparseMatrix:index(i, j)
  assert(i >= 0 and i < self.numRows)
  assert(j >= 0 and j < self.numCols)
  local arrays = require 'stuart-ml.util.java.arrays'
  if not self.isTransposed then
    return arrays.binarySearch(self.rowIndices, self.colPtrs[j+1], self.colPtrs[j+2], i)
  else
    return arrays.binarySearch(self.rowIndices, self.colPtrs[i+1], self.colPtrs[i+2], j)
  end
end

function SparseMatrix:map(f)
  local moses = require 'moses'
  return SparseMatrix.new(self.numRows, self.numCols, self.colPtrs, self.rowIndices, moses.map(self.values, f), self.isTransposed)
end

function SparseMatrix:numActives()
  return #self.values
end

function SparseMatrix:numNonzeros()
  local moses = require 'moses'
  return moses.countf(self.values, function(x) return x ~= 0 end)
end

--[[
  Generate a diagonal matrix in `SparseMatrix` format from the supplied values.
  @param vector a `Vector` that will form the values on the diagonal of the matrix
  @return Square `SparseMatrix` with size `values.length` x `values.length` and non-zero
          `values` on the diagonal
--]]
function SparseMatrix.spdiag()
  error('NIY')
end

--[[
  Generate an Identity Matrix in `SparseMatrix` format.
  @param n number of rows and columns of the matrix
  @return `SparseMatrix` with size `n` x `n` and values of ones on the diagonal
--]]
function SparseMatrix.speye()
  error('NIY')
end

--[[
  Generate a `SparseMatrix` consisting of `i.i.d`. uniform random numbers. The number of non-zero
  elements equal the ceiling of `numRows` x `numCols` x `density`

  @param numRows number of rows of the matrix
  @param numCols number of columns of the matrix
  @param density the desired density for the matrix
  @param rng a random number generator
  @return `SparseMatrix` with size `numRows` x `numCols` and values in U(0, 1)
--]]
function SparseMatrix.sprand()
  error('NIY')
end

--[[
  Generate a `SparseMatrix` consisting of `i.i.d`. gaussian random numbers.
  @param numRows number of rows of the matrix
  @param numCols number of columns of the matrix
  @param density the desired density for the matrix
  @param rng a random number generator
  @return `SparseMatrix` with size `numRows` x `numCols` and values in N(0, 1)
--]]
function SparseMatrix.sprandn()
  error('NIY')
end

--[[
  Generate a `DenseMatrix` from the given `SparseMatrix`. The new matrix will have isTransposed
  set to false.
--]]
function SparseMatrix:toDense()
  local DenseMatrix = require 'stuart-ml.linalg.DenseMatrix'
  return DenseMatrix.new(self.numRows, self.numCols, self:toArray())
end

function SparseMatrix:toSparse()
  return self
end

function SparseMatrix:transpose()
  return SparseMatrix.new(self.numCols, self.numRows, self.colPtrs, self.rowIndices, self.values, not self.isTransposed)
end

function SparseMatrix:update(...)
  local moses = require 'moses'
  local nargs = #moses.pack(...)
  if nargs == 1 then
    return self:updatef(...)
  else
    return self:update3(...)
  end
end

function SparseMatrix:updatef(f)
  for i=1,#self.values do
    self.values[i] = f(self.values[i])
  end
  return self
end

function SparseMatrix:update3(i, j, v)
  local ind = self:index(i, j)
  assert(ind >= 1)
  self.values[ind] = v
end

return SparseMatrix
