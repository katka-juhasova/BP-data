local M = {}

--[[
  Computes column-wise summary statistics for the input RDD.
  
  @param X an RDD for which column-wise summary statistics are to be computed.
  @return table containing column-wise summary statistics.
--]]
M.colStats = function(rdd)
  local RowMatrix = require 'stuart-ml.linalg.distributed.RowMatrix'
  return RowMatrix.new(rdd):computeColumnSummaryStatistics()
end

--[[
Compute the Pearson correlation for the input RDDs.
Returns NaN if either vector has 0 variance.

@param x RDD[Double] of the same cardinality as y
@param y RDD[Double] of the same cardinality as x
@return A Double containing the Pearson correlation between the two input RDD[Double]s

@note The two input RDDs need to have the same number of partitions and the same number of
      elements in each partition.
--]]
function M.corr(...)
  local Correlations = require 'stuart-ml.stat.corr.Correlations'
  local moses = require 'moses'
  local args = moses.pack(...)
  if #args == 1 then
    local x = args[1]
    return Correlations.corrMatrix(x)
  elseif #args == 2 then
    if type(args[2]) == 'string' then
      local x, method = args[1], args[2]
      return Correlations.corrMatrix(x, method)
    else
      local x, y = args[1], args[2]
      return Correlations.corr(x, y)
    end
  elseif #args == 3 then
    local x, y, method = args[1], args[2], args[3]
    return Correlations.corr(x, y, method)
  end
  error('Unsupported args')
end

return M
