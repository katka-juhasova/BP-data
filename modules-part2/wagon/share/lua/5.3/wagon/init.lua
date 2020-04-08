
local LOG     = require 'wagon.log'
local BUILDER = require 'wagon.builder'
local DRIVER  = require 'wagon.driver'

local WAGON = {}

function WAGON.usage()
  print "Usage:"
  print "  wagon <command>"
  print "Available commands"
  print "  help build load drive"
end

--- Builds wagon in the current directory if it isn't already there.
function WAGON.init()
  if BUILDER.isWagonBuilt() then
    return LOG.info "Wagon is already built in the current directory"
  else
    return BUILDER.buildWagon()
  end
end

--- Installs all dependencies in the nearest wagon.
--  @param rockspec_path path to the rockspec file stating the dependencies
function WAGON.install(rockspec_path)
  if rockspec_path then
    LOG.info("Loading rockspec '%s'...", rockspec_path)
    if BUILDER.goToNearestWagon() then
      return DRIVER.loadRockspec(rockspec_path)
    else
      return LOG.info "Could not find a wagon to load onto"
    end
  else
    LOG.info "Please specify a rockspec file"
  end
end

function WAGON.run(...) --luacheck: no unused
  if BUILDER.goToNearestWagon() then
    return DRIVER.run(table.concat({ ... }, ' '))
  else
    return LOG.info "Could not find a wagon to run command with"
  end
end

return WAGON

