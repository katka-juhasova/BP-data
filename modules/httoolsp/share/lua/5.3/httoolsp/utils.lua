local str_byte = string.byte
local str_format = string.format
local str_gsub = string.gsub
local is_empty_table
is_empty_table = function(tbl)
  return next(tbl) == nil
end
local _to_hex_cb
_to_hex_cb = function(c)
  return str_format('%02x', str_byte(c))
end
local to_hex
to_hex = function(bytes)
  local hex = str_gsub(bytes, '.', _to_hex_cb)
  return hex
end
local _get_random_function
_get_random_function = function()
  local ok, mod = pcall(require, 'resty.random')
  if ok and mod.bytes then
    return mod.bytes
  end
  ok, mod = pcall(require, 'digest')
  if ok and mod.urandom then
    return mod.urandom
  end
  local str_char = string.char
  local math_random = math.random
  return function(length)
    local t = { }
    for n = 1, length do
      t[n] = str_char(math_random(1, 255))
    end
    return table.concat(t)
  end
end
local random_bytes = _get_random_function()
local random_hex
random_hex = function(length)
  return to_hex(random_bytes(length))
end
return {
  is_empty_table = is_empty_table,
  to_hex = to_hex,
  random_bytes = random_bytes,
  random_hex = random_hex
}
