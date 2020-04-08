local M = {}

M.nextDouble = function()
  return M.nextFloat(0, 1)
end

M.nextFloat = function(lower, upper)
  return lower + math.random() * (upper - lower)
end

M.nextInt = function(n)
  if n ~= nil then
    return math.random(0, n)
  else
    return math.random(-2147483648, 2147483647)
  end
end

M.nextLong = function(n)
  if n ~= nil then
    return math.random(0, n)
  else
    return math.random(-2^56, 2^56)
  end
end

return M
