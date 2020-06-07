
local lfs = require 'lfs'

local DEFS  = require 'wagon.defs'
local LOG   = require 'wagon.log'

local FS = {}

local _load51
local _load52

function FS.isDir(path)
  local mode = lfs.attributes(path, 'mode')
  return mode and mode == 'directory'
end

function FS.changeDir(path)
  return lfs.chdir(path)
end

function FS.fullPath(path)
  return lfs.currentdir() .. "/" .. path
end

function FS.changeToParentDir()
  local lastdir = lfs.currentdir()
  assert(FS.changeDir('..'))
  return lfs.currentdir() ~= lastdir
end

function FS.createDir(name)
  assert(lfs.mkdir(name))
  LOG.raw("  created %s", name)
end

function FS.createFile(name, contents)
  local file = io.open(name, 'w')
  file:write(contents)
  file:close()
  LOG.raw("  created %s", name)
end

function FS.loadFile(path)
  local version = DEFS.luaVersion()
  if version.minor <= 1 then
    return _load51(path)
  else
    return _load52(path)
  end
end

function _load51(filepath)
  local data = {}
  local chunk = assert(loadfile(filepath))
  setfenv(chunk, data)
  chunk()
  return data
end

function _load52(filepath)
  local data = {}
  assert(loadfile(filepath, 't', data)) ()
  return data
end

return FS

