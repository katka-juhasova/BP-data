return function()
  local path = require 'pl.path'

  local cli = require 'ddlt.modules.cli'()
  local ddlt = require 'ddlt.core'()
  local appName = ddlt.appName
  cli:set_name(ddlt.appName)
  local exit = os.exit

  local cliArgs, err = cli:parse(arg)
  if not cliArgs then
    io.stderr:write(err .. '\n')
    exit(1)
  end

  if cliArgs.version then
    -- Return early if asked for the version
    print(ddlt.version)
    exit(0)
  end

  -- Load current working directory
  local _, err = path.chdir(path.normpath(cliArgs.directory))
  if err then
    io.stderr:write(appName .. ': error: ' .. err .. '\n')
    exit(1)
  end

  return cliArgs
end
