
local DEFS = {}

DEFS.WAGON_DIR     = '.wagon'
DEFS.ROCKTREE_DIR  = DEFS.WAGON_DIR .. '/rocktree'
DEFS.LUA_DIR       = DEFS.ROCKTREE_DIR .. '/share/lua'
DEFS.LIB_DIR       = DEFS.ROCKTREE_DIR .. '/lib/lua'
DEFS.BIN_DIR       = DEFS.ROCKTREE_DIR .. '/bin'
DEFS.CONFIG_FILE   = DEFS.WAGON_DIR .. '/config.lua'

DEFS.CONFIG = [[
rocks_trees = {
  { name = 'user', root = '%s' }
}
]]

function DEFS.luaVersion()
  local major, minor = _VERSION:match("(%d+)%.(%d+)")
  return { major = tonumber(major), minor = tonumber(minor) }
end

return DEFS

