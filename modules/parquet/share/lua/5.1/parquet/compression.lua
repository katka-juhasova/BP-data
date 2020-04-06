local PARQUET_COMPRESSION_METHODS = {
  ['UNCOMPRESSED']= {
    deflate = function(value) return value end,
    inflate = function(value) return value end
  }
}

local function deflate(method, value)
  local x = PARQUET_COMPRESSION_METHODS[method]
  assert(x ~= nil, 'unsupported compression method: ' .. method)
  return x.deflate(value)
end

local function inflate(method, value)
  local x = PARQUET_COMPRESSION_METHODS[method]
  assert(x ~= nil, 'unsupported compression method: ' .. method)
  return x.inflate(value)
end

local function register(method, deflateFn, inflateFn)
  PARQUET_COMPRESSION_METHODS[method] = {deflate=deflateFn, inflate=inflateFn}
end

local M = {
  PARQUET_COMPRESSION_METHODS = PARQUET_COMPRESSION_METHODS,
  deflate = deflate,
  inflate = inflate,
  register = register
}

return M
