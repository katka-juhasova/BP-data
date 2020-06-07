return function()
  local path = require 'pl.path'

  local cli = require 'ddt.modules.cli'()
  local ddt = require 'ddt.core'()
  local appName = ddt.appName
  cli:set_name(ddt.appName)
  local exit = os.exit

  local cliArgs, err = cli:parse(arg)
  if not cliArgs then
    io.stderr:write(err .. '\n')
    exit(1)
  end

  if cliArgs.version then
    -- Return early if asked for the version
    print(ddt.version)
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
