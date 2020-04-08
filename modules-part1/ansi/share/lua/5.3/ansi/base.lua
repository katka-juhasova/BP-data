
local base = {}

local function join(numbers)
  local result = ""

  i = 1
  for k,v in pairs(numbers) do
    for _ = i,k-1 do
      result = result .. ";"
    end
    result = result .. v
  end

  return result
end


function base.buildCode(nums, letter, handle)
  local code = string.char(27) .. "["
      .. join(nums) .. letter
  
  if handle then
    return handle:write(code)
  else
    return code
  end
end


return base
