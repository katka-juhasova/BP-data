local M = {}

local error = error
local ipairs = ipairs
local load = load
local pairs = pairs
local type = type

local math_type = math.type
local table_concat = table.concat

local _ENV = M

local function has_mixed_types(t)
  local seen, n = {}, 0
  for _, v in ipairs(t) do
    if not seen[type(v)] then
      seen[type(v)] = true
      n = n + 1
    end
  end
  return n > 1
end

local function nicify_expected(expected)
  local t = {}
  for x in expected:gmatch('([^|]+)') do
    local y = x:match('[*+]$')
    if y then
      t[#t + 1] = '{' .. x .. '}'
    else
      t[#t + 1] = x
    end
  end
  return table_concat(t, ' or ')
end

local function nicify_value(v)
  if type(v) == 'table' then
    if #v == 0 then
      return '{}'
    elseif has_mixed_types(v) then
      return '{...mixed}'
    else
      return '{' .. type(v[0]) .. '+}'
    end
  end
  return type(v)
end

local function validate_table(t, expected, min_size)
  if #t < min_size then
    return false
  end
  if expected == 'any' then
    return true
  end
  for _, v in ipairs(t) do
    if type(v) ~= expected then
      return false
    end
  end
  return true
end

local CompileCache = {}
local CompileEnv = {
  math_type = math_type,
  nicify_value = nicify_value,
  type = type,
  validate_table = validate_table
}

local function noop()
end

local function compile(expected)
  local buf = {}
  buf[#buf + 1] = ('return function(v) -- %s'):format(expected)
  for x in expected:gmatch('([^|]+)') do
    local n, f = x:match('^(%a+)([*+]?)')
    if f == '+' then
      buf[#buf + 1] = ('if validate_table(v, %q, 1) then return end'):format(n)
    elseif f == '*' then
      buf[#buf + 1] = ('if validate_table(v, %q, 0) then return end'):format(n)
    elseif n == 'integer' then
      buf[#buf + 1] = ('if math_type(v) == %q then return end'):format(n)
    elseif n == 'any' then
      return noop
    else
      buf[#buf + 1] = ('if type(v) == %q then return end'):format(n)
    end
  end
  buf[#buf + 1] = ("return ('expected %s, got %%s'):format(nicify_value(v))"):format(nicify_expected(expected))
  buf[#buf + 1] = 'end'
  return load(table_concat(buf, '\n'), expected, 't', CompileEnv)()
end

local function validate_value(v, expected)
  if type(expected) == 'function' then
    return expected(v)
  end
  if not CompileCache[expected] then
    CompileCache[expected] = compile(expected)
  end
  return CompileCache[expected](v)
end

function validate(t, schema)
  if type(schema) == 'string' then
    local err = validate_value(t, schema)
    if err then
      error(("bad value (%s)"):format(err))
    end
  else
    for k, expected in pairs(schema) do
      local err = validate_value(t[k], expected)
      if err then
        error(("bad property '%s' (%s)"):format(k, err))
      end
    end
  end
end

return M
