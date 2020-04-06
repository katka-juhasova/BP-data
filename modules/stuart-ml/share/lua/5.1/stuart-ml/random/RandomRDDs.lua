local M = {}

-- Returns `numPartitions` if it is positive, or `sc.defaultParallelism` otherwise.
local function numPartitionsOrDefault(sc, numPartitions)
  if numPartitions > 0 then
    return numPartitions
  else
    return sc.defaultMinPartitions or 1
  end
end

--[[
Generates an RDD[Vector] with vectors containing `i.i.d.` samples drawn from the
standard normal distribution.

@param sc SparkContext used to create the RDD.
@param numRows Number of Vectors in the RDD.
@param numCols Number of elements in each Vector.
@param numPartitions Number of partitions in the RDD (default: `sc.defaultParallelism`).
@return RDD[Vector] with vectors containing `i.i.d.` samples ~ `N(0.0, 1.0)`.
--]]
function M.normalVectorRDD(sc, numRows, numCols, numPartitions)
  numPartitions = numPartitionsOrDefault(sc, numPartitions)
  assert(numRows > 0)
  assert(numCols > 0)
  assert(numPartitions > 0)
  local partitions = {}
  local Vectors = require 'stuart-ml.linalg.Vectors'
  local random = require 'stuart-ml.util.random'
  local Partition = require 'stuart.Partition'
  for partitionIndex = 1, numPartitions do
    local partitionData = {}
    for i = 1, numRows do
      local vectorData = {}
      for j = 1, numCols do
        vectorData[#vectorData+1] = random.nextLong()
      end
      local vector = Vectors.dense(vectorData)
      partitionData[#partitionData+1] = vector
    end
    local partition = Partition.new(partitionData, partitionIndex)
    partitions[#partitions+1] = partition
  end
  local RDD = require 'stuart.RDD'
  return RDD.new(sc, partitions)
end

return M
