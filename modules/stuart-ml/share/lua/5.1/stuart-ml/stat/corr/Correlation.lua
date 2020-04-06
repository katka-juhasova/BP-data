local class = require 'stuart.class'

local Correlation = class.new()

--[[
Combine the two input RDD[Double]s into an RDD[Vector] and compute the correlation using the
correlation implementation for RDD[Vector]. Can be NaN if correlation is undefined for the
input vectors.
--]]
function Correlation:computeCorrelationWithMatrixImpl(x, y)
  local DenseVector = require 'stuart-ml.linalg.DenseVector'
  local mat = x:zip(y):map(function(e)
    local xi, yi = e[1], e[2]
    return DenseVector.new({xi, yi})
  end)
  return self:computeCorrelationMatrix(mat):get(0, 1)
end

return Correlation
