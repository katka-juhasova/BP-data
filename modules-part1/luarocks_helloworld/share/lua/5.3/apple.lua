local  print = print

local _M = {}
setfenv (1, _M)

function _M.info ()
  print("apple")
end

return _M
