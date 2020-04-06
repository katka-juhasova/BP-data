local M = {}

M.EPSILON = 2.2204460492503e-16

--[[
 * Returns the squared Euclidean distance between two vectors. The following formula will be used
 * if it does not introduce too much numerical error:
 * <pre>
 *   \|a - b\|_2^2 = \|a\|_2^2 + \|b\|_2^2 - 2 a^T b.
 * </pre>
 * When both vector norms are given, this is faster than computing the squared distance directly,
 * especially when one of the vectors is a sparse vector.
 * @param v1 the first vector
 * @param norm1 the norm of the first vector, non-negative
 * @param v2 the second vector
 * @param norm2 the norm of the second vector, non-negative
 * @param precision desired relative precision for the squared distance
 * @return squared distance between v1 and v2 within the specified precision
--]]
M.fastSquaredDistance = function(v1, norm1, v2, norm2, precision)
  precision = precision or 1e-6
  local n = v1:size()
  assert(v2:size() == n)
  assert(norm1 >= 0.0 and norm2 >= 0.0)
  local sumSquaredNorm = norm1 * norm1 + norm2 * norm2
  local normDiff = norm1 - norm2
  local sqDist = 0.0
  local precisionBound1 = 2.0 * M.EPSILON * sumSquaredNorm / (normDiff * normDiff + M.EPSILON)
  local BLAS = require 'stuart-ml.linalg.BLAS'
  local class = require 'stuart.class'
  local Vectors = require 'stuart-ml.linalg.Vectors'
  local SparseVector = require 'stuart-ml.linalg.SparseVector'
  if precisionBound1 < precision then
    sqDist = sumSquaredNorm - 2.0 * BLAS.dot(v1, v2)
  elseif class.istype(v1,SparseVector) or class.istype(v2,SparseVector) then
    local dotValue = BLAS.dot(v1, v2)
    sqDist = math.max(sumSquaredNorm - 2.0 * dotValue, 0.0)
    local precisionBound2 = M.EPSILON * (sumSquaredNorm + 2.0 * math.abs(dotValue)) / (sqDist + M.EPSILON)
    if precisionBound2 > precision then
      sqDist = Vectors.sqdist(v1, v2)
    end
  else
    sqDist = Vectors.sqdist(v1, v2)
  end
  return sqDist
end

local function computeNumFeatures(rdd)
  local arrays = require 'stuart-ml.util.java.arrays'
  return rdd:map(function(e)
    local indices = e[2]
    return arrays.lastOption(indices) or 0
  end):reduce(function(r,e)
    return math.max(r,e)
  end) + 1
end

local function parseLibSVMRecord(line)
  local util = require 'stuart.util'
  local items = util.split(line, ' ')
  local arrays = require 'stuart-ml.util.java.arrays'
  local label = tonumber(arrays.head(items))
  local moses = require 'moses'
  local unzip = require 'stuart-ml.util'.unzip
  local y = moses.map(moses.filter(arrays.tail(items), function(s) return s:len() > 0 end), function(item)
    local indexAndValue = util.split(item, ':')
    local index = tonumber(indexAndValue[1]) - 1
    local value = tonumber(indexAndValue[2])
    return {index, value}
  end)
  local z = unzip(y)
  local indices, values = z[1] or {}, z[2] or {}
  -- check if indices are one-based and in ascending order
  local previous = -1
  for i = 1, #indices do
    local current = indices[i]
    assert(current > previous) -- indices should be one-based and in ascending order
    previous = current
  end
  return {label, indices, values}
end

local function parseLibSVMFile(sc, path, minPartitions)
  local function trim(s) return (s:gsub('^%s*(.-)%s*$', '%1')) end
  return sc:textFile(path, minPartitions)
    :map(function(s) return trim(s) end)
    :filter(function(line) return line:len() > 0 or line:sub(1,1) ~= '#' end)
    :map(parseLibSVMRecord)
end

--[[
  Loads labeled data in the LIBSVM format into an RDD[LabeledPoint].
  The LIBSVM format is a text-based format used by LIBSVM and LIBLINEAR.
  Each line represents a labeled sparse feature vector using the following format:
  {{{label index1:value1 index2:value2 ...}}}
  where the indices are one-based and in ascending order.
  @param sc Spark context
  @param path file or directory path in any Hadoop-supported file system URI
  @param numFeatures number of features, which will be determined from the input data if a
                     nonpositive value is given. This is useful when the dataset is already split
                     into multiple files and you want to load them separately, because some
                     features may not present in certain files, which leads to inconsistent
                     feature dimensions.
  @param minPartitions min number of partitions
  @return labeled data stored as an RDD[LabeledPoint]
--]]
M.loadLibSVMFile = function(sc, path, numFeatures, minPartitions)
  numFeatures = numFeatures or -1
  minPartitions = minPartitions or sc.defaultMinPartitions
  local parsed = parseLibSVMFile(sc, path, minPartitions)

  -- Determine number of features
  local d
  if numFeatures > 0 then
    d = numFeatures
  else
    d = computeNumFeatures(parsed)
  end
  local LabeledPoint = require 'stuart-ml.regression.LabeledPoint'
  local Vectors = require 'stuart-ml.linalg.Vectors'
  return parsed:map(function(e)
    local label, indices, values = e[1], e[2], e[3]
    return LabeledPoint.new(label, Vectors.sparse(d, indices, values))
  end)
end

return M
