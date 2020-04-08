local M = {}

function M.corr(x, y, method)
  local correlation = M.getCorrelationFromName(method)
  return correlation:computeCorrelation(x, y)
end

function M.corrMatrix(x, method)
  local correlation = M.getCorrelationFromName(method)
  return correlation:computeCorrelationMatrix(x)
end

-- Match input correlation name with a known name via simple string matching.
function M.getCorrelationFromName(method)
  method = method or 'pearson'
  if method == 'pearson' then
    local PearsonCorrelation = require 'stuart-ml.stat.corr.PearsonCorrelation'
    return PearsonCorrelation.new()
  elseif method == 'spearman' then
    error('NIY')
  else
    error('Unrecognized correlation method')
  end
end

return M
