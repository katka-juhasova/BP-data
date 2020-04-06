local M = {}

local ipairs = ipairs

local _ENV = M

function first(a, p)
  if not a or #a == 0 then
    return
  end
  for _, v in ipairs(a) do
    if p(v) then
      return v
    end
  end
end

function any(a, p)
  if not a or #a == 0 then
    return false
  end
  for _, v in ipairs(a) do
    if p(v) then
      return true
    end
  end
  return false
end

function contains(a, x)
  if not a or #a == 0 then
    return false
  end
  for _, v in ipairs(a) do
    if v == x then
      return true
    end
  end
  return false
end

function append(src, dst)
  if not src then
    return
  end

  for _, v in ipairs(src) do
    dst[#dst + 1] = v
  end
end

function appendif(src, dst, p)
  if not src then
    return
  end

  for _, v in ipairs(src) do
    if p(v) then
      dst[#dst + 1] = v
    end
  end
end

function foreach(a, f)
  if not a or #a == 0 then
    return
  end
  for _, v in ipairs(a) do
    f(v)
  end
end

function filter(a, p)
  if not a then
    return
  end
  local r = {}
  if #a == 0 then
    return r
  end
  for _, v in ipairs(a) do
    if p(v) then
      r[#r + 1] = v
    end
  end
  return r
end

function groupby(a, f)
  if not a then
    return
  end
  local r = {}
  if #a == 0 then
    return r
  end
  for _, v in ipairs(a) do
    local k = f(v)
    if not r[k] then
      r[k] = v
    end
  end
  return r
end

function merge(src, dst, keys)
  if not src then
    return
  end

  if keys then
    for _, k in ipairs(keys) do
      if dst[k] == nil then
        dst[k] = src[k]
      end
    end
  else
    for k, v in pairs(src) do
      if dst[k] == nil then
        dst[k] = v
      end
    end
  end
end

function map(a, f)
  if not a then
    return
  end
  local r = {}
  if #a == 0 then
    return r
  end
  for i, v in ipairs(a) do
    r[i] = f(v)
  end
  return r
end

function filter_map(a, p, f)
  if not a then
    return
  end
  local r = {}
  if #a == 0 then
    return r
  end
  for _, v in ipairs(a) do
    if p(v) then
      r[#r + 1] = f(v)
    end
  end
  return r
end

return M
