local class = require 'stuart.class'

-- Represents a row-oriented distributed Matrix with no meaningful row indices.
local RowMatrix = class.new()

function RowMatrix:_init(rows, nRows, nCols)
  self.rows = rows
  self.nRows = nRows or 0
  self.nCols = nCols or 0
end

function RowMatrix:checkNumColumns(cols)
  assert(cols <= 65535)
  if cols > 10000 then
    local memMB = (cols * cols) / 125000
    local logging = require 'stuart.internal.logging'
    logging.logWarning(string.format('$cols columns will require at least %d megabytes of memory', memMB))
  end
end

--[[
Compute all cosine similarities between columns of this matrix using the brute-force
approach of computing normalized dot products.
--]]
function RowMatrix:columnSimilarities()
  error('NIY')
end

-- Find all similar columns using the DIMSUM sampling algorithm, described in two papers
function RowMatrix:columnSimilaritiesDIMSUM()
  error('NIY')
end

--[[
  Computes column-wise summary statistics.
--]]
function RowMatrix:computeColumnSummaryStatistics()
  local MultivariateOnlineSummarizer = require 'stuart-ml.stat.MultivariateOnlineSummarizer'
  local summarizer = MultivariateOnlineSummarizer.new()
  local seqOp = function(summarizer_, data) return summarizer_:add(data) end
  local combOp = function(summarizer1, summarizer2) return summarizer1:merge(summarizer2) end
  local summary = self.rows:treeAggregate(summarizer, seqOp, combOp)
  self:updateNumRows(summary:count())
  return summary
end

-- Computes the covariance matrix, treating each row as an observation.
function RowMatrix:computeCovariance()
  local n = self:numCols()
  self:checkNumColumns(n)

  local summary = self:computeColumnSummaryStatistics()
  local m = summary:count()
  assert(m > 1, 'Cannot compute the covariance of a RowMatrix with <= 1 row')
  local mean = summary:mean()

  -- We use the formula Cov(X, Y) = E[X * Y] - E[X] E[Y], which is not accurate if E[X * Y] is
  -- large but Cov(X, Y) is small, but it is good for sparse computation.
  
  local G = self:computeGramianMatrix()

  local m1 = m - 1.0
  for i = 0, n-1 do
    local alpha = m / m1 * mean[i+1]
    for j = i, n-1 do
      local Gij = G:get(i,j) / m1 - alpha * mean[j+1]
      G:update(i, j, Gij)
      G:update(j, i, Gij)
    end
  end

  return G
end

-- Computes the Gramian matrix `A^T A`.
function RowMatrix:computeGramianMatrix()
  local n = self:numCols()
  self:checkNumColumns(n)
  -- Computes n*(n+1)/2, avoiding overflow in the multiplication.
  -- This succeeds when n <= 65535, which is checked above
  local nt
  if n % 2 == 0 then
    nt = (n / 2) * (n + 1)
  else
    nt = n * ((n + 1) / 2)
  end

  -- Compute the upper triangular part of the gram matrix.
  local BLAS = require 'stuart-ml.linalg.BLAS'
  local seqOp = function(u, v)
    BLAS.spr(1.0, v, u)
    return u
  end
  local DenseVector = require 'stuart-ml.linalg.DenseVector'
  local moses = require 'moses'
  local combOp = function(u1, u2)
    local values = moses.map(moses.zip(u1.values, u2.values), function(e)
      return e[1]+e[2]
    end)
    return DenseVector.new(values)
  end
  local zeroValue = DenseVector.new(moses.zeros(nt))
  local GU = self.rows:treeAggregate(zeroValue, seqOp, combOp)
  return RowMatrix.triuToFull(n, GU.values)
end

-- Computes the top k principal components only.
function RowMatrix:computePrincipalComponents()
  error('NIY')
end

--[[
Computes the top k principal components and a vector of proportions of
variance explained by each principal component.
--]]
function RowMatrix:computePrincipalComponentsAndExplainedVariance()
  error('NIY')
end

--[[
Computes singular value decomposition of this matrix. Denote this matrix by A (m x n). This
will compute matrices U, S, V such that A ~= U * S * V', where S contains the leading k
singular values, U and V contain the corresponding singular vectors.
--]]
function RowMatrix:computeSVD()
  error('NIY')
end

-- Multiply this matrix by a local matrix on the right.
function RowMatrix:multiply()
  error('NIY')
end

-- Multiplies the Gramian matrix `A^T A` by a dense vector on the right without computing `A^T A`.
function RowMatrix:multiplyGramianMatrixBy()
  error('NIY')
end

-- Gets or computes the number of columns.
function RowMatrix:numCols()
  if self.nCols <= 0 then
    -- Calling `first` will throw an exception if `rows` is empty.
    self.nCols = self.rows:first():size()
  end
  return self.nCols
end

-- Gets or computes the number of rows.
function RowMatrix:numRows()
  if self.nRows <= 0 then
    self.nRows = self.rows:count()
    if self.nRows == 0 then
      error('Cannot determine the number of rows because it is not specified in the constructor and the rows RDD is empty')
    end
  end
  return self.nRows
end

--[[
Compute QR decomposition for RowMatrix. The implementation is designed to optimize the QR
decomposition (factorization) for the RowMatrix of a tall and skinny shape.
Reference:
  Paul G. Constantine, David F. Gleich. "Tall and skinny QR factorizations in MapReduce
  architectures" (see <a href="http://dx.doi.org/10.1145/1996092.1996103">here</a>)
--]]
function RowMatrix:tallSkinnyQR()
  error('NIY')
end

-- Fills a full square matrix from its upper triangular part.
function RowMatrix.triuToFull(n, U)
  local DenseMatrix = require 'stuart-ml.linalg.DenseMatrix'
  local G = DenseMatrix.zeros(n, n)
  local idx = 1
  for col = 0, n-1 do
    for row = 0, col-1 do
      local value = U[idx]
      G:update(row, col, value)
      G:update(col, row, value)
      idx = idx + 1
    end
    G:update(col, col, U[idx])
    idx = idx + 1
  end
  local Matrices = require 'stuart-ml.linalg.Matrices'
  return Matrices.dense(n, n, G.values)
end

-- Updates or verifies the number of rows.
function RowMatrix:updateNumRows(m)
  if self.nRows <= 0 then
    self.nRows = m
  else
    assert(self.nRows == m, string.format('The number of rows %d is different from what specified or previously computed: %d', m, self.nRows))
  end
end

return RowMatrix
