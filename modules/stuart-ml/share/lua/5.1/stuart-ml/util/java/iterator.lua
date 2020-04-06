local M = {}

--[[
Creates iterator that produces the results of some element computation a number of times.
interface: https://www.scala-lang.org/api/current/scala/collection/Iterator$.html
@param len the number of elements returned by the iterator
@param f the element computation
@returns a Lua iterator that produces the results of n evaluations of f
--]]
M.fill = function(len, f)
  local i = 0
  return function()
    i = i + 1
    if i > len then return nil end
    return f()
  end
end

return M
