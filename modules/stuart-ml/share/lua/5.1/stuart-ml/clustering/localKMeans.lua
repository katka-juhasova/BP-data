--[[
  An utility module to run K-means locally. It's used in the initialization of
  KMeans but not meant to be publicly exposed.
--]]
local M = {}

--[[
  Run K-means++ on the weighted point set `points`. This first does the K-means++
  initialization procedure and then rounds of Lloyd's algorithm.
--]]
M.kMeansPlusPlus = function(_, points, weights, k, maxIterations)
  local dimensions = points[1].vector:size()
  local centers = {}

  -- Initialize centers by sampling using the k-means++ procedure.
  centers[1] = M.pickWeighted(points, weights):toDense()
  local KMeans = require 'stuart-ml.clustering.KMeans'
  local moses = require 'moses'
  local costArray = moses.map(points, function(vectorWithNorm)
    return KMeans.fastSquaredDistance(vectorWithNorm, centers[1])
  end)
  
  local random = require 'stuart-ml.util.random'
  local logging = require 'stuart.internal.logging'
  for i = 1, k do
    local sum = moses.sum(moses.map(moses.zip(costArray, weights), function(p) return p[1] * p[2] end))
    local r = random.nextDouble() * sum
    local cumulativeScore = 0.0
    local j = 1
    while j <= #points and cumulativeScore < r do
      cumulativeScore = cumulativeScore + weights[j] * costArray[j]
      j = j + 1
    end
    if j == 1 then
      logging.logWarning(string.format(
        'kMeansPlusPlus initialization ran out of distinct points for centers. Using duplicate point for center k = %d.', i))
      centers[i] = points[1]:toDense()
    else
      centers[i] = points[j-1]:toDense()
    end
  
    -- update costArray
    for p = 1, #points do
      costArray[p] = math.min(KMeans.fastSquaredDistance(points[p], centers[i], costArray[p]))
    end
  end
  
  -- Run up to maxIterations iterations of Lloyd's algorithm
  local oldClosest = moses.fill({}, -1, 1, #points)
  local iteration = 0
  local moved = true
  local BLAS = require 'stuart-ml.linalg.BLAS'
  local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
  local Vectors = require 'stuart-ml.linalg.Vectors'
  while moved and iteration < maxIterations do
    moved = false
    local counts = moses.fill({}, 0.0, 1, k)
    local sums = moses.fill({}, Vectors.zeros(dimensions), 1, k)
    for i = 1, #points do
      local p = points[i]
      local index, _ = KMeans.findClosest(centers, p)
      BLAS.axpy(weights[i], p.vector, sums[index])
      counts[index] = counts[index] + weights[i]
      if index ~= oldClosest[i] then
        moved = true
        oldClosest[i] = index
      end
    end
    -- Update centers
    for j = 1, k do
      if counts[j] == 0.0 then
        -- Assign center to a random point
        centers[j] = points[1 + random.nextInt(#points-1)]:toDense()
      else
        BLAS.scal(1.0 / counts[j], sums[j])
        centers[j] = VectorWithNorm.new(sums[j])
      end
    end
    iteration = iteration + 1
  end
  
  if iteration == maxIterations then
    logging.logInfo(string.format('Local KMeans++ reached the max number of iterations: %d', maxIterations))
  else
    logging.logInfo(string.format("Local KMeans++ converged in %d iterations.", iteration))
  end
  
  return centers
end

M.pickWeighted = function(data, weights)
  local random = require 'stuart-ml.util.random'
  local moses = require 'moses'
  local r = random.nextDouble() * moses.sum(weights)
  local i, curWeight = 1, 0.0
  while i <= #data and curWeight < r do
    curWeight = curWeight + weights[i]
    i = i + 1
  end
  return data[i-1]
end

return M
