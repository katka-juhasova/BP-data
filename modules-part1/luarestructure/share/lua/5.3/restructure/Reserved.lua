local utils = require('restructure.utils')
local vstruct = require('vstruct') -- FIXME avoid exposing buffer internals.

local Reserved = {}
Reserved.__index = Reserved

function Reserved.new(type, count)
  local b = setmetatable({}, Reserved)
  b.type = type
  b.count = count or 1
  return b
end

function Reserved:decode(stream, parent)
  vstruct.read("x"..self:size(nil, parent), stream.buffer, {})
  return nil
end

function Reserved:size(_, parent)
  local count = utils.resolveLength(self.count, nil, parent)
  return self.type:size() * count
end

function Reserved:encode(stream, val, parent)
  stream:fill(0, self:size(val, parent))
end

return Reserved