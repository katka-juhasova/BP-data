local json = require "dkjson"

local function time()
  return os.date "%Y-%m-%dT%H:%M:%S"
end

local function quote(value)
  if string.find(value, " ") then
    return string.format("%q", value)
  end

  return value
end

local LogfmtFormatter = {}

function LogfmtFormatter:format(tbl)
  local message = "time=\"" .. time() .. "\" "
  for k, v in pairs(tbl) do
    message = message .. k .. "=" .. quote(v) .. " "
  end

  return message
end

function LogfmtFormatter:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  return o
end

local JSONFormatter = {}

function JSONFormatter:format(tbl)
  tbl["time"] = time()

  return json.encode(tbl)
end

function JSONFormatter:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  return o
end

local Logger = {}

function Logger:err(err, ...)
  self:log({err = err}, ...)
end

function Logger:log(...)
  local result = {}
  local args = table.pack(...)

  for i=1, args.n do
    if type(args[i]) == "table" then
      for k, v in pairs(args[i]) do
        result[tostring(k)] = tostring(v)
      end
    end
  end

  local message = self.formatter:format(result)
  for _, v in pairs(self.filters) do
    if v(message) ~= nil then
      return
    end
  end
end

function Logger:new(o)
  if o == nil then
    o = {}
  end
  
  if o.formatter == nil then
    o.formatter = LogfmtFormatter:new()
  end
  
  if o.filters == nil then
    o.filters = {print}
  end
  
  setmetatable(o, self)
  self.__index = self
  return o
end

local default_logger = Logger:new()
local function log(...)
  default_logger:log(...)
end

local function err(why, ...)
  default_logger:err(why, ...)
end

return {
  default_logger = default_logger,
  Logger = Logger,
  LogfmtFormatter = LogfmtFormatter,
  JSONFormatter = JSONFormatter,
  log = log,
  err = err,
}
