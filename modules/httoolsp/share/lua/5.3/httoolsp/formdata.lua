local random_hex
random_hex = require('httoolsp.utils').random_hex
local table_insert = table.insert
local table_concat = table.concat
local co_wrap = coroutine.wrap
local co_yield = coroutine.yield
local DEFAULT_CONTENT_TYPE = 'application/octet-stream'
local CRLF = '\r\n'
local _check_value_type
_check_value_type = function(value)
  local value_type = type(value)
  if value_type == 'string' or value_type == 'function' then
    return true
  end
  return false, ('value %s has unsupported type %s'):format(tostring(value), value_type)
end
local _check_param_type
_check_param_type = function(param_name, param)
  if type(param) == 'string' then
    return true
  end
  if param_name == 'name' then
    return false, 'name parameter must be a string'
  end
  if param == nil then
    return true
  end
  return false, ('%s parameter must be a string or nil'):format(param_name)
end
local _make_item
_make_item = function(name, value, content_type, filename)
  local ok, err = _check_param_type('name', name)
  if not ok then
    return nil, err
  end
  ok, err = _check_value_type(value)
  if not ok then
    return nil, err
  end
  ok, err = _check_param_type('content_type', content_type)
  if not ok then
    return nil, err
  end
  ok, err = _check_param_type('filename', filename)
  if not ok then
    return nil, err
  end
  if filename then
    if not content_type then
      content_type = DEFAULT_CONTENT_TYPE
    end
    return {
      name,
      value,
      content_type,
      filename
    }
  elseif content_type then
    return {
      name,
      value,
      content_type
    }
  end
  return {
    name,
    value
  }
end
local _item_to_value
_item_to_value = function(item)
  return item[2]
end
local _item_to_table
_item_to_table = function(item)
  return {
    name = item[1],
    value = item[2],
    content_type = item[3],
    filename = item[4]
  }
end
local FormData
do
  local _class_0
  local _base_0 = {
    get_boundary = function(self)
      local boundary = self._boundary
      if boundary then
        return boundary
      end
      boundary = ('====FormData=Boundary====%s===='):format(random_hex(16))
      self._boundary = boundary
      return boundary
    end,
    set_boundary = function(self, boundary)
      if self._boundary then
        return false, 'boundary is already set'
      end
      if type(boundary) ~= 'string' or #boundary == 0 or #boundary > 70 then
        return false, 'boundary must be a non-empty string no longer than 70 characters'
      end
      self._boundary = boundary
      return true
    end,
    count = function(self)
      local count = 0
      for _, item_indexes in pairs(self._names) do
        count = count + #item_indexes
      end
      return count
    end,
    get = function(self, name, last, as_table)
      if last == nil then
        last = false
      end
      if as_table == nil then
        as_table = false
      end
      local ok, err = _check_param_type('name', name)
      if not ok then
        return nil, err
      end
      local item_indexes = self._names[name]
      if not item_indexes then
        return nil
      end
      local item_index
      if last then
        item_index = item_indexes[#item_indexes]
      else
        item_index = item_indexes[1]
      end
      local item = self._items[item_index]
      if as_table then
        return _item_to_table(item)
      end
      return _item_to_value(item)
    end,
    get_all = function(self, name, as_table)
      if as_table == nil then
        as_table = false
      end
      local ok, err = _check_param_type('name', name)
      if not ok then
        return nil, err
      end
      local item_indexes = self._names[name]
      if not item_indexes then
        return nil
      end
      local items = self._items
      local extractor
      if as_table then
        extractor = _item_to_table
      else
        extractor = _item_to_value
      end
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #item_indexes do
        local idx = item_indexes[_index_0]
        _accum_0[_len_0] = extractor(items[idx])
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end,
    set = function(self, name, value, content_type, filename)
      local ok, err = self:_check_mutable()
      if not ok then
        return false, err
      end
      local item
      item, err = _make_item(name, value, content_type, filename)
      if not item then
        return false, err
      end
      local item_index
      local old_item_indexes = self._names[name]
      if old_item_indexes then
        for _index_0 = 1, #old_item_indexes do
          local old_item_index = old_item_indexes[_index_0]
          self._items[old_item_index] = nil
        end
        item_index = old_item_indexes[1]
      else
        item_index = self._last_free_item_index
        self._last_free_item_index = item_index + 1
      end
      self._items[item_index] = item
      self._names[name] = {
        item_index
      }
      return true
    end,
    add = function(self, name, value, content_type, filename)
      local ok, err = self:_check_mutable()
      if not ok then
        return false, err
      end
      local item
      item, err = _make_item(name, value, content_type, filename)
      if not item then
        return false, err
      end
      local item_index = self._last_free_item_index
      self._last_free_item_index = item_index + 1
      self._items[item_index] = item
      local item_indexes = self._names[name]
      if item_indexes then
        table_insert(item_indexes, item_index)
      else
        self._names[name] = {
          item_index
        }
      end
      return true
    end,
    delete = function(self, name)
      local ok, err = self:_check_mutable()
      if not ok then
        return nil, err
      end
      ok, err = _check_param_type('name', name)
      if not ok then
        return nil, err
      end
      local item_indexes = self._names[name]
      if not item_indexes then
        return nil
      end
      self._names[name] = nil
      local _max_0 = 1
      for _index_0 = #item_indexes, _max_0 < 0 and #item_indexes + _max_0 or _max_0, -1 do
        local item_index = item_indexes[_index_0]
        self._items[item_index] = nil
        if item_index + 1 == self._last_free_item_index then
          self._last_free_item_index = self._last_free_item_index - 1
        end
      end
      return #item_indexes
    end,
    _check_mutable = function(self)
      if self._iterated then
        return false, 'form-data is already iterated, cannot mutate'
      end
      if self._rendered then
        return false, 'form-data is already rendered, cannot mutate'
      end
      return true
    end,
    render = function(self)
      local rendered = self._rendered
      if rendered then
        return rendered
      end
      if self._iterated then
        return nil, 'form-data is already iterated, cannot render'
      end
      if self:count() == 0 then
        return nil, 'empty form-data'
      end
      local buffer = { }
      self:_render(function(chunk)
        return table_insert(buffer, chunk)
      end)
      rendered = table_concat(buffer)
      self._rendered = rendered
      return rendered
    end,
    iterator = function(self)
      if self._iterated then
        return nil, 'form-data is already iterated, cannot iterate again'
      end
      if self._rendered then
        return nil, 'form-data is already rendered, cannot iterate'
      end
      if self:count() == 0 then
        return nil, 'empty form-data'
      end
      self._iterated = true
      local co = co_wrap(self._render)
      co(self, co_yield, true)
      return co
    end,
    _render = function(self, callback, priming)
      if priming == nil then
        priming = false
      end
      local boundary = self:get_boundary()
      if priming then
        callback(nil)
      end
      local sep = ('--%s'):format(boundary)
      for idx = 1, self._last_free_item_index - 1 do
        local item = self._items[idx]
        if item then
          local name, value, content_type, filename
          name, value, content_type, filename = item[1], item[2], item[3], item[4]
          local chunk = {
            sep
          }
          if filename then
            table_insert(chunk, ('content-disposition: form-data; name="%s"; filename="%s"'):format(name, filename))
          else
            table_insert(chunk, ('content-disposition: form-data; name="%s"'):format(name))
          end
          if content_type then
            table_insert(chunk, ('content-type: %s'):format(content_type))
          end
          if type(value) == 'string' then
            table_insert(chunk, CRLF .. value)
            callback(table_concat(chunk, CRLF) .. CRLF)
          else
            callback(table_concat(chunk, CRLF) .. CRLF .. CRLF)
            for c in value do
              callback(c)
            end
            callback(CRLF)
          end
        end
      end
      return callback(('--%s--%s'):format(boundary, CRLF))
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self._boundary = nil
      self._names = { }
      self._items = { }
      self._last_free_item_index = 1
      self._iterated = false
      self._rendered = nil
    end,
    __base = _base_0,
    __name = "FormData"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  FormData = _class_0
end
return {
  FormData = FormData,
  new = function(...)
    return FormData(...)
  end
}
