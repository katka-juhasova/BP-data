local modname = { 'lecho','core' }
local concat = table.concat
local ok, ffi = pcall(require,'ffi')

if not ok then -- we must be in regular Lua, just use normal C module
    return require(concat(modname,'.'))
end

local lecho_lib -- save reference to library/namespace

ffi.cdef[[
int lecho_off(void *userdata);
int lecho_on(void *userdata);
int lecho_get(void *userdata);
int lecho_status(void *userdata);
unsigned int lecho_size(void);
]]

pcall(function()
  if ffi.C.lecho_size then -- we're in a static binary, already linked, etc
      lecho_lib = ffi.C
  end
end)

if not lecho_lib then -- module not already linked, try to find and open dynamically
  local dir_sep, sep, sub
  local gmatch = string.gmatch
  local match = string.match
  local open = io.open
  local close = io.close

  for m in gmatch(package.config, '[^\n]+') do
      local m = m:gsub('([^%w])','%%%1')
      if not dir_sep then dir_sep = m
          elseif not sep then sep = m
          elseif not sub then sub = m end
  end

  local lib_name = concat(modname,dir_sep)

  for m in gmatch(package.cpath, '[^' .. sep ..';]+') do
    local so_path, r = m:gsub(sub,lib_name)
    if(r > 0) then
      local f = open(so_path)
        if f ~= nil then
          close(f)
          lecho_lib = ffi.load(so_path)
          break
        end
    end
  end

end

if not lecho_lib then
  return nil,'failed to load module'
end


-- now we return the real guts of the module
local M = {}
M.__index = M

local data_size = lecho_lib.lecho_size()
M.state = ffi.new("char[?]",data_size);
lecho_lib.lecho_get(M.state)

function M:off()
  return lecho_lib.lecho_off(self.state) == 0
end

function M:on()
  return lecho_lib.lecho_on(self.state) == 0
end

function M:status()
  return lecho_lib.lecho_status(self.state)
end

setmetatable(M,M)

return M
