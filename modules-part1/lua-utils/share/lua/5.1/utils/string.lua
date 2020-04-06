local _M = {}

function _M.split(text, delimiter)
  if text.find(text, delimiter) == nil then
    return { text }
  end

  local splited_texts = {}
  local last_position

  for splited_text, position in text:gmatch("(.-)"..delimiter.."()") do
    table.insert(splited_texts, splited_text)
    last_position = position
  end
  table.insert(splited_texts, string.sub(text, last_position))
  return splited_texts
end

function _M.split_lines(text)
  local lines = {}
  local function splitter(line)
    table.insert(lines, line)
    return ""
  end
  text:gsub("(.-\r?\n)", splitter)
  return lines
end

function _M.new(self)
  local object = {}
  setmetatable(object, object)
  object.__index = self
  return object
end

return _M
