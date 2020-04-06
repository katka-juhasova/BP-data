local modname = { 'whereami','core' }
local concat = table.concat

local ok, ffi = pcall(require,'ffi')
if not ok then
    return require(concat(modname,'.'))
end

local wai_lib

ffi.cdef[[
int wai_getExecutablePath(char* out, int capacity, int* dirname_length);
]]

pcall(function()
    if ffi.C.wai_getExecutablePath then
        wai_lib = ffi.C
    end
end)

if not wai_lib then
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

    local function find_lib(name)
      for m in gmatch(package.cpath, '[^' .. sep ..';]+') do
          local so_path, r = m:gsub(sub,name)
          if(r > 0) then
              local f = open(so_path)
              if f ~= nil then
                  close(f)
                  return so_path
              end
          end
      end
    end

    local function load_lib()
       local so_path = find_lib(concat(modname,dir_sep))
       if so_path then
           return ffi.load(so_path)
       end
    end

    wai_lib = load_lib()
end

if not wai_lib then
    return nil,'failed to load module'
end

return function()
    local path_size = wai_lib.wai_getExecutablePath(nil,0,nil)
    local path = ffi.new("char[?]",path_size)
    local res = wai_lib.wai_getExecutablePath(path,path_size,nil)
    return ffi.string(path,path_size), nil
end

