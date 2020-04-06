local _M = {}

function _M.dump(table)
  for key, value in pairs(table) do
    print(key, value)
  end
end

function _M.equal(table1, table2)
  local result = true

  for i=1, #table1 do
    if table1[i] ~= table2[i] then
      result = false
      break
    end
  end

  return result
end

function _M.new(self)
  local object = {}
  setmetatable(object, object)
  object.__index = self
  return object
end

return _M
