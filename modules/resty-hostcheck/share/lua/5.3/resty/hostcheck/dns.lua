local resolver = require("resty.dns.resolver")
local lrucache = require("resty.lrucache")
local CACHE_SIZE = 10000
local MAXIMUM_TTL_VALUE = 2147483647
local cache, err = lrucache.new(CACHE_SIZE)
if (not cache) then
  return nil, error("failed to create the cache: " .. (err or "unknown"))
end
local a_records_and_max_ttl, resolve
a_records_and_max_ttl = function(answers)
  local addresses = { }
  local ttl = MAXIMUM_TTL_VALUE
  for _, ans in ipairs(answers) do
    if ans.address then
      table.insert(addresses, ans.address)
      if ttl > ans.ttl then
        ttl = ans.ttl
      end
    end
  end
  table.sort(addresses)
  return addresses, ttl
end
resolve = function(host, nameservers)
  if nameservers == nil then
    nameservers = nil
  end
  if (nameservers == nil) then
    nameservers = {
      "127.0.0.1"
    }
  end
  local cached_addresses = cache:get(host)
  if cached_addresses then
    local message = string.format("addresses %s for host %s was resolved from cache", table.concat(cached_addresses, ", "), host)
    ngx.log(ngx.INFO, message)
    return cached_addresses
  end
  local r
  r, err = resolver:new({
    nameservers = nameservers
  }, {
    retrans = 5
  }, {
    timeout = 2000
  })
  if not r then
    ngx.log(ngx.ERR, "failed to instantiate the resolver: " .. tostring(err))
    return nil, {
      host
    }
  end
  local answers
  answers, err = r:query(host, {
    qtype = r.TYPE_A
  }, { })
  if not answers then
    ngx.log(ngx.ERR, "failed to query the DNS server: " .. tostring(err))
    return nil, {
      host
    }
  end
  if answers.errcode then
    ngx.log(ngx.ERR, string.format("server returned error code: %s: %s", answers.errcode, answers.errstr))
    return nil, {
      host
    }
  end
  local addresses, ttl = a_records_and_max_ttl(answers)
  if #addresses == 0 then
    ngx.log(ngx.ERR, "no A record resolved")
    return nil, {
      host
    }
  end
  cache:set(host, addresses, ttl)
  return addresses
end
return {
  resolve = resolve
}
