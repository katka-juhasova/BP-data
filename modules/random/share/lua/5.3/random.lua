local random = math.random
local _seed = nil
local version = "1.1-0"

local function seed(value)
  if value == nil then
    return _seed
  end
  _seed = value
  math.randomseed(_seed)
  return _seed
end

local function choice(sequence)
  local seq_type = type(sequence)
  if seq_type == "number" then
    return random(sequence)
  elseif seq_type == "string" or seq_type == "table" then
    local r_index = random(#sequence)
    return sequence[r_index], r_index
  else
    error "`choice` requires parameter to be an iterable sequence."
  end
end

local function shuffle(sequence)
  local seq_type = type(sequence)
  if seq_type ~= "table" then
    error "Invalid sequence provided to `shuffle`."
  end
  local size = #sequence
  for idx = size, 1, -1 do
    local r_index = random(idx)
    sequence[idx], sequence[r_index] = sequence[r_index], sequence[idx]
  end
  return sequence
end

local function choices(sequence)
  local routine = coroutine.create(function ()
      while true do
        local r_index = random(#sequence)
        coroutine.yield(sequence[r_index], r_index)
      end
  end)
  return function ()
    local code, result = coroutine.resume(routine)
    return result
  end
end

local function sample(sequence, size, replace)
  local length = #sequence
  if replace == nil then
    replace = false
  end
  assert((size <= length and size >= 0) or replace, "The sample size was larger than population.")
  local result, pool = {}, {}
  for i = 1, size do
    local idx
    repeat
      idx = random(length)
    until (replace == true or pool[idx] == nil)
    result[i] = sequence[idx]
    pool[idx] = true
  end
  return result
end

return {
  _VERSION = version,
  seed = seed,
  choice = choice,
  shuffle = shuffle,
  choices = choices,
  sample = sample
}
