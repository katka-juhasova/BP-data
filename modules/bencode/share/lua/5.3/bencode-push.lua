local M = {}

M.decoder = function (callbacks)
  local pos, level = 1, 0
  local s, machine, emb_any
  local str_length = 0

  local function to_state(f)
    machine = f
    return machine()
  end

  local accum_number = 0
  local function emb_int()
    if pos > #s then return end
    local ch = s:sub(pos, pos)
    pos = pos + 1
    if ch == 'e' then
      callbacks.push_number(level, accum_number)
      accum_number = 0
      return to_state(emb_any);
    end
    accum_number = 10*accum_number + ch:byte() - 48 --tonumber(ch)
    return emb_int()
  end

  local function emb_str ()
    if pos > #s then return end
    if str_length > #s-pos+1 then
      local fragment = s:sub(pos, -1)
      callbacks.push_string_fragment(level, fragment)
      str_length = str_length - #fragment
      pos = #s+1
      return emb_str()
    else
      callbacks.push_string_fragment(level, s:sub(pos, pos+str_length-1)) 
      callbacks.push_string_fragment(level, nil)
      pos = pos + str_length
      return to_state(emb_any)
    end
  end

  local function emb_len()
    if pos > #s then return end
    local ch = s:sub(pos, pos)
    pos = pos + 1
    if ch == ':' then
      callbacks.push_string_len(level, str_length)
      return to_state(emb_str)
    end
    str_length = 10*str_length + ch:byte() - 48 --tonumber(ch)
    return emb_len()
  end

  local function emb_list ()
    callbacks.push_list(level)
    level = level + 1
    return to_state(emb_any)
  end

  local function emb_dict ()
    callbacks.push_dict(level)
    level = level + 1
    return to_state(emb_any)
  end

  emb_any = function ()
    if pos > #s then return end
    local ch = s:sub(pos, pos)
    
    if ch == 'i' then
      pos = pos + 1
      return to_state(emb_int)
    elseif ch == 'd' then
      pos = pos + 1
      return to_state(emb_dict)
    elseif ch == 'l' then
      pos = pos + 1
      return to_state(emb_list)
    elseif ch == 'e' then
      pos, level = pos + 1, level - 1
      callbacks.push_pop(level)
      return to_state(emb_any)
    elseif ch>='0' and ch<='9' then
      str_length = 0
      return to_state(emb_len)
    end
    error() --TODO
  end

  machine = emb_any

  return function (in_s)
    s, pos = in_s, 1
    return machine(callbacks)
  end
end

M.encoder = function (callback)
  local depth = 0
  return {
    push_number = function (n)
      callback('i')
      callback(tostring(n))
      callback('e')
    end,
    push_dict = function ()
      depth = depth + 1
      callback('d')
    end,
    push_list = function ()
      depth = depth + 1
      callback('l')
    end,
    push_string = function (s)
      callback(tostring(#s))
      callback(':')
      callback(tostring(s))
    end,
    push_string_length = function (n)
      callback(tostring(n))
      callback(':')
    end,
    push_string_fragment = function (s)
      callback(s)
    end,
    pop = function ()
      assert(depth > 0, "pop from empty table")
      depth = depth - 1
      callback('e')
    end,
    depth = function()
      return depth
    end
  }  
end

return M

