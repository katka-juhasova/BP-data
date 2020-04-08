local copas = require('copas')
local Promise, async, await
local events = { }
do
  local _class_0
  local _base_0 = {
    catch = function(self, fn)
      return self:andThen(nil, fn)
    end,
    andthen = function(self, a, b)
      return self:andThen(a, b)
    end,
    finally = function(self, fn)
      return Promise(function(res, rej)
        local resh
        resh = function(val)
          local ok, err = pcall(fn, val, nil)
          if ok then
            return res(val)
          else
            return rej(err)
          end
        end
        local rejh
        rejh = function(reason)
          local ok, err = pcall(fn, nil, reason)
          if ok then
            return rej(reason)
          else
            return rej(val)
          end
        end
        return self:andThen(resh, rejh)
      end)
    end,
    andThen = function(self, resh, rejh)
      local _res, _rej, _pro
      _pro = Promise(function(res, rej)
        _res, _rej = res, rej
      end)
      if not ('function' == type(resh)) then
        resh = (function(a)
          return a
        end)
      end
      local resfn
      resfn = function(val)
        local ok
        ok, val = pcall(resh, val)
        if ok then
          return _pro:_resolve(val)
        else
          return _pro:_reject(val)
        end
      end
      if self._status == 'resolved' then
        Promise._invoke(function()
          return resfn(self._value)
        end)
      elseif self._status == 'pending' then
        table.insert(self._resolvehandlers, resfn)
      end
      if not ('function' == type(rejh)) then
        rejh = (function(a)
          return error(a)
        end)
      end
      local rejfn
      rejfn = function(reason)
        local ok, val = pcall(rejh, reason)
        if ok then
          return _pro:_resolve(val)
        else
          return _pro:_reject(val)
        end
      end
      if self._status == 'rejected' then
        Promise._invoke(function()
          return rejfn(self._reasson)
        end)
      elseif self._status == 'pending' then
        table.insert(self._rejecthandlers, rejfn)
      end
      if self._status == 'resolved' then
        _pro:_resolve(self._value)
      elseif self._status == 'rejected' then
        _pro:_reject(self._reason)
      end
      return _pro
    end,
    _resolve = function(self, val)
      if self == val then
        error("A Promise can not be resolved with itself")
      end
      if not (self._status == 'pending') then
        return 
      end
      if ('table' == type(val)) and val.__class == Promise then
        if val._status == 'pending' then
          table.insert(val._resolvehandlers, (function()
            local _base_1 = self
            local _fn_0 = _base_1._resolve
            return function(...)
              return _fn_0(_base_1, ...)
            end
          end)())
          return table.insert(val._rejecthandlers, (function()
            local _base_1 = self
            local _fn_0 = _base_1._reject
            return function(...)
              return _fn_0(_base_1, ...)
            end
          end)())
        elseif val._status == 'resolved' then
          return self:_resolve(val._value)
        else
          return self:_reject(val._value)
        end
      end
      if 'table' == type(val) then
        local ok, _then = pcall(function()
          return val.andThen or val.andthen or val['then']
        end)
        if not (ok) then
          return self:_reject(_then)
        end
        if 'function' == type(_then) then
          local err
          ok, err = pcall(function()
            return _then(val, (function()
              local _base_1 = self
              local _fn_0 = _base_1._resolve
              return function(...)
                return _fn_0(_base_1, ...)
              end
            end)(), (function()
              local _base_1 = self
              local _fn_0 = _base_1._reject
              return function(...)
                return _fn_0(_base_1, ...)
              end
            end)())
          end)
          if not (ok) then
            return self:_reject(err)
          end
          return 
        end
      end
      self._status, self._value = 'resolved', val
      local _list_0 = self._resolvehandlers
      for _index_0 = 1, #_list_0 do
        local handler = _list_0[_index_0]
        Promise._invoke(function()
          return handler(val)
        end)
      end
    end,
    _reject = function(self, reason)
      if not (self._status == 'pending') then
        return 
      end
      self._status, self._reason = 'rejected', reason
      local _list_0 = self._rejecthandlers
      for _index_0 = 1, #_list_0 do
        local handler = _list_0[_index_0]
        Promise._invoke(function()
          return handler(reason)
        end)
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, fn)
      self._status = 'pending'
      self._value, self._reason = nil, nil
      self._resolvehandlers, self._rejecthandlers = { }, { }
      if fn then
        return Promise._invoke(function()
          local ok, err = pcall(fn, (function()
            local _base_1 = self
            local _fn_0 = _base_1._resolve
            return function(...)
              return _fn_0(_base_1, ...)
            end
          end)(), (function()
            local _base_1 = self
            local _fn_0 = _base_1._reject
            return function(...)
              return _fn_0(_base_1, ...)
            end
          end)())
          if not (ok) then
            return self:_reject(err)
          end
        end)
      end
    end,
    __base = _base_0,
    __name = "Promise"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self._invoke = function(fn)
    return copas.addthread(function()
      copas.sleep(0)
      return fn()
    end)
  end
  self.resolve = function(val)
    return Promise(function(res, rej)
      return res(val)
    end)
  end
  self.reject = function(reason)
    return Promise(function(res, rej)
      return rej(reason)
    end)
  end
  self.all = function(list)
    local pro = Promise(function(res, rej)
      local waiting = 0
      local resolved = { }
      local values = { }
      for i, pro in ipairs(list) do
        if ('table' == type(pro)) and Promise == pro.__class then
          waiting = waiting + 1
          local resfn
          resfn = function(val)
            if not (resolved[i]) then
              resolved[i] = true
              waiting = waiting - 1
              values[i] = val
              if waiting == 0 then
                return res(values)
              end
            end
          end
          pro:andThen(resfn, rej)
        else
          values[i] = pro
        end
      end
      if waiting == 0 then
        return res(values)
      end
    end)
    if #list == 0 then
      pro._resolve({ })
    end
    return pro
  end
  self.race = function(list)
    return Promise(function(res, rej)
      for _index_0 = 1, #list do
        local pro = list[_index_0]
        pro:andThen(res, rej)
      end
    end)
  end
  Promise = _class_0
end
async = function(fn)
  return function(...)
    local p = Promise()
    local argc, argv = (select('#', ...)), {
      ...
    }
    local unpack = table.unpack or unpack
    copas.addthread(function()
      copas.sleep(0)
      local ok, val = pcall(fn, unpack(argv, 1, argc))
      if ok then
        return p:_resolve(val)
      else
        return p:_reject(val)
      end
    end)
    return p
  end
end
await = function(p)
  local ok, val
  local resfn
  resfn = function(resval)
    ok = true
    val = resval
  end
  local rejfn
  rejfn = function(rejval)
    ok = false
    val = rejval
  end
  (Promise.resolve(p)):andthen(resfn, rejfn)
  while ok == nil do
    copas.sleep(0)
  end
  if ok then
    return val
  else
    return error(val)
  end
end
return {
  Promise = Promise,
  async = async,
  await = await
}
