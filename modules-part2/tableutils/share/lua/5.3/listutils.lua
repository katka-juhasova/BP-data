--- tableutil/listutil: Utility functions for working with list-like tables
--
-- Peter Aronoff
-- BSD 3-Clause License
-- 2013-2018
local ipairs = ipairs

local foreach = function (func, list)
  for _, val in ipairs(list) do
    func(val)
  end
end

local foreach_withindex = function (func, list)
  for idx, val in ipairs(list) do
    func(val, idx)
  end
end

local map = function (func, list)
  local mapped = {}
  -- We can't use for idx, val here, since a user could theoretically use map
  -- as if it were filter. If they did this, and we used the original list's
  -- indices, mapped would become a sparse table. We don't want that.
  for _, val in ipairs(list) do
    local res = func(val)
    if res ~= nil then
      mapped[#mapped + 1] = res
    end
  end

  return mapped
end

local foldl = function (func, accumulator, list)
  for idx=1, #list do
    accumulator = func(accumulator, list[idx])
  end

  return accumulator
end

local foldr = function (func, accumulator, list)
  for idx=#list, 1, -1 do
    accumulator = func(accumulator, list[idx])
  end

  return accumulator
end

local filter = function (pred, list)
  local found = {}
  -- We can't use for idx, val here, since found[idx] inside the if clause
  -- could yield the wrong results. E.g., found[1], found[2], found[4]. That
  -- gives us a sparse array, which we do not want.
  for _, val in ipairs(list) do
    if pred(val) then
      found[#found + 1] = val
    end
  end

  return found
end

local partition = function (pred, list)
  local hits = {}
  local misses = {}
  for _, val in ipairs(list) do
    if pred(val) then
      hits[#hits + 1] = val
    else
      misses[#misses + 1] = val
    end
  end

  return hits, misses
end

local zip = function (l1, l2)
  local zipped = {}
  local len = #l1
  if #l2 < len then len = #l2 end
  for idx = 1, len do
    zipped[idx] = { l1[idx], l2[idx] }
  end

  return zipped
end

local stitch = function(l1, l2)
  local stitched = {}
  local len = #l1
  if #l2 < len then len = #l2 end
  for idx = 1, len do
    stitched[l1[idx]] = l2[idx]
  end

  return stitched
end

local all = function (pred, list)
  for _, val in ipairs(list) do
    if not pred(val) then
      return false
    end
  end

  return true
end

local any = function (pred, list)
  for _, val in ipairs(list) do
    if pred(val) then
      return true
    end
  end

  return false
end

local member = function (elem, list)
  for _, val in ipairs(list) do
    if val == elem then
      return true
    end
  end

  return false
end

local max = function(t)
  local maximum = t[1]
  for _, val in ipairs(t) do
    if val > maximum then
      maximum = val
    end
  end

  return maximum
end

local min = function(t)
  local minimum = t[1]
  for _, val in ipairs(t) do
    if val < minimum then
      minimum = val
    end
  end

  return minimum
end

local sum = function (t)
  local total = 0
  for _, val in ipairs(t) do
    total = total + val
  end

  return total
end

local product = function (t)
  local result = 1
  for _, val in ipairs(t) do
    result = result * val
  end

  return result
end

local version = function ()
  return "2.2.1"
end

local author = function ()
  return "Peter Aronoff"
end

local url = function ()
  return "https://github.com/telemachus/tableutils"
end

local license = function ()
  return "BSD 3-Clause"
end

return {
  foreach = foreach,
  foreach_withindex = foreach_withindex,
  map = map,
  foldl = foldl,
  reduce = foldl,
  foldr = foldr,
  filter = filter,
  partition = partition,
  all = all,
  any = any,
  member = member,
  zip = zip,
  max = max,
  min = min,
  sum = sum,
  product = product,
  stitch = stitch,
  version = version,
  author = author,
  url = url,
  license = license,
}
