local _M = {}

local lfs = require "lfs"

-- Code by David Kastrup

-- Returns iterator, which traverses given "dir" recursively and returns name and attributes
-- of the next file or directory on each iteration.
function _M.dirtree(dir)
  assert(dir and dir ~= "", "directory parameter is missing or empty")

  local path_separator = package.config:sub(1, 1)

  -- Strip trailing slash, if any
  if string.sub(dir, -1) == path_separator then
    dir = string.sub(dir, 1, -2)
  end

  local function yieldtree(dir)
    for entry in lfs.dir(dir) do
      if entry ~= "." and entry ~= ".." then
        entry = dir .. path_separator .. entry
        local attr = lfs.attributes(entry)
        coroutine.yield(entry, attr)
        if attr.mode == "directory" then
          yieldtree(entry)
        end
      end
    end
  end

  return coroutine.wrap(function() yieldtree(dir) end)
end

-- Code by Ilya Chesnokov

-- Returns array of files matching a given "pattern" received by recursive traversion of directory
-- "dir_name".
-- If pattern is not specified, all files are returned.
function _M.find_files(dir_name, pattern)
  local files = {}
  for filename, attr in _M.dirtree(dir_name) do
    if attr.mode == 'file' and pattern and string.match(filename, pattern) then
      files[#files + 1] = filename
    end
  end
  return files
end

-- Find '*.lua' files
function _M.find_lua_files(dir_name)
  return _M.find_files(dir_name, '[.]lua$')
end

return _M
