local tree = require('cirru-parser.tree')
local array = require('cirru-parser.array')
local runParse = nil
local shorten = nil
local parse
parse = function(code, filename)
  local buffer = nil
  local state = {
    name = 'indent',
    x = 1,
    y = 1,
    level = 1,
    indent = 0,
    indented = 0,
    nest = 0,
    path = filename
  }
  local xs = { }
  while (string.len(code)) > 0 do
    do
      local _obj_0 = runParse(xs, buffer, state, code)
      xs, buffer, state, code = _obj_0[1], _obj_0[2], _obj_0[3], _obj_0[4]
    end
  end
  local res = runParse(xs, buffer, state, code)
  res = array.map(res, tree.resolveDollar)
  res = array.map(res, tree.resolveComma)
  return res
end
shorten = function(xs)
  if array.isArray(xs) then
    return array.map(xs, shorten)
  else
    return xs.text
  end
end
local pare
pare = function(code, filename)
  local res = parse(code, filename)
  return shorten(res)
end
local _escape_eof
_escape_eof = function(xs, buffer, state, code)
  return error("EOF in escape state")
end
local _string_eof
_string_eof = function(xs, buffer, state, code)
  return error("EOF in string state")
end
local _space_eof
_space_eof = function(xs, buffer, state, code)
  return xs
end
local _token_eof
_token_eof = function(xs, buffer, state, code)
  buffer.ex = state.x
  buffer.ey = state.y
  xs = tree.appendItem(xs, state.level, buffer)
  buffer = nil
  return xs
end
local _indent_eof
_indent_eof = function(xs, buffer, state, code)
  return xs
end
local _escape_newline
_escape_newline = function(xs, buffer, state, code)
  return error('newline while escape')
end
local _escape_n
_escape_n = function(xs, buffer, state, code)
  state.x = state.x + 1
  buffer.text = buffer.text .. '\n'
  state.name = 'string'
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _escape_t
_escape_t = function(xs, buffer, state, code)
  state.x = state.x + 1
  buffer.text = buffer.text .. '\t'
  state.name = 'string'
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _escape_else
_escape_else = function(xs, buffer, state, code)
  state.x = state.x + 1
  buffer.text = buffer.text .. (string.sub(code, 1, 1))
  state.name = 'string'
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _string_backslash
_string_backslash = function(xs, buffer, state, code)
  state.name = 'escape'
  state.x = state.x + 1
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _string_newline
_string_newline = function(xs, buffer, state, code)
  return error('newline in a string')
end
local _string_quote
_string_quote = function(xs, buffer, state, code)
  state.name = 'token'
  state.x = state.x + 1
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _string_else
_string_else = function(xs, buffer, state, code)
  state.x = state.x + 1
  buffer.text = buffer.text .. (string.sub(code, 1, 1))
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _space_space
_space_space = function(xs, buffer, state, code)
  state.x = state.x + 1
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _space_newline
_space_newline = function(xs, buffer, state, code)
  if state.nest ~= 0 then
    error('incorrect nesting')
  end
  state.name = 'indent'
  state.x = 1
  state.y = state.y + 1
  state.indented = 0
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _space_open
_space_open = function(xs, buffer, state, code)
  local nesting = tree.createNesting(1)
  xs = tree.appendItem(xs, state.level, nesting)
  state.nest = state.nest + 1
  state.level = state.level + 1
  state.x = state.x + 1
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _space_close
_space_close = function(xs, buffer, state, code)
  state.nest = state.nest - 1
  state.level = state.level - 1
  if state.nest < 0 then
    error('close at space')
  end
  state.x = state.x + 1
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _space_quote
_space_quote = function(xs, buffer, state, code)
  state.name = 'string'
  buffer = {
    text = '',
    x = state.x,
    y = state.y,
    path = state.path
  }
  state.x = state.x + 1
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _space_else
_space_else = function(xs, buffer, state, code)
  state.name = 'token'
  buffer = {
    text = string.sub(code, 1, 1),
    x = state.x,
    y = state.y,
    path = state.path
  }
  state.x = state.x + 1
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _token_space
_token_space = function(xs, buffer, state, code)
  state.name = 'space'
  buffer.ex = state.x
  buffer.ey = state.y
  xs = tree.appendItem(xs, state.level, buffer)
  state.x = state.x + 1
  buffer = nil
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _token_newline
_token_newline = function(xs, buffer, state, code)
  state.name = 'indent'
  buffer.ex = state.x
  buffer.ey = state.y
  xs = tree.appendItem(xs, state.level, buffer)
  state.indented = 0
  state.x = 1
  state.y = state.y + 1
  buffer = nil
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _token_open
_token_open = function(xs, buffer, state, code)
  return error('open parenthesis in token')
end
local _token_close
_token_close = function(xs, buffer, state, code)
  state.name = 'space'
  buffer.ex = state.x
  buffer.ey = state.y
  xs = tree.appendItem(xs, state.level, buffer)
  buffer = nil
  return {
    xs,
    buffer,
    state,
    code
  }
end
local _token_quote
_token_quote = function(xs, buffer, state, code)
  state.name = 'string'
  state.x = state.x + 1
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _token_else
_token_else = function(xs, buffer, state, code)
  buffer.text = buffer.text .. (string.sub(code, 1, 1))
  state.x = state.x + 1
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _indent_space
_indent_space = function(xs, buffer, state, code)
  state.indented = state.indented + 1
  state.x = state.x + 1
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _indent_newilne
_indent_newilne = function(xs, buffer, state, code)
  state.x = 1
  state.y = state.y + 1
  state.indented = 0
  return {
    xs,
    buffer,
    state,
    (string.sub(code, 2))
  }
end
local _indent_close
_indent_close = function(xs, buffer, state, code)
  return error('close parenthesis at indent')
end
local _indent_else
_indent_else = function(xs, buffer, state, code)
  state.name = 'space'
  if math.fmod(state.indented, 2) == 1 then
    error('odd indentation')
  end
  local indented = state.indented / 2
  local diff = indented - state.indent
  if diff <= 0 then
    local nesting = tree.createNesting(1)
    xs = tree.appendItem(xs, (state.level + diff - 1), nesting)
  else
    if diff > 0 then
      local nesting = tree.createNesting(diff)
      xs = tree.appendItem(xs, state.level, nesting)
    end
  end
  state.level = state.level + diff
  state.indent = indented
  return {
    xs,
    buffer,
    state,
    code
  }
end
runParse = function(xs, buffer, state, code)
  local eof = (string.len(code)) == 0
  local char = string.sub(code, 1, 1)
  local _exp_0 = state.name
  if 'escape' == _exp_0 then
    if eof then
      return _escape_eof(xs, buffer, state, code)
    else
      local _exp_1 = char
      if '\n' == _exp_1 then
        return _escape_newline(xs, buffer, state, code)
      elseif 'n' == _exp_1 then
        return _escape_n(xs, buffer, state, code)
      elseif 't' == _exp_1 then
        return _escape_t(xs, buffer, state, code)
      else
        return _escape_else(xs, buffer, state, code)
      end
    end
  elseif 'string' == _exp_0 then
    if eof then
      return _string_eof(xs, buffer, state, code)
    else
      local _exp_1 = char
      if '\\' == _exp_1 then
        return _string_backslash(xs, buffer, state, code)
      elseif '\n' == _exp_1 then
        return _string_newline(xs, buffer, state, code)
      elseif '"' == _exp_1 then
        return _string_quote(xs, buffer, state, code)
      else
        return _string_else(xs, buffer, state, code)
      end
    end
  elseif 'space' == _exp_0 then
    if eof then
      return _space_eof(xs, buffer, state, code)
    else
      local _exp_1 = char
      if ' ' == _exp_1 then
        return _space_space(xs, buffer, state, code)
      elseif '\n' == _exp_1 then
        return _space_newline(xs, buffer, state, code)
      elseif '(' == _exp_1 then
        return _space_open(xs, buffer, state, code)
      elseif ')' == _exp_1 then
        return _space_close(xs, buffer, state, code)
      elseif '"' == _exp_1 then
        return _space_quote(xs, buffer, state, code)
      else
        return _space_else(xs, buffer, state, code)
      end
    end
  elseif 'token' == _exp_0 then
    if eof then
      return _token_eof(xs, buffer, state, code)
    else
      local _exp_1 = char
      if ' ' == _exp_1 then
        return _token_space(xs, buffer, state, code)
      elseif '\n' == _exp_1 then
        return _token_newline(xs, buffer, state, code)
      elseif '(' == _exp_1 then
        return _token_open(xs, buffer, state, code)
      elseif ')' == _exp_1 then
        return _token_close(xs, buffer, state, code)
      elseif '"' == _exp_1 then
        return _token_quote(xs, buffer, state, code)
      else
        return _token_else(xs, buffer, state, code)
      end
    end
  elseif 'indent' == _exp_0 then
    if eof then
      return _indent_eof(xs, buffer, state, code)
    else
      local _exp_1 = char
      if ' ' == _exp_1 then
        return _indent_space(xs, buffer, state, code)
      elseif '\n' == _exp_1 then
        return _indent_newilne(xs, buffer, state, code)
      elseif ')' == _exp_1 then
        return _indent_close(xs, buffer, state, code)
      else
        return _indent_else(xs, buffer, state, code)
      end
    end
  end
end
return {
  parse = parse,
  pare = pare
}
