--[[
  Factory methods for stuart-ml.linalg.Matrix.
--]]
local M = {}

--[[
  Creates a column-major dense matrix.
 
  @param numRows number of rows
  @param numCols number of columns
  @param values matrix entries in column major
--]]
M.dense = function(numRows, numCols, values)
  local DenseMatrix = require 'stuart-ml.linalg.DenseMatrix'
  return DenseMatrix.new(numRows, numCols, values)
end

--[[
  Generate a diagonal matrix in `Matrix` format from the supplied values.
  @param vector a `Vector` that will form the values on the diagonal of the matrix
  @return Square `Matrix` with size `values.length` x `values.length` and `values`
          on the diagonal
--]]
M.diag = function(vector)
  local n = vector:size()
  local DenseMatrix = require 'stuart-ml.linalg.DenseMatrix'
  local matrix = DenseMatrix.zeros(n, n)
  local values = vector:toArray()
  for i=0, n-1 do
    matrix:update(i, i, values[i+1])
  end
  return matrix
end

--[[
  Generate a dense Identity Matrix in `Matrix` format.
  @param n number of rows and columns of the matrix
  @return `Matrix` with size `n` x `n` and values of ones on the diagonal
--]]
M.eye = function(n)
  local DenseMatrix = require 'stuart-ml.linalg.DenseMatrix'
  return DenseMatrix.eye(n)
end

--[[
  Creates a Matrix instance from a breeze matrix.
  @param breeze a breeze matrix
  @return a Matrix instance
--]]
M.fromBreeze = function()
  error('NIY')
end

--[[
  Convert new linalg type to spark.mllib type.  Light copy; only copies references
--]]
M.fromML = function()
  error('NIY')
end

--[[
  Horizontally concatenate a sequence of matrices. The returned matrix will be in the format
  the matrices are supplied in. Supplying a mix of dense and sparse matrices will result in
  a sparse matrix. If the Array is empty, an empty `DenseMatrix` will be returned.
  @param matrices array of matrices
  @return a single `Matrix` composed of the matrices that were horizontally concatenated
--]]
M.horzcat = function()
  error('NIY')
end

--[[
  Generate a `DenseMatrix` consisting of ones.
  @param numRows number of rows of the matrix
  @param numCols number of columns of the matrix
  @return `Matrix` with size `numRows` x `numCols` and values of ones
--]]
M.ones = function(numRows, numCols)
  local DenseMatrix = require 'stuart-ml.linalg.DenseMatrix'
  return DenseMatrix.ones(numRows, numCols)
end

--[[
  Generate a `DenseMatrix` consisting of `i.i.d.` uniform random numbers.
  @param numRows number of rows of the matrix
  @param numCols number of columns of the matrix
  @return `Matrix` with size `numRows` x `numCols` and values in U(0, 1)
--]]
M.rand = function(numRows, numCols)
  local moses = require 'moses'
  local DenseMatrix = require 'stuart-ml.linalg.DenseMatrix'
  local data = moses.map(moses.zeros(numRows * numCols), function() return math.random() end)
  return DenseMatrix.new(numRows, numCols, data)
end

--[[
  Generate a `DenseMatrix` consisting of `i.i.d.` gaussian random numbers.
  @param numRows number of rows of the matrix
  @param numCols number of columns of the matrix
  @param rng a random number generator
  @return `Matrix` with size `numRows` x `numCols` and values in N(0, 1)
--]]
M.randn = function()
  error('NIY')
end

--[[
  Creates a column-major sparse matrix in Compressed Sparse Column (CSC) format.
   
  @param numRows number of rows
  @param numCols number of columns
  @param colPtrs the index corresponding to the start of a new column
  @param rowIndices the row index of the entry
  @param values non-zero matrix entries in column major
--]]
M.sparse = function (numRows, numCols, colPtrs, rowIndices, values)
  local SparseMatrix = require 'stuart-ml.linalg.SparseMatrix'
  return SparseMatrix.new(numRows, numCols, colPtrs, rowIndices, values)
end

--[[
  Generate a sparse Identity Matrix in `Matrix` format.
  @param n number of rows and columns of the matrix
  @return `Matrix` with size `n` x `n` and values of ones on the diagonal
--]]
M.speye = function(n)
  local SparseMatrix = require 'stuart-ml.linalg.SparseMatrix'
  return SparseMatrix.speye(n)
end

--[[
  Generate a `SparseMatrix` consisting of `i.i.d.` gaussian random numbers.
  @param numRows number of rows of the matrix
  @param numCols number of columns of the matrix
  @param density the desired density for the matrix
  @param rng a random number generator
  @return `Matrix` with size `numRows` x `numCols` and values in U(0, 1)
--]]
M.sprand = function()
  error('NIY')
end

--[[
  Vertically concatenate a sequence of matrices. The returned matrix will be in the format
  the matrices are supplied in. Supplying a mix of dense and sparse matrices will result in
  a sparse matrix. If the Array is empty, an empty `DenseMatrix` will be returned.
  @param matrices array of matrices
  @return a single `Matrix` composed of the matrices that were vertically concatenated
--]]
M.vertcat = function()
  error('NIY')
end

--[[
  Generate a `SparseMatrix` consisting of `i.i.d.` gaussian random numbers.
  @param numRows number of rows of the matrix
  @param numCols number of columns of the matrix
  @param density the desired density for the matrix
  @param rng a random number generator
  @return `Matrix` with size `numRows` x `numCols` and values in N(0, 1)
--]]
M.sprandn = function()
  error('NIY')
end

--[[
  Generate a `Matrix` consisting of zeros.
  @param numRows number of rows of the matrix
  @param numCols number of columns of the matrix
  @return `Matrix` with size `numRows` x `numCols` and values of zeros
--]]
M.zeros = function(numRows, numCols)
  local DenseMatrix = require 'stuart-ml.linalg.DenseMatrix'
  return DenseMatrix.zeros(numRows, numCols)
end

return M
