--- @module ldk.cli.reader
local M = {}

local Trues = {
  ['t'] = true,
  ['1'] = true,
  ['true'] = true,
  ['yes'] = true,
  ['on'] = true
}

local Falses = {
  ['f'] = false,
  ['0'] = false,
  ['false'] = false,
  ['no'] = false,
  ['off'] = false
}

local error = error
local tonumber = tonumber
local math_type = math.type

local _ENV = M

local builtin_readers = {}
local custom_readers = {}
local cached_readers = {}

local function add_reader(t, typename, requires_arg, read)
  for k in typename:gmatch('(%S+)') do
    t[k] = {read = read, requires_arg = requires_arg, type = 'single'}
  end
end

add_reader(builtin_readers, 'nil', false, function()
  return true
end)

add_reader(builtin_readers, 'string s', true, function(s)
  return s
end)

add_reader(builtin_readers, 'char c', true, function(s)
  if #s == 1 then
    return s
  end
  return nil, ("invalid char: '%s'"):format(s)
end)

add_reader(builtin_readers, 'number n float f', true, function(s)
  local v = tonumber(s)
  if v then
    return v
  end
  return nil, ("invalid number: '%s'"):format(s)
end)

add_reader(builtin_readers, 'integer int i', true, function(s)
  local v = tonumber(s)
  if v and math_type(v) == 'integer' then
    return v
  end
  return nil, ("invalid integer: '%s'"):format(s)
end)

add_reader(builtin_readers, 'boolean bool b', true, function(s)
  s = s:lower()
  local v = Trues[s] or Falses[s]
  if v ~= nil then
    return v
  end
  return nil, ("invalid boolean: '%s'"):format(s)
end)

local function get_reader(typename)
  return custom_readers[typename] or builtin_readers[typename]
end

local function check_type(typename)
  if get_reader(typename) then
    return typename
  end
  return error('invalid type: ' .. typename)
end

local function parse_tuple_type(typename)
  local key_type, value_type = typename:match('^(%w+)=(%w+)$')
  if key_type then
    key_type = check_type(key_type)
    value_type = check_type(value_type)
    return {key_type, value_type}
  end
end

--- parses a flag's type.
-- `t1=t2` defines a key-value pair
-- `{t1=t2}` defines a map
-- `[t]` defines a list
local function parse_type(typename)
  local component_type = typename:match('^{([^{}]+)}$')
  if component_type then
    local value_type = parse_tuple_type(component_type)
    if value_type then
      return 'map', value_type
    end
  else
    component_type = typename:match('^%[([^%[%]]+)%]$')
    if component_type then
      local value_type = parse_tuple_type(component_type)
      if value_type then
        return 'tuple-list', value_type
      end
      value_type = check_type(component_type)
      return 'list', value_type
    else
      local value_type = parse_tuple_type(typename)
      if value_type then
        return 'tuple', value_type
      end
      value_type = check_type(typename)
      return 'single', value_type
    end
  end
end

local function create_tuple_reader(value_type)
  local reader1 = create(value_type[1])
  if not reader1.requires_arg then
    return
  end
  local reader2 = create(value_type[2])
  if not reader2.requires_arg then
    return
  end
  return function(s)
    local k, v = s:match('^([^=]+)=([^=]+)$')
    if k then
      local err, v1, v2
      v1, err = reader1.read(k)
      if err then
        return nil, err
      end
      v2, err = reader2.read(v)
      if err then
        return nil, err
      end
      return {v1, v2}
    end
    return nil, ("not a tuple: '%s'"):format(s)
  end
end

local function create_map_reader(value_type)
  local read = create_tuple_reader(value_type)
  if read then
    return function(s)
      local result = {}
      for arg in s:gmatch('([^,]+)') do
        local kv, err = read(arg)
        if err then
          return nil, err
        end
        result[kv[1]] = kv[2]
      end
      return result
    end
  end
end

local function create_list_reader(value_type)
  local reader = create(value_type)
  if reader.requires_arg then
    return function(s)
      local result = {}
      for arg in s:gmatch('([^,]+)') do
        local v, err = reader.read(arg)
        if err then
          return nil, err
        end
        result[#result + 1] = v
      end
      return result
    end
  end
end

local function create_tuple_list_reader(value_type)
  local read = create_tuple_reader(value_type)
  if read then
    return function(s)
      local result = {}
      for arg in s:gmatch('([^,]+)') do
        local v, err = read(arg)
        if err then
          return nil, err
        end
        result[#result + 1] = v
      end
      return result
    end
  end
end

function create(typename)
  if cached_readers[typename] then
    return cached_readers[typename]
  end
  local reader
  local reader_type, value_type = parse_type(typename)
  if reader_type == 'single' then
    reader = get_reader(value_type)
  else
    local read
    if reader_type == 'list' then
      read = create_list_reader(value_type)
    elseif reader_type == 'tuple-list' then
      read = create_tuple_list_reader(value_type)
    elseif reader_type == 'map' then
      read = create_map_reader(value_type)
    elseif reader_type == 'tuple' then
      read = create_tuple_reader(value_type)
    end
    if read then
      reader = {read = read, requires_arg = true, type = reader_type}
    end
  end
  if not reader then
    error('invalid type: ' .. typename)
  end
  cached_readers[typename] = reader
  return reader
end

--- Registers a given function as the reader for the specified type.
-- @tparam string typename a space separated list of type names (i.e.: `'integer i'`).
-- @tparam boolean requires_arg whether the reader requires an argument or not.
-- @tparam function read the function used to read a value from the command line (see @{Read}).
function register(typename, requires_arg, read)
  add_reader(custom_readers, typename, requires_arg, read)
end

--- Function Types
-- @section ftypes

--- Represents a function used to convert a string into an option value.
-- @function Read
-- @tparam string s the string to be converted.
-- @return the converted value if the conversion succeeds; otherwise `nil`.
-- @treturn string an error message if the conversion fails; otherwise `nil`.

return M
