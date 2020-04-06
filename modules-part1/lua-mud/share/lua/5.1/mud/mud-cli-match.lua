--
-- Implementation of the command line interface as called by 'lua-mud(1)'
--

local lua_mud = require('mud.mud')

local mud_cli = {}

--
-- internal functions
--
function help(rcode, error_msg)
  if error_msg ~= nil then
    print("Error: " .. error_msg)
    print("")
  end
  print("Usage: lua-mud-match <mudfile> <from|to> <ip|domain> <source port> <destination port> [options]")
  print("Reads <mudfile>, performs basic validation, and prints summary information")
  print("")
  print("Options:")
  print("-h: show this help")
  os.exit(rcode)
end

function parse_args(args)
  local mudfile = nil
  local from_device = nil
  local ip_or_domain = nil
  local source_port = nil
  local destination_port = nil

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
      elseif from_device == nil then
        if args[i] == "from" then from_device = true
        elseif args[i] == "to" then from_device = false
        else help(1, "Bad value for <from|to>, must be \"from\" or \"to\"")
        end
      elseif ip_or_domain == nil then ip_or_domain = arg[i]
      elseif source_port == nil then
        source_port = tonumber(arg[i])
        if source_port == nil then help(1, "<source port> must be a number") end
      elseif destination_port == nil then
        destination_port = tonumber(arg[i])
        if destination_port == nil then help(1, "<destination port> must be a number") end
      else help(1, "Too many arguments at " .. table.getn(args))
      end
    end
  end

  if mudfile == nil then help(1, "Missing argument: <mudfile>") end
  if ip_or_domain == nil then help(1, "Missing argument: <ip_or_domain>") end
  if source_port == nil then help(1, "Missing argument: <source_port>") end
  if destination_port == nil then help(1, "Missing argument: <destination_port>") end

  return mudfile, from_device, ip_or_domain, source_port, destination_port
end

--
-- external functions
--
function main(args)
  mudfile, from_device, ip_or_domain, source_port, destination_port = parse_args(args)

  local mud, err = lua_mud.mud_create_from_file(mudfile)
  if mud == nil then
    print("Error: " .. err)
  else
    local a,b = mud:validate()
    local actions = mud:get_policy_actions(from_device, {ip_or_domain}, {ip_or_domain}, source_port, destination_port)
    if actions ~= nil then
      print("Match! Actions:")
      for k,v in pairs(actions) do
        print(k .. ": " .. v)
      end
    else
      print("No match")
    end
  end
end

mud_cli.main = main
return mud_cli
