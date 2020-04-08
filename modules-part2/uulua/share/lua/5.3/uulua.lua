math.randomseed(os.time())
local random = math.random
random()
random()
random()

local M = {}

--- Converts a number between 0 and 15 to a hex digit
-- Behavior for numbers not between 0 and 15 is not defined!
local function tohex(num)
  return string.char(("0123456789abcdef"):byte(num+1))
end

--- Generates a version 4 variant 1 UUID
-- does not accept any arguments
function M.v41()
  local uuid = "xxxxxxxx-xxxx-axxx-bxxx-xxxxxxxxxxxx"
  uuid = uuid:gsub("a", function(a)
    return "4"
  end):gsub("b", function(b)
    return tohex(8+random(3)) -- 10xx
  end):gsub("x", function(x)
    return tohex(random(15))
  end)
  return uuid
end

--- Generates a version 4 variant 2 UUID
-- does not accept any arguments
function M.v42()
  local uuid = "xxxxxxxx-xxxx-axxx-bxxx-xxxxxxxxxxxx"
  uuid = uuid:gsub("a", function(a)
    return "4"
  end):gsub("b", function(b)
    return tohex(12+random(1)) -- 110x
  end):gsub("x", function(x)
    return tohex(random(15))
  end)
  return uuid
end

M.random = M.v41

return M
