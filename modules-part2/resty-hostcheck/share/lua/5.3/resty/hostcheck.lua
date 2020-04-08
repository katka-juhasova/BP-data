local dns = require("resty.hostcheck.dns")
local resolve
resolve = dns.resolve
local HostCheck
do
  local _class_0
  local _base_0 = {
    oneip = function(self, host, ip)
      if ip == nil then
        ip = nil
      end
      ip = ip or self.options.ip
      local answers, err = resolve(host, self.options.nameservers)
      if not answers then
        return nil, error("failed to resolve dns: " .. (err or "unknown"))
      end
      for _index_0 = 1, #answers do
        local item = answers[_index_0]
        if (item == ip) then
          return item
        end
      end
      return nil, answers
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      opts = opts or { }
      local defOpts = {
        ip = "127.0.0.1",
        nameservers = {
          "127.0.0.1"
        }
      }
      opts.ip = opts.ip or defOpts.ip
      opts.nameservers = opts.nameservers or defOpts.nameservers
      self.options = opts
    end,
    __base = _base_0,
    __name = "HostCheck"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  HostCheck = _class_0
end
return HostCheck
