
local BUNDLER = require 'wagon.bundler'
local FS      = require 'wagon.fs'
local LOG     = require 'wagon.log'

local DRIVER = {}

local _PREAMBLE = 'LUA_PATH="%lua_path" '
               .. 'LUA_CPATH="%lib_path" '
               .. 'PATH="%bin_path:$PATH" '
               .. 'LUAROCKS_CONFIG="%config_file" '

local _INSTALL_CMD = [[
luarocks --local --tree=.wagon/rocktree install %s >/dev/null
]]

local function _formatPreamble(env)
  local params = {
    lua_path = table.concat(env.lua_paths, ';'),
    lib_path = table.concat(env.lib_paths, ';'),
    bin_path = table.concat(env.bin_paths, ':'),
    config_file = env.config_file
  }
  return _PREAMBLE:gsub("%%([%w_]+)", params)
end

function DRIVER.run(command)
  local env = BUNDLER.bundle()
  local preamble = _formatPreamble(env)
  local code = ("%s%s"):format(preamble, command)
  return assert(os.execute(code), "Command failed")
end

function DRIVER.loadRockspec(rockspec_path)
  LOG.info "Installing dependency rocks..."
  local spec = FS.loadFile(rockspec_path)
  for _, depstr in ipairs(spec.dependencies) do
    local rockname = depstr:match("^([^ ]+)")
    if rockname ~= 'lua' and rockname ~= 'luarocks' then
      LOG.raw("  %s", rockname)
      local command = _INSTALL_CMD:format(rockname)
      DRIVER.run(command)
    end
  end
end

return DRIVER

