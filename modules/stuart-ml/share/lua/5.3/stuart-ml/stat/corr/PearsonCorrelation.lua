local class = require 'stuart.class'
local Correlation = require 'stuart-ml.stat.corr.Correlation'

--[[
Compute Pearson correlation for two RDDs of the type RDD[Double] or the correlation matrix
for an RDD of the type RDD[Vector].

Definition of Pearson correlation can be found at
http://en.wikipedia.org/wiki/Pearson_product-moment_correlation_coefficient
--]]
local PearsonCorrelation = class.new(Correlation)

-- Compute the Pearson correlation for two datasets. NaN if either vector has 0 variance.
function PearsonCorrelation:computeCorrelation(x, y)
  return self:computeCorrelationWithMatrixImpl(x, y)
end

--[[
Compute the Pearson correlation matrix S, for the input matrix, where S(i, j) is the
correlation between column i and j. 0 covariance results in a correlation value of Double.NaN.
--]]
function PearsonCorrelation:computeCorrelationMatrix(x)
  local RowMatrix = require 'stuart-ml.linalg.distributed.RowMatrix'
  local rowMatrix = RowMatrix.new(x)
  local cov = rowMatrix:computeCovariance()
  return self:computeCorrelationMatrixFromCovariance(cov)
end

local function closeToZero(value, threshold)
  return math.abs(value) <= (threshold or 1e-12)
end

--[[
Compute the Pearson correlation matrix from the covariance matrix.
0 variance results in a correlation value of nil.
--]]
function PearsonCorrelation:computeCorrelationMatrixFromCovariance(covarianceMatrix)
  local cov = covarianceMatrix
  local n = cov.numCols
  
  -- Compute the standard deviation on the diagonals first
  for i = 0, n-1 do
    local x = cov:get(i,i)
    if closeToZero(x) then
      cov:update(i, i, 0.0)
    else
      cov:update(i, i, math.sqrt(x))
    end
  end
  
  -- Loop through columns since cov is column major
  local containNaN = false
  for j = 0, n-1 do
    local sigma = cov:get(j,j)
    for i = 0, j-1 do
      local corr
      if sigma == 0 or cov:get(i,i) == 0 then
        containNaN = true
        corr = nil
      else
        corr = cov:get(i,j) / (sigma * cov:get(i,i))
      end
      cov:update(i, j, corr)
      cov:update(j, i, corr)
    end
  end
  
  -- put 1.0 on the diagonals
  for i = 0, n-1 do
    cov:update(i, i, 1.0)
  end
  
  if containNaN then
    local logging = require 'stuart.internal.logging'
    logging.logWarning('Pearson correlation matrix contains NaN values.')
  end
  
  return cov
end

return PearsonCorrelation
