--[[
    Helper methods for loading models from files.
--]]
local M = {}

-- Returns URI for path/data using the Hadoop filesystem
function M.dataPath(path)
  return path .. '/data'
end

--[[
 * Load metadata from the given path.
 * @return (class name, version, metadata)
--]]
function M.loadMetadata(sc, path)
  local firstLine = sc:textFile(M.metadataPath(path)):first()
  local jsonDecode = require 'stuart.util'.jsonDecode
  local metadata = jsonDecode(firstLine)
  return metadata.class, metadata.version, metadata
end

-- Returns URI for path/metadata using the Hadoop filesystem
function M.metadataPath(path)
  return path .. '/metadata'
end

return M
