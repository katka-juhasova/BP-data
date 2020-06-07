#!/usr/bin/env lua
local title, arrow, dart, bullet, error
do
  local _obj_0 = require("ltext")
  title, arrow, dart, bullet, error = _obj_0.title, _obj_0.arrow, _obj_0.dart, _obj_0.bullet, _obj_0.error
end
local argparse = require("argparse")
table.unpack = table.unpack or (unpack or function() end)
local argl
do
  local _with_0 = argparse()
  _with_0:name("ccrunx-image")
  _with_0:description("Package instances of CCRunX instances")
  _with_0:epilog("https://ccrunx.daelvn.ga")
  _with_0:command_target("action")
  do
    local _with_1 = _with_0:option("-v --version")
    _with_1:description("Prints the ccrunx-image version")
    _with_1:action(function()
      return print("ccrunx-image 0.2")
    end)
  end
  do
    local _with_1 = _with_0:flag("--embed")
    _with_1:description("Embeds the command in another such as ccrunx-compose")
  end
  do
    local _with_1 = _with_0:command("compress c")
    _with_1:description("Compress an instance")
    _with_1:target("compress")
    do
      local _with_2 = _with_1:argument("environment")
      _with_2:description("Package this environment")
      _with_2:args(1)
    end
  end
  do
    local _with_1 = _with_0:command("decompress d")
    _with_1:description("Decompress an image")
    _with_1:target("decompress")
    do
      local _with_2 = _with_1:argument("file")
      _with_2:description("File to decompress")
      _with_2:args(1)
    end
  end
  argl = _with_0:parse()
end
local _exp_0 = argl.action
if "compress" == _exp_0 then
  local env = argl.environment
  print(arrow(tostring(argl.embed and "  " or "") .. "Compressing environment " .. tostring(env) .. " at .ccrunx/" .. tostring(env)))
  local zip = io.popen("zip ccrunx-image_" .. tostring(env) .. ".ccrunx -r " .. tostring(env) .. " .ccrunx/" .. tostring(env))
  for line in zip:lines() do
    print(bullet((argl.embed and "   " or "") .. line))
  end
  zip:close()
  return print(arrow(tostring(argl.embed and "  " or "") .. "Created archive ccrunx-image_" .. tostring(env) .. ".ccrunx"))
elseif "decompress" == _exp_0 then
  local file = argl.file
  print(arrow(tostring(argl.embed and "  " or "") .. "Decompressing image " .. tostring(file)))
  local unzip = io.popen("unzip " .. tostring(file))
  for line in unzip:lines() do
    print(bullet((argl.embed and "   " or "") .. line))
  end
  unzip:close()
  return print(arrow(tostring(argl.embed and "  " or "") .. "Decompressed image " .. tostring(file)))
end
