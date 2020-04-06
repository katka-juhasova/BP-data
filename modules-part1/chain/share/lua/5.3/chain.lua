local function get_env(f)
  local level = 1
  repeat
    local name, value = debug.getupvalue(f, level)
    if name == '_ENV' then return value end
    level = level + 1
  until name == nil
end

local function add_to_function_env(f, to_add)
  local f_env = get_env(f)
  if f_env then
    for k, v in pairs(to_add) do
      f_env[k] = v
    end
  end
end

return function(...)
  local frames = {
    { args = table.pack(...) }
  }
  local chain_builder = {}

  return setmetatable(chain_builder, {
    __index = function(_, name)
      return function(...)
        table.insert(frames, { name = name, args = table.pack(...) })
        return chain_builder
      end
    end,

    __call = function(_, f)
      local frame_index
      local env = {}

      local function chained_call(...)
        for i, v in ipairs(frames[frame_index].args) do
          env[v] = select(i, ...)
        end

        if frame_index == #frames then
          add_to_function_env(f, env)
          return f(env)
        else
          frame_index = frame_index + 1
          return {
            [frames[frame_index].name] = chained_call
          }
        end
      end

      return function(...)
        frame_index = 1
        return chained_call(...)
      end
    end
  })
end
