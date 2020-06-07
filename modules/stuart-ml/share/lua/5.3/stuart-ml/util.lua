local M = {}

--- Produces a flexible list of numbers. If one positive value is passed, will count from 0 to that value,
-- with a default step of 1. If two values are passed, will count from the first one to the second one, with the
-- same default step of 1. A third value passed will be considered a step value.
-- @name range
-- @param[opt] from the initial value of the range
-- @param[optchain] to the final value of the range
-- @param[optchain] step the step of count
-- @return a new array of numbers
M.mosesPatchedRange = function(...)
  local arg = {...}
  local _start,_stop,_step
  if #arg==0 then return {}
  elseif #arg==1 then _stop,_start,_step = arg[1],0,1
  elseif #arg==2 then _start,_stop,_step = arg[1],arg[2],1
  elseif #arg == 3 then _start,_stop,_step = arg[1],arg[2],arg[3]
  end
  if (_step and _step==0) then return {} end
  
  -- BEGIN patch --------------------------------------------------------------
  if _start == 1 and _stop == 1 and _step == 1 then return {1} end
  -- END patch ----------------------------------------------------------------
  
  local _ranged = {}
  local _steps = math.max(math.floor((_stop-_start)/_step),0)
  for i=1,_steps do _ranged[#_ranged+1] = _start+_step*i end
  if #_ranged>0 then table.insert(_ranged,1,_start) end
  return _ranged
end

-- Moses 2.1.0-1 has a bug in zip(). This temporary fix is sourced from
-- https://github.com/Yonaba/Moses/commit/14171d243b76c845c3a9001aee1a0e9d2056f95e
M.mosesPatchedZip = function(...)
  local moses = require 'moses'
  local args = {...}
  local n = moses.max(args, function(array) return #array end) or 0
  local _ans = {}
  for i = 1,n do
    if not _ans[i] then _ans[i] = {} end
    for k, array in ipairs(args) do
      if (array[i]~=nil) then _ans[i][#_ans[i]+1] = array[i] end
    end
  end
  return _ans
end

M.tableIterator = function(table)
  local i = 0
  return function()
    i = i + 1
    if i <= #table then return table[i] end
  end
end

M.unzip = function(array)
  local zip = M.mosesPatchedZip
  local unpack = table.unpack or unpack
  return zip(unpack(array))
end

return M
