-- lerror | 15.07.2018
-- By daelvn
-- Errors and Exceptions for default Lua errors

--# Namespace #--
local lua = {}

--# Libraries #--
local lobject = require "lobject"
local Class   = lobject.class

--# Errors & Exceptions #--
lua.Error     = Class "LuaError" (function (argl) return {err=argl.err} end)
lua.Exception = Class "LuaException" (function (argl) return {err=argl.err} end)

--# pcall #--
function lua.pcall (f)
  local ok,err = pcall (f)
  if not ok and type (err) == "string" then
    return ok,{lerror=true,mode="raise",kind="exception",e=lua.Exception:new {err=err}}
  end
  return ok,err
end

--# Return #--
return lua
