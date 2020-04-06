local class = require 'stuart.class'

-- Moses find() and unique() don't use metatable __eq fns, so don't work for Spark Vector types
local function find(array, value)
  local moses = require 'moses'
  for i = 1, #array do
    if moses.isEqual(array[i], value, true) then return i end
  end
end
local function unique(array)
  local ret = {}
  for i = 1, #array do
    if not find(ret, array[i]) then
      ret[#ret+1] = array[i]
    end
  end
  return ret
end

local KMeans = class.new()

KMeans.RANDOM = 'RANDOM'
KMeans.K_MEANS_PARALLEL = 'k-means||'

function KMeans:_init(k, maxIterations, initializationMode, initializationSteps, epsilon, seed)
  self.k = k or 2
  self.maxIterations = maxIterations or 20
  self.initializationMode = initializationMode or KMeans.K_MEANS_PARALLEL
  self.initializationSteps = initializationSteps or 2
  self.epsilon = epsilon or 1e-4
  self.seed = seed or math.random(32000)
  self.initialModel = nil
end

-- Returns the squared Euclidean distance between two vectors
function KMeans.fastSquaredDistance(vectorWithNorm1, vectorWithNorm2)
  local MLUtils = require 'stuart-ml.util.MLUtils'
  return MLUtils.fastSquaredDistance(vectorWithNorm1.vector, vectorWithNorm1.norm, vectorWithNorm2.vector, vectorWithNorm2.norm)
end

-- returns a Lua 1-based index
function KMeans.findClosest(centers, point)
  local bestDistance = math.huge
  local bestIndex = 1
  for i,center in ipairs(centers) do
    local lowerBoundOfSqDist = center.norm - point.norm
    lowerBoundOfSqDist = lowerBoundOfSqDist * lowerBoundOfSqDist
    if lowerBoundOfSqDist < bestDistance then
      local distance = KMeans.fastSquaredDistance(center, point)
      if distance < bestDistance then
        bestDistance = distance
        bestIndex = i
      end
    end
  end
  return bestIndex, bestDistance
end

function KMeans:getInitializationMode()
  return self.initializationMode
end

function KMeans:getInitializationSteps()
  return self.initializationSteps
end

function KMeans:getK()
  return self.k
end

function KMeans:getMaxIterations()
  return self.maxIterations
end

function KMeans:getSeed()
  return self.seed
end

function KMeans:initKMeansParallel(data)
  local RDD = require 'stuart.RDD'
  assert(class.istype(data,RDD))
  
  -- Initialize empty centers and point costs.
  local costs = data:map(function() return math.huge end)

  -- Initialize the first center to a random point.
  math.randomseed(self.seed)
  local seed = math.random(32000)
  local sample = data:takeSample(false, 1, seed)
  
  -- Could be empty if data is empty; fail with a better message early:
  assert(#sample > 0, 'No samples available from data')

  local centers = {}
  local newCenters = {sample[1]:toDense()}
  centers[#centers+1] = newCenters[1]
  
  -- On each step, sample 2 * k points on average with probability proportional
  -- to their squared distance from the centers. Note that only distances between points
  -- and new centers are computed in each iteration.
  local bcNewCentersList = {}
  local moses = require 'moses'
  local tableIterator = require 'stuart-ml.util'.tableIterator
  local random = require 'stuart-ml.util.random'
  for step = 1, self.initializationSteps do
    local bcNewCenters = newCenters
    bcNewCentersList[#bcNewCentersList+1] = bcNewCenters
    local preCosts = costs
    costs = data:zip(preCosts):map(function(e)
      local point, cost = e[1], e[2]
      return math.min(KMeans.pointCost(bcNewCenters, point), cost)
    end)

    local sumCosts = costs:sum()

    local chosen = data:zip(costs):mapPartitionsWithIndex(function(_, pointCostsIter)
      local r = {}
      for pointCost in pointCostsIter do
        local point, cost = pointCost[1], pointCost[2]
        if random.nextDouble() < 2.0 * cost * self.k / sumCosts then
          r[#r+1] = point
        end
      end
      return tableIterator(r)
    end):collect()
    
    newCenters = moses.map(chosen, function(v) return v:toDense() end)
    centers = moses.append(centers, newCenters)
  end


  local distinctCenters = unique(moses.pluck(centers, 'vector'))
  local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
  distinctCenters = moses.map(distinctCenters, function(v) return VectorWithNorm.new(v) end)

  if #distinctCenters <= self.k then
    return distinctCenters
  else
    -- Finally, we might have a set of more than k distinct candidate centers; weight each
    -- candidate by the number of points in the dataset mapping to it and run a local k-means++
    -- on the weighted centers to pick k of them
    local countMap = data:map(function(vectorWithNorm)
      local bestIndex, _ = KMeans.findClosest(distinctCenters, vectorWithNorm)
      return bestIndex
    end):countByValue()

    local myWeights = moses.map(distinctCenters, function(_, i) return countMap[i] or 0.0 end)
    local localKMeans = require 'stuart-ml.clustering.localKMeans'
    return localKMeans.kMeansPlusPlus(0, distinctCenters, myWeights, self.k, 30)
  end
end

function KMeans:initRandom(vectorsWithNormsRDD)
  -- Select without replacement; may still produce duplicates if the data has < k distinct
  -- points, so deduplicate the centroids to match the behavior of k-means|| in the same situation
  local now = require 'stuart.interface'.now
  local has_now, seed = pcall(now)
  if not has_now then seed = math.random(32000) end
  local sample = vectorsWithNormsRDD:takeSample(false, self.k, seed)
  local moses = require 'moses'
  local distinctSample = unique(moses.pluck(sample, 'vector'))
  local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
  return moses.map(distinctSample, function(v) return VectorWithNorm.new(v) end)
end

function KMeans.pointCost(centers, point)
  local _, bestDistance = KMeans.findClosest(centers, point)
  return bestDistance
end

--[[
  Train a K-means model on the given set of points; `data` should be cached for high
  performance, because this is an iterative algorithm.
--]]
function KMeans:run(data)
  -- Compute squared norms and cache them.
  local Vectors = require 'stuart-ml.linalg.Vectors'
  local norms = data:map(function(v) return Vectors.norm(v, 2.0) end)
  local zippedData = data:zip(norms):map(function(e)
    local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
    return VectorWithNorm.new(e[1], e[2])
  end)
  local model = self:runAlgorithm(zippedData)
  return model
end

--[[
  Implementation of K-Means algorithm.
--]]
function KMeans:runAlgorithm(data)
  local moses = require 'moses'
  local centers
  if self.initialModel ~= nil then
    local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
    centers = moses.map(self.initialModel.clusterCenters, function(center) return VectorWithNorm.new(center) end)
  else
    if self.initializationMode == KMeans.RANDOM then
      centers = self:initRandom(data)
    else
      centers = self:initKMeansParallel(data)
    end
  end
  if self.initialModel == nil then
    if self.initializationMode == KMeans.RANDOM then
      self:initRandom(data)
    else
      self:initKMeansParallel(data)
    end
  end
  
  local converged, cost, iteration = false, 0.0, 1
  
  -- Execute iterations of Lloyd's algorithm until converged
  local now = require 'stuart.interface'.now
  local has_now, iterationStartTime = pcall(now)
  
  local BLAS = require 'stuart-ml.linalg.BLAS'
  local tableIterator = require 'stuart-ml.util'.tableIterator
  local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
  local Vectors = require 'stuart-ml.linalg.Vectors'
  
  while iteration <= self.maxIterations and not converged do
    
    -- Find the sum and count of points mapping to each center
    local totalContribs = data:mapPartitions(function(partitionIter)
      local dims = centers[1].vector:size()
      
      local sums = moses.fill({}, Vectors.zeros(dims), 1, #centers)
      local counts = moses.fill({}, 0, 1, #centers)
      
      for point in partitionIter do
        local bestCenter, cost_ = KMeans.findClosest(centers, point)
        cost = cost + cost_
        local sum = sums[bestCenter]
        BLAS.axpy(1.0, point.vector, sum)
        counts[bestCenter] = counts[bestCenter] + 1
      end
      
      local contribsKeys = moses.filter(moses.keys(counts), function(i) return counts[i] > 0 end)
      local contribs = moses.map(contribsKeys, function(j)
        return {j, {sums[j], counts[j]}}
      end)
      return tableIterator(contribs)
      
    end):reduceByKey(function(e)
      local sum1, count1, sum2, count2 = e[1][1], e[1][2], e[2][1], e[2][2]
      BLAS.axpy(1.0, sum2, sum1)
      return {sum1, count1 + count2}
    end):collectAsMap()
    
    -- Update the cluster centers and costs
    converged = true
    moses.each(totalContribs, function(e, j)
      local sum, count = e[1], e[2]
      BLAS.scal(1.0 / count, sum)
      local newCenter = VectorWithNorm.new(sum)
      if converged and KMeans.fastSquaredDistance(newCenter, centers[j]) > self.epsilon * self.epsilon then
        converged = false
      end
      centers[j] = newCenter
    end)
    
    iteration = iteration + 1
  end
  
  local logging = require 'stuart.internal.logging'
  if has_now then
    local iterationTimeInSeconds = now() - iterationStartTime
    logging.logInfo(string.format('Iterations took %f seconds.', iterationTimeInSeconds))
  end
  
  if iteration == self.maxIterations then
    logging.logInfo(string.format('KMeans reached the max number of iterations: %d.', self.maxIterations))
  else
    logging.logInfo(string.format('KMeans converged in %d iterations.', iteration))
  end
  
  logging.logInfo(string.format('The cost is %f', cost))
  
  local KMeansModel = require 'stuart-ml.clustering.KMeansModel'
  return KMeansModel.new(moses.pluck(centers, 'vector'))
end

function KMeans:setInitialModel(model)
  assert(model.k == self.k, 'mismatched cluster count')
  self.initialModel = model
  return self
end

function KMeans:setInitializationMode(initializationMode)
  assert(initializationMode == KMeans.RANDOM or initializationMode == KMeans.K_MEANS_PARALLEL)
  self.initializationMode = initializationMode
  return self
end

function KMeans:setInitializationSteps(initializationSteps)
  assert(initializationSteps > 0, 'Number of initialization steps must be positive but got ' .. initializationSteps)
  self.initializationSteps = initializationSteps
  return self
end

function KMeans:setK(k)
  assert(k > 0, 'Number of clusters must be positive but got ' .. k)
  self.k = k
  return self
end

function KMeans:setMaxIterations(maxIterations)
  assert(maxIterations >= 0, 'Maximum of iterations must be nonnegative but got ' .. maxIterations)
  self.maxIterations = maxIterations
  return self
end

function KMeans:setSeed(seed)
  self.seed = seed
  return self
end

function KMeans.train(rdd, k, maxIterations, initializationMode, seed)
  return KMeans.new(k, maxIterations, initializationMode, 2, 1e-4, seed):run(rdd)
end

return KMeans
