local socket = require('socket')
local json = require('dkjson')

local zabbix_sender = {
  _VERSION      = '0.1.0-0',
  _DESCRIPTION  = 'A zabbix sender protocol implementation in Lua.',
  _URL          = 'https://git.kokolor.es/imo/lua-zabbix-sender',
  _LICENCE      = 'MIT'
}

-- protocol + flag
local ZHEAD = 'ZBXD\x01'

--- Privat helper functions

-- returns nanoseconds / I dunno how precise this is
local function _get_time()
  local time = socket.gettime()

  return math.floor(time), math.floor(( time % 1 ) * 1000 * 1000000 )
end

-- creates the payload as described in the docs
-- https://www.zabbix.com/documentation/4.0/manual/appendix/protocols/header_datalen
local function _build_payload(items, with_ns)
  local time, ns = _get_time()
  local data = {
    request = 'sender data',
    data = items,
    clock = time
  }

  if with_ns then
    data.ns = ns
  end

  local jdata = json.encode(data)

  return ZHEAD .. string.pack('<L', jdata:len()) .. jdata
end

-- parses the JSON response and returns only the data from then
-- info string
local function _parse_response_data(resp)
  local resp_info = {}

  local ok, data = pcall(json.decode, resp)
  if not ok then
    return ok, data
  end

  data.info:gsub('(%w+):%s(%d+);', function(k, v)
    resp_info[k] = tonumber(v)
  end)

  return resp_info
end

-- receives the response from the server
local function _receive_response(conn)
  -- TODO: maybe just use *a, because according to the docs the server
  -- closes the connection after it sent the status back
  local resp_head, err = conn:receive(13)

  if not resp_head then
    return false, err
  elseif not resp_head:find('^' .. ZHEAD) or resp_head:len() ~= 13 then
    return false, 'Got invalid response from server'
  end

  local resp_data_len = string.unpack('<L', resp_head:sub(6))
  local resp_data = conn:receive(resp_data_len)

  return _parse_response_data(resp_data)
end


--- Main methods

local ZabbixSender = {}

function ZabbixSender:add_item(key, value, mhost)
  assert(key and value, 'Needs at least two arguments - key and value')
  mhost = mhost or self.monitored_host
  assert(mhost, 'No monitored host was given and no fallback was set')

  local time, ns = _get_time()
  local item = {
    key = key,
    value = value,
    host = mhost,
    clock = time
  }

  if self.with_ns then
    item.ns = ns
  end

  table.insert(self.items, item)

  return self
end

function ZabbixSender:clear()
  self.items = {}
end

function ZabbixSender:has_unsent_items()
  local count = #self.items
  return count ~= 0, count
end

function ZabbixSender:send()
  local data = _build_payload(self.items, self.with_ns)
  local conn = assert(socket.connect(self.host, self.port))
  conn:settimeout(2)

  local ok, err = conn:send(data)
  if not ok then
    conn:close()
    return false, err
  end

  local resp, err = _receive_response(conn)
  conn:close()

  if not resp then
    return false, err
  end

  self:clear()
  return resp
end


--- Public functions

function zabbix_sender.new(opts)
  opts = opts or {}
  local self = {
    host = opts.host or 'localhost',
    port = tonumber(opts.port) or 10051,
    monitored_host = opts.monitored_host,
    with_ns = opts.with_ns or false,
    items = {}
  }

  return setmetatable(self, { __index = ZabbixSender })
end

return zabbix_sender
