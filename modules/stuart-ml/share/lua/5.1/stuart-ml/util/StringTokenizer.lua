local class = require 'stuart.class'

local StringTokenizer = class.new()

local function contains(s, c)
  for i=1,#s do
    if s:sub(i,i) == c then return true end
  end
  return false
end

function StringTokenizer:_init(str, delims, returnDelims)
  self.str = str
  self.delims = delims or '\t\n\r\f'
  self.returnDelims = not not returnDelims
  self.pos = 1
end

function StringTokenizer:hasMoreTokens()
  if self.pos > #self.str then return false end
  if self.returnDelims then
    return true
  else
    for i=self.pos, #self.str do
      local c = self.str:sub(i,i)
      if not contains(self.delims, c) then return true end
    end
    return false
  end
end

function StringTokenizer:nextToken()
  if self.returnDelims then return self:_nextTokenOrDelim() end
  local token = ''
  for i=self.pos, #self.str do
    self.pos = self.pos + 1
    local c = self.str:sub(i,i)
    if contains(self.delims, c) then
      if #token > 0 then
        return token
      end
    else
      token = token .. c
    end
  end
  if #token == 0 then error('no next element') end
  return token
end

function StringTokenizer:_nextTokenOrDelim()
  local token = ''
  for i=self.pos, #self.str do
    local c = self.str:sub(i,i)
    if contains(self.delims, c) then
      if #token == 0 then
        self.pos = self.pos + 1
        return c
      else
        return token
      end
    else
      token = token .. c
      self.pos = self.pos + 1
    end
  end
  if #token == 0 then error('no next element') end
  return token
end

return StringTokenizer
