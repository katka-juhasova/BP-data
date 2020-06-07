local Bitfield = {}
Bitfield.__index = Bitfield

function Bitfield.new(type, flags)
  local b = setmetatable({}, Bitfield)
  b.type = type
  b.flags = flags or {}
  return b
end

function Bitfield:decode(stream)
  local val = self.type:decode(stream)
  local res = {}
  for i, flag in ipairs(self.flags) do
    if flag then
      local v = bit32.band(val, bit32.lshift(1, i - 1))
      if v == 0 then res[flag] = false else res[flag] = true end
    end
  end

  return res
end

function Bitfield:size()
  return self.type:size()
end

function Bitfield:encode(stream, keys)
  local val = 0
  for i,flag in ipairs(self.flags) do
    if flag and keys[flag] then
      val = bit32.bor(val, bit32.lshift(1,i - 1))
    end
  end
  self.type:encode(stream, val)
end

return Bitfield
