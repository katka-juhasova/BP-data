local lrandom = require('random')
local os = require('os')

local salt = {}

local c = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

function salt.gen(self, len)
  local r = lrandom.new(os.time())
  local i = 0
  while i < len do
    local p = r(1, #c)
    x = (x or '') .. string.sub(c, p, p)
    i = i + 1
  end
  return x
end

return salt
