local path = require 'pl.path'
local utils = require 'busted.utils'

local function script_path()
   local str = path.abspath(debug.getinfo(1, "S").source:sub(2))
   return str:match("(.*/)")
end

local tablex = require 'pl.tablex'

return function(options)
  local appName = ''
  local options = options or {}
  local cli = require 'cliargs.core'()

  local configLoader = require 'busted.modules.configuration_loader'()

  -- Default cli arg values
  local defaultPattern = options.specPattern or '_spec.json'

  local cliArgsParsed = {}
  local bustedArgsParsed = {}

  local function makeList(values)
    return type(values) == 'table' and values or { values }
  end

  local function processOption(key, value, altkey, opt)
    if altkey then cliArgsParsed[altkey] = value end
    cliArgsParsed[key] = value
    return true
  end

  local function processArg(key, value)
    cliArgsParsed[key] = value
    return true
  end

  local function processArgList(key, value)
    local list = cliArgsParsed[key] or {}
    tablex.insertvalues(list, utils.split(value, ','))
    processArg(key, list)
    return true
  end

  local function processMultiOption(key, value, altkey, opt)
    local list = cliArgsParsed[key] or {}
    table.insert(list, value)
    processOption(key, list, altkey, opt)
    return true
  end

  local function processDir(key, value, altkey, opt)
    local dpath = path.normpath(path.join(cliArgsParsed[key] or '', value))
    processOption(key, dpath, altkey, opt)
    return true
  end

  -- Load up the command-line interface options
  cli:flag('--version', 'prints the program version and exits', false, processOption)

  cli:splat('ROOT', 'test script file/folder. Folders will be traversed for any file that matches the --pattern option.', 'spec', 999, processArgList)

  cli:option('-p, --pattern=PATTERN', 'only run test files matching the Lua pattern', defaultPattern, processMultiOption)
  cli:option('--exclude-pattern=PATTERN', 'do not run test files matching the Lua pattern, takes precedence over --pattern', nil, processMultiOption)

  cli:option('-F, --ddlt-file=FILE', 'load configuration options from FILE', nil, processOption)
  cli:option('-C, --directory=DIR', 'change to directory DIR before running tests. If multiple options are specified, each is interpreted relative to the previous one.', './', processDir)
  cli:option('-f, --config-file=FILE', 'load configuration options for busted options', nil, processOption)
  cli:flag('-c, --[no-]coverage', 'do code coverage analysis (requires `LuaCov` to be installed)', false, processOption)
  cli:flag('-v, --[no-]verbose', 'verbose output of errors', false, processOption)
  cli:flag('-R, --[no-]recursive', 'recurse into subdirectories', true, processOption)

  local function parse(args)
    -- Parse the cli arguments
    local cliArgs, cliErr = cli:parse(args)
    local bustedArgs = {}
    if not cliArgs then
      return nil, appName .. ': error: ' .. cliErr .. '; re-run with --help for usage.'
    end

    -- Load ddlt config file if available
    local ddltConfigFilePath
    if cliArgs.F then
      -- if the file is given, then we require it to exist
      if not path.isfile(cliArgs.F) then
        return nil, ("specified config file '%s' not found"):format(cliArgs.F)
      end
      ddltConfigFilePath = cliArgs.F
    else
      -- try default file
      ddltConfigFilePath = path.normpath(path.join(cliArgs.directory, '.ddlt'))
      if not path.isfile(ddltConfigFilePath) then
        ddltConfigFilePath = nil  -- clear default file, since it doesn't exist
      end
    end

    -- Load busted config file if available
    local bustedConfigFilePath
    if cliArgs.f then
      -- if the file is given, then we require it to exist
      if not path.isfile(cliArgs.f) then
        return nil, ("specified config file '%s' not found"):format(cliArgs.f)
      end
      bustedConfigFilePath = cliArgs.f
    else
      -- try default file
      bustedConfigFilePath = path.normpath(path.join(cliArgs.directory, '.busted'))
      if not path.isfile(bustedConfigFilePath) then
        bustedConfigFilePath = nil  -- clear default file, since it doesn't exist
      end
    end

    if ddltConfigFilePath then
      local ddltConfigFile, err = loadfile(ddltConfigFilePath)
      if not ddltConfigFile then
        return nil, ("failed loading config file `%s`: %s"):format(ddltConfigFilePath, err)
      else
        local ok, config = pcall(function()
          local conf, err = configLoader(ddltConfigFile(), cliArgsParsed, cliArgs)
          return conf or error(err:gsub("busted", "ddlt"), 0)
        end)
        if not ok then
          return nil, appName .. ': error: ' .. config
        else
          cliArgs = config
        end
      end
    else
      cliArgs = tablex.merge(cliArgs, cliArgsParsed, true)
    end

    if bustedConfigFilePath then
      local bustedConfigFile, err = loadfile(bustedConfigFilePath)
      if bustedConfigFile and not err then
        local ok, config = pcall(function()
          local conf, err = configLoader(bustedConfigFile(), bustedArgsParsed)
          return conf or error(err, 0)
        end)
        if not ok then
          return nil, appName .. ': error: ' .. config
        else
          bustedArgs = config
        end
      end
    end

    table.insert(arg, script_path()..'../tests/test.lua')
    bustedArgs['standalone'] = false
    cliArgs.bustedArgs = bustedArgs
    cliArgs.cli = true

    -- Ensure multi-options are in a list
    cliArgs.pattern = makeList(cliArgs.pattern)
    cliArgs.p = cliArgs.pattern
    cliArgs['exclude-pattern'] = makeList(cliArgs['exclude-pattern'])

    return cliArgs
  end

  return {
    set_name = function(self, name)
      appName = name
      return cli:set_name(name)
    end,

    set_silent = function(self, name)
      appName = name
      return cli:set_silent(name)
    end,

    parse = function(self, args)
      return parse(args)
    end
  }
end
