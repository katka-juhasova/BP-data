
local FS  = require 'wagon.fs'
local LOG = require 'wagon.log'
local DEFS = require 'wagon.defs'

local BUILDER = {}

function BUILDER.isWagonBuilt()
  return FS.isDir(DEFS.WAGON_DIR)
end

function BUILDER.buildWagon()
  LOG.info "Building wagon..."
  FS.createDir(DEFS.WAGON_DIR)
  FS.createDir(DEFS.ROCKTREE_DIR)
  local config_contents = DEFS.CONFIG:format(DEFS.ROCKTREE_DIR)
  FS.createFile(DEFS.CONFIG_FILE, config_contents)
end

function BUILDER.goToNearestWagon()
  repeat
    if FS.isDir(DEFS.WAGON_DIR) then
      return true
    end
  until not FS.changeToParentDir()
  return false
end

function BUILDER.findNearestWagon()
  return error "WIP"
end

return BUILDER

