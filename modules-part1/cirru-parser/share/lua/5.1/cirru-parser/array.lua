local size
size = function(list)
  local count = 0
  for key, value in pairs(list) do
    count = count + 1
  end
  return count
end
local concat
concat = function(listA, listB)
  local resultList = { }
  local sizeA = size(listA)
  for key, value in pairs(listA) do
    resultList[key] = value
  end
  for key, value in pairs(listB) do
    resultList[key + sizeA] = value
  end
  return resultList
end
local append
append = function(list, item)
  return concat(list, {
    item
  })
end
local init
init = function(list)
  local sizeX = size(list)
  if sizeX < 1 then
    error("call init upon empty table")
  end
  local resultList = { }
  for key, value in pairs(list) do
    if key < sizeX then
      resultList[key] = value
    end
  end
  return resultList
end
local tail
tail = function(list)
  local resultList = { }
  for key, value in pairs(list) do
    if key > 1 then
      resultList[key - 1] = value
    end
  end
  return resultList
end
local isArray
isArray = function(list)
  if type(list) ~= 'table' then
    return false
  end
  for key, value in pairs(list) do
    if (type(key)) ~= 'number' then
      return false
    end
  end
  return true
end
local map
map = function(list, fn)
  local resultList = { }
  for key, value in pairs(list) do
    resultList[key] = fn(value, key)
  end
  return resultList
end
return {
  size = size,
  concat = concat,
  append = append,
  init = init,
  isArray = isArray,
  tail = tail,
  map = map
}
