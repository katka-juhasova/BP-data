--
-- Implementation of the command line interface as called by 'lua-mud(1)'
--

local lua_mud = require 'mud.mud'
local iptables_rb = require("mud.rulebuilders.iptables")

local mud_cli = {}

--
-- internal functions
--
function help(rcode, error_msg)
  if error_msg ~= nil then
    print("Error: " .. error_msg)
    print("")
  end
  print("Usage: lua-mud-cli-rulebuilder <mudfile> [options]")
  print("Reads <mudfile>, outputs iptables commands (work in progress)")
  print("")
  print("Options:")
  print("-h: show this help")
  os.exit(rcode)
end

function parse_args(args)
  local mudfile = nil

  -- set skip to true in the loop when encountering a flag that has
  -- an argument
  skip = false
  for i = 1,table.getn(args) do
    if skip then
      skip = false
    elseif arg[i] == "-h" then
      help()
    else
      if mudfile == nil then mudfile = arg[i]
      else help(1, "Too many arguments at " .. table.getn(args))
      end
    end
  end

  if mudfile == nil then help(1, "Missing argument: <mudfile>") end

  return mudfile
end


--
-- external functions
--
function main(args)
  mudfile = parse_args(args)
  local mud = lua_mud.mud:create()
  mud:parseFile(mudfile)
  --local mud, err = lua_mud.mud_create_from_file(mudfile)
  builder = iptables_rb.create_rulebuilder()
  local rules = builder:build_rules(mud)
  for i, rule in pairs(rules) do
    print(rule)
  end
end

mud_cli.main = main
return mud_cli
