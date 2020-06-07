--[[
 * Simple parser for a numeric structure consisting of three types:
 *
 *  - number: a double in Java's floating number format
 *  - array: an array of numbers stored as `[v0,v1,...,vn]`
 *  - tuple: a list of numbers, arrays, or tuples stored as `(...)`
--]]

local M = {}

-- Parses a string into a Double, or an Array[Double].
function M.parse(s)
  local StringTokenizer = require 'stuart-ml.util.StringTokenizer'
  local tokenizer = StringTokenizer.new(s, '()[],', true)
  assert(tokenizer:hasMoreTokens())
  local token = tokenizer:nextToken()
  if token == '(' then
    return M.parseTuple(tokenizer)
  elseif token == '[' then
    return M.parseArray(tokenizer)
  else
    return M.parseNumber(token)
  end
end

function M.parseArray(tokenizer)
  local values = {}
  local parsing = true
  local allowComma, token
  while parsing and tokenizer:hasMoreTokens() do
    token = tokenizer:nextToken()
    if token == ']' then
      parsing = false
    elseif token == ',' then
      assert(allowComma, 'Found a "," at a wrong position.')
      allowComma = false
    else
      -- expecting a number
      values[#values+1] = M.parseNumber(token)
      allowComma = true
    end
  end
  assert(not parsing, 'An array must end with "]".')
  return values
end

function M.parseNumber(s)
  while s:sub(1,1) == '+' or s:sub(1,1) == ' ' do s = s:sub(2) end
  local jsonDecode = require 'stuart.util'.jsonDecode
  local n = jsonDecode(s)
  assert(type(n) == 'number')
  return n
end

function M.parseTuple(tokenizer)
  local items = {}
  local parsing = true
  local allowComma = false
  local token
  local function trim(s) return s:match'^%s*(.*%S)' or '' end
  while parsing and tokenizer:hasMoreTokens() do
    token = tokenizer:nextToken()
    if token == '(' then
      items[#items+1] = M.parseTuple(tokenizer)
      allowComma = true
    elseif token == '[' then
      items[#items+1] = M.parseArray(tokenizer)
      allowComma = true
    elseif token == ',' then
      assert(allowComma, 'Found a "," at a wrong position.')
      allowComma = false
    elseif token == ')' then
      parsing = false
    elseif trim(token) ~= '' then -- ignore whitespaces between delim chars, e.g. ', ['
      -- expecting a number
      items[#items+1] = M.parseNumber(token)
      allowComma = true
    end
  end
  assert(not parsing, 'A tuple must end with ")".')
  return items
end

return M
