local math = require "math"

local u = {}

--------------------------------------------------------------------------------
-- Numbers
--------------------------------------------------------------------------------

--- Return random number
-- @param {Number} [lower=0]              The lower bound.
-- @param {Number} [upper=1]              The upper bound.
-- @param {Boolean} [floating=false]      Specify returning a floating-point number.
--
-- @return {Number}  Returns the random number.
function u.random(...)
  local args_count = select("#", ...)
  local lower     = select(1, ...)
  local upper     = select(2, ...)
  local floating  = select(3, ...)

  if args_count == 1 then
    upper = lower
    lower = nil
  end

  if lower == nil then lower = 0 end
  if upper == nil then upper = 1 end
  if floating == nil then floating = false end

  if not u.is_integer(lower) or not u.is_integer(upper) then floating = true end

  -- Swap values when lover > upper
  if lower > upper then
    lower, upper = upper, lower
  end

  if floating then
    return math.min(lower + math.random() * (upper - lower), upper)
  else
    return math.random(lower, upper)
  end
end

--- Checks if value is an integer.
-- @param {Number} value                The value to check.
--
-- @return {Boolean}  Returns true if value is an integer, else false.
function u.is_integer(value)
  if type(value) ~= "number" then
    return false
  end

  return value % 1 == 0
end

--------------------------------------------------------------------------------
-- Strings
--------------------------------------------------------------------------------

--- Splits string into an array of strings
-- @param {String} str              The string to split.
-- @param {String} [separator]      The character to use for separating the string.
--
-- @return {String[]}  Returns the array of strings.
function u.split(str, separator)
  local parts = {}
  local start = 1
  local finded = 1

  if separator and separator ~= "" then
    while finded do
      finded = str:find(separator, start)
      if finded then
        table.insert(parts, str:sub(start, finded - 1))
        start = finded + #separator
      else
        table.insert(parts, str:sub(start))
      end
    end
  else
    for i = 1, #str do
      table.insert(parts, str:sub(i, i))
    end
  end

  return parts
end

--------------------------------------------------------------------------------
-- Tables
--------------------------------------------------------------------------------

--- Checks if value is an array.
-- @param {Any} value              The string to split.
--
-- @return {Boolean}  Returns true if value is an array, else false.
function u.is_array(value)
  if type(value) ~= "table" then
    return false
  end

  for k, v in pairs(value) do
    if type(k) ~= "number" then
      return false
    end
  end

  return true
end

--- Merge two or more arrays into one
-- @param {Any[]} main_array        The destination array
-- @param {...Any[]}                The source arrays
--
-- @return {Any[]}  Returns array
function u.merge_arrays(main_array, ...)
  -- Walk arrays
  for i = 1, select("#", ...) do
    local arr = select(i, ...)

    -- Walk values of source array
    for k, v in pairs(arr) do
      table.insert(main_array, v)
    end
  end

  return main_array
end

--- Merge two or more object into one
-- @param {Object} main_object       The destination object
-- @param {...Object}                The source objects
--
-- @return {Object}  Returns object
function u.merge_objects(main_object, ...)
  -- Walk objects
  for i = 1, select("#", ...) do
    local obj = select(i, ...)

    -- Walk values of source object
    for k, v in pairs(obj) do
      if type(v) == "table" and main_object[k] ~= nil then
        main_object[k] = u.merge(main_object[k], v)
      else
        main_object[k] = v
      end
    end
  end

  return main_object
end

--- Merge two or more tables into one
-- @param {Table} main_table       The destination table
-- @param {...Table}               The source tables
--
-- @return {Table}  Returns table
function u.merge(main_table, ...)
  local is_arr = true

  -- Finding object argument
  if not u.is_array(main_table) then
    is_arr = false
  else
    for i = 1, select("#", ...) do
      local t = select(i, ...)

      if not u.is_array(t) then
        is_arr = false
        break
      end
    end
  end

  if is_arr then
    return u.merge_arrays(main_table, ...)
  else
    return u.merge_objects(main_table, ...)
  end
end

--- Checks if value includes in a array
-- @param {Any[]} arr              The array to query.
-- @param {Any} value              The value to search for.
--
-- @return {Boolean}  Returns true if value exists, else false.
function u.in_array(arr, value)
  for k, v in ipairs(arr) do
    if v == value then return true end
  end

  return false
end

--- Checks if key includes in a object
-- @param {Object} object          The object to query.
-- @param {String|Number} key      The key to search for.
--
-- @return {Boolean}  Returns true if key exists, else false.
function u.in_object(object, key)
  for k, v in pairs(object) do
    if k == key then return true end
  end

  return false
end

--- Checks if key or value includes in a object or array
-- @param {Object|Any[]} t          The object or array to query.
-- @param {Any} i                   The key or value to search for.
--
-- @return {Boolean}  Returns true if key or value exists, else false.
function u.in_table(t, i)
  if u.is_array(t) then
    return u.in_array(t, i)
  else
    return u.in_object(t, i)
  end
end

return u
