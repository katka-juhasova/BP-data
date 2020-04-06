
local utils = {}


-- check whether a lua table is an array or a dictionary
-- note: this will only work if the table is either an array or a dictionary. if the table is both, god help us all
-- https://stackoverflow.com/a/25709704/2513803
function utils.is_array(t)
  local i = 0
  for _ in pairs(t) do
      i = i + 1
      if t[i] == nil then return false end
  end
  return true
end


-- check whether a table contains a value
-- https://stackoverflow.com/a/33511182/2513803
function utils.has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end


return utils
