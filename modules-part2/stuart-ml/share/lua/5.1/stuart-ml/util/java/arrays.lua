local M = {}

-- interface: https://docs.oracle.com/javase/7/docs/api/java/util/Arrays.html#binarySearch(float[],%20int,%20int,%20float)
--            (but conforming to Lua 1-based table indexes instead of Java's 0-based indexes)
-- implementation: https://stackoverflow.com/questions/19522451/binary-search-of-an-array-of-arrays-in-lua
M.binarySearch = function(a, fromIndex, toIndex, key)
  fromIndex = fromIndex or 1
  assert(fromIndex >= 1)
  toIndex = toIndex or #a+1
  while fromIndex < toIndex do
    local mid = math.floor((fromIndex+toIndex) / 2)
    local midVal = a[mid]
    if midVal < key then
      fromIndex = mid+1
    elseif midVal > key then
      toIndex = mid
    else
      return mid
    end
  end
  return -fromIndex
end

M.head = function(a)
  if #a > 0 then return a[1] end
end

M.lastOption = function(a)
  if #a > 0 then return a[#a] end
end

M.tabulate = function(n, f)
  local res = {}
  for i = 0, n-1 do
    res[#res+1] = f(i)
  end
  return res
end

M.tail = function(a)
  local unpack = table.unpack or unpack
  return {unpack(a, 2, #a)}
end

return M
