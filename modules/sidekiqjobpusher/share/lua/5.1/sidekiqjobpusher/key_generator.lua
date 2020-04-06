local KeyGenerator
do
  local _base_0 = {
    generate = function(queue, namespace)
      if namespace then
        return namespace .. ':queue:' .. queue
      else
        return 'queue:' .. queue
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "KeyGenerator"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  KeyGenerator = _class_0
  return _class_0
end
