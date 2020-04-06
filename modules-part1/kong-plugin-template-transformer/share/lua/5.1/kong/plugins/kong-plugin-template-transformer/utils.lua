_M = {}

function _M.has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function _M.hide_fields(table, hidden_fields)
  if hidden_fields ~= nil and next(hidden_fields) ~= nil then
    for key, value in pairs(table) do
      if _M.has_value(hidden_fields, key) then
          table[key] = "******"
      end

      if type(value) == "table" then
        _M.hide_fields(value, hidden_fields)
      end
    end
  end
end

return _M
