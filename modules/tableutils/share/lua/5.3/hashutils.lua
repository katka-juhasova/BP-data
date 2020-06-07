--- tableutil/hashutil: Utility functions for working with hash-like tables
--
-- Peter Aronoff
-- BSD 3-Clause License
-- 2013-2018
local pairs = pairs

local foreach = function (func, hash)
  for key, val in pairs(hash) do
    func(key, val)
  end
end

local map = function (func, hash)
  local mapped = {}

  for key, val in pairs(hash) do
    func(key, val, mapped)
  end

  return mapped
end

local reduce = function (func, accumulator, hash)
  for key, val in pairs(hash) do
    accumulator = func(accumulator, key, val)
  end

  return accumulator
end

local filter = function (pred, hash)
  local found = {}

  for key, val in pairs(hash) do
    if pred(key, val) then
      found[key] = val
    end
  end

  return found
end

local partition = function (pred, hash)
  local hits = {}
  local misses = {}

  for key, val in pairs(hash) do
    if pred(key, val) then
      hits[key] = val
    else
      misses[key] = val
    end
  end

  return hits, misses
end

local all = function (pred, hash)
  for key, val in pairs(hash) do
    if not pred(key, val) then
      return false
    end
  end

  return true
end

local any = function (fun, hash)
  for key, val in pairs(hash) do
    if fun(key) or fun(val) then
      return true
    end
  end

  return false
end

local iskey = function (wanted, hash)
  for key, _ in pairs(hash) do
    if key == wanted then
      return true
    end
  end

  return false
end

local isval = function (wanted, hash)
  for _, val in pairs(hash) do
    if val == wanted then
      return true
    end
  end

  return false
end

local keys = function (hash)
  local ks = {}
  for k, _ in pairs(hash) do
    ks[#ks + 1] = k
  end

  return ks
end

local values = function (hash)
  local vs = {}
  for _, v in pairs(hash) do
    vs[#vs + 1] = v
  end

  return vs
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
  map = map,
  reduce = reduce,
  filter = filter,
  partition = partition,
  all = all,
  any = any,
  iskey = iskey,
  isval = isval,
  keys = keys,
  values = values,
  version = version,
  author = author,
  url = url,
  license = license,
}
