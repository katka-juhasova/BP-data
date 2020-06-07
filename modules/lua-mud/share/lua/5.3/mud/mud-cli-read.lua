--
-- Implementation of the command line interface as called by 'lua-mud(1)'
--

local lua_mud = require 'mud.mud'

local mud_cli = {}

--
-- internal functions
--
function help(rcode, error_msg)
  if error_msg ~= nil then
    print("Error: " .. error_msg)
    print("")
  end
  print("Usage: lua-mud-read <mudfile> [options]")
  print("Reads <mudfile>, performs basic validation, and prints summary information")
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

function print_mud_summary(mud)
  --print(mud:to_json())
  print("MUD URL: " .. mud:get_mud_url())
  print("Last update: " .. mud:get_last_update())
  print("Cache validity: " .. mud:get_cache_validity())
  if mud:get_is_supported() then
    print("Supported: Yes")
  else
    print("Supported: No")
  end
  if mud:get_systeminfo() then
    print("Systeminfo: " .. mud:get_systeminfo())
  else
    print("Systeminfo not set")
  end

  print("Globally defined acls:")
  for _,acl in pairs(mud:get_acls()) do
    print(" " .. acl:getNode("name"):getValue())
    local aces = acl:getNode("aces")
    for _,r in pairs(aces:getNode("ace"):getValue()) do
      print("  - " .. r:getNode("name"):getValue())
    end
  end

  print("From-device policy:")
  for acl_n, pnode in pairs(mud:get_from_device_policy_acls()) do
    print(" " .. acl_n .. " (" .. pnode:getNode("name"):getValue() .. ")")
  end

  print("To-device policy:")
  for acl_n, pnode in pairs(mud:get_to_device_policy_acls()) do
    print(" " .. acl_n .. " (" .. pnode:getNode("name"):getValue() .. ")")
  end
end

--
-- external functions
--
function main(args)
  mudfile = parse_args(args)
  local mud = lua_mud.mud:create()
  mud:parseFile(mudfile)
  --local mud, err = lua_mud.mud_create_from_file(mudfile)
  print_mud_summary(mud)
end

mud_cli.main = main
return mud_cli
